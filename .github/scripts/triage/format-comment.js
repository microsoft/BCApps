// Comment formatting for triage assessments
// See: docs/features/issue-triage-agent/design.md (FR18)

const ACTION_EMOJI = {
  'Implement': ':white_check_mark:',
  'Defer': ':hourglass_flowing_sand:',
  'Investigate': ':mag:',
  'Reject': ':x:',
};

/**
 * Format the full triage comment (Phase 1 + Phase 2 results).
 */
export function formatTriageComment(phase1, phase2, isRetriage) {
  const qs = phase1.quality_score;
  const t = phase2.triage;
  const e = phase2.enrichment;
  const actionEmoji = ACTION_EMOJI[t.recommended_action?.action] || ':question:';

  let md = `## :robot: AI Triage Assessment\n\n`;
  md += `> Automated assessment by the Issue Triage Agent (GPT-5.4)\n`;
  md += `> Triggered by \`ai-triage\` label\n`;

  if (isRetriage) {
    md += `> :arrows_counterclockwise: **Re-triage** - see earlier assessment comments for history.\n`;
  }

  md += `\n---\n\n`;

  // Quality score table
  md += `### Issue Quality Score: ${qs.total}/100 - ${phase1.verdict}\n\n`;
  md += `| Dimension | Score | Notes |\n`;
  md += `|-----------|-------|-------|\n`;
  md += `| Clarity | ${qs.clarity.score}/20 | ${qs.clarity.notes} |\n`;
  md += `| Reproducibility | ${qs.reproducibility.score}/20 | ${qs.reproducibility.notes} |\n`;
  md += `| Context | ${qs.context.score}/20 | ${qs.context.notes} |\n`;
  md += `| Specificity | ${qs.specificity.score}/20 | ${qs.specificity.notes} |\n`;
  md += `| Actionability | ${qs.actionability.score}/20 | ${qs.actionability.notes} |\n`;

  // Missing info (if any)
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
      md += `- [${wi.type} #${wi.id}: ${wi.title}](${wi.url}) (${wi.state})\n`;
    }
    md += `\n`;
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

  return md;
}

/**
 * Format a comment for INSUFFICIENT issues (Phase 2 skipped).
 */
export function formatInsufficientComment(phase1) {
  const qs = phase1.quality_score;

  let md = `## :robot: AI Triage Assessment\n\n`;
  md += `> Automated assessment by the Issue Triage Agent (GPT-5.4)\n`;
  md += `> Triggered by \`ai-triage\` label\n`;
  md += `\n---\n\n`;

  // Quality score table
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

  return md;
}
