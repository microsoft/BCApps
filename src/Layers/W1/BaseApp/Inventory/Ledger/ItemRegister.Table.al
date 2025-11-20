// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 46 "Item Register"
{
    Caption = 'Item Register';
    LookupPageID = "Item Registers";
    DataClassification = CustomerContent;
    Permissions = TableData "Item Register" = ri;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch".Name;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
        field(10; "From Phys. Inventory Entry No."; Integer)
        {
            Caption = 'From Phys. Inventory Entry No.';
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(11; "To Phys. Inventory Entry No."; Integer)
        {
            Caption = 'To Phys. Inventory Entry No.';
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(5800; "From Value Entry No."; Integer)
        {
            Caption = 'From Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(5801; "To Value Entry No."; Integer)
        {
            Caption = 'To Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(5831; "From Capacity Entry No."; Integer)
        {
            Caption = 'From Capacity Entry No.';
            TableRelation = Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        }
        field(5832; "To Capacity Entry No."; Integer)
        {
            Caption = 'To Capacity Entry No.';
            TableRelation = Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        }
        field(5895; "Cost Adjustment Run Guid"; Guid)
        {
            Caption = 'Cost Adjustment Run Guid';
            DataClassification = CustomerContent;
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
        key(Key4; "Cost Adjustment Run Guid")
        {

        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", "Creation Date", "Source Code")
        {
        }
    }

    procedure GetNextEntryNo(UseLegacyPosting: Boolean): Integer
    begin
        if not UseLegacyPosting then
            exit(GetNextEntryNo());
        Rec.LockTable();
        exit(GetLastEntryNo() + 1);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Register", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Item Register"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Register", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;
}

