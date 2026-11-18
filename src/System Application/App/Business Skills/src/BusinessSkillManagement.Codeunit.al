// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Agents;
using System.Environment;

/// <summary>
/// Governs skill creation, content updates, lifecycle and discovery.
/// Preserves text history and optimistic concurrency while sharing eligibility rules across native and API callers.
/// </summary>
/// <remarks>
/// The platform table "Business Skill" stamps ownership, assigns manual skill identifiers and protects identity.
/// AL supplies app-owned identifiers and governs status, content, versions, history and deletion.
/// </remarks>
codeunit 4163 "Business Skill Management"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SkillExists(SkillId: BigInteger): Boolean
    var
        Skill: Record "Business Skill";
    begin
        exit(Skill.Get(SkillId));
    end;

    /// <summary>
    /// Validates a skill before insertion. App-owned skills require an identifier; an omitted version defaults to v1.0.
    /// </summary>
    procedure ValidateSkillInsert(var Skill: Record "Business Skill")
    begin
        if not Skill.Manual then
            Skill.TestField("Skill ID");
        PreventReadOnlyManualSkill(Skill);
        if Skill.Version = '' then
            Skill.Version := InitialVersionTok;
        ValidateContent(Skill, false, ActiveContentRequiredErr);
    end;

    /// <summary>Validates a skill before it is modified.</summary>
    procedure ValidateSkillModify(var Skill: Record "Business Skill")
    var
        StoredSkill: Record "Business Skill";
    begin
        StoredSkill.Get(Skill.ID);
        if ((Skill."Skill ID" <> StoredSkill."Skill ID") or (Skill."Owning App ID" <> StoredSkill."Owning App ID") or
           (Skill."Owning App Publisher" <> StoredSkill."Owning App Publisher")
           or (Skill.Manual <> StoredSkill.Manual))
        then
            Error(SkillIdentityImmutableErr);
        if StoredSkill."Read-Only" then
            if not Skill."Read-Only" or (Skill.Version <> StoredSkill.Version) then
                Error(ReadOnlyErr);
        Skill.TestField(Version);
        if (Skill.Version <> StoredSkill.Version) and not IsManualSkill(Skill) then
            if TextHelper.ContentEquals(TextHelper.GetSkillText(Skill, false), TextHelper.GetSkillText(StoredSkill)) then
                Error(ProgrammaticVersionRequiresTextErr);
        PreventReadOnlyManualSkill(Skill);
        ValidateContent(Skill, false, ActiveContentRequiredErr);
    end;

    procedure IsManualSkill(Skill: Record "Business Skill"): Boolean
    begin
        exit(Skill.Manual);
    end;

    /// <summary>Returns whether the native manual editor can change the skill's instructions and version.</summary>
    procedure CanEditSkillText(Skill: Record "Business Skill"): Boolean
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        exit(Skill.Manual and not Skill."Read-Only" and AgentUtilities.CanCurrentUserManageBusinessSkills());
    end;

    procedure ValidateManualVersionChange(Skill: Record "Business Skill")
    begin
        if not IsManualSkill(Skill) then
            Error(ManualVersionOnlyErr);
        Skill.TestField(Version);
    end;

    local procedure PreventReadOnlyManualSkill(Skill: Record "Business Skill")
    begin
        if IsManualSkill(Skill) and Skill."Read-Only" then
            Error(ManualReadOnlyErr);
    end;

    /// <summary>
    /// Applies the version rules to a text change of a saved skill. A manual skill advances its version; a skill owned by an app
    /// must already carry a new version supplied by the app.
    /// </summary>
    procedure ValidateSkillTextChange(var Skill: Record "Business Skill"; NewText: SecretText)
    var
        StoredSkill: Record "Business Skill";
    begin
        if Skill.IsTemporary() or (Skill.ID = 0) then
            exit;
        StoredSkill.Get(Skill.ID);
        if TextHelper.ContentEquals(TextHelper.GetSkillText(StoredSkill), NewText) then begin
            if IsManualSkill(StoredSkill) then
                Skill.Version := StoredSkill.Version;
            exit;
        end;
        if StoredSkill."Read-Only" then
            Error(ReadOnlyErr);
        if IsManualSkill(StoredSkill) then begin
            Skill.Version := GetNextVersion(StoredSkill.Version);
            exit;
        end;
        if (Skill.Version = '') or (Skill.Version = StoredSkill.Version) then
            Error(ProgrammaticVersionRequiredErr);
    end;

    local procedure GetNextVersion(CurrentVersion: Text[50]): Text[50]
    var
        NextVersion: Text;
    begin
        NextVersion := IncStr(CurrentVersion);
        if (NextVersion <> '') and (NextVersion <> CurrentVersion) and (StrLen(NextVersion) <= MaxStrLen(CurrentVersion)) then
            exit(CopyStr(NextVersion, 1, MaxStrLen(CurrentVersion)));
        exit(CopyStr(CurrentVersion, 1, MaxStrLen(CurrentVersion) - StrLen(VersionSuffixTok)) + VersionSuffixTok);
    end;

    procedure GetAppName(AppId: Guid): Text
    var
        AppModule: ModuleInfo;
    begin
        if IsNullGuid(AppId) then
            exit(CreatedManuallyLbl);
        if NavApp.GetModuleInfo(AppId, AppModule) then
            exit(AppModule.Name);
        exit(StrSubstNo(UnavailableAppLbl, AppId));
    end;

    procedure GetAppPublisher(AppId: Guid): Text
    var
        AppModule: ModuleInfo;
    begin
        if IsNullGuid(AppId) then
            exit('');
        if NavApp.GetModuleInfo(AppId, AppModule) then
            exit(AppModule.Publisher);
        exit(UnavailablePublisherLbl);
    end;

    /// <summary>
    /// Creates an inactive manual copy of a skill with the current text of the source skill. The copy gets a new skill ID
    /// from the platform and starts its own text history at v1.0.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CopySkill(SkillId: BigInteger): BigInteger
    var
        SourceSkill: Record "Business Skill";
        LatestVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        SkillText: SecretText;
    begin
        SourceSkill.Get(SkillId);
        LatestVersion.SetCurrentKey("Skill ID", "Entry No.");
        LatestVersion.SetRange("Skill ID", SkillId);
        if LatestVersion.FindLast() then
            SkillText := LatestVersion.GetText()
        else
            SkillText := TextHelper.GetSkillText(SourceSkill);
        exit(Builder.Initialize('', SourceSkill.Title, SkillText).SetManual(true).SetDescription(SourceSkill.Description).Create());
    end;

    procedure UpdateSkillRecord(SkillId: BigInteger; var SourceSkill: Record "Business Skill"; SkillText: SecretText): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        VerifySkillRevision(BusinessSkill, SourceSkill.SystemId, SourceSkill.SystemRowVersion);
        exit(UpdateSkill(BusinessSkill, SourceSkill.Title, SourceSkill.Description, SkillText, SourceSkill.Version));
    end;

    procedure UpdateSkill(SkillId: BigInteger; Title: Text[250]; SkillText: SecretText): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        exit(UpdateSkill(BusinessSkill, Title, SkillText));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; SkillText: SecretText): Boolean
    begin
        exit(UpdateSkill(BusinessSkill, Title, BusinessSkill.Description, SkillText));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; Description: Text[2048]; SkillText: SecretText): Boolean
    begin
        exit(UpdateSkill(BusinessSkill, Title, Description, SkillText, BusinessSkill.Version));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; Description: Text[2048]; SkillText: SecretText; SkillVersion: Text[50]): Boolean
    var
        TextChanged: Boolean;
        VersionChanged: Boolean;
    begin
        TextChanged := not TextHelper.ContentEquals(TextHelper.GetSkillText(BusinessSkill), SkillText);
        VersionChanged := BusinessSkill.Version <> SkillVersion;
        if (BusinessSkill.Title = Title) and (BusinessSkill.Description = Description) and not TextChanged and not VersionChanged then
            exit(true);
        if VersionChanged then begin
            BusinessSkill.Version := SkillVersion;
            ValidateManualVersionChange(BusinessSkill);
        end;
        BusinessSkill.Title := Title;
        BusinessSkill.Description := Description;
        if TextChanged then
            TextHelper.SetSkillText(BusinessSkill, SkillText);
        if VersionChanged then
            BusinessSkill.Version := SkillVersion;
        ValidateSkillModify(BusinessSkill);
        BusinessSkill.Modify(true);
        if TextChanged then
            RecordTextVersion(BusinessSkill.ID, SkillText, BusinessSkill.Version);
        exit(true);
    end;

    procedure ActivateSkill(SkillId: BigInteger): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.Status := BusinessSkill.Status::Active;
        ValidateContent(BusinessSkill, true, ActivationContentRequiredErr);
        BusinessSkill.Modify(true);
        exit(true);
    end;

    procedure DeactivateSkill(SkillId: BigInteger): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.Status := BusinessSkill.Status::Inactive;
        BusinessSkill.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Deletes an inactive skill. The platform does not check deletes, so the delete rules are enforced here.
    /// The text history of the skill is removed when the platform reports the delete.
    /// </summary>
    procedure DeleteSkill(SkillId: BigInteger)
    var
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        DeleteSkill(SkillId, CallerModule.Id);
    end;

    /// <summary>Deletes an inactive skill for the caller captured by an internal entry point or public facade.</summary>
    procedure DeleteSkill(SkillId: BigInteger; CallerAppId: Guid)
    var
        BusinessSkill: Record "Business Skill";
        DeleteError: Text;
    begin
        BusinessSkill.Get(SkillId);
        if BusinessSkill.Status = BusinessSkill.Status::Active then
            Error(DeleteActiveSkillErr);
        if not CanDeleteSkill(BusinessSkill, CallerAppId, DeleteError) then
            Error(DeleteError);
        BusinessSkill.Delete(true);
    end;

    /// <summary>
    /// Returns whether the calling app and the current user may delete the skill. A skill of an installed app can be deleted only
    /// by that app; a manual skill, or a skill whose app is no longer installed, needs the permission to manage business skills.
    /// </summary>
    procedure CanDeleteSkill(Skill: Record "Business Skill"): Boolean
    var
        CallerModule: ModuleInfo;
        DeleteError: Text;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        exit(CanDeleteSkill(Skill, CallerModule.Id, DeleteError));
    end;

    /// <summary>Returns whether deletion is permitted and, if not, the reason it is blocked.</summary>
    procedure CanDeleteSkill(Skill: Record "Business Skill"; var DeleteError: Text): Boolean
    var
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        exit(CanDeleteSkill(Skill, CallerModule.Id, DeleteError));
    end;

    local procedure CanDeleteSkill(Skill: Record "Business Skill"; CallerAppId: Guid; var DeleteError: Text): Boolean
    var
        AgentUtilities: Codeunit "Agent Utilities";
        OwningModule: ModuleInfo;
    begin
        Clear(DeleteError);
        if not IsManualSkill(Skill) then
            if NavApp.GetModuleInfo(Skill."Owning App ID", OwningModule) then begin
                if CallerAppId = Skill."Owning App ID" then
                    exit(true);
                DeleteError := StrSubstNo(DeleteInstalledOwnerErr, OwningModule.Name);
                exit(false);
            end;
        if AgentUtilities.CanCurrentUserManageBusinessSkills() then
            exit(true);
        DeleteError := DeleteNotAllowedErr;
        exit(false);
    end;

    procedure SetSkillText(SkillId: BigInteger; SkillText: SecretText)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        UpdateSkill(BusinessSkill, BusinessSkill.Title, SkillText);
    end;

    procedure SetSkillText(SkillId: BigInteger; SkillText: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.TestField(Manual, true);
        VerifySkillRevision(BusinessSkill, ExpectedSystemId, ExpectedRevision);
        UpdateSkill(BusinessSkill, BusinessSkill.Title, SkillText);
    end;

    /// <summary>Changes the text of a skill owned by an app together with the new version supplied by the app.</summary>
    procedure SetSkillText(SkillId: BigInteger; SkillText: SecretText; NewVersion: Text[50])
    var
        BusinessSkill: Record "Business Skill";
        TextChanged: Boolean;
    begin
        BusinessSkill.Get(SkillId);
        TextChanged := not TextHelper.ContentEquals(TextHelper.GetSkillText(BusinessSkill), SkillText);
        if not TextChanged and (BusinessSkill.Version = NewVersion) then
            exit;
        BusinessSkill.Version := NewVersion;
        if TextChanged then
            TextHelper.SetSkillText(BusinessSkill, SkillText);
        ValidateSkillModify(BusinessSkill);
        BusinessSkill.Modify(true);
        if TextChanged then
            RecordTextVersion(BusinessSkill.ID, SkillText, BusinessSkill.Version);
    end;

    /// <summary>Updates the skill selected by its calling app and code, including inactive skills.</summary>
    procedure SetNewContentAndUpdateVersion(CallerAppId: Guid; SkillCode: Code[100]; Content: SecretText; ContentVersion: Text[50])
    var
        Skill: Record "Business Skill";
    begin
        Skill.SetRange("Owning App ID", CallerAppId);
        Skill.SetRange("Skill ID", SkillCode);
        Skill.SetRange(Manual, false);
        if not Skill.FindFirst() then
            Error(AppSkillNotFoundErr);
        SetSkillText(Skill.ID, Content, ContentVersion);
    end;

    procedure RestoreTextVersion(EntryNo: Integer)
    var
        TextVersion: Record "Business Skill Text Version";
    begin
        TextVersion.Get(EntryNo);
        SetSkillText(TextVersion."Skill ID", TextVersion.GetText());
    end;

    procedure DeleteTextVersion(EntryNo: Integer)
    var
        TextVersion: Record "Business Skill Text Version";
    begin
        VerifyCanDeleteTextVersion(EntryNo);
        TextVersion.Get(EntryNo);
        TextVersion.Delete(true);
    end;

    procedure VerifyCanDeleteTextVersion(EntryNo: Integer)
    var
        TextVersion: Record "Business Skill Text Version";
        TextHistory: Codeunit "Business Skill Text History";
    begin
        TextVersion.Get(EntryNo);
        if TextHistory.IsLatestVersion(TextVersion) then
            Error(CannotDeleteLatestErr);
    end;

    /// <summary>Records the saved text of the skill as a new text version, unless it equals the latest version.</summary>
    procedure RecordTextVersion(var Skill: Record "Business Skill")
    begin
        if Skill.IsTemporary() then
            exit;
        RecordTextVersion(Skill.ID, TextHelper.GetSkillText(Skill), Skill.Version);
    end;

    /// <summary>Records the text as a new text version of the skill, unless it equals the latest version.</summary>
    procedure RecordTextVersion(SkillId: BigInteger; NewText: SecretText; SkillVersion: Text[50])
    var
        LatestVersion: Record "Business Skill Text Version";
        TextVersion: Record "Business Skill Text Version";
    begin
        LatestVersion.SetCurrentKey("Skill ID", "Entry No.");
        LatestVersion.SetRange("Skill ID", SkillId);
        if LatestVersion.FindLast() then
            if TextHelper.ContentEquals(LatestVersion.GetText(), NewText) then
                exit;
        TextVersion."Skill ID" := SkillId;
        TextVersion.Version := SkillVersion;
        TextVersion.SetText(NewText);
        TextVersion.Insert(true);
    end;

    /// <summary>Skills are not scoped to companies yet, so every existing skill applies to the current company.</summary>
    procedure IsSkillAvailableForCurrentCompany(SkillId: BigInteger): Boolean
    begin
        exit(SkillExists(SkillId));
    end;

    procedure SetAvailableSkillsFilter(var BusinessSkill: Record "Business Skill")
    begin
        BusinessSkill.SetRange(Status, BusinessSkill.Status::Active);
    end;

    procedure IsSkillAvailable(BusinessSkill: Record "Business Skill"): Boolean
    begin
        exit(BusinessSkill.Status = BusinessSkill.Status::Active);
    end;

    procedure GetAllActiveSkills(): SecretText
    begin
        exit(SearchSkills(''));
    end;

    procedure GetSkillById(SkillId: BigInteger): SecretText
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        if not IsSkillAvailable(BusinessSkill) then
            Error(SkillUnavailableErr, SkillId);
        exit(SkillToJsonObject(BusinessSkill));
    end;

    [NonDebuggable]
    procedure SearchSkills(SearchText: Text): SecretText
    var
        BusinessSkill: Record "Business Skill";
        Result: JsonArray;
        SkillJson: JsonObject;
        SerializedResult: Text;
    begin
        SetAvailableSkillsFilter(BusinessSkill);
        if BusinessSkill.FindSet() then
            repeat
                if IsSkillAvailable(BusinessSkill) then
                    if SkillMatchesSearch(BusinessSkill, LowerCase(SearchText)) then begin
                        SkillJson.ReadFrom(SkillToJsonObject(BusinessSkill).Unwrap());
                        Result.Add(SkillJson);
                    end;
            until BusinessSkill.Next() = 0;
        Result.WriteTo(SerializedResult);
        exit(SerializedResult);
    end;

    procedure SkillToJsonObject(var Skill: Record "Business Skill"): SecretText
    var
        Result: JsonObject;
        SecretResult: SecretText;
    begin
        Result.Add('id', Skill.ID);
        Result.Add('systemId', Skill.SystemId);
        Result.Add('title', Skill.Title);
        Result.Add('description', Skill.Description);
        Result.Add('skillText', '');
        case Skill.Status of
            Skill.Status::Active:
                Result.Add('status', 'Active');
            Skill.Status::Inactive:
                Result.Add('status', 'Inactive');
        end;
        Result.Add('lastModifiedDateTime', Skill.SystemModifiedAt);
        Result.WriteWithSecretsTo('skillText', TextHelper.GetSkillText(Skill), SecretResult);
        exit(SecretResult);
    end;

    local procedure ValidateContent(var Skill: Record "Business Skill"; LoadFromDatabase: Boolean; ErrorMessage: Text)
    var
        Value: SecretText;
    begin
        Value := TextHelper.GetSkillText(Skill, LoadFromDatabase);
        TextHelper.ValidateLength(Value);
        if (Skill.Status = Skill.Status::Active) and ((Skill.Title.Trim() = '') or TextHelper.IsBlank(Value)) then
            Error(ErrorMessage);
    end;

    local procedure VerifySkillRevision(Skill: Record "Business Skill"; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    begin
        // The editor holds an earlier snapshot; fetching a record to save must not bypass stale-edit detection.
        if (Skill.SystemId <> ExpectedSystemId) or (Skill.SystemRowVersion <> ExpectedRevision) then
            Error(SkillChangedErr);
    end;

    local procedure SkillMatchesSearch(var Skill: Record "Business Skill"; SearchText: Text): Boolean
    begin
        exit((SearchText = '') or LowerCase(Skill.Title).Contains(SearchText) or LowerCase(Skill.Description).Contains(SearchText));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnAfterBusinessSkillDeleted', '', false, false)]
    local procedure DeleteTextVersionsOnAfterBusinessSkillDeleted(Skill: Record "Business Skill")
    var
        TextVersion: Record "Business Skill Text Version";
    begin
        TextVersion.SetRange("Skill ID", Skill.ID);
        TextVersion.DeleteAll(false);
    end;

    var
        TextHelper: Codeunit "Business Skill Text";
        ActivationContentRequiredErr: Label 'A skill needs a title and skill text before it can be activated.';
        ActiveContentRequiredErr: Label 'An active skill needs a title and skill text.';
        SkillChangedErr: Label 'This skill was changed by another user. Refresh it before saving your changes.';
        SkillUnavailableErr: Label 'Skill %1 is not active.', Comment = '%1 = skill ID';
        CannotDeleteLatestErr: Label 'The current (latest) version cannot be deleted.';
        ReadOnlyErr: Label 'The instructions and version of this skill are read-only. Create an editable copy to change them.';
        ManualReadOnlyErr: Label 'A manually owned skill cannot be read-only.';
        ManualVersionOnlyErr: Label 'Only manually owned skills can change the version directly.';
        ProgrammaticVersionRequiredErr: Label 'Specify a new version when you change the text of an app-owned skill.';
        ProgrammaticVersionRequiresTextErr: Label 'The version of an app-owned skill can change only together with its text.';
        DeleteActiveSkillErr: Label 'Deactivate the skill before you delete it.';
        DeleteInstalledOwnerErr: Label 'You cannot delete this skill because its owning extension, ''%1'', is still installed. Uninstall the extension to delete the skill, or deactivate the skill to stop it being used.', Comment = '%1 = name of the installed extension that owns the skill';
        DeleteNotAllowedErr: Label 'You do not have permission to delete this skill.';
        SkillIdentityImmutableErr: Label 'The skill ID, owning app ID, owning app publisher and Manual flag cannot be changed after the skill is created.';
        AppSkillNotFoundErr: Label 'The skill was not found among the calling app''s skills.';
        InitialVersionTok: Label 'v1.0', Locked = true;
        VersionSuffixTok: Label ' - 2', Locked = true;
        CreatedManuallyLbl: Label 'Created manually';
        UnavailableAppLbl: Label 'Unavailable app (%1)', Comment = '%1 = owning app ID';
        UnavailablePublisherLbl: Label 'Unavailable publisher';
}
