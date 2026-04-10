// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 7301 "Zone List"
{
    Caption = 'Zone List';
    DataCaptionFields = "Location Code";
    Editable = false;
    PageType = List;
    SourceTable = Zone;

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
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
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
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Zone Ranking"; Rec."Zone Ranking")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zone Ranking';
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
        area(navigation)
        {
            group("&Zone")
            {
                Caption = '&Zone';
                Image = Zones;
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Zone Code" = field(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to hold items.';
                }
            }
        }
    }
}

