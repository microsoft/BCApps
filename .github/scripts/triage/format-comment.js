// Comment formatting for triage assessments
// See: docs/features/issue-triage-agent/design.md (FR18)
//
// Produces a compact issue comment with a link to the full wiki report.
// Falls back to the verbose format if the wiki report could not be published.

import { formatDuplicatesSection } from './duplicate-detector.js';
import { formatPrecedentsSection } from './precedent-finder.js';

const GITHUB_COMMENT_MAX_CHARS = 65536;

const ACTION_EMOJI = {
  'Implement': ':white_check_mark:',
  'Defer': ':hourglass_flowing_sand:',
  'Investigate': ':mag:',
  'Reject': ':x:',
};

/**
 * Format a compact triage comment for the issue.
 * If wikiUrl is provided, links to the full report on the wiki.
 * If wikiUrl is null (publish failed), falls back to verbose inline format.
 */
export function formatTriageComment(phase1, phase2, isRetriage, duplicates = [], previousScores = null, wikiUrl = null, precedents = []) {
  if (!wikiUrl) {
    return formatVerboseComment(phase1, phase2, isRetriage, duplicates, previousScores, precedents);
  }

  const qs = phase1.quality_score;
  const t = phase2.triage;
  const actionEmoji = ACTION_EMOJI[t.recommended_action?.action] || ':question:';

  let md = `## :robot: AI Triage Assessment\n\n`;
  md += `> Automated assessment by the Issue Triage Agent (GPT-5.4)\n`;

  if (isRetriage) {
    md += `> :arrows_counterclockwise: **Re-triage** — see wiki history for previous assessment.\n`;
  }

  md += `\n`;

  // Compact summary table
  md += `| Verdict | Quality | Priority | Action |\n`;
  md += `|---------|---------|----------|--------|\n`;
  md += `| ${phase1.verdict} | ${qs.total}/100 | ${t.priority_score.score}/10 | ${actionEmoji} ${t.recommended_action.action} |\n`;

  md += `\n**Summary:** ${phase2.executive_summary}\n`;

  // Duplicates warning (if any)
  const dupsSection = formatDuplicatesSection(duplicates);
  if (dupsSection) {
    md += `\n${dupsSection}`;
  }

  // Missing info (if any)
  if (phase1.missing_info && phase1.missing_info.length > 0) {
    md += `\n### :warning: Information needed\n\n`;
    for (const item of phase1.missing_info) {
      md += `- [ ] ${item}\n`;
    }
  }

  md += `\n---\n<sub>Was this triage helpful? React with :thumbsup: or :thumbsdown: on this comment to provide feedback.</sub>\n`;

  md += `\n:clipboard: [View full triage report →](${wikiUrl}) _(opens in same tab — use Ctrl+Click to open in new tab)_\n`;

  return md;
}

/**
 * Verbose fallback comment when wiki publishing fails.
 * Contains the full assessment inline (same as the previous format).
 */
