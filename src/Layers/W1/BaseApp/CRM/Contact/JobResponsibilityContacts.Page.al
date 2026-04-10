// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5083 "Job Responsibility Contacts"
{
    Caption = 'Job Responsibility Contacts';
    DataCaptionFields = "Job Responsibility Code";
    PageType = List;
    SourceTable = "Contact Job Responsibility";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
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

