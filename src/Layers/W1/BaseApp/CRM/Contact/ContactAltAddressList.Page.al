// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5057 "Contact Alt. Address List"
{
    Caption = 'Contact Alt. Address List';
    CardPageID = "Contact Alt. Address Card";
    DataCaptionFields = "Contact No.", "Code";
    Editable = false;
    PageType = List;
    SourceTable = "Contact Alt. Address";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Company Name 2"; Rec."Company Name 2")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field(County; Rec.County)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    ExtendedDatatype = EMail;
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
}

