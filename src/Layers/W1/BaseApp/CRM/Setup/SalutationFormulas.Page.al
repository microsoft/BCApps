// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

page 5152 "Salutation Formulas"
{
    Caption = 'Salutation Formulas';
    DataCaptionFields = "Salutation Code";
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
                field(Salutation; Rec.Salutation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the salutation itself.';
                }
                field("Name 1"; Rec."Name 1")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 3"; Rec."Name 3")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 4"; Rec."Name 4")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation. The options are: Job Title, First Name, Middle Name, Surname, Initials and Company Name.';
                }
                field("Name 5"; Rec."Name 5")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a salutation.';
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

