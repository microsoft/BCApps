// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Utilities;
using System.Security.AccessControl;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Setup;

table 343 "Item Application Entry History"
{
    Caption = 'Item Application Entry History';
    DrillDownPageID = "Item Application Entry History";
    LookupPageID = "Item Application Entry History";
    Permissions = TableData "Item Application Entry History" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "Inbound Item Entry No."; Integer)
        {
            Caption = 'Inbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Outbound Item Entry No."; Integer)
        {
            Caption = 'Outbound Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(9; "Primary Entry No."; Integer)
        {
            Caption = 'Primary Entry No.';
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Transferred-from Entry No."; Integer)
        {
            Caption = 'Transferred-from Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(25; "Creation Date"; DateTime)
        {
            Caption = 'Creation Date';
        }
        field(26; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(27; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
        }
        field(28; "Last Modified By User"; Code[50])
        {
            Caption = 'Last Modified By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(29; "Deleted Date"; DateTime)
        {
            Caption = 'Deleted Date';
        }
        field(30; "Deleted By User"; Code[50])
        {
            Caption = 'Deleted By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5800; "Cost Application"; Boolean)
        {
            Caption = 'Cost Application';
        }
        field(5804; "Output Completely Invd. Date"; Date)
        {
            Caption = 'Output Completely Invd. Date';
        }
    }

    keys
    {
        key(Key1; "Primary Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Application Entry History", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        InventorySetup: Record "Inventory Setup";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if InventorySetup.UseLegacyPosting() then
            exit(GetLastEntryNo() + 1);
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Item Application Entry History"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Application Entry History", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Primary Entry No.")))
    end;
}

