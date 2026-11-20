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

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [UI]
    end;

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
        // [SCENARIO] Global installment setup is visible only while its feature is enabled.
        // [GIVEN] The global Payment Installments feature is disabled.
        LibraryInstallments.SetFeatureEnabled(false);

        // [WHEN] Payment terms are opened.
        PaymentTerms.OpenView();

        // [THEN] Installment indicators and rule actions are hidden.
        Assert.IsFalse(PaymentTerms."Has Installments".Visible(), 'Global installment setup must be hidden when the feature is disabled.');
        Assert.IsFalse(PaymentTerms.InstallmentLines.Visible(), 'Global installment rules must be hidden when the feature is disabled.');
        PaymentTerms.Close();

        LibraryInstallments.SetFeatureEnabled(true);
        // [WHEN] Payment terms are reopened with the feature enabled.
        PaymentTerms.OpenView();
        // [THEN] Installment indicators and rule actions are visible.
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
        // [GIVEN] A posted invoice with changed reusable rules, a settled first installment, and a partially paid final installment.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Rule.Get(SalesInvoiceHeader."Payment Terms Code", 30000);
        Rule."Discount %" := 9;
        Evaluate(Rule."Discount Date Calculation", '<10D>');
        Rule.Modify(true);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 10);
        PlanLine.SetRange("Plan ID", SalesInvoiceHeader."Installment Plan ID");
        PlanLine.SetRange("Installment No.", 3);
        PlanLine.FindFirst();
        PostedSchedule.Trap();

        // [WHEN] The posted installment schedule is opened.
        SalesInstallmentHistory.ShowSchedule(SalesInvoiceHeader);

        // [THEN] The page shows the original allocation and discount, the current balance, and a read-only amount.
        Assert.IsTrue(PostedSchedule.First(), 'The settled installment must remain visible.');
        PostedSchedule."Installment No.".AssertEquals(1);
        PostedSchedule.RemainingAmount.AssertEquals(0);
        PostedSchedule.RemainingAmountLCY.AssertEquals(0);
        PostedSchedule.Open.AssertEquals(false);
        Assert.IsTrue(PostedSchedule.Next(), 'The unpaid middle installment must remain visible.');
        PostedSchedule."Installment No.".AssertEquals(2);
        PostedSchedule.RemainingAmount.AssertEquals(41.67);
        PostedSchedule.RemainingAmountLCY.AssertEquals(41.67);
        PostedSchedule.Open.AssertEquals(true);
        PostedSchedule.GoToRecord(PlanLine);
        PostedSchedule.Amount.AssertEquals(41.66);
        PostedSchedule.RemainingAmount.AssertEquals(31.66);
        PostedSchedule.RemainingAmountLCY.AssertEquals(31.66);
        PostedSchedule.Open.AssertEquals(true);
        PostedSchedule."Discount %".AssertEquals(0);
        Assert.IsFalse(PostedSchedule.Amount.Editable(), 'The posted allocation must remain read-only.');
        PostedSchedule.Close();
    end;

    [Test]
    procedure PostedScheduleRefreshesBalancesWhenDatasetIsRefiltered()
    var
        Invoice: Record "Sales Invoice Header";
        PostedSchedule: TestPage "Posted Installment Schedule";
    begin
        // [SCENARIO] Refreshing the posted schedule dataset reloads balances changed after its initial display.
        // [GIVEN] An open schedule whose final installment receives a partial payment after the page is loaded.
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        PostedSchedule.Trap();
        SalesInstallmentHistory.ShowSchedule(Invoice);
        Assert.IsTrue(PostedSchedule.Last(), 'The final installment must be visible.');
        PostedSchedule.RemainingAmount.AssertEquals(41.66);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 10);

        // [WHEN] The dataset is refreshed by filtering to the final installment.
        PostedSchedule.Filter.SetFilter("Installment No.", '3');

        // [THEN] The page displays the new remaining balances rather than its initial cached values.
        Assert.IsTrue(PostedSchedule.First(), 'The selected installment must remain visible.');
        PostedSchedule.RemainingAmount.AssertEquals(31.66);
        PostedSchedule.RemainingAmountLCY.AssertEquals(31.66);
        PostedSchedule.Open.AssertEquals(true);
        PostedSchedule.Close();
    end;
}
