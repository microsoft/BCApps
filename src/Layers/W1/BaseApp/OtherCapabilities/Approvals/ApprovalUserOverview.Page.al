// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;
using System.Security.User;

page 30441 "Approval User Overview"
{
    ApplicationArea = All;
    Caption = 'Approval User Overview';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SourceTable = Workflow;
    SourceTableTemporary = true;
    SourceTableView = where(Enabled = const(true));
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Workflows)
            {
                Caption = 'Workflows';
                repeater(control1)
                {
                    field(Code; Rec.Code)
                    {
                        ToolTip = 'Specifies the workflow code.';
                    }
                    field(Description; Rec.Description)
                    {
                        ToolTip = 'Specifies the workflow description.';
                    }
                }
            }
            group(Approvers)
            {
                Caption = 'Approvers';

                part("Approval Users"; "Approval Users")
                {
                    Visible = ApprovalUsers;
                }
                part("Workflow User Group Members"; "Workflow User Group Members")
                {
                    Visible = UserGroupApproval;
                }

            }
        }
    }
    trigger OnOpenPage()
    begin
        LoadWorkflows();
    end;

    trigger OnAfterGetCurrRecord()
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
        UserSetup: Record "User Setup";
    begin
        WorkflowApproversBuffer.SetRange(WorkflowCode, Rec.Code);
        if WorkflowApproversBuffer.FindFirst() then
            if WorkflowApproversBuffer.ApproverType = WorkflowApproversBuffer.ApproverType::"Workflow User Group" then begin
                UserGroupApproval := true;
                ApprovalUsers := false;

                WorkflowUserGroupMember.SetRange("Workflow User Group Code", WorkflowApproversBuffer.UserGroupCode);
                CurrPage."Workflow User Group Members".Page.SetTableView(WorkflowUserGroupMember);
                CurrPage."Approval Users".Page.Update(false);
            end else begin
                ApprovalUsers := true;
                UserGroupApproval := false;

                UserSetup.Reset();
                if WorkflowApproversBuffer.ApproverLimitType = WorkflowApproversBuffer.ApproverLimitType::"Specific Approver" then
                    UserSetup.SetRange("User ID", WorkflowApproversBuffer.UserName);
                CurrPage."Approval Users".Page.SetTableView(UserSetup);
                CurrPage."Approval Users".Page.SetAmountsVisible(true);
                CurrPage."Approval Users".Page.SetWorkflowType(WorkflowApproversBuffer.WorkflowType);
                CurrPage."Approval Users".Page.Update(false);
            end;
    end;

    procedure LoadWorkflows()
    var
        Workflow: Record Workflow;
    begin
        WorkflowApproversBuffer.FillBuffer();
        Workflow.SetRange(Enabled, true);
        if Workflow.FindSet() then
            repeat
                WorkflowApproversBuffer.SetRange(WorkflowCode, Workflow.Code);
                if WorkflowApproversBuffer.FindFirst() then begin
                    Rec.TransferFields(Workflow);
                    Rec.Insert();
                end;
            until Workflow.Next() = 0;
    end;

    var
        WorkflowApproversBuffer: Record "Workflow Approvers Buffer";
        ApprovalUsers: Boolean;
        UserGroupApproval: Boolean;
}