// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Hosts the native Markdown field for a business skill's instructions.
/// Editable only for a saved skill the caller may maintain; otherwise read-only, including previews.
/// </summary>
page 4163 "Business Skill Content Part"
{
    PageType = CardPart;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Business Skill Content';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(SkillContentGroup)
            {
                ShowCaption = false;
                field(SkillContent; SkillContentValue)
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Caption = 'Skill content';
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
                        BusinessSkillImpl.SetContent(SkillId, SkillContentValue, SkillSystemId, SkillRevision);
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
                ToolTip = 'View earlier versions of the skill content and restore one if needed.';
                Image = History;
                Visible = IsManualSkill;

                trigger OnAction()
                var
                    BusSkillContentVersions: Page "Bus Skill Content Versions";
                begin
                    BusSkillContentVersions.SetSkillId(SkillId);
                    Commit();
                    BusSkillContentVersions.RunModal();
                    if BusSkillContentVersions.GetRestored() then begin
                        LoadSkillSnapshot();
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(DownloadContent)
            {
                ApplicationArea = All;
                Caption = 'Download content';
                ToolTip = 'Download the current skill content to a text file.';
                Image = Export;
                Visible = SkillId <> 0;

                trigger OnAction()
                begin
                    BusinessSkillImpl.DownloadContent(SkillId);
                end;
            }
        }
    }

    /// <summary>
    /// Binds the part to a saved skill and loads its current content. A zero ID renders read-only.
    /// </summary>
    procedure SetSkillId(NewSkillId: BigInteger; AllowEdit: Boolean)
    var
        Skill: Record "Business Skill";
    begin
        IsReadOnly := not AllowEdit;
        if Skill.Get(NewSkillId) then
            IsReadOnly := IsReadOnly or not BusinessSkillImpl.CanEditContent(Skill)
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
    /// Displays arbitrary read-only content (used to preview a historic version).
    /// </summary>
    [NonDebuggable]
    procedure SetReadOnlyContent(NewContent: SecretText)
    begin
        SkillId := 0;
        IsManualSkill := false;
        IsReadOnly := true;
        SkillContentValue := NewContent.Unwrap();
        CurrPage.Update(false);
    end;

    [NonDebuggable]
    local procedure LoadSkillSnapshot()
    var
        Skill: Record "Business Skill";
    begin
        Clear(SkillSystemId);
        Clear(SkillRevision);
        Clear(SkillContentValue);
        IsManualSkill := false;
        if Skill.Get(SkillId) then begin
            IsManualSkill := Skill.Manual;
            SkillSystemId := Skill.SystemId;
            SkillRevision := Skill.SystemRowVersion;
            SkillContentValue := BusinessSkillImpl.GetContent(Skill).Unwrap();
        end;
    end;

    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        SkillId: BigInteger;
        SkillSystemId: Guid;
        SkillRevision: BigInteger;
        [NonDebuggable]
        SkillContentValue: Text;
        IsReadOnly: Boolean;
        IsManualSkill: Boolean;
        ReadOnlyModeErr: Label 'This skill content is read-only.';
}
