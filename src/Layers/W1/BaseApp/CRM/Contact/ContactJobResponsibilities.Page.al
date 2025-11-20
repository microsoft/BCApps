// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5081 "Contact Job Responsibilities"
{
    Caption = 'Contact Job Responsibilities';
    DataCaptionFields = "Contact No.";
    PageType = List;
    SourceTable = "Contact Job Responsibility";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job Responsibility Code"; Rec."Job Responsibility Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job responsibility code.';
                }
                field("Job Responsibility Description"; Rec."Job Responsibility Description")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    ToolTip = 'Specifies the description for the job responsibility you have assigned to the contact.';
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

