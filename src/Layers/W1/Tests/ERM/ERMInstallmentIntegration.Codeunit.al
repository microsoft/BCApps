// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Integration.Entity;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134499 "ERM Installment Integration"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInstallments: Codeunit "Library - ERM Installments";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    procedure ReadRoleCanReadPostedScheduleAndLiveBalances()
    var
        Invoice: Record "Sales Invoice Header";
        Plan: Record "Sales Installment Plan";
        Line: Record "Sales Installment Plan Line";
        Entry: Record "Cust. Ledger Entry";
        PermissionsMock: Codeunit "Permissions Mock";
        RemainingAmount: Decimal;
    begin
        // [SCENARIO] A read-only user can inspect the complete posted schedule and current balances.
        // [GIVEN] A posted installment invoice with a partially paid final installment.
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 10);
        // [WHEN] The caller is restricted to the standard read role.
        PermissionsMock.Start();
        LibraryLowerPermissions.SetRead();

        // [THEN] All three obligations remain readable and their balances total 115.
        Plan.Get(Invoice."Installment Plan ID");
        Assert.AreEqual(Invoice.SystemId, Plan."Posted Invoice SystemId", 'A reader must resolve the owning posted invoice.');
        Line.SetRange("Plan ID", Plan.ID);
        Assert.AreEqual(3, Line.Count(), 'A reader must see every original installment.');
        Line.FindSet();
        repeat
            Entry.Get(Line."Cust. Ledger Entry No.");
            Entry.CalcFields("Remaining Amount");
            RemainingAmount += Entry."Remaining Amount";
        until Line.Next() = 0;
        Assert.AreEqual(115, RemainingAmount, 'Read-only access must include current entry balances.');
    end;

    [Test]
    procedure ReadRoleCannotModifyDraftSchedule()
    var
        Header: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Plan: Record "Sales Installment Plan";
        PermissionsMock: Codeunit "Permissions Mock";
    begin
        // [SCENARIO] Read permission does not allow changes to an invoice-owned draft schedule.
        // [GIVEN] A draft installment plan and a caller restricted to the read role.
        LibraryInstallments.CreateInvoice(Header, SalesLine, '');
        Plan.Get(Header."Installment Plan ID");
        PermissionsMock.Start();
        LibraryLowerPermissions.SetRead();
        Plan."Document Date" += 1;

        // [WHEN] The caller tries to change the plan's document date.
        asserterror Plan.Modify(false);

        // [THEN] Table permissions reject the change.
        Assert.ExpectedError('Sorry, the current permissions prevented the action. (TableData');
    end;

    [Test]
    procedure SalesPreviewRejectsMissingSourceReadPermission()
    var
        Header: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Plan: Record "Sales Installment Plan";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        SalesInstallmentMgt: Codeunit "Sales Installment Mgt.";
        PermissionsMock: Codeunit "Permissions Mock";
    begin
        // [SCENARIO] A caller without source read permission cannot obtain a temporary sales schedule.
        // [GIVEN] A saved installment invoice and a caller with execute permissions only.
        LibraryInstallments.CreateInvoice(Header, SalesLine, '');
        PermissionsMock.Start();
        PermissionsMock.Set('All Objects');
        Assert.IsFalse(Plan.ReadPermission(), 'The caller must not have read permission on the source plan.');

        // [WHEN] The caller requests a temporary preview.
        asserterror SalesInstallmentMgt.CalculatePreview(Header, TempPlanLine);

        // [THEN] An explicit source-table permission error is raised before any schedule data is returned.
        Assert.ExpectedError('You do not have permission to read the');
        Assert.ExpectedError(Plan.TableCaption());
        Assert.IsTrue(TempPlanLine.IsEmpty(), 'A denied preview must not populate the temporary schedule.');
    end;

    [Test]
    procedure PurchasePreviewRejectsMissingSourceReadPermission()
    var
        Header: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Plan: Record "Purchase Installment Plan";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        PurchaseInstallmentMgt: Codeunit "Purchase Installment Mgt.";
        PermissionsMock: Codeunit "Permissions Mock";
    begin
        // [SCENARIO] A caller without source read permission cannot obtain a temporary purchase schedule.
        // [GIVEN] A saved installment invoice and a caller with execute permissions only.
        LibraryInstallments.CreatePurchaseInvoice(Header, PurchaseLine, '');
        PermissionsMock.Start();
        PermissionsMock.Set('All Objects');
        Assert.IsFalse(Plan.ReadPermission(), 'The caller must not have read permission on the source plan.');

        // [WHEN] The caller requests a temporary preview.
        asserterror PurchaseInstallmentMgt.CalculatePreview(Header, TempPlanLine);

        // [THEN] An explicit source-table permission error is raised before any schedule data is returned.
        Assert.ExpectedError('You do not have permission to read the');
        Assert.ExpectedError(Plan.TableCaption());
        Assert.IsTrue(TempPlanLine.IsEmpty(), 'A denied preview must not populate the temporary schedule.');
    end;

    [Test]
    procedure JournalPostingRoleUpdatesNonAnchorInvoiceAPIStatus()
    var
        Invoice: Record "Sales Invoice Header";
        Entry: Record "Cust. Ledger Entry";
        JournalLine: Record "Gen. Journal Line";
        Template: Record "Gen. Journal Template";
        Batch: Record "Gen. Journal Batch";
        Aggregate: Record "Sales Invoice Entity Aggregate";
        PermissionsMock: Codeunit "Permissions Mock";
        APIMockEvents: Codeunit "API Mock Events";
        ApplicationID: Code[50];
    begin
        // [SCENARIO] A standard journal posting role can settle the last non-anchor installment and refresh invoice API status.
        // [GIVEN] Only the middle installment remains open and is selected for a customer receipt.
        BindSubscription(APIMockEvents);
        APIMockEvents.SetIsAPIEnabled(true);
        LibraryInstallments.CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 41.67);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 41.66);
        LibraryInstallments.GetInstallment(Entry, Invoice."Installment Plan ID", 2);
        ApplicationID := LibraryUtility.GenerateGUID();
        Entry."Applies-to ID" := ApplicationID;
        Entry."Amount to Apply" := 41.67;
        Entry.Modify(true);
        LibraryERM.FindGenJournalTemplate(Template);
        LibraryERM.CreateGenJournalBatch(Batch, Template.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            JournalLine, Template.Name, Batch.Name, JournalLine."Document Type"::Payment,
            JournalLine."Account Type"::Customer, Entry."Customer No.",
            JournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -41.67);
        JournalLine.Validate("Posting Date", WorkDate());
        JournalLine.Validate("Applies-to ID", ApplicationID);
        JournalLine.Modify(true);
        PermissionsMock.Start();
        LibraryLowerPermissions.SetJournalsPost();

        // [WHEN] The selected receipt is posted under the journal posting role.
        LibraryERM.PostGeneralJnlLine(JournalLine);

        // [THEN] The logical invoice closes and its API status becomes Paid without elevated plan writes.
        Invoice.CalcFields("Remaining Amount", Closed);
        Assert.AreEqual(0, Invoice."Remaining Amount", 'The standard journal role must settle the remaining obligation.');
        Assert.IsTrue(Invoice.Closed, 'The grouped invoice must close under the standard journal posting role.');
        Aggregate.Get(Invoice."No.", true);
        Assert.AreEqual(Aggregate.Status::Paid, Aggregate.Status, 'Non-anchor posting must update API status without elevated plan writes.');
        UnbindSubscription(APIMockEvents);
    end;

    [Test]
    procedure BatchOfTwelveInstallmentInvoicesKeepsGroupsAndOriginalAllocations()
    var
        Invoices: array[10] of Record "Sales Invoice Header";
        Header: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Line: Record "Sales Installment Plan Line";
        TempOriginalLine: Record "Sales Installment Plan Line" temporary;
        Entry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        Aggregate: Record "Sales Invoice Entity Aggregate";
        APIMockEvents: Codeunit "API Mock Events";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceIndex: Integer;
        EntryCount: Integer;
        OriginalAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO] Payments across multiple twelve-installment invoices preserve invoice grouping and original allocations.
        // [GIVEN] Ten invoices for one customer each contain twelve separately identified obligations.
        BindSubscription(APIMockEvents);
        APIMockEvents.SetIsAPIEnabled(true);
        LibraryInstallments.CreateInvoice(Header, SalesLine, '');
        CustomerNo := Header."Bill-to Customer No.";
        GLAccountNo := SalesLine."No.";
        for InvoiceIndex := 1 to ArrayLen(Invoices) do begin
            if InvoiceIndex > 1 then begin
                LibrarySales.CreateSalesHeader(Header, Header."Document Type"::Invoice, CustomerNo);
                Header.Validate("Document Date", WorkDate());
                Header.Validate("Posting Date", WorkDate());
                Header.Validate("Prices Including VAT", false);
                Header.Modify(true);
                LibrarySales.CreateSalesLine(SalesLine, Header, SalesLine.Type::"G/L Account", GLAccountNo, 1);
                SalesLine.Validate("Unit Price", 100);
                SalesLine.Modify(true);
            end;
            Header.Validate("External Document No.", LibraryUtility.GenerateGUID());
            Header.Modify(true);
            SetTwelveInstallments(Header."Installment Plan ID");
            Invoices[InvoiceIndex].Get(LibrarySales.PostSalesDocument(Header, true, true));
            Line.SetRange("Plan ID", Invoices[InvoiceIndex]."Installment Plan ID");
            Line.FindSet();
            repeat
                TempOriginalLine := Line;
                TempOriginalLine.Insert();
            until Line.Next() = 0;
        end;

        // [WHEN] Each invoice's final installment is settled and its first installment is partly paid.
        for InvoiceIndex := 1 to ArrayLen(Invoices) do begin
            LibraryInstallments.PayInstallment(Invoices[InvoiceIndex]."Installment Plan ID", 12, 10.38);
            LibraryInstallments.PayInstallment(Invoices[InvoiceIndex]."Installment Plan ID", 1, 5);
        end;

        // [THEN] Each invoice stays open with its own residual balance and all original obligations remain unchanged.
        for InvoiceIndex := 1 to ArrayLen(Invoices) do begin
            Invoices[InvoiceIndex].CalcFields("Remaining Amount", Closed);
            Assert.AreEqual(109.62, Invoices[InvoiceIndex]."Remaining Amount", 'Each invoice must retain only its own residual balance.');
            Assert.IsFalse(Invoices[InvoiceIndex].Closed, 'Closing the anchor must not close the other eleven obligations.');
            Aggregate.Get(Invoices[InvoiceIndex]."No.", true);
            Assert.AreEqual(Aggregate.Status::Open, Aggregate.Status, 'Every partly settled invoice must remain open in the API.');
            Entry.SetRange("Installment Plan ID", Invoices[InvoiceIndex]."Installment Plan ID");
            Assert.AreEqual(12, Entry.Count(), 'Settlement must retain twelve entries per schedule.');
            Entry.SetRange("Invoice Entry No.", Invoices[InvoiceIndex]."Cust. Ledger Entry No.");
            Assert.AreEqual(12, Entry.Count(), 'Every obligation must retain its own invoice group.');
            Entry.CalcSums("Sales (LCY)");
            Assert.AreEqual(100, Entry."Sales (LCY)", 'Splitting must not duplicate invoice sales statistics.');
            Entry.SetRange("Invoice Entry No.");
        end;
        TempOriginalLine.FindSet();
        repeat
            Line.Get(TempOriginalLine."Plan ID", TempOriginalLine."Line No.");
            Assert.AreEqual(TempOriginalLine."Cust. Ledger Entry No.", Line."Cust. Ledger Entry No.", 'Batch settlement must preserve ledger identities.');
            Assert.AreEqual(TempOriginalLine.Amount, Line.Amount, 'Batch settlement must preserve original allocations.');
            Assert.AreEqual(TempOriginalLine."Amount (LCY)", Line."Amount (LCY)", 'Batch settlement must preserve original LCY allocations.');
            Assert.AreEqual(TempOriginalLine."Due Date", Line."Due Date", 'Batch settlement must preserve original due dates.');
            Entry.Get(Line."Cust. Ledger Entry No.");
            Entry.CalcFields(Amount, "Remaining Amount");
            OriginalAmount += Entry.Amount;
            RemainingAmount += Entry."Remaining Amount";
            EntryCount += 1;
        until TempOriginalLine.Next() = 0;
        Assert.AreEqual(120, EntryCount, 'The batch must retain every original obligation.');
        Assert.AreEqual(1250, OriginalAmount, 'Original ledger allocations must reconcile to all ten invoices.');
        Assert.AreEqual(1096.20, RemainingAmount, 'Residual obligations must reconcile after all twenty receipts.');
        Customer.Get(CustomerNo);
        Customer.CalcFields("Balance (LCY)");
        Assert.AreEqual(RemainingAmount, Customer."Balance (LCY)", 'Customer balance must reconcile to all residual obligations.');
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Source No.", CustomerNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(RemainingAmount, GLEntry.Amount, 'The receivables control balance must reconcile to the batch.');
        UnbindSubscription(APIMockEvents);
    end;

    local procedure SetTwelveInstallments(PlanID: Guid)
    var
        Line: Record "Sales Installment Plan Line";
        Sequence: Integer;
    begin
        Line.SetRange("Plan ID", PlanID);
        Line.DeleteAll(true);
        for Sequence := 1 to 12 do begin
            Line.Init();
            Line."Plan ID" := PlanID;
            Line."Line No." := Sequence * 10000;
            if Sequence = 12 then
                Line."Allocation Type" := Line."Allocation Type"::"Remaining Amount"
            else
                Line."Payment %" := 8.33333;
            Evaluate(Line."Due Date Calculation", StrSubstNo('<%1D>', Sequence * 30));
            Line.Insert(true);
        end;
    end;
}
