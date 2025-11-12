// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

page 5151 "Contact Salutations"
{
    Caption = 'Contact Salutations';
    Editable = false;
    PageType = List;
    SourceTable = "Salutation Formula";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Salutation Type"; Rec."Salutation Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the salutation is formal or informal. Make your selection by clicking the field.';
                }
                field(GetContactSalutation; Rec.GetContactSalutation())
                {
                    ApplicationArea = All;
                    Caption = 'Salutation';
                    ToolTip = 'Specifies a salutation. Use a code that makes it easy for you to remember the salutation, for example, M-JOB for "Male person with a job title".';
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

