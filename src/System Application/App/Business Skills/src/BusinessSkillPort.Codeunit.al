// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Utilities;

/// <summary>
/// Imports and exports manual skills with their complete instruction text.
/// Imported skills are new manual skills: AL assigns their skill IDs, and the file carries no skill ID or owner.
/// </summary>
codeunit 4167 "Business Skill Port"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ExportSkills(var Skill: Record "Business Skill")
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        BuildSkillExportBlob(Skill, TempBlob);
        DownloadBlob(TempBlob);
    end;

    procedure BuildExportXml(var Skill: Record "Business Skill"): Text
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        BuildSkillExportBlob(Skill, TempBlob);
        exit(ReadBlobText(TempBlob));
    end;

    local procedure BuildSkillExportBlob(var Skill: Record "Business Skill"; var TempBlob: Codeunit "Temp Blob")
    var
        TempSkill: Record "Business Skill" temporary;
    begin
        if Skill.FindSet() then
            repeat
                TempSkill.TransferFields(Skill, true);
                TempSkill.SystemId := Skill.SystemId;
                TempSkill.SystemCreatedAt := Skill.SystemCreatedAt;
                TempSkill.SystemCreatedBy := Skill.SystemCreatedBy;
                TempSkill.SystemModifiedAt := Skill.SystemModifiedAt;
                TempSkill.SystemModifiedBy := Skill.SystemModifiedBy;
                TempSkill.Insert(false, true);
            until Skill.Next() = 0;
        RunExport(TempSkill, TempBlob);
    end;

    local procedure RunExport(var TempSkill: Record "Business Skill" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        SkillManagement: Codeunit "Business Skill Management";
        ExportPort: XmlPort "Business Skill Export";
        OutStr: OutStream;
    begin
        if TempSkill.FindSet() then
            repeat
                if not SkillManagement.IsManualSkill(TempSkill) then
                    Error(ManualSkillsOnlyErr, TempSkill."Skill ID");
            until TempSkill.Next() = 0;
        TempBlob.CreateOutStream(OutStr, TextHelper.GetEncoding());
        ExportPort.SetBuffer(TempSkill);
        ExportPort.SetDestination(OutStr);
        ExportPort.Export();
    end;

    procedure ImportSkills()
    var
        InStr: InStream;
        FileName: Text;
    begin
        if UploadIntoStream(ImportDialogTitleLbl, '', ImportFilterLbl, FileName, InStr) then
            Message(ImportFromStream(InStr));
    end;

    procedure ImportFromXml(XmlText: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextHelper.GetEncoding());
        OutStr.WriteText(XmlText);
        TempBlob.CreateInStream(InStr, TextHelper.GetEncoding());
        exit(ImportFromStream(InStr));
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure ImportFromStream(var InStr: InStream): Text
    var
        ImportPort: XmlPort "Business Skill Import";
    begin
        Clear(SkillReferences);
        SkillsCreated := 0;
        ImportPort.SetSource(InStr);
        ImportPort.SetPort(this);
        ImportPort.Import();
        exit(StrSubstNo(ImportSummaryLbl, SkillsCreated));
    end;

    internal procedure ImportSkillElement(var SourceSkill: Record "Business Skill"; SkillText: Text)
    var
        Skill: Record "Business Skill";
        SkillManagement: Codeunit "Business Skill Management";
    begin
        ValidateSkillReference(SourceSkill.ID);
        Skill.Title := SourceSkill.Title;
        Skill.Description := SourceSkill.Description;
        Skill.Version := SourceSkill.Version;
        Skill.Status := Skill.Status::Active;
        TextHelper.SetSkillText(Skill, SkillText);
        SkillManagement.InsertSkillRecord(Skill);
        SkillReferences.Add(SourceSkill.ID, Skill.ID);
        SkillsCreated += 1;
    end;

    internal procedure ValidateSkillReference(Reference: BigInteger)
    begin
        if (Reference <= 0) or SkillReferences.ContainsKey(Reference) then
            Error(InvalidReferenceErr);
    end;

    local procedure DownloadBlob(var TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
        FileName: Text;
    begin
        TempBlob.CreateInStream(InStr, TextHelper.GetEncoding());
        FileName := 'BusinessSkills.xml';
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    local procedure ReadBlobText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextHelper.GetEncoding());
        exit(TextHelper.ReadText(InStr));
    end;

    var
        TextHelper: Codeunit "Business Skill Text";
        SkillReferences: Dictionary of [BigInteger, BigInteger];
        SkillsCreated: Integer;
        InvalidReferenceErr: Label 'The document contains an invalid or duplicate skill reference.';
        ManualSkillsOnlyErr: Label 'Skill %1 is app-owned. Only manually owned skills can be exported.', Comment = '%1 = skill ID';
        ImportSummaryLbl: Label 'Import complete. Skills created: %1.', Comment = '%1 = created skill count';
        ImportDialogTitleLbl: Label 'Import Business Skills';
        ImportFilterLbl: Label 'XML Files (*.xml)|*.xml', Locked = true;
}
