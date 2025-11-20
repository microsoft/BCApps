// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

table 5807 "Cost Adjustment Detailed Log"
{
    DataClassification = CustomerContent;
    Caption = 'Cost Adjustment Detailed Log';
    LookupPageId = "Cost Adjustment Detailed Logs";
    InherentPermissions = Rimd;

    fields
    {
        field(1; "Cost Adjustment Run Guid"; Guid)
        {
            Caption = 'Cost Adjustment Run Guid';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
        }
        field(4; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
        }
        field(5; "Duration"; Duration)
        {
            Caption = 'Duration';
        }
        field(6; "Interim Date-Time"; DateTime)
        {
            Caption = 'Interim Date-Time';
        }
    }

    keys
    {
        key(PK; "Cost Adjustment Run Guid", "Item No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Ending Date-Time")
        {

        }
    }
}
