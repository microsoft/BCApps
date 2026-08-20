#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"

now=${NOW_EPOCH:-$(date -u '+%s')}
cutoff_5min=$(date -u -d "@$((now - 300))" '+%Y-%m-%dT%H:%M:%SZ')
cutoff_30d=$(date -u -d "@$((now - 2592000))" '+%Y-%m-%dT%H:%M:%SZ')

new_issues=()
updated_issues=()
stale_issues=()

classify_labels() {
  local labels=$1

  has_missing_info=false
  has_request_type=false
  has_agent_not_processable=false

  while IFS= read -r label; do
    [ -z "$label" ] && continue
    case "$label" in
      missing-info)
        has_missing_info=true
        ;;
      event-request|request-for-external|enum-request|extensibility-enhancement)
        has_request_type=true
        ;;
      agent-not-processable)
        has_agent_not_processable=true
        ;;
    esac
  done <<< "$labels"
}

while IFS= read -r issue; do
  number=$(echo "$issue" | jq -r '.number')
  created_at=$(echo "$issue" | jq -r '.created_at')
  updated_at=$(echo "$issue" | jq -r '.updated_at')
  label_names=$(echo "$issue" | jq -r '.labels[].name')

  classify_labels "$label_names"
  [ "$has_request_type" = "true" ] && continue
  [ "$has_agent_not_processable" = "true" ] && continue

  comments=$(gh api "repos/$GITHUB_REPOSITORY/issues/$number/comments" \
    --paginate | jq -cs 'add // []')

  if echo "$comments" | jq -e 'any(.[];
    ((.user.login // "") | ascii_downcase | endswith("[bot]") | not) and
    ((.body // "") | test("/not-accurate"; "i"))
  )' > /dev/null; then
    continue
  fi

  last_comment_author=$(echo "$comments" | jq -r 'last | .user.login // ""')
  last_comment_updated_at=$(echo "$comments" | jq -r 'last | .updated_at // ""')

  if [ "$has_missing_info" = "false" ]; then
    [[ "$created_at" < "$cutoff_5min" ]] || continue
    new_issues+=("$number")
  elif [[ "$updated_at" < "$cutoff_30d" ]]; then
    if [[ "${last_comment_author,,}" == *"[bot]" ]]; then
      stale_issues+=("$number")
    fi
  elif [[ "$updated_at" < "$cutoff_5min" ]]; then
    if [ -z "$last_comment_author" ] ||
       [[ "${last_comment_author,,}" != *"[bot]" ]] ||
       { [ -n "$last_comment_updated_at" ] &&
         [[ "$updated_at" > "$last_comment_updated_at" ]]; }; then
      updated_issues+=("$number")
    fi
  fi
done < <(gh api "repos/$GITHUB_REPOSITORY/issues" \
  --paginate -X GET \
  -f state=open \
  -f type=Task \
  -f per_page=100 \
  --jq '.[]')

echo "::group::New issues (${#new_issues[@]})"
[ "${#new_issues[@]}" -gt 0 ] && printf '  #%s\n' "${new_issues[@]}" || echo "  (none)"
echo "::endgroup::"

echo "::group::Updated issues (${#updated_issues[@]})"
[ "${#updated_issues[@]}" -gt 0 ] && printf '  #%s\n' "${updated_issues[@]}" || echo "  (none)"
echo "::endgroup::"

echo "::group::Stale issues (${#stale_issues[@]})"
[ "${#stale_issues[@]}" -gt 0 ] && printf '  #%s\n' "${stale_issues[@]}" || echo "  (none)"
echo "::endgroup::"

all_issues=("${new_issues[@]}" "${updated_issues[@]}" "${stale_issues[@]}")
if [ "${#all_issues[@]}" -eq 0 ]; then
  echo "issues=[]" >> "$GITHUB_OUTPUT"
else
  issues_json=$(printf '%s\n' "${all_issues[@]}" | jq -R 'tonumber' | jq -sc '.')
  echo "issues=$issues_json" >> "$GITHUB_OUTPUT"
fi
