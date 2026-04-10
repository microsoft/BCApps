// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;

codeunit 5059 ProfileManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'General';
        Text001: Label 'No profile questionnaire is created for this contact.';
#pragma warning restore AA0074
        TempProfileQuestionnaireHeader: Record "Profile Questionnaire Header" temporary;

    local procedure FindLegalProfileQuestionnaire(Cont: Record Contact)
    var
        ContBusRel: Record "Contact Business Relation";
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
        ContProfileAnswer: Record "Contact Profile Answer";
        Valid: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLegalProfileQuestionnaire(TempProfileQuestionnaireHeader, Cont, IsHandled);
        if IsHandled then
            exit;

        TempProfileQuestionnaireHeader.DeleteAll();

        ProfileQuestnHeader.Reset();
        if ProfileQuestnHeader.Find('-') then
            repeat
                OnFindLegalProfileQuestionnaireOnBeforeLoopProfileQuestnHeader(ProfileQuestnHeader, Cont);
                Valid := true;
                if (ProfileQuestnHeader."Contact Type" = ProfileQuestnHeader."Contact Type"::Companies) and
                   (Cont.Type <> Cont.Type::Company)
                then
                    Valid := false;
                if (ProfileQuestnHeader."Contact Type" = ProfileQuestnHeader."Contact Type"::People) and
                   (Cont.Type <> Cont.Type::Person)
                then
                    Valid := false;
                if Valid and (ProfileQuestnHeader."Business Relation Code" <> '') then
                    if not ContBusRel.Get(Cont."Company No.", ProfileQuestnHeader."Business Relation Code") then
                        Valid := false;
                if not Valid then begin
                    ContProfileAnswer.Reset();
                    ContProfileAnswer.SetRange("Contact No.", Cont."No.");
                    ContProfileAnswer.SetRange("Profile Questionnaire Code", ProfileQuestnHeader.Code);
                    if ContProfileAnswer.FindFirst() then
                        Valid := true;
                end;
                if Valid then begin
                    TempProfileQuestionnaireHeader := ProfileQuestnHeader;
                    TempProfileQuestionnaireHeader.Insert();
                end;
            until ProfileQuestnHeader.Next() = 0;
    end;

    procedure GetQuestionnaire(): Code[20]
    var
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
    begin
        if ProfileQuestnHeader.FindFirst() then
            exit(ProfileQuestnHeader.Code);

        ProfileQuestnHeader.Init();
        ProfileQuestnHeader.Code := Text000;
        ProfileQuestnHeader.Description := Text000;
        ProfileQuestnHeader.Insert();
        exit(ProfileQuestnHeader.Code);
    end;

    procedure ProfileQuestionnaireAllowed(Cont: Record Contact; ProfileQuestnHeaderCode: Code[20]): Code[20]
    begin
        FindLegalProfileQuestionnaire(Cont);

        if TempProfileQuestionnaireHeader.Get(ProfileQuestnHeaderCode) then
            exit(ProfileQuestnHeaderCode);
        if TempProfileQuestionnaireHeader.FindFirst() then
            exit(TempProfileQuestionnaireHeader.Code);

        Error(Text001);
    end;

    procedure ShowContactQuestionnaireCard(Cont: Record Contact; ProfileQuestnLineCode: Code[20]; ProfileQuestnLineLineNo: Integer)
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ContProfileAnswers: Page "Contact Profile Answers";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowContactQuestionnaireCard(Cont, ProfileQuestnLineCode, ProfileQuestnLineLineNo, IsHandled);
        if IsHandled then
            exit;

        Cont.CheckIfMinorForProfiles();
        ContProfileAnswers.SetParameters(Cont, ProfileQuestionnaireAllowed(Cont, ''), ProfileQuestnLineCode, ProfileQuestnLineLineNo);
        if TempProfileQuestionnaireHeader.Get(ProfileQuestnLineCode) then begin
            ProfileQuestnLine.Get(ProfileQuestnLineCode, ProfileQuestnLineLineNo);
            ContProfileAnswers.SetRecord(ProfileQuestnLine);
        end;
        ContProfileAnswers.RunModal();
    end;

    procedure CheckName(CurrentQuestionsChecklistCode: Code[20]; var Cont: Record Contact)
    begin
        FindLegalProfileQuestionnaire(Cont);
        TempProfileQuestionnaireHeader.Get(CurrentQuestionsChecklistCode);
    end;

    procedure SetName(ProfileQuestnHeaderCode: Code[20]; var ProfileQuestnLine: Record "Profile Questionnaire Line"; ContactProfileAnswerLine: Integer)
    begin
        ProfileQuestnLine.FilterGroup := 2;
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", ProfileQuestnHeaderCode);
        ProfileQuestnLine.FilterGroup := 0;
        if ContactProfileAnswerLine = 0 then
            if ProfileQuestnLine.Find('-') then;
    end;

    procedure LookupName(var ProfileQuestnHeaderCode: Code[20]; var ProfileQuestnLine: Record "Profile Questionnaire Line"; var Cont: Record Contact)
    begin
        Commit();
        FindLegalProfileQuestionnaire(Cont);
        if TempProfileQuestionnaireHeader.Get(ProfileQuestnHeaderCode) then;
        if PAGE.RunModal(
             PAGE::"Profile Questionnaire List", TempProfileQuestionnaireHeader) = ACTION::LookupOK
        then
            ProfileQuestnHeaderCode := TempProfileQuestionnaireHeader.Code;

        SetName(ProfileQuestnHeaderCode, ProfileQuestnLine, 0);
    end;

    procedure ShowAnswerPoints(CurrProfileQuestnLine: Record "Profile Questionnaire Line")
    begin
        CurrProfileQuestnLine.SetRange("Profile Questionnaire Code", CurrProfileQuestnLine."Profile Questionnaire Code");
        PAGE.RunModal(PAGE::"Answer Points", CurrProfileQuestnLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLegalProfileQuestionnaire(var TempProfileQuestionnaireHeader: Record "Profile Questionnaire Header" temporary; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowContactQuestionnaireCard(Contact: Record Contact; ProfileQuestnLineCode: Code[20]; ProfileQuestnLineLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindLegalProfileQuestionnaireOnBeforeLoopProfileQuestnHeader(ProfileQuestnHeader: Record "Profile Questionnaire Header"; Contact: Record Contact)
    begin
    end;
}

