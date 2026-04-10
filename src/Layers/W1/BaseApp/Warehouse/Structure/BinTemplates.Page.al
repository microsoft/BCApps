// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7367 "Bin Templates"
{
    ApplicationArea = Warehouse;
    Caption = 'Bin Templates';
    DataCaptionFields = "Code", Description;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Description"; Rec."Bin Description")
                {
                    ApplicationArea = Warehouse;
                }
                field("Bin Type Code"; Rec."Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Block Movement"; Rec."Block Movement")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Ranking"; Rec."Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Maximum Cubage"; Rec."Maximum Cubage")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Maximum Weight"; Rec."Maximum Weight")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

