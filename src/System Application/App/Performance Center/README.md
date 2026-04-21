# Performance Center

One-stop hub for troubleshooting Business Central performance problems.

The module has two flavors on the same page:

- **Simple** — a normal user describes a slow scenario in a wizard ("it is slow
  when I press *Post* on a sales order, it happens every time, it should take a
  second but takes twenty"). The Performance Center creates a
  *Performance Analysis* record and a matching *Performance Profile Scheduler*
  to capture data.
- **Advanced** — a technical user sees active profilers, missing index hints,
  recent analyses across users, and can drill from any analysis down to the
  captured profiles.

## Lifecycle

```
Requested  ->  Scheduled  ->  Capturing  ->  CaptureEnded  ->  AiFiltering
    ->  AiAnalyzing  ->  Concluded
(+ Cancelled / Failed)
```

The user can `Stop Capture` at any time from the Analysis card. After the
capture ends, the AI filters the captured profiles down to the relevant set
(with a score + reason per profile) and then produces a narrative conclusion
based on those profiles.

## AI dependency

All AI-driven actions — AI filtering, AI analysis and the post-analysis chat
— run through a single Copilot capability named
**"AI-assisted performance analysis in Performance Center"**. When the
capability is inactive, those actions are greyed out with an inline hint.
Scheduling and browsing captured profiles keep working without AI, so data
is not lost.

## Post-analysis chat

Once the state is `Concluded` the Analysis card shows a prominent action
**"Click here to chat with the analysis report"** that opens a
`PromptDialog` page primed with the conclusion and the top findings, so the
user can ask follow-up questions.

## Chat-based request (preview stub)

A separate page `Perf. Analysis Chat Req. Stub` illustrates how the
request experience could be driven by a Copilot chat instead of a wizard.
It is intentionally non-functional in this iteration; the wizard is the
supported request entry point.
