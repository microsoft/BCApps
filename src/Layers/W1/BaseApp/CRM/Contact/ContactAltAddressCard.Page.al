// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5056 "Contact Alt. Address Card"
{
    Caption = 'Contact Alt. Address Card';
    DataCaptionExpression = Caption();
    PageType = Card;
    SourceTable = "Contact Alt. Address";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Post Code"; Rec."Post Code")
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
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number for the alternate address.';
                }
                field("Mobile Phone No."; Rec."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Telex No."; Rec."Telex No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Pager; Rec.Pager)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Telex Answer Back"; Rec."Telex Answer Back")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
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
            group("&Alt. Contact Address")
            {
                Caption = '&Alt. Contact Address';
                action("Date Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Ranges';
                    Image = DateRange;
                    RunObject = Page "Alt. Addr. Date Ranges";
                    RunPageLink = "Contact No." = field("Contact No."),
                                  "Contact Alt. Address Code" = field(Code);
                    ToolTip = 'Specify date ranges that apply to the contact''s alternate address.';
                }
            }
        }
    }

    var
#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning restore AA0074

    procedure Caption(): Text
    var
        Cont: Record Contact;
    begin
        if Cont.Get(Rec."Contact No.") then
            exit(Rec."Contact No." + ' ' + Cont.Name + ' ' + Rec.Code + ' ' + Rec."Company Name");

        exit(Text000);
    end;
}

