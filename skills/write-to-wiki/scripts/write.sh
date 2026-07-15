#!/usr/bin/env bash
# write.sh — write an OKF v0.1 conformant markdown document to the daily wiki folder
#
# Spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
#
# Usage:
#   write.sh --title "Session Title" [OPTIONS] [BODY]
#   echo "body text" | write.sh --title "Session Title"
#
# Options:
#   -t, --title        <text>       Document title (required)
#   -y, --type         <text>       OKF type field (default: "session")
#   -d, --description  <text>       Short one-line summary
#   --tags             <csv>        Comma-separated tags e.g. "smith,infra,qa"
#   --resource         <url>        Canonical URI for the underlying asset
#   --date             <yyyy-mm-dd> Override date (default: today)
#   --wiki-root        <path>       Wiki root dir (default: WIKI_ROOT env or ~/wiki/.captures)
#   --dry-run                       Print the document without writing
#   -h, --help                      Show this help
#
# Body:
#   Remaining positional args OR stdin are used as the markdown body.
#
# Environment:
#   WIKI_ROOT   — root directory for raw auto-captured session entries
#                 (default: ~/wiki/.captures). Kept separate from the
#                 curated topic wiki (~/wiki/entities, decisions, patterns,
#                 sessions, index.md) which an LLM manually synthesizes into
#                 via the wiki-ingest skill — the two used to share the same
#                 root and index.md/log.md, which made "sessions/2026-07-01"
#                 (curated) and "2026-07-01/" (raw capture) collide in
#                 search results. See decisions/wiki-hooks.md.
#
# OKF conformance (v0.1):
#   - Every concept .md has YAML frontmatter with required `type` field
#   - index.md files have NO frontmatter (except bundle root okf_version block)
#   - index.md uses "* [Title](slug.md) — description" format per §6
#   - log.md maintained at daily level, newest-first per §7
#   - Cross-links use bundle-relative paths (/ prefix) per §5.1
#
# File layout:
#   $WIKI_ROOT/
#     index.md                  ← bundle root (okf_version frontmatter)
#     log.md                    ← bundle-level change log
#     <yyyy-mm-dd>/
#       index.md                ← daily listing (no frontmatter, §6)
#       log.md                  ← daily change log (§7)
#       <slug>.md               ← your concept document

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
WIKI_ROOT="${WIKI_ROOT:-$HOME/wiki/.captures}"
TITLE=""
TYPE="session"
DESCRIPTION=""
TAGS=""
RESOURCE=""
DATE="$(date +%Y-%m-%d)"
DRY_RUN=0
BODY_ARGS=()

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--title)        TITLE="$2";       shift 2 ;;
    -y|--type)         TYPE="$2";        shift 2 ;;
    -d|--description)  DESCRIPTION="$2"; shift 2 ;;
    --tags)            TAGS="$2";        shift 2 ;;
    --resource)        RESOURCE="$2";    shift 2 ;;
    --date)            DATE="$2";        shift 2 ;;
    --wiki-root)       WIKI_ROOT="$2";   shift 2 ;;
    --dry-run)         DRY_RUN=1;        shift ;;
    -h|--help)         grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)                 BODY_ARGS+=("$1"); shift ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
if [ -z "$TITLE" ]; then
  echo "write-to-wiki: --title is required" >&2; exit 1
fi

# ── Build body ────────────────────────────────────────────────────────────────
BODY=""
if [ ${#BODY_ARGS[@]} -gt 0 ]; then
  BODY="${BODY_ARGS[*]}"
elif [ ! -t 0 ]; then
  BODY="$(cat)"
fi

# ── Slugify title → filename (OKF concept ID) ─────────────────────────────────
slug() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 ]//g' \
    | tr ' ' '-' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//'
}

SLUG=$(slug "$TITLE")
DAY_DIR="$WIKI_ROOT/$DATE"
FILE="$DAY_DIR/${SLUG}.md"

# Bundle-relative concept ID (§2) for cross-links
CONCEPT_ID="$DATE/$SLUG"

# ── Build YAML frontmatter (§4.1) ─────────────────────────────────────────────
# Required: type
# Recommended: title, description, resource, tags, timestamp
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

