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
                ToolTip = 'Specifies the details of the archive operation.';
                Editable = false;
                MultiLine = true;
            }
            field(DisplayNameConfirmation; EnteredDisplayName)
            {
                ApplicationArea = All;
                Caption = 'Agent display name';
                ToolTip = 'Specifies the display name of the agent to archive.';
            }
        }
    }

    var
        ExpectedDisplayName: Text[80];
        EnteredDisplayName: Text[80];
        ConfirmationPrompt: Text;
        Confirmed: Boolean;
        NameMismatchErr: Label 'The name you entered does not exactly match the agent''s display name.';
        ConfirmationInstructionLbl: Label 'You are about to archive the agent "%1". Once archived, the agent can no longer process new tasks and it cannot be restored. The agent and its existing tasks and logs remain available as read-only for auditing.\\To confirm, type the agent''s display name below.', Comment = '%1 = agent display name';

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

        // Case-sensitive by design: in-memory AL Text "<>" is ordinal, so the user must type the display name exactly.
        if EnteredDisplayName <> ExpectedDisplayName then
            Error(NameMismatchErr);

        Confirmed := true;
        exit(true);
    end;
}
