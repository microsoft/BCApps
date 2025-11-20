// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5149 "Profile Questn. Line List"
{
    AutoSplitKey = true;
    Caption = 'Profile Questn. Line List';
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the profile questionnaire line. This field is used internally by the program.';
                }
                field(Question; Rec.Question())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Question';
                    ToolTip = 'Specifies the question in the profile questionnaire.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Answer';
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("From Value"; Rec."From Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value from which the automatic classification of your contacts starts.';
                    Visible = false;
                }
                field("To Value"; Rec."To Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value that the automatic classification of your contacts stops at.';
                    Visible = false;
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of contacts that have given this answer.';
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

