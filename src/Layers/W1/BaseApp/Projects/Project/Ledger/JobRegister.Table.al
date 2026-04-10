// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 241 "Job Register"
{
    Caption = 'Project Register';
    DrillDownPageID = "Job Registers";
    LookupPageID = "Job Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            ToolTip = 'Specifies the first item entry number in the register.';
            TableRelation = "Job Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            ToolTip = 'Specifies the entry number of the last entry line you included before you posted the entries in the journal.';
            TableRelation = "Job Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date on which you posted the entries in the journal.';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            ToolTip = 'Specifies the time on which you posted the entries in the journal.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetNextEntryNo(UseLegacyPosting: Boolean): Integer
    begin
        if not UseLegacyPosting then
            exit(GetNextEntryNo());
        Rec.LockTable();
        exit(GetLastEntryNo() + 1);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Register", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Job Register"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;
}

