# MLLM V2 Agentic Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-pass MLLM extraction with an agentic plan-act-verify loop where the model identifies document structure, extracts from identified regions, and self-corrects by calling AL-implemented verification tools.

**Architecture:** One agentic AOAI call loop (GPT-4.1 Mini) with 6 verification tools registered as AOAI Functions. The model plans (chain-of-thought), extracts, calls verify tools, sees failures with error details, corrects, and repeats. AL drives the tool dispatch loop; the model decides when to call what. New handler registered as `"MLLM V2"` enum value alongside V1.

**Tech Stack:** AL (Business Central), System.AI (AOAI SDK), `AOAI Function` interface for tool adapters, `AOAIChatMessages.AddTool()` + `AppendFunctionResponsesToChatMessages()` for the loop.

---

## File Map

| Action | Path | ID | Responsibility |
|--------|------|----|----------------|
| Modify | `App/src/Processing/Import/StructureReceivedEDoc.Enum.al` | enum 6103 | Add `"MLLM V2"` value |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyTools.Codeunit.al` | 6233 | All 6 verification logic methods |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyLineMathTool.Codeunit.al` | 6235 | `verify_line_math` AOAI Function adapter |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyTotalsTool.Codeunit.al` | 6236 | `verify_invoice_totals` AOAI Function adapter |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyVATTool.Codeunit.al` | 6237 | `verify_vat` AOAI Function adapter |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyDatesTool.Codeunit.al` | 6238 | `verify_dates` AOAI Function adapter |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyRequiredTool.Codeunit.al` | 6239 | `verify_required_fields` AOAI Function adapter |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyRangesTool.Codeunit.al` | 6243 | `verify_ranges` AOAI Function adapter |
| Create | `App/.resources/Prompts/EDocMLLMExtractionV2-SystemPrompt.md` | — | Three-section V2 system prompt |
| Create | `App/src/Processing/Import/StructureReceivedEDocument/EDocumentMLLMHandlerV2.Codeunit.al` | 6244 | V2 handler: agentic loop + interface impl |
| Create | `Test/src/Processing/EDocMLLMVerifyToolsTests.Codeunit.al` | 135648 | Unit tests for all 6 verify methods |

All paths are relative to `src/Apps/W1/EDocument/`.

---

## Task 1: Register the "MLLM V2" enum value

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/StructureReceivedEDoc.Enum.al`

- [ ] **Step 1: Add enum value**

Open the file. After the `"MLLM"` value (value 3), add:

```al
    value(4; "MLLM V2")
    {
        Caption = 'MLLM Extraction V2';
        Implementation = IStructureReceivedEDocument = "E-Document MLLM Handler V2";
    }
```

The handler codeunit name `"E-Document MLLM Handler V2"` will be created in Task 5.

- [ ] **Step 2: Verify file compiles**

The file will not compile until Task 5 creates the referenced codeunit. That is expected — this step just records the intent. Come back and verify compilation after Task 5.

---

## Task 2: Create EDocMLLMVerifyTools with unit tests

The core verification logic. No AOAI calls — pure math and validation. Test this codeunit thoroughly before building the tool adapters on top.

**Files:**
- Create: `src/Apps/W1/EDocument/App/src/Processing/Import/StructureReceivedEDocument/EDocMLLMVerifyTools.Codeunit.al`
- Create: `src/Apps/W1/EDocument/Test/src/Processing/EDocMLLMVerifyToolsTests.Codeunit.al`

- [ ] **Step 1: Create the stub codeunit**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

