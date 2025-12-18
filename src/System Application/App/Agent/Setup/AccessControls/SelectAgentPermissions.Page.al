// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4336 "Select Agent Permissions"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "Access Control";
    SourceTableTemporary = true;
    Caption = 'Edit Agent Permissions (Preview)';
    Extensible = false;
    DataCaptionExpression = '';
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            label(Info)
            {
                Caption = 'Agent tasks use permissions shared by both the agent and the task creator/approver.';
            }
            part(PermissionsPart; "Select Agent Permissions Part")
            {
                Caption = 'Agent permissions';
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        BackupAccessControl();
        CurrPage.PermissionsPart.Page.Initialize(AgentUserSecurityID, Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::LookupCancel then
            RestoreAccessControl();

        exit(true);
    end;

    internal procedure Initialize(NewAgentUserSecurityID: Guid; var TempAccessControl: Record "Access Control" temporary)
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        Rec.Copy(TempAccessControl, true);
    end;

    internal procedure GetTempAccessControl(var TempAccessControl: Record "Access Control" temporary)
    begin
        TempAccessControl.Copy(Rec, true);
    end;

    local procedure BackupAccessControl()
    begin
        TempBackupAccessControl.Copy(Rec, true);
    end;

    local procedure RestoreAccessControl()
    begin
        Rec.Copy(TempBackupAccessControl, true);
    end;

    var
        TempBackupAccessControl: Record "Access Control" temporary;
        AgentUserSecurityID: Guid;
}