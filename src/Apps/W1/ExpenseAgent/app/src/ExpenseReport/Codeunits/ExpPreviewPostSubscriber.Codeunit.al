// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;
using Microsoft.Utilities;

codeunit 6995 "Exp. Preview Post. Subscriber"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', true, true)]
    local procedure OnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry" temporary)
    begin
        ExpensePreviewPostInstance.InsertDocumentEntry(DocumentEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', true, true)]
    local procedure OnAfterShowEntries(TableNo: Integer)
    begin
        case TableNo of
            Database::"Expense Ledger Entry":
                ExpensePreviewPostInstance.ShowEntries();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', true, true)]
    local procedure OnAfterFindPostedDocuments(sender: Page Navigate; var DocNoFilter: Text; var DocumentEntry: Record "Document Entry" temporary; var PostingDateFilter: Text)
    begin
        FindPostedExpenseReport(DocumentEntry, DocNoFilter, PostingDateFilter);
        FindExpenseLedgEntries(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', true, true)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; sender: Page Navigate)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        PostedExpenseReport: Record "Posted Expense Report Header";
        PageManagement: Codeunit "Page Management";
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Expense Ledger Entry":
                if ExpenseLedgerEntry.ReadPermission() then begin
                    ExpenseLedgerEntry.Reset();
                    ExpenseLedgerEntry.SetFilter("Document No.", DocNoFilter);
                    ExpenseLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(Page::"Expense Ledger Entries", ExpenseLedgerEntry);
                end;
            Database::"Posted Expense Report Header":
                if PostedExpenseReport.ReadPermission() then begin
                    PostedExpenseReport.SetFilter("No.", DocNoFilter);
                    PostedExpenseReport.SetFilter("Posting Date", PostingDateFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        PageManagement.PageRun(PostedExpenseReport)
                    else
                        PageManagement.PageRunList(PostedExpenseReport);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", OnBeforeGetConditionalCardPageID, '', true, true)]
    local procedure OnBeforeGetConditionalCardPageID(RecRef: RecordRef; var CardPageID: Integer; var IsHandled: Boolean)
    begin
        case RecRef.Number of
            Database::"Posted Expense Report Header":
                begin
                    CardPageID := Page::"Posted Expense Report";
                    IsHandled := true;
                end;
        end;
    end;

    local procedure FindExpenseLedgEntries(var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
    begin
        if ExpenseLedgerEntry.ReadPermission() then begin
            ExpenseLedgerEntry.Reset();
            ExpenseLedgerEntry.SetFilter("Document No.", DocNoFilter);
            ExpenseLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Expense Ledger Entry", ExpenseLedgerEntry.TableCaption(), ExpenseLedgerEntry.Count);
        end;
    end;

    local procedure FindPostedExpenseReport(var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text)
    var
        PostedExpenseReport: Record "Posted Expense Report Header";
    begin
        if PostedExpenseReport.ReadPermission() then begin
            PostedExpenseReport.Reset();
            PostedExpenseReport.SetFilter("No.", DocNoFilter);
            PostedExpenseReport.SetFilter("Posting Date", PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Posted Expense Report Header", PostedExpenseReportLbl, PostedExpenseReport.Count);
        end;
    end;

    var
        ExpensePreviewPostInstance: Codeunit "Expense Preview Post Instance";
        PostedExpenseReportLbl: Label 'Posted Expense Report';
}