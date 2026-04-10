// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5055 "Name Details"
{
    Caption = 'Name Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Salutation Code"; Rec."Salutation Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s job title, and is valid for contact persons only.';
                }
                field(Initials; Rec.Initials)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Middle Name"; Rec."Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Surname; Rec.Surname)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Language Code"; Rec."Language Code")
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
        area(processing)
        {
            action("&Salutations")
            {
                ApplicationArea = Suite;
                Caption = '&Salutations';
                Image = Salutation;
                RunObject = Page "Contact Salutations";
                RunPageLink = "Contact No. Filter" = field("No."),
                              "Salutation Code" = field("Salutation Code");
                ToolTip = 'Edit specific details regarding the contact person''s name, for example the contact''s first name, middle name, surname, title, and so on.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Salutations_Promoted"; "&Salutations")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Editable(Rec.Type = Rec.Type::Person);
    end;
}

