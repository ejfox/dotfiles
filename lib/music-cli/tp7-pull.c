// tp7-pull: copy recordings off a Teenage Engineering TP-7 over MTP (libmtp). Runs as ROOT via tp7-root-pull.sh,
// writing into a user-writable folder, so it is written defensively.
//
//   tp7-pull DEST          pull what's new
//   tp7-pull DEST --list   show every file on the device and what would happen to it; copies nothing
//   tp7-pull --selftest    check the safety logic without a device
//
// Rules (rewritten 2026-10-03, hardened 2026-10-04; the original source was lost):
//   1. Only the TP-7 itself. Opens the device with Teenage Engineering's USB ids (0x2367:0x0019), never "the first
//      MTP device" (a phone plugged in at the same time would otherwise be read).
//   2. Only things it recorded: its own names (YYYY-MM-DD_HHMMSS_NNN.wav; the clock may be wrong, e.g. 2064-...)
//      or files inside a folder named exactly "memo". Music loaded through Field Kit is never pulled back.
//   3. Safe names only: no "/", no leading ".", nothing that could escape DEST.
//   4. Disk floor: before each file, it must fit AND leave min_free_gb free, otherwise stop cleanly (exit 3).
//   5. Newest first by the device's own object order (works even when the clock is wrong).
//   6. Every download is verified: written to "<name>.part" opened O_EXCL|O_NOFOLLOW (a planted symlink can't
//      redirect a root write), size checked against the device, then renamed into place. Never a half file.
//   7. Device unplugged mid-pull: stop after 3 consecutive failures instead of failing every remaining file.
//   8. A file already in DEST or in the quarantine folder with the device's exact size is "have it": quarantine
//      false-positives are never re-downloaded in a loop.
//
// Config (optional, values validated): /Users/<user>/.config/music/tp7-pull.conf, derived from DEST
//   min_free_gb=20        # 1-500
//   pull_all=0            # 1 = skip rule 2 (rules 1, 3, 4, 6 still apply)
//
// Output contract with tp7-import.sh (keep it): "<DEST> TOPULL=<n>", per file "P <done> <total> <name>",
// "STOP diskfloor ...", "END got=<n> failed=<n>". Exit: 0 ok, 1 errors, 2 usage, 3 disk floor, 4 device lost.
//
// Build: cc -Wall -Wextra -O2 tp7-pull.c $(pkg-config --cflags --libs libmtp) -o tp7-pull
#include <libmtp.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <unistd.h>

#define TP7_VENDOR 0x2367
#define TP7_PRODUCT 0x0019
#define GB 1073741824.0
#define MAX_CONSECUTIVE_FAILS 3

typedef struct { LIBMTP_file_t *f; char folder[512]; int pull; const char *why; } entry;

static double min_free_gb = 20;
static int pull_all = 0;
static regex_t made_here;

// ---------- pure helpers (covered by --selftest) ----------

// a device filename we're willing to create inside DEST
static int safe_name(const char *s) {
  if (!s || !*s || s[0] == '.' || strlen(s) > 200) return 0;
  for (const char *p = s; *p; p++) if (*p == '/' || *p == '\\' || (unsigned char)*p < 0x20) return 0;
  return 1;
}

// does a folder path contain a component named exactly "memo" (case-insensitive)?
static int in_memo_folder(const char *folder) {
  const char *p = folder;
  while (p && *p) {
    const char *slash = strchr(p, '/');
    size_t len = slash ? (size_t)(slash - p) : strlen(p);
    if (len == 4 && strncasecmp(p, "memo", 4) == 0) return 1;
    p = slash ? slash + 1 : NULL;
  }
  return 0;
}

static int is_ours(const char *name, const char *folder) {
  return regexec(&made_here, name, 0, NULL, 0) == 0 || in_memo_folder(folder);
}

// "/Users/<user>/..." → "/Users/<user>" (we run as root, so $HOME is wrong). Returns 0 if DEST isn't under /Users.
static int user_home(const char *dest, char *home, size_t n) {
  if (strncmp(dest, "/Users/", 7) != 0) return 0;
  const char *end = strchr(dest + 7, '/');
  size_t len = end ? (size_t)(end - dest) : strlen(dest);
  if (len <= 7 || len >= n) return 0;
  memcpy(home, dest, len);
  home[len] = 0;
  return 1;
}

static void parse_config_line(const char *line) {
  double gb; int all;
  if (sscanf(line, " min_free_gb = %lf", &gb) == 1) { if (gb >= 1 && gb <= 500) min_free_gb = gb; return; }
  if (sscanf(line, " pull_all = %d", &all) == 1) { if (all == 0 || all == 1) pull_all = all; }
}

