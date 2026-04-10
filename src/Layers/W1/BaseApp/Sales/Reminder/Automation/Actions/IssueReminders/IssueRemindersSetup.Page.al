// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;

/// <summary>
/// Configures the parameters for the automated issue reminders action including posting options and filters.
/// </summary>
page 6761 "Issue Reminders Setup"
{
    PageType = Card;
    SourceTable = "Issue Reminders Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                group(RequestParameters)
                {
                    ShowCaption = false;
                    field(ReplacePostingDate; Rec."Replace Posting Date")
                    {
                        ApplicationArea = All;
                        Caption = 'Replace posting date';
                    }
                    field("Replace Posting Date formula"; Rec."Replace Posting Date formula")
                    {
                        ApplicationArea = All;
                        Caption = 'Replace posting date formula';
                    }
                    field("Replace VAT Date"; Rec."Replace VAT Date")
                    {
                        Visible = VATDateEnabled;
                        ApplicationArea = All;
                        Caption = 'Replace VAT date';
                    }
                    field("Replace VAT Date formula"; Rec."Replace VAT Date formula")
                    {
                        Visible = VATDateEnabled;
                        ApplicationArea = All;
                        Caption = 'Replace VAT date formula';
                    }
                }
                group(JournalGroup)
                {
                    ShowCaption = false;
                    Visible = IsJournalTemplNameVisible;

                    field(JnlTemplateName; Rec."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";

                        trigger OnValidate()
                        begin
                            Rec."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; Rec."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJournalLine."Journal Batch Name" := Rec."Journal Batch Name";
                            GenJnlManagement.SetJnlBatchName(GenJournalLine);
                            if GenJournalLine."Journal Batch Name" <> '' then
                                Rec."Journal Batch Name" := GenJournalLine."Journal Batch Name";
                            exit(true);
                        end;
                    }
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(ReminderFilter; ReminderFilterTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Filter';
                    ToolTip = 'Specifies the filter that is used to define which reminders can be processed by this job.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetReminderSelectionFilter();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        if GeneralLedgerSetup.Get() then
            IsJournalTemplNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";

        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        ReminderFilterTxt := Rec.GetReminderSelectionDisplayText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ReminderFilterTxt := Rec.GetReminderSelectionDisplayText();
    end;

    var
        VATDateEnabled: Boolean;
        IsJournalTemplNameVisible: Boolean;
        ReminderFilterTxt: Text;
}
