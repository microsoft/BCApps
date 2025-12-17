// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;

page 4321 "Select Agent Access Control"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "Agent Access Control";
    SourceTableTemporary = true;
    Caption = 'Select users to manage tasks and configure the agent';
    MultipleNewLines = false;
    Extensible = false;
    DataCaptionExpression = '';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AccessControlPart; "Select Agent Acc. Control Part")
            {
                Caption = 'Agent Access Control';
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Ensure Load and SetAgentUserSecurityID were called before opening
        if IsNullGuid(AgentUserSecurityID) then
            Error('Agent User Security ID must be set before opening this page.');

        BackupAgentAccessControl();
        CurrPage.AccessControlPart.Page.SetAgentUserSecurityID(AgentUserSecurityID);
        CurrPage.AccessControlPart.Page.SetTempAgentAccessControl(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempModifiedAgentAccessControl: Record "Agent Access Control" temporary;
    begin
        if CloseAction = CloseAction::LookupCancel then
            RestoreAgentAccessControl()
        else if CloseAction = CloseAction::OK then begin
            CurrPage.AccessControlPart.Page.GetTempAgentAccessControl(TempModifiedAgentAccessControl);
            SaveChangesToAgentAccessControl(TempModifiedAgentAccessControl);
        end;

        exit(true);
    end;

    internal procedure Load(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempAgentAccessControl.Reset();
        if not TempAgentAccessControl.FindSet() then
            exit;

        repeat
            Rec.TransferFields(TempAgentAccessControl);
            Rec.Insert();
        until TempAgentAccessControl.Next() = 0;
    end;

    internal procedure SetAgentUserSecurityID(UserSecurityID: Guid)
    begin
        AgentUserSecurityID := UserSecurityID;
        AgentAccessControlMgt.Initialize(AgentUserSecurityID);
        ShowCompanyField := AgentAccessControlMgt.GetShowCompanyField();
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

    local procedure SaveChangesToAgentAccessControl(var TempModifiedAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        // Delete all existing access control records for the agent
        AgentAccessControl.SetRange("Agent User Security ID", AgentUserSecurityID);
        if AgentAccessControl.FindSet() then
            repeat
            until AgentAccessControl.Delete();

        // Insert the modified records
        TempModifiedAgentAccessControl.Reset();
        if not TempModifiedAgentAccessControl.FindSet() then
            exit;

        repeat
            Clear(AgentAccessControl);
            AgentAccessControl.TransferFields(TempModifiedAgentAccessControl);
            AgentAccessControl.Insert();
        until TempModifiedAgentAccessControl.Next() = 0;
    end;

    var
        AgentAccessControlMgt: Codeunit "Agent Access Control Mgt.";
        TempBackupAgentAccessControl: Record "Agent Access Control" temporary;
        AgentUserSecurityID: Guid;
        ShowCompanyField: Boolean;
}