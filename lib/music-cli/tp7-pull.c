// tp7-pull: copy recordings off a Teenage Engineering TP-7 over MTP (libmtp). Run as root via tp7-root-pull.sh.
//
//   tp7-pull DEST          pull what's new (skip-existing by name + size)
//   tp7-pull DEST --list   show every file on the device and what would happen to it; copies nothing
//
// Rules (rewritten 2026-10-03; the original source was lost):
//   1. Only things the TP-7 made: its own recording names (YYYY-MM-DD_HHMMSS_NNN.wav; the clock can be wrong,
//      e.g. 2064-12-13_...) or anything in a "memo" folder. Music loaded through Field Kit is never pulled back.
//   2. Disk floor: before each file, check it fits AND leaves min_free_gb free; otherwise stop cleanly (exit 3).
//   3. Newest first, so a stopped pull still has the latest recordings.
//
// Config (optional): /Users/<user>/.config/music/tp7-pull.conf, derived from DEST
//   min_free_gb=20
//   pull_all=0            # 1 = pull every file regardless of rule 1 (old behavior)
//
// Output contract with tp7-import.sh (keep it): "<DEST> TOPULL=<n>", then per file "P <done> <total> <name>".
//
// Build: cc tp7-pull.c $(pkg-config --cflags --libs libmtp) -o tp7-pull
#include <libmtp.h>
#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <sys/statvfs.h>

typedef struct { LIBMTP_file_t *f; char folder[512]; int pull; const char *why; } entry;

static double min_free_gb = 20;
static int pull_all = 0;

static void read_config(const char *dest) {
  // /Users/<user>/... → /Users/<user>/.config/music/tp7-pull.conf (we run as root, so $HOME is wrong)
  char home[256] = "", conf[512];
  if (strncmp(dest, "/Users/", 7) == 0) {
    const char *end = strchr(dest + 7, '/');
    size_t n = end ? (size_t)(end - dest) : strlen(dest);
    if (n < sizeof home) { memcpy(home, dest, n); home[n] = 0; }
  }
  if (!*home) return;
  snprintf(conf, sizeof conf, "%s/.config/music/tp7-pull.conf", home);
  FILE *fp = fopen(conf, "r");
  if (!fp) return;
  char line[256];
  while (fgets(line, sizeof line, fp)) {
    if (sscanf(line, "min_free_gb=%lf", &min_free_gb) == 1) continue;
    sscanf(line, "pull_all=%d", &pull_all);
  }
  fclose(fp);
}

// full folder path of a file's parent, e.g. "store_00010001/memo"
static void folder_path(LIBMTP_folder_t *root, uint32_t id, char *out, size_t n) {
  char parts[16][128];
  int depth = 0;
  while (id != 0 && depth < 16) {
    LIBMTP_folder_t *f = LIBMTP_Find_Folder(root, id);
    if (!f) break;
    snprintf(parts[depth++], 128, "%s", f->name ? f->name : "?");
    id = f->parent_id;
  }
  out[0] = 0;
  for (int i = depth - 1; i >= 0; i--) {
    strncat(out, parts[i], n - strlen(out) - 1);
    if (i) strncat(out, "/", n - strlen(out) - 1);
  }
}

static double free_bytes(const char *dest) {
  struct statvfs s;
  if (statvfs(dest, &s) != 0) return -1;
  return (double)s.f_bavail * (double)s.f_frsize;
}

static int newest_first(const void *a, const void *b) {
  return strcmp(((const entry *)b)->f->filename, ((const entry *)a)->f->filename);
}

int main(int argc, char **argv) {
  if (argc < 2) { fprintf(stderr, "usage: tp7-pull DEST [--list]\n"); return 2; }
  const char *dest = argv[1];
  int list = argc > 2 && strcmp(argv[2], "--list") == 0;
  read_config(dest);
  mkdir(dest, 0755);

  regex_t made_here;
  regcomp(&made_here, "^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_[0-9]{3}\\.wav$", REG_EXTENDED | REG_ICASE);

  LIBMTP_Init();
  LIBMTP_mtpdevice_t *dev = LIBMTP_Get_First_Device();
  if (!dev) { fprintf(stderr, "NODEV\n"); return 1; }
  printf("device opened\n");
  fflush(stdout);

  LIBMTP_folder_t *folders = LIBMTP_Get_Folder_List(dev);
  LIBMTP_file_t *files = LIBMTP_Get_Filelisting_With_Callback(dev, NULL, NULL);

  int n = 0;
  for (LIBMTP_file_t *f = files; f; f = f->next) n++;
  entry *e = calloc(n ? n : 1, sizeof *e);
  int i = 0, topull = 0;
  for (LIBMTP_file_t *f = files; f; f = f->next, i++) {
    e[i].f = f;
    folder_path(folders, f->parent_id, e[i].folder, sizeof e[i].folder);
    char local[1024];
    snprintf(local, sizeof local, "%s/%s", dest, f->filename);
    struct stat st;
    int is_memo = strcasestr(e[i].folder, "memo") != NULL;
    int ours = regexec(&made_here, f->filename, 0, NULL, 0) == 0 || is_memo;
    if (f->filetype == LIBMTP_FILETYPE_FOLDER) { e[i].why = "folder"; }
    else if (!pull_all && !ours) { e[i].why = "skip: not a TP-7 recording (loaded library?)"; }
    else if (stat(local, &st) == 0 && (uint64_t)st.st_size == f->filesize) { e[i].why = "have it"; }
    else { e[i].pull = 1; e[i].why = "pull"; topull++; }
  }
  qsort(e, n, sizeof *e, newest_first);

  if (list) {
    for (i = 0; i < n; i++)
      printf("%s\t%s\t%llu MB\t%s\n", e[i].folder, e[i].f->filename, (unsigned long long)(e[i].f->filesize >> 20), e[i].why);
    printf("TOTAL %d files, %d would be pulled\n", n, topull);
    LIBMTP_Release_Device(dev);
    return 0;
  }

  printf("%s TOPULL=%d\n", dest, topull);
  fflush(stdout);
  int done = 0, failed = 0, rc = 0;
  for (i = 0; i < n; i++) {
    if (!e[i].pull) continue;
    LIBMTP_file_t *f = e[i].f;
    double need = (double)f->filesize + min_free_gb * 1073741824.0;
    double have = free_bytes(dest);
    if (have >= 0 && have < need) {
      printf("STOP diskfloor: %.1f GB free, %s needs %llu MB + %.0f GB floor. Free up space or raise min_free_gb.\n",
             have / 1073741824.0, f->filename, (unsigned long long)(f->filesize >> 20), min_free_gb);
      fflush(stdout);
      rc = 3;
      break;
    }
    char local[1024], part[1100];
    snprintf(local, sizeof local, "%s/%s", dest, f->filename);
    snprintf(part, sizeof part, "%s.part", local);   // never leave a half file under the real name
    printf("get [id=%u] %s (%llu MB)... ", f->item_id, f->filename, (unsigned long long)(f->filesize >> 20));
    fflush(stdout);
    if (LIBMTP_Get_File_To_File(dev, f->item_id, part, NULL, NULL) == 0 && rename(part, local) == 0) {
      printf("ok\n");
      printf("P %d %d %s\n", ++done, topull, f->filename);
    } else {
      printf("FAIL\n");
      LIBMTP_Dump_Errorstack(dev);
      LIBMTP_Clear_Errorstack(dev);
      remove(part);
      failed++;
      if (!rc) rc = 1;
    }
    fflush(stdout);
  }
  printf("END got=%d failed=%d\n", done, failed);
  LIBMTP_Release_Device(dev);
  return rc;
}
