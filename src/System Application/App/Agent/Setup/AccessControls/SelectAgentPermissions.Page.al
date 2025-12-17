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
    Caption = 'Edit Agent Permissions (Preview)';
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

        CurrPage.PermissionsPart.Page.SetTempAccessControlBuffer(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempModifiedAccessControlBuffer: Record "Access Control Buffer" temporary;
    begin
        if CloseAction = CloseAction::LookupCancel then
            RestoreAccessControlBuffer()
        else if CloseAction = CloseAction::OK then begin
            CurrPage.PermissionsPart.Page.GetTempAccessControlBuffer(TempModifiedAccessControlBuffer);
            SaveChangesToAccessControl(TempModifiedAccessControlBuffer);
        end;

        exit(true);
    end;

    internal procedure Load(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempAccessControlBuffer.Reset();
        if not TempAccessControlBuffer.FindSet() then
            exit;

        repeat
            Rec.TransferFields(TempAccessControlBuffer);
            Rec.Insert();
        until TempAccessControlBuffer.Next() = 0;

        AgentUserSecurityID := UserSecurityID;
    end;

    internal procedure SetAgentUserSecurityID(UserSecurityID: Guid)
    begin
        AgentUserSecurityID := UserSecurityID;
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

    local procedure SaveChangesToAccessControl(var TempModifiedAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        // Delete all existing access control records for the agent
        AccessControl.SetRange("User Security ID", AgentUserSecurityID);
        AccessControl.DeleteAll();

        // Insert the modified records
        TempModifiedAccessControlBuffer.Reset();
        if not TempModifiedAccessControlBuffer.FindSet() then
            exit;

        repeat
            Clear(AccessControl);
            AccessControl."User Security ID" := AgentUserSecurityID;
            AccessControl."Role ID" := TempModifiedAccessControlBuffer."Role ID";
            AccessControl."Company Name" := TempModifiedAccessControlBuffer."Company Name";
            AccessControl.Scope := TempModifiedAccessControlBuffer.Scope;
            AccessControl."App ID" := TempModifiedAccessControlBuffer."App ID";
            AccessControl.Insert();
        until TempModifiedAccessControlBuffer.Next() = 0;
    end;

    var
        TempBackupAccessControlBuffer: Record "Access Control Buffer" temporary;
        AgentUserSecurityID: Guid;
}