codeunit 6233 "E-Doc. MLLM Verify Tools"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Checks unit_price × quantity × (1 − discount_pct/100) ≈ line_extension_amount within 1%.
    /// Returns false and sets ErrorText when the check fails.
    /// </summary>
    procedure VerifyLineMath(UnitPrice: Decimal; Quantity: Decimal; DiscountPct: Decimal; LineExtensionAmount: Decimal; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    /// <summary>
    /// Checks sum(LineAmounts) ≈ TaxExclusiveAmount within 1%.
    /// </summary>
    procedure VerifyInvoiceTotals(LineAmounts: List of [Decimal]; TaxExclusiveAmount: Decimal; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    /// <summary>
    /// Checks TaxExclusiveAmount × VATRate/100 ≈ TaxAmount within 1%.
    /// </summary>
    procedure VerifyVAT(TaxExclusiveAmount: Decimal; VATRate: Decimal; TaxAmount: Decimal; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    /// <summary>
    /// Validates issue_date and due_date are parseable XML dates, year 1900-2100, due_date >= issue_date.
    /// </summary>
    procedure VerifyDates(IssueDateText: Text; DueDateText: Text; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    /// <summary>
    /// Checks VendorName, InvoiceNo are non-empty and LineCount > 0.
    /// </summary>
    procedure VerifyRequiredFields(VendorName: Text; InvoiceNo: Text; LineCount: Integer; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    /// <summary>
    /// Checks quantities and prices > 0, VAT rates and discount percentages 0-100.
    /// Stops at first violation and reports the line index.
    /// </summary>
    procedure VerifyRanges(Quantities: List of [Decimal]; Prices: List of [Decimal]; VATRates: List of [Decimal]; DiscountPcts: List of [Decimal]; var ErrorText: Text): Boolean
    begin
        exit(false); // stub
    end;

    internal procedure IsWithinTolerance(Expected: Decimal; Actual: Decimal): Boolean
    var
        Denominator: Decimal;
    begin
        Denominator := Abs(Actual);
        if Denominator < 1 then
            Denominator := 1;
        exit(Abs(Expected - Actual) / Denominator < 0.01);
    end;
}
```

- [ ] **Step 2: Write the test codeunit**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;

codeunit 135648 "EDoc MLLM Verify Tools Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    // VerifyLineMath -----------------------------------------------------------

    [Test]
    procedure VerifyLineMath_Pass_NoDiscount()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // 5 × 40 × 1.00 = 200
        Assert.IsTrue(VerifyTools.VerifyLineMath(40, 5, 0, 200, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyLineMath_Pass_WithDiscount()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // 3.65 × 1083 × 0.64 = 2529.888 ≈ 2529.89
        Assert.IsTrue(VerifyTools.VerifyLineMath(3.65, 1083, 36, 2529.89, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyLineMath_Pass_WithinOnePct()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // Expected = 100, actual = 100.9 — within 1%
        Assert.IsTrue(VerifyTools.VerifyLineMath(10, 10, 0, 100.9, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyLineMath_Fail_WrongPrice()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // net price 2.34 used instead of gross 3.65 with 20% discount → expected 2027, actual 2529
        Assert.IsFalse(VerifyTools.VerifyLineMath(2.34, 1083, 20, 2529.89, ErrorText), 'Should fail');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be set');
    end;

    [Test]
    procedure VerifyLineMath_Pass_ZeroLineAmount()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // Zero line amount — skip check (freight lines sometimes have zero amount)
        Assert.IsTrue(VerifyTools.VerifyLineMath(0, 0, 0, 0, ErrorText), ErrorText);
    end;

    // VerifyInvoiceTotals ------------------------------------------------------

    [Test]
    procedure VerifyInvoiceTotals_Pass()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        Lines: List of [Decimal];
        ErrorText: Text;
    begin
        Lines.Add(200);
        Lines.Add(30);
        Lines.Add(20);
        Assert.IsTrue(VerifyTools.VerifyInvoiceTotals(Lines, 250, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyInvoiceTotals_Fail_MissingLine()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        Lines: List of [Decimal];
        ErrorText: Text;
    begin
        Lines.Add(200);
        // missing 30 + 20
        Assert.IsFalse(VerifyTools.VerifyInvoiceTotals(Lines, 250, ErrorText), 'Should fail');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be set');
    end;

    // VerifyVAT ----------------------------------------------------------------

    [Test]
    procedure VerifyVAT_Pass()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // 250 × 15% = 37.5
        Assert.IsTrue(VerifyTools.VerifyVAT(250, 15, 37.5, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyVAT_Fail()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyVAT(250, 15, 100, ErrorText), 'Should fail');
    end;

    [Test]
    procedure VerifyVAT_Skip_ZeroTax()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        // tax_amount = 0 means zero-rated — skip check
        Assert.IsTrue(VerifyTools.VerifyVAT(250, 0, 0, ErrorText), ErrorText);
    end;

    // VerifyDates --------------------------------------------------------------

    [Test]
    procedure VerifyDates_Pass_ValidDates()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsTrue(VerifyTools.VerifyDates('2024-03-15', '2024-04-15', ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyDates_Pass_NoDueDate()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsTrue(VerifyTools.VerifyDates('2024-03-15', '', ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyDates_Fail_DueDateBeforeIssue()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyDates('2024-04-15', '2024-03-15', ErrorText), 'Should fail');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be set');
    end;

    [Test]
    procedure VerifyDates_Fail_InvalidDate()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyDates('not-a-date', '', ErrorText), 'Should fail');
    end;

    [Test]
    procedure VerifyDates_Fail_MissingIssueDate()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyDates('', '', ErrorText), 'Should fail');
    end;

    // VerifyRequiredFields -----------------------------------------------------

    [Test]
    procedure VerifyRequiredFields_Pass()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsTrue(VerifyTools.VerifyRequiredFields('Contoso Ltd', 'INV-001', 2, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyRequiredFields_Fail_MissingVendor()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyRequiredFields('', 'INV-001', 2, ErrorText), 'Should fail');
        Assert.IsSubstring(ErrorText, 'vendor');
    end;

    [Test]
    procedure VerifyRequiredFields_Fail_NoLines()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
    begin
        Assert.IsFalse(VerifyTools.VerifyRequiredFields('Contoso Ltd', 'INV-001', 0, ErrorText), 'Should fail');
        Assert.IsSubstring(ErrorText, 'line');
    end;

    // VerifyRanges -------------------------------------------------------------

    [Test]
    procedure VerifyRanges_Pass()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        Qtys: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscPcts: List of [Decimal];
        ErrorText: Text;
    begin
        Qtys.Add(5); Prices.Add(40); VATRates.Add(15); DiscPcts.Add(0);
        Assert.IsTrue(VerifyTools.VerifyRanges(Qtys, Prices, VATRates, DiscPcts, ErrorText), ErrorText);
    end;

    [Test]
    procedure VerifyRanges_Fail_NegativeQty()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        Qtys: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscPcts: List of [Decimal];
        ErrorText: Text;
    begin
        Qtys.Add(-1); Prices.Add(40); VATRates.Add(15); DiscPcts.Add(0);
        Assert.IsFalse(VerifyTools.VerifyRanges(Qtys, Prices, VATRates, DiscPcts, ErrorText), 'Should fail');
        Assert.IsSubstring(ErrorText, 'quantity');
    end;

    [Test]
    procedure VerifyRanges_Fail_DiscountOver100()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        Qtys: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscPcts: List of [Decimal];
        ErrorText: Text;
    begin
        Qtys.Add(5); Prices.Add(40); VATRates.Add(15); DiscPcts.Add(150);
        Assert.IsFalse(VerifyTools.VerifyRanges(Qtys, Prices, VATRates, DiscPcts, ErrorText), 'Should fail');
        Assert.IsSubstring(ErrorText, 'discount');
    end;

    // IsWithinTolerance --------------------------------------------------------

    [Test]
    procedure IsWithinTolerance_Pass_ExactMatch()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        Assert.IsTrue(VerifyTools.IsWithinTolerance(100, 100), 'Exact match');
    end;

    [Test]
    procedure IsWithinTolerance_Pass_SmallDelta()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        Assert.IsTrue(VerifyTools.IsWithinTolerance(2529.888, 2529.89), 'Rounding delta');
    end;

    [Test]
    procedure IsWithinTolerance_Fail_LargeDelta()
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        Assert.IsFalse(VerifyTools.IsWithinTolerance(2027, 2529.89), 'Wrong value');
    end;
}
```

- [ ] **Step 3: Implement the 6 methods in EDocMLLMVerifyTools**

Replace the stub body of each method with the real implementation:

```al
procedure VerifyLineMath(UnitPrice: Decimal; Quantity: Decimal; DiscountPct: Decimal; LineExtensionAmount: Decimal; var ErrorText: Text): Boolean
var
    Expected: Decimal;
begin
    if LineExtensionAmount = 0 then
        exit(true);
    Expected := UnitPrice * Quantity * (1 - DiscountPct / 100);
    if IsWithinTolerance(Expected, LineExtensionAmount) then
        exit(true);
    ErrorText := StrSubstNo('%1 × %2 × (1 − %3/100) = %4, but line_extension_amount = %5. Re-check which price column is the gross (pre-discount) unit price.',
        UnitPrice, Quantity, DiscountPct, Round(Expected, 0.01), LineExtensionAmount);
    exit(false);
end;

procedure VerifyInvoiceTotals(LineAmounts: List of [Decimal]; TaxExclusiveAmount: Decimal; var ErrorText: Text): Boolean
var
    LineAmount: Decimal;
    Sum: Decimal;
begin
    if TaxExclusiveAmount = 0 then
        exit(true);
    foreach LineAmount in LineAmounts do
        Sum += LineAmount;
    if IsWithinTolerance(Sum, TaxExclusiveAmount) then
        exit(true);
    ErrorText := StrSubstNo('Sum of line_extension_amounts = %1, but tax_exclusive_amount = %2. Check for missing or duplicated lines.',
        Round(Sum, 0.01), TaxExclusiveAmount);
    exit(false);
end;

procedure VerifyVAT(TaxExclusiveAmount: Decimal; VATRate: Decimal; TaxAmount: Decimal; var ErrorText: Text): Boolean
var
    Expected: Decimal;
begin
    if TaxAmount = 0 then
        exit(true);
    Expected := TaxExclusiveAmount * VATRate / 100;
    if IsWithinTolerance(Expected, TaxAmount) then
        exit(true);
    ErrorText := StrSubstNo('%1 × %2% = %3, but tax_amount = %4. Re-check the VAT rate.',
        TaxExclusiveAmount, VATRate, Round(Expected, 0.01), TaxAmount);
    exit(false);
end;

procedure VerifyDates(IssueDateText: Text; DueDateText: Text; var ErrorText: Text): Boolean
var
    IssueDate: Date;
    DueDate: Date;
begin
    if IssueDateText = '' then begin
        ErrorText := 'issue_date is missing.';
        exit(false);
    end;
    if not Evaluate(IssueDate, IssueDateText, 9) then begin
        ErrorText := StrSubstNo('issue_date "%1" is not a valid XML date (expected YYYY-MM-DD).', IssueDateText);
        exit(false);
    end;
    if (Date2DMY(IssueDate, 3) < 1900) or (Date2DMY(IssueDate, 3) > 2100) then begin
        ErrorText := StrSubstNo('issue_date year %1 is out of expected range 1900–2100.', Date2DMY(IssueDate, 3));
        exit(false);
    end;
    if DueDateText = '' then
        exit(true);
    if not Evaluate(DueDate, DueDateText, 9) then begin
        ErrorText := StrSubstNo('due_date "%1" is not a valid XML date (expected YYYY-MM-DD).', DueDateText);
        exit(false);
    end;
    if DueDate < IssueDate then begin
        ErrorText := StrSubstNo('due_date %1 is before issue_date %2.', Format(DueDate, 0, 9), Format(IssueDate, 0, 9));
        exit(false);
    end;
    exit(true);
end;

procedure VerifyRequiredFields(VendorName: Text; InvoiceNo: Text; LineCount: Integer; var ErrorText: Text): Boolean
var
    Missing: Text;
begin
    if VendorName = '' then
        AppendMissing(Missing, 'vendor name');
    if InvoiceNo = '' then
        AppendMissing(Missing, 'invoice number');
    if LineCount <= 0 then
        AppendMissing(Missing, 'invoice lines (line_count = 0)');
    if Missing <> '' then begin
        ErrorText := 'Missing required fields: ' + Missing;
        exit(false);
    end;
    exit(true);
end;

procedure VerifyRanges(Quantities: List of [Decimal]; Prices: List of [Decimal]; VATRates: List of [Decimal]; DiscountPcts: List of [Decimal]; var ErrorText: Text): Boolean
var
    i: Integer;
    Value: Decimal;
begin
    for i := 1 to Quantities.Count() do begin
        Quantities.Get(i, Value);
        if Value <= 0 then begin
            ErrorText := StrSubstNo('Line %1 quantity %2 must be > 0.', i, Value);
            exit(false);
        end;
    end;
    for i := 1 to Prices.Count() do begin
        Prices.Get(i, Value);
        if Value <= 0 then begin
            ErrorText := StrSubstNo('Line %1 unit price %2 must be > 0.', i, Value);
            exit(false);
        end;
    end;
    for i := 1 to VATRates.Count() do begin
        VATRates.Get(i, Value);
        if (Value < 0) or (Value > 100) then begin
            ErrorText := StrSubstNo('Line %1 VAT rate %2 must be between 0 and 100.', i, Value);
            exit(false);
        end;
    end;
    for i := 1 to DiscountPcts.Count() do begin
        DiscountPcts.Get(i, Value);
        if (Value < 0) or (Value > 100) then begin
            ErrorText := StrSubstNo('Line %1 discount %2%% must be between 0 and 100.', i, Value);
            exit(false);
        end;
    end;
    exit(true);
end;

local procedure AppendMissing(var Missing: Text; Field: Text)
begin
    if Missing <> '' then
        Missing += ', ';
    Missing += Field;
end;
```


## Task 3: Create the 6 AOAI Function tool adapters

Each adapter is a thin codeunit implementing `AOAI Function`. It declares the tool's JSON schema in `GetPrompt()` and delegates to `EDocMLLMVerifyTools` in `Execute()`.

**Files:** 6 new codeunits (6235–6239, 6243)

- [ ] **Step 1: Create EDocMLLMVerifyLineMathTool.Codeunit.al (6235)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6235 "E-Doc. MLLM VL Math Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_line_math');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'number'); PropObj.Add('description', 'Gross unit price before discounts');
        PropsObj.Add('unit_price', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'Quantity of units');
        PropsObj.Add('quantity', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'Combined discount percentage 0-100 (use 0 if no discount)');
        PropsObj.Add('discount_pct', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'line_extension_amount from the invoice');
        PropsObj.Add('line_extension_amount', PropObj);
        RequiredArr.Add('unit_price'); RequiredArr.Add('quantity'); RequiredArr.Add('discount_pct'); RequiredArr.Add('line_extension_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that gross_unit_price × quantity × (1 − discount_pct/100) matches line_extension_amount within 1%. Call once per invoice line.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        UnitPrice: Decimal;
        Quantity: Decimal;
        DiscountPct: Decimal;
        LineExtAmt: Decimal;
    begin
        GetDecimalArg(Arguments, 'unit_price', UnitPrice);
        GetDecimalArg(Arguments, 'quantity', Quantity);
        GetDecimalArg(Arguments, 'discount_pct', DiscountPct);
        GetDecimalArg(Arguments, 'line_extension_amount', LineExtAmt);
        if VerifyTools.VerifyLineMath(UnitPrice, Quantity, DiscountPct, LineExtAmt, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;

    local procedure GetDecimalArg(Arguments: JsonObject; PropertyName: Text; var Value: Decimal)
    var
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if not Arguments.Get(PropertyName, Token) then
            exit;
        if Token.AsValue().IsNull() then
            exit;
        if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
            Value := DecimalValue;
    end;
}
```

- [ ] **Step 2: Create EDocMLLMVerifyTotalsTool.Codeunit.al (6236)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6236 "E-Doc. MLLM VL Totals Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_invoice_totals');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        ItemsObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line_extension_amount values');
        PropsObj.Add('line_amounts', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_exclusive_amount from legal_monetary_total');
        PropsObj.Add('tax_exclusive_amount', PropObj);
        RequiredArr.Add('line_amounts'); RequiredArr.Add('tax_exclusive_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that the sum of all line_extension_amounts matches tax_exclusive_amount within 1%.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        LineAmountsToken: JsonToken;
        LineAmountsArray: JsonArray;
        LineToken: JsonToken;
        LineAmounts: List of [Decimal];
        TaxExclusiveAmount: Decimal;
        LineAmt: Decimal;
        DecimalValue: Decimal;
        Token: JsonToken;
    begin
        if Arguments.Get('line_amounts', LineAmountsToken) then begin
            LineAmountsArray := LineAmountsToken.AsArray();
            foreach LineToken in LineAmountsArray do begin
                if Evaluate(DecimalValue, LineToken.AsValue().AsText(), 9) then
                    LineAmounts.Add(DecimalValue);
            end;
        end;
        if Arguments.Get('tax_exclusive_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
                TaxExclusiveAmount := DecimalValue;

        if VerifyTools.VerifyInvoiceTotals(LineAmounts, TaxExclusiveAmount, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;
}
```

- [ ] **Step 3: Create EDocMLLMVerifyVATTool.Codeunit.al (6237)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6237 "E-Doc. MLLM VL VAT Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_vat');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_exclusive_amount');
        PropsObj.Add('tax_exclusive_amount', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'VAT rate percentage 0-100');
        PropsObj.Add('vat_rate', PropObj); Clear(PropObj);
        PropObj.Add('type', 'number'); PropObj.Add('description', 'tax_amount');
        PropsObj.Add('tax_amount', PropObj);
        RequiredArr.Add('tax_exclusive_amount'); RequiredArr.Add('vat_rate'); RequiredArr.Add('tax_amount');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that tax_exclusive_amount × vat_rate/100 ≈ tax_amount within 1%.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        TaxExcl: Decimal;
        VATRate: Decimal;
        TaxAmt: Decimal;
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if Arguments.Get('tax_exclusive_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxExcl := DecimalValue;
        if Arguments.Get('vat_rate', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then VATRate := DecimalValue;
        if Arguments.Get('tax_amount', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then TaxAmt := DecimalValue;

        if VerifyTools.VerifyVAT(TaxExcl, VATRate, TaxAmt, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;
}
```

- [ ] **Step 4: Create EDocMLLMVerifyDatesTool.Codeunit.al (6238)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6238 "E-Doc. MLLM VL Dates Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_dates');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string'); PropObj.Add('description', 'issue_date in YYYY-MM-DD format');
        PropsObj.Add('issue_date', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'due_date in YYYY-MM-DD format, or empty string if not present');
        PropsObj.Add('due_date', PropObj);
        RequiredArr.Add('issue_date'); RequiredArr.Add('due_date');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that issue_date and due_date are valid XML dates (YYYY-MM-DD), year 1900-2100, and due_date >= issue_date if present.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        IssueDate: Text;
        DueDate: Text;
        Token: JsonToken;
    begin
        if Arguments.Get('issue_date', Token) then IssueDate := Token.AsValue().AsText();
        if Arguments.Get('due_date', Token) then DueDate := Token.AsValue().AsText();

        if VerifyTools.VerifyDates(IssueDate, DueDate, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;
}
```

- [ ] **Step 5: Create EDocMLLMVerifyRequiredTool.Codeunit.al (6239)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6239 "E-Doc. MLLM VL Required Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_required_fields');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Supplier/vendor company name');
        PropsObj.Add('vendor_name', PropObj); Clear(PropObj);
        PropObj.Add('type', 'string'); PropObj.Add('description', 'Invoice number / id');
        PropsObj.Add('invoice_no', PropObj); Clear(PropObj);
        PropObj.Add('type', 'integer'); PropObj.Add('description', 'Number of invoice lines extracted');
        PropsObj.Add('line_count', PropObj);
        RequiredArr.Add('vendor_name'); RequiredArr.Add('invoice_no'); RequiredArr.Add('line_count');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that vendor name, invoice number, and at least one invoice line are present.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        VendorName: Text;
        InvoiceNo: Text;
        LineCount: Integer;
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if Arguments.Get('vendor_name', Token) then VendorName := Token.AsValue().AsText();
        if Arguments.Get('invoice_no', Token) then InvoiceNo := Token.AsValue().AsText();
        if Arguments.Get('line_count', Token) then
            if Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
                LineCount := Round(DecimalValue, 1);

        if VerifyTools.VerifyRequiredFields(VendorName, InvoiceNo, LineCount, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;
}
```

- [ ] **Step 6: Create EDocMLLMVerifyRangesTool.Codeunit.al (6243)**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using System.AI;

codeunit 6243 "E-Doc. MLLM VL Ranges Tool" implements "AOAI Function"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetName(): Text
    begin
        exit('verify_ranges');
    end;

    procedure GetPrompt(): JsonObject
    var
        ToolObj: JsonObject;
        FunctionObj: JsonObject;
        ParamsObj: JsonObject;
        PropsObj: JsonObject;
        PropObj: JsonObject;
        ItemsObj: JsonObject;
        RequiredArr: JsonArray;
    begin
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line quantities');
        PropsObj.Add('quantities', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line unit prices');
        PropsObj.Add('prices', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line VAT rates (0-100)');
        PropsObj.Add('vat_rates', PropObj); Clear(PropObj); Clear(ItemsObj);
        ItemsObj.Add('type', 'number');
        PropObj.Add('type', 'array'); PropObj.Add('items', ItemsObj); PropObj.Add('description', 'All line discount percentages (0-100)');
        PropsObj.Add('discount_pcts', PropObj);
        RequiredArr.Add('quantities'); RequiredArr.Add('prices'); RequiredArr.Add('vat_rates'); RequiredArr.Add('discount_pcts');
        ParamsObj.Add('type', 'object'); ParamsObj.Add('properties', PropsObj); ParamsObj.Add('required', RequiredArr);
        FunctionObj.Add('name', GetName());
        FunctionObj.Add('description', 'Verify that quantities > 0, unit prices > 0, VAT rates 0-100, discount percentages 0-100 for all lines.');
        FunctionObj.Add('parameters', ParamsObj);
        ToolObj.Add('type', 'function'); ToolObj.Add('function', FunctionObj);
        exit(ToolObj);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        VerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ResultObj: JsonObject;
        ErrorText: Text;
        Quantities: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscountPcts: List of [Decimal];
    begin
        ParseDecimalArray(Arguments, 'quantities', Quantities);
        ParseDecimalArray(Arguments, 'prices', Prices);
        ParseDecimalArray(Arguments, 'vat_rates', VATRates);
        ParseDecimalArray(Arguments, 'discount_pcts', DiscountPcts);

        if VerifyTools.VerifyRanges(Quantities, Prices, VATRates, DiscountPcts, ErrorText) then
            ResultObj.Add('pass', true)
        else begin
            ResultObj.Add('pass', false);
            ResultObj.Add('error', ErrorText);
        end;
        exit(ResultObj);
    end;

    local procedure ParseDecimalArray(Arguments: JsonObject; PropertyName: Text; var Values: List of [Decimal])
    var
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        DecimalValue: Decimal;
    begin
        if not Arguments.Get(PropertyName, ArrayToken) then
            exit;
        foreach ItemToken in ArrayToken.AsArray() do
            if Evaluate(DecimalValue, ItemToken.AsValue().AsText(), 9) then
                Values.Add(DecimalValue);
    end;
}
```


## Task 4: Create the V2 system prompt

**Files:**
- Create: `src/Apps/W1/EDocument/App/.resources/Prompts/EDocMLLMExtractionV2-SystemPrompt.md`

- [ ] **Step 1: Create the prompt file**

```markdown
You are an invoice data extraction agent with access to verification tools.

PHASE 1 — UNDERSTAND THE DOCUMENT:
Before extracting any values, reason through the document's structure out loud. Cover:
- What type of document is this and in what language?
- What number format does this document use? (decimal separator, thousands separator — these vary by country)
- What columns appear in the line item table? For each column, what does it represent? Some invoices show only a unit price; others show a gross price, one or more discount columns, and a net price. Some discounts are percentages, others are monetary amounts. Some apply sequentially. Describe exactly what you see.
- Where are the header fields (supplier, buyer, invoice number, dates)?
- Where is the totals section?
- Is there anything unusual about this invoice's layout?

Your analysis determines how you extract. Two invoices from different vendors may look completely different — your job is to understand each one on its own terms.

PHASE 2 — EXTRACT FROM THE REGIONS YOU IDENTIFIED:
Use your analysis from Phase 1 to extract values. Do not sweep left-to-right across the full text. Extract from the specific regions and columns you identified.

Format rules (non-negotiable):
- Numbers: XML decimal format — period (.) as decimal separator, no thousands separators (e.g. 1083 not "1 083", 2.34 not "2,34")
- Dates: YYYY-MM-DD

For everything else — how to represent the price, how to represent discounts, which column maps to which UBL field — let your Phase 1 analysis guide you. The verify tools in Phase 3 will tell you if your extraction is mathematically inconsistent.

Output valid UBL JSON matching the schema provided.

PHASE 3 — VERIFY YOUR OWN OUTPUT:
Call the verification tools on what you extracted:
- verify_line_math for each invoice line
- verify_invoice_totals with all line amounts
- verify_vat for the tax total
- verify_dates with issue_date and due_date
- verify_required_fields with vendor name, invoice number, line count
- verify_ranges with all quantities, prices, VAT rates, and discount percentages

If a tool returns { "pass": false }, read its error message. It will tell you specifically what does not add up. Reconsider your Phase 1 analysis if needed — the error may reveal that you misidentified a column role or misread a discount structure. Correct and call the tools again. Only finalise when all tools return { "pass": true }.

Output ONLY valid JSON. No markdown, no explanation.
```


## Task 5: Create EDocumentMLLMHandlerV2

This is the main handler. It implements the same three interfaces as V1 (`IStructureReceivedEDocument`, `IStructuredFormatReader`, `IStructuredDataType`) and uses the existing `EDocMLLMSchemaHelper` for JSON→draft mapping (unchanged from V1). The key difference is `StructureReceivedEDocument()` which runs the agentic loop.

**Files:**
- Create: `src/Apps/W1/EDocument/App/src/Processing/Import/StructureReceivedEDocument/EDocumentMLLMHandlerV2.Codeunit.al`

- [ ] **Step 1: Create the handler codeunit**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.AI;
using System.Azure.KeyVault;
using System.Telemetry;
using System.Utilities;

codeunit 6244 "E-Document MLLM Handler V2" implements IStructureReceivedEDocument, IStructuredFormatReader, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit Telemetry;
        StructuredData: Text;
        FileFormat: Enum "E-Doc. File Format";
        FeatureNameLbl: Label 'E-Document MLLM Extraction V2', Locked = true;
        FileDataLbl: Label 'data:application/pdf;base64,%1', Locked = true;
        SystemPromptV2ResourceTok: Label 'Prompts/EDocMLLMExtractionV2-SystemPrompt.md', Locked = true;
        UserPromptLbl: Label 'Extract invoice data into this UBL JSON structure: %1. \n\nExtract ONLY visible values. Return JSON only. %2', Locked = true;
        SecurityPromptAKVKeyTok: Label 'EDocMLLMExtraction-SecurityPromptV281', Locked = true;
        MaxToolCallsTok: Integer;
        BudgetExhaustedErr: Label 'The document could not be verified after %1 tool calls. The extraction was inconsistent.', Comment = '%1 = tool call count';
        DocumentNotProcessedErr: Label 'The document could not be processed.';
        InappropriateContentErr: Label 'The document could not be processed because it contains inappropriate content.';

    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ResponseJson: JsonObject;
        ResponseText: Text;
    begin
        MaxToolCallsTok := 200;

        RegisterCopilotCapabilityIfNeeded();

        ResponseText := CallMLLMV2(EDocumentDataStorage);

        if IsInappropriateContentResponse(ResponseText) then
            Error(InappropriateContentErr);

        if not ValidateAndUnwrapResponse(ResponseText, ResponseJson) then
            exit(FallbackToADI(EDocumentDataStorage));

        StructuredData := ResponseText;
        FileFormat := "E-Doc. File Format"::JSON;
        exit(this);
    end;

    [NonDebuggable]
    local procedure CallMLLMV2(EDocumentDataStorage: Record "E-Doc. Data Storage"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIUserMessage: Codeunit "AOAI User Message";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIDeployments: Codeunit "AOAI Deployments";
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        VerifyLineMathTool: Codeunit "E-Doc. MLLM VL Math Tool";
        VerifyTotalsTool: Codeunit "E-Doc. MLLM VL Totals Tool";
        VerifyVATTool: Codeunit "E-Doc. MLLM VL VAT Tool";
        VerifyDatesTool: Codeunit "E-Doc. MLLM VL Dates Tool";
        VerifyRequiredTool: Codeunit "E-Doc. MLLM VL Required Tool";
        VerifyRangesTool: Codeunit "E-Doc. MLLM VL Ranges Tool";
        FromTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        Base64Data: Text;
        ToolCallCount: Integer;
    begin
        // Load PDF as base64
        FromTempBlob := EDocumentDataStorage.GetTempBlob();
        FromTempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Base64Data := Base64Convert.ToBase64(InStream);

        // Configure AOAI
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41MiniPreview());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis");
        AOAIChatCompletionParams.SetTemperature(0);
        // Do NOT set JSON mode — tool-calling and JSON mode cannot be combined.
        // The system prompt instructs the model to output UBL JSON as its final response.

        // System prompt
        AOAIChatMessages.SetPrimarySystemMessage(NavApp.GetResourceAsText(SystemPromptV2ResourceTok, TextEncoding::UTF8));

        // Register 6 verification tools
        AOAIChatMessages.AddTool(VerifyLineMathTool);
        AOAIChatMessages.AddTool(VerifyTotalsTool);
        AOAIChatMessages.AddTool(VerifyVATTool);
        AOAIChatMessages.AddTool(VerifyDatesTool);
        AOAIChatMessages.AddTool(VerifyRequiredTool);
        AOAIChatMessages.AddTool(VerifyRangesTool);
        AOAIChatMessages.SetToolChoice('auto');

        // User message: PDF + UBL schema + security clause
        AOAIUserMessage.AddFilePart(StrSubstNo(FileDataLbl, Base64Data));
        AOAIUserMessage.AddTextPart(SecretText.SecretStrSubstNo(UserPromptLbl, EDocMLLMSchemaHelper.GetDefaultSchema(), GetSecurityClause()).Unwrap());
        AOAIChatMessages.AddUserMessage(AOAIUserMessage);

        // Agentic dispatch loop
        repeat
            AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

            if not AOAIOperationResponse.IsSuccess() then
                exit('');

            if AOAIOperationResponse.IsFunctionCall() then begin
                ToolCallCount += AOAIOperationResponse.GetFunctionResponses().Count();
                if ToolCallCount > MaxToolCallsTok then
                    Error(BudgetExhaustedErr, ToolCallCount);
                AOAIOperationResponse.AppendFunctionResponsesToChatMessages(AOAIChatMessages);
            end;
        until not AOAIOperationResponse.IsFunctionCall();

        exit(AOAIOperationResponse.GetResult());
    end;

    [NonDebuggable]
    local procedure GetSecurityClause() Result: SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptAKVKeyTok, Result) then
            Error(DocumentNotProcessedErr);
    end;

    // The following methods are identical to V1 (EDocumentMLLMHandler) --------

    local procedure IsInappropriateContentResponse(ResponseText: Text): Boolean
    var
        ResponseJson: JsonObject;
        ContentToken: JsonToken;
        ErrorToken: JsonToken;
        InnerText: Text;
    begin
        if ResponseText = '' then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if ResponseJson.Get('content', ContentToken) and ContentToken.IsValue() then begin
            InnerText := ContentToken.AsValue().AsText();
            Clear(ResponseJson);
            if not ResponseJson.ReadFrom(InnerText) then
                exit(false);
        end;
        exit(ResponseJson.Get('error', ErrorToken));
    end;

    local procedure ValidateAndUnwrapResponse(var ResponseText: Text; var ResponseJson: JsonObject): Boolean
    var
        ContentToken: JsonToken;
    begin
        if ResponseText = '' then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if ResponseJson.Get('content', ContentToken) then begin
            ResponseText := ContentToken.AsValue().AsText();
            if not ResponseJson.ReadFrom(ResponseText) then
                exit(false);
        end;
        exit(ValidateMLLMResponse(ResponseJson));
    end;

    local procedure ValidateMLLMResponse(ResponseJson: JsonObject): Boolean
    var
        SupplierToken: JsonToken;
        PartyToken: JsonToken;
        NameToken: JsonToken;
        AddressToken: JsonToken;
        SupplierObj: JsonObject;
        PartyObj: JsonObject;
        NameObj: JsonObject;
        VendorName: Text;
    begin
        if not ResponseJson.Get('accounting_supplier_party', SupplierToken) then exit(false);
        if not SupplierToken.IsObject() then exit(false);
        SupplierObj := SupplierToken.AsObject();
        if not SupplierObj.Get('party', PartyToken) then exit(false);
        if not PartyToken.IsObject() then exit(false);
        PartyObj := PartyToken.AsObject();
        if not PartyObj.Get('party_name', NameToken) then exit(false);
        if not NameToken.IsObject() then exit(false);
        NameObj := NameToken.AsObject();
        if not NameObj.Get('name', NameToken) then exit(false);
        VendorName := NameToken.AsValue().AsText();
        if VendorName = '' then exit(false);
        if not PartyObj.Get('postal_address', AddressToken) then exit(false);
        if not AddressToken.IsObject() then exit(false);
        exit(true);
    end;

    local procedure FallbackToADI(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        ADIHandler: Codeunit "E-Document ADI Handler";
    begin
        exit(ADIHandler.StructureReceivedEDocument(EDocumentDataStorage));
    end;

    local procedure GetInvoiceLineCount(ResponseJson: JsonObject): Integer
    var
        LinesToken: JsonToken;
    begin
        if ResponseJson.Get('invoice_line', LinesToken) then
            if LinesToken.IsArray() then
                exit(LinesToken.AsArray().Count());
        exit(0);
    end;

    procedure RegisterCopilotCapabilityIfNeeded()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"E-Document MLLM Analysis") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"E-Document MLLM Analysis", '');
    end;

    // IStructuredFormatReader + IStructuredDataType (identical to V1) ----------

    procedure GetFileFormat(): Enum "E-Doc. File Format"
    begin
        exit(this.FileFormat);
    end;

    procedure GetContent(): Text
    begin
        exit(this.StructuredData);
    end;

    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        exit("E-Doc. Read into Draft"::MLLM);
    end;

#pragma warning disable AA0139
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
    begin
        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocPurchaseDraftUtility.PersistDraft(EDocument, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
    end;

    local procedure ReadIntoBuffer(
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        InStream: InStream;
        SourceJsonObject: JsonObject;
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        BlobAsText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(BlobAsText);
        SourceJsonObject.ReadFrom(BlobAsText);
        EDocMLLMSchemaHelper.MapHeaderFromJson(SourceJsonObject, TempEDocPurchaseHeader);
        TempEDocPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        if SourceJsonObject.Get('invoice_line', LinesToken) then
            if LinesToken.IsArray() then begin
                LinesArray := LinesToken.AsArray();
                EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, EDocument."Entry No", TempEDocPurchaseLine);
            end;
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocReadablePurchaseDoc: Page "E-Doc. Readable Purchase Doc.";
    begin
        ReadIntoBuffer(EDocument, TempBlob, TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.SetBuffer(TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.Run();
    end;
#pragma warning restore AA0139
}
```

---

## Task 6: Wire up app.json and verify full compilation

The new codeunit files must be included in the app's file list (if the project uses explicit file lists) and the app version should be bumped.

**Files:**
- Modify: `src/Apps/W1/EDocument/App/app.json`

- [ ] **Step 1: Bump app version patch number**

In `app.json`, increment the 4th version segment (e.g. `29.0.0.1` → `29.0.0.2`).

- [ ] **Step 2: Full compile of EDocument app**

Run the compile command for the EDocument app. Expected: 0 errors, 0 warnings introduced by new code.

Use: `dispatch 'Build-Application -AppName "E-Document Core" -CountryCode W1'`

Expected output: build succeeds.

- [ ] **Step 3: Run existing MLLM tests to verify nothing regressed**

Run: `dispatch 'Run-Tests -AppName "E-Document Core Tests" -TestCodeunit "EDoc MLLM Tests"'`

Expected: all tests pass (V1 tests are unaffected).

- [ ] **Step 4: Run new verify tools tests**

Run: `dispatch 'Run-Tests -AppName "E-Document Core Tests" -TestCodeunit "EDoc MLLM Verify Tools Tests"'`

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/App/app.json
git commit -m "Bump version and verify V2 compiles cleanly"
```
