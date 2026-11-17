// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
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
        ExpectedScheduleInvoiceNo: Code[20];
        ExpectedScheduleAmount: Decimal;

    [Test]
    procedure SelectingTermsCreatesOwnedRuleSnapshot()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
    begin
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Selecting installment terms creates an invoice-owned draft snapshot without caching calculated values.
        // [GIVEN] A sales invoice and payment terms containing two equal installment rules.
        // [WHEN] The installment terms are selected on the invoice.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        // [THEN] The invoice owns both snapshotted rules and summarizes the first due date without storing calculated line values.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Changing the document date retains the owned rule snapshot even when reusable rules have changed.
        // [GIVEN] An installment invoice whose reusable payment percentage and due-date formula are subsequently changed.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        PlanID := SalesHeader."Installment Plan ID";
        Rule.Get(PaymentTerms.Code, 10000);
        Rule."Payment %" := 20;
        Evaluate(Rule."Due Date Calculation", '<120D>');
        Rule.Modify();

        // [WHEN] The document date is moved forward by one day.
        SalesHeader.Validate("Document Date", CalcDate('<1D>', SalesHeader."Document Date"));
        SalesHeader.Modify(true);

        // [THEN] The same plan and original percentage are retained, and the due date uses the snapshotted formula.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Explicitly changing installment terms replaces the invoice's owned draft snapshot.
        // [GIVEN] An installment invoice and another set of installment payment terms.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        CreateRules(ReplacementTerms);

        // [WHEN] The replacement terms are selected on the invoice.
        SalesHeader.Validate("Payment Terms Code", ReplacementTerms.Code);
        SalesHeader.Modify(true);

        // [THEN] A new snapshot identifies the replacement terms, and the old draft header and lines are removed.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Switching to ordinary payment terms removes the invoice's draft installment plan.
        // [GIVEN] An installment invoice and payment terms without installment rules.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);

        // [WHEN] The ordinary payment terms are selected on the invoice.
        SalesHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        SalesHeader.Modify(true);

        // [THEN] The plan link, owned draft header, and draft lines are removed.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Adding reusable installment rules does not implicitly activate an existing ordinary invoice.
        // [GIVEN] An invoice using ordinary terms to which installment rules are subsequently added.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        SalesHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        SalesHeader.Modify(true);
        CreateRuleLines(OrdinaryTerms.Code);

        // [WHEN] The existing invoice's document date is revalidated.
        SalesHeader.Validate("Document Date", CalcDate('<1D>', SalesHeader."Document Date"));
        SalesHeader.Modify(true);

        // [THEN] The invoice remains without a plan and retains native payment-term due-date calculation.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Changing the bill-to customer applies that customer's ordinary terms and removes the old draft plan.
        // [GIVEN] An installment invoice and another customer using ordinary payment terms.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        OldPlanID := SalesHeader."Installment Plan ID";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", OrdinaryTerms.Code);
        Customer.Modify(true);

        // [WHEN] The invoice's bill-to customer is changed.
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] The new customer's terms replace the old terms, and the old owned draft is removed.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Copying and then deleting an invoice preserves the source's independently owned rule snapshot.
        // [GIVEN] Source and target invoices with owned plans, and reusable source rules changed after snapshot creation.
        CreateInvoiceWithPlan(SourceHeader, PaymentTerms);
        CreateInvoiceWithPlan(TargetHeader, TargetTerms);
        ReplacedPlanID := TargetHeader."Installment Plan ID";
        Rule.Get(PaymentTerms.Code, 10000);
        Rule."Payment %" := 20;
        Rule.Modify();
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);

        // [WHEN] The source invoice is copied over the target invoice.
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Invoice, SourceHeader."No.", TargetHeader);

        // [THEN] The target owns an independent copy of the source snapshot, and its previous plan is removed.
        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        Assert.AreNotEqual(SourceHeader."Installment Plan ID", TargetHeader."Installment Plan ID", 'Copied invoices must not share mutable plans.');
        Plan.Get(TargetHeader."Installment Plan ID");
        Assert.AreEqual(TargetHeader.SystemId, Plan."Source SystemId", 'The copy must own the copied plan.');
        Assert.IsFalse(Plan.Get(ReplacedPlanID), 'Copying over an invoice must remove its previous owned plan.');
        PlanLine.Get(TargetHeader."Installment Plan ID", 10000);
        Assert.AreEqual(50, PlanLine."Payment %", 'Copy Document must copy the source snapshot, not changed reusable setup.');

        // [WHEN] The copied target invoice is subsequently deleted.
        TargetHeader.Delete(false);

        // [THEN] The source invoice's plan still exists.
        Assert.IsTrue(Plan.Get(SourceHeader."Installment Plan ID"), 'Deleting a copy must not remove the source plan.');
    end;

    [Test]
    procedure UnsavedHeaderDoesNotLeaveAnOrphanPlan()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        Plan: Record "Installment Plan";
    begin
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Validating and then inserting a new invoice defers plan ownership until its SystemId is assigned.
        // [GIVEN] Installment payment terms and a sales invoice header that has not been inserted.
        CreateRules(PaymentTerms);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SalesHeader."No."));
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Posting Date" := WorkDate();

        // [WHEN] Installment payment terms are validated before the invoice is inserted.
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] No orphan plan or premature ownership link is persisted.
        Plan.SetRange("Payment Terms Code", PaymentTerms.Code);
        Assert.IsTrue(Plan.IsEmpty(), 'Validation before insertion must not persist a plan.');
        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'An unsaved invoice must not claim ownership of a plan.');

        // [WHEN] The same invoice header is subsequently inserted.
        SalesHeader.Insert(false);

        // [THEN] The new snapshot is owned by the invoice's assigned SystemId.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Deleting an invoice without its table trigger still removes its owned draft plan.
        // [GIVEN] An invoice with an owned installment plan.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        PlanID := SalesHeader."Installment Plan ID";

        // [WHEN] The invoice is deleted with RunTrigger set to false.
        SalesHeader.Delete(false);

        // [THEN] Neither the draft header nor its lines remain.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Opening and reopening preview recalculates live invoice totals without persisting calculated amounts.
        // [GIVEN] An installment invoice with VAT and an applied invoice discount, with automatic discounting and rounding disabled.
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

        // [WHEN] The installment schedule is previewed.
        SalesInstallmentMgt.CalculatePreview(SalesHeader, TempPlanLine);

        // [THEN] The preview reconciles to the current VAT-inclusive discounted total in document currency and LCY.
        SalesHeader.CalcFields("Amount Including VAT");
        TempPlanLine.CalcSums(Amount, "Amount (LCY)");
        Assert.AreEqual(SalesHeader."Amount Including VAT", TempPlanLine.Amount, 'Preview must include current VAT and invoice discounts.');
        Assert.AreEqual(TempPlanLine.Amount, TempPlanLine."Amount (LCY)", 'LCY documents must reconcile in both columns.');
        // [GIVEN] The invoice quantity is subsequently increased.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate(Quantity, 3);
        SalesLine.Modify(true);

        // [WHEN] The schedule is previewed again.
        SalesInstallmentMgt.CalculatePreview(SalesHeader, TempPlanLine);

        // [THEN] The preview uses the changed total, and no calculated monetary amounts are stored on draft lines.
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
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] The invoice header due date cannot override the installment schedule's first due date.
        // [GIVEN] An invoice with an owned installment plan.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        // [WHEN] The header due date is changed independently of the schedule.
        asserterror SalesHeader.Validate("Due Date", CalcDate('<1D>', SalesHeader."Due Date"));

        // [THEN] Validation rejects the change because the header date is only the first installment summary.
        Assert.ExpectedError('first installment summary');
    end;

    [Test]
    procedure HeaderDiscountCannotOverrideTheSchedule()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] Header payment discount conditions cannot override installment-level conditions.
        // [GIVEN] An invoice with an owned installment plan.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);

        // [WHEN] A header payment discount date is entered.
        asserterror SalesHeader.Validate("Pmt. Discount Date", SalesHeader."Document Date");

        // [THEN] Validation rejects the nonzero header payment discount condition.
        Assert.ExpectedError('header payment discount conditions must be zero');
    end;

    [Test]
    [HandlerFunctions('InstallmentScheduleHandler')]
    procedure HeaderConditionErrorActionOpensTheSavedInvoiceSchedule()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        ScheduleErrorInfo: ErrorInfo;
    begin
        // [FEATURE] [Installments] [Draft]
        // [SCENARIO] The header-condition error action opens the saved invoice's calculated installment schedule.
        // [GIVEN] An installment invoice with a priced line and error context identifying that invoice.
        CreateInvoiceWithPlan(SalesHeader, PaymentTerms);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Amount Including VAT");
        ExpectedScheduleInvoiceNo := SalesHeader."No.";
        ExpectedScheduleAmount := SalesHeader."Amount Including VAT" / 2;
        ScheduleErrorInfo.RecordId(SalesHeader.RecordId());

        // [WHEN] The error's schedule action is invoked.
        SalesInstallmentMgt.ShowScheduleFromError(ScheduleErrorInfo);
        // [THEN] The page handler verifies the invoice number, both calculated amounts, and that no other installments appear.
    end;

    [PageHandler]
    procedure InstallmentScheduleHandler(var SalesInstallmentSchedule: TestPage "Sales Installment Schedule")
    begin
        SalesInstallmentSchedule.SourceDocumentNo.AssertEquals(ExpectedScheduleInvoiceNo);
        Assert.IsTrue(SalesInstallmentSchedule.First(), 'The action must open the calculated schedule.');
        SalesInstallmentSchedule.Amount.AssertEquals(ExpectedScheduleAmount);
        Assert.IsTrue(SalesInstallmentSchedule.Next(), 'Both installments must be shown.');
        SalesInstallmentSchedule.Amount.AssertEquals(ExpectedScheduleAmount);
        Assert.IsFalse(SalesInstallmentSchedule.Next(), 'The schedule must contain only this invoice''s installments.');
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
