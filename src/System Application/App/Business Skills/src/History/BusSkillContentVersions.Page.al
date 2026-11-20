// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Security.AccessControl;

/// <summary>
/// Read-only history of a business skill's content. Lets the user preview earlier versions, restore one
/// as the current content, download or delete versions. The latest (current) version cannot be deleted.
/// </summary>
page 4162 "Bus Skill Content Versions"
{
    ApplicationArea = All;
    PageType = Worksheet;
    LinksAllowed = false;
    Caption = 'Business Skill Content History';
    SourceTable = "Bus Skill Content Version";
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    DataCaptionExpression = '';
    Permissions = tabledata User = r;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(MainGroup)
            {
                ShowCaption = false;

                repeater(Versions)
                {
                    field(ContentVersion; Rec."Content Version")
                    {
                        StyleExpr = StyleExpression;
                    }
                    field(CreatedAt; Rec.SystemCreatedAt)
                    {
                        Caption = 'Created at';
                        ToolTip = 'Specifies the date and time when this version was created.';
                        StyleExpr = StyleExpression;
                    }
                    field(CreatedBy; CreatedByName)
                    {
                        Caption = 'Created by';
                        ToolTip = 'Specifies the user who created this version.';
                        StyleExpr = StyleExpression;
                    }
                    field(IsCurrent; IsLatest)
                    {
                        Caption = 'Current';
                        ToolTip = 'Specifies whether this is the current (latest) version of the skill content.';
                        StyleExpr = StyleExpression;
                    }
                }
                group(ContentGroup)
                {
                    ShowCaption = false;

                    part(ContentPreview; "Business Skill Content Part")
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Skill content (read-only)';
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SetAsCurrent)
            {
                ApplicationArea = All;
                Caption = 'Set as current';
                ToolTip = 'Restore this version as the current skill content.';
                Image = Restore;
                Enabled = CanRestore;

                trigger OnAction()
                var
                    BusinessSkillContentHistory: Codeunit "Business Skill Content History";
                begin
                    if IsLatest then begin
                        CurrPage.Close();
                        exit;
                    end;
                    BusinessSkillContentHistory.RestoreVersion(Rec."Entry No.");
                    Restored := true;
                    CurrPage.Close();
                end;
            }
            action(DownloadVersion)
            {
                ApplicationArea = All;
                Caption = 'Download';
                ToolTip = 'Download the selected version to a text file.';
                Image = Export;

                trigger OnAction()
                var
                    BusinessSkillContentHistory: Codeunit "Business Skill Content History";
                begin
                    BusinessSkillContentHistory.DownloadVersion(Rec);
                end;
            }
            action(DeleteVersion)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                ToolTip = 'Delete the selected version. The current (latest) version cannot be deleted.';
                Image = Delete;
                Enabled = CanChange;

                trigger OnAction()
                var
                    BusinessSkillContentHistory: Codeunit "Business Skill Content History";
                begin
                    if not Confirm(DeleteConfirmQst) then
                        exit;
                    BusinessSkillContentHistory.DeleteVersion(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SetAsCurrent_Promoted; SetAsCurrent) { }
                actionref(DownloadVersion_Promoted; DownloadVersion) { }
                actionref(DeleteVersion_Promoted; DeleteVersion) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Skill ID", "Entry No.");
        Rec.SetRange("Skill ID", SkillId);
        Rec.Ascending(false);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateComputedFields();
    end;

    trigger OnAfterGetCurrRecord()
    var
        Skill: Record "Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        UpdateComputedFields();
        CanChange := (Rec."Entry No." <> 0) and not IsLatest and Skill.Get(Rec."Skill ID");
        CanRestore := CanChange and BusinessSkillImpl.CanEditContent(Skill);
        if Rec."Entry No." <> xRec."Entry No." then
            UpdatePreview();
    end;

    local procedure UpdateComputedFields()
    var
        BusinessSkillContentHistory: Codeunit "Business Skill Content History";
    begin
        IsLatest := BusinessSkillContentHistory.IsLatestVersion(Rec);
        CreatedByName := GetUserName(Rec.SystemCreatedBy);
        if IsLatest then
            StyleExpression := 'Strong'
        else
            StyleExpression := '';
    end;

    local procedure UpdatePreview()
    begin
        CurrPage.ContentPreview.Page.SetReadOnlyContent(Rec.GetContent());
    end;

    local procedure GetUserName(UserSecId: Guid): Text
    var
        User: Record User;
    begin
        if IsNullGuid(UserSecId) or not User.ReadPermission() then
            exit('');
        User.SetRange("User Security ID", UserSecId);
        if User.FindFirst() then
            exit(User."User Name");
        exit('');
    end;

    /// <summary>
    /// Filters the history to a single skill. Call before running the page.
    /// </summary>
    procedure SetSkillId(NewSkillId: BigInteger)
    begin
        SkillId := NewSkillId;
    end;

    /// <summary>
    /// Returns whether the user restored an earlier version during this session.
    /// </summary>
    procedure GetRestored(): Boolean
    begin
        exit(Restored);
    end;

    var
        SkillId: BigInteger;
        IsLatest: Boolean;
        CanChange: Boolean;
        CanRestore: Boolean;
        Restored: Boolean;
        StyleExpression: Text;
        CreatedByName: Text;
        DeleteConfirmQst: Label 'Delete the selected skill content version?';
}
