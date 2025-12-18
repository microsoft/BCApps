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
        BackupAgentAccessControl();
        CurrPage.AccessControlPart.Page.SetAgentUserSecurityID(AgentUserSecurityID);
        CurrPage.AccessControlPart.Page.SetTempAgentAccessControl(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::LookupCancel then
            RestoreAgentAccessControl();

        exit(true);
    end;

    internal procedure SetTempAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        Rec.Copy(TempAgentAccessControl, true);
    end;

    internal procedure GetTempAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        TempAgentAccessControl.Copy(Rec, true);
    end;

    internal procedure SetAgentUserSecurityID(UserSecurityID: Guid)
    var
        AgentImpl: Codeunit "Agent Impl.";
        GlobalSingleCompanyName: Text[30];
    begin
        AgentUserSecurityID := UserSecurityID;
        ShowCompanyField := not AgentImpl.TryGetAccessControlForSingleCompany(AgentUserSecurityID, GlobalSingleCompanyName);
    end;

    local procedure BackupAgentAccessControl()
    begin
        TempBackupAgentAccessControl.Copy(Rec, true);
    end;

    local procedure RestoreAgentAccessControl()
    begin
        Rec.Copy(TempBackupAgentAccessControl, true);
    end;

    var
        TempBackupAgentAccessControl: Record "Agent Access Control" temporary;
        AgentUserSecurityID: Guid;
        ShowCompanyField: Boolean;
}