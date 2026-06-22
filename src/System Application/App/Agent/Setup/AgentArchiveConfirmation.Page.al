// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4337 "Agent Archive Confirmation"
{
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    PageType = StandardDialog;
    Caption = 'Archive agent';

    layout
    {
        area(Content)
        {
            field(Instruction; ConfirmationPrompt)
            {
                ApplicationArea = All;
                Caption = 'Confirmation';
                ToolTip = 'Specifies what archiving the agent does and warns that the action cannot be undone.';
                Editable = false;
                MultiLine = true;
            }
            field(DisplayNameConfirmation; EnteredDisplayName)
            {
                ApplicationArea = All;
                Caption = 'Type the display name';
                ToolTip = 'Specifies the agent''s display name. Type it exactly to confirm that you want to archive the agent.';
            }
        }
    }

    var
        ExpectedDisplayName: Text[80];
        EnteredDisplayName: Text[80];
        ConfirmationPrompt: Text;
        Confirmed: Boolean;
        NameMismatchErr: Label 'The name you entered does not match the agent''s display name.';
        ConfirmationInstructionLbl: Label 'You are about to archive the agent "%1". This removes the agent from active use and cannot be undone.\\To confirm, type the agent''s display name below.', Comment = '%1 = agent display name';

    /// <summary>
    /// Sets the agent display name that the user must type to confirm archiving, and builds the confirmation prompt.
    /// </summary>
    /// <param name="DisplayName">The display name of the agent to archive.</param>
    internal procedure SetAgentDisplayName(DisplayName: Text[80])
    begin
        ExpectedDisplayName := DisplayName;
        ConfirmationPrompt := StrSubstNo(ConfirmationInstructionLbl, DisplayName);
    end;

    /// <summary>
    /// Indicates whether the user confirmed the archive operation by typing the matching display name.
    /// </summary>
    /// <returns>True if the user confirmed; otherwise false.</returns>
    internal procedure IsConfirmed(): Boolean
    begin
        exit(Confirmed);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if (EnteredDisplayName = '') or (not IsExactMatch(EnteredDisplayName, ExpectedDisplayName)) then
            Error(NameMismatchErr);

        Confirmed := true;
        exit(true);
    end;

    local procedure IsExactMatch(Entered: Text; Expected: Text): Boolean
    var
        Index: Integer;
    begin
        // AL's Text equality is case-insensitive; compare character-by-character (ordinal/case-sensitive)
        // so the user must type the display name exactly, matching the "type the exact name" design.
        if StrLen(Entered) <> StrLen(Expected) then
            exit(false);
        for Index := 1 to StrLen(Expected) do
            if Entered[Index] <> Expected[Index] then
                exit(false);
        exit(true);
    end;
}
