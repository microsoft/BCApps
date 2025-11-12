// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using System.Utilities;

report 1393 "Cancel Issued Reminders"
{
    AdditionalSearchTerms = 'cancel issued reminder';
    Caption = 'Cancel Issued Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            RequestFilterFields = "No.", "Customer No.", "Posting Date";

            trigger OnAfterGetRecord()
            var
                TempErrorMessage: Record "Error Message" temporary;
                CancelIssuedReminder: Codeunit "Cancel Issued Reminder";
            begin
                CancelIssuedReminder.SetParameters(UseSameDocumentNo, UseSamePostingDate, NewPostingDate, UseSameVATDateReq, NewVATDateReq, NoOfRecords > 1);
                CancelIssuedReminder.SetGenJnlBatch(GenJnlBatch);
                if CancelIssuedReminder.Run("Issued Reminder Header") then begin
                    if CancelIssuedReminder.GetErrorMessages(TempErrorMessage) then
                        AddIssuedReminderToErrorBuffer();
                    Commit();
                end else
                    if NoOfRecords > 1 then begin
                        TempErrorMessage.LogLastError();
                        AddIssuedReminderToErrorBuffer();
                    end else
                        Error(GetLastErrorText);
            end;

            trigger OnPostDataItem()
            begin
                if NoOfRecords > 1 then
                    if not TempIssuedReminderHeader.IsEmpty() then
                        AskShowNotCancelledIssuedReminders();
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 0 then
                    Error(NothingToCancelErr);

                if (not UseSamePostingDate) and (NewPostingDate = 0D) then
                    Error(SpecifyPostingDateErr);

                if (not UseSameVATDateReq) and (NewVATDateReq = 0D) then
                    Error(SpecifyVATDateErr);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(UseSameDocumentNo; UseSameDocumentNo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Document No.';
                    ToolTip = 'Specifies if you want to use the same document number for corrective ledger entries. If you do not select the check box, then a document number will be assigned from the Canceled Issued Reminder Nos. number series that is defined on the Sales & Receivables Setup page.';
                }
                field(UseSamePostingDate; UseSamePostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Posting Date';
                    ToolTip = 'Specifies if you want to use same posting date for corrective ledger entries.';

                    trigger OnValidate()
                    begin
                        if UseSamePostingDate then
                            NewPostingDate := 0D;
                        SetEnabled();

                        if VATReportingDateMgt.IsVATDateUsageSetToPostingDate() then
                            UseSameVATDateReq := UseSamePostingDate;
                    end;
                }
                field(UseSameVATDate; UseSameVATDateReq)
                {
                    ApplicationArea = VAT;
                    Caption = 'Use Same VAT Date';
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies if you want to use same VAT date for corrective ledger entries.';
                }
                field(NewVATDate; NewVATDateReq)
                {
                    ApplicationArea = VAT;
                    Caption = 'New VAT Date';
                    Editable = VATDateEnabled and (not UseSameVATDateReq);
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the new VAT date for corrective ledger entries.';
                }
                field(NewPostingDate; NewPostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Posting Date';
                    Enabled = NewPostingDateEnabled;
                    ToolTip = 'Specifies the new posting date for corrective ledger entries.';

                    trigger OnValidate()
                    begin
                        UpdateVATDate();
                    end;
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

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UseSameDocumentNo := true;
            UseSamePostingDate := true;
            UseSameVATDateReq := true;
            SetEnabled();
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();

            GLSetup.Get();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    var
        TempIssuedReminderHeader: Record "Issued Reminder Header" temporary;
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLSetup: Record "General Ledger Setup";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        NoOfRecords: Integer;
        NothingToCancelErr: Label 'There is nothing to cancel.';
        UseSameDocumentNo: Boolean;
        UseSamePostingDate, UseSameVATDateReq : Boolean;
        NewPostingDate, NewVATDateReq : Date;
        NewPostingDateEnabled: Boolean;
        IsJournalTemplNameVisible: Boolean;
        VATDateEnabled: Boolean;
        SpecifyPostingDateErr: Label 'You must specify a Posting Date.';
        SpecifyVATDateErr: Label 'You must specify a VAT Date.';
        ShowNotCancelledRemindersQst: Label 'One or more of the selected issued reminders could not be canceled.\\Do you want to see a list of the issued reminders that were not canceled?';

    local procedure SetEnabled()
    begin
        NewPostingDateEnabled := not UseSamePostingDate;
    end;

    local procedure AskShowNotCancelledIssuedReminders()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(ShowNotCancelledRemindersQst, true) then
            PAGE.RunModal(PAGE::"Issued Reminder List", TempIssuedReminderHeader);
    end;

    local procedure AddIssuedReminderToErrorBuffer()
    begin
        TempIssuedReminderHeader := "Issued Reminder Header";
        TempIssuedReminderHeader.Insert();
    end;

    local procedure UpdateVATDate()
    begin
        if not UseSameVATDateReq then
            NewVATDateReq := NewPostingDate;
    end;
}

