// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Hosts the native Markdown field for a business skill's instructions.
/// Editable only for a saved skill the caller may maintain; otherwise read-only, including previews.
/// </summary>
page 4163 "Business Skill Text Part"
{
    PageType = CardPart;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Business Skill Text';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(SkillTextGroup)
            {
                ShowCaption = false;
                field(SkillText; SkillTextValue)
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Caption = 'Skill text';
                    ToolTip = 'Specifies the skill instructions. Use visual formatting or edit the Markdown source.';
                    ExtendedDatatype = Markdown;
                    MultiLine = true;
                    Editable = not IsReadOnly;

                    trigger OnValidate()
                    var
                        Skill: Record "Business Skill";
                        BusinessSkillImpl: Codeunit "Business Skill Impl.";
                    begin
                        if IsReadOnly or not CurrPage.Editable() or (SkillId = 0) then
                            Error(ReadOnlyModeErr);
                        BusinessSkillImpl.SetSkillText(SkillId, SkillTextValue, SkillSystemId, SkillRevision);
                        Skill.Get(SkillId);
                        SkillRevision := Skill.SystemRowVersion;
                        LoadSkillSnapshot();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ViewHistory)
            {
                ApplicationArea = All;
                Caption = 'View history';
                ToolTip = 'View earlier versions of the skill text and restore one if needed.';
                Image = History;
                Visible = SkillId <> 0;

                trigger OnAction()
                var
                    TextVersions: Page "Business Skill Text Versions";
                begin
                    TextVersions.SetSkillId(SkillId);
                    Commit();
                    TextVersions.RunModal();
                    if TextVersions.GetRestored() then begin
                        LoadSkillSnapshot();
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(DownloadText)
            {
                ApplicationArea = All;
                Caption = 'Download text';
                ToolTip = 'Download the current skill text to a text file.';
                Image = Export;
                Visible = SkillId <> 0;

                trigger OnAction()
                var
                    TextVersion: Record "Business Skill Text Version";
                    TextHistory: Codeunit "Business Skill Text History";
                begin
                    TextVersion.SetCurrentKey("Skill ID", "Entry No.");
                    TextVersion.SetRange("Skill ID", SkillId);
                    TextVersion.Ascending(false);
                    if TextVersion.FindFirst() then
                        TextHistory.DownloadVersion(TextVersion);
                end;
            }
        }
    }

    /// <summary>
    /// Binds the part to a saved skill and loads its current text. A zero ID renders read-only.
    /// </summary>
    procedure SetSkillId(NewSkillId: BigInteger; AllowEdit: Boolean)
    var
        Skill: Record "Business Skill";
    begin
        IsReadOnly := not AllowEdit;
        if Skill.Get(NewSkillId) then
            IsReadOnly := IsReadOnly or not BusinessSkillImpl.CanEditSkillText(Skill)
        else
            IsReadOnly := true;
        if (SkillId = NewSkillId) and (SkillId <> 0) then
            exit;
        SkillId := NewSkillId;
        LoadSkillSnapshot();
    end;

    procedure RefreshSkill()
    begin
        LoadSkillSnapshot();
    end;

    /// <summary>
    /// Displays arbitrary read-only text (used to preview a historic version).
    /// </summary>
    [NonDebuggable]
    procedure SetReadOnlyText(NewText: SecretText)
    begin
        SkillId := 0;
        IsReadOnly := true;
        SkillTextValue := NewText.Unwrap();
        CurrPage.Update(false);
    end;

    [NonDebuggable]
    local procedure LoadSkillSnapshot()
    var
        Skill: Record "Business Skill";
    begin
        Clear(SkillSystemId);
        Clear(SkillRevision);
        Clear(SkillTextValue);
        if Skill.Get(SkillId) then begin
            SkillSystemId := Skill.SystemId;
            SkillRevision := Skill.SystemRowVersion;
            SkillTextValue := BusinessSkillImpl.GetSkillText(Skill).Unwrap();
        end;
    end;

    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        SkillId: BigInteger;
        SkillSystemId: Guid;
        SkillRevision: BigInteger;
        [NonDebuggable]
        SkillTextValue: Text;
        IsReadOnly: Boolean;
        ReadOnlyModeErr: Label 'This skill text is read-only.';
}
