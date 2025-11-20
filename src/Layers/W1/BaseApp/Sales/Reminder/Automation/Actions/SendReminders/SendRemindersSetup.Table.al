// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Automation;

table 6755 "Send Reminders Setup"
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
        field(10; "Send by Email"; Boolean)
        {
            InitValue = true;
        }
        field(11; Print; Boolean)
        {
        }
        field(12; "Use Document Sending Profile"; Boolean)
        {
        }
        field(13; "Log Interaction"; Boolean)
        {
        }
        field(14; "Show Amounts Not Due"; Boolean)
        {
        }
        field(15; "Show Multiple Interest Rates"; Boolean)
        {
        }
        field(16; "Attach Invoice Documents"; Option)
        {
            OptionCaption = 'No, Overdue only, All';
            OptionMembers = No,"Overdue only",All;
        }
        field(17; "Send Multiple Times Per Level"; Boolean)
        {
        }
        field(18; "Minimum Time Between Sending"; Duration)
        {
        }
        field(20; "Reminder Filter"; Blob)
        {
        }
    }
    keys
    {
        key(Key1; Code, "Action Group Code")
        {
            Clustered = true;
        }
    }

    procedure SetReminderSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        IssuedReminderHeaderRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        ExistingFilters: Text;
    begin
        IssuedReminderHeaderRecordRef.Open(Database::"Issued Reminder Header");
        Clear(Rec."Reminder Filter");
        Rec."Reminder Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        ExistingFilters := GetReminderSelectionFilter();
        if not RequestPageParametersHelper.OpenPageToGetFilter(IssuedReminderHeaderRecordRef, SelectionFilterOutStream, ExistingFilters) then
            exit;

        Rec.Modify();
    end;

    procedure GetReminderSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Issued Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

    procedure GetReminderSelectionFilterView(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Issued Reminder Header", Rec.FieldNo("Reminder Filter")));
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
}