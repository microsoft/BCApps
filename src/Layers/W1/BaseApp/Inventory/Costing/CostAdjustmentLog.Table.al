// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

table 5806 "Cost Adjustment Log"
{
    DataClassification = CustomerContent;
    Caption = 'Cost Adjustment Log';
    LookupPageId = "Cost Adjustment Logs";
    InherentPermissions = Rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Cost Adjustment Run Guid"; Guid)
        {
            Caption = 'Cost Adjustment Run Guid';
        }
        field(3; Status; Enum "Cost Adjustment Run Status")
        {
            Caption = 'Status';
        }
        field(4; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
        }
        field(5; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
        }
        field(6; "Item Register No."; Integer)
        {
            Caption = 'Item Register No.';
            TableRelation = "Item Register";
            ValidateTableRelation = false;
            BlankZero = true;
        }
        field(7; "Item Filter"; Text[2048])
        {
            Caption = 'Item Filter';
        }
        field(11; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
        field(12; "Last Error Call Stack"; Text[2048])
        {
            Caption = 'Last Error Call Stack';
        }
        field(13; "Failed Item No."; Code[20])
        {
            Caption = 'Failed Item No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Cost Adjustment Run Guid")
        {

        }
    }
}