static void read_config(const char *dest) {
  char home[256], conf[512];
  if (!user_home(dest, home, sizeof home)) return;
  if (snprintf(conf, sizeof conf, "%s/.config/music/tp7-pull.conf", home) >= (int)sizeof conf) return;
  FILE *fp = fopen(conf, "r");
  if (!fp) return;
  char line[256];
  while (fgets(line, sizeof line, fp)) parse_config_line(line);
  fclose(fp);
}

// size of DEST/name (or -1); used for "have it" checks in DEST and the quarantine folder
static long long size_of(const char *dir, const char *name) {
  char p[1024];
  struct stat st;
  if (snprintf(p, sizeof p, "%s/%s", dir, name) >= (int)sizeof p) return -1;
  if (lstat(p, &st) != 0 || !S_ISREG(st.st_mode)) return -1;
  return (long long)st.st_size;
}

static double free_bytes(const char *dest) {
  struct statvfs s;
  if (statvfs(dest, &s) != 0) return -1;
  return (double)s.f_bavail * (double)s.f_frsize;
}

// newest first: MTP object handles increase as the device creates files, independent of its (broken) clock
static int newest_first(const void *a, const void *b) {
  uint32_t x = ((const entry *)a)->f->item_id, y = ((const entry *)b)->f->item_id;
  return x < y ? 1 : x > y ? -1 : 0;
}

// open "<path>" for writing without ever following a symlink or reusing an existing file
static int open_new_file(const char *path) {
  unlink(path);   // a stale .part from a killed run (unlink removes a symlink itself, never its target)
  return open(path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0644);
}

// remove leftover "*.part" files from a killed run
static void clean_stale_parts(const char *dest) {
  DIR *d = opendir(dest);
  if (!d) return;
  struct dirent *de;
  char p[1024];
  while ((de = readdir(d))) {
    size_t l = strlen(de->d_name);
    if (l > 5 && strcmp(de->d_name + l - 5, ".part") == 0 && snprintf(p, sizeof p, "%s/%s", dest, de->d_name) < (int)sizeof p)
      unlink(p);
  }
  closedir(d);
}

// ---------- self-test (no device needed) ----------
static int selftest(void) {
  int fails = 0;
#define CHECK(cond, what) do { if (cond) printf("ok    %s\n", what); else { printf("FAIL  %s\n", what); fails++; } } while (0)
  CHECK(regexec(&made_here, "2026-09-26_231258_000.wav", 0, NULL, 0) == 0, "TP-7 recording name matches");
  CHECK(regexec(&made_here, "2064-12-13_054123_000.wav", 0, NULL, 0) == 0, "broken-clock recording name matches");
  CHECK(regexec(&made_here, "10-19 120 - BENJARBO.wav", 0, NULL, 0) != 0, "loaded library name rejected");
  CHECK(regexec(&made_here, "001.wav", 0, NULL, 0) != 0, "numbered library track rejected");
  CHECK(regexec(&made_here, "2026-09-26_231258_000.wav.part", 0, NULL, 0) != 0, "suffix after .wav rejected");
  CHECK(in_memo_folder("store_00010001/memo"), "memo folder recognized");
  CHECK(in_memo_folder("MEMO"), "memo folder case-insensitive");
  CHECK(!in_memo_folder("store_00010001/memories"), "\"memories\" is not the memo folder");
  CHECK(!in_memo_folder("library/memo-mixes"), "\"memo-mixes\" is not the memo folder");
  CHECK(!safe_name("../../etc/sudoers"), "path traversal name rejected");
  CHECK(!safe_name("a/b.wav"), "slash in name rejected");
  CHECK(!safe_name(".hidden.wav"), "dotfile name rejected");
  CHECK(!safe_name(""), "empty name rejected");
  CHECK(safe_name("2026-09-26_231258_000.wav"), "normal name accepted");
  char home[256];
  CHECK(user_home("/Users/ejfox/tp7/latest/recordings", home, sizeof home) && strcmp(home, "/Users/ejfox") == 0, "home derived from DEST");
  CHECK(!user_home("/tmp/x", home, sizeof home), "non-/Users DEST gives no config path");
  min_free_gb = 20; parse_config_line("min_free_gb=-5");   CHECK(min_free_gb == 20, "negative floor ignored");
  parse_config_line("min_free_gb=99999");                  CHECK(min_free_gb == 20, "absurd floor ignored");
  parse_config_line("min_free_gb = 30");                   CHECK(min_free_gb == 30, "valid floor applied");
  parse_config_line("pull_all=7");                         CHECK(pull_all == 0, "invalid pull_all ignored");
  min_free_gb = 20;
  // symlink planted at the .part path must not be followed (the root-write redirect attack)
  char tdir[] = "/tmp/tp7-selftest-XXXXXX";
  if (mkdtemp(tdir)) {
    char target[256], link[256];
    snprintf(target, sizeof target, "%s/victim", tdir);
    snprintf(link, sizeof link, "%s/x.wav.part", tdir);
    FILE *v = fopen(target, "w"); if (v) { fputs("untouched", v); fclose(v); }
    if (symlink(target, link) == 0) {
      int fd = open_new_file(link);   // unlinks the symlink, then creates a fresh regular file
      if (fd >= 0) { if (write(fd, "data", 4) != 4) fails++; close(fd); }
      struct stat st;
      char buf[16] = "";
      FILE *r = fopen(target, "r"); if (r) { if (!fgets(buf, sizeof buf, r)) buf[0] = 0; fclose(r); }
      CHECK(strcmp(buf, "untouched") == 0 && lstat(link, &st) == 0 && S_ISREG(st.st_mode), "planted .part symlink not followed");
    }
    char cmd[300]; snprintf(cmd, sizeof cmd, "rm -rf '%s'", tdir); if (system(cmd)) {}
  }
  printf("%s (%d failed)\n", fails ? "SELFTEST FAILED" : "SELFTEST PASSED", fails);
  return fails ? 1 : 0;
}

