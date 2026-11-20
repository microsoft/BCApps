// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 134494 "ERM Installments UI"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInstallments: Codeunit "Library - ERM Installments";
        SalesInstallmentHistory: Codeunit "Sales Installment History";

    [Test]
    procedure FeatureSwitchControlsGlobalPaymentTermsVisibility()
    var
        PaymentTerms: TestPage "Payment Terms";
    begin
        LibraryInstallments.SetFeatureEnabled(false);
        PaymentTerms.OpenView();
        Assert.IsFalse(PaymentTerms."Has Installments".Visible(), 'Global installment setup must be hidden when the feature is disabled.');
        Assert.IsFalse(PaymentTerms.InstallmentLines.Visible(), 'Global installment rules must be hidden when the feature is disabled.');
        PaymentTerms.Close();

        LibraryInstallments.SetFeatureEnabled(true);
        PaymentTerms.OpenView();
        Assert.IsTrue(PaymentTerms."Has Installments".Visible(), 'Global installment setup must be visible when the feature is enabled.');
        Assert.IsTrue(PaymentTerms.InstallmentLines.Visible(), 'Global installment rules must be visible when the feature is enabled.');
        PaymentTerms.Close();
    end;

    [Test]
    procedure PostedScheduleShowsOriginalRulesAndCurrentEntryBalances()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        Rule: Record "Payment Term Installment";
        PostedSchedule: TestPage "Posted Installment Schedule";
    begin
        // [FEATURE] [Installments] [UI]
        // [SCENARIO] The posted schedule shows snapshotted rules and current installment balances as read-only.
        // [GIVEN] A posted invoice with changed reusable rules and a partially paid final installment.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Rule.Get(SalesInvoiceHeader."Payment Terms Code", 30000);
        Rule."Discount %" := 9;
        Evaluate(Rule."Discount Date Calculation", '<10D>');
        Rule.Modify(true);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 10);
        PlanLine.SetRange("Plan ID", SalesInvoiceHeader."Installment Plan ID");
        PlanLine.SetRange("Installment No.", 3);
        PlanLine.FindFirst();
        PostedSchedule.Trap();

        // [WHEN] The posted installment schedule is opened.
        SalesInstallmentHistory.ShowSchedule(SalesInvoiceHeader);

        // [THEN] The page shows the original allocation and discount, the current balance, and a read-only amount.
        PostedSchedule.GoToRecord(PlanLine);
        PostedSchedule.Amount.AssertEquals(41.66);
        PostedSchedule.RemainingAmount.AssertEquals(31.66);
        PostedSchedule."Discount %".AssertEquals(0);
        Assert.IsFalse(PostedSchedule.Amount.Editable(), 'The posted allocation must remain read-only.');
        PostedSchedule.Close();
    end;
}