build_frontmatter() {
  echo "---"
  echo "type: $TYPE"
  echo "title: $TITLE"
  [ -n "$DESCRIPTION" ] && echo "description: $DESCRIPTION"
  [ -n "$RESOURCE"    ] && echo "resource: $RESOURCE"
  if [ -n "$TAGS" ]; then
    # Normalize spacing: "smith, infra" → "[smith, infra]"
    TAGS_CLEAN=$(echo "$TAGS" | sed 's/,\s*/,/g' | sed 's/,/, /g')
    echo "tags: [$TAGS_CLEAN]"
  fi
  echo "timestamp: $TIMESTAMP"
  echo "---"
}

# ── Assemble concept document (§4) ───────────────────────────────────────────
FRONTMATTER=$(build_frontmatter)

DOC="${FRONTMATTER}

# ${TITLE}

${BODY}"

# ── Dry run ───────────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = "1" ]; then
  echo "── DRY RUN ── would write to: $FILE"
  echo "── Concept ID: $CONCEPT_ID"
  echo ""
  echo "$DOC"
  exit 0
fi

# ── Ensure bundle root is initialized ────────────────────────────────────────
# Bundle root index.md: only place frontmatter is allowed in index (§11 okf_version)
ROOT_INDEX="$WIKI_ROOT/index.md"
if [ ! -f "$ROOT_INDEX" ]; then
  mkdir -p "$WIKI_ROOT"
  cat > "$ROOT_INDEX" << EOF
---
okf_version: "0.1"
---

# Wiki

A personal knowledge bundle in [Open Knowledge Format v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md).

EOF
  echo "📁 Initialized wiki bundle at $WIKI_ROOT"
fi

# ── Ensure daily folder and index exist ──────────────────────────────────────
mkdir -p "$DAY_DIR"

# Daily index.md: NO frontmatter per §6 — just a listing
DAILY_INDEX="$DAY_DIR/index.md"
if [ ! -f "$DAILY_INDEX" ]; then
  cat > "$DAILY_INDEX" << EOF
# $DATE

EOF
  # Add daily folder entry to root index
  if ! grep -q "($DATE/)" "$ROOT_INDEX" 2>/dev/null; then
    echo "* [$DATE](/$DATE/) — $(date '+%A, %B %-d %Y')" >> "$ROOT_INDEX"
  fi
fi

# ── Write concept document ────────────────────────────────────────────────────
if [ -f "$FILE" ]; then
  echo "write-to-wiki: $FILE already exists — appending update section" >&2
  {
    echo ""
    echo "---"
    echo ""
    echo "## Update — $(date '+%H:%M %Z')"
    echo ""
    echo "$BODY"
  } >> "$FILE"
else
  echo "$DOC" > "$FILE"
fi

# ── Update daily index (§6 format: * [Title](slug.md) — description) ─────────
INDEX_ENTRY="* [${TITLE}](${SLUG}.md)"
[ -n "$DESCRIPTION" ] && INDEX_ENTRY="${INDEX_ENTRY} — ${DESCRIPTION}"

if ! grep -q "(${SLUG}.md)" "$DAILY_INDEX" 2>/dev/null; then
  echo "$INDEX_ENTRY" >> "$DAILY_INDEX"
fi

# ── Update daily log.md (§7: date-grouped, newest first) ─────────────────────
DAILY_LOG="$DAY_DIR/log.md"
LOG_VERB="Creation"
[ -f "$FILE" ] && LOG_VERB="Update"

if [ ! -f "$DAILY_LOG" ]; then
  cat > "$DAILY_LOG" << EOF
# $DATE Update Log

## $(date '+%H:%M %Z')
* **${LOG_VERB}**: [${TITLE}](/${CONCEPT_ID}.md)$([ -n "$DESCRIPTION" ] && echo " — $DESCRIPTION")

EOF
else
  # Prepend new entry after the heading
  TEMP=$(mktemp)
  head -3 "$DAILY_LOG" > "$TEMP"
  echo "* **${LOG_VERB}**: [${TITLE}](/${CONCEPT_ID}.md)$([ -n "$DESCRIPTION" ] && echo " — $DESCRIPTION")" >> "$TEMP"
  tail -n +4 "$DAILY_LOG" >> "$TEMP"
  mv "$TEMP" "$DAILY_LOG"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo "✍️  Concept:  $FILE"
echo "📋 Index:    $DAILY_INDEX"
echo "📜 Log:      $DAILY_LOG"
echo "🔗 ID:       /$CONCEPT_ID"
