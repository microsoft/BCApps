// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Lists canonical skills and opens the skill card for standard creation and editing.
/// The page writes through "Business Skill Management", because the platform table has no table triggers.
/// </summary>
page 4160 "Business Skills"
{
    PageType = List;
    RefreshOnActivate = true;
    Caption = 'Business Skills';
    SourceTable = "Business Skill";
    CardPageId = "Business Skill Card";
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Extensible = true;
    ApplicationArea = All;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'Business Skill, policies, workflows, skills';
    InherentEntitlements = X;
    InherentPermissions = X;
    AboutTitle = 'About business skills';
    AboutText = 'Open a skill card to edit the skill.';

    layout
    {
        area(Content)
        {
            repeater(Skills)
            {
                field(ID; Rec.ID)
                {
                    Visible = false;
                }
                field(Title; Rec.Title) { Editable = false; }
                field(Description; Rec.Description) { Editable = false; }
                field(Status; Rec.Status) { Editable = false; }
                field("Read-Only"; Rec."Read-Only") { Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Import)
            {
                Caption = 'Import';
                ToolTip = 'Import skills from an XML file. Imported skills are manual skills with new skill IDs.';
                Image = Import;

                trigger OnAction()
                var
                    BusinessSkillPort: Codeunit "Business Skill Port";
                begin
                    BusinessSkillPort.ImportSkills();
                    CurrPage.Update(false);
                end;
            }
            action(Export)
            {
                Caption = 'Export';
                ToolTip = 'Export the selected manual skills to an XML file.';
                Image = Export;

                trigger OnAction()
                var
                    Skill: Record "Business Skill";
                    BusinessSkillPort: Codeunit "Business Skill Port";
                begin
                    CurrPage.SetSelectionFilter(Skill);
                    BusinessSkillPort.ExportSkills(Skill);
                end;
            }
            action(CopyToEdit)
            {
                Caption = 'Copy';
                ToolTip = 'Create an editable manual copy with a new skill ID and the current content, starting at version v1.0.';
                Image = Copy;
                Enabled = Rec.ID <> 0;

                trigger OnAction()
                var
                    Skill: Record "Business Skill";
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
            group(ExportImport)
            {
                Caption = 'Export';
                ShowAs = SplitButton;

                actionref(ExportRef; Export) { }
                actionref(ImportRef; Import) { }
            }
            actionref(CopyRef; CopyToEdit) { }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Builder: Codeunit "Business Skill Builder";
        TextHelper: Codeunit "Business Skill Text";
    begin
        Builder.Initialize('', Rec.Title, TextHelper.GetSkillText(Rec, false))
            .SetManual(true)
            .SetDescription(Rec.Description)
            .SetContentLocked(Rec."Read-Only")
            .SetActive(Rec.Status = Rec.Status::Active);
        if Rec.Version <> '' then
            Builder.SetContentVersion(Rec.Version);
        Rec.Get(Builder.Create());
        exit(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        SkillManagement.DeleteSkill(Rec.ID);
        exit(false);
    end;

    var
        SkillManagement: Codeunit "Business Skill Management";
}
