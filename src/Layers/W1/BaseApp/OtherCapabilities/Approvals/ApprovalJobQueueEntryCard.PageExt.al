// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Threading;
using System.Azure.Identity;
using System.Telemetry;

pageextension 9806 "Approval Job Queue Entry Card" extends "Job Queue Entry Card"
{
    actions
    {
        addafter("Set Status to Ready Without Approval")
        {
            action("Set Status to Ready")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Status to Ready';
                Image = ResetStatus;
                ToolTip = 'Change the status of the entry.';
                Enabled = not IsPendingApproval;

                trigger OnAction()
                var
                    AuditLog: Codeunit "Audit Log";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    SetStatustoReadyActivatedLbl: Label 'UserSecurityId %1 set the Status of the job queue entry %2 to Ready.', Locked = true;
                begin
                    if IsUserDelegated then begin
                        ApprovalsMgmt.SendForApproval(Rec);
                        CurrPage.Update(false);
                    end else begin
                        Rec.SetStatus(Rec.Status::Ready);
                        AuditLog.LogAuditMessage(StrSubstNo(SetStatustoReadyActivatedLbl, UserSecurityId(), Rec."Entry No."), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
                    end;
                end;
            }
        }
        modify("Set Status to Ready Without Approval")
        {
            Enabled = false; // Disable in favor of Set Status to Ready With Approval
            Visible = false;
        }

        addafter("Job &Queue")
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                Visible = IsUserDelegated;

                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not IsPendingApproval and IsUserDelegated;
                    Visible = IsUserDelegated;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the job queue entry.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.SendForApproval(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = IsPendingApproval and IsUserDelegated;
                    Visible = IsUserDelegated;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelJobQueueEntryApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(Rec.RecordId);
                    end;
                }
            }
        }
        addafter(Category_Report)
        {
            group(Category_Approvals)
            {
                Caption = 'Approvals';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
        }
        addafter("Set Status to Ready Without Approval_Promoted")
        {
            actionref("Set Status to Ready_Promoted"; "Set Status to Ready")
            {
            }
        }
    }

    var
        IsPendingApproval: Boolean;
        IsUserDelegated: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if IsUserDelegated then
            IsPendingApproval := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId());
    end;

    trigger OnOpenPage()
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        IsUserDelegated := AzureADGraphUser.IsUserDelegated();
    end;
}