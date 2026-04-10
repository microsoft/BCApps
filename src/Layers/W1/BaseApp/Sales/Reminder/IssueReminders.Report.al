// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.CRM.Outlook;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Setup;
using System.Utilities;

/// <summary>
/// Posts reminder documents in batch, creating issued reminders and general ledger entries for fees and interest.
/// </summary>
report 190 "Issue Reminders"
{
    Caption = 'Issue Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';

            trigger OnAfterGetRecord()
            var
                InvoiceRoundingAmount: Decimal;
                ShouldConfirmInvoiceRounding: Boolean;
            begin
                InvoiceRoundingAmount := GetInvoiceRoundingAmount();
                OnAfterGetRecordReminderHeaderOnAfterGetInvoiceRoundingAmount("Reminder Header", InvoiceRoundingAmount);
                ShouldConfirmInvoiceRounding := InvoiceRoundingAmount <> 0;
                OnReminderHeaderOnAfterGetRecordOnAfterCalcShouldConfirmInvoiceRounding("Reminder Header", InvoiceRoundingAmount, ShouldConfirmInvoiceRounding);
                if ShouldConfirmInvoiceRounding then
                    if not ConfirmManagement.GetResponse(ProceedOnIssuingWithInvRoundingQst, false) then
                        CurrReport.Break();

                RecordNo := RecordNo + 1;
                Clear(ReminderIssue);
                ReminderIssue.Set("Reminder Header", ReplacePostingDate, PostingDateReq, ReplaceVATDateReq, VATDateReq);
                ReminderIssue.SetGenJnlBatch(GenJnlBatch);
                OnReminderHeaderOnAfterGetRecordOnAfterReminderIssueSetParams("Reminder Header", ReminderIssue, PrintEmailDocument);
                if NoOfRecords = 1 then begin
                    ReminderIssue.Run();
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                    Commit();
                    Mark := not ReminderIssue.Run();
                end;

                if PrintEmailDocument <> PrintEmailDocument::" " then begin
                    ReminderIssue.GetIssuedReminder(IssuedReminderHeader);
                    TempIssuedReminderHeader := IssuedReminderHeader;
                    OnBeforeTempIssuedReminderHeaderInsert(TempIssuedReminderHeader);
                    if TempIssuedReminderHeader."No." <> '' then
                        TempIssuedReminderHeader.Insert();
                end;
            end;

            trigger OnPostDataItem()
            var
                IssuedReminderHeaderPrint: Record "Issued Reminder Header";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                Window.Close();
                Commit();
                if PrintEmailDocument <> PrintEmailDocument::" " then
                    if TempIssuedReminderHeader.FindSet() then
                        repeat
                            IssuedReminderHeaderPrint := TempIssuedReminderHeader;
                            IsHandled := false;
                            OnBeforePrintIssuedReminderHeader(IssuedReminderHeaderPrint, IsHandled, PrintEmailDocument, HideDialog);
                            if not IsHandled then begin
                                IssuedReminderHeaderPrint.SetRecFilter();
                                IssuedReminderHeaderPrint.PrintRecords(false, PrintEmailDocument = PrintEmailDocument::Email, HideDialog);
                            end;
                        until TempIssuedReminderHeader.Next() = 0;
                MarkedOnly := true;
                if FindFirst() then
                    if ConfirmManagement.GetResponse(ShowNotIssuedQst, true) then
                        PAGE.RunModal(0, "Reminder Header");
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(EnterPostingDateErr);
                if ReplaceVATDateReq and (VATDateReq = 0D) then
                    Error(EnterVATDateErr);

                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(IssuingReminderMsg)
                else begin
                    Window.Open(IssuingRemindersMsg);
                    OldDateTime := CurrentDateTime;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintDoc; PrintEmailDocument)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print';
                        OptionCaption = ' ,Print,Email';
                        Enabled = not IsOfficeAddin;
                        ToolTip = 'Specifies it you want to print or email the reminders when they are issued.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the reminders'' posting date with the date entered in the field below.';

                        trigger OnValidate()
                        begin
                            if VATReportingDateMgt.IsVATDateUsageSetToPostingDate() then
                                ReplaceVATDateReq := ReplacePostingDate;

                            UpdateVATDate();
                        end;
                    }
                    field(ReplaceVATDate; ReplaceVATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Replace VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies if you want to replace the reminders'' VAT date with the date entered in the field below.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date. If you place a check mark in the check box above, the program will use this date on all reminders when you post.';

                        trigger OnValidate()
                        begin
                            UpdateVATDate();
                        end;
                    }
                    field(VATDate; VATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies the VAT date. If you place a check mark in the check box above, the program will use this date on all reminders when you post.';
                    }
                    field(HideEmailDialog; HideDialog)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Hide Email Dialog';
                        ToolTip = 'Specifies if you want to hide email dialog.';
                    }
                    field(JnlTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.Get();
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();

            if GLSetup."Journal Templ. Name Mandatory" then begin
                IsJournalTemplNameVisible := true;
                SalesSetup.get();
                SalesSetup.TestField("Reminder Journal Template Name");
                SalesSetup.TestField("Reminder Journal Batch Name");
                GenJnlBatch.Get(SalesSetup."Reminder Journal Template Name", SalesSetup."Reminder Journal Batch Name");
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        IsOfficeAddin := OfficeMgt.IsAvailable();
        if IsOfficeAddin then
            PrintEmailDocument := 2;

        OnAfterInitReport(PrintEmailDocument, ReplacePostingDate, PostingDateReq, HideDialog);
    end;

    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        TempIssuedReminderHeader: Record "Issued Reminder Header" temporary;
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        ReminderIssue: Codeunit "Reminder-Issue";
        ConfirmManagement: Codeunit "Confirm Management";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        ReplacePostingDate, ReplaceVATDateReq : Boolean;
        HideDialog: Boolean;
        IsJournalTemplNameVisible: Boolean;

        EnterPostingDateErr: Label 'Enter the Posting Date.';
        EnterVATDateErr: Label 'Enter the VAT Date.';
        IssuingReminderMsg: Label 'Issuing reminder...';
        IssuingRemindersMsg: Label 'Issuing reminders @1@@@@@@@@@@@@@';
        ShowNotIssuedQst: Label 'It was not possible to issue some of the selected reminders.\Do you want to see these reminders?';
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the reminder when it is posted according to invoice rounding setup.\Do you want to continue?';

    protected var
        PostingDateReq, VATDateReq : Date;
        PrintEmailDocument: Option " ",Print,Email;
        IsOfficeAddin: Boolean;
        VATDateEnabled: Boolean;

    local procedure UpdateVATDate()
    begin
        if ReplaceVATDateReq then
            VATDateReq := PostingDateReq;
    end;

    /// <summary>
    /// Raised after the report initialization to set default parameter values.
    /// </summary>
    /// <param name="PrintDoc">The print/email option setting.</param>
    /// <param name="ReplacePostingDate">Indicates whether to replace the posting date.</param>
    /// <param name="PostingDateReq">The posting date request value.</param>
    /// <param name="HideDialog">Indicates whether to hide dialogs.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReport(var PrintDoc: Option " ",Print,Email; var ReplacePostingDate: Boolean; var PostingDateReq: Date; var HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing or emailing an issued reminder.
    /// </summary>
    /// <param name="IssuedReminderHeader">The issued reminder header to print.</param>
    /// <param name="IsHandled">Set to true to skip default printing.</param>
    /// <param name="PrintDoc">The print/email option setting.</param>
    /// <param name="HideDialog">Indicates whether to hide the email dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintIssuedReminderHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; var IsHandled: Boolean; PrintDoc: Option " ",Print,Email; HideDialog: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a temporary issued reminder header for printing.
    /// </summary>
    /// <param name="TempIssuedReminderHeader">The temporary issued reminder header to insert.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempIssuedReminderHeaderInsert(var TempIssuedReminderHeader: Record "Issued Reminder Header" temporary)
    begin
    end;

    /// <summary>
    /// Raised after calculating whether to confirm invoice rounding.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being issued.</param>
    /// <param name="InvoiceRoundingAmount">The calculated invoice rounding amount.</param>
    /// <param name="ShouldConfirmInvoiceRounding">Indicates whether to show the rounding confirmation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnReminderHeaderOnAfterGetRecordOnAfterCalcShouldConfirmInvoiceRounding(var ReminderHeader: Record "Reminder Header"; InvoiceRoundingAmount: Decimal; var ShouldConfirmInvoiceRounding: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting parameters on the reminder issue codeunit.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being issued.</param>
    /// <param name="ReminderIssue">The reminder issue codeunit instance.</param>
    /// <param name="PrintDoc">The print/email option setting.</param>
    [IntegrationEvent(false, false)]
    local procedure OnReminderHeaderOnAfterGetRecordOnAfterReminderIssueSetParams(var ReminderHeader: Record "Reminder Header"; var ReminderIssue: Codeunit "Reminder-Issue"; PrintDoc: Option)
    begin
    end;

    /// <summary>
    /// Raised after calculating the invoice rounding amount for a reminder.
    /// </summary>
    /// <param name="ReminderHeader">The reminder header being processed.</param>
    /// <param name="InvoiceRoundingAmount">The calculated invoice rounding amount.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordReminderHeaderOnAfterGetInvoiceRoundingAmount(var ReminderHeader: Record "Reminder Header"; var InvoiceRoundingAmount: Decimal)
    begin
    end;
}

