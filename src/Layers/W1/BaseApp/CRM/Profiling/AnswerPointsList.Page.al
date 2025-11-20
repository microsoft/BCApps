// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5173 "Answer Points List"
{
    Caption = 'Answer Points List';
    DataCaptionFields = "Profile Questionnaire Line No.";
    Editable = false;
    PageType = List;
    SourceTable = Rating;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Rating Profile Quest. Code"; Rec."Rating Profile Quest. Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the profile questionnaire that contains the answer you use to create your rating.';
                }
                field("ProfileQuestionnaireLine.Question"; ProfileQuestionnaireLine.Question())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Question';
                    ToolTip = 'Specifies the question in the profile questionnaire.';
                }
                field("ProfileQuestionnaireLine.Description"; ProfileQuestionnaireLine.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Answer';
                    Editable = false;
                    ToolTip = 'Specifies answers to the questions in the profile questionnaire.';
                }
                field(Points; Rec.Points)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of points you have assigned to this answer.';
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

    trigger OnAfterGetCurrRecord()
    begin
        if not ProfileQuestionnaireLine.Get(Rec."Rating Profile Quest. Code", Rec."Rating Profile Quest. Line No.") then
            Clear(ProfileQuestionnaireLine);
    end;

    trigger OnAfterGetRecord()
    begin
        if ProfileQuestionnaireLine.Get(Rec."Rating Profile Quest. Code", Rec."Rating Profile Quest. Line No.") then;
    end;

    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
}