function formatVerboseComment(phase1, phase2, isRetriage, duplicates, previousScores, precedents) {
  const qs = phase1.quality_score;
  const t = phase2.triage;
  const e = phase2.enrichment;
  const actionEmoji = ACTION_EMOJI[t.recommended_action?.action] || ':question:';

  let md = `## :robot: AI Triage Assessment\n\n`;
  md += `> Automated assessment by the Issue Triage Agent (GPT-5.4)\n`;
  md += `> Triggered by \`ai-triage\` label\n`;
  md += `> :warning: Full report could not be published to wiki — showing inline.\n`;

  if (isRetriage) {
    md += `> :arrows_counterclockwise: **Re-triage** - see earlier assessment comments for history.\n`;
  }

  md += `\n---\n\n`;

  md += formatDuplicatesSection(duplicates);
  md += formatPrecedentsSection(precedents);

  // Quality score table
  md += `### Issue Quality Score: ${qs.total}/100 - ${phase1.verdict}\n\n`;
  md += `| Dimension | Score | Notes |\n`;
  md += `|-----------|-------|-------|\n`;
  md += `| Clarity | ${qs.clarity.score}/20 | ${qs.clarity.notes} |\n`;
  md += `| Reproducibility | ${qs.reproducibility.score}/20 | ${qs.reproducibility.notes} |\n`;
  md += `| Context | ${qs.context.score}/20 | ${qs.context.notes} |\n`;
  md += `| Specificity | ${qs.specificity.score}/20 | ${qs.specificity.notes} |\n`;
  md += `| Actionability | ${qs.actionability.score}/20 | ${qs.actionability.notes} |\n`;

  // Re-triage comparison
  if (isRetriage && previousScores) {
    md += `\n#### :arrows_counterclockwise: Changes since last triage\n\n`;
    md += `| Metric | Previous | Current | Change |\n`;
    md += `|--------|----------|---------|--------|\n`;
    if (previousScores.qualityTotal != null) {
      const delta = qs.total - previousScores.qualityTotal;
      const arrow = delta > 0 ? ':arrow_up:' : delta < 0 ? ':arrow_down:' : ':left_right_arrow:';
      md += `| Quality Score | ${previousScores.qualityTotal}/100 | ${qs.total}/100 | ${arrow} ${delta > 0 ? '+' : ''}${delta} |\n`;
    }
    for (const dim of ['clarity', 'reproducibility', 'context', 'specificity', 'actionability']) {
      if (previousScores[dim] != null && qs[dim]) {
        const delta = qs[dim].score - previousScores[dim];
        if (delta !== 0) {
          const arrow = delta > 0 ? ':arrow_up:' : ':arrow_down:';
          const label = dim.charAt(0).toUpperCase() + dim.slice(1);
          md += `| ${label} | ${previousScores[dim]}/20 | ${qs[dim].score}/20 | ${arrow} ${delta > 0 ? '+' : ''}${delta} |\n`;
        }
      }
    }
    if (previousScores.priority != null && t.priority_score?.score != null) {
      const delta = t.priority_score.score - previousScores.priority;
      if (delta !== 0) {
        const arrow = delta > 0 ? ':arrow_up:' : ':arrow_down:';
        md += `| Priority | ${previousScores.priority}/10 | ${t.priority_score.score}/10 | ${arrow} ${delta > 0 ? '+' : ''}${delta} |\n`;
      }
    }
    if (previousScores.verdict && previousScores.verdict !== phase1.verdict) {
      md += `\n> Verdict changed: **${previousScores.verdict}** → **${phase1.verdict}**\n`;
    }
    md += `\n`;
  }

  // Missing info
  if (phase1.missing_info && phase1.missing_info.length > 0) {
    md += `\n### :warning: Information needed\n\n`;
    for (const item of phase1.missing_info) {
      md += `- [ ] ${item}\n`;
    }
  }

  md += `\n---\n\n`;

  // Triage recommendation table
  md += `### Triage Recommendation\n\n`;
  md += `| Aspect | Assessment | Rationale |\n`;
  md += `|--------|-----------|----------|\n`;
  md += `| Complexity | ${t.complexity.rating} | ${t.complexity.rationale} |\n`;
  md += `| Value | ${t.value.rating} | ${t.value.rationale} |\n`;
  md += `| Risk | ${t.risk.rating} | ${t.risk.rationale} |\n`;
  md += `| Effort | ${t.effort.rating} | ${t.effort.rationale} |\n`;
  md += `| Impl. Path | ${t.implementation_path.rating} | ${t.implementation_path.rationale} |\n`;
  md += `| Priority | ${t.priority_score.score}/10 | ${t.priority_score.rationale} |\n`;
  md += `| Confidence | ${t.confidence.rating} | ${t.confidence.rationale} |\n`;

  md += `\n**Recommended Action:** ${actionEmoji} **${t.recommended_action.action}**\n\n`;
  md += `> ${t.recommended_action.rationale}\n\n`;
  md += `**Summary:** ${phase2.executive_summary}\n`;

  md += `\n---\n\n`;

  // Enrichment context (collapsible)
  md += `<details>\n<summary>:mag: Enrichment context (click to expand)</summary>\n\n`;

  if (e.documentation && e.documentation.length > 0) {
    md += `#### Related documentation\n\n`;
    for (const doc of e.documentation) {
      if (doc.url && doc.url.startsWith('http')) {
        md += `- [${doc.title}](${doc.url}) - ${doc.relevance}\n`;
      } else {
        md += `- **${doc.title}** - ${doc.relevance}\n`;
      }
    }
    md += `\n`;
  }

  if (e.ideas_portal && e.ideas_portal.length > 0) {
    md += `#### Ideas Portal & community requests\n\n`;
    for (const idea of e.ideas_portal) {
      if (idea.url && idea.url.startsWith('http')) {
        md += `- [${idea.title}](${idea.url}) - ${idea.relevance}\n`;
      } else {
        md += `- **${idea.title}** - ${idea.relevance}\n`;
      }
    }
    md += `\n`;
  }

  if (e.matched_ideas && e.matched_ideas.length > 0) {
    md += `#### Dynamics 365 Ideas Portal matches\n\n`;
    for (const idea of e.matched_ideas) {
      md += `- [${idea.title}](${idea.url}) - :thumbsup: ${idea.votes} votes (${idea.status})\n`;
    }
    md += `\n`;
  }

  if (e.ado_work_items && e.ado_work_items.length > 0) {
    md += `#### Azure DevOps related work items\n\n`;
    for (const wi of e.ado_work_items) {
      md += `- [${wi.type} #${wi.id}: ${wi.title}](${wi.url}) (${wi.state})${wi.matchReason ? ` — _${wi.matchReason}_` : ''}\n`;
    }
    md += `\n`;
  }

  if (e.marketplace && e.marketplace.searchUrl) {
    md += `#### AppSource Marketplace\n\n`;
    md += `[Search related apps](${e.marketplace.searchUrl})\n\n`;
  }

  if (e.community && e.community.length > 0) {
    md += `#### Community discussions\n\n`;
    for (const disc of e.community) {
      if (disc.url && disc.url.startsWith('http')) {
        md += `- [${disc.title}](${disc.url}) - ${disc.relevance}\n`;
      } else {
        md += `- **${disc.title}** - ${disc.relevance}\n`;
      }
    }
    md += `\n`;
  }

  if (e.code_areas && e.code_areas.length > 0) {
    md += `#### Related code areas\n\n`;
    for (const area of e.code_areas) {
      md += `- \`${area.path}\` - ${area.relevance}\n`;
    }
    md += `\n`;
  }

  if (e.analyzed_files && e.analyzed_files.length > 0) {
    md += `#### Source files analyzed\n\n`;
    md += `> ${e.analyzed_files.length} file(s) from \`${e.analyzed_directory || 'src/'}\` were provided as context for this assessment.\n\n`;
    for (const file of e.analyzed_files) {
      md += `- \`${file}\`\n`;
    }
    md += `\n`;
  }

  md += `</details>\n`;

  md += `\n---\n<sub>Was this triage helpful? React with :thumbsup: or :thumbsdown: on this comment to provide feedback.</sub>\n`;

  return truncateComment(md);
}

