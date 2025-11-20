// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5109 "Profile Questionnaires"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Questionnaire Setup';
    PageType = List;
    SourceTable = "Profile Questionnaire Header";
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
                    ToolTip = 'Specifies the code of the profile questionnaire.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the profile questionnaire.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority you give to the profile questionnaire and where it should be displayed on the lines of the Contact Card. There are five options:';
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of contact you want to use this profile questionnaire for.';
                }
                field("Business Relation Code"; Rec."Business Relation Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the business relation to which the profile questionnaire applies.';
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
            action("Edit Questionnaire Setup")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Edit Questionnaire Setup';
                Ellipsis = true;
                Image = Setup;
                RunObject = Page "Profile Questionnaire Setup";
                RunPageLink = "Profile Questionnaire Code" = field(Code);
                ShortCutKey = 'Return';
                ToolTip = 'Modify how the questionnaire is set up.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Questionnaire Setup_Promoted"; "Edit Questionnaire Setup")
                {
                }
            }
        }
    }
}

