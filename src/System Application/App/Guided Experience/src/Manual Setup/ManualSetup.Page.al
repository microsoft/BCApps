// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

/// <summary>This page shows all registered manual setups.</summary>
page 1875 "Manual Setup"
{
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Manual Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Guided Experience Item";
    SourceTableTemporary = true;
    UsageCategory = Administration;
    ContextSensitiveHelpPage = 'setup';
    Permissions = tabledata "Guided Experience Item" = r;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;

                field(Name; Rec."Short Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the manual setup.';
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        RunPage();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the manual setup.';
                }
                field(ExtensionName; Rec."Extension Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the extension which has added this setup.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Open Manual Setup")
            {
                ApplicationArea = All;
                Caption = 'Open Manual Setup';
                Image = Edit;
                Scope = Repeater;
                ShortcutKey = 'Return';
                ToolTip = 'View or edit the setup for the application feature.';
                Enabled = (Rec."Object Type to Run" = Rec."Object Type to Run"::Page) and (Rec."Object ID to Run" <> 0);

                trigger OnAction()
                begin
                    RunPage();
                end;
            }
        }
    }

    var
        ManualSetupCategory: Enum "Manual Setup Category";
        NameIndent: Integer;
        FilterSet: Boolean;
        NameEmphasize: Boolean;

    trigger OnOpenPage()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceImpl: Codeunit "Guided Experience Impl.";
    begin
        GuidedExperience.OnRegisterManualSetup();
        GuidedExperienceImpl.GetContentForManualSetup(Rec);
        Rec.SetCurrentKey("Manual Setup Category");

        if FilterSet then
            Rec.SetRange("Manual Setup Category", ManualSetupCategory);

        if Rec.FindFirst() then; // Set selected record to first record
    end;

    trigger OnAfterGetRecord()
    var
        GuidedExperienceImpl: Codeunit "Guided Experience Impl.";
    begin
        if GuidedExperienceImpl.IsAssistedSetupSetupRecord(Rec) then
            SetPageVariablesForSetupRecord()
        else
            SetPageVariablesForSetupGroup();
    end;

    local procedure RunPage()
    begin
        if (Rec."Object Type to Run" = Rec."Object Type to Run"::Page) and (Rec."Object ID to Run" <> 0) then
            Page.Run(Rec."Object ID to Run");
    end;

    local procedure SetPageVariablesForSetupRecord()
    begin
        NameIndent := 1;
        NameEmphasize := false;
    end;

    local procedure SetPageVariablesForSetupGroup()
    begin
        NameEmphasize := true;
        NameIndent := 0;
    end;

    internal procedure SetCategoryToDisplay(ManualSetupCategoryValue: Enum "Manual Setup Category")
    begin
        FilterSet := true;
        ManualSetupCategory := ManualSetupCategoryValue;
    end;
}


