// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

page 5153 Salutations
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Salutations';
    PageType = List;
    SourceTable = Salutation;
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
                    ToolTip = 'Specifies the salutation code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the salutation.';
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
            group("&Salutation")
            {
                Caption = '&Salutation';
                Image = SalutationFormula;
                action(Formulas)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Formulas';
                    Image = SalutationFormula;
                    RunObject = Page "Salutation Formulas";
                    RunPageLink = "Salutation Code" = field(Code);
                    ToolTip = 'View or edit formal and an informal salutations for each language you want to use when interacting with your contacts.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Formulas_Promoted; Formulas)
                {
                }
            }
        }
    }
}

