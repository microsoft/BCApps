// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Family;

page 99000790 Family
{
    Caption = 'Family';
    PageType = ListPlus;
    SourceTable = Family;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            part(Control13; "Family Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Family No." = field("No.");
                SubPageView = sorting("Family No.", "Line No.");
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

