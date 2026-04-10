// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

page 5071 "Web Source Launch"
{
    Caption = 'Web Source Launch';
    Editable = false;
    PageType = List;
    SourceTable = "Contact Web Source";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Web Source Code"; Rec."Web Source Code")
                {
                    ApplicationArea = All;
                }
                field("Web Source Description"; Rec."Web Source Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                }
                field("Search Word"; Rec."Search Word")
                {
                    ApplicationArea = RelationshipMgmt;
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

