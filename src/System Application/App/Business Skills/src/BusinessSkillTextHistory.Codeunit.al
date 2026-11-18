// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

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
    /// Writes the new text to the skill BLOB and records a version when the text changed.
    /// </summary>
    procedure SetSkillText(SkillId: BigInteger; NewText: SecretText)
    var
        SkillManagement: Codeunit "Business Skill Management";
    begin
        SkillManagement.SetSkillText(SkillId, NewText);
    end;

    /// <summary>
    /// Restores an earlier version as the current skill text by re-inserting it as a new version.
    /// </summary>
    procedure RestoreVersion(EntryNo: Integer)
    var
        SkillManagement: Codeunit "Business Skill Management";
    begin
        SkillManagement.RestoreTextVersion(EntryNo);
    end;

    /// <summary>
    /// Deletes a version. The latest (current) version cannot be deleted.
    /// </summary>
    procedure DeleteVersion(var TextVersion: Record "Business Skill Text Version")
    var
        SkillManagement: Codeunit "Business Skill Management";
    begin
        SkillManagement.DeleteTextVersion(TextVersion."Entry No.");
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
        TextHelper: Codeunit "Business Skill Text";
    begin
        if SkillId = 0 then
            exit;
        if not Skill.Get(SkillId) then
            exit;
        exit(TextHelper.GetSkillText(Skill));
    end;

    /// <summary>
    /// Downloads a single version to a text file.
    /// </summary>
    procedure DownloadVersion(var TextVersion: Record "Business Skill Text Version")
    var
        TempBlob: Codeunit "Temp Blob";
        TextHelper: Codeunit "Business Skill Text";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, TextHelper.GetEncoding());
        TextHelper.WriteText(OutStr, TextVersion.GetText());
        TempBlob.CreateInStream(InStr, TextHelper.GetEncoding());
        FileName := StrSubstNo(FileNameLbl, TextVersion."Skill ID", TextVersion."Entry No.");
        DownloadFromStream(InStr, DownloadDialogLbl, '', AllFilesFilterLbl, FileName);
    end;

    /// <summary>
    /// HTML-encodes text for safe injection into the WebPageViewer add-in.
    /// </summary>
    procedure EncodeContent(Content: SecretText): SecretText
    var
        TextHelper: Codeunit "Business Skill Text";
    begin
        exit(TextHelper.EncodeContent(Content));
    end;

    local procedure GetLatestVersion(SkillId: BigInteger; var Latest: Record "Business Skill Text Version"): Boolean
    begin
        Latest.Reset();
        Latest.SetCurrentKey("Skill ID", "Entry No.");
        Latest.SetRange("Skill ID", SkillId);
        Latest.Ascending(false);
        exit(Latest.FindFirst());
    end;

    var
        FileNameLbl: Label 'Skill-%1-Version-%2.txt', Comment = '%1 = Skill ID, %2 = Entry No.', Locked = true;
        DownloadDialogLbl: Label 'Download skill text version';
        AllFilesFilterLbl: Label 'Text Files (*.txt)|*.txt', Locked = true;
}
