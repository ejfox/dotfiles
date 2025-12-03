# Startup Script - Complete Documentation

## Overview

The startup script (`~/.startup.sh` → `~/.dotfiles/.startup.sh`) provides a ultra-fast, intelligent terminal startup experience with seamless offline support.

**Key Stats:**
- Cold start: ~3 seconds (all components fetching)
- Warm cache: ~0.3 seconds (instant)
- Offline mode: Instant (uses cached data)
- All components have graceful fallbacks

## Architecture

```
User starts terminal
    ↓
Header displayed immediately (date/time)
    ↓
Network check (0.5s timeout to 1.1.1.1)
    ↓
7 components fetch in parallel:
├─ Stats (WPM + productivity)
├─ Tasks (Things app + LLM prioritization)
├─ Calendar (icalBuddy)
├─ Repos (git scan)
├─ Email (custom script)
├─ Insights (LLM pattern analysis) 
└─ (Cache checks before each)
    ↓
Components display as they complete
    ↓
Footer shown
```

## Components Breakdown

### 1. STATS (Monkeytype WPM + RescueTime)
- **Source:** ejfox.com/api/{monkeytype,rescuetime}
- **TTL:** 30 minutes
- **Timeout:** 0.7s per API
- **Fallback:** Shows previous cached data
- **Offline:** Uses cache
- **Format:** `188.95 WPM • 0.5h productive`

### 2. TASKS (Things app + LLM)
- **Source:** things-cli today
- **LLM:** claude 4o-mini (intelligent prioritization)
- **TTL:** 15 minutes
- **Timeouts:** 1.2s for LLM
- **Fallback:** Raw task list if LLM unavailable
- **Offline:** Uses cache
- **Shows:** Top 3 tasks, LLM-ranked by urgency

### 3. CALENDAR (icalBuddy)
- **Source:** icalBuddy eventsToday
- **TTL:** 15 minutes
- **Fallback:** Skips section if no events
- **Offline:** Uses cache
- **Shows:** Up to 3 events with times

### 4. REPOS (Git activity scan)
- **Source:** ~/code directory, git commits
- **TTL:** 30 minutes
- **Sort:** By last commit (newest first)
- **Fallback:** Skips if no repos or ~/code missing
- **Offline:** Uses cache
- **Shows:** Top 3 most recently active repos

### 5. EMAIL (Custom summary)
- **Source:** ~/.email-summary.sh
- **TTL:** Managed by email script (self-caching)
- **Fallback:** Skips if script missing
- **Offline:** Uses cached output from script
- **Shows:** Actionable/important emails

### 6. INSIGHTS (LLM pattern analysis)
- **Source:** LLM analysis of work patterns
- **TTL:** 30 minutes
- **Inputs:** Time, location, git activity, recent commands
- **Timeout:** 1.5s LLM
- **Fallback:** Skips if offline or LLM unavailable
- **Format:** 1-line insight (max 10 words)

## Intelligent Caching

All cache files stored in `/tmp/startup_cache/` with per-component TTLs:

| Component | File | TTL | Size |
|-----------|------|-----|------|
| Stats | stats.tmp | 30min | ~30B |
| Tasks | tasks.tmp | 15min | ~50B |
| Calendar | calendar.tmp | 15min | ~50B |
| Repos | repos.tmp | 30min | ~40B |
| Email | email.tmp | varies | ~400B |
| Insights | insights.tmp | 30min | ~50B |

**Cache logic:**
1. Check if file exists AND is fresh (newer than TTL)
2. If fresh, skip component entirely
3. If stale, fetch new data in background
4. On offline (network check fails), skip network components
5. Always show cached data if available

## Offline Support

When network check fails (0.5s timeout):
- Stats APIs skipped
- Insights generation skipped
- Task LLM prioritization skipped
- All other components (local) work normally
- Previous cached data shown throughout
- No error messages - graceful degradation

## Network Detection

**Method:** 0.5s timeout curl to Cloudflare DNS (1.1.1.1)
**Result:** Sets `ONLINE` variable (0=success, 1=offline)
**Used by:** Stats fetcher and Insights generator

This is fast enough that it doesn't block startup, and any API that times out just fails silently with fallback to cache.

