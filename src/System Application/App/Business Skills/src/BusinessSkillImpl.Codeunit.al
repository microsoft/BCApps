// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System;
using System.Agents;
using System.Utilities;

/// <summary>
/// Governs skill creation, content updates and lifecycle.
/// Preserves content history and optimistic concurrency while sharing eligibility rules across native and API callers.
/// </summary>
/// <remarks>
/// The platform table "Business Skill" stamps ownership, assigns manual skill identifiers and protects identity.
/// AL supplies app-owned identifiers and governs status, content, versions, history and deletion.
/// </remarks>
codeunit 4163 "Business Skill Impl."
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
        ValidateContent(Skill, GetContentFromBuffer(Skill), ActiveContentRequiredErr);
    end;

    /// <summary>
    /// Validates a skill before it is modified.
    /// </summary>
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
        Skill.TestField(Version);
        if (Skill.Version <> StoredSkill.Version) and not IsManualSkill(Skill) then
            if ContentEquals(GetContentFromBuffer(Skill), GetContent(StoredSkill)) then
                Error(ProgrammaticVersionRequiresContentErr);
        PreventReadOnlyManualSkill(Skill);
        ValidateContent(Skill, GetContentFromBuffer(Skill), ActiveContentRequiredErr);
    end;

    procedure IsManualSkill(Skill: Record "Business Skill"): Boolean
    begin
        exit(Skill.Manual);
    end;

    /// <summary>
    /// Returns whether the native manual editor can change the skill's instructions and version.
    /// </summary>
    procedure CanEditContent(Skill: Record "Business Skill"): Boolean
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
    /// Applies the version rules to a content change of a saved skill. A manual skill advances its version; a skill owned by an app
    /// must already carry a new version supplied by the app.
    /// </summary>
    procedure ValidateContentChange(var Skill: Record "Business Skill"; NewContent: SecretText)
    var
        StoredSkill: Record "Business Skill";
    begin
        if Skill.IsTemporary() or (Skill.ID = 0) then
            exit;
        StoredSkill.Get(Skill.ID);
        if ContentEquals(GetContent(StoredSkill), NewContent) then begin
            if IsManualSkill(StoredSkill) then
                Skill.Version := StoredSkill.Version;
            exit;
        end;
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
    /// Creates an inactive manual copy of a skill with the current content of the source skill. The copy gets a new skill ID
    /// from the platform and starts its own content history at v1.0.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CopySkill(SkillId: BigInteger): BigInteger
    var
        SourceSkill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        SkillContent: SecretText;
    begin
        SourceSkill.Get(SkillId);
        SkillContent := BusinessSkillContentHistory.GetLatestContent(SourceSkill);
        exit(Builder.Initialize('', SourceSkill.Title, SkillContent).SetManual(true).SetDescription(SourceSkill.Description).Create());
    end;

    procedure UpdateSkillRecord(SkillId: BigInteger; var SourceSkill: Record "Business Skill"; SkillContent: SecretText): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        VerifySkillRevision(BusinessSkill, SourceSkill.SystemId, SourceSkill.SystemRowVersion);
        exit(UpdateSkill(BusinessSkill, SourceSkill.Title, SourceSkill.Description, SkillContent, SourceSkill.Version));
    end;

    procedure UpdateSkill(SkillId: BigInteger; Title: Text[250]; SkillContent: SecretText): Boolean
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        exit(UpdateSkill(BusinessSkill, Title, SkillContent));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; SkillContent: SecretText): Boolean
    begin
        exit(UpdateSkill(BusinessSkill, Title, BusinessSkill.Description, SkillContent));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; Description: Text[2048]; SkillContent: SecretText): Boolean
    begin
        exit(UpdateSkill(BusinessSkill, Title, Description, SkillContent, BusinessSkill.Version));
    end;

    local procedure UpdateSkill(var BusinessSkill: Record "Business Skill"; Title: Text[250]; Description: Text[2048]; SkillContent: SecretText; SkillVersion: Text[50]): Boolean
    var
        ContentChanged: Boolean;
        VersionChanged: Boolean;
    begin
        ContentChanged := not ContentEquals(GetContent(BusinessSkill), SkillContent);
        VersionChanged := BusinessSkill.Version <> SkillVersion;
        if (BusinessSkill.Title = Title) and (BusinessSkill.Description = Description) and not ContentChanged and not VersionChanged then
            exit(true);
        if VersionChanged then begin
            BusinessSkill.Version := SkillVersion;
            ValidateManualVersionChange(BusinessSkill);
        end;
        BusinessSkill.Title := Title;
        BusinessSkill.Description := Description;
        if ContentChanged then
            SetContent(BusinessSkill, SkillContent);
        if VersionChanged then
            BusinessSkill.Version := SkillVersion;
        ValidateSkillModify(BusinessSkill);
        BusinessSkill.Modify(true);
        if ContentChanged then
            BusinessSkillContentHistory.RecordContentVersion(BusinessSkill.ID, SkillContent, BusinessSkill.Version);
        exit(true);
    end;

    procedure ActivateSkill(SkillId: BigInteger)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.Status := BusinessSkill.Status::Active;
        ValidateContent(BusinessSkill, GetContent(BusinessSkill), ActivationContentRequiredErr);
        BusinessSkill.Modify(true);
    end;

    procedure DeactivateSkill(SkillId: BigInteger)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.Status := BusinessSkill.Status::Inactive;
        BusinessSkill.Modify(true);
    end;

    /// <summary>
    /// Deletes an inactive skill. The platform does not check deletes, so the delete rules are enforced here.
    /// </summary>
    procedure DeleteSkill(SkillId: BigInteger)
    var
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        DeleteSkill(SkillId, CallerModule.Id);
    end;

    /// <summary>
    /// Deletes an inactive skill and its manual history for the caller captured by an internal entry point or public facade.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure DeleteSkill(SkillId: BigInteger; CallerAppId: Guid)
    var
        BusinessSkill: Record "Business Skill";
        ActiveSkillError: ErrorInfo;
        DeleteError: Text;
    begin
        BusinessSkill.Get(SkillId);
        if BusinessSkill.Status = BusinessSkill.Status::Active then begin
            ActiveSkillError.Message := DeleteActiveSkillErr;
            ActiveSkillError.RecordId := BusinessSkill.RecordId();
            ActiveSkillError.PageNo := Page::"Business Skill Card";
            ActiveSkillError.AddNavigationAction(OpenSkillLbl);
            Error(ActiveSkillError);
        end;
        if not CanDeleteSkill(BusinessSkill, CallerAppId, DeleteError) then
            Error(DeleteError);
        BusinessSkill.Delete(true);
        if BusinessSkill.Manual then
            BusinessSkillContentHistory.DeleteHistory(SkillId);
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

    /// <summary>
    /// Returns whether deletion is permitted and, if not, the reason it is blocked.
    /// </summary>
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

    procedure SetContent(SkillId: BigInteger; SkillContent: SecretText)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        UpdateSkill(BusinessSkill, BusinessSkill.Title, SkillContent);
    end;

    procedure SetContent(SkillId: BigInteger; SkillContent: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.Get(SkillId);
        BusinessSkill.TestField(Manual, true);
        VerifySkillRevision(BusinessSkill, ExpectedSystemId, ExpectedRevision);
        UpdateSkill(BusinessSkill, BusinessSkill.Title, SkillContent);
    end;

    /// <summary>
    /// Changes the content of a skill owned by an app together with the new version supplied by the app.
    /// </summary>
    procedure SetContent(SkillId: BigInteger; SkillContent: SecretText; NewVersion: Text[50])
    var
        BusinessSkill: Record "Business Skill";
        ContentChanged: Boolean;
    begin
        BusinessSkill.Get(SkillId);
        ContentChanged := not ContentEquals(GetContent(BusinessSkill), SkillContent);
        if not ContentChanged and (BusinessSkill.Version = NewVersion) then
            exit;
        BusinessSkill.Version := NewVersion;
        if ContentChanged then
            SetContent(BusinessSkill, SkillContent);
        ValidateSkillModify(BusinessSkill);
        BusinessSkill.Modify(true);
        if ContentChanged then
            BusinessSkillContentHistory.RecordContentVersion(BusinessSkill.ID, SkillContent, BusinessSkill.Version);
    end;

    /// <summary>
    /// Updates the skill selected by its calling app and code, including inactive skills.
    /// </summary>
    procedure SetNewContentAndUpdateVersion(CallerAppId: Guid; SkillCode: Code[100]; Content: SecretText; ContentVersion: Text[50])
    var
        Skill: Record "Business Skill";
    begin
        GetAppOwnedSkill(CallerAppId, SkillCode, Skill);
        SetContent(Skill.ID, Content, ContentVersion);
    end;

    /// <summary>
    /// Updates only the calling app's skill metadata through the existing validation and write path.
    /// </summary>
    procedure UpdateMetadata(CallerAppId: Guid; SkillCode: Code[100]; Name: Text[250]; Description: Text[2048])
    var
        BusinessSkill: Record "Business Skill";
    begin
        GetAppOwnedSkill(CallerAppId, SkillCode, BusinessSkill);
        UpdateSkill(BusinessSkill, Name, Description, GetContent(BusinessSkill));
    end;

    local procedure GetAppOwnedSkill(CallerAppId: Guid; SkillCode: Code[100]; var Skill: Record "Business Skill")
    begin
        Skill.SetRange("Owning App ID", CallerAppId);
        Skill.SetRange("Skill ID", SkillCode);
        Skill.SetRange(Manual, false);
        if not Skill.FindFirst() then
            Error(AppSkillNotFoundErr);
    end;

    /// <summary>
    /// Skills are not scoped to companies yet, so every existing skill applies to the current company.
    /// </summary>
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

    local procedure ValidateContent(Skill: Record "Business Skill"; Value: SecretText; ErrorMessage: Text)
    begin
        ValidateLength(Value);
        if (Skill.Status = Skill.Status::Active) and ((Skill.Title.Trim() = '') or IsBlank(Value)) then
            Error(ErrorMessage);
    end;

    local procedure VerifySkillRevision(Skill: Record "Business Skill"; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    begin
        // The editor holds an earlier snapshot; fetching a record to save must not bypass stale-edit detection.
        if (Skill.SystemId <> ExpectedSystemId) or (Skill.SystemRowVersion <> ExpectedRevision) then
            Error(SkillChangedErr);
    end;

    /// <summary>
    /// Returns the instructions of the skill, loaded from the database.
    /// </summary>
    procedure GetContent(var Skill: Record "Business Skill"): SecretText
    begin
        Skill.CalcFields("Skill Text");
        exit(GetContentFromBuffer(Skill));
    end;

    /// <summary>
    /// Downloads current stored content independently of manual content history.
    /// </summary>
    procedure DownloadContent(SkillId: BigInteger)
    var
        BusinessSkill: Record "Business Skill";
        TempBlob: Codeunit "Temp Blob";
        Input: InStream;
        Output: OutStream;
        FileName: Text;
    begin
        BusinessSkill.Get(SkillId);
        TempBlob.CreateOutStream(Output, GetEncoding());
        WriteText(Output, GetContent(BusinessSkill));
        TempBlob.CreateInStream(Input, GetEncoding());
        FileName := StrSubstNo(ContentFileNameLbl, SkillId);
        DownloadFromStream(Input, DownloadContentLbl, '', TextFilesFilterLbl, FileName);
    end;

    /// <summary>
    /// Returns the content already loaded or assigned on the record buffer without reloading it.
    /// </summary>
    procedure GetContentFromBuffer(var Skill: Record "Business Skill"): SecretText
    var
        Input: InStream;
    begin
        if not Skill."Skill Text".HasValue() then
            exit;
        Skill."Skill Text".CreateInStream(Input, GetEncoding());
        exit(ReadText(Input));
    end;

    /// <summary>
    /// Sets instructions without saving the record, applying manual or app-owned version rules.
    /// </summary>
    procedure SetContent(var Skill: Record "Business Skill"; Value: SecretText)
    var
        Output: OutStream;
    begin
        ValidateLength(Value);
        ValidateContentChange(Skill, Value);
        Clear(Skill."Skill Text");
        Skill."Skill Text".CreateOutStream(Output, GetEncoding());
        WriteText(Output, Value);
    end;

    /// <summary>
    /// Returns the encoding used by skill, history and portable text streams.
    /// </summary>
    procedure GetEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    /// <summary>
    /// Reads the stream line by line, inserting separators only between returned lines.
    /// </summary>
    [NonDebuggable]
    procedure ReadText(Input: InStream): SecretText
    var
        TextBuilder: TextBuilder;
        TextLine: Text;
        FirstLine: Boolean;
    begin
        FirstLine := true;
        while not Input.EOS() do begin
            Input.ReadText(TextLine);
            if not FirstLine then
                TextBuilder.AppendLine('');
            TextBuilder.Append(TextLine);
            FirstLine := false;
        end;
        exit(TextBuilder.ToText());
    end;

    /// <summary>
    /// Returns the maximum supported instruction length.
    /// </summary>
    procedure GetMaxLength(): Integer
    begin
        exit(100000);
    end;

    /// <summary>
    /// Checks the persistent instruction limit independently of the UI.
    /// </summary>
    [NonDebuggable]
    procedure ValidateLength(Value: SecretText)
    begin
        if StrLen(Value.Unwrap()) > GetMaxLength() then
            Error(ContentTooLongErr, Format(GetMaxLength(), 0, 9));
    end;

    /// <summary>
    /// Encodes text for HTML attributes and content, not for JavaScript execution.
    /// </summary>
    [NonDebuggable]
    procedure EncodeContent(Value: SecretText): SecretText
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.HtmlEncode(Value.Unwrap()));
    end;

    /// <summary>
    /// Unwraps only at the stream boundary; callers retain protected content.
    /// </summary>
    [NonDebuggable]
    procedure WriteText(Output: OutStream; Value: SecretText)
    begin
        Output.WriteText(Value.Unwrap());
    end;

    /// <summary>
    /// Compares protected content without returning plaintext.
    /// </summary>
    [NonDebuggable]
    procedure ContentEquals(Value: SecretText; Other: SecretText): Boolean
    begin
        exit(Value.Unwrap() = Other.Unwrap());
    end;

    /// <summary>
    /// Checks whitespace without exposing the content.
    /// </summary>
    [NonDebuggable]
    procedure IsBlank(Value: SecretText): Boolean
    begin
        exit(Value.Unwrap().Trim() = '');
    end;

    var
        BusinessSkillContentHistory: Codeunit "Business Skill Content History";
        ContentTooLongErr: Label 'Skill content must not exceed %1 characters.', Comment = '%1 = maximum content length';
        ActivationContentRequiredErr: Label 'A skill needs a title and skill content before it can be activated.';
        ActiveContentRequiredErr: Label 'An active skill needs a title and skill content.';
        SkillChangedErr: Label 'This skill was changed by another user. Refresh it before saving your changes.';
        ManualReadOnlyErr: Label 'A manually owned skill cannot be read-only.';
        ManualVersionOnlyErr: Label 'Only manually owned skills can change the version directly.';
        ProgrammaticVersionRequiredErr: Label 'Specify a new version when you change the content of an app-owned skill.';
        ProgrammaticVersionRequiresContentErr: Label 'The version of an app-owned skill can change only together with its content.';
        DeleteActiveSkillErr: Label 'Deactivate the skill before you delete it.';
        OpenSkillLbl: Label 'Open skill';
        ContentFileNameLbl: Label 'Skill-%1.txt', Comment = '%1 = Skill ID', Locked = true;
        DownloadContentLbl: Label 'Download skill content';
        TextFilesFilterLbl: Label 'Text Files (*.txt)|*.txt', Locked = true;
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
