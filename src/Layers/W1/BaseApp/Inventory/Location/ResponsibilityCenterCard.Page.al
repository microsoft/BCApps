// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.Dimension;

page 5714 "Responsibility Center Card"
{
    Caption = 'Responsibility Center Card';
    PageType = Card;
    SourceTable = "Responsibility Center";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Location;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Location;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Location;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Location;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Location;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the person you regularly contact. ';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Location;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Location;
                    Importance = Additional;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Location;
                    ExtendedDatatype = EMail;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Location;
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
            group("&Resp. Ctr.")
            {
                Caption = '&Resp. Ctr.';
                Image = Dimensions;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5714),
                                  "No." = field(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }
}