## Dependencies

### Required
- bash (4.0+)
- curl (for network/API calls)
- jq (for JSON parsing)

### Optional (graceful skip if missing)
- things-cli (for tasks)
- icalBuddy (for calendar)
- /opt/homebrew/bin/llm (for task prioritization & insights)
- ~/.email-summary.sh (for email)

## Usage

```bash
# Run startup
~/.startup.sh

# Skip startup (press ESC during execution)
# (Ctrl-C works too)

# Run in zen mode (disabled startup)
touch /tmp/.zen-mode-state
~/.startup.sh  # Will exit immediately

# Clear cache manually
rm /tmp/startup_cache/*.tmp
```

## Configuration

Edit cache TTLs in script:
```bash
CACHE_STATS=30        # Minutes
CACHE_TASKS=15
CACHE_CALENDAR=15
CACHE_REPOS=30
CACHE_INSIGHTS=30
```

## Troubleshooting

### Nothing shows up
- Check cache directory: `ls /tmp/startup_cache/`
- Verify components are available: `which things-cli`, `command -v icalBuddy`
- Run manually: `things-cli today`, `icalBuddy -n eventsToday`

### Script is slow
- First run slow (cold cache): Expected
- Subsequent runs: Should be <500ms
- If slow: Check API endpoints, network latency

### Missing sections
- Sections only show if:
  1. Tool is available (things-cli, icalBuddy, etc)
  2. Data exists (has tasks, has events, etc)
  3. Cache is fresh OR fetch succeeds
- Missing is normal if tools unavailable

### Offline mode not working
- Script should skip online-only components
- Check `ONLINE` variable is set correctly
- Verify cache files exist: `ls /tmp/startup_cache/`

## Performance Targets

- **Startup time:** < 1s with cached data
- **Cold start:** < 4s with fresh fetches
- **Offline:** < 0.5s instant
- **Memory:** < 5MB
- **Cache size:** < 2MB total

## Testing

Run comprehensive tests:
```bash
bash /tmp/deep_test.sh          # Component testing
bash /tmp/final_validation.sh   # Health check
```

Test offline mode:
```bash
# Simulate offline
sudo ifconfig en0 down
~/.startup.sh    # Should use cache
sudo ifconfig en0 up
```

## Maintenance

**Weekly:**
- Clear old cache: `rm /tmp/startup_cache/*.tmp`

**Monthly:**
- Review API endpoints still valid
- Check Things tasks format hasn't changed
- Verify calendar feed working

**Yearly:**
- Update cache TTLs based on usage patterns
- Review LLM prompts for relevance

## Performance Benchmarks

**Test results (2025-11-30):**

Cold start (fresh):
- Real: ~3.2s
- User: ~1.5s
- System: ~0.7s

Warm cache:
- Real: ~0.3s
- User: ~0.03s
- System: ~0.04s

Warm cache (second run):
- Real: ~0.3s
- User: ~0.03s
- System: ~0.04s

## Implementation Details

### Background Processing
All fetchers run in background (`&` with PID tracking):
```bash
fetch_component &
COMPONENT_PID=$!
# ... other components ...
wait $COMPONENT_PID  # Wait when displaying
```

This allows parallel execution without blocking.

### Error Handling
Every component:
1. Checks if cache is fresh (early exit)
2. Checks if required tool available (graceful skip)
3. Has a timeout on API calls
4. Includes fallback logic
5. Silently skips on any error

### Cache Freshness Check
```bash
cache_fresh() {
  [[ -f "$1" ]] && [[ -z $(find "$1" -mmin +$2 2>/dev/null) ]]
}
# Returns 0 if file exists AND is newer than $2 minutes
```

## Future Enhancements

- [ ] Configurable components enable/disable
- [ ] Custom section order
- [ ] Metrics dashboard (stats over time)
- [ ] Component timing visualization
- [ ] Network speed testing
- [ ] Custom startup themes

## Security

- No credentials stored in script
- All API calls use HTTPS
- Cache files in /tmp (user-readable only)
- No logging of sensitive data
- Safe for public dotfiles repo

---

**Last Updated:** 2025-11-30
**Version:** 2.0 (Fully documented & tested)
**Status:** Production Ready ✓
