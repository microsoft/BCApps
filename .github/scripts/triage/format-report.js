// Full triage report formatting for GitHub Wiki pages
// Structured for quick PM scanning: TL;DR first, details on demand.

import { formatDuplicatesSection } from './duplicate-detector.js';
import { formatPrecedentsSection } from './precedent-finder.js';
import { escapeMdTable } from './phase2-enrich.js';

const ACTION_EMOJI = {
  'Implement': ':white_check_mark:',
  'Defer': ':hourglass_flowing_sand:',
  'Investigate': ':mag:',
  'Reject': ':x:',
};

/** Color-coded dot for a Low/Medium/High-style rating (green=good, red=bad). */
function ratingDot(rating) {
  const r = (rating || '').toLowerCase();
  if (['low', 'xs', 's', 'xs-s'].includes(r)) return ':green_circle:';
  if (['medium', 'm'].includes(r)) return ':yellow_circle:';
  return ':red_circle:'; // High, Very High, L, XL, L-XL
}

/** Color-coded dot for priority score (inverted — high priority = red = urgent). */
function priorityDot(score) {
  if (score >= 8) return ':red_circle:';
  if (score >= 5) return ':yellow_circle:';
  return ':green_circle:';
}

/** Color-coded dot for confidence (green=high confidence). */
function confidenceDot(rating) {
  const r = (rating || '').toLowerCase();
  if (r === 'high') return ':green_circle:';
  if (r === 'medium') return ':yellow_circle:';
  return ':red_circle:';
}

/**
 * Format the full triage report for a GitHub Wiki page.
 */
