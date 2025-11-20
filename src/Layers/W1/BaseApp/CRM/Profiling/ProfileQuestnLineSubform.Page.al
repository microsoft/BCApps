// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5169 "Profile Questn. Line Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Set; Set)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Select';
                    ToolTip = 'Specifies that the profile question will be included.';

                    trigger OnValidate()
                    begin
                        Rec.TestField(Type, Rec.Type::Answer);

                        if Set then begin
                            TempProfileQuestionnaireLine.Init();
                            TempProfileQuestionnaireLine.Validate("Profile Questionnaire Code", Rec."Profile Questionnaire Code");
                            TempProfileQuestionnaireLine.Validate("Line No.", Rec."Line No.");
                            TempProfileQuestionnaireLine.Insert();
                        end else begin
                            TempProfileQuestionnaireLine.Get(Rec."Profile Questionnaire Code", Rec."Line No.");
                            TempProfileQuestionnaireLine.Delete();
                        end;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Set := TempProfileQuestionnaireLine.Get(Rec."Profile Questionnaire Code", Rec."Line No.");
        StyleIsStrong := Rec.Type = Rec.Type::Question;
    end;

    var
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
        Set: Boolean;
        StyleIsStrong: Boolean;

    procedure SetProfileQnLine(var FromProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        ClearSettings();
        if FromProfileQuestionnaireLine.Find('-') then
            repeat
                TempProfileQuestionnaireLine := FromProfileQuestionnaireLine;
                TempProfileQuestionnaireLine.Insert();
            until FromProfileQuestionnaireLine.Next() = 0;
    end;

    local procedure ClearSettings()
    begin
        if TempProfileQuestionnaireLine.FindFirst() then
            TempProfileQuestionnaireLine.DeleteAll();
    end;
}

