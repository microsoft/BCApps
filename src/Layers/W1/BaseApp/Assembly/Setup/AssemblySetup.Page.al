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
                }
                field("Copy Component Dimensions from"; Rec."Copy Component Dimensions from")
                {
                    ApplicationArea = Dimensions;
                }
                field("Default Location for Orders"; Rec."Default Location for Orders")
                {
                    ApplicationArea = Location;
                }
                field("Copy Comments when Posting"; Rec."Copy Comments when Posting")
                {
                    ApplicationArea = Assembly;
                }
                field("Default Gen. Bus. Post. Group"; Rec."Default Gen. Bus. Post. Group")
                {
                    ApplicationArea = Assembly;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Assembly Order Nos."; Rec."Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                }
                field("Assembly Quote Nos."; Rec."Assembly Quote Nos.")
                {
                    ApplicationArea = Assembly;
                }
                field("Blanket Assembly Order Nos."; Rec."Blanket Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                }
                field("Posted Assembly Order Nos."; Rec."Posted Assembly Order Nos.")
                {
                    ApplicationArea = Assembly;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Create Movements Automatically"; Rec."Create Movements Automatically")
                {
                    ApplicationArea = Warehouse;
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

