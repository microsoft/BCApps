// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

table 7308 "Put-away Template Line"
{
    Caption = 'Put-away Template Line';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the set of criteria that is on the put-away template line.';
        }
        field(4; "Find Fixed Bin"; Boolean)
        {
            Caption = 'Find Fixed Bin';
            ToolTip = 'Specifies that you must put items in a particular bin. You define the bin by choosing the item on a line on the Bin Contents page and selecting the Fixed checkbox. If you haven''t specified a fixed bin for items, choose the Find Floating Bin checkbox.';

            trigger OnValidate()
            begin
                if "Find Fixed Bin" then begin
                    "Find Same Item" := true;
                    "Find Floating Bin" := false;
                end else
                    "Find Floating Bin" := true;
            end;
        }
        field(5; "Find Floating Bin"; Boolean)
        {
            Caption = 'Find Floating Bin';
            ToolTip = 'Specifies that you must put items in a bin that is not specifically tied to any particular item. A bin is considered floating when there are no lines in the Bin Contents page where the Fixed, Default, or Dedicated checkbox is selected.';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Find Floating Bin" then begin
                    "Find Bin w. Less than Min. Qty" := false;
                    "Find Fixed Bin" := false;
                end else begin
                    "Find Fixed Bin" := true;
                    "Find Same Item" := true;
                end;
            end;
        }
        field(6; "Find Same Item"; Boolean)
        {
            Caption = 'Find Same Item';
            ToolTip = 'Specifies that you must put items in bins that already contain the same item. You define the bin for an item by choosing the item on a line on the Bin Contents page. This setting doesn''t consider the quantity that''s currently in the bin.';

            trigger OnValidate()
            begin
                if "Find Fixed Bin" then
                    "Find Same Item" := true;

                if not "Find Same Item" then
                    "Find Unit of Measure Match" := false;
            end;
        }
        field(7; "Find Unit of Measure Match"; Boolean)
        {
            Caption = 'Find Unit of Measure Match';
            ToolTip = 'Specifies that you must put items in bins that have the same unit of measure as the item. You define the unit of measure for a bin on the Bin Contents page. To use this option, the bin must be assigned to a location where Directed Put-Away and Pick is enabled.';

            trigger OnValidate()
            begin
                if "Find Unit of Measure Match" then
                    "Find Same Item" := true;
            end;
        }
        field(8; "Find Bin w. Less than Min. Qty"; Boolean)
        {
            Caption = 'Find Bin w. Less than Min. Qty';
            ToolTip = 'Specifies that you must put items in bins that are currently below their minimum quantity of items. You define a minimum quantity for bins on the Bin Contents page.';

            trigger OnValidate()
            begin
                if "Find Bin w. Less than Min. Qty" then begin
                    Validate("Find Fixed Bin", true);
                    "Find Empty Bin" := false;
                end;
            end;
        }
        field(9; "Find Empty Bin"; Boolean)
        {
            Caption = 'Find Empty Bin';
            ToolTip = 'Specifies that an empty bin must be used in the put-away process.';

            trigger OnValidate()
            begin
                if "Find Empty Bin" then
                    "Find Bin w. Less than Min. Qty" := false;
            end;
        }
    }

    keys
    {
        key(Key1; "Put-away Template Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

