// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Utilities;

/// <summary>
/// Maintains the version history of a manual business skill's content and provides the read/write helpers used
/// by the skill-content editor part and history page.
/// </summary>
/// <remarks>
/// The skill's own BLOB remains the source of truth for the current content; manual content changes are mirrored
/// into an append-only <see cref="Bus Skill Content Version"/> entry (deduplicated so an unchanged
/// save does not create a new version). The latest entry always matches the current skill content.
/// </remarks>
codeunit 4166 "Business Skill Content History"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Restores an earlier version as the current skill content by re-inserting it as a new version.
    /// </summary>
    procedure RestoreVersion(EntryNo: Integer)
    var
        BusSkillContentVersion: Record "Bus Skill Content Version";
        BusinessSkill: Record "Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusSkillContentVersion.Get(EntryNo);
        BusinessSkill.Get(BusSkillContentVersion."Skill ID");
        BusinessSkill.TestField(Manual, true);
        BusinessSkillImpl.SetContent(BusSkillContentVersion."Skill ID", BusSkillContentVersion.GetContent());
    end;

    /// <summary>
    /// Removes a deleted manual skill's history, including its latest version.
    /// </summary>
    procedure DeleteHistory(SkillId: BigInteger)
    var
        BusSkillContentVersion: Record "Bus Skill Content Version";
    begin
        BusSkillContentVersion.SetRange("Skill ID", SkillId);
        BusSkillContentVersion.DeleteAll(false);
    end;

    /// <summary>
    /// Deletes a version. The latest (current) version cannot be deleted.
    /// </summary>
    procedure DeleteVersion(var BusSkillContentVersion: Record "Bus Skill Content Version")
    begin
        BusSkillContentVersion.Get(BusSkillContentVersion."Entry No.");
        VerifyCanDeleteVersion(BusSkillContentVersion."Entry No.");
        BusSkillContentVersion.Delete(true);
    end;

    /// <summary>
    /// Rejects deletion of the current content version, including direct table deletion.
    /// </summary>
    procedure VerifyCanDeleteVersion(EntryNo: Integer)
    var
        BusSkillContentVersion: Record "Bus Skill Content Version";
    begin
        BusSkillContentVersion.Get(EntryNo);
        if IsLatestVersion(BusSkillContentVersion) then
            Error(CannotDeleteLatestErr);
    end;

    /// <summary>
    /// Records saved manual content as a new version unless it equals the latest version.
    /// </summary>
    procedure RecordContentVersion(var BusinessSkill: Record "Business Skill")
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if BusinessSkill.IsTemporary() then
            exit;
        RecordContentVersion(BusinessSkill.ID, BusinessSkillImpl.GetContent(BusinessSkill), BusinessSkill.Version);
    end;

    /// <summary>
    /// Records manual content unless it equals the latest version or is blank before history exists.
    /// </summary>
    procedure RecordContentVersion(SkillId: BigInteger; NewContent: SecretText; ContentVersion: Text[50])
    var
        BusinessSkill: Record "Business Skill";
        LatestBusSkillContentVersion: Record "Bus Skill Content Version";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusinessSkill.Get(SkillId);
        if not BusinessSkill.Manual then
            exit;
        if GetLatestVersion(SkillId, LatestBusSkillContentVersion) then begin
            if BusinessSkillImpl.ContentEquals(LatestBusSkillContentVersion.GetContent(), NewContent) then
                exit;
        end else
            if BusinessSkillImpl.IsBlank(NewContent) then
                exit;
        BusSkillContentVersion."Skill ID" := SkillId;
        BusSkillContentVersion."Content Version" := ContentVersion;
        BusSkillContentVersion.SetContent(NewContent);
        BusSkillContentVersion.Insert(true);
    end;

    /// <summary>
    /// Returns the latest manual version for copying, or stored content for app-owned skills or missing history.
    /// </summary>
    procedure GetLatestContent(var BusinessSkill: Record "Business Skill"): SecretText
    var
        LatestBusSkillContentVersion: Record "Bus Skill Content Version";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if BusinessSkill.Manual then
            if GetLatestVersion(BusinessSkill.ID, LatestBusSkillContentVersion) then
                exit(LatestBusSkillContentVersion.GetContent());
        exit(BusinessSkillImpl.GetContent(BusinessSkill));
    end;

    /// <summary>
    /// Returns whether the given entry is the latest version for its skill.
    /// </summary>
    procedure IsLatestVersion(var BusSkillContentVersion: Record "Bus Skill Content Version"): Boolean
    var
        LatestBusSkillContentVersion: Record "Bus Skill Content Version";
    begin
        if not GetLatestVersion(BusSkillContentVersion."Skill ID", LatestBusSkillContentVersion) then
            exit(false);
        exit(LatestBusSkillContentVersion."Entry No." = BusSkillContentVersion."Entry No.");
    end;

    /// <summary>
    /// Compatibility read helper. The skill record owns current content; history is not its source.
    /// </summary>
    procedure GetContent(SkillId: BigInteger): SecretText
    var
        BusinessSkill: Record "Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        if SkillId = 0 then
            exit;
        if not BusinessSkill.Get(SkillId) then
            exit;
        exit(BusinessSkillImpl.GetContent(BusinessSkill));
    end;

    /// <summary>
    /// Downloads a single version to a text file.
    /// </summary>
    procedure DownloadVersion(var BusSkillContentVersion: Record "Bus Skill Content Version")
    var
        TempBlob: Codeunit "Temp Blob";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, BusinessSkillImpl.GetEncoding());
        BusinessSkillImpl.WriteText(OutStr, BusSkillContentVersion.GetContent());
        TempBlob.CreateInStream(InStr, BusinessSkillImpl.GetEncoding());
        FileName := StrSubstNo(FileNameLbl, BusSkillContentVersion."Skill ID", BusSkillContentVersion."Entry No.");
        DownloadFromStream(InStr, DownloadDialogLbl, '', AllFilesFilterLbl, FileName);
    end;

    local procedure GetLatestVersion(SkillId: BigInteger; var LatestBusSkillContentVersion: Record "Bus Skill Content Version"): Boolean
    begin
        LatestBusSkillContentVersion.Reset();
        LatestBusSkillContentVersion.SetCurrentKey("Skill ID", "Entry No.");
        LatestBusSkillContentVersion.SetRange("Skill ID", SkillId);
        LatestBusSkillContentVersion.Ascending(false);
        exit(LatestBusSkillContentVersion.FindFirst());
    end;

    var
        CannotDeleteLatestErr: Label 'The current (latest) version cannot be deleted.';
        FileNameLbl: Label 'Skill-%1-Version-%2.txt', Comment = '%1 = Skill ID, %2 = Entry No.', Locked = true;
        DownloadDialogLbl: Label 'Download skill content version';
        AllFilesFilterLbl: Label 'Text Files (*.txt)|*.txt', Locked = true;
}
