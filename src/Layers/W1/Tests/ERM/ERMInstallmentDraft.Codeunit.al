// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 134492 "ERM Installment Draft"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        SalesInstallmentMgt: Codeunit "Sales Installment Mgt.";

    [Test]
    procedure SelectingTermsCreatesOwnedRuleSnapshot()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        Plan.Get(SalesHeader."Installment Plan ID");
        Assert.AreEqual(SalesHeader.SystemId, Plan."Source SystemId", 'The invoice must own its plan.');
        Assert.AreEqual(SalesHeader.RecordId(), Plan."Source Record ID", 'The source must identify the typed sales document.');
        Assert.AreEqual(Plan.Status::Draft, Plan.Status, 'A new plan must be draft.');
        Assert.AreEqual(CalcDate('<30D>', SalesHeader."Document Date"), SalesHeader."Due Date", 'The header must summarize the first installment.');
        Assert.AreEqual(0, SalesHeader."Payment Discount %", 'Header discount conditions must not override installments.');
        PlanLine.SetRange("Plan ID", Plan.ID);
        Assert.AreEqual(2, PlanLine.Count(), 'Both rule snapshots must be stored.');
        PlanLine.FindFirst();
        Assert.AreEqual(0, PlanLine.Amount, 'Draft calculated amounts must not be cached.');
        Assert.AreEqual(0D, PlanLine."Due Date", 'Draft calculated dates must not be cached.');
    end;

    [Test]
    procedure DateRevalidationDoesNotReloadChangedSetup()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Rule: Record "Payment Term Installment";
        PlanLine: Record "Installment Plan Line";
        PlanID: Guid;
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        PlanID := SalesHeader."Installment Plan ID";
        Rule.Get(PaymentTerms.Code, 10000);
        Rule."Payment %" := 20;
        Evaluate(Rule."Due Date Calculation", '<120D>');
        Rule.Modify();

        SalesHeader.Validate("Document Date", CalcDate('<1D>', SalesHeader."Document Date"));
        SalesHeader.Modify(true);

        Assert.AreEqual(PlanID, SalesHeader."Installment Plan ID", 'Date validation must retain the existing snapshot.');
        Assert.AreEqual(CalcDate('<30D>', SalesHeader."Document Date"), SalesHeader."Due Date", 'Dates must use the snapshotted formula.');
        PlanLine.Get(PlanID, 10000);
        Assert.AreEqual(50, PlanLine."Payment %", 'Changed or incomplete reusable setup must not replace the snapshot.');
    end;

    [Test]
    procedure ChangingTermsReplacesOnlyTheOwnedPlan()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        ReplacementTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        OldPlanID: Guid;
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        CreateRules(ReplacementTerms);

        SalesHeader.Validate("Payment Terms Code", ReplacementTerms.Code);
        SalesHeader.Modify(true);

        Assert.AreNotEqual(OldPlanID, SalesHeader."Installment Plan ID", 'Explicitly changing terms must create a new snapshot.');
        Assert.IsFalse(Plan.Get(OldPlanID), 'The replaced draft header must be removed.');
        PlanLine.SetRange("Plan ID", OldPlanID);
        Assert.IsTrue(PlanLine.IsEmpty(), 'The replaced draft lines must be removed.');
        Plan.Get(SalesHeader."Installment Plan ID");
        Assert.AreEqual(ReplacementTerms.Code, Plan."Payment Terms Code", 'The new snapshot must identify the selected terms.');
    end;

    [Test]
    procedure OrdinaryTermsRemoveTheDraftPlan()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        OrdinaryTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        OldPlanID: Guid;
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);

        SalesHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        SalesHeader.Modify(true);

        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'Ordinary terms must remove the plan link.');
        Assert.IsFalse(Plan.Get(OldPlanID), 'The unused draft plan must be removed.');
        PlanLine.SetRange("Plan ID", OldPlanID);
        Assert.IsTrue(PlanLine.IsEmpty(), 'The unused draft lines must be removed.');
    end;

    [Test]
    procedure AddingSetupDoesNotActivateAnExistingOrdinaryInvoice()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        OrdinaryTerms: Record "Payment Terms";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        SalesHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        SalesHeader.Modify(true);
        CreateRuleLines(OrdinaryTerms.Code);

        SalesHeader.Validate("Document Date", CalcDate('<1D>', SalesHeader."Document Date"));
        SalesHeader.Modify(true);

        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'Adding reusable setup must not implicitly activate an existing ordinary invoice.');
        Assert.AreEqual(
            CalcDate(OrdinaryTerms."Due Date Calculation", SalesHeader."Document Date"), SalesHeader."Due Date",
            'An ordinary invoice must retain native due-date calculation.');
    end;

    [Test]
    procedure ChangingBillToCustomerReplacesTheDraftTerms()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        OrdinaryTerms: Record "Payment Terms";
        Customer: Record Customer;
        Plan: Record "Installment Plan";
        OldPlanID: Guid;
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", OrdinaryTerms.Code);
        Customer.Modify(true);

        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        Assert.AreEqual(OrdinaryTerms.Code, SalesHeader."Payment Terms Code", 'Bill-to changes must use the new customer terms.');
        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'An ordinary bill-to customer must remove the old global plan.');
        Assert.IsFalse(Plan.Get(OldPlanID), 'Bill-to changes must not leave the old owned draft.');
    end;

    [Test]
    procedure CopyDocumentCreatesAnIndependentSnapshot()
    var
        SourceHeader: Record "Sales Header";
        TargetHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        TargetTerms: Record "Payment Terms";
        Rule: Record "Payment Term Installment";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ReplacedPlanID: Guid;
    begin
        CreateInvoiceWithPlan(SourceHeader, PaymentTerms);
        CreateInvoiceWithPlan(TargetHeader, TargetTerms);
        ReplacedPlanID := TargetHeader."Installment Plan ID";
        Rule.Get(PaymentTerms.Code, 10000);
        Rule."Payment %" := 20;
        Rule.Modify();
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);

        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Invoice, SourceHeader."No.", TargetHeader);

        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        Assert.AreNotEqual(SourceHeader."Installment Plan ID", TargetHeader."Installment Plan ID", 'Copied invoices must not share mutable plans.');
        Plan.Get(TargetHeader."Installment Plan ID");
        Assert.AreEqual(TargetHeader.SystemId, Plan."Source SystemId", 'The copy must own the copied plan.');
        Assert.IsFalse(Plan.Get(ReplacedPlanID), 'Copying over an invoice must remove its previous owned plan.');
        PlanLine.Get(TargetHeader."Installment Plan ID", 10000);
        Assert.AreEqual(50, PlanLine."Payment %", 'Copy Document must copy the source snapshot, not changed reusable setup.');

        TargetHeader.Delete(false);

        Assert.IsTrue(Plan.Get(SourceHeader."Installment Plan ID"), 'Deleting a copy must not remove the source plan.');
    end;

    [Test]
    procedure UnsavedHeaderDoesNotLeaveAnOrphanPlan()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
    begin
        CreateRules(PaymentTerms);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SalesHeader."No."));
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Posting Date" := WorkDate();

        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        Plan.SetRange("Payment Terms Code", PaymentTerms.Code);
        Assert.IsTrue(Plan.IsEmpty(), 'Validation before insertion must not persist a plan.');
        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'An unsaved invoice must not claim ownership of a plan.');

        SalesHeader.Insert(false);

        Plan.Get(SalesHeader."Installment Plan ID");
        Assert.AreEqual(SalesHeader.SystemId, Plan."Source SystemId", 'Insertion must bind the snapshot to the assigned SystemId.');
    end;

    [Test]
    procedure DeleteWithoutTableTriggerRemovesOwnedDraft()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        PlanID: Guid;
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        PlanID := SalesHeader."Installment Plan ID";

        SalesHeader.Delete(false);

        Assert.IsFalse(Plan.Get(PlanID), 'Deletion must remove the draft even when RunTrigger is false.');
        PlanLine.SetRange("Plan ID", PlanID);
        Assert.IsTrue(PlanLine.IsEmpty(), 'Deletion must not leave draft lines.');
    end;

    [Test]
    procedure PreviewUsesCurrentVATAndInvoiceDiscountTotalsWithoutCaching()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        PlanLine: Record "Installment Plan Line";
        TempPlanLine: Record "Installment Plan Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        DiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        SalesSetup.Get();
        SalesSetup."Invoice Rounding" := false;
        SalesSetup."Calc. Inv. Discount" := false;
        SalesSetup.Modify();
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        DiscountByType.ApplyInvDiscBasedOnAmt(10, SalesHeader);

        SalesInstallmentMgt.CalculatePreview(SalesHeader, TempPlanLine);

        SalesHeader.CalcFields("Amount Including VAT");
        TempPlanLine.CalcSums(Amount, "Amount (LCY)");
        Assert.AreEqual(SalesHeader."Amount Including VAT", TempPlanLine.Amount, 'Preview must include current VAT and invoice discounts.');
        Assert.AreEqual(TempPlanLine.Amount, TempPlanLine."Amount (LCY)", 'LCY documents must reconcile in both columns.');
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate(Quantity, 3);
        SalesLine.Modify(true);

        SalesInstallmentMgt.CalculatePreview(SalesHeader, TempPlanLine);

        SalesHeader.CalcFields("Amount Including VAT");
        TempPlanLine.CalcSums(Amount);
        Assert.AreEqual(SalesHeader."Amount Including VAT", TempPlanLine.Amount, 'Reopening preview must use changed line totals.');
        PlanLine.SetRange("Plan ID", SalesHeader."Installment Plan ID");
        PlanLine.SetFilter(Amount, '<>0');
        Assert.IsTrue(PlanLine.IsEmpty(), 'Preview must not persist calculated monetary amounts.');
    end;

    [Test]
    procedure HeaderDueDateCannotOverrideTheSchedule()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        asserterror SalesHeader.Validate("Due Date", CalcDate('<1D>', SalesHeader."Due Date"));

        Assert.ExpectedError('first installment summary');
    end;

    [Test]
    procedure HeaderDiscountCannotOverrideTheSchedule()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        asserterror SalesHeader.Validate("Pmt. Discount Date", SalesHeader."Document Date");

        Assert.ExpectedError('header payment discount conditions must be zero');
    end;

    [Test]
    procedure InstallmentInvoiceCannotApplyDuringPosting()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        SalesPost: Codeunit "Sales-Post";
    begin
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        SalesHeader."Applies-to ID" := 'INSTALLMENT';

        asserterror SalesPost.Run(SalesHeader);

        Assert.ExpectedError('Applies-to ID');
    end;

    local procedure CreateInvoiceWithPlan(var SalesHeader: Record "Sales Header"; var PaymentTerms: Record "Payment Terms")
    var
        Customer: Record Customer;
        OrdinaryTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        Customer.Validate("Payment Terms Code", OrdinaryTerms.Code);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateRules(PaymentTerms);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
    end;

    local procedure CreateRules(var PaymentTerms: Record "Payment Terms")
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateRuleLines(PaymentTerms.Code);
    end;

    local procedure CreateRuleLines(PaymentTermsCode: Code[10])
    var
        Rule: Record "Payment Term Installment";
    begin
        Rule.Init();
        Rule."Payment Terms Code" := PaymentTermsCode;
        Rule."Line No." := 10000;
        Rule."Payment %" := 50;
        Evaluate(Rule."Due Date Calculation", '<30D>');
        Rule.Insert(true);
        Rule."Line No." := 20000;
        Evaluate(Rule."Due Date Calculation", '<60D>');
        Rule.Insert(true);
    end;
}
