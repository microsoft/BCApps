## 1. Table Field Reordering

- [x] 1.1 Keep fields 1-12 in their current declaration order (these are original fields — do not move them)
- [x] 1.2 Reorder field declarations for fields 15+ in `Payment Practice Header` (Table 687) to match CSV-column-aligned groups: Reporting Config (15-16) → Payment Statistics GB (20-23) → Payment Policies (34, 30-33) → Retention (40-58) → Qualifying Contracts (60-62) → Payment Terms (63-70) → Dispute Resolution (71) → Retention Std Terms (72-73)
- [x] 1.3 Within Retention group, reorder fields to CSV-column order: 40, 41, 72, 42, 43, 44, 45, 73, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58
- [x] 1.4 Within Payment Policies group, reorder so Is Payment Code Member (34) comes before Offers E-Invoicing (30), Offers Supply Chain Finance (31), Policy Covers Deduct. Charges (32), Has Deducted Charges in Period (33)

## 2. Page Group Reordering

- [x] 2.1 Keep existing groups (General, Payment Statistics) in their original positions; add new "Qualifying Contracts" group immediately after "Payment Statistics" (do not move existing groups)
- [x] 2.2 Merge "Statistics" and "Payment Statistics" groups into a single "Payment Statistics" group; common stats always visible, Dispute & Retention totals conditionally visible
- [x] 2.3 Move "Dispute Resolution Process" field out of "Payment Policies" into a new "Dispute Resolution" group positioned between "Construction Contract Retention" and "Payment Policies"
- [x] 2.4 Reorder fields in "Payment Policies" group: Is Payment Code Member first, then Offers E-Invoicing, Offers Supply Chain Finance, Policy Covers Deduct. Charges, Has Deducted Charges in Period
- [x] 2.5 Move "Payment Policies" group to appear after the new "Dispute Resolution" group (last data group before Lines)

## 3. Verification

- [x] 3.1 Verify field IDs are unchanged by comparing before/after field-ID lists
- [x] 3.2 Build the app to confirm no compile errors
