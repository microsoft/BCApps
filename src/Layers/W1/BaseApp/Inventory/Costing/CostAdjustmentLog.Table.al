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
            ToolTip = 'Specifies the number of the entry.';
            AutoIncrement = true;
        }
        field(2; "Cost Adjustment Run Guid"; Guid)
        {
            Caption = 'Cost Adjustment Run Guid';
            ToolTip = 'Specifies the unique identifier of the cost adjustment run.';
        }
        field(3; Status; Enum "Cost Adjustment Run Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the cost adjustment run.';
        }
        field(4; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
            ToolTip = 'Specifies the starting date and time of the cost adjustment run.';
        }
        field(5; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
            ToolTip = 'Specifies the ending date and time of the cost adjustment run.';
        }
        field(6; "Item Register No."; Integer)
        {
            Caption = 'Item Register No.';
            ToolTip = 'Specifies the item register number that is created for the cost adjustment run. Blank value indicates that the cost adjustment has not produced any new value entries.';
            TableRelation = "Item Register";
            ValidateTableRelation = false;
            BlankZero = true;
        }
        field(7; "Item Filter"; Text[2048])
        {
            Caption = 'Item Filter';
            ToolTip = 'Specifies the item filter used for the cost adjustment run.';
        }
        field(11; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            ToolTip = 'Specifies the last error that occurred during the cost adjustment run.';
        }
        field(12; "Last Error Call Stack"; Text[2048])
        {
            Caption = 'Last Error Call Stack';
            ToolTip = 'Specifies the last error call stack that occurred during the cost adjustment run.';
        }
        field(13; "Failed Item No."; Code[20])
        {
            Caption = 'Failed Item No.';
            ToolTip = 'Specifies the item number that failed during the cost adjustment run.';
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
