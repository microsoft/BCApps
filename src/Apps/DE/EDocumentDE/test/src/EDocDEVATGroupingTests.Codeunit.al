// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 148504 "E-Doc DE VAT Grouping Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;
    Permissions =
        tabledata "Sales Invoice Header" = RIM,
        tabledata "Sales Invoice Line" = RIM,
        tabledata "Sales Cr.Memo Header" = RI,
        tabledata "Sales Cr.Memo Line" = RI,
        tabledata "Value Entry" = RI;

    var
        Assert: Codeunit Assert;
        ExportXRechnung: Codeunit "Export XRechnung Document";
        ExportZUGFeRD: Codeunit "Export ZUGFeRD Document";
        VATBusPostingGroup: Code[20];

    [Test]
    procedure XRechnungInvoiceKeepsExemptAndZeroRatedBreakdowns()
    begin
        VerifyMixedCategories(false, false, false, false);
    end;

    [Test]
    procedure XRechnungCreditMemoKeepsExemptAndZeroRatedBreakdowns()
    begin
        VerifyMixedCategories(false, true, false, false);
    end;

    [Test]
    procedure ZUGFeRDInvoiceKeepsExemptAndZeroRatedBreakdowns()
    begin
        VerifyMixedCategories(true, false, false, false);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoKeepsExemptAndZeroRatedBreakdowns()
    begin
        VerifyMixedCategories(true, true, false, false);
    end;

    [Test]
    procedure XRechnungInvoiceGroupingDoesNotDependOnLineOrder()
    begin
        VerifyMixedCategories(false, false, true, false);
    end;

    [Test]
    procedure ZUGFeRDInvoiceGroupingDoesNotDependOnLineOrder()
    begin
        VerifyMixedCategories(true, false, true, false);
    end;

    [Test]
    procedure XRechnungInvoiceDiscountIsSplitByCategory()
    begin
        VerifyMixedCategories(false, false, false, true);
    end;

    [Test]
    procedure ZUGFeRDInvoiceDiscountIsSplitByCategory()
    begin
        VerifyMixedCategories(true, false, false, true);
    end;

    [Test]
    procedure XRechnungCreditMemoDiscountIsSplitByCategory()
    begin
        VerifyMixedCategories(false, true, true, true);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoDiscountIsSplitByCategory()
    begin
        VerifyMixedCategories(true, true, true, true);
    end;

    [Test]
    procedure XRechnungPreservesStandardRatesAndTotals()
    begin
        VerifyStandardRates(false, false);
    end;

    [Test]
    procedure ZUGFeRDPreservesStandardRatesAndTotals()
    begin
        VerifyStandardRates(true, false);
    end;

    [Test]
    procedure XRechnungPreservesStandardCreditMemoRatesAndTotals()
    begin
        VerifyStandardRates(false, true);
    end;

    [Test]
    procedure ZUGFeRDPreservesStandardCreditMemoRatesAndTotals()
    begin
        VerifyStandardRates(true, true);
    end;

    [Test]
    procedure XRechnungInvoicePricesIncludingVATKeepsDiscountTotals()
    begin
        VerifyPricesIncludingVAT(false, false);
    end;

    [Test]
    procedure ZUGFeRDInvoicePricesIncludingVATKeepsDiscountTotals()
    begin
        VerifyPricesIncludingVAT(true, false);
    end;

    [Test]
    procedure XRechnungCreditMemoPricesIncludingVATKeepsDiscountTotals()
    begin
        VerifyPricesIncludingVAT(false, true);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoPricesIncludingVATKeepsDiscountTotals()
    begin
        VerifyPricesIncludingVAT(true, true);
    end;

    [Test]
    procedure ZUGFeRDLegacyRateOnlyAPIRejectsAmbiguousCategories()
    var
        Header: Record "Sales Invoice Header";
        Line: Record "Sales Invoice Line";
        Currency: Record Currency;
        Document: XmlDocument;
        Root: XmlElement;
        Amounts, VATAmounts, Discounts: Dictionary of [Decimal, Decimal];
        Totals: Dictionary of [Text, Decimal];
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'E', 0, 100, 0, false, false);
        AddLine(Header, 20000, 'Z', 0, 200, 0, false, false);
        ExportFixture(Header, true, false, Document);
        Root := XmlElement.Create('CompatibilityTest');
        Line.SetRange("Document No.", Header."No.");
        Amounts.Add(0, 300);
        VATAmounts.Add(0, 0);
        Discounts.Add(0, 0);
        // The old API cannot express two categories at rate zero. It must fail before writing XML.
        asserterror ExportZUGFeRD.InsertSupplyChainTradeTransaction(Root, Header, Line, 'EUR', Currency, Amounts, VATAmounts, Totals, Discounts);
        Assert.ExpectedError('rate-only XML export cannot represent VAT categories');
        Assert.AreEqual(300, Amounts.Get(0), 'Rejecting ambiguous input must not consume caller totals.');
    end;

    local procedure VerifyPricesIncludingVAT(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Line: Record "Sales Invoice Line";
        Document: XmlDocument;
    begin
        CreateFixture(Header);
        Header."Prices Including VAT" := true;
        Header.Modify();
        AddLine(Header, 10000, 'S', 19, 90, 11.90, false, false);
        Line.Get(Header."No.", 10000);
        Line."Unit Price" := 119;
        Line."Line Amount" := 119;
        Line.Modify();
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, 'S', 19, 90, 17.10);
        AssertAllowance(Document, IsCII, 'S', 10);
        AssertPayable(Document, IsCII, 107.10);
    end;

    [Test]
    procedure XRechnungInvoiceSkipsZeroDiscountCategory()
    begin
        VerifyUndiscountedZeroCategory(false, false);
    end;

    [Test]
    procedure XRechnungCreditMemoSkipsZeroDiscountCategory()
    begin
        VerifyUndiscountedZeroCategory(false, true);
    end;

    [Test]
    procedure ZUGFeRDInvoiceSkipsZeroDiscountCategory()
    begin
        VerifyUndiscountedZeroCategory(true, false);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoSkipsZeroDiscountCategory()
    begin
        VerifyUndiscountedZeroCategory(true, true);
    end;

    local procedure VerifyUndiscountedZeroCategory(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
    begin
        // Splitting zero-rate categories must not introduce a 0/0 discount calculation for Z.
        CreateFixture(Header);
        AddLine(Header, 10000, 'E', 0, 90, 10, false, false);
        AddLine(Header, 20000, 'Z', 0, 0, 0, false, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, 'E', 0, 90, 0);
        AssertBreakdown(Document, IsCII, 'Z', 0, 0, 0);
        AssertAllowance(Document, IsCII, 'E', 10);
        if IsCII then
            AssertNodeCount(Document, '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]', 1)
        else
            AssertNodeCount(Document, '/*/*[local-name()="AllowanceCharge"]', 1);
        AssertPayable(Document, IsCII, 90);
    end;

    [Test]
    procedure XRechnungInvoiceForwardMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(false, false, false);
    end;

    [Test]
    procedure XRechnungInvoiceReversedMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(false, false, true);
    end;

    [Test]
    procedure XRechnungCreditMemoForwardMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(false, true, false);
    end;

    [Test]
    procedure XRechnungCreditMemoReversedMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(false, true, true);
    end;

    [Test]
    procedure ZUGFeRDInvoiceForwardMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(true, false, false);
    end;

    [Test]
    procedure ZUGFeRDInvoiceReversedMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(true, false, true);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoForwardMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(true, true, false);
    end;

    [Test]
    procedure ZUGFeRDCreditMemoReversedMixedCategoryCharges()
    begin
        VerifyMixedCategoryCharges(true, true, true);
    end;

    local procedure VerifyMixedCategoryCharges(IsCII: Boolean; IsCreditMemo: Boolean; ReverseOrder: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
    begin
        CreateFixture(Header);
        if ReverseOrder then begin
            AddLine(Header, 10000, 'Z', 0, 200, 0, false, false);
            AddLine(Header, 20000, 'E', 0, 100, 0, false, false);
        end else begin
            AddLine(Header, 10000, 'E', 0, 100, 0, false, false);
            AddLine(Header, 20000, 'Z', 0, 200, 0, false, false);
        end;
        AddLine(Header, 30000, 'E', 0, 15, 0, true, false);
        AddLine(Header, 40000, 'Z', 0, -5, 0, true, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, 'E', 0, 115, 0);
        AssertBreakdown(Document, IsCII, 'Z', 0, 195, 0);
        AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        if IsCII then
            AssertNodeCount(Document, '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]', 2)
        else
            AssertNodeCount(Document, '/*/*[local-name()="AllowanceCharge"]', 2);
        AssertPayable(Document, IsCII, 310);
    end;

    [Test]
    procedure ZUGFeRDLegacyInvoicePreservesSuppliedTotals()
    var
        Header: Record "Sales Invoice Header";
        Line: Record "Sales Invoice Line";
        Currency: Record Currency;
        Document: XmlDocument;
        Root: XmlElement;
        Amounts, VATAmounts, Discounts: Dictionary of [Decimal, Decimal];
        Totals: Dictionary of [Text, Decimal];
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'S', 19, 100, 0, false, false);
        ExportFixture(Header, true, false, Document);
        Root := XmlElement.Create('CompatibilityTest');
        Line.SetRange("Document No.", Header."No.");
        Amounts.Add(19, 200);
        VATAmounts.Add(19, 38);
        Discounts.Add(19, 0);
        Totals.Add(Line.FieldName(Amount), 200);
        Totals.Add(Line.FieldName("Amount Including VAT"), 238);
        Totals.Add(Line.FieldName("Inv. Discount Amount"), 0);
        ExportZUGFeRD.InsertSupplyChainTradeTransaction(Root, Header, Line, 'EUR', Currency, Amounts, VATAmounts, Totals, Discounts);
        Document := XmlDocument.Create();
        Document.Add(Root);
        AssertBreakdown(Document, true, 'S', 19, 200, 38);
        Assert.AreEqual(0, Amounts.Count(), 'Consumed taxable amounts must be removed from the caller dictionary.');
        Assert.AreEqual(0, VATAmounts.Count(), 'Consumed VAT amounts must be removed from the caller dictionary.');
    end;

    [Test]
    procedure ZUGFeRDLegacyCreditMemoPreservesSuppliedTotals()
    var
        Header: Record "Sales Invoice Header";
        CreditHeader: Record "Sales Cr.Memo Header";
        Line: Record "Sales Cr.Memo Line";
        Currency: Record Currency;
        Document: XmlDocument;
        Root: XmlElement;
        Amounts, VATAmounts, Discounts: Dictionary of [Decimal, Decimal];
        Totals: Dictionary of [Text, Decimal];
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'S', 19, 100, 0, false, false);
        ExportFixture(Header, true, true, Document);
        CreditHeader.Get(Header."No.");
        Root := XmlElement.Create('CompatibilityTest');
        Line.SetRange("Document No.", Header."No.");
        Amounts.Add(19, 200);
        VATAmounts.Add(19, 38);
        Discounts.Add(19, 0);
        Totals.Add(Line.FieldName(Amount), 200);
        Totals.Add(Line.FieldName("Amount Including VAT"), 238);
        Totals.Add(Line.FieldName("Inv. Discount Amount"), 0);
        ExportZUGFeRD.InsertSupplyChainTradeTransaction(Root, CreditHeader, Line, 'EUR', Currency, Amounts, VATAmounts, Totals, Discounts);
        Document := XmlDocument.Create();
        Document.Add(Root);
        AssertBreakdown(Document, true, 'S', 19, 200, 38);
        Assert.AreEqual(0, Amounts.Count(), 'Consumed taxable amounts must be removed from the caller dictionary.');
        Assert.AreEqual(0, VATAmounts.Count(), 'Consumed VAT amounts must be removed from the caller dictionary.');
    end;

    local procedure VerifyMixedCategories(IsCII: Boolean; IsCreditMemo: Boolean; ReverseOrder: Boolean; WithDiscount: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
        FirstCategory, SecondCategory: Code[10];
        Discount: Decimal;
    begin
        // BR-E-01 / BR-Z-01: different categories must survive even at the same numeric rate.
        CreateFixture(Header);
        FirstCategory := 'E';
        SecondCategory := 'Z';
        if ReverseOrder then begin
            FirstCategory := 'Z';
            SecondCategory := 'E';
        end;
        if WithDiscount then
            Discount := 10;
        AddLine(Header, 10000, FirstCategory, 0, 100 - Discount, Discount, false, false);
        AddLine(Header, 20000, SecondCategory, 0, 200 - Discount, Discount, false, false);
        // A second line in the first category must aggregate, not create another breakdown.
        AddLine(Header, 30000, FirstCategory, 0, 50, 0, false, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, FirstCategory, 0, 150 - Discount, 0);
        AssertBreakdown(Document, IsCII, SecondCategory, 0, 200 - Discount, 0);
        AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        if WithDiscount then begin
            AssertAllowance(Document, IsCII, 'E', 10);
            AssertAllowance(Document, IsCII, 'Z', 10);
            if not IsCII then begin
                AssertDiscountBaseAndPercent(Document, FirstCategory, 150, Round(100 * Discount / 150, 0.00001));
                AssertDiscountBaseAndPercent(Document, SecondCategory, 200, 100 * Discount / 200);
            end;
        end;
        AssertPayable(Document, IsCII, 350 - 2 * Discount);
    end;

    local procedure VerifyStandardRates(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
    begin
        CreateFixture(Header);
        AddLine(Header, 10000, 'S', 7, 100, 0, false, false);
        AddLine(Header, 20000, 'S', 19, 200, 0, false, false);
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertBreakdown(Document, IsCII, 'S', 7, 100, 7);
        AssertBreakdown(Document, IsCII, 'S', 19, 200, 38);
        AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        AssertPayable(Document, IsCII, 345);
    end;

    [Test]
    procedure ReviewS1UBLInvoiceDifferentCategoryCharge()
    begin
        VerifyAssignedItemCharge(false, false, 20, false, false, false);
    end;

    [Test]
    procedure ReviewS1UBLInvoiceDifferentCategoryAllowance()
    begin
        VerifyAssignedItemCharge(false, false, -20, false, false, false);
    end;

    [Test]
    procedure ReviewS1UBLInvoiceResolvedDifferentCategory()
    begin
        VerifyAssignedItemCharge(false, false, 20, false, true, false);
    end;

    [Test]
    procedure ReviewS1UBLInvoiceResolvedSameCategory()
    begin
        VerifyAssignedItemCharge(false, false, 20, true, true, false);
    end;

    [Test]
    procedure ReviewS1UBLInvoiceForcedLineDifferentCategory()
    begin
        VerifyAssignedItemCharge(false, false, 20, false, false, true);
    end;

    [Test]
    procedure ReviewS2UBLInvoiceZeroDiscountBase()
    begin
        VerifyZeroDiscountBase(false, false);
    end;

    [Test]
    procedure ReviewS1UBLCreditMemoDifferentCategoryCharge()
    begin
        VerifyAssignedItemCharge(false, true, 20, false, false, false);
    end;

    [Test]
    procedure ReviewS1UBLCreditMemoDifferentCategoryAllowance()
    begin
        VerifyAssignedItemCharge(false, true, -20, false, false, false);
    end;

    [Test]
    procedure ReviewS1UBLCreditMemoResolvedDifferentCategory()
    begin
        VerifyAssignedItemCharge(false, true, 20, false, true, false);
    end;

    [Test]
    procedure ReviewS1UBLCreditMemoResolvedSameCategory()
    begin
        VerifyAssignedItemCharge(false, true, 20, true, true, false);
    end;

    [Test]
    procedure ReviewS1UBLCreditMemoForcedLineDifferentCategory()
    begin
        VerifyAssignedItemCharge(false, true, 20, false, false, true);
    end;

    [Test]
    procedure ReviewS2UBLCreditMemoZeroDiscountBase()
    begin
        VerifyZeroDiscountBase(false, true);
    end;

    [Test]
    procedure ReviewS1CIIInvoiceDifferentCategoryCharge()
    begin
        VerifyAssignedItemCharge(true, false, 20, false, false, false);
    end;

    [Test]
    procedure ReviewS1CIIInvoiceDifferentCategoryAllowance()
    begin
        VerifyAssignedItemCharge(true, false, -20, false, false, false);
    end;

    [Test]
    procedure ReviewS1CIIInvoiceResolvedDifferentCategory()
    begin
        VerifyAssignedItemCharge(true, false, 20, false, true, false);
    end;

    [Test]
    procedure ReviewS1CIIInvoiceResolvedSameCategory()
    begin
        VerifyAssignedItemCharge(true, false, 20, true, true, false);
    end;

    [Test]
    procedure ReviewS1CIIInvoiceForcedLineDifferentCategory()
    begin
        VerifyAssignedItemCharge(true, false, 20, false, false, true);
    end;

    [Test]
    procedure ReviewS2CIIInvoiceZeroDiscountBase()
    begin
        VerifyZeroDiscountBase(true, false);
    end;

    [Test]
    procedure ReviewS1CIICreditMemoDifferentCategoryCharge()
    begin
        VerifyAssignedItemCharge(true, true, 20, false, false, false);
    end;

    [Test]
    procedure ReviewS1CIICreditMemoDifferentCategoryAllowance()
    begin
        VerifyAssignedItemCharge(true, true, -20, false, false, false);
    end;

    [Test]
    procedure ReviewS1CIICreditMemoResolvedDifferentCategory()
    begin
        VerifyAssignedItemCharge(true, true, 20, false, true, false);
    end;

    [Test]
    procedure ReviewS1CIICreditMemoResolvedSameCategory()
    begin
        VerifyAssignedItemCharge(true, true, 20, true, true, false);
    end;

    [Test]
    procedure ReviewS1CIICreditMemoForcedLineDifferentCategory()
    begin
        VerifyAssignedItemCharge(true, true, 20, false, false, true);
    end;

    [Test]
    procedure ReviewS2CIICreditMemoZeroDiscountBase()
    begin
        VerifyZeroDiscountBase(true, true);
    end;

    local procedure VerifyAssignedItemCharge(IsCII: Boolean; IsCreditMemo: Boolean; ChargeAmount: Decimal; SameCategory: Boolean; UseSetupCategory: Boolean; ForceLineMapping: Boolean)
    var
        Header: Record "Sales Invoice Header";
        TargetLine: Record "Sales Invoice Line";
        ChargeLine: Record "Sales Invoice Line";
        CreditHeader: Record "Sales Cr.Memo Header";
        CreditChargeLine: Record "Sales Cr.Memo Line";
        CreditTargetLine: Record "Sales Cr.Memo Line";
        Service: Record "E-Document Service";
        Mapping: Codeunit "E-Doc. Item Charge Mapping";
        Structure: Enum "Item Charge E-Doc. Structure";
        Document: XmlDocument;
        ChargeCategory: Code[10];
        LinePath, ChargePath: Text;
        ExpectedLineAmount: Decimal;
    begin
        CreateFixture(Header);
        CompleteReviewHeader(Header);
        ChargeCategory := 'Z';
        if SameCategory then
            ChargeCategory := 'E';
        // In the fallback cases the target category is blank and resolves from VAT Posting Setup.
        // For the different-category case both source fields are blank, but resolve to E and Z.
        AddLine(Header, 10000, 'E', 0, 100, 0, false, UseSetupCategory);
        AddLine(Header, 20000, ChargeCategory, 0, ChargeAmount, 0, true, UseSetupCategory and not SameCategory);
        AssignItemCharge(Header, 10000, 20000, ForceLineMapping);
        if IsCreditMemo then
            CopyToCreditMemo(Header);
        Service."Item Charge E-Invoice Mapping" := Service."Item Charge E-Invoice Mapping"::Automatic;
        // Prove that the real mapper found the assigned line. No subscriber forces a test result.
        if IsCreditMemo then begin
            CreditHeader.Get(Header."No.");
            CreditChargeLine.Get(Header."No.", 20000);
            Structure := Mapping.GetItemChargeStructure(Service, CreditHeader, CreditChargeLine, CreditTargetLine);
            Assert.AreEqual(10000, CreditTargetLine."Line No.", 'The real mapper must resolve the assigned credit-memo line.');
        end else begin
            ChargeLine.Get(Header."No.", 20000);
            Structure := Mapping.GetItemChargeStructure(Service, Header, ChargeLine, TargetLine);
            Assert.AreEqual(10000, TargetLine."Line No.", 'The real mapper must resolve the assigned invoice line.');
        end;
        Assert.AreEqual(Structure::"Line Allowance/Charge".AsInteger(), Structure.AsInteger(), 'Fixture must exercise the real line-level mapping path.');
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        ExpectedLineAmount := 100;
        AssertReviewDeliveryAddress(Document, IsCII);
        if SameCategory then
            ExpectedLineAmount += ChargeAmount;
        LinePath := DocumentLinePath(IsCII);
        AssertNodeCount(Document, LinePath, 1);
        if IsCII then begin
            AssertDecimal(Document, LinePath + '/*[local-name()="SpecifiedLineTradeSettlement"]/*[local-name()="SpecifiedTradeSettlementLineMonetarySummation"]/*[local-name()="LineTotalAmount"]', ExpectedLineAmount);
            AssertNodeCount(Document, LinePath + '/*[local-name()="SpecifiedLineTradeSettlement"]/*[local-name()="ApplicableTradeTax"][*[local-name()="CategoryCode"]="E"]', 1);
            ChargePath := LinePath + '/*[local-name()="SpecifiedLineTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]';
        end else begin
            AssertDecimal(Document, LinePath + '/*[local-name()="LineExtensionAmount"]', ExpectedLineAmount);
            AssertNodeCount(Document, LinePath + '/*[local-name()="Item"]/*[local-name()="ClassifiedTaxCategory"][*[local-name()="ID"]="E"]', 1);
            ChargePath := LinePath + '/*[local-name()="AllowanceCharge"]';
        end;
        if SameCategory then begin
            AssertNodeCount(Document, ChargePath, 1);
            if IsCII then
                AssertDecimal(Document, ChargePath + '/*[local-name()="ActualAmount"]', Abs(ChargeAmount))
            else
                AssertDecimal(Document, ChargePath + '/*[local-name()="Amount"]', Abs(ChargeAmount));
            AssertNodeCount(Document, DocumentChargePath(IsCII), 0);
            AssertBreakdown(Document, IsCII, 'E', 0, 100 + ChargeAmount, 0);
            AssertNodeCount(Document, BreakdownPath(IsCII), 1);
        end else begin
            AssertNodeCount(Document, ChargePath, 0);
            AssertNodeCount(Document, DocumentChargePath(IsCII), 1);
            AssertAllowance(Document, IsCII, 'Z', Abs(ChargeAmount));
            if ChargeAmount > 0 then
                AssertNodeCount(Document, DocumentChargePath(IsCII) + '[.//*[local-name()="ChargeIndicator"][.="true" or *="true"]]', 1)
            else
                AssertNodeCount(Document, DocumentChargePath(IsCII) + '[.//*[local-name()="ChargeIndicator"][.="false" or *="false"]]', 1);
            AssertBreakdown(Document, IsCII, 'E', 0, 100, 0);
            AssertBreakdown(Document, IsCII, 'Z', 0, ChargeAmount, 0);
            AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        end;
        AssertPayable(Document, IsCII, 100 + ChargeAmount);
    end;

    local procedure AssignItemCharge(Header: Record "Sales Invoice Header"; TargetLineNo: Integer; ChargeLineNo: Integer; ForceLineMapping: Boolean)
    var
        TargetLine: Record "Sales Invoice Line";
        ChargeLine: Record "Sales Invoice Line";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ValueEntry: Record "Value Entry";
        EntryNo: Integer;
    begin
        Item."No." := Header."No.";
        Item.Description := 'Assigned item-charge regression item';
        Item.Insert();
        TargetLine.Get(Header."No.", TargetLineNo);
        TargetLine.Type := TargetLine.Type::Item;
        TargetLine."No." := Item."No.";
        TargetLine.Modify();
        ChargeLine.Get(Header."No.", ChargeLineNo);
        ItemCharge.Get(ChargeLine."No.");
        ItemCharge."E-Invoice Mapping" := ItemCharge."E-Invoice Mapping"::Automatic;
        if ForceLineMapping then
            ItemCharge."E-Invoice Mapping" := ItemCharge."E-Invoice Mapping"::"Line Allowance/Charge";
        ItemCharge.Modify();
        // Minimal isolated value-entry links used by the real mapper, not a posting or costing test.
        ValueEntry.LockTable();
        if ValueEntry.FindLast() then
            EntryNo := ValueEntry."Entry No.";
        EntryNo += 1;
        ValueEntry.Init();
        ValueEntry."Entry No." := EntryNo;
        ValueEntry."Item Ledger Entry No." := EntryNo;
        ValueEntry."Document No." := Header."No.";
        ValueEntry."Document Line No." := TargetLineNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry.Insert();
        ValueEntry."Entry No." := EntryNo + 1;
        ValueEntry."Document Line No." := ChargeLineNo;
        ValueEntry."Item Charge No." := ChargeLine."No.";
        ValueEntry.Insert();
    end;

    local procedure VerifyZeroDiscountBase(IsCII: Boolean; IsCreditMemo: Boolean)
    var
        Header: Record "Sales Invoice Header";
        Document: XmlDocument;
        Path: Text;
    begin
        CreateFixture(Header);
        CompleteReviewHeader(Header);
        AddLine(Header, 10000, 'E', 0, 90, 10, false, false);
        AddLine(Header, 20000, 'E', 0, -100, 0, true, false);
        AddLine(Header, 30000, 'Z', 0, 200, 0, false, false);
        // The E net base is -10; adding its discount of 10 gives a zero percentage denominator.
        ExportFixture(Header, IsCII, IsCreditMemo, Document);
        AssertReviewDeliveryAddress(Document, IsCII);
        AssertBreakdown(Document, IsCII, 'E', 0, -10, 0);
        AssertBreakdown(Document, IsCII, 'Z', 0, 200, 0);
        AssertNodeCount(Document, BreakdownPath(IsCII), 2);
        AssertNodeCount(Document, DocumentLinePath(IsCII), 2);
        AssertNodeCount(Document, DocumentChargePath(IsCII), 2);
        if IsCII then begin
            Path := DocumentChargePath(true) + '[*[local-name()="Reason"]="Document discount"]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="ActualAmount"]', 10);
            AssertDecimal(Document, '//*[local-name()="SpecifiedTradeSettlementHeaderMonetarySummation"]/*[local-name()="LineTotalAmount"]', 300);
            AssertDecimal(Document, '//*[local-name()="SpecifiedTradeSettlementHeaderMonetarySummation"]/*[local-name()="AllowanceTotalAmount"]', 110);
        end else begin
            Path := DocumentChargePath(false) + '[*[local-name()="AllowanceChargeReason"]="Document discount"]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="Amount"]', 10);
            AssertNodeCount(Document, Path + '/*[local-name()="BaseAmount" or local-name()="MultiplierFactorNumeric"]', 0);
            AssertNodeCount(Document, Path + '/*[local-name()="TaxCategory"][*[local-name()="ID"]="E"]', 1);
            AssertDecimal(Document, '/*/*[local-name()="LegalMonetaryTotal"]/*[local-name()="LineExtensionAmount"]', 300);
            AssertDecimal(Document, '/*/*[local-name()="LegalMonetaryTotal"]/*[local-name()="AllowanceTotalAmount"]', 110);
        end;
        AssertPayable(Document, IsCII, 190);
    end;

    local procedure CompleteReviewHeader(var Header: Record "Sales Invoice Header")
    begin
        // Full document validation also requires complete delivery and order-reference fixture data.
        // CII reads Sell-to fields; UBL reads Ship-to fields for the delivery address.
        Header."Sell-to Address" := Header."Bill-to Address";
        Header."Sell-to City" := Header."Bill-to City";
        Header."Sell-to Post Code" := Header."Bill-to Post Code";
        Header."Sell-to Country/Region Code" := Header."Bill-to Country/Region Code";
        Header."Ship-to Name" := Header."Bill-to Name";
        Header."Ship-to Address" := Header."Bill-to Address";
        Header."Ship-to City" := Header."Bill-to City";
        Header."Ship-to Post Code" := Header."Bill-to Post Code";
        Header."Ship-to Country/Region Code" := Header."Bill-to Country/Region Code";
        Header."Order No." := 'VAT-XML-ORDER';
        Header.Modify();
    end;

    local procedure AssertReviewDeliveryAddress(Document: XmlDocument; IsCII: Boolean)
    var
        Path: Text;
    begin
        if IsCII then begin
            Path := '//*[local-name()="ApplicableHeaderTradeDelivery"]/*[local-name()="ShipToTradeParty"]/*[local-name()="PostalTradeAddress"]';
            AssertNodeCount(Document, Path + '/*[local-name()="LineOne" and .="Test Street 2"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="CityName" and .="Berlin"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="PostcodeCode" and .="10115"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="CountryID" and .="DE"]', 1);
        end else begin
            Path := '/*/*[local-name()="Delivery"]/*[local-name()="DeliveryLocation"]/*[local-name()="Address"]';
            AssertNodeCount(Document, Path + '/*[local-name()="StreetName" and .="Test Street 2"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="CityName" and .="Berlin"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="PostalZone" and .="10115"]', 1);
            AssertNodeCount(Document, Path + '/*[local-name()="Country"]/*[local-name()="IdentificationCode" and .="DE"]', 1);
        end;
    end;

    local procedure DocumentLinePath(IsCII: Boolean): Text
    begin
        if IsCII then
            exit('//*[local-name()="IncludedSupplyChainTradeLineItem"]');
        exit('/*/*[local-name()="InvoiceLine" or local-name()="CreditNoteLine"]');
    end;

    local procedure DocumentChargePath(IsCII: Boolean): Text
    begin
        if IsCII then
            exit('//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"]');
        exit('/*/*[local-name()="AllowanceCharge"]');
    end;

    local procedure CopyToCreditMemo(Header: Record "Sales Invoice Header")
    var
        CreditHeader: Record "Sales Cr.Memo Header";
        InvoiceLine: Record "Sales Invoice Line";
        CreditLine: Record "Sales Cr.Memo Line";
    begin
        if CreditHeader.Get(Header."No.") then
            exit;
        CreditHeader.TransferFields(Header);
        CreditHeader."Return Order No." := Header."Order No.";
        CreditHeader.Insert();
        InvoiceLine.SetRange("Document No.", Header."No.");
        if InvoiceLine.FindSet() then
            repeat
                CreditLine.Init();
                CreditLine.TransferFields(InvoiceLine);
                CreditLine.Insert();
            until InvoiceLine.Next() = 0;
    end;

    local procedure CreateFixture(var Header: Record "Sales Invoice Header")
    var
        EDocumentService: Record "E-Document Service";
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
    begin
        // These are isolated posted-record fixtures for the real XML serializers, not posting tests.
        EDocumentService.SetFilter("Document Format", '%1|%2', EDocumentService."Document Format"::XRechnung, EDocumentService."Document Format"::ZUGFeRD);
        EDocumentService.DeleteAll();
        VATBusPostingGroup := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        if not CountryRegion.Get('DE') then begin
            CountryRegion.Code := 'DE';
            CountryRegion.Insert();
        end;
        CountryRegion."ISO Code" := 'DE';
        CountryRegion.Modify();
        CompanyInformation.Get();
        CompanyInformation.Name := 'VAT XML test seller';
        CompanyInformation.Address := 'Test Street 1';
        CompanyInformation.City := 'Berlin';
        CompanyInformation."Post Code" := '10115';
        CompanyInformation."Country/Region Code" := 'DE';
        CompanyInformation."VAT Registration No." := 'DE123456789';
        CompanyInformation.GLN := '1234567890128';
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation."E-Mail" := 'seller@example.com';
        CompanyInformation."Contact Person" := 'XML test';
        CompanyInformation."Phone No." := '030123456';
        CompanyInformation.Modify();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'EUR';
        GeneralLedgerSetup.Modify();
        Customer."No." := VATBusPostingGroup;
        Customer.Name := 'VAT XML test buyer';
        Customer.GLN := '1234567890135';
        Customer."Use GLN in Electronic Document" := true;
        Customer."E-Mail" := 'buyer@example.com';
        Customer.Insert();
        Header.Init();
        Header."No." := VATBusPostingGroup;
        Header."Sell-to Customer No." := Customer."No.";
        Header."Bill-to Customer No." := Customer."No.";
        Header."Sell-to Customer Name" := Customer.Name;
        Header."Bill-to Name" := Customer.Name;
        Header."Bill-to Address" := 'Test Street 2';
        Header."Bill-to City" := 'Berlin';
        Header."Bill-to Post Code" := '10115';
        Header."Bill-to Country/Region Code" := 'DE';
        Header."VAT Country/Region Code" := 'DE';
        Header."VAT Registration No." := 'DE987654321';
        Header."Buyer Reference" := 'VAT-XML-TEST';
        Header."Document Date" := 20260115D;
        Header."Posting Date" := 20260115D;
        Header."Due Date" := 20260215D;
        Header.Insert();
    end;

    local procedure AddLine(Header: Record "Sales Invoice Header"; LineNo: Integer; Category: Code[10]; Rate: Decimal; NetAmount: Decimal; InvoiceDiscount: Decimal; IsCharge: Boolean; UseSetupCategory: Boolean)
    var
        Line: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        ItemCharge: Record "Item Charge";
        VATProdPostingGroup: Code[20];
    begin
        VATProdPostingGroup := CopyStr(Category + Format(Rate, 0, 9), 1, 20);
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then begin
            VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
            VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
            VATPostingSetup."VAT %" := Rate;
            VATPostingSetup."Tax Category" := Category;
            if Category in ['E', 'O'] then begin
                VATClause.Code := CopyStr(CopyStr(VATBusPostingGroup, 1, 18) + Category, 1, MaxStrLen(VATClause.Code));
                if Category = 'O' then begin
                    VATClause.Description := 'Not subject to VAT';
                    VATClause."VATEX Code" := 'VATEX-EU-O';
                end else
                    VATClause.Description := 'Exempt from VAT';
                VATClause.Insert();
                VATPostingSetup."VAT Clause Code" := VATClause.Code;
            end;
            VATPostingSetup.Insert();
        end;
        Line."Document No." := Header."No.";
        Line."Line No." := LineNo;
        Line.Type := Line.Type::"G/L Account";
        Line."No." := 'VAT-XML-TEST';
        if IsCharge then begin
            ItemCharge."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
            ItemCharge."E-Invoice Mapping" := ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge";
            ItemCharge.Insert();
            Line.Type := Line.Type::"Charge (Item)";
            Line."No." := ItemCharge."No.";
        end;
        Line.Description := 'VAT XML test line';
        Line.Quantity := 1;
        Line."Unit of Measure Code" := 'C62';
        Line."VAT Bus. Posting Group" := VATBusPostingGroup;
        Line."VAT Prod. Posting Group" := VATProdPostingGroup;
        if not UseSetupCategory then
            Line."Tax Category" := Category;
        Line."VAT %" := Rate;
        Line.Amount := NetAmount;
        Line."Amount Including VAT" := NetAmount * (1 + Rate / 100);
        Line."Inv. Discount Amount" := InvoiceDiscount;
        Line."Line Amount" := NetAmount + InvoiceDiscount;
        Line."Unit Price" := Line."Line Amount";
        Line.Insert();
    end;

    local procedure ExportFixture(Header: Record "Sales Invoice Header"; IsCII: Boolean; IsCreditMemo: Boolean; var Document: XmlDocument)
    var
        CreditHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
    begin
        TempBlob.CreateOutStream(Output, TextEncoding::UTF8);
        if IsCreditMemo then begin
            CopyToCreditMemo(Header);
            CreditHeader.Get(Header."No.");
            if IsCII then
                ExportZUGFeRD.CreateXML(CreditHeader, Output)
            else
                ExportXRechnung.CreateXML(CreditHeader, Output);
        end else
            if IsCII then
                ExportZUGFeRD.CreateXML(Header, Output)
            else
                ExportXRechnung.CreateXML(Header, Output);
        TempBlob.CreateInStream(Input, TextEncoding::UTF8);
        XmlDocument.ReadFrom(Input, Document);
    end;

    local procedure BreakdownPath(IsCII: Boolean): Text
    begin
        if IsCII then
            exit('//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="ApplicableTradeTax"]');
        exit('/*/*[local-name()="TaxTotal"]/*[local-name()="TaxSubtotal"]');
    end;

    local procedure AssertBreakdown(Document: XmlDocument; IsCII: Boolean; Category: Text; Rate: Decimal; Basis: Decimal; Tax: Decimal)
    var
        Path: Text;
    begin
        if IsCII then begin
            Path := BreakdownPath(true) + '[*[local-name()="CategoryCode"]="' + Category + '" and *[local-name()="RateApplicablePercent"]=' + Format(Rate, 0, 9) + ']';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="BasisAmount"]', Basis);
            AssertDecimal(Document, Path + '/*[local-name()="CalculatedAmount"]', Tax);
        end else begin
            Path := BreakdownPath(false) + '[*[local-name()="TaxCategory"][*[local-name()="ID"]="' + Category + '" and *[local-name()="Percent"]=' + Format(Rate, 0, 9) + ']]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="TaxableAmount"]', Basis);
            AssertDecimal(Document, Path + '/*[local-name()="TaxAmount"]', Tax);
        end;
    end;

    local procedure AssertAllowance(Document: XmlDocument; IsCII: Boolean; Category: Text; Amount: Decimal)
    var
        Path: Text;
    begin
        if IsCII then begin
            Path := '//*[local-name()="ApplicableHeaderTradeSettlement"]/*[local-name()="SpecifiedTradeAllowanceCharge"][*[local-name()="CategoryTradeTax"]/*[local-name()="CategoryCode"]="' + Category + '"]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="ActualAmount"]', Amount);
        end else begin
            Path := '/*/*[local-name()="AllowanceCharge"][*[local-name()="TaxCategory"]/*[local-name()="ID"]="' + Category + '"]';
            AssertNodeCount(Document, Path, 1);
            AssertDecimal(Document, Path + '/*[local-name()="Amount"]', Amount);
        end;
    end;

    local procedure AssertDiscountBaseAndPercent(Document: XmlDocument; Category: Text; Basis: Decimal; Percent: Decimal)
    var
        Path: Text;
    begin
        Path := '/*/*[local-name()="AllowanceCharge"][*[local-name()="TaxCategory"]/*[local-name()="ID"]="' + Category + '"]';
        AssertNodeCount(Document, Path, 1);
        AssertDecimal(Document, Path + '/*[local-name()="BaseAmount"]', Basis);
        AssertDecimal(Document, Path + '/*[local-name()="MultiplierFactorNumeric"]', Percent);
    end;

    local procedure AssertPayable(Document: XmlDocument; IsCII: Boolean; Amount: Decimal)
    begin
        if IsCII then
            AssertDecimal(Document, '//*[local-name()="SpecifiedTradeSettlementHeaderMonetarySummation"]/*[local-name()="DuePayableAmount"]', Amount)
        else
            AssertDecimal(Document, '/*/*[local-name()="LegalMonetaryTotal"]/*[local-name()="PayableAmount"]', Amount);
    end;

    local procedure AssertNodeCount(Document: XmlDocument; Path: Text; Expected: Integer)
    var
        Nodes: XmlNodeList;
    begin
        Document.SelectNodes(Path, Nodes);
        Assert.AreEqual(Expected, Nodes.Count(), Path);
    end;

    local procedure AssertDecimal(Document: XmlDocument; Path: Text; Expected: Decimal)
    var
        Node: XmlNode;
        Actual: Decimal;
    begin
        Assert.IsTrue(Document.SelectSingleNode(Path, Node), Path);
        Evaluate(Actual, Node.AsXmlElement().InnerText(), 9);
        Assert.AreEqual(Expected, Actual, Path);
    end;
}
