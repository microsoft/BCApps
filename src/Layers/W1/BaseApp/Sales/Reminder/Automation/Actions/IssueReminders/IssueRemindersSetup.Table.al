// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Setup;
using System.Automation;
using System.Utilities;

/// <summary>
/// Stores the configuration settings for an automated issue reminders action including posting and journal options.
/// </summary>
table 6756 "Issue Reminders Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code identifying this issue reminders setup.
        /// </summary>
        field(1; Code; Code[50])
        {
            ToolTip = 'Specifies the unique code of the issue reminder setup.';
        }
        /// <summary>
        /// Specifies the reminder action group to which this setup belongs.
        /// </summary>
        field(2; "Action Group Code"; Code[50])
        {
        }
        /// <summary>
        /// Specifies a description of this issue reminders setup.
        /// </summary>
        field(3; Description; Text[50])
        {
            ToolTip = 'Specifies the description of the issue reminder setup.';
        }
        /// <summary>
        /// Specifies whether and how to replace the posting date when issuing reminders.
        /// </summary>
        field(10; "Replace Posting Date"; Option)
        {
            ToolTip = 'Specifies whether to replace the posting date of the reminder with the posting date of the original document.';
            OptionMembers = "No","Use date from reminder","Use Workdate";
        }
        /// <summary>
        /// Specifies the date formula for calculating the replacement posting date.
        /// </summary>
        field(11; "Replace Posting Date formula"; DateFormula)
        {
            ToolTip = 'Specifies the formula that is used to calculate the posting date of the reminder. Base date is the date when the job is started.';
        }
        /// <summary>
        /// Specifies whether and how to replace the VAT date when issuing reminders.
        /// </summary>
        field(12; "Replace VAT Date"; Option)
        {
            ToolTip = 'Specifies whether to replace the VAT date of the reminder with the VAT date of the original document.';
            OptionMembers = "No","Use date from reminder","Use Workdate";
        }
        /// <summary>
        /// Specifies the date formula for calculating the replacement VAT date.
        /// </summary>
        field(13; "Replace VAT Date formula"; DateFormula)
        {
            ToolTip = 'Specifies the formula that is used to calculate the VAT date of the reminder. Base date is the date when the job is started.';
        }
        /// <summary>
        /// Stores the filter criteria for selecting reminders to issue.
        /// </summary>
        field(20; "Reminder Filter"; Blob)
        {
        }
        /// <summary>
        /// Specifies the general journal template name for posting reminder entries.
        /// </summary>
        field(21; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            ToolTip = 'Specifies the name of the journal template that is used for the posting.';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Specifies the general journal batch name for posting reminder entries.
        /// </summary>
        field(22; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
        }
    }
    keys
    {
        key(Key1; Code, "Action Group Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        UpdateJournalTemplatesIfNeeded();
    end;

    /// <summary>
    /// Opens a filter page to allow the user to set the reminder selection filter for issuing.
    /// </summary>
    procedure SetReminderSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        ReminderHeaderRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        SelectionFilterInStream: InStream;
        ExistingFilters: Text;
    begin
        ReminderHeaderRecordRef.Open(Database::"Reminder Header");
        ExistingFilters := GetReminderSelectionFilter();

        TempBlob.CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        if not RequestPageParametersHelper.OpenPageToGetFilter(ReminderHeaderRecordRef, SelectionFilterOutStream, ExistingFilters) then
            exit;

        Clear(Rec."Reminder Filter");
        TempBlob.CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        Rec."Reminder Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        CopyStream(SelectionFilterOutStream, SelectionFilterInStream);

        Rec.Modify();
        Rec.CalcFields("Reminder Filter");
    end;

    /// <summary>
    /// Gets the display text for the reminder selection filter.
    /// </summary>
    /// <returns>A formatted display text showing the filter criteria.</returns>
    procedure GetReminderSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

    /// <summary>
    /// Gets the view filter for the reminder selection that can be applied to a record.
    /// </summary>
    /// <returns>The view filter string for reminder header records.</returns>
    procedure GetReminderSelectionFilterView(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

    local procedure GetReminderSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        Rec.CalcFields("Reminder Filter");
        Rec."Reminder Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Reminder Filter".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;

    local procedure UpdateJournalTemplatesIfNeeded()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        GeneralLedgerSetup.Get();

        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            SalesReceivablesSetup.Get();
            SalesReceivablesSetup.TestField("Reminder Journal Template Name");
            SalesReceivablesSetup.TestField("Reminder Journal Batch Name");
            Rec."Journal Template Name" := SalesReceivablesSetup."Reminder Journal Template Name";
            Rec."Journal Batch Name" := SalesReceivablesSetup."Reminder Journal Batch Name";
        end;
    end;
}