/**
 * Truncate comment to fit within GitHub's character limit.
 */
function truncateComment(md) {
  if (md.length <= GITHUB_COMMENT_MAX_CHARS) return md;

  const detailsStart = md.indexOf('<details>');
  const detailsEnd = md.indexOf('</details>');

  if (detailsStart !== -1 && detailsEnd !== -1) {
    const overhead = md.length - GITHUB_COMMENT_MAX_CHARS;
    const detailsContent = md.substring(detailsStart, detailsEnd + '</details>'.length);
    const truncatedDetails = detailsContent.substring(0, Math.max(200, detailsContent.length - overhead - 100))
      + '\n\n> ... enrichment context truncated to fit GitHub comment limits.\n\n</details>\n';

    const result = md.substring(0, detailsStart) + truncatedDetails + md.substring(detailsEnd + '</details>'.length);
    return result.substring(0, GITHUB_COMMENT_MAX_CHARS);
  }

  return md.substring(0, GITHUB_COMMENT_MAX_CHARS - 100) + '\n\n> ... comment truncated to fit GitHub character limit.\n';
}

/**
 * Format a comment for INSUFFICIENT issues (Phase 2 skipped).
 */
export function formatInsufficientComment(phase1, duplicates = []) {
  const qs = phase1.quality_score;

  let md = `## :robot: AI Triage Assessment\n\n`;
  md += `> Automated assessment by the Issue Triage Agent (GPT-5.4)\n`;
  md += `> Triggered by \`ai-triage\` label\n`;
  md += `\n---\n\n`;

  md += formatDuplicatesSection(duplicates);

  md += `### Issue Quality Score: ${qs.total}/100 - INSUFFICIENT\n\n`;
  md += `| Dimension | Score | Notes |\n`;
  md += `|-----------|-------|-------|\n`;
  md += `| Clarity | ${qs.clarity.score}/20 | ${qs.clarity.notes} |\n`;
  md += `| Reproducibility | ${qs.reproducibility.score}/20 | ${qs.reproducibility.notes} |\n`;
  md += `| Context | ${qs.context.score}/20 | ${qs.context.notes} |\n`;
  md += `| Specificity | ${qs.specificity.score}/20 | ${qs.specificity.notes} |\n`;
  md += `| Actionability | ${qs.actionability.score}/20 | ${qs.actionability.notes} |\n`;

  md += `\n---\n\n`;

  md += `### :stop_sign: This issue needs more information before it can be triaged\n\n`;
  md += `The following information is required to proceed:\n\n`;

  if (phase1.missing_info && phase1.missing_info.length > 0) {
    for (const item of phase1.missing_info) {
      md += `- [ ] ${item}\n`;
    }
  } else {
    md += `- [ ] Please provide a clearer description of the problem or feature request\n`;
    md += `- [ ] Add context: Business Central version, environment, and steps to reproduce\n`;
  }

  md += `\n> Once the above information is provided, add the \`ai-triage\` label again to re-run the assessment.\n`;

  md += `\n---\n<sub>Was this triage helpful? React with :thumbsup: or :thumbsdown: on this comment to provide feedback.</sub>\n`;

  return md;
}
