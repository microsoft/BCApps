// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Inventory.Ledger;
using System.Security.AccessControl;

table 5815 "Inventory Period Entry"
{
    Caption = 'Inventory Period Entry';
    DrillDownPageID = "Inventory Period Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            NotBlank = true;
        }
        field(2; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            NotBlank = true;
            TableRelation = "Inventory Period";
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
        field(6; "Closing Item Register No."; Integer)
        {
            Caption = 'Closing Item Register No.';
            TableRelation = "Item Register";
            ValidateTableRelation = false;
        }
        field(7; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = 'Close,Re-open';
            OptionMembers = Close,"Re-open";
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Ending Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure RemoveItemRegNo(EntryNo: Integer; PhysInventory: Boolean)
    var
        ItemReg: Record "Item Register";
        InvtPeriodEntry: Record "Inventory Period Entry";
    begin
        if PhysInventory then begin
            ItemReg.SetFilter("From Phys. Inventory Entry No.", '<=%1', EntryNo);
            ItemReg.SetFilter("To Phys. Inventory Entry No.", '>=%1', EntryNo);
        end else begin
            ItemReg.SetFilter("From Entry No.", '<=%1', "Entry No.");
            ItemReg.SetFilter("To Entry No.", '>=%1', "Entry No.");
        end;
        if ItemReg.FindFirst() then begin
            InvtPeriodEntry.SetFilter("Closing Item Register No.", '>=%1', ItemReg."No.");
            InvtPeriodEntry.ModifyAll("Closing Item Register No.", 0);
        end;
    end;
}

