// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Comment;

page 5204 "Alternative Address List"
{
    Caption = 'Alternate Address List';
    CardPageID = "Alternative Address Card";
    DataCaptionFields = "Employee No.";
    Editable = false;
    PageType = List;
    SourceTable = "Alternative Address";

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
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Visible = false;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Address")
            {
                Caption = '&Address';
                Image = Addresses;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = const("Alternative Address"),
                                  "No." = field("Employee No."),
                                  "Alternative Address Code" = field(Code);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }
}

