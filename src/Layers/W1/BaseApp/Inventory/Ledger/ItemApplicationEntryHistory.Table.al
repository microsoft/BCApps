// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Setup;
using Microsoft.Utilities;
using System.Security.AccessControl;

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
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            ToolTip = 'Specifies the entry number of the item ledger entry, for which the item application entry was recorded.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "Inbound Item Entry No."; Integer)
        {
            Caption = 'Inbound Item Entry No.';
            ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory increase or positive quantity in inventory for this entry.';
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Outbound Item Entry No."; Integer)
        {
            Caption = 'Outbound Item Entry No.';
            ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory decrease for this entry.';
            TableRelation = "Item Ledger Entry";
        }
        field(9; "Primary Entry No."; Integer)
        {
            Caption = 'Primary Entry No.';
            ToolTip = 'Specifies a unique identifying number for each item application entry history record.';
        }
        field(11; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the item quantity being applied from the inventory decrease in the Outbound Item Entry No. field, to the inventory increase in the Inbound Item Entry No. field.';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies a date that corresponds to the posting date of the item ledger entry, for which this item application entry was created.';
        }
        field(23; "Transferred-from Entry No."; Integer)
        {
            Caption = 'Transferred-from Entry No.';
            ToolTip = 'Specifies the item ledger entry number of the inventory increase, if an item application entry originates from an item location transfer.';
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
            ToolTip = 'Specifies which application entries should have the cost forwarded, or simply included, in an average cost calculation.';
        }
        field(5804; "Output Completely Invd. Date"; Date)
        {
            Caption = 'Output Completely Invd. Date';
            ToolTip = 'Specifies the outbound item entries have been completely invoiced.';
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

