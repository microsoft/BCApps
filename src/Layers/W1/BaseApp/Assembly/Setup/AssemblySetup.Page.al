// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Setup;

using Microsoft.Inventory.BOM;

page 905 "Assembly Setup"
{
    AccessByPermission = TableData "BOM Component" = R;
    AdditionalSearchTerms = 'kitting setup';
    ApplicationArea = Assembly;
    Caption = 'Assembly Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Assembly Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Stockout Warning"; Rec."Stockout Warning")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies whether the assembly availability warning appears during sales order entry.';
                }
                field("Copy Component Dimensions from"; Rec."Copy Component Dimensions from")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how dimension codes are distributed to assembly components when they are consumed in assembly order posting.';
                }
                field("Default Location for Orders"; Rec."Default Location for Orders")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies at which location assembly orders are created by default.';
                }
                field("Copy Comments when Posting"; Rec."Copy Comments when Posting")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies that comments on assembly order lines are copied to the resulting posted documents.';
                }
                field("Default Gen. Bus. Post. Group"; Rec."Default Gen. Bus. Post. Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the general business posting group that is used by default for assembly orders.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Assembly Order Nos."; Rec."Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly orders when they are created.';
                }
                field("Assembly Quote Nos."; Rec."Assembly Quote Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly quotes when they are created.';
                }
                field("Blanket Assembly Order Nos."; Rec."Blanket Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly blanket orders when they are created.';
                }
                field("Posted Assembly Order Nos."; Rec."Posted Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number series code used to assign numbers to assembly orders when they are posted.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Create Movements Automatically"; Rec."Create Movements Automatically")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that an inventory movement for the required components is created automatically when you create an inventory pick.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