export function formatWikiReport(phase1, phase2, isRetriage, duplicates, previousScores, issueMeta, precedents = []) {
  const qs = phase1.quality_score;
  const t = phase2.triage;
  const e = phase2.enrichment;
  const actionEmoji = ACTION_EMOJI[t.recommended_action?.action] || ':question:';

  let md = `# Issue #${issueMeta.number}: ${issueMeta.title}\n\n`;

  // ── TL;DR ──
  md += `${actionEmoji} **${t.recommended_action.action}** — ${phase2.executive_summary}\n\n`;

  md += `${priorityDot(t.priority_score.score)} Priority **${t.priority_score.score}/10** · ${ratingDot(t.complexity.rating)} Complexity **${t.complexity.rating}** · ${ratingDot(t.effort.rating)} Effort **${t.effort.rating}** · ${ratingDot(t.risk.rating)} Risk **${t.risk.rating}** · :compass: Path **${t.implementation_path.rating}** · ${confidenceDot(t.confidence.rating)} Confidence **${t.confidence.rating}**\n\n`;

  md += `> **Type:** ${phase1.issue_type} | **Quality:** ${qs.total}/100 (${phase1.verdict}) | **Author:** @${issueMeta.author} | **Date:** ${new Date().toISOString().split('T')[0]} | [View issue](${issueMeta.url})\n`;

  if (isRetriage) {
    md += `> :arrows_counterclockwise: **Re-triage** — see earlier versions in wiki history.\n`;
  }

  md += `\n`;

  // ── Action rationale (visible — the "why" behind the recommendation) ──
  md += `> ${actionEmoji} **Why ${t.recommended_action.action}?** ${t.recommended_action.rationale}\n\n`;

  // ── Duplicates (if any, shown prominently) ──
  md += formatDuplicatesSection(duplicates);

  // ── Precedents (similar resolved issues) ──
  md += formatPrecedentsSection(precedents);

  // ── Missing info (if any, shown prominently) ──
  if (phase1.missing_info && phase1.missing_info.length > 0) {
    md += `### :warning: Information needed\n\n`;
    for (const item of phase1.missing_info) {
      md += `- [ ] ${item}\n`;
    }
    md += `\n`;
  }

  md += `---\n\n`;

  // ── Full triage rationale (collapsible — all 7 aspects with rationales) ──
  md += `<details>\n<summary><strong>Full triage rationale</strong> — all assessment aspects</summary>\n\n`;

  md += `| Aspect | Assessment | Rationale |\n`;
  md += `|--------|-----------|----------|\n`;
  md += `| Complexity | ${t.complexity.rating} | ${escapeMdTable(t.complexity.rationale)} |\n`;
  md += `| Value | ${t.value.rating} | ${escapeMdTable(t.value.rationale)} |\n`;
  md += `| Risk | ${t.risk.rating} | ${escapeMdTable(t.risk.rationale)} |\n`;
  md += `| Effort | ${t.effort.rating} | ${escapeMdTable(t.effort.rationale)} |\n`;
  md += `| Impl. Path | ${t.implementation_path.rating} | ${escapeMdTable(t.implementation_path.rationale)} |\n`;
  md += `| Priority | ${t.priority_score.score}/10 | ${escapeMdTable(t.priority_score.rationale)} |\n`;
  md += `| Confidence | ${t.confidence.rating} | ${escapeMdTable(t.confidence.rationale)} |\n`;

  md += `\n</details>\n\n`;

  // ── Quality breakdown (collapsible) ──
  md += `<details>\n<summary><strong>Quality breakdown</strong> — ${qs.total}/100 (${phase1.verdict})</summary>\n\n`;

  md += `| Dimension | Score | Notes |\n`;
  md += `|-----------|-------|-------|\n`;
  md += `| Clarity | ${qs.clarity.score}/20 | ${escapeMdTable(qs.clarity.notes)} |\n`;
  md += `| Reproducibility | ${qs.reproducibility.score}/20 | ${escapeMdTable(qs.reproducibility.notes)} |\n`;
  md += `| Context | ${qs.context.score}/20 | ${escapeMdTable(qs.context.notes)} |\n`;
  md += `| Specificity | ${qs.specificity.score}/20 | ${escapeMdTable(qs.specificity.notes)} |\n`;
  md += `| Actionability | ${qs.actionability.score}/20 | ${escapeMdTable(qs.actionability.notes)} |\n`;

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
  const hasEnrichment = (e.learn_articles?.length > 0) ||
    (e.ideas_portal?.length > 0) || (e.matched_ideas?.length > 0) ||
    (e.ado_work_items?.length > 0) || (e.related_prs?.length > 0) ||
    (e.community_discussions?.length > 0) ||
    (e.marketplace?.ecosystem?.density !== 'Unknown') || (e.marketplace?.searchUrl) ||
    (e.youtube_videos?.length > 0) ||
    (e.competitive_landscape && e.competitive_landscape.position !== 'Unknown') ||
    (e.code_areas?.length > 0) || (e.git_history?.totalCommits > 0);

  if (hasEnrichment) {
    md += `<details>\n<summary><strong>Enrichment context</strong> — external sources and references</summary>\n\n`;

    if (e.learn_articles && e.learn_articles.length > 0) {
      md += `#### Microsoft Learn\n`;
      md += `_Documentation confirmed relevant to this issue by LLM analysis._\n\n`;
      for (const doc of e.learn_articles) {
        md += `- [${doc.title}](${doc.url}) — ${doc.relevance}\n`;
      }
      md += `\n`;
    }

    if ((e.ideas_portal && e.ideas_portal.length > 0) || (e.matched_ideas && e.matched_ideas.length > 0)) {
      md += `#### Ideas Portal\n`;
      if (e.matched_ideas && e.matched_ideas.length > 0) {
        for (const idea of e.matched_ideas) {
          md += `- [${idea.title}](${idea.url}) — :thumbsup: ${idea.votes} votes (${idea.status})`;
          if (idea.relevance) md += ` — ${idea.relevance}`;
          md += `\n`;
        }
      }
      if (e.ideas_portal && e.ideas_portal.length > 0) {
        for (const idea of e.ideas_portal) {
          // Skip LLM-suggested ideas that duplicate a matched idea by title
          const isDuplicate = e.matched_ideas?.some(m => m.title.toLowerCase() === (idea.title || '').toLowerCase());
          if (isDuplicate) continue;
          if (idea.url && idea.url.startsWith('http')) {
            md += `- [${idea.title}](${idea.url}) — ${idea.relevance}\n`;
          } else {
            md += `- **${idea.title}** — ${idea.relevance}\n`;
          }
        }
      }
      md += `\n`;
    }

    if (e.ado_work_items && e.ado_work_items.length > 0) {
      md += `#### ADO work items\n`;
      for (const wi of e.ado_work_items) {
        const reason = wi.relevance || wi.matchReason;
        md += `- [${wi.type} #${wi.id}: ${wi.title}](${wi.url}) (${wi.state})${reason ? ` — _${reason}_` : ''}\n`;
      }
      md += `\n`;
    }

    if (e.related_prs && e.related_prs.length > 0) {
      md += `#### Related pull requests\n`;
      for (const pr of e.related_prs) {
        md += `- [#${pr.number}: ${pr.title}](${pr.url}) (${pr.state}) by @${pr.author}`;
        if (pr.matchReason) md += ` — _${pr.matchReason}_`;
        md += `\n`;
      }
      md += `\n`;
    }

    if (e.marketplace && (e.marketplace.ecosystem?.density !== 'Unknown' || e.marketplace.searchUrl)) {
      md += `#### Marketplace Ecosystem\n`;
      md += `_Third-party app density: signals whether partners actively build solutions in this area._\n\n`;
      if (e.marketplace.ecosystem && e.marketplace.ecosystem.density !== 'Unknown') {
        md += `**${e.marketplace.ecosystem.density}** — ${e.marketplace.ecosystem.rationale}\n\n`;
      }
      if (e.marketplace.searchUrl) {
        md += `[Search related apps on Marketplace](${e.marketplace.searchUrl})\n\n`;
      }
    }

    if (e.competitive_landscape && e.competitive_landscape.position !== 'Unknown') {
      md += `#### Competitive Landscape\n`;
      md += `_Market positioning: how this capability compares across competing ERP platforms._\n\n`;
      md += `**${e.competitive_landscape.position}** — ${e.competitive_landscape.rationale}\n\n`;
    }

    if ((e.community_discussions && e.community_discussions.length > 0) || e.community_search_url) {
      md += `#### Community discussions\n`;
      md += `_Discussions confirmed relevant to this issue by LLM analysis._\n\n`;
      if (e.community_discussions && e.community_discussions.length > 0) {
        for (const d of e.community_discussions) {
          md += `- [${d.title}](${d.url})`;
          if (d.source) md += ` (${d.source})`;
          if (d.views > 0) md += ` · ${d.views} views, ${d.replies} replies`;
          md += ` — ${d.relevance}\n`;
        }
      }
      if (e.community_search_url) {
        md += `- [Search Microsoft Dynamics Community](${e.community_search_url})\n`;
      }
      md += `\n`;
    }

    if (e.youtube_videos && e.youtube_videos.length > 0) {
      md += `#### YouTube videos\n`;
      for (const v of e.youtube_videos) {
        const reason = v.relevance || v.matchReason;
        md += `- [${v.title}](${v.url}) by ${v.channelTitle}`;
        if (v.publishedAt) md += ` (${v.publishedAt})`;
        if (reason) md += ` — _${reason}_`;
        md += `\n`;
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

    if (e.git_history && e.git_history.totalCommits > 0) {
      md += `#### Git history (last 3 months)\n`;
      md += `${e.git_history.totalCommits} commits in this area.\n\n`;
      if (e.git_history.topChangedFiles?.length > 0) {
        md += `**Most changed files:** `;
        md += e.git_history.topChangedFiles.slice(0, 5).map(f => `\`${f.path}\` (${f.changeCount})`).join(', ');
        md += `\n\n`;
      }
      if (e.git_history.topContributors?.length > 0) {
        md += `**Active contributors:** `;
        md += e.git_history.topContributors.map(c => `${c.name} (${c.commits})`).join(', ');
        md += `\n\n`;
      }
      if (e.git_history.keywordCommits?.length > 0) {
        md += `**Keyword-matching commits:**\n`;
        for (const c of e.git_history.keywordCommits.slice(0, 5)) {
          md += `- \`${c.hash}\` ${c.date} — ${c.subject}\n`;
        }
        md += `\n`;
      }
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

  md += `---\n<sub>Was this triage helpful? React with :thumbsup: or :thumbsdown: on the [issue comment](${issueMeta.url}) to provide feedback.</sub>\n\n`;
  md += `---\n`;
  md += `> Generated by the Issue Triage Agent (GPT-5.4) | [Back to issue](${issueMeta.url})\n`;

  return md;
}
