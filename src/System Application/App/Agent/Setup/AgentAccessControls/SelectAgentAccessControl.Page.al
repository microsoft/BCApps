// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4321 "Select Agent Access Control"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
    SourceTableTemporary = true;
    Caption = 'Select users to manage tasks and configure the agent';
    Extensible = false;
    DataCaptionExpression = '';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AccessControlPart; "Select Agent Access Ctrl Part")
            {
                Caption = 'Agent Access Control';
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        BackupAgentAccessControl();
        CurrPage.AccessControlPart.Page.Initialize(AgentUserSecurityID, Rec);
        CurrPage.AccessControlPart.Page.Update(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::Cancel then
            RestoreAgentAccessControl();

        exit(true);
    end;

    internal procedure Initialize(NewAgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        Rec.Copy(TempAgentAccessControl, true);
    end;

    internal procedure GetTempAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        TempAgentAccessControl.Copy(Rec, true);
    end;

    local procedure BackupAgentAccessControl()
    begin
        TempBackupAgentAccessControl.Reset();
        TempBackupAgentAccessControl.DeleteAll();

        Rec.Reset();
        if not Rec.FindSet() then
            exit;

        repeat
            TempBackupAgentAccessControl.TransferFields(Rec);
            TempBackupAgentAccessControl.Insert();
        until Rec.Next() = 0;
    end;

    local procedure RestoreAgentAccessControl()
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempBackupAgentAccessControl.Reset();
        if not TempBackupAgentAccessControl.FindSet() then
            exit;

        repeat
            Rec.TransferFields(TempBackupAgentAccessControl);
            Rec.Insert();
        until TempBackupAgentAccessControl.Next() = 0;
    end;

    var
        TempBackupAgentAccessControl: Record "Agent Access Control" temporary;
        AgentUserSecurityID: Guid;
}