// ---------- device ----------
static LIBMTP_mtpdevice_t *open_tp7(void) {
  LIBMTP_raw_device_t *raw = NULL;
  int n = 0;
  if (LIBMTP_Detect_Raw_Devices(&raw, &n) != LIBMTP_ERROR_NONE || n == 0) return NULL;
  LIBMTP_mtpdevice_t *dev = NULL;
  for (int i = 0; i < n; i++) {
    if (raw[i].device_entry.vendor_id == TP7_VENDOR && raw[i].device_entry.product_id == TP7_PRODUCT) {
      dev = LIBMTP_Open_Raw_Device_Uncached(&raw[i]);
      break;
    }
  }
  free(raw);
  return dev;
}

static void folder_path(LIBMTP_folder_t *root, uint32_t id, char *out, size_t n) {
  char parts[16][128];
  int depth = 0;
  while (id != 0 && depth < 16) {
    LIBMTP_folder_t *f = LIBMTP_Find_Folder(root, id);
    if (!f) break;
    snprintf(parts[depth++], sizeof parts[0], "%s", f->name ? f->name : "?");
    id = f->parent_id;
  }
  out[0] = 0;
  for (int i = depth - 1; i >= 0; i--) {
    strncat(out, parts[i], n - strlen(out) - 1);
    if (i) strncat(out, "/", n - strlen(out) - 1);
  }
}

