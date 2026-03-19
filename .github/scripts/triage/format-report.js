// Full triage report formatting for GitHub Wiki pages
// Structured for quick PM scanning: TL;DR first, details on demand.

import { formatDuplicatesSection } from './duplicate-detector.js';

const ACTION_EMOJI = {
  'Implement': ':white_check_mark:',
  'Defer': ':hourglass_flowing_sand:',
  'Investigate': ':mag:',
  'Reject': ':x:',
};

/**
 * Format the full triage report for a GitHub Wiki page.
 */
export function formatWikiReport(phase1, phase2, isRetriage, duplicates, previousScores, issueMeta) {
  const qs = phase1.quality_score;
  const t = phase2.triage;
  const e = phase2.enrichment;
  const actionEmoji = ACTION_EMOJI[t.recommended_action?.action] || ':question:';

  let md = `# Issue #${issueMeta.number}: ${issueMeta.title}\n\n`;

  // ── TL;DR ──
  md += `${actionEmoji} **${t.recommended_action.action}** — ${phase2.executive_summary}\n\n`;

  md += `| Quality | Priority | Complexity | Effort | Risk | Path | Confidence |\n`;
  md += `|---------|----------|------------|--------|------|------|------------|\n`;
  md += `| ${qs.total}/100 (${phase1.verdict}) | ${t.priority_score.score}/10 | ${t.complexity.rating} | ${t.effort.rating} | ${t.risk.rating} | ${t.implementation_path.rating} | ${t.confidence.rating} |\n`;

  md += `\n`;
  md += `> **Type:** ${phase1.issue_type} | **Author:** @${issueMeta.author} | **Date:** ${new Date().toISOString().split('T')[0]} | [View issue](${issueMeta.url})\n`;

  if (isRetriage) {
    md += `> :arrows_counterclockwise: **Re-triage** — see earlier versions in wiki history.\n`;
  }

  md += `\n`;

  // ── Duplicates (if any, shown prominently) ──
  md += formatDuplicatesSection(duplicates);

  // ── Missing info (if any, shown prominently) ──
  if (phase1.missing_info && phase1.missing_info.length > 0) {
    md += `### :warning: Information needed\n\n`;
    for (const item of phase1.missing_info) {
      md += `- [ ] ${item}\n`;
    }
    md += `\n`;
  }

  md += `---\n\n`;

  // ── Triage rationale (collapsible) ──
  md += `<details>\n<summary><strong>Triage rationale</strong> — why ${t.recommended_action.action}?</summary>\n\n`;

  md += `| Aspect | Assessment | Rationale |\n`;
  md += `|--------|-----------|----------|\n`;
  md += `| Complexity | ${t.complexity.rating} | ${t.complexity.rationale} |\n`;
  md += `| Value | ${t.value.rating} | ${t.value.rationale} |\n`;
  md += `| Risk | ${t.risk.rating} | ${t.risk.rationale} |\n`;
  md += `| Effort | ${t.effort.rating} | ${t.effort.rationale} |\n`;
  md += `| Impl. Path | ${t.implementation_path.rating} | ${t.implementation_path.rationale} |\n`;
  md += `| Priority | ${t.priority_score.score}/10 | ${t.priority_score.rationale} |\n`;
  md += `| Confidence | ${t.confidence.rating} | ${t.confidence.rationale} |\n`;

  md += `\n> ${t.recommended_action.rationale}\n\n`;
  md += `</details>\n\n`;

  // ── Quality breakdown (collapsible) ──
  md += `<details>\n<summary><strong>Quality breakdown</strong> — ${qs.total}/100 (${phase1.verdict})</summary>\n\n`;

  md += `| Dimension | Score | Notes |\n`;
  md += `|-----------|-------|-------|\n`;
  md += `| Clarity | ${qs.clarity.score}/20 | ${qs.clarity.notes} |\n`;
  md += `| Reproducibility | ${qs.reproducibility.score}/20 | ${qs.reproducibility.notes} |\n`;
  md += `| Context | ${qs.context.score}/20 | ${qs.context.notes} |\n`;
  md += `| Specificity | ${qs.specificity.score}/20 | ${qs.specificity.notes} |\n`;
  md += `| Actionability | ${qs.actionability.score}/20 | ${qs.actionability.notes} |\n`;

  // Re-triage comparison
  if (isRetriage && previousScores) {
    md += `\n#### Changes since last triage\n\n`;
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
  }

  md += `\n</details>\n\n`;

  // ── Enrichment context (collapsible) ──
  const hasEnrichment = (e.documentation?.length > 0) || (e.ideas_portal?.length > 0) ||
    (e.matched_ideas?.length > 0) || (e.ado_work_items?.length > 0) ||
    (e.community?.length > 0) || (e.marketplace?.searchUrl) ||
    (e.code_areas?.length > 0);

  if (hasEnrichment) {
    md += `<details>\n<summary><strong>Enrichment context</strong> — external sources and references</summary>\n\n`;

    if (e.documentation && e.documentation.length > 0) {
      md += `#### Documentation\n`;
      for (const doc of e.documentation) {
        if (doc.url && doc.url.startsWith('http')) {
          md += `- [${doc.title}](${doc.url}) — ${doc.relevance}\n`;
        } else {
          md += `- **${doc.title}** — ${doc.relevance}\n`;
        }
      }
      md += `\n`;
    }

    if (e.ideas_portal && e.ideas_portal.length > 0) {
      md += `#### Ideas Portal\n`;
      for (const idea of e.ideas_portal) {
        if (idea.url && idea.url.startsWith('http')) {
          md += `- [${idea.title}](${idea.url}) — ${idea.relevance}\n`;
        } else {
          md += `- **${idea.title}** — ${idea.relevance}\n`;
        }
      }
      md += `\n`;
    }

    if (e.matched_ideas && e.matched_ideas.length > 0) {
      md += `#### Ideas Portal matches\n`;
      for (const idea of e.matched_ideas) {
        md += `- [${idea.title}](${idea.url}) — :thumbsup: ${idea.votes} votes (${idea.status})\n`;
      }
      md += `\n`;
    }

    if (e.ado_work_items && e.ado_work_items.length > 0) {
      md += `#### ADO work items\n`;
      for (const wi of e.ado_work_items) {
        md += `- [${wi.type} #${wi.id}: ${wi.title}](${wi.url}) (${wi.state})${wi.matchReason ? ` — _${wi.matchReason}_` : ''}\n`;
      }
      md += `\n`;
    }

    if (e.marketplace && e.marketplace.searchUrl) {
      md += `#### AppSource\n`;
      md += `[Search related apps](${e.marketplace.searchUrl})\n\n`;
    }

    if (e.community && e.community.length > 0) {
      md += `#### Community\n`;
      for (const disc of e.community) {
        if (disc.url && disc.url.startsWith('http')) {
          md += `- [${disc.title}](${disc.url}) — ${disc.relevance}\n`;
        } else {
          md += `- **${disc.title}** — ${disc.relevance}\n`;
        }
      }
      md += `\n`;
    }

    if (e.code_areas && e.code_areas.length > 0) {
      md += `#### Code areas\n`;
      for (const area of e.code_areas) {
        md += `- \`${area.path}\` — ${area.relevance}\n`;
      }
      md += `\n`;
    }

    md += `</details>\n\n`;
  }

  // ── Source files (collapsible) ──
  if (e.analyzed_files && e.analyzed_files.length > 0) {
    md += `<details>\n<summary><strong>Source files analyzed</strong> — ${e.analyzed_files.length} file(s) from <code>${e.analyzed_directory || 'src/'}</code></summary>\n\n`;
    for (const file of e.analyzed_files) {
      md += `- \`${file}\`\n`;
    }
    md += `\n</details>\n\n`;
  }

  md += `---\n`;
  md += `> Generated by the Issue Triage Agent (GPT-5.4) | [Back to issue](${issueMeta.url})\n`;

  return md;
}
