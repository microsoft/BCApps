// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

codeunit 4162 "Business Skill Builder Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Initialize(OwnerAppId: Guid; SkillCode: Code[100]; DisplayName: Text[250]; Content: Text)
    begin
        VerifyNew();
        TempBusinessSkill."Owning App ID" := OwnerAppId;
        TempBusinessSkill."Skill ID" := SkillCode;
        TempBusinessSkill.TestField("Skill ID");
        TempBusinessSkill.TestField("Owning App ID");
        TempBusinessSkill."Read-Only" := true;
        TempBusinessSkill.Title := DisplayName;
        TextHelper.SetSkillText(TempBusinessSkill, Content);
        TempBusinessSkill.Status := TempBusinessSkill.Status::Inactive;
        Initialized := true;
    end;

    procedure SetContentLocked(ContentLocked: Boolean)
    begin
        VerifyReady();
        TempBusinessSkill."Read-Only" := ContentLocked;
    end;

    procedure SetContentVersion(ContentVersion: Text[50])
    begin
        VerifyReady();
        TempBusinessSkill.Version := ContentVersion;
        TempBusinessSkill.TestField(Version);
    end;

    procedure SetDisplayName(DisplayName: Text[250])
    begin
        VerifyReady();
        TempBusinessSkill.Title := DisplayName;
    end;

    procedure SetDescription(Description: Text[2048])
    begin
        VerifyReady();
        TempBusinessSkill.Description := Description;
    end;

    procedure SetContent(Content: Text)
    begin
        VerifyReady();
        TextHelper.SetSkillText(TempBusinessSkill, Content);
    end;

    procedure SetActive(Active: Boolean)
    begin
        VerifyReady();
        if Active then
            TempBusinessSkill.Status := TempBusinessSkill.Status::Active
        else
            TempBusinessSkill.Status := TempBusinessSkill.Status::Inactive;
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Create(): BigInteger
    var
        Skill: Record "Business Skill";
        SkillText: Text;
    begin
        VerifyReady();
        SkillManagement.ValidateSkillInsert(TempBusinessSkill);
        SkillText := TextHelper.GetSkillText(TempBusinessSkill, false);
        Skill."Skill ID" := TempBusinessSkill."Skill ID";
        Skill.Manual := false;
        Skill."Read-Only" := TempBusinessSkill."Read-Only";
        Skill.Version := TempBusinessSkill.Version;
        Skill.Title := TempBusinessSkill.Title;
        Skill.Description := TempBusinessSkill.Description;
        Skill.Status := TempBusinessSkill.Status;
        TextHelper.SetSkillText(Skill, SkillText);
        Skill.Insert(true);
        SkillManagement.RecordTextVersion(Skill.ID, SkillText, Skill.Version);
        Created := true;
        exit(Skill.ID);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure CreateOrUpdate(): BigInteger
    var
        Skill: Record "Business Skill";
        SkillText: Text;
        TextChanged: Boolean;
    begin
        VerifyReady();
        Skill.SetRange("Owning App ID", TempBusinessSkill."Owning App ID");
        Skill.SetRange("Skill ID", TempBusinessSkill."Skill ID");
        if not Skill.FindFirst() then
            exit(Create());

        SkillText := TextHelper.GetSkillText(TempBusinessSkill, false);
        TextChanged := TextHelper.GetSkillText(Skill) <> SkillText;
        if not TextChanged and (Skill.Title = TempBusinessSkill.Title) and (Skill.Description = TempBusinessSkill.Description) and
           (Skill.Status = TempBusinessSkill.Status) and (Skill."Read-Only" = TempBusinessSkill."Read-Only")
        then begin
            Created := true;
            exit(Skill.ID);
        end;
        if TextChanged then begin
            VerifyVersion();
            Skill.Version := TempBusinessSkill.Version;
            SkillManagement.ValidateSkillTextChange(Skill, SkillText);
            TextHelper.SetSkillText(Skill, SkillText);
        end;
        Skill.Title := TempBusinessSkill.Title;
        Skill.Description := TempBusinessSkill.Description;
        Skill.Status := TempBusinessSkill.Status;
        Skill."Read-Only" := TempBusinessSkill."Read-Only";
        SkillManagement.ValidateSkillModify(Skill);
        Skill.Modify(true);
        if TextChanged then
            SkillManagement.RecordTextVersion(Skill.ID, SkillText, Skill.Version);
        Created := true;
        exit(Skill.ID);
    end;

    local procedure VerifyNew()
    begin
        if Initialized then
            Error(OneShotErr);
    end;

    local procedure VerifyReady()
    begin
        if not Initialized then
            Error(NotInitializedErr);
        if Created then
            Error(OneShotErr);
    end;

    local procedure VerifyVersion()
    begin
        if TempBusinessSkill.Version = '' then
            Error(VersionRequiredErr);
    end;

    var
        TempBusinessSkill: Record "Business Skill" temporary;
        SkillManagement: Codeunit "Business Skill Management";
        TextHelper: Codeunit "Business Skill Text";
        Initialized: Boolean;
        Created: Boolean;
        NotInitializedErr: Label 'Initialize the business skill builder before using it.';
        OneShotErr: Label 'A business skill builder instance can create only one skill. Clear the variable before creating another skill.';
        VersionRequiredErr: Label 'Set a new version of the skill before changing its instructions.';
}
