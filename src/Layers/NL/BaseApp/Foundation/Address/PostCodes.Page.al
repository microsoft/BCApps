// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

page 367 "Post Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Post Codes';
    PageType = List;
    AboutTitle = 'About Post Codes';
    AboutText = 'Maintain and view postal codes along with related city, county, country/region, and time zone information to ensure accurate address details across your business records.';
    PopulateAllFields = true;
    SourceTable = "Post Code";
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
                    ApplicationArea = Basic, Suite;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(TimeZone; Rec."Time Zone")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Zone';
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
            group("&Post Code")
            {
                Caption = '&Post Code';
                Image = ZoneCode;
                action("&Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Ranges';
                    Image = Ranges;
                    RunObject = Page "Post Code Ranges";
                    RunPageLink = "Post Code" = field(Code),
                                  City = field(City);
                    RunPageView = sorting("Post Code", City, Type, "From No.");
                    ToolTip = 'View or edit street names and cities by post codes. When you enter the post code and house number in an address field the program assists you in filling in the corresponding street name and city. If the house number does not fit into a range by the given post code, the Post Code Range window appears with a list of all the street names and cities by the given post code for you to select from.';
                }
            }
        }
    }
}

