// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

page 5080 "Job Responsibilities"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Job Responsibilities';
    PageType = List;
    SourceTable = "Job Responsibility";
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDownPageID = "Job Responsibility Contacts";
                    Visible = HideNumberOfContacts;
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
            group("&Job Responsibility")
            {
                Caption = '&Job responsibility';
                Image = Job;
                action("C&ontacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'C&ontacts';
                    Image = CustomerContact;
                    RunObject = Page "Job Responsibility Contacts";
                    RunPageLink = "Job Responsibility Code" = field(Code);
                    ToolTip = 'View a list of contacts that are associated with the specific job responsibility.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        HideNumberOfContacts := false;
    end;

    internal procedure HideNumberOfContactsField()
    begin
        HideNumberOfContacts := true;
    end;

    var
        HideNumberOfContacts: Boolean;
}

