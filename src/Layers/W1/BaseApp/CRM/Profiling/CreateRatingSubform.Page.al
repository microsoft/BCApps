// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5191 "Create Rating Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Profile Questionnaire Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("From Value"; Rec."From Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'From';
                    ToolTip = 'Specifies the value from which the automatic classification of your contacts starts.';
                }
                field("To Value"; Rec."To Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'To';
                    ToolTip = 'Specifies the value that the automatic classification of your contacts stops at.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Rec.Type = Rec.Type::Question;
        if Rec.Type <> Rec.Type::Question then
            DescriptionIndent := 1
        else
            DescriptionIndent := 0;
    end;

    var
        StyleIsStrong: Boolean;
        DescriptionIndent: Integer;

    procedure SetRecords(var ProfileLineQuestion: Record "Profile Questionnaire Line"; var ProfileLineAnswer: Record "Profile Questionnaire Line")
    begin
        Rec.DeleteAll();

        Rec := ProfileLineQuestion;
        Rec."Line No." := -1;
        Rec.Insert();

        if ProfileLineAnswer.Find('-') then
            repeat
                Rec := ProfileLineAnswer;
                Rec."Profile Questionnaire Code" := ProfileLineQuestion."Profile Questionnaire Code";
                Rec.Insert();
            until ProfileLineAnswer.Next() = 0;
    end;

    procedure UpdateForm()
    begin
        CurrPage.Update(false);
    end;
}

