// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Threading;
using System.Azure.Identity;

pageextension 9805 "Approval Job Queue Entries" extends "Job Queue Entries"
{
    actions
    {
        addafter(ResetStatusWithoutApproval)
        {
            action(ResetStatus)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Status to Ready';
                Image = ResetStatus;
                ToolTip = 'Change the status of the selected entry.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if IsUserDelegated then
                        ApprovalsMgmt.SendForApproval(Rec)
                    else
                        Rec.SetStatus(Rec.Status::Ready);
                end;
            }
        }
        modify(ResetStatusWithoutApproval)
        {
            Enabled = false; // Disable in favor of Reset Status With Approval
            Visible = false;
        }

        addafter(RestartWithoutApproval)
        {
            action(Restart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restart';
                Image = Start;
                ToolTip = 'Stop and start the selected entry.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if IsUserDelegated then
                        ApprovalsMgmt.SendForApproval(Rec)
                    else
                        Rec.Restart();
                end;
            }
        }
        modify(RestartWithoutApproval)
        {
            Enabled = false; // Disable in favor of Restart
            Visible = false;
        }

        addafter(RestartWithoutApproval_Promoted)
        {
            actionref(ResetStatus_Promoted; ResetStatus)
            {
            }
            actionref(Restart_Promoted; Restart)
            {
            }
        }
    }

    var
        IsUserDelegated: Boolean;

    trigger OnOpenPage()
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
    begin
        IsUserDelegated := AzureADGraphUser.IsUserDelegated();
    end;
}