int main(int argc, char **argv) {
  if (regcomp(&made_here, "^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_[0-9]{3}\\.wav$", REG_EXTENDED | REG_ICASE | REG_NOSUB) != 0) {
    fprintf(stderr, "internal: bad pattern\n");
    return 1;
  }
  if (argc >= 2 && strcmp(argv[1], "--selftest") == 0) return selftest();
  if (argc < 2 || argv[1][0] != '/') { fprintf(stderr, "usage: tp7-pull /absolute/DEST [--list] | --selftest\n"); return 2; }
  const char *dest = argv[1];
  int list = argc > 2 && strcmp(argv[2], "--list") == 0;
  read_config(dest);
  if (mkdir(dest, 0755) != 0 && errno != EEXIST) { perror("mkdir DEST"); return 1; }
  struct stat dst;
  if (lstat(dest, &dst) != 0 || !S_ISDIR(dst.st_mode)) { fprintf(stderr, "DEST is not a real directory\n"); return 1; }

  // quarantine lives next to the recordings ledger: <tp7 root>/quarantine
  char quarantine[1024] = "";
  {
    char tmp[1024];
    snprintf(tmp, sizeof tmp, "%s", dest);
    char *slash = strrchr(tmp, '/');
    if (slash && slash != tmp) { *slash = 0; slash = strrchr(tmp, '/'); }
    if (slash && slash != tmp) { *slash = 0; snprintf(quarantine, sizeof quarantine, "%s/quarantine", tmp); }
  }
  if (!list) clean_stale_parts(dest);

  LIBMTP_Init();
  LIBMTP_mtpdevice_t *dev = open_tp7();
  if (!dev) { fprintf(stderr, "NODEV\n"); printf("NODEV\n"); return 1; }
  printf("device opened\n");
  fflush(stdout);

  LIBMTP_folder_t *folders = LIBMTP_Get_Folder_List(dev);
  LIBMTP_file_t *files = LIBMTP_Get_Filelisting_With_Callback(dev, NULL, NULL);
  if (!files && LIBMTP_Get_Errorstack(dev)) {
    // an empty device and a failed listing must not look the same ("nothing to import")
    printf("LISTFAIL: couldn't read the device's file list\n");
    LIBMTP_Dump_Errorstack(dev);
    LIBMTP_Release_Device(dev);
    return 1;
  }

  int n = 0;
  for (LIBMTP_file_t *f = files; f; f = f->next) n++;
  entry *e = calloc(n ? (size_t)n : 1, sizeof *e);
  if (!e) { perror("calloc"); return 1; }
  int i = 0, topull = 0;
  for (LIBMTP_file_t *f = files; f; f = f->next, i++) {
    e[i].f = f;
    folder_path(folders, f->parent_id, e[i].folder, sizeof e[i].folder);
    long long have = safe_name(f->filename) ? size_of(dest, f->filename) : -1;
    long long held = (safe_name(f->filename) && *quarantine) ? size_of(quarantine, f->filename) : -1;
    if (f->filetype == LIBMTP_FILETYPE_FOLDER) e[i].why = "folder";
    else if (!safe_name(f->filename)) e[i].why = "skip: unsafe file name";
    else if (!pull_all && !is_ours(f->filename, e[i].folder)) e[i].why = "skip: not a TP-7 recording (loaded library?)";
    else if (have >= 0 && (uint64_t)have == f->filesize) e[i].why = "have it";
    else if (held >= 0 && (uint64_t)held == f->filesize) e[i].why = "have it (in quarantine, complete)";
    else { e[i].pull = 1; e[i].why = "pull"; topull++; }
  }
  qsort(e, (size_t)n, sizeof *e, newest_first);

  if (list) {
    for (i = 0; i < n; i++)
      printf("%s\t%s\t%llu MB\t%s\n", e[i].folder, e[i].f->filename, (unsigned long long)(e[i].f->filesize >> 20), e[i].why);
    printf("TOTAL %d files, %d would be pulled (floor %.0f GB, %.1f GB free)\n", n, topull, min_free_gb, free_bytes(dest) / GB);
    LIBMTP_Release_Device(dev);
    return 0;
  }

  printf("%s TOPULL=%d\n", dest, topull);
  fflush(stdout);
  int done = 0, failed = 0, streak = 0, rc = 0;
  for (i = 0; i < n; i++) {
    if (!e[i].pull) continue;
    LIBMTP_file_t *f = e[i].f;
    double have = free_bytes(dest);
    if (have < 0 || have < (double)f->filesize + min_free_gb * GB) {
      printf("STOP diskfloor: %.1f GB free, %s needs %llu MB + %.0f GB floor. Free up space or lower min_free_gb.\n",
             have / GB, f->filename, (unsigned long long)(f->filesize >> 20), min_free_gb);
      rc = 3;
      break;
    }
    char local[1024], part[1100];
    if (snprintf(local, sizeof local, "%s/%s", dest, f->filename) >= (int)sizeof local ||
        snprintf(part, sizeof part, "%s.part", local) >= (int)sizeof part) {
      printf("skip (path too long): %s\n", f->filename);
      continue;
    }
    printf("get [id=%u] %s (%llu MB)... ", f->item_id, f->filename, (unsigned long long)(f->filesize >> 20));
    fflush(stdout);
    int ok = 0;
    int fd = open_new_file(part);
    if (fd >= 0) {
      int got = LIBMTP_Get_File_To_File_Descriptor(dev, f->item_id, fd, NULL, NULL);
      struct stat st;
      int sized = fstat(fd, &st) == 0 && (uint64_t)st.st_size == f->filesize;   // verify, don't trust
      int synced = fsync(fd) == 0;
      close(fd);
      ok = got == 0 && sized && synced && rename(part, local) == 0;
      if (!ok) unlink(part);
    }
    if (ok) {
      printf("ok\nP %d %d %s\n", ++done, topull, f->filename);
      streak = 0;
    } else {
      printf("FAIL\n");
      LIBMTP_Dump_Errorstack(dev);
      LIBMTP_Clear_Errorstack(dev);
      failed++;
      rc = 1;
      if (++streak >= MAX_CONSECUTIVE_FAILS) {
        printf("STOP device lost: %d failures in a row (unplugged or asleep?). Reconnect to resume; nothing is lost.\n", streak);
        rc = 4;
        break;
      }
    }
    fflush(stdout);
  }
  printf("END got=%d failed=%d\n", done, failed);
  fflush(stdout);
  LIBMTP_Release_Device(dev);
  return rc;
}
