# Advanced CLI Workflow Pipelines

## Current Toolkit Stack
- `obs` - Obsidian vault access (read/write notes)
- `scrap` - Scrapbook database (Supabase-backed scraps)
- `pub` - Publishing pipeline (Obsidian → website2)
- `llm` - Claude AI via CLI (text processing)

## Potential Integrated Workflows

### 1. **Scrap → LLM Synthesis → Obsidian Note**
```bash
# Single scrap → summarize with LLM → save to obs as draft
scrap get <id> | llm -m gpt-4o-mini "Synthesize this into a blog post outline"  | \
  obs create "blog/generated-$(date +%Y%m%d).md"

# Batch: all scraps with tag → LLM analysis → create note
scraps --tag "research" | \
  jq -r '.[].content' | \
  llm -m gpt-4o-mini "Find 3 key insights across all these scraps" | \
  obs create "robots/scrap-analysis-$(date +%Y%m%d).md"
```

### 2. **Obsidian Note → LLM Enhancement → Scrap Storage**
```bash
# Read draft → enhance with Claude → save as scrap
obs print "drafts/idea.md" | \
  llm -m gpt-4o-mini -s "Expand this into 3 related angles/questions" | \
  scrap save --title "Expanded Idea" --tags "ai,research"

# Multi-note synthesis
find ~/.obsidian/robots -name "*.md" -mtime -7 -print0 | xargs -0 -I {} sh -c \
  'obs print {} | llm -s "Extract the core concept in one sentence"' | \
  scrap save --title "Weekly Concepts" --tags "weekly"
```

### 3. **Smart Publishing Pipeline: Scrap → Note → Site**
```bash
# Draft from scrap database
scrap list --filter "status=ready" | jq -r '.[0] | {title: .title, content: .content}' | \
  jq -r '"---\nstatus: ready\n---\n\(.content)"' | \
  obs create "blog/\(.title | @uri).md"

# Then publish the note
pub import && pub publish
```

### 4. **Content Gap Analysis (Obsidian + Scraps + LLM)**
```bash
# What topics do I have scraps for but NO published notes?
SCRAP_TAGS=$(scraps | jq -r '.[].tags[]' | sort -u)
NOTE_TAGS=$(find ~/.obsidian/blog -name "*.md" -exec grep -h "tags:" {} \; | \
  sed 's/.*tags: //' | tr ',' '\n' | tr -d '[]"' | sort -u)

# Find topics in scraps but not published
comm -23 <(echo "$SCRAP_TAGS" | sort) <(echo "$NOTE_TAGS" | sort) | \
  while read tag; do
    echo "Gap: $tag"
    scraps --tag "$tag" | llm -s "Create a compelling blog post idea about $tag"
  done
```

### 5. **Daily Ideation: Scraps → LLM → Obsidian Brain Dump**
```bash
# Morning ritual: what should I focus on today?
scraps -limit 10 --order "random" | \
  jq -r '.[].content' | \
  llm -m gpt-4o-mini \
    -s "Based on these past scraps/ideas, what's ONE powerful thing I could work on today?" | \
  obs create "daily/$(date +%Y-%m-%d)-focus.md"
```

### 6. **Batch Content Processing (Tag-based)**
```bash
# Process all unprocessed scraps through LLM
scraps --filter "processed=false" | \
  jq -r '.[] | "\(.id)|\(.content)"' | \
  while IFS='|' read id content; do
    # Tag categorization
    tags=$(echo "$content" | llm -m gpt-4o-mini \
      -s "Output ONLY comma-separated tags for this content, no explanation")
    
    # Save back (would need scrap CLI update support)
    echo "Updated scrap $id with tags: $tags"
  done
```

### 7. **Reverse Research: Note → Question → Scraps**
```bash
# Read obs note → generate research questions → search scraps for answers
obs print "projects/current.md" | \
  llm -s "Generate 5 research questions this raises" | \
  while read question; do
    echo "Research: $question"
    scraps --search "$question" | jq '.[] | "\(.title): \(.content)"'
  done
```

### 8. **Writing Assistant: LLM Feedback Loop**
```bash
# Draft → LLM critique → store questions as scraps → iterate
obs print "drafts/essay.md" | \
  llm -s "Give 3 specific critical feedback points on this writing" | \
  tee >(obs create "drafts/$(basename).feedback.md") | \
  jq -R 'split("\n") | .[]' | \
  scrap save --title "Feedback on essay" --tags "writing,meta"
```

### 9. **Smart Publishing: Only publish notes that pass LLM quality**
```bash
# Check all status:ready notes for quality before publishing
for note in $(obs tags | grep -i "status:ready"); do
  quality=$(obs print "$note" | \
    llm -s "Rate this writing 1-10 for clarity, originality, actionability (output ONLY number)")
  
  if [ "$quality" -gt 7 ]; then
    echo "✓ Publishing $note (quality: $quality)"
    pub import
  else
    echo "⚠ Hold $note (quality: $quality) - needs revision"
  fi
done
```

### 10. **Meta-Analysis: Vault Health Report**
```bash
# Comprehensive analysis of your entire writing system
{
  echo "=== VAULT HEALTH REPORT ==="
  echo ""
  echo "## Statistics"
  pub status
  
  echo ""
  echo "## Quality Analysis"
  find ~/.obsidian/blog -name "*.md" | \
    xargs -I {} sh -c 'obs print {} | llm -s "One sentence: is this ready to publish?"' | \
    sort | uniq -c
  
  echo ""
  echo "## Gap Analysis"
  scraps | jq -r '.[].tags[]' | sort | uniq -c | sort -rn | \
    awk '{print "Scraps about " $2 ": " $1}' | \
    head -5
} | tee "vault-health-$(date +%Y%m%d).md"
```

---

## Pro-Level Aliases to Add to .zshrc

```bash
# Synthesize scraps into a note
alias synthscrap="scrap list -limit 20 | jq -r '.[].content' | llm -m gpt-4o-mini 'Synthesize these insights' | obs create"

# Enhance any text file with Claude
enhance() { cat "$1" | llm -m gpt-4o-mini "Improve this, add depth" | tee "${1%.md}-enhanced.md" }

# Quick scrap → published note pipeline
scrap2note() { scrap get "$1" | obs create "blog/from-scrap-$(date +%s).md" && pub import }

# LLM-powered note search
lfind() { obs tags | grep -i "$1" | llm "Find the most relevant ones" }

# Batch scrap summarization
scrapsummary() { scraps --tag "$1" | jq -r '.[].content' | llm "Generate key insights" }
```

