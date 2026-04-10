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
                }
                field("Salutation Type"; Rec."Salutation Type")
                {
                    ApplicationArea = All;
                }
                field(Salutation; Rec.Salutation)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Name 1"; Rec."Name 1")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Name 3"; Rec."Name 3")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Name 4"; Rec."Name 4")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Name 5"; Rec."Name 5")
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

