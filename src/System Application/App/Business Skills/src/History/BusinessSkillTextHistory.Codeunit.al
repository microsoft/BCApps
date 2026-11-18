// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Environment;
using System.Utilities;

/// <summary>
/// Maintains the version history of a business skill's text and provides the read/write helpers used
/// by the skill-text editor part and history page.
/// </summary>
/// <remarks>
/// The skill's own BLOB remains the source of truth for the current text; every change is mirrored
/// into an append-only <see cref="Business Skill Text Version"/> entry (deduplicated so an unchanged
/// save does not create a new version). The latest entry always matches the current skill text.
/// </remarks>
codeunit 4166 "Business Skill Text History"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Restores an earlier version as the current skill text by re-inserting it as a new version.
    /// </summary>
    procedure RestoreVersion(EntryNo: Integer)
    var
        TextVersion: Record "Business Skill Text Version";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        TextVersion.Get(EntryNo);
        BusinessSkillImpl.SetSkillText(TextVersion."Skill ID", TextVersion.GetText());
    end;

    /// <summary>
    /// Deletes a version. The latest (current) version cannot be deleted.
    /// </summary>
    procedure DeleteVersion(var TextVersion: Record "Business Skill Text Version")
    begin
        TextVersion.Get(TextVersion."Entry No.");
        VerifyCanDeleteVersion(TextVersion."Entry No.");
        TextVersion.Delete(true);
    end;

    /// <summary>
    /// Rejects deletion of the current text version, including direct table deletion.
    /// </summary>
    procedure VerifyCanDeleteVersion(EntryNo: Integer)
    var
        TextVersion: Record "Business Skill Text Version";
    begin
        TextVersion.Get(EntryNo);
        if IsLatestVersion(TextVersion) then
            Error(CannotDeleteLatestErr);
    end;

    /// <summary>
    /// Records the saved text as a new version unless it equals the latest version.
    /// </summary>
    procedure RecordTextVersion(var Skill: Record "Business Skill")
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if Skill.IsTemporary() then
            exit;
        RecordTextVersion(Skill.ID, BusinessSkillImpl.GetSkillText(Skill), Skill.Version);
    end;

    /// <summary>
    /// Records the supplied text as a new version unless it equals the latest version.
    /// </summary>
    procedure RecordTextVersion(SkillId: BigInteger; NewText: SecretText; SkillVersion: Text[50])
    var
        LatestVersion: Record "Business Skill Text Version";
        TextVersion: Record "Business Skill Text Version";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if GetLatestVersion(SkillId, LatestVersion) then
            if BusinessSkillImpl.ContentEquals(LatestVersion.GetText(), NewText) then
                exit;
        TextVersion."Skill ID" := SkillId;
        TextVersion.Version := SkillVersion;
        TextVersion.SetText(NewText);
        TextVersion.Insert(true);
    end;

    /// <summary>
    /// Returns the latest version for copying, falling back to the skill's content when no history exists.
    /// </summary>
    procedure GetLatestText(var Skill: Record "Business Skill"): SecretText
    var
        LatestVersion: Record "Business Skill Text Version";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if GetLatestVersion(Skill.ID, LatestVersion) then
            exit(LatestVersion.GetText());
        exit(BusinessSkillImpl.GetSkillText(Skill));
    end;

    /// <summary>
    /// Returns whether the given entry is the latest version for its skill.
    /// </summary>
    procedure IsLatestVersion(var TextVersion: Record "Business Skill Text Version"): Boolean
    var
        Latest: Record "Business Skill Text Version";
    begin
        if not GetLatestVersion(TextVersion."Skill ID", Latest) then
            exit(false);
        exit(Latest."Entry No." = TextVersion."Entry No.");
    end;

    /// <summary>
    /// Compatibility read helper. The skill record owns current text; history is not its source.
    /// </summary>
    procedure GetSkillText(SkillId: BigInteger): SecretText
    var
        Skill: Record "Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if SkillId = 0 then
            exit;
        if not Skill.Get(SkillId) then
            exit;
        exit(BusinessSkillImpl.GetSkillText(Skill));
    end;

    /// <summary>
    /// Downloads a single version to a text file.
    /// </summary>
    procedure DownloadVersion(var TextVersion: Record "Business Skill Text Version")
    var
        TempBlob: Codeunit "Temp Blob";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, BusinessSkillImpl.GetEncoding());
        BusinessSkillImpl.WriteText(OutStr, TextVersion.GetText());
        TempBlob.CreateInStream(InStr, BusinessSkillImpl.GetEncoding());
        FileName := StrSubstNo(FileNameLbl, TextVersion."Skill ID", TextVersion."Entry No.");
        DownloadFromStream(InStr, DownloadDialogLbl, '', AllFilesFilterLbl, FileName);
    end;

    local procedure GetLatestVersion(SkillId: BigInteger; var Latest: Record "Business Skill Text Version"): Boolean
    begin
        Latest.Reset();
        Latest.SetCurrentKey("Skill ID", "Entry No.");
        Latest.SetRange("Skill ID", SkillId);
        Latest.Ascending(false);
        exit(Latest.FindFirst());
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
        CannotDeleteLatestErr: Label 'The current (latest) version cannot be deleted.';
        FileNameLbl: Label 'Skill-%1-Version-%2.txt', Comment = '%1 = Skill ID, %2 = Entry No.', Locked = true;
        DownloadDialogLbl: Label 'Download skill text version';
        AllFilesFilterLbl: Label 'Text Files (*.txt)|*.txt', Locked = true;
}
