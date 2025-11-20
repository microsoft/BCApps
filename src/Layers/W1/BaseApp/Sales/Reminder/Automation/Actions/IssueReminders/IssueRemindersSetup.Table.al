// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Automation;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Setup;

table 6756 "Issue Reminders Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[50])
        {
        }
        field(2; "Action Group Code"; Code[50])
        {
        }
        field(3; Description; Text[50])
        {
        }
        field(10; "Replace Posting Date"; Option)
        {
            OptionMembers = "No","Use date from reminder","Use Workdate";
        }
        field(11; "Replace Posting Date formula"; DateFormula)
        {
        }
        field(12; "Replace VAT Date"; Option)
        {
            OptionMembers = "No","Use date from reminder","Use Workdate";
        }
        field(13; "Replace VAT Date formula"; DateFormula)
        {
        }
        field(20; "Reminder Filter"; Blob)
        {
        }
        field(21; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(22; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
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

    procedure SetReminderSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        ReminderHeaderRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        ExistingFilters: Text;
    begin
        ReminderHeaderRecordRef.Open(Database::"Reminder Header");
        Clear(Rec."Reminder Filter");
        Rec."Reminder Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        ExistingFilters := GetReminderSelectionFilter();
        if not RequestPageParametersHelper.OpenPageToGetFilter(ReminderHeaderRecordRef, SelectionFilterOutStream, ExistingFilters) then
            exit;

        Rec.Modify();
    end;

    procedure GetReminderSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

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