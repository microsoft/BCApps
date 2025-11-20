// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5170 "Answer Where-Used"
{
    Caption = 'Answer Where-Used';
    DataCaptionFields = "Rating Profile Quest. Line No.";
    Editable = false;
    PageType = List;
    SourceTable = Rating;
    SourceTableView = sorting("Rating Profile Quest. Code", "Rating Profile Quest. Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Profile Questionnaire Code"; Rec."Profile Questionnaire Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the profile questionnaire that contains the question you use to create your rating.';
                }
                field("Profile Question Description"; Rec."Profile Question Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the description you have entered for this rating question in the Description field in the Profile Questionnaire Setup window.';
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
}

