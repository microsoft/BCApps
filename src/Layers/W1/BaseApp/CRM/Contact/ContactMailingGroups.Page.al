// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5064 "Contact Mailing Groups"
{
    Caption = 'Contact Mailing Groups';
    DataCaptionFields = "Contact No.";
    PageType = List;
    SourceTable = "Contact Mailing Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Mailing Group Code"; Rec."Mailing Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the mailing group code. This field is not editable.';
                }
                field("Mailing Group Description"; Rec."Mailing Group Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the mailing group you have chosen to assign the contact.';
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

