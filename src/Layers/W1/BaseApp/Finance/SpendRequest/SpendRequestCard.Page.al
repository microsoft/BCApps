// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using System.Automation;
using System.Environment;
using System.Privacy;

page 6841 "Spend Request Card"
{
    Caption = 'Spend Request';
    PageType = Document;
    ApplicationArea = Basic, Suite;
    SourceTable = "Spend Request";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditNo();
                    end;
                }
                field(Type; Rec.Type)
                {
                }
                field("Requested By"; Rec."Requested By")
                {
                }
                field(Purpose; Rec.Purpose)
                {
                    MultiLine = true;
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                }
                field("Total Expected Amount"; Rec."Total Expected Amount")
                {
                    Importance = Promoted;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field(TotalSpentAmount; Rec."Total Spent Amount")
                {
                    Importance = Promoted;
                }
            }
            part(Lines; "Spend Request Subform")
            {
                Caption = 'Lines';
                Editable = Rec.Status = Rec.Status::Open;
                SubPageLink = "Spend Request No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Schedule)
            {
                Caption = 'Schedule';

                field("Expected Start Date"; Rec."Expected Start Date")
                {
                    Importance = Promoted;
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                    Importance = Promoted;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';

                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                    Importance = Promoted;
                }
                field("Approved At"; Rec."Approved/Rejected At")
                {
                    Importance = Promoted;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(StatusGrp)
            {
                Caption = 'Status';
                action(Release)
                {
                    Caption = 'Set status to Released';
                    ToolTip = 'Set the status field to Released so that it can be processed for approval.';
                    ApplicationArea = Basic, Suite;
                    Image = ReleaseDoc;

                    trigger OnAction()
                    begin
                        if Rec.Status = Rec.Status::Released then
                            exit;
                        Rec.Status := Rec.Status::Released;
                        Rec.Modify();
                    end;
                }
                action(Approve)
                {
                    Caption = 'Set status to Approved';
                    ToolTip = 'Manually set the status field to Approved';
                    ApplicationArea = Basic, Suite;
                    Image = Approve;

                    trigger OnAction()
                    begin
                        if Rec.Status = Rec.Status::Approved then
                            exit;
                        Rec.Status := Rec.Status::Approved;
                        Rec."Approved/Rejected At" := CurrentDateTime();
                        Rec."Approved/Rejected by User ID" := UserId();
                        Rec.Modify();
                    end;
                }
                action(Reject)
                {
                    Caption = 'Set status to Rejected';
                    ToolTip = 'Manually set the status field to Rejected';
                    ApplicationArea = Basic, Suite;
                    Image = Reject;

                    trigger OnAction()
                    var
                        Employee: Record Employee;
                    begin
                        if Rec.Status = Rec.Status::Rejected then
                            exit;
                        Rec.TestField(Status, Rec.Status::Released);
                        Rec.Status := Rec.Status::Rejected;
                        Rec."Approved/Rejected At" := CurrentDateTime();
                        Rec."Approved/Rejected by User ID" := UserId();
                        Rec.Modify();
                    end;
                }
                action(ReOpen)
                {
                    Caption = 'Set status to Open';
                    ToolTip = 'Set the status field to Open so that it can be edited.';
                    ApplicationArea = Basic, Suite;
                    Image = ReOpen;

                    trigger OnAction()
                    begin
                        if Rec.Status = Rec.Status::Open then
                            exit;
                        if Rec.Status = Rec.Status::Closed then
                            Error('A closed spend request cannot be reopened.');
                        Rec.CalcFields("Total Spent Amount");
                        if Rec."Total Spent Amount" <> 0 then
                            Error('A spend request with posted expenses cannot be reopened.');
                        Rec.Status := Rec.Status::Open;
                        Rec.Modify();
                    end;
                }
            }
            group("Spend Request Approval")
            {
                /*
                                Caption = 'Request Approval';
                                action(SendApprovalRequest)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Send Approval Request';
                                    Image = SendApprovalRequest;
                                    ToolTip = 'Request approval of the document.';

                                    trigger OnAction()
                                    var
                                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                                    begin
                                        if ApprovalsMgmt.CheckPurchaseApprovalPossible(Rec) then
                                            ApprovalsMgmt.OnSendPurchaseDocForApproval(Rec);
                                    end;
                                }
                                action(CancelApprovalRequest)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Cancel Approval Request';
                                    Image = CancelApprovalRequest;
                                    ToolTip = 'Cancel the approval request.';

                                    trigger OnAction()
                                    var
                                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                                        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
                                    begin
                                        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(Rec);
                                        WorkflowWebhookMgt.FindAndCancel(Rec.RecordId);
                                    end;
                                }
                                */
                group(Flow)
                {
                    Caption = 'Power Automate';
                    Image = Flow;

                    customaction(CreateFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_request';
                    }
                }
            }
        }
    }

    var
        IsSaaS: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
    begin
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
        IsSaaS := EnvironmentInfo.IsSaaS();
    end;
}
