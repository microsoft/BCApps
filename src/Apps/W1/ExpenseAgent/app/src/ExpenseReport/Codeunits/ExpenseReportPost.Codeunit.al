// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using System.Utilities;

codeunit 6987 "Expense Report-Post"
{
    Access = Internal;
    TableNo = "Expense Report Header";
    Permissions = TableData "Expense Report Header" = rimd,
                  TableData "Expense Report Line" = rimd,
                  TableData "Sales Header" = rimd,
                  TableData "Sales Line" = rimd,
                  TableData "Gen. Journal Line" = rimd,
                  TableData "Expense Ledger Entry" = rimd,
                  TableData "Expense Report Line Particip." = rimd,
                  TableData "Expense Report Line Item" = rimd,
                  TableData "Expense Report Line Per Diem" = rimd,
                  TableData "Posted Expense Report Header" = rimd,
                  TableData "Posted Expense Report Line" = rimd,
                  TableData "Posted Exp. Rep. Line Item" = rimd,
                  TableData "Posted Exp. Rep. Line Per Diem" = rimd,
                  TableData "Posted Exp. Rep. Line Particip" = rimd,
                  TableData "Posted Exp. Rep. Line VAT Spec" = rimd,
                  TableData "Expense Category" = r,
                  TableData "Expense Posting Group" = r,
                  TableData "Expense User" = r;

    trigger OnRun()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader.Copy(Rec);
        ExpenseReportHeader.SetAutoCalcFields();
        RunWithCheck(ExpenseReportHeader);
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        GlobalExpenseLedgerEntry: Record "Expense Ledger Entry";
        VATSetup: Record "VAT Setup";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PreviewMode: Boolean;
        AmountToEmployee: Decimal;
        AmountToEmployeeLCY: Decimal;
        CanPostExpenseReportQst: Label 'Do you want to post Expense Report %1?', Comment = '%1 = Expense Report No.';
        ExpenseReportWithStatusErr: Label 'Expense Report %1 cannot be posted because its status is %2.', Comment = '%1 = Document No., %2 = Status';
        NothingToPostErr: Label 'There is nothing to post.';
        DocumentCanOnlyBePostedWhenApprovalProcessIsCompleteErr: Label 'This document can only be posted when the approval process is complete.';
        ReimbursementNotificationCannotBeSentErr: Label 'Reimbursement notification cannot be sent as the reimbursable amount is 0.';
        AgentNotEnabledErr: Label 'Please make sure the Expense Agent is active.';
        CommunicationDisabledErr: Label 'Sending emails to users is turned off. Turn on Communication for the Expense Agent before sending reimbursement notifications.';
        NoNoreplyAccountErr: Label 'No account is set for sending emails. Set the send mail account for the Expense Agent before sending reimbursement notifications.';
        NotApprovedForVATReclaimErr: Label 'VAT Reclaim Status is not set for Line with Expense Category %1 and Expense Subcategory %2.', Comment = '%1 = Expense Category, %2 = Expense Subcategory';

    internal procedure RunWithCheck(var ExpenseReportHeader: Record "Expense Report Header")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ReleaseExpenseReport: Codeunit "Release Exp. Report Document";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField(Expense);
        ExpenseAgentSetup.GetRecordOnce();

        if (ExpenseAgentSetup."Enable Approval Workflow") or ExpenseAgentSetup."Enable Agent" then begin
            if not PreviewMode then
                if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::Approved then
                    Error(DocumentCanOnlyBePostedWhenApprovalProcessIsCompleteErr);
        end else
            if not (ExpenseReportHeader.Status in [ExpenseReportHeader.Status::Approved, ExpenseReportHeader.Status::Released]) then
                ReleaseExpenseReport.Run(ExpenseReportHeader);

        ExpenseReportHeader.Get(ExpenseReportHeader."No."); // Refresh after release

        CheckAndCreatePostedDocument(ExpenseReportHeader);

        if not PreviewMode then begin
            if TrySendReimbursementNotification(PostedExpenseReportHeader) then;
            ExpenseReportHeader.Delete(true);
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    internal procedure PostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportHeaderCopy: Record "Expense Report Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CanPostExpenseReportQst, ExpenseReportHeader."No."), true) then
            exit;

        ExpenseReportHeaderCopy.Copy(ExpenseReportHeader);
        ExpenseReportHeaderCopy.SetAutoCalcFields();

        RunWithCheck(ExpenseReportHeaderCopy);
        ExpenseReportHeader := ExpenseReportHeaderCopy;
    end;

    local procedure CheckAndCreatePostedDocument(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        AmountToEmployee := 0;
        ValidateExpenseReportForPosting(ExpenseReportHeader);
        CreatePostedExpenseReport(ExpenseReportHeader);
        UpdateLastPostingNos(ExpenseReportHeader);
        ProcessExpenseReportLines(ExpenseReportHeader);
        InsertPstdExpReportHeaderVATSpecs(ExpenseReportHeader."No.", PostedExpenseReportHeader."No.");
        if AmountToEmployee <> 0 then
            PostEmployeeEntry(ExpenseReportHeader);
    end;

    local procedure ValidateExpenseReportForPosting(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.TestField("Posted Expense Reports Nos.");

        ExpenseReportHeader.TestField("Expense User No.");
        ExpenseReportHeader.TestField("Employee Posting Group");
        ExpenseReportHeader.TestField("Expense Report Date");

        if not PreviewMode then
            if not (ExpenseReportHeader.Status in [ExpenseReportHeader.Status::Released, ExpenseReportHeader.Status::Approved]) then
                Error(ExpenseReportWithStatusErr, ExpenseReportHeader."No.", ExpenseReportHeader.Status);

        if not PreviewMode then
            ExpenseReportHeader.CheckExpenseReportPostRestrictions();

        ValidateExpenseReportLineForPosting(ExpenseReportHeader);
    end;

    local procedure CreatePostedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        NoSeries: Codeunit "No. Series";
    begin
        ExpenseUser.Get(ExpenseReportHeader."Expense User No.");

        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader.TransferFields(ExpenseReportHeader);
        PostedExpenseReportHeader."No." := NoSeries.GetNextNo(ExpenseAgentSetup."Posted Expense Reports Nos.", WorkDate());
        ExpenseReportHeader."Posting No." := PostedExpenseReportHeader."No.";
        PostedExpenseReportHeader.Insert();

        ExpenseReportCommentLine.CopyComments(
            ExpenseReportCommentLine."Document Type"::"Expense Report".AsInteger(),
            ExpenseReportCommentLine."Document Type"::"Posted Expense Report".AsInteger(),
            ExpenseReportHeader."No.",
            PostedExpenseReportHeader."No.");
    end;

    local procedure ProcessExpenseReportLines(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.TestField("Expense Category");
                ExpenseReportLine.TestField("Reimbursement Type");

                PostedExpenseReportLine.Init();
                PostedExpenseReportLine.TransferFields(ExpenseReportLine);
                PostedExpenseReportLine."Document No." := PostedExpenseReportHeader."No.";
                PostedExpenseReportLine.Insert();

                if not PreviewMode then
                    CopyDocumentAttachment(ExpenseReportLine, PostedExpenseReportLine);

                InsertPstdExpReportLineParticipants(PostedExpenseReportLine, ExpenseReportLine);
                InsertPstdExpReportLinePerDiem(PostedExpenseReportLine, ExpenseReportLine);
                InsertPstdExpReportLineItemization(PostedExpenseReportLine, ExpenseReportLine);
                InsertPstdExpReportLineVATSpecs(PostedExpenseReportLine, ExpenseReportLine);
                CreateSalesDocument(PostedExpenseReportHeader, PostedExpenseReportLine);

                if PostedExpenseReportLine."Expense No." <> '' then
                    UpdateExpenseFromPostedExpenseReportLine(PostedExpenseReportLine);

                InitExpenseLedgerEntry(GlobalExpenseLedgerEntry);

                if ExpenseReportLine.Amount <> 0 then
                    CreateAndPostJournalEntry(ExpenseReportHeader, ExpenseReportLine, PostedExpenseReportLine);

                InsertExpenseLedgerEntry(GlobalExpenseLedgerEntry);

            until ExpenseReportLine.Next() = 0;

        if not PreviewMode then
            DeleteRelatedExpenseReportLines(ExpenseReportHeader);
    end;

    local procedure ValidateExpenseReportLineForPosting(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                CheckMandatoryFields(ExpenseReportLine);
                ValidateVATSpecLinesForPosting(ExpenseReportLine);
            until ExpenseReportLine.Next() = 0
        else
            Error(NothingToPostErr);
    end;

    local procedure ValidateVATSpecLinesForPosting(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineVATSpec.FindSet() then
            repeat
                if ExpenseReportLineVATSpec."Reclaim Status" = ExpenseReportLineVATSpec."Reclaim Status"::"Pending" then
                    Error(NotApprovedForVATReclaimErr, ExpenseReportLineVATSpec."Expense Category", ExpenseReportLineVATSpec."Expense Subcategory");
            until ExpenseReportLineVATSpec.Next() = 0;
    end;

    local procedure CheckMandatoryFields(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        ExpenseReportLine.TestField("Expense Category");

        ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpenseCategory.TestField(Inactive, false);

        if ExpenseSubCategory.Get(ExpenseReportLine."Expense Category", ExpenseReportLine."Expense Subcategory Code") then
            ExpenseSubCategory.TestField(Inactive, false);
    end;

    local procedure CopyDocumentAttachment(ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line")
    var
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
    begin
        DocumentAttachmentMgt.CopyAttachments(ExpenseReportLine, PostedExpReportLine);
    end;

    local procedure UpdateExpenseFromPostedExpenseReportLine(PostedExpReportLine: Record "Posted Expense Report Line")
    var
        Expense: Record Expense;
    begin
        Expense.Get(PostedExpReportLine."Expense No.");

        Expense.Validate("Posted Expense Report No.", PostedExpReportLine."Document No.");
        Expense.Modify();
    end;

    local procedure CreateSalesDocument(PostedExpReportHeader: Record "Posted Expense Report Header"; PostedExpReportLine: Record "Posted Expense Report Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if not PostedExpReportLine.Billable then
            exit;

        if not FindSalesDocumentToAppend(SalesHeader, PostedExpReportHeader, PostedExpReportLine) then begin
            SalesHeader.Init();
            SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
            SalesHeader.Insert(true);

            SalesHeader.Validate("Sell-to Customer No.", PostedExpReportLine."Billable to Customer");
            SalesHeader.Validate("Currency Code", PostedExpReportLine."Expense Currency Code");
            SalesHeader.Validate("Posting Date", PostedExpReportHeader."Posting Date");
            SalesHeader.Modify(true);
        end;

        InitSalesLine(SalesLine, SalesHeader);
        UpdateSalesLineInformation(SalesLine, PostedExpReportLine);
    end;

    local procedure InitSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", GetNextSalesLineNo(SalesHeader));
    end;

    local procedure UpdateSalesLineInformation(var SalesLine: Record "Sales Line"; PostedExpReportLine: Record "Posted Expense Report Line")
    begin
        SalesLine.Validate("Type", PostedExpReportLine."Account Type"::"G/L Account");
        SalesLine.Validate("No.", PostedExpReportLine."Account No.");
        SalesLine.Validate("Description", PostedExpReportLine.Description);
        SalesLine.Validate("Quantity", 1);
        SalesLine.Validate("Unit Price", PostedExpReportLine.Amount);
        SalesLine.Validate("Currency Code", PostedExpReportLine."Expense Currency Code");
        SalesLine.Validate("Posted Exp. Report No.", PostedExpenseReportHeader."No.");
        SalesLine.Validate("Posted Exp. Report Line No.", PostedExpReportLine."Line No.");
        SalesLine.Insert(true);
    end;

    local procedure FindSalesDocumentToAppend(var SalesHeader: Record "Sales Header"; PostedExpReportHeader: Record "Posted Expense Report Header"; PostedExpReportLine: Record "Posted Expense Report Line"): Boolean
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", PostedExpReportLine."Billable to Customer");
        SalesHeader.SetRange("Currency Code", PostedExpReportLine."Expense Currency Code");
        SalesHeader.SetRange("Posting Date", PostedExpReportHeader."Posting Date");
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);

        exit(SalesHeader.FindFirst());
    end;

    local procedure GetNextSalesLineNo(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);

        exit(10000);
    end;

    local procedure InsertPstdExpReportLineParticipants(PstdExpenseReportLine: Record "Posted Expense Report Line"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineParticipants: Record "Expense Report Line Particip.";
        PostedExpReportLineParticipants: Record "Posted Exp. Rep. Line Particip";
    begin
        ExpenseReportLineParticipants.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticipants.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineParticipants.FindSet() then
            repeat
                PostedExpReportLineParticipants.Init();
                PostedExpReportLineParticipants.TransferFields(ExpenseReportLineParticipants);
                PostedExpReportLineParticipants."Expense Report No." := PstdExpenseReportLine."Document No.";
                PostedExpReportLineParticipants."Expense Report Line No." := PstdExpenseReportLine."Line No.";
                PostedExpReportLineParticipants.Insert();
            until ExpenseReportLineParticipants.Next() = 0;
    end;

    local procedure InsertPstdExpReportLinePerDiem(PstdExpenseReportLine: Record "Posted Expense Report Line"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLinePerDiem.FindSet() then
            repeat
                PostedExpenseReportLinePerDiem.Init();
                PostedExpenseReportLinePerDiem.TransferFields(ExpenseReportLinePerDiem);
                PostedExpenseReportLinePerDiem."Expense Report No." := PstdExpenseReportLine."Document No.";
                PostedExpenseReportLinePerDiem."Expense Report Line No." := PstdExpenseReportLine."Line No.";
                PostedExpenseReportLinePerDiem.Insert();
            until ExpenseReportLinePerDiem.Next() = 0;
    end;

    local procedure InsertPstdExpReportLineItemization(PstdExpenseReportLine: Record "Posted Expense Report Line"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineItem: Record "Expense Report Line Item";
        PostedExpRepLineItem: Record "Posted Exp. Rep. Line Item";
    begin
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineItem.FindSet() then
            repeat
                PostedExpRepLineItem.Init();
                PostedExpRepLineItem.TransferFields(ExpenseReportLineItem);
                PostedExpRepLineItem."Expense Report No." := PstdExpenseReportLine."Document No.";
                PostedExpRepLineItem."Expense Report Line No." := PstdExpenseReportLine."Line No.";
                PostedExpRepLineItem.Insert();
            until ExpenseReportLineItem.Next() = 0;
    end;

    local procedure DeleteRelatedExpenseReportLines(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLineParticipants: Record "Expense Report Line Particip.";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseReportLineParticipants.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineParticipants.DeleteAll();

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLinePerDiem.DeleteAll();

        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportLineItem.DeleteAll();

        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLineVATSpec.DeleteAll();
    end;

    local procedure CreateAndPostJournalEntry(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line")
    var
        RefundableAmount: Decimal;
        RefundableAmountLCY: Decimal;
    begin
        PostRefundableJnlLine(ExpenseReportHeader, ExpenseReportLine, PostedExpReportLine, RefundableAmount, RefundableAmountLCY);

        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid" then
            exit;

        if ExpenseReportLine.Refundable then
            PostCompanyPaidExpenseJournal(ExpenseReportHeader, ExpenseReportLine, PostedExpReportLine, RefundableAmountLCY);

        if ExpenseReportLine."Reimbursable Amount (LCY)" < 0 then
            PostNonRefundableJnlLine(ExpenseReportHeader, ExpenseReportLine, PostedExpReportLine);
    end;

    local procedure PostRefundableJnlLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line"; var RefundableAmount: Decimal; var RefundableAmountLCY: Decimal)
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        if not PostedExpReportLine.Refundable then
            exit;

        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineVATSpec.FindSet() then
            PostRefundableJnlLineFromSpecs(ExpenseReportHeader, ExpenseReportLine, PostedExpReportLine, ExpenseReportLineVATSpec, RefundableAmount, RefundableAmountLCY)
        else
            PostRefundableJnlLineSingle(ExpenseReportHeader, ExpenseReportLine, PostedExpReportLine, RefundableAmount, RefundableAmountLCY)
    end;

    local procedure PostRefundableJnlLineSingle(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line"; var RefundableAmount: Decimal; var RefundableAmountLCY: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(GenJournalLine, ExpenseReportHeader, PostedExpReportLine);
        SetupRefundableAccount(GenJournalLine, ExpenseReportHeader, ExpenseReportLine);
        SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportLine."Dimension Set ID");

        if ExpenseReportLine."Job No." <> '' then begin
            PostedExpReportLine."Job Ledger Entry No." := PostProjectJnlLine(PostedExpReportLine, PostedExpenseReportHeader, GenJournalLine);
            PostedExpReportLine.Modify();
        end;

        GlobalExpenseLedgerEntry.CopyFromGenJnlLine(GenJournalLine);
        GlobalExpenseLedgerEntry."Refundable Amount" := GenJournalLine.Amount;
        GlobalExpenseLedgerEntry."Refundable Amount (LCY)" := GenJournalLine."Amount (LCY)";

        GenJnlPostLine.RunWithCheck(GenJournalLine);

        RefundableAmount := GenJournalLine.Amount + GenJournalLine."VAT Amount";
        RefundableAmountLCY := GenJournalLine."Amount (LCY)" + GenJournalLine."VAT Amount (LCY)";

        if ShouldConsiderPostingRoundingDifference(PostedExpenseReportHeader."Reimbursement Currency Code", ExpenseReportLine."Expense Currency Code") then
            if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid" then
                if Abs(RefundableAmountLCY) <> Abs(ExpenseReportLine."Reimbursable Amount (LCY)") then
                    PostRoundingDifferenceOnCurrency(GenJournalLine, ExpenseReportLine, ExpenseReportLine."Reimbursable Amount (LCY)" - RefundableAmountLCY);
    end;

    local procedure PostRefundableJnlLineFromSpecs(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line"; var ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec."; var RefundableAmount: Decimal; var RefundableAmountLCY: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobLedgEntryPosted: Boolean;
        GlobalEntryCopied: Boolean;
    begin
        // Each spec row produces its own Gen. Journal Line and VAT Entry.
        // Amounts are taken directly from the spec — no proportional splitting.
        repeat
            Clear(GenJournalLine);
            CreateGenJournalLineFromSpec(GenJournalLine, ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineVATSpec, PostedExpReportLine);
            SetupRefundableAccountForSpec(GenJournalLine, ExpenseReportLine, ExpenseReportLineVATSpec);
            SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportLine."Dimension Set ID");

            if (not JobLedgEntryPosted) and (ExpenseReportLine."Job No." <> '') then begin
                PostedExpReportLine."Job Ledger Entry No." := PostProjectJnlLine(PostedExpReportLine, PostedExpenseReportHeader, GenJournalLine);
                PostedExpReportLine.Modify();
                JobLedgEntryPosted := true;
            end;

            if not GlobalEntryCopied then begin
                GlobalExpenseLedgerEntry.CopyFromGenJnlLine(GenJournalLine);
                GlobalExpenseLedgerEntry."Refundable Amount" := ExpenseReportLine."Refundable Amount";
                GlobalExpenseLedgerEntry."Refundable Amount (LCY)" := ExpenseReportLine."Refundable Amount (LCY)";
                GlobalEntryCopied := true;
            end;

            GenJnlPostLine.RunWithCheck(GenJournalLine);

            // Accumulate gross (base + VAT) from the spec row for rounding/balance checks.
            RefundableAmount += ExpenseReportLineVATSpec."VAT Base Amount" + ExpenseReportLineVATSpec."VAT Amount";
            RefundableAmountLCY += ExpenseReportLineVATSpec."VAT Base Amount (LCY)" + ExpenseReportLineVATSpec."VAT Amount (LCY)";
        until ExpenseReportLineVATSpec.Next() = 0;

        // Employee paid accumulator: the employee paid the gross reimbursable amount for the whole line.
        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid" then begin
            AmountToEmployee += ExpenseReportLine."Reimbursable Amount";
            AmountToEmployeeLCY += ExpenseReportLine."Reimbursable Amount (LCY)";
        end;

        if ShouldConsiderPostingRoundingDifference(PostedExpenseReportHeader."Reimbursement Currency Code", ExpenseReportLine."Expense Currency Code") then
            if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid" then
                if Abs(RefundableAmountLCY) <> Abs(ExpenseReportLine."Reimbursable Amount (LCY)") then
                    PostRoundingDifferenceOnCurrency(GenJournalLine, ExpenseReportLine, ExpenseReportLine."Reimbursable Amount (LCY)" - RefundableAmountLCY);
    end;

    local procedure PostCompanyPaidExpenseJournal(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line"; RefundableAmountLCY: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(GenJournalLine, ExpenseReportHeader, PostedExpReportLine);
        SetupCompanyPaidAccount(GenJournalLine, ExpenseReportHeader, ExpenseReportLine);
        SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportLine."Dimension Set ID");

        GenJnlPostLine.RunWithCheck(GenJournalLine);

        if ShouldConsiderPostingRoundingDifference(PostedExpenseReportHeader."Reimbursement Currency Code", ExpenseReportLine."Expense Currency Code") then
            if Abs(RefundableAmountLCY) <> Abs(GenJournalLine."Amount (LCY)") then
                PostRoundingDifferenceOnCurrency(GenJournalLine, ExpenseReportLine, Abs(GenJournalLine."Amount (LCY)") - RefundableAmountLCY);
    end;

    local procedure PostNonRefundableJnlLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpReportLine: Record "Posted Expense Report Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        RefundableLCY: Decimal;
    begin
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineVATSpec.FindSet() then begin
            PostNonRefundableJnlLineFromSpecs(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineVATSpec);
            exit;
        end;

        CreateGenJournalLine(GenJournalLine, ExpenseReportHeader, PostedExpReportLine);
        SetupNonRefundableAccount(GenJournalLine, ExpenseReportHeader, ExpenseReportLine);
        SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportLine."Dimension Set ID");

        if not ExpenseReportLine.Refundable then
            GlobalExpenseLedgerEntry.CopyFromGenJnlLine(GenJournalLine);

        GenJnlPostLine.RunWithCheck(GenJournalLine);

        RefundableLCY := GenJournalLine."Amount (LCY)" + GenJournalLine."VAT Amount (LCY)";
        if ShouldConsiderPostingRoundingDifference(PostedExpenseReportHeader."Reimbursement Currency Code", ExpenseReportLine."Expense Currency Code") then
            if Abs(ExpenseReportLine."Reimbursable Amount (LCY)") <> Abs(RefundableLCY) then
                PostRoundingDifferenceOnCurrency(GenJournalLine, ExpenseReportLine, ExpenseReportLine."Reimbursable Amount (LCY)" - RefundableLCY);
    end;

    local procedure PostNonRefundableJnlLineFromSpecs(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; var ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GlobalEntryCopied: Boolean;
    begin
        // Each spec row produces its own Gen. Journal Line and VAT Entry.
        // Amounts are taken directly from the spec — no proportional splitting.
        repeat
            Clear(GenJournalLine);
            CreateGenJournalLineFromSpec(GenJournalLine, ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineVATSpec, PostedExpenseReportLine);
            SetupNonRefundableAccountForSpec(GenJournalLine, ExpenseReportLine, ExpenseReportLineVATSpec);
            SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportLine."Dimension Set ID");

            if not GlobalEntryCopied then begin
                if not ExpenseReportLine.Refundable then
                    GlobalExpenseLedgerEntry.CopyFromGenJnlLine(GenJournalLine);
                GlobalEntryCopied := true;
            end;

            GenJnlPostLine.RunWithCheck(GenJournalLine);
        until ExpenseReportLineVATSpec.Next() = 0;

        // Accumulate employee reimbursement amount once per line.
        AmountToEmployee += ExpenseReportLine."Reimbursable Amount";
        AmountToEmployeeLCY += ExpenseReportLine."Reimbursable Amount (LCY)";
    end;

    local procedure SetupNonRefundableAccountForSpec(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportLine: Record "Expense Report Line"; ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        if ExpenseReportLineVATSpec."Expense Category" <> '' then
            ExpenseCategory.Get(ExpenseReportLineVATSpec."Expense Category")
        else
            ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.TestField("Non-Refundable Debit Account");

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine."Account No." := ExpensePostingGroup."Non-Refundable Debit Account";
    end;

    local procedure ShouldConsiderPostingRoundingDifference(ReimbursementCurrencyCode: Code[10]; ExpenseCurrencyCode: Code[10]): Boolean
    begin
        exit((ReimbursementCurrencyCode = '') and (ExpenseCurrencyCode <> ''));
    end;

    local procedure PostProjectJnlLine(PostedExpReportLine: Record "Posted Expense Report Line"; PostedExpReportHeader: Record "Posted Expense Report Header"; GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        ProjectJournalLine: Record "Job Journal Line";
        JobPostLine: Codeunit "Job Jnl.-Post Line";
        JobLedgEntryNo: Integer;
    begin
        SourceCodeSetup.TestField("Job Journal");
        PostedExpReportLine.TestField("Job Task No.");

        ProjectJournalLine.Init();
        ProjectJournalLine."Source Code" := SourceCodeSetup."Job Journal";
        ProjectJournalLine.Validate("Line Type", ProjectJournalLine."Line Type"::Billable);
        ProjectJournalLine.Validate("Posting Date", PostedExpReportHeader."Posting Date");
        ProjectJournalLine.Validate("Document No.", PostedExpReportHeader."No.");
        ProjectJournalLine.Validate("Job No.", PostedExpReportLine."Job No.");
        ProjectJournalLine.Validate("Job Task No.", PostedExpReportLine."Job Task No.");
        ProjectJournalLine.Validate(Type, ProjectJournalLine.Type::"G/L Account");
        ProjectJournalLine.Validate("No.", GenJournalLine."Account No.");
        ProjectJournalLine.Validate(Quantity, 1);
        ProjectJournalLine.Validate("Unit Cost (LCY)", GenJournalLine."Amount (LCY)");
        ProjectJournalLine.Validate("Unit Price (LCY)", GenJournalLine."Amount (LCY)");
        ProjectJournalLine."Expense Report No." := PostedExpReportHeader."No.";
        ProjectJournalLine."Expense Report Line No." := PostedExpReportLine."Line No.";
        JobLedgEntryNo := JobPostLine.RunWithCheck(ProjectJournalLine);

        exit(JobLedgEntryNo);
    end;

    local procedure PostEmployeeEntry(ExpenseReportHeader: Record "Expense Report Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Employee);
        GenJournalLine.Validate("Posting Date", ExpenseReportHeader."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", PostedExpenseReportHeader."No.");
        GenJournalLine.Validate("Expense User No.", ExpenseReportHeader."Expense User No.");
        GenJournalLine.Validate("Account No.", ExpenseUser."Employee No.");
        GenJournalLine.Validate("Posting Group", ExpenseReportHeader."Employee Posting Group");
        GenJournalLine.Validate("Currency Code", ExpenseReportHeader."Reimbursement Currency Code");
        GenJournalLine.Validate("Source Currency Code", ExpenseReportHeader."Reimbursement Currency Code");
        GenJournalLine."Currency Factor" := ExpenseReportHeader."Reimbursement Currency Factor";
        GenJournalLine.Amount := -AmountToEmployee;
        GenJournalLine."Amount (LCY)" := -AmountToEmployeeLCY;

        if ExpenseReportHeader.Description <> '' then begin
            GenJournalLine.Validate(Description, ExpenseReportHeader.Description);
            GenJournalLine.Validate("Keep Description", true);
        end;

        SetupSourceCodeAndDimensions(GenJournalLine, ExpenseReportHeader."Dimension Set ID");
        GenJournalLine."System-Created Entry" := true;
        GenJnlPostLine.RunWithCheck(GenJournalLine);
    end;

    local procedure UpdateLastPostingNos(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        ExpenseReportHeader."Last Posting No." := ExpenseReportHeader."Posting No.";
        ExpenseReportHeader."Posting No." := '';
    end;

    local procedure UpdateVATInformationOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportLine: Record "Expense Report Line")
    var
        Vendor: Record Vendor;
    begin
        ExpenseReportLine.TestField("Vendor No.");
        Vendor.SetLoadFields("Country/Region Code", "VAT Registration No.");
        Vendor.Get(ExpenseReportLine."Vendor No.");
        GenJournalLine."VAT %" := ExpenseReportLine."VAT %";
        GenJournalLine."Bill-to/Pay-to No." := Vendor."No.";
        GenJournalLine."Country/Region Code" := Vendor."Country/Region Code";
        GenJournalLine."VAT Registration No." := Vendor."VAT Registration No.";
        GenJournalLine."VAT Calculation Type" := ExpenseReportLine."VAT Calculation Type";
        GenJournalLine."VAT Posting" := GenJournalLine."VAT Posting"::"Manual VAT Entry";

        GenJournalLine.Validate("VAT Bus. Posting Group", ExpenseReportLine."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", ExpenseReportLine."VAT Prod. Posting Group");

        if (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '') then
            GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
    end;

    local procedure ClearVATInformationOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Bill-to/Pay-to No." := '';
        GenJournalLine."VAT Registration No." := '';
        GenJournalLine."VAT Posting" := GenJournalLine."VAT Posting"::"Automatic VAT Entry";
        GenJournalLine."VAT %" := 0;
        GenJournalLine."VAT Amount" := 0;
        GenJournalLine."VAT Amount (LCY)" := 0;
        GenJournalLine.Validate("VAT Prod. Posting Group", '');
        GenJournalLine.Validate("VAT Bus. Posting Group", '');
        GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::" ";
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; PostedExpReportLine: Record "Posted Expense Report Line")
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", ExpenseReportHeader."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", PostedExpReportLine."Document No.");
        GenJournalLine.Validate("Expense User No.", ExpenseReportHeader."Expense User No.");
        GenJournalLine.Validate("Expense Category", PostedExpReportLine."Expense Category");
        GenJournalLine.Validate("Expense Subcategory Code", PostedExpReportLine."Expense Subcategory Code");
        GenJournalLine.Validate(Description, PostedExpReportLine.Description);
        GenJournalLine.Validate("Keep Description", true);
    end;

    /// <summary>
    /// Initialises a Gen. Journal Line whose amounts, VAT fields, and expense classification come
    /// directly from a single <see cref="Exp. Report Line VAT Spec."/> row. The posting engine
    /// creates the VAT Entry and routes non-deductible VAT via VAT Posting Setup automatically.
    /// </summary>
    local procedure CreateGenJournalLineFromSpec(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec."; PostedExpReportLine: Record "Posted Expense Report Line")
    var
        Vendor: Record Vendor;
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", ExpenseReportHeader."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", PostedExpReportLine."Document No.");
        GenJournalLine.Validate("Expense User No.", ExpenseReportHeader."Expense User No.");
        GenJournalLine.Validate(Description, ExpenseReportLine.UpdatePostingDescription());
        GenJournalLine.Validate("Keep Description", true);

        // Use spec-level expense category/subcategory when present; fall back to parent line.
        if ExpenseReportLineVATSpec."Expense Category" <> '' then begin
            GenJournalLine.Validate("Expense Category", ExpenseReportLineVATSpec."Expense Category");
            GenJournalLine.Validate("Expense Subcategory Code", ExpenseReportLineVATSpec."Expense Subcategory");
        end else begin
            GenJournalLine.Validate("Expense Category", ExpenseReportLine."Expense Category");
            GenJournalLine.Validate("Expense Subcategory Code", ExpenseReportLine."Expense Subcategory Code");
        end;

        // Amounts come directly from the spec row — base (net) + VAT as captured on the receipt.
        GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::Purchase;
        GenJournalLine."Currency Code" := ExpenseReportLine."Expense Currency Code";
        GenJournalLine."Currency Factor" := ExpenseReportLine."Expense Currency Factor";
        GenJournalLine.Amount := ExpenseReportLineVATSpec."VAT Base Amount";
        GenJournalLine."Amount (LCY)" := ExpenseReportLineVATSpec."VAT Base Amount (LCY)";

        if ExpenseReportLineVATSpec."Reclaim Status" = ExpenseReportLineVATSpec."Reclaim Status"::"Approved" then begin
            GenJournalLine."VAT Bus. Posting Group" := ExpenseReportLineVATSpec."VAT Bus. Posting Group";
            GenJournalLine."VAT Prod. Posting Group" := ExpenseReportLineVATSpec."VAT Prod. Posting Group";
            GenJournalLine."VAT Posting" := GenJournalLine."VAT Posting"::"Manual VAT Entry";
            GenJournalLine."VAT Calculation Type" := ExpenseReportLine."VAT Calculation Type";
            GenJournalLine."VAT Base Amount" := ExpenseReportLineVATSpec."VAT Base Amount";
            GenJournalLine."VAT Base Amount (LCY)" := ExpenseReportLineVATSpec."VAT Base Amount (LCY)";
            GenJournalLine."VAT Amount" := ExpenseReportLineVATSpec."VAT Amount";
            GenJournalLine."VAT Amount (LCY)" := ExpenseReportLineVATSpec."VAT Amount (LCY)";
            GenJournalLine."VAT %" := ExpenseReportLineVATSpec."VAT %";

            // VAT Reclaim % is used to route the non-deductible portion of VAT to the correct accounts via VAT Posting Setup.
            if (ExpenseReportLineVATSpec."Reclaim %" <> 100) and (ExpenseReportLineVATSpec."VAT Amount" <> 0) then begin
                VATSetup.Get();
                VATSetup.TestField("Non-Deductible VAT Is Enabled");
                GenJournalLine.Validate("Non-Deductible VAT %", 100 - ExpenseReportLineVATSpec."Reclaim %");
            end;
        end else begin
            // VAT is not reclaimable: include VAT in the expense amount (gross) and do not create a VAT entry.
            GenJournalLine.Amount := ExpenseReportLineVATSpec."VAT Base Amount" + ExpenseReportLineVATSpec."VAT Amount";
            GenJournalLine."Amount (LCY)" := ExpenseReportLineVATSpec."VAT Base Amount (LCY)" + ExpenseReportLineVATSpec."VAT Amount (LCY)";

            GenJournalLine."VAT Posting" := GenJournalLine."VAT Posting"::"Automatic VAT Entry";
            GenJournalLine."VAT %" := 0;
            GenJournalLine."VAT Amount" := 0;
            GenJournalLine."VAT Amount (LCY)" := 0;
            GenJournalLine."VAT Base Amount" := 0;
            GenJournalLine."VAT Base Amount (LCY)" := 0;
            GenJournalLine."VAT Bus. Posting Group" := '';
            GenJournalLine."VAT Prod. Posting Group" := '';
            GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::" ";
        end;

        // Vendor details for VAT registration tracing.
        if ExpenseReportLine."Vendor No." <> '' then begin
            Vendor.SetLoadFields("Country/Region Code", "VAT Registration No.");
            Vendor.Get(ExpenseReportLine."Vendor No.");
            GenJournalLine."Bill-to/Pay-to No." := Vendor."No.";
            GenJournalLine."Country/Region Code" := Vendor."Country/Region Code";
            GenJournalLine."VAT Registration No." := Vendor."VAT Registration No.";
        end;

        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure SetupRefundableAccount(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.TestField("Refundable Debit Account");

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine."Account No." := ExpensePostingGroup."Refundable Debit Account";

        GenJournalLine.Validate("Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");
        GenJournalLine.Validate("Source Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");
        if ExpenseReportLine."VAT Liable" then
            UpdateVATInformationOnGenJnlLine(GenJournalLine, ExpenseReportLine);

        GenJournalLine.Amount := ExpenseReportLine."Refundable Amount";
        GenJournalLine."Amount (LCY)" := ExpenseReportLine."Refundable Amount (LCY)";

        UpdateVATAmount(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)",
            GenJournalLine."VAT Amount", GenJournalLine."VAT Amount (LCY)",
            GenJournalLine."VAT Base Amount", GenJournalLine."VAT Base Amount (LCY)",
            ExpenseReportHeader, ExpenseReportLine);

        GenJournalLine."Currency Factor" := PostedExpenseReportHeader."Reimbursement Currency Factor";
        GenJournalLine."Source Currency Amount" := GenJournalLine.Amount;

        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid" then begin
            AmountToEmployee += ExpenseReportLine."Reimbursable Amount";
            AmountToEmployeeLCY += ExpenseReportLine."Reimbursable Amount (LCY)";
        end;

        GenJournalLine."Spend Request No." := ExpenseReportLine."Spend Request No.";
        GenJournalLine."Spend Request Close" := ExpenseReportLine."Spend Request Close";
        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure SetupCompanyPaidAccount(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line")
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Get(ExpenseReportHeader."Employee Posting Group");

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");

        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Company Paid" then
            GenJournalLine."Account No." := EmployeePostingGroup.GetExpensePayableBankPaidAccount();

        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Credit Card" then
            GenJournalLine."Account No." := EmployeePostingGroup.GetExpensePayableCardPaidAccount();

        GenJournalLine.Validate("Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");
        GenJournalLine.Validate("Source Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");

        GetCompanyPaidAmount(ExpenseReportHeader, ExpenseReportLine, GenJournalLine.Amount, GenJournalLine."Amount (LCY)");

        GenJournalLine."Currency Factor" := PostedExpenseReportHeader."Reimbursement Currency Factor";
        GenJournalLine."Source Currency Amount" := GenJournalLine.Amount;
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then begin
            GenJournalLine."VAT Base Amount" := GenJournalLine.Amount;
            GenJournalLine."VAT Base Amount (LCY)" := GenJournalLine."Amount (LCY)";
        end;

        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure SetupNonRefundableAccount(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.TestField("Non-Refundable Debit Account");

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine."Account No." := ExpensePostingGroup."Non-Refundable Debit Account";
        GenJournalLine.Validate("Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");
        GenJournalLine.Validate("Source Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");

        GetNonRefundableAmount(ExpenseReportHeader, ExpenseReportLine, GenJournalLine.Amount, GenJournalLine."Amount (LCY)");

        GenJournalLine."Currency Factor" := PostedExpenseReportHeader."Reimbursement Currency Factor";
        GenJournalLine."Source Currency Amount" := GenJournalLine.Amount;

        AmountToEmployee += ExpenseReportLine."Reimbursable Amount";
        AmountToEmployeeLCY += ExpenseReportLine."Reimbursable Amount (LCY)";

        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure SetupRefundableAccountForSpec(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportLine: Record "Expense Report Line"; ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        if ExpenseReportLineVATSpec."Expense Category" <> '' then
            ExpenseCategory.Get(ExpenseReportLineVATSpec."Expense Category")
        else
            ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.TestField("Refundable Debit Account");

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine."Account No." := ExpensePostingGroup."Refundable Debit Account";

        GenJournalLine."Spend Request No." := ExpenseReportLine."Spend Request No.";
        GenJournalLine."Spend Request Close" := ExpenseReportLine."Spend Request Close";
        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure GetCompanyPaidAmount(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; var Amount: Decimal; var AmountLCY: Decimal)
    var
        ExpenseCurrency: Record Currency;
        ReimbursementCurrency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        ReimbursementCurrency.Initialize(ExpenseReportHeader."Reimbursement Currency Code");
        ExpenseCurrency.Initialize(ExpenseReportLine."Expense Currency Code");

        // The conversion date and currency factor to consider for Company Paid calculation will depend on the setup in Expense Agent Setup. 
        // If the setup is based on posting date, then the conversion date will be the posting date of the expense report. 
        // If the setup is based on expense date, then the conversion date will be the expense date of the line.

        // For Company Paid amount calculation, we need to consider the exchange rate on conversion date based on the setup.
        // Because We need to post rounding difference on Refundable amount if the exchange rate on posting date is different from the exchange rate based on expense date in setup.
        // so we need to consider exchange rate on conversion date to calculate the accurate Company Paid amount in LCY and calculate the rounding difference on refundable amount.
        Amount := -(ExpenseReportLine.Amount - ExpenseReportLine."Non-Refundable Amount");
        AmountLCY :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    ExpenseReportLine.GetReimbursementConversionDate(),
                    ExpenseCurrency.Code,
                    Amount,
                    CurrencyExchangeRate.ExchangeRate(ExpenseReportLine.GetReimbursementConversionDate(), ExpenseCurrency.Code)),
                ExpenseCurrency."Amount Rounding Precision");

        if ExpenseCurrency.Code <> ReimbursementCurrency.Code then
            Amount :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        ExpenseReportLine.GetReimbursementConversionDate(),
                        ReimbursementCurrency.Code,
                        AmountLCY,
                        CurrencyExchangeRate.ExchangeRate(ExpenseReportLine.GetReimbursementConversionDate(), ReimbursementCurrency.Code)),
                    ReimbursementCurrency."Amount Rounding Precision");
    end;

    local procedure GetNonRefundableAmount(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; var Amount: Decimal; var AmountLCY: Decimal)
    var
        ExpenseCurrency: Record Currency;
        ReimbursementCurrency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        ReimbursementCurrency.Initialize(ExpenseReportHeader."Reimbursement Currency Code");
        ExpenseCurrency.Initialize(ExpenseReportLine."Expense Currency Code");

        if ExpenseReportLine.Refundable then
            Amount := -ExpenseReportLine."Non-Refundable Amount"
        else
            Amount := -ExpenseReportLine.Amount;

        // For Non-Refundable amount calculation, we need to consider the exchange rate on posting date, not on the date of expense date.
        // Because We need to post rounding difference on reimbursable amount if the exchange rate on posting date is different from the exchange rate based on expense date in setup.
        // so we need to consider exchange rate on posting date for conversion to calculate the accurate Non-Refundable amount in LCY and calculate the rounding difference.
        AmountLCY :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    ExpenseReportHeader."Posting Date",
                    ExpenseCurrency.Code,
                    Amount,
                    CurrencyExchangeRate.ExchangeRate(ExpenseReportHeader."Posting Date", ExpenseCurrency.Code)),
                ExpenseCurrency."Amount Rounding Precision");

        if ExpenseCurrency.Code <> ReimbursementCurrency.Code then
            Amount :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        ExpenseReportHeader."Posting Date",
                        ReimbursementCurrency.Code,
                        AmountLCY,
                        CurrencyExchangeRate.ExchangeRate(ExpenseReportHeader."Posting Date", ReimbursementCurrency.Code)),
                    ReimbursementCurrency."Amount Rounding Precision");
    end;

    local procedure PostRoundingDifferenceOnCurrency(GenJournalLine: Record "Gen. Journal Line"; ExpenseReportLine: Record "Expense Report Line"; AmountToPost: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        AccNo: Code[20];
    begin
        ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        if AmountToPost > 0 then begin
            ExpensePostingGroup.TestField("Debit Rounding Account");
            AccNo := ExpensePostingGroup."Debit Rounding Account";
        end else begin
            ExpensePostingGroup.TestField("Credit Rounding Account");
            AccNo := ExpensePostingGroup."Credit Rounding Account";
        end;

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := AccNo;
        GenJournalLine.Amount := AmountToPost;
        GenJournalLine."Amount (LCY)" := AmountToPost;
        GenJournalLine."Source Currency Amount" := AmountToPost;
        GenJournalLine."System-Created Entry" := true;
        ClearVATInformationOnGenJnlLine(GenJournalLine);
        GenJnlPostLine.RunWithCheck(GenJournalLine);
    end;

    procedure UpdateVATAmount(
        var Amount: Decimal;
        var AmountLCY: Decimal;
        var VATAmount: Decimal;
        var VATAmountLCY: Decimal;
        var VATBaseAmount: Decimal;
        var VATBaseAmountLCY: Decimal;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line")
    var
        CurrencyToConsider: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ConversionDate: Date;
        CurrFactor: Decimal;
    begin
        VATBaseAmount := Amount;
        VATBaseAmountLCY := AmountLCY;
        VATAmount := 0;
        VATAmountLCY := 0;

        if not ExpenseReportLine."VAT Liable" then
            exit;

        if ExpenseReportHeader."Reimbursement Currency Code" = '' then begin
            if ExpenseReportLine."Expense Currency Code" = '' then
                CurrencyToConsider.InitRoundingPrecision()
            else
                CurrencyToConsider.Get(ExpenseReportLine."Expense Currency Code");
        end else
            CurrencyToConsider.Get(ExpenseReportHeader."Reimbursement Currency Code");

        ConversionDate := ExpenseReportHeader."Posting Date";
        CurrFactor := CurrExchRate.ExchangeRate(ConversionDate, CurrencyToConsider.Code);

        if ExpenseReportLine."VAT Difference" <> 0 then begin
            ExpenseReportLine.CheckVATDifference(CurrencyToConsider);
            VATAmount := ExpenseReportLine."VAT Amount";
            VATAmountLCY := ExpenseReportLine."VAT Amount (LCY)";
            VATBaseAmount := ExpenseReportLine."Amount without VAT";
            VATBaseAmountLCY := ExpenseReportLine."Amount without VAT (LCY)";
            Amount := VATBaseAmount;
            AmountLCY := VATBaseAmountLCY;
            exit;
        end;

        VATBaseAmount := Round((Amount) / (1 + ExpenseReportLine."VAT %" / 100), CurrencyToConsider."Amount Rounding Precision");
        VATAmount := Amount - VATBaseAmount;

        if ExpenseReportHeader."Reimbursement Currency Code" = '' then begin
            VATAmountLCY := VATAmount;
            VATBaseAmountLCY := VATBaseAmount;
        end else begin
            VATBaseAmountLCY :=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        ConversionDate,
                        ExpenseReportLine."Expense Currency Code",
                        VATBaseAmount,
                        CurrFactor),
                        CurrencyToConsider."Amount Rounding Precision");

            VATAmountLCY :=
               Round(
                   CurrExchRate.ExchangeAmtFCYToLCY(
                       ConversionDate,
                       ExpenseReportLine."Expense Currency Code",
                       VATAmount,
                       CurrFactor),
                       CurrencyToConsider."Amount Rounding Precision");
        end;

        Amount := VATBaseAmount;
        AmountLCY := VATBaseAmountLCY;
    end;

    local procedure SetupSourceCodeAndDimensions(var GenJournalLine: Record "Gen. Journal Line"; DimensionSetId: Integer)
    begin
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine.Validate("Source Code", SourceCodeSetup.Expense);
        GenJournalLine.Validate("Dimension Set ID", DimensionSetId);
    end;

    local procedure InitExpenseLedgerEntry(var ExpenseLedgerEntry: Record "Expense Ledger Entry")
    begin
        ExpenseLedgerEntry.LockTable();
        ExpenseLedgerEntry.Init();
        ExpenseLedgerEntry."Entry No." := ExpenseLedgerEntry.GetNextEntryNo();
        ExpenseLedgerEntry.CopyFromPostedExpenseReportLine(PostedExpenseReportLine);
        ExpenseLedgerEntry."Posting Date" := PostedExpenseReportHeader."Posting Date";
        ExpenseLedgerEntry."Document Type" := ExpenseLedgerEntry."Document Type"::Invoice;
        ExpenseLedgerEntry."Employee No." := ExpenseUser."Employee No.";
        ExpenseLedgerEntry."Source Code" := SourceCodeSetup.Expense;
    end;

    local procedure InsertExpenseLedgerEntry(var ExpenseLedgerEntry: Record "Expense Ledger Entry")
    begin
        ExpenseLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        ExpenseLedgerEntry."Employee Posting Group" := PostedExpenseReportHeader."Employee Posting Group";
        ExpenseLedgerEntry.Insert(true);
    end;

    /// <summary>
    /// Sets the Preview Mode for the current instance of the codeunit.
    /// Preview Mode ensures no transactions are committed to the database and no documents are sent.
    /// </summary>
    /// <param name="NewPreviewMode">The new value for the Preview Mode.</param>
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterBindSubscription', '', true, true)]
    local procedure OnAfterBindSubscription()
    begin
        TryBindPostingPreviewHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterUnbindSubscription', '', true, true)]
    local procedure OnAfterUnbindSubscription()
    begin
        TryUnbindPostingPreviewHandler();
    end;

    local procedure TryBindPostingPreviewHandler(): Boolean
    var
        ExpensePreviewPostingHandler: Codeunit "Exp. Preview Posting Handler";
        ExpensePreviewPostInstance: Codeunit "Expense Preview Post Instance";
    begin
        ExpensePreviewPostInstance.Initialize();
        exit(ExpensePreviewPostingHandler.TryBindPostingPreviewHandler());
    end;

    local procedure TryUnbindPostingPreviewHandler(): Boolean
    var
        ExpensePreviewPostingHandler: Codeunit "Exp. Preview Posting Handler";
    begin
        exit(ExpensePreviewPostingHandler.TryUnbindPostingPreviewHandler());
    end;

    [TryFunction]
    local procedure TrySendReimbursementNotification(PostedExpReportHeader: Record "Posted Expense Report Header")
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Enable Agent" then
            exit;
        if not ExpenseAgentSetup.IsOutgoingCommunicationConfigured() then
            exit;

        ExpenseUser.Get(PostedExpReportHeader."Expense User No.");
        if ExpenseUser."E-mail" = '' then
            exit;

        PostedExpReportHeader.CalcFields("Reimbursable Amount");
        if PostedExpReportHeader."Reimbursable Amount" = 0 then
            exit;

        SendReimbursementNotification(PostedExpReportHeader, ExpenseUser);
    end;

    internal procedure CheckAndSendReimbursementNotification(PostedExpReportHeader: Record "Posted Expense Report Header"): Boolean
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Enable Agent" then
            Error(AgentNotEnabledErr);
        if not ExpenseAgentSetup."Enable Communication" then
            Error(CommunicationDisabledErr);
        if IsNullGuid(ExpenseAgentSetup."Noreply Email Account ID") then
            Error(NoNoreplyAccountErr);

        ExpenseUser.Get(PostedExpReportHeader."Expense User No.");
        ExpenseUser.TestField("E-mail");

        PostedExpReportHeader.CalcFields("Reimbursable Amount");
        if PostedExpReportHeader."Reimbursable Amount" = 0 then
            Error(ReimbursementNotificationCannotBeSentErr);

        exit(SendReimbursementNotification(PostedExpReportHeader, ExpenseUser));
    end;

    local procedure SendReimbursementNotification(PostedExpReportHeader: Record "Posted Expense Report Header"; ExpenseUser2: Record "Expense User"): Boolean
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        exit(EAHttpClient.SendReimbursementNotification(ExpenseUser2."E-mail", PostedExpReportHeader.SystemId));
    end;

    /// <summary>
    /// Copies per-line <see cref="Exp. Report Line VAT Spec."/> rows for the given Expense Report Line
    /// into <see cref="Posted Exp. Rep. Line VAT Spec."/>. The reclaim justification blob is
    /// transferred explicitly since TransferFields does not copy blob content.
    /// </summary>
    local procedure InsertPstdExpReportLineVATSpecs(PstdExpenseReportLine: Record "Posted Expense Report Line"; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedERLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        JustificationInStream: InStream;
        Justification: Text;
    begin
        ExpenseReportLineVATSpec.SetAutoCalcFields("Reclaim Justification");
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineVATSpec.FindSet() then
            repeat
                PostedERLineVATSpec.Init();
                PostedERLineVATSpec.TransferFields(ExpenseReportLineVATSpec);
                PostedERLineVATSpec."Expense Report No." := PstdExpenseReportLine."Document No.";
                PostedERLineVATSpec."Expense Report Line No." := PstdExpenseReportLine."Line No.";
                if ExpenseReportLineVATSpec."Reclaim Justification".HasValue() then begin
                    ExpenseReportLineVATSpec."Reclaim Justification".CreateInStream(JustificationInStream, TextEncoding::UTF8);
                    JustificationInStream.ReadText(Justification);
                    PostedERLineVATSpec.SetJustification(Justification);
                end;
                PostedERLineVATSpec.Insert();
            until ExpenseReportLineVATSpec.Next() = 0;
    end;

    /// <summary>
    /// Copies the aggregate <see cref="Exp. Report Line VAT Spec."/> rows (Document Line No. = 0)
    /// for the draft Expense Report into <see cref="Posted Exp. Rep. Line VAT Spec."/> with
    /// Expense Report Line No. = 0, then deletes the source aggregate rows.
    /// Called once after all individual lines have been processed.
    /// </summary>
    local procedure InsertPstdExpReportHeaderVATSpecs(DraftDocumentNo: Code[20]; PostedDocumentNo: Code[20])
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        JustificationInStream: InStream;
        Justification: Text;
    begin
        ExpenseReportLineVATSpec.SetAutoCalcFields("Reclaim Justification");
        ExpenseReportLineVATSpec.SetRange("Document No.", DraftDocumentNo);
        ExpenseReportLineVATSpec.SetRange("Document Line No.", 0);
        if not ExpenseReportLineVATSpec.FindSet() then
            exit;

        repeat
            PostedExpenseReportLineVATSpec.Init();
            PostedExpenseReportLineVATSpec.TransferFields(ExpenseReportLineVATSpec);
            PostedExpenseReportLineVATSpec."Expense Report No." := PostedDocumentNo;
            PostedExpenseReportLineVATSpec."Expense Report Line No." := 0;
            if ExpenseReportLineVATSpec."Reclaim Justification".HasValue() then begin
                ExpenseReportLineVATSpec."Reclaim Justification".CreateInStream(JustificationInStream, TextEncoding::UTF8);
                JustificationInStream.ReadText(Justification);
                PostedExpenseReportLineVATSpec.SetJustification(Justification);
            end;
            PostedExpenseReportLineVATSpec.Insert();
        until ExpenseReportLineVATSpec.Next() = 0;

        // Delete the source aggregate rows now that they are safely in the posted table.
        ExpenseReportLineVATSpec.DeleteAll();
    end;
}
