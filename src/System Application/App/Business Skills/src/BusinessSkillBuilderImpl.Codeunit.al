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

    procedure Initialize(OwnerAppId: Guid; SkillCode: Code[100]; DisplayName: Text[250]; Content: SecretText)
    var
        TempNewSkill: Record "Business Skill" temporary;
    begin
        VerifyNew();
        TempNewSkill."Owning App ID" := OwnerAppId;
        TempNewSkill."Skill ID" := SkillCode;
        TempNewSkill."Read-Only" := true;
        TempNewSkill.Title := DisplayName;
        BusinessSkillImpl.SetContent(TempNewSkill, Content);
        TempNewSkill.Status := TempNewSkill.Status::Inactive;
        TempBusinessSkill := TempNewSkill;
        CallingAppId := OwnerAppId;
        Initialized := true;
    end;

    procedure SetManual(Manual: Boolean)
    begin
        VerifyReady();
        TempBusinessSkill.Manual := Manual;
        if Manual then
            Clear(TempBusinessSkill."Owning App ID")
        else
            TempBusinessSkill."Owning App ID" := CallingAppId;
        if not ContentLockedSpecified then
            TempBusinessSkill."Read-Only" := not Manual;
    end;

    procedure SetContentLocked(ContentLocked: Boolean)
    begin
        VerifyReady();
        TempBusinessSkill."Read-Only" := ContentLocked;
        ContentLockedSpecified := true;
    end;

    procedure SetContentVersion(ContentVersion: Text)
    begin
        VerifyReady();
        if ContentVersion = '' then
            Error(VersionRequiredErr);
        if StrLen(ContentVersion) > MaxStrLen(TempBusinessSkill.Version) then
            Error(ContentVersionTooLongErr, MaxStrLen(TempBusinessSkill.Version));
        TempBusinessSkill.Version := CopyStr(ContentVersion, 1, MaxStrLen(TempBusinessSkill.Version));
        ContentVersionSpecified := true;
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
        DescriptionSpecified := true;
    end;

    procedure SetContent(Content: SecretText)
    begin
        VerifyReady();
        BusinessSkillImpl.SetContent(TempBusinessSkill, Content);
    end;

    procedure SetActive(Active: Boolean)
    begin
        VerifyReady();
        if Active then
            TempBusinessSkill.Status := TempBusinessSkill.Status::Active
        else
            TempBusinessSkill.Status := TempBusinessSkill.Status::Inactive;
        ActiveSpecified := true;
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Create(): BigInteger
    var
        Skill: Record "Business Skill";
        SkillContent: SecretText;
    begin
        VerifyReady();
        VerifyOwnership();
        if TempBusinessSkill.Manual then
            TempBusinessSkill.TestField("Skill ID", '');
        BusinessSkillImpl.ValidateSkillInsert(TempBusinessSkill);
        SkillContent := BusinessSkillImpl.GetContentFromBuffer(TempBusinessSkill);
        Skill."Skill ID" := TempBusinessSkill."Skill ID";
        Skill.Manual := TempBusinessSkill.Manual;
        Skill."Read-Only" := TempBusinessSkill."Read-Only";
        Skill.Version := TempBusinessSkill.Version;
        Skill.Title := TempBusinessSkill.Title;
        Skill.Description := TempBusinessSkill.Description;
        Skill.Status := TempBusinessSkill.Status;
        BusinessSkillImpl.SetContent(Skill, SkillContent);
        Skill.Insert(true);
        BusinessSkillContentHistory.RecordContentVersion(Skill.ID, SkillContent, Skill.Version);
        Created := true;
        exit(Skill.ID);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CreateOrUpdate(): BigInteger
    var
        Skill: Record "Business Skill";
    begin
        VerifyReady();
        VerifyOwnership();
        if TempBusinessSkill.Manual and (TempBusinessSkill."Skill ID" = '') then
            exit(Create());
        TempBusinessSkill.TestField("Skill ID");
        Skill.SetRange("Owning App ID", TempBusinessSkill."Owning App ID");
        Skill.SetRange("Skill ID", TempBusinessSkill."Skill ID");
        if not Skill.FindFirst() then begin
            if TempBusinessSkill.Manual then
                Error(ManualSkillNotFoundErr);
            exit(Create());
        end;
        exit(Update(Skill));
    end;

    /// <summary>
    /// Creates a new skill for zero, or updates the existing nonzero ID without changing its identity.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CreateOrUpdate(SkillId: BigInteger): BigInteger
    var
        Skill: Record "Business Skill";
    begin
        if SkillId = 0 then
            exit(Create());
        VerifyReady();
        VerifyOwnership();
        Skill.Get(SkillId);
        if (Skill."Owning App ID" <> TempBusinessSkill."Owning App ID") or
           ((TempBusinessSkill."Skill ID" <> '') and (Skill."Skill ID" <> TempBusinessSkill."Skill ID"))
        then
            Error(SkillIdentityMismatchErr);
        exit(Update(Skill));
    end;

    local procedure Update(var Skill: Record "Business Skill"): BigInteger
    var
        SkillContent: SecretText;
        ContentChanged: Boolean;
        VersionChanged: Boolean;
        Changed: Boolean;
    begin
        if Skill.Manual <> TempBusinessSkill.Manual then
            Error(SkillIdentityMismatchErr);
        SkillContent := BusinessSkillImpl.GetContentFromBuffer(TempBusinessSkill);
        ContentChanged := not BusinessSkillImpl.ContentEquals(BusinessSkillImpl.GetContent(Skill), SkillContent);
        VersionChanged := ContentVersionSpecified and (Skill.Version <> TempBusinessSkill.Version);
        Changed := ContentChanged or VersionChanged or (Skill.Title <> TempBusinessSkill.Title) or
            (DescriptionSpecified and (Skill.Description <> TempBusinessSkill.Description)) or
            (ActiveSpecified and (Skill.Status <> TempBusinessSkill.Status)) or
            (ContentLockedSpecified and (Skill."Read-Only" <> TempBusinessSkill."Read-Only"));
        if not Changed then begin
            Created := true;
            exit(Skill.ID);
        end;
        if ContentVersionSpecified then
            Skill.Version := TempBusinessSkill.Version;
        if ContentChanged then begin
            if not Skill.Manual and not ContentVersionSpecified then
                Error(VersionRequiredErr);
            BusinessSkillImpl.SetContent(Skill, SkillContent);
            if Skill.Manual and VersionChanged then
                Skill.Version := TempBusinessSkill.Version;
        end;
        Skill.Title := TempBusinessSkill.Title;
        if DescriptionSpecified then
            Skill.Description := TempBusinessSkill.Description;
        if ActiveSpecified then
            Skill.Status := TempBusinessSkill.Status;
        if ContentLockedSpecified then
            Skill."Read-Only" := TempBusinessSkill."Read-Only";
        BusinessSkillImpl.ValidateSkillModify(Skill);
        Skill.Modify(true);
        if ContentChanged then
            BusinessSkillContentHistory.RecordContentVersion(Skill.ID, SkillContent, Skill.Version);
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

    local procedure VerifyOwnership()
    begin
        if not TempBusinessSkill.Manual then
            TempBusinessSkill.TestField("Owning App ID");
    end;

    var
        TempBusinessSkill: Record "Business Skill" temporary;
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        BusinessSkillContentHistory: Codeunit "Business Skill Content History";
        CallingAppId: Guid;
        Initialized: Boolean;
        Created: Boolean;
        ContentLockedSpecified: Boolean;
        ContentVersionSpecified: Boolean;
        DescriptionSpecified: Boolean;
        ActiveSpecified: Boolean;
        NotInitializedErr: Label 'Initialize the business skill builder before using it.';
        OneShotErr: Label 'A business skill builder instance can create only one skill. Clear the variable before creating another skill.';
        VersionRequiredErr: Label 'Set a new version of the skill before changing its instructions.';
        ContentVersionTooLongErr: Label 'The content version cannot exceed %1 characters.', Comment = '%1 = maximum content version length';
        ManualSkillNotFoundErr: Label 'The manual skill was not found. Use an empty skill code to create a new manual skill.';
        SkillIdentityMismatchErr: Label 'The selected skill does not match the builder''s skill code and ownership.';
}
