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

    // VerifyLineMath tests

    [Test]
    procedure VerifyLineMath_Pass_NoDiscount()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] 40 × 5 × 1.0 = 200, line_extension_amount = 200 → pass
        Result := EDocMLLMVerifyTools.VerifyLineMath(40, 5, 0, 200, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyLineMath to pass for 40 × 5 = 200');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyLineMath_Pass_WithDiscount()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] Swedish invoice case: 3.65 × 1083 × (1 - 36/100) ≈ 2529.89 → pass
        // 3.65 × 1083 = 3952.95; 3952.95 × 0.64 = 2529.888 ≈ 2529.89
        Result := EDocMLLMVerifyTools.VerifyLineMath(3.65, 1083, 36, 2529.89, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyLineMath to pass for Swedish invoice case');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyLineMath_Pass_WithinOnePct()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] 10 × 10 × 1.0 = 100, actual = 100.9 → within 1% tolerance → pass
        Result := EDocMLLMVerifyTools.VerifyLineMath(10, 10, 0, 100.9, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyLineMath to pass when within 1% tolerance');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyLineMath_Fail_WrongPrice()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] Wrong unit price: 2.34 × 1083 × 0.80 ≈ 2027, but actual = 2529.89 → fail
        Result := EDocMLLMVerifyTools.VerifyLineMath(2.34, 1083, 20, 2529.89, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyLineMath to fail for wrong price');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    [Test]
    procedure VerifyLineMath_Pass_ZeroLineAmount()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] line_extension_amount = 0 → skip check → pass
        Result := EDocMLLMVerifyTools.VerifyLineMath(0, 0, 0, 0, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyLineMath to pass when line_extension_amount = 0');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    // VerifyInvoiceTotals tests

    [Test]
    procedure VerifyInvoiceTotals_Pass()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        LineAmounts: List of [Decimal];
        Result: Boolean;
    begin
        // [SCENARIO] [200, 30, 20] sums to 250, tax_exclusive_amount = 250 → pass
        LineAmounts.Add(200);
        LineAmounts.Add(30);
        LineAmounts.Add(20);
        Result := EDocMLLMVerifyTools.VerifyInvoiceTotals(LineAmounts, 250, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyInvoiceTotals to pass when sum matches');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyInvoiceTotals_Fail_MissingLine()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        LineAmounts: List of [Decimal];
        Result: Boolean;
    begin
        // [SCENARIO] [200] sums to 200, tax_exclusive_amount = 250 → fail (missing lines)
        LineAmounts.Add(200);
        Result := EDocMLLMVerifyTools.VerifyInvoiceTotals(LineAmounts, 250, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyInvoiceTotals to fail when sum does not match');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    // VerifyVAT tests

    [Test]
    procedure VerifyVAT_Pass()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] 250 × 15% = 37.5, tax_amount = 37.5 → pass
        Result := EDocMLLMVerifyTools.VerifyVAT(250, 15, 37.5, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyVAT to pass for 250 × 15% = 37.5');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyVAT_Fail()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] 250 × 15% = 37.5, but tax_amount = 100 → fail
        Result := EDocMLLMVerifyTools.VerifyVAT(250, 15, 100, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyVAT to fail when tax_amount does not match');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    [Test]
    procedure VerifyVAT_Skip_ZeroTax()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] tax_amount = 0 → skip check → pass
        Result := EDocMLLMVerifyTools.VerifyVAT(250, 15, 0, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyVAT to pass when tax_amount = 0 (skip)');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    // VerifyDates tests

    [Test]
    procedure VerifyDates_Pass_ValidDates()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] Valid issue and due dates where due >= issue → pass
        Result := EDocMLLMVerifyTools.VerifyDates('2024-03-15', '2024-04-15', ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyDates to pass for valid dates');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyDates_Pass_NoDueDate()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] Valid issue date, no due date → pass
        Result := EDocMLLMVerifyTools.VerifyDates('2024-03-15', '', ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyDates to pass when due_date is empty');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyDates_Fail_DueDateBeforeIssue()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] due_date 2024-03-15 is before issue_date 2024-04-15 → fail
        Result := EDocMLLMVerifyTools.VerifyDates('2024-04-15', '2024-03-15', ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyDates to fail when due_date is before issue_date');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    [Test]
    procedure VerifyDates_Fail_InvalidDate()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] issue_date = 'not-a-date' cannot be parsed → fail
        Result := EDocMLLMVerifyTools.VerifyDates('not-a-date', '', ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyDates to fail for unparseable issue_date');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    [Test]
    procedure VerifyDates_Fail_MissingIssueDate()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] issue_date = '' → fail with missing date error
        Result := EDocMLLMVerifyTools.VerifyDates('', '', ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyDates to fail when issue_date is empty');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
    end;

    // VerifyRequiredFields tests

    [Test]
    procedure VerifyRequiredFields_Pass()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] All required fields present → pass
        Result := EDocMLLMVerifyTools.VerifyRequiredFields('Contoso Ltd', 'INV-001', 2, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyRequiredFields to pass when all fields are present');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyRequiredFields_Fail_MissingVendor()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] VendorName = '' → fail, ErrorText contains 'vendor'
        Result := EDocMLLMVerifyTools.VerifyRequiredFields('', 'INV-001', 2, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyRequiredFields to fail when vendor name is missing');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
        Assert.IsTrue(ErrorText.ToLower().Contains('vendor'), 'ErrorText should mention vendor');
    end;

    [Test]
    procedure VerifyRequiredFields_Fail_NoLines()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Result: Boolean;
    begin
        // [SCENARIO] LineCount = 0 → fail, ErrorText contains 'line'
        Result := EDocMLLMVerifyTools.VerifyRequiredFields('Contoso Ltd', 'INV-001', 0, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyRequiredFields to fail when line count is 0');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
        Assert.IsTrue(ErrorText.ToLower().Contains('line'), 'ErrorText should mention line');
    end;

    // VerifyRanges tests

    [Test]
    procedure VerifyRanges_Pass()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Quantities: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscountPcts: List of [Decimal];
        Result: Boolean;
    begin
        // [SCENARIO] qty=5, price=40, vat=15, disc=0 → all in range → pass
        Quantities.Add(5);
        Prices.Add(40);
        VATRates.Add(15);
        DiscountPcts.Add(0);
        Result := EDocMLLMVerifyTools.VerifyRanges(Quantities, Prices, VATRates, DiscountPcts, ErrorText);
        Assert.IsTrue(Result, 'Expected VerifyRanges to pass for valid values');
        Assert.AreEqual('', ErrorText, 'ErrorText should be empty on pass');
    end;

    [Test]
    procedure VerifyRanges_Fail_NegativeQty()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Quantities: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscountPcts: List of [Decimal];
        Result: Boolean;
    begin
        // [SCENARIO] qty=-1 → fail, ErrorText contains 'quantity'
        Quantities.Add(-1);
        Prices.Add(40);
        VATRates.Add(15);
        DiscountPcts.Add(0);
        Result := EDocMLLMVerifyTools.VerifyRanges(Quantities, Prices, VATRates, DiscountPcts, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyRanges to fail for negative quantity');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
        Assert.IsTrue(ErrorText.ToLower().Contains('quantity'), 'ErrorText should mention quantity');
    end;

    [Test]
    procedure VerifyRanges_Fail_DiscountOver100()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
        ErrorText: Text;
        Quantities: List of [Decimal];
        Prices: List of [Decimal];
        VATRates: List of [Decimal];
        DiscountPcts: List of [Decimal];
        Result: Boolean;
    begin
        // [SCENARIO] disc=150 → fail, ErrorText contains 'discount'
        Quantities.Add(5);
        Prices.Add(40);
        VATRates.Add(15);
        DiscountPcts.Add(150);
        Result := EDocMLLMVerifyTools.VerifyRanges(Quantities, Prices, VATRates, DiscountPcts, ErrorText);
        Assert.IsFalse(Result, 'Expected VerifyRanges to fail for discount > 100');
        Assert.AreNotEqual('', ErrorText, 'ErrorText should be non-empty on fail');
        Assert.IsTrue(ErrorText.ToLower().Contains('discount'), 'ErrorText should mention discount');
    end;

    // IsWithinTolerance tests (testing internal method via public exposure)

    [Test]
    procedure IsWithinTolerance_Pass_ExactMatch()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        // [SCENARIO] 100 vs 100 → within tolerance → true
        Assert.IsTrue(EDocMLLMVerifyTools.IsWithinTolerance(100, 100), 'Expected IsWithinTolerance to return true for exact match');
    end;

    [Test]
    procedure IsWithinTolerance_Pass_SmallDelta()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        // [SCENARIO] 2529.888 vs 2529.89 → tiny delta, well within 1% → true
        Assert.IsTrue(EDocMLLMVerifyTools.IsWithinTolerance(2529.888, 2529.89), 'Expected IsWithinTolerance to return true for small delta');
    end;

    [Test]
    procedure IsWithinTolerance_Fail_LargeDelta()
    var
        EDocMLLMVerifyTools: Codeunit "E-Doc. MLLM Verify Tools";
    begin
        // [SCENARIO] 2027 vs 2529.89 → ~20% difference → false
        Assert.IsFalse(EDocMLLMVerifyTools.IsWithinTolerance(2027, 2529.89), 'Expected IsWithinTolerance to return false for large delta');
    end;
}
