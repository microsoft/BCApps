// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.User;

page 4322 "Select Agent Permissions"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = Agent;
    Caption = 'Edit Agent Permissions (Preview)';
    DataCaptionExpression = '';
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            group(Info)
            {
                ShowCaption = false;
                InstructionalText = 'During task execution, the agent permissions are intersected with the permissions of the user creating or approving the task. The agent can then only operate within the boundaries of both permission sets.';
            }

            part(Permissions; "User Subform")
            {
                Editable = true;
                Caption = 'Agent Permissions';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Permissions.Page.SetAgentPermissionEditMode();
    end;
}