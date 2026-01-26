// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;

table 12130 "Lifo Band"
{
    Caption = 'Lifo Band';
    DrillDownPageID = "Lifo Band List";
    LookupPageID = "Lifo Band List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Lifo Category"; Code[20])
        {
            Caption = 'LIFO Category';
            TableRelation = "Lifo Category";
        }
        field(4; "Competence Year"; Date)
        {
            Caption = 'Competence Year';
            NotBlank = true;
        }
        field(10; "Increment Quantity"; Decimal)
        {
            Caption = 'Increment Quantity';

            trigger OnValidate()
            begin
                "Residual Quantity" := "Increment Quantity" - "Absorbed Quantity";
                UpdateIncrementValue();
            end;
        }
        field(11; "Absorbed Quantity"; Decimal)
        {
            Caption = 'Absorbed Quantity';

            trigger OnValidate()
            begin
                "Residual Quantity" := "Increment Quantity" - "Absorbed Quantity";
                UpdateIncrementValue();
            end;
        }
        field(12; "Residual Quantity"; Decimal)
        {
            Caption = 'Residual Quantity';
            Editable = true;

            trigger OnValidate()
            begin
                UpdateIncrementValue();
            end;
        }
        field(13; CMP; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'CMP';

            trigger OnValidate()
            begin
                UpdateIncrementValue();
            end;
        }
        field(16; Definitive; Boolean)
        {
            Caption = 'Definitive';
        }
        field(18; "Increment Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Increment Value';
        }
        field(20; "Qty not Invoiced"; Decimal)
        {
            Caption = 'Qty not Invoiced';
        }
        field(21; "Amount not Invoiced"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount not Invoiced';
        }
        field(25; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(27; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
        }
        field(30; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
        }
        field(31; "Invoiced Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoiced Amount';
        }
        field(32; "Year Average Cost"; Decimal)
        {
            Caption = 'Year Average Cost';

            trigger OnValidate()
            begin
                UpdateIncrementValue();
            end;
        }
        field(40; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Enabled = false;
            TableRelation = Location;
        }
        field(45; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Lifo Category", "Item No.", "Competence Year", "Location Code")
        {
            Enabled = false;
        }
        key(Key3; "Item No.", Positive)
        {
        }
        key(Key4; "Item No.", "Competence Year")
        {
        }
        key(Key5; "Lifo Category", "Item No.", "Competence Year")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    [Scope('OnPrem')]
    procedure UpdateIncrementValue()
    begin
        "Increment Value" := "Residual Quantity" * "Year Average Cost";
        OnAfterUpdateIncrementValue(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateIncrementValue(var LifoBand: Record "Lifo Band")
    begin
    end;
}

