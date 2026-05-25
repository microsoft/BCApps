## Context

The `Paym. Prac. Dispute Ret. Data` table (689) stores narrative text fields for UK government payment practice reporting. All four large text fields are currently `Text[2048]`, and six retention-related description fields are `Text[250]`. Analysis of 2,284 real government reports shows the actual length distribution varies significantly across fields.

## Goals / Non-Goals

**Goals:**
- Right-size text fields based on empirical data from the UK government portal export.
- Reduce `Max Contr. Pmt. Period Info` and `Other Pmt. Terms Information` to `Text[1024]`.
- Increase retention narrative fields from `Text[250]` to `Text[1024]` to accommodate detailed descriptions required by 2025 regulations.

**Non-Goals:**
- Switching any field to Blob type — the plumbing cost (page variables, CalcFields, stream I/O) isn't justified.
- Changing `Standard Payment Terms Desc.` or `Dispute Resolution Process` — these stay at `Text[2048]`.
- Adding any truncation warnings or UI validation — the field lengths are the validation.

## Decisions

### 1. Keep Text[2048] for Standard Payment Terms and Dispute Resolution

**Rationale:** Real-world data shows maximums of 3,021 and 3,507 chars respectively. These already truncate edge cases. Text[2048] is the AL maximum for Text fields, so there's no better option without Blob. Blob was rejected due to complexity overhead (~50-80 lines of helper code for page binding, CSV export, and CopyFromPrevious).

**Alternative considered:** Blob with Subtype = Memo — provides unlimited length but requires page variable indirection, CalcFields calls in CSV export, and stream-copy logic in CopyFromPrevious. Not worth it for <0.5% truncation on data users type manually in BC.

### 2. Reduce two fields to Text[1024]

**Rationale:**
- `Max Contr. Pmt. Period Info`: real max = 802, P99 = 611. Text[1024] covers 100% of observed data with headroom.
- `Other Pmt. Terms Information`: real max = 1,680, P99 = 1,009. Text[1024] covers >99% of reports. The 0.2% exceeding 1,024 are extreme outliers from the government portal (not manually typed in BC).

### 3. Increase retention Text[250] fields to Text[1024]

**Rationale:** The 2025 retention requirements are new — no historical data exists. The UK government guidance asks for detailed narrative descriptions (specific circumstances, release mechanisms, parity policies, staged release descriptions). Text[250] is tight for multi-sentence descriptions. Text[1024] provides comfortable headroom while staying well under the 2048 maximum.

**Fields affected:** `Retention Circs. Desc.`, `Terms Fairness Desc.`, `Release Mechanism Desc.`, `Prescribed Days Desc.`, `Standard Payment Terms Desc.` (already 2048, no change), and `Max Contr. Pmt. Period Info` (covered above).

## Risks / Trade-offs

- **[Truncation of Other Pmt. Terms Information]** → 0.2% of government portal reports exceed 1,024 chars (max 1,680). Acceptable because BC users type this manually rather than importing from the portal. If future CSV import is added, import logic should handle truncation.
- **[Over-sizing retention fields]** → Increasing from 250 to 1024 uses more potential storage per row. Negligible impact since SQL Server stores only actual content length for variable-length columns, and these records number in the low hundreds per company.
