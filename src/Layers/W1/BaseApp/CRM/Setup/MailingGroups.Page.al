// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

page 5063 "Mailing Groups"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Mailing Groups';
    PageType = List;
    SourceTable = "Mailing Group";
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the mailing group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the mailing group.';
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Mailing Group Contacts";
                    ToolTip = 'Specifies the number of contacts that have been assigned the mailing group. This field is not editable.';
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
            group("&Mailing Group")
            {
                Caption = '&Mailing Group';
                Image = Group;
                action("C&ontacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'C&ontacts';
                    Image = CustomerContact;
                    RunObject = Page "Mailing Group Contacts";
                    RunPageLink = "Mailing Group Code" = field(Code);
                    ToolTip = 'View a list of the contact companies you have assigned the mailing group to.';
                }
            }
        }
    }
}

