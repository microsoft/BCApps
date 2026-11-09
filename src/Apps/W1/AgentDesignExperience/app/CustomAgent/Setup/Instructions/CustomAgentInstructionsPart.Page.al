// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Designer.CustomAgent;

page 4353 "Custom Agent Instructions Part"
{
    PageType = CardPart;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Designer - Instructions';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                ShowCaption = false;
                field(InstructionsText; InstructionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Instructions';
                    ToolTip = 'Specifies what the agent should do, its tone, and the rules and guidelines it must follow. Use visual formatting or edit the Markdown source.';
                    ExtendedDatatype = Markdown;
                    MultiLine = true;
                    Editable = not IsReadOnly;

                    trigger OnValidate()
                    begin
                        if IsReadOnly or not CurrPage.Editable() then
                            Error(ReadOnlyModeErr);
                        if InstructionsTxt.Trim() = '' then
                            Error(InstructionsCannotBeEmptyErr);
                        if StrLen(InstructionsTxt) > 30000 then
                            Error(InstructionsTooLongErr, 30000);

                        if not IsTemporary then
                            GlobalCustomAgentSetup.SetInstructions(InstructionsTxt);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SaveAsVersion)
            {
                ApplicationArea = All;
                Caption = 'Save to history';
                ToolTip = 'Save the current instructions as a new version with a custom name.';
                Image = Save;
                Visible = not IsReadOnly and InstructionsHistoryVisible;

                trigger OnAction()
                var
                    CustomAgentInstructions: Codeunit "Custom Agent Instructions";
                begin
                    CustomAgentInstructions.SaveInstructionsAsNewVersion(InstructionsTxt, GlobalUserSecurityId);
                end;
            }
            action(ViewHistory)
            {
                ApplicationArea = All;
                Caption = 'View history';
                ToolTip = 'View the history of changes made to the agent instructions and restore an earlier version if needed.';
                Visible = InstructionsHistoryVisible;
                Image = History;

                trigger OnAction()
                var
                    CustomAgentInstructionsLog: Page "Cust. Agent Instructions Log";
                begin
                    CustomAgentInstructionsLog.SetGlobalAgentUserSecurityId(GlobalUserSecurityId);
                    CustomAgentInstructionsLog.RunModal();
                    if CustomAgentInstructionsLog.GetRestoredPreviousVersionOfInstructions() then
                        RefreshInstructions();
                end;
            }
            action(DownloadInstructions)
            {
                ApplicationArea = All;
                Caption = 'Download instructions';
                ToolTip = 'Download the current agent instructions to a text file.';
                Image = Export;

                trigger OnAction()
                var
                    CustomAgentInstructions: Codeunit "Custom Agent Instructions";
                begin
                    CustomAgentInstructions.DownloadCurrentInstructions(InstructionsTxt);
                end;
            }
            action(HowToWriteInstructions)
            {
                ApplicationArea = All;
                Caption = 'How to write instructions';
                ToolTip = 'Opens a web page that provides more information about defining instructions and building agents.';
                Image = Help;
                Enabled = not IsReadOnly;

                trigger OnAction()
                var
                    CustomAgentInstructions: Codeunit "Custom Agent Instructions";
                begin
                    Hyperlink(CustomAgentInstructions.GetHowToWriteInstructionsUrl());
                end;
            }
        }
    }

    internal procedure SetUserSecurityId(UserSecId: Guid)
    begin
        GlobalUserSecurityId := UserSecId;
        InstructionsHistoryVisible := not IsNullGuid(GlobalUserSecurityId);
        RefreshInstructions();
    end;

    internal procedure GetInstructions(): Text
    begin
        exit(InstructionsTxt);
    end;

    internal procedure SetInstructions(NewInstructions: Text): Text
    begin
        InstructionsTxt := NewInstructions;
        CurrPage.Update(false);
    end;

    internal procedure SetReadOnlyMode(ReadOnly: Boolean)
    begin
        IsReadOnly := ReadOnly;
        if ReadOnly then
            CurrPageCaption := ViewAgentInstructionsLbl
        else
            CurrPageCaption := EditAgentInstructionsLbl;
    end;

    internal procedure SetIsTemporary(NewIsTemporary: Boolean)
    begin
        IsTemporary := NewIsTemporary;
    end;

    internal procedure SetInstructionsHistoryVisible(NewVisible: Boolean)
    begin
        InstructionsHistoryVisible := NewVisible;
    end;

    internal procedure RefreshInstructions()
    begin
        if not IsNullGuid(GlobalUserSecurityId) then begin
            GlobalCustomAgentSetup.Get(GlobalUserSecurityId);
            GlobalCustomAgentSetup.TryGetInstructions(GlobalUserSecurityId, InstructionsTxt);
        end;

        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    begin
        if not InstructionsHistoryVisible then
            InstructionsHistoryVisible := not IsNullGuid(GlobalUserSecurityId);

        if CurrPageCaption <> '' then
            CurrPage.Caption := CurrPageCaption;
    end;

    var
        GlobalCustomAgentSetup: Record "Custom Agent Setup";
        InstructionsHistoryVisible: Boolean;
        EditAgentInstructionsLbl: Label 'Edit agent instructions';
        ViewAgentInstructionsLbl: Label 'View agent instructions';
        ReadOnlyModeErr: Label 'This page is in view-only mode. Instructions cannot be modified.';
        InstructionsTxt: Text;
        GlobalUserSecurityId: Guid;
        IsReadOnly: Boolean;
        IsTemporary: Boolean;
        CurrPageCaption: Text;
        InstructionsCannotBeEmptyErr: Label 'Instructions cannot be empty.';
        InstructionsTooLongErr: Label 'Instructions cannot exceed %1 characters.', Comment = '%1 = maximum instruction length';
}
