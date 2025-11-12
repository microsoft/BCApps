// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using Microsoft.CRM.Contact;

page 5114 "Contact Profile Answers"
{
    AutoSplitKey = true;
    Caption = 'Contact Profile Answers';
    DataCaptionExpression = CaptionStr;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            field(CurrentQuestionsChecklistCode; CurrentQuestionsChecklistCode)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Profile Questionnaire Code';
                ToolTip = 'Specifies the profile questionnaire.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    ProfileManagement.LookupName(CurrentQuestionsChecklistCode, Rec, Cont);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ProfileManagement.CheckName(CurrentQuestionsChecklistCode, Cont);
                    CurrentQuestionsChecklistCodeO();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies whether the entry is a question or an answer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of contacts that have given this answer.';
                    Visible = false;
                }
                field(Set; Set)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Set';
                    ToolTip = 'Specifies the answer to the question.';
                    Editable = (Rec.Type = Rec.Type::Answer);

                    trigger OnValidate()
                    begin
                        UpdateProfileAnswer();
                    end;
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

    trigger OnAfterGetRecord()
    begin
        Set := ContProfileAnswer.Get(Cont."No.", Rec."Profile Questionnaire Code", Rec."Line No.");

        StyleIsStrong := Rec.Type = Rec.Type::Question;
        if Rec.Type <> Rec.Type::Question then
            DescriptionIndent := 1
        else
            DescriptionIndent := 0;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ProfileQuestionnaireLine2.Copy(Rec);

        if not ProfileQuestionnaireLine2.Find(Which) then
            exit(false);

        ProfileQuestLineQuestion := ProfileQuestionnaireLine2;
        if ProfileQuestionnaireLine2.Type = Rec.Type::Answer then
            ProfileQuestLineQuestion.Get(ProfileQuestionnaireLine2."Profile Questionnaire Code", ProfileQuestLineQuestion.FindQuestionLine());

        OK := true;
        if ProfileQuestLineQuestion."Auto Contact Classification" then begin
            OK := false;
            repeat
                if Which = '+' then
                    GoNext := ProfileQuestionnaireLine2.Next(-1) <> 0
                else
                    GoNext := ProfileQuestionnaireLine2.Next(1) <> 0;
                if GoNext then begin
                    ProfileQuestLineQuestion := ProfileQuestionnaireLine2;
                    if ProfileQuestionnaireLine2.Type = Rec.Type::Answer then
                        ProfileQuestLineQuestion.Get(
                          ProfileQuestionnaireLine2."Profile Questionnaire Code", ProfileQuestLineQuestion.FindQuestionLine());
                    OK := not ProfileQuestLineQuestion."Auto Contact Classification";
                end;
            until (not GoNext) or OK;
        end;

        if not OK then
            exit(false);

        Rec := ProfileQuestionnaireLine2;
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ActualSteps: Integer;
        Step: Integer;
        NoOneFound: Boolean;
    begin
        ProfileQuestionnaireLine2.Copy(Rec);

        if Steps > 0 then
            Step := 1
        else
            Step := -1;

        repeat
            if ProfileQuestionnaireLine2.Next(Step) <> 0 then begin
                if ProfileQuestionnaireLine2.Type = Rec.Type::Answer then
                    ProfileQuestLineQuestion.Get(
                      ProfileQuestionnaireLine2."Profile Questionnaire Code", ProfileQuestionnaireLine2.FindQuestionLine());
                if ((not ProfileQuestLineQuestion."Auto Contact Classification") and
                    (ProfileQuestionnaireLine2.Type = Rec.Type::Answer)) or
                   ((ProfileQuestionnaireLine2.Type = Rec.Type::Question) and (not ProfileQuestionnaireLine2."Auto Contact Classification"))
                then begin
                    ActualSteps := ActualSteps + Step;
                    if Steps <> 0 then
                        Rec := ProfileQuestionnaireLine2;
                end;
            end else
                NoOneFound := true
        until (ActualSteps = Steps) or NoOneFound;

        exit(ActualSteps);
    end;

    trigger OnOpenPage()
    begin
        if ContactProfileAnswerCode = '' then
            CurrentQuestionsChecklistCode :=
              ProfileManagement.ProfileQuestionnaireAllowed(Cont, CurrentQuestionsChecklistCode)
        else
            CurrentQuestionsChecklistCode := ContactProfileAnswerCode;

        ProfileManagement.SetName(CurrentQuestionsChecklistCode, Rec, ContactProfileAnswerLine);

        if (Cont."Company No." <> '') and (Cont."No." <> Cont."Company No.") then begin
            CaptionStr := CopyStr(Cont."Company No." + ' ' + Cont."Company Name", 1, MaxStrLen(CaptionStr));
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        end else
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
    end;

    var
        ProfileQuestionnaireLine2: Record "Profile Questionnaire Line";
        ProfileQuestLineQuestion: Record "Profile Questionnaire Line";
        ProfileManagement: Codeunit ProfileManagement;
        GoNext: Boolean;
        OK: Boolean;
        CaptionStr: Text;
        RunFormCode: Boolean;
        StyleIsStrong: Boolean;
        DescriptionIndent: Integer;

    protected var
        Cont: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        CurrentQuestionsChecklistCode: Code[20];
        ContactProfileAnswerCode: Code[20];
        ContactProfileAnswerLine: Integer;
        Set: Boolean;

    procedure SetParameters(var SetCont: Record Contact; SetProfileQuestionnaireCode: Code[20]; SetContProfileAnswerCode: Code[20]; SetContProfileAnswerLine: Integer)
    begin
        Cont := SetCont;
        CurrentQuestionsChecklistCode := SetProfileQuestionnaireCode;
        ContactProfileAnswerCode := SetContProfileAnswerCode;
        ContactProfileAnswerLine := SetContProfileAnswerLine;
    end;

    procedure UpdateProfileAnswer()
    begin
        if not RunFormCode and Set then
            Rec.TestField(Type, Rec.Type::Answer);

        if Set then begin
            ContProfileAnswer.Init();
            ContProfileAnswer."Contact No." := Cont."No.";
            ContProfileAnswer."Contact Company No." := Cont."Company No.";
            ContProfileAnswer.Validate("Profile Questionnaire Code", CurrentQuestionsChecklistCode);
            ContProfileAnswer.Validate("Line No.", Rec."Line No.");
            ContProfileAnswer."Last Date Updated" := Today;
            ContProfileAnswer.Insert(true);
        end else
            if ContProfileAnswer.Get(Cont."No.", CurrentQuestionsChecklistCode, Rec."Line No.") then
                ContProfileAnswer.Delete(true);

        OnAfterUpdateProfileAnswer(Rec, xRec, Cont);
    end;

    procedure SetRunFromForm(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; ContactFrom: Record Contact; CurrQuestionsChecklistCodeFrom: Code[20])
    begin
        Set := true;
        RunFormCode := true;
        Cont := ContactFrom;
        CurrentQuestionsChecklistCode := CurrQuestionsChecklistCodeFrom;
        Rec := ProfileQuestionnaireLine;
    end;

    local procedure CurrentQuestionsChecklistCodeO()
    begin
        CurrPage.SaveRecord();
        ProfileManagement.SetName(CurrentQuestionsChecklistCode, Rec, 0);
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProfileAnswer(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; var xProfileQuestionnaireLine: Record "Profile Questionnaire Line"; Contact: Record Contact)
    begin
    end;
}

