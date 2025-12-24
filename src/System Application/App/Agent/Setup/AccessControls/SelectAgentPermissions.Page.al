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
    SourceTable = "Access Control Buffer";
    SourceTableTemporary = true;
    Caption = 'Edit Agent Permissions';
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
        BackupAccessControlBuffer();
        CurrPage.PermissionsPart.Page.Initialize(AgentUserSecurityID, Rec);
        CurrPage.PermissionsPart.Page.Update(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::Cancel then
            RestoreAccessControlBuffer();

        exit(true);
    end;

    internal procedure Initialize(NewAgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        AgentUserSecurityID := NewAgentUserSecurityID;
        Rec.Copy(TempAccessControlBuffer, true);
    end;

    internal procedure GetTempAccessControlBuffer(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        TempAccessControlBuffer.Copy(Rec, true);
    end;

    local procedure BackupAccessControlBuffer()
    begin
        TempBackupAccessControlBuffer.Reset();
        TempBackupAccessControlBuffer.DeleteAll();

        Rec.Reset();
        if not Rec.FindSet() then
            exit;

        repeat
            TempBackupAccessControlBuffer.TransferFields(Rec);
            TempBackupAccessControlBuffer.Insert();
        until Rec.Next() = 0;
    end;

    local procedure RestoreAccessControlBuffer()
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempBackupAccessControlBuffer.Reset();
        if not TempBackupAccessControlBuffer.FindSet() then
            exit;

        repeat
            Rec.TransferFields(TempBackupAccessControlBuffer);
            Rec.Insert();
        until TempBackupAccessControlBuffer.Next() = 0;
    end;

    var
        TempBackupAccessControlBuffer: Record "Access Control Buffer" temporary;
        AgentUserSecurityID: Guid;
}