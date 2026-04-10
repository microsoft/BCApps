// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7303 "Bin List"
{
    Caption = 'Bin List';
    DataCaptionFields = "Zone Code";
    Editable = false;
    PageType = List;
    SourceTable = Bin;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field(Empty; Rec.Empty)
                {
                    ApplicationArea = Warehouse;
                }
                field(Default; Rec.Default)
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
                field(Dedicated; Rec.Dedicated)
                {
                    ApplicationArea = Warehouse;
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
        area(navigation)
        {
            group("&Bin")
            {
                Caption = '&Bin';
                Image = Bins;
                action("&Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Zone Code" = field("Zone Code"),
                                  "Bin Code" = field(Code);
                    ToolTip = 'View the bin content. A bin can hold several different items. Each item that has been fixed to the bin, placed in the bin, or for which the bin is the default bin appears in this window as a separate line. Some of the fields on the lines contain information about the bin for which you are creating bin content, for example, the bin ranking, and you cannot change these values.';
                }
            }
        }
    }
}

