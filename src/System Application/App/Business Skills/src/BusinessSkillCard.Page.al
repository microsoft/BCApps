// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Agents;
using System.Security.AccessControl;

/// <summary>
/// Creates and edits canonical skill metadata and instructions.
/// The page writes through "Business Skill Management", because the platform table has no table triggers.
/// </summary>
page 4161 "Business Skill Card"
{
    PageType = Card;
    Caption = 'Business Skill';
    SourceTable = "Business Skill";
    DelayedInsert = true;
    Extensible = false;
    ApplicationArea = All;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata User = r;
    DataCaptionExpression = Rec.Title;
    AboutTitle = 'Maintain a business skill';
    AboutText = 'Maintain one canonical skill. New skills are inactive until activated with a title and instructions.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = CanMaintainSkill;

                field("Title"; Rec."Title")
                {
                    Editable = CanMaintainSkill;

                    trigger OnValidate()
                    begin
                        InitializeSkillTextEditor();
                    end;
                }
                field(Description; Rec.Description)
                {
                    MultiLine = true;
                    Editable = CanMaintainSkill;

                    trigger OnValidate()
                    begin
                        InitializeSkillTextEditor();
                    end;
                }
                field("Status"; Rec."Status")
                {
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = IsInactive;
                }
                field("Read-Only"; Rec."Read-Only")
                {
                    Editable = false;
                }
                field(Version; Rec.Version)
                {
                    Importance = Additional;
                    Editable = CanEditVersion;

                    trigger OnValidate()
                    begin
                        InitializeSkillTextEditor();
                    end;
                }
            }
            part(SkillTextEditor; "Business Skill Text Part")
            {
                Caption = 'Skill text';
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Activate)
            {
                Caption = 'Activate';
                ToolTip = 'Set the skill to Active, making it visible to the Business Skill Service.';
                Image = Approve;
                Enabled = CanMaintainSkill;

                trigger OnAction()
                begin
                    ActivateSkill();
                end;
            }
            action(Deactivate)
            {
                Caption = 'Deactivate';
                ToolTip = 'Stop including this skill in discovery without deleting its content.';
                Image = Cancel;
                Enabled = CanMaintainSkill;

                trigger OnAction()
                var
                    BPMgt: Codeunit "Business Skill Management";
                begin
                    CurrPage.SaveRecord();
                    BPMgt.DeactivateSkill(Rec.ID);
                    Rec.Get(Rec.ID);
                    UpdateEditorState();
                    CurrPage.SkillTextEditor.Page.RefreshSkill();
                    CurrPage.Update(false);
                end;
            }
            action(Export)
            {
                Caption = 'Export';
                ToolTip = 'Export this skill to an XML file.';
                Image = Export;
                Enabled = CanExport;

                trigger OnAction()
                var
                    Skill: Record "Business Skill";
                    BusinessSkillPort: Codeunit "Business Skill Port";
                begin
                    Skill.SetRange(ID, Rec.ID);
                    BusinessSkillPort.ExportSkills(Skill);
                end;
            }
            action(CopyToEdit)
            {
                Caption = 'Copy';
                ToolTip = 'Create an editable manual copy with a new skill ID and the current content, starting at version v1.0.';
                Image = Copy;
                Enabled = HasSavedSkill;

                trigger OnAction()
                var
                    Skill: Record "Business Skill";
                    SkillManagement: Codeunit "Business Skill Management";
                begin
                    CurrPage.SaveRecord();
                    Skill.Get(SkillManagement.CopySkill(Rec.ID));
                    Commit();
                    Page.Run(Page::"Business Skill Card", Skill);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ActivateRef; Activate) { }
                actionref(DeactivateRef; Deactivate) { }
                actionref(ExportRef; Export) { }
                actionref(CopyRef; CopyToEdit) { }
            }
        }
    }

    var
        TextHelper: Codeunit "Business Skill Text";
        ActivateOnCloseQst: Label 'This skill is inactive. Do you want to activate it before closing?';
        CanMaintainSkill: Boolean;
        HasSavedSkill: Boolean;
        IsInactive: Boolean;
        CanEditContent: Boolean;
        CanEditVersion: Boolean;
        CanExport: Boolean;

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Skill Text");
        UpdateEditorState();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Manual := true;
        Rec.Status := Rec.Status::Inactive;
        UpdateEditorState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditorState();
        CurrPage.SkillTextEditor.Page.SetSkillId(Rec.ID, CurrPage.Editable() and CanEditContent);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        Builder.Initialize('', Rec.Title, TextHelper.GetSkillText(Rec, false))
            .SetManual(true)
            .SetDescription(Rec.Description)
            .SetContentLocked(Rec."Read-Only")
            .SetActive(Rec.Status = Rec.Status::Active);
        if Rec.Version <> '' then
            Builder.SetContentVersion(Rec.Version);
        Rec.Get(Builder.Create());
        UpdateEditorState();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        BPMgt: Codeunit "Business Skill Management";
    begin
        // The UI owns an optimistic snapshot and a separate text control. Save both atomically,
        // including no-op detection, rather than issuing a second native modify of the stale buffer.
        BPMgt.UpdateSkillRecord(Rec.ID, Rec, TextHelper.GetSkillText(Rec));
        Rec.Get(Rec.ID);
        Rec.SetAutoCalcFields("Skill Text");
        CurrPage.SkillTextEditor.Page.RefreshSkill();
        exit(false);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        BPMgt: Codeunit "Business Skill Management";
    begin
        BPMgt.DeleteSkill(Rec.ID);
        exit(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not CurrPage.Editable() or (Rec.ID = 0) then
            exit(true);
        CurrPage.SaveRecord();
        if Rec.Status = Rec.Status::Inactive then
            if Confirm(ActivateOnCloseQst, false) then
                ActivateSkill();
        exit(true);
    end;

    local procedure ActivateSkill()
    var
        BPMgt: Codeunit "Business Skill Management";
    begin
        CurrPage.SaveRecord();
        BPMgt.ActivateSkill(Rec.ID);
        Rec.Get(Rec.ID);
        UpdateEditorState();
        CurrPage.SkillTextEditor.Page.RefreshSkill();
        CurrPage.Update(false);
    end;

    local procedure InitializeSkillTextEditor()
    begin
        CurrPage.SaveRecord();
        UpdateEditorState();
        CurrPage.SkillTextEditor.Page.SetSkillId(Rec.ID, CurrPage.Editable() and CanEditContent);
        CurrPage.Update(false);
    end;

    local procedure UpdateEditorState()
    var
        SkillManagement: Codeunit "Business Skill Management";
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        HasSavedSkill := Rec.ID <> 0;
        IsInactive := Rec.Status = Rec.Status::Inactive;
        if Rec.ID = 0 then
            CanMaintainSkill := true
        else
            CanMaintainSkill := SkillManagement.SkillExists(Rec.ID);
        CanMaintainSkill := CanMaintainSkill and AgentUtilities.CanCurrentUserManageBusinessSkills();
        CanEditContent := CanMaintainSkill and SkillManagement.CanEditSkillText(Rec);
        CanEditVersion := CanEditContent;
        CanExport := HasSavedSkill and SkillManagement.IsManualSkill(Rec);
    end;

}
