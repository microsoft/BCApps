// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Security.User;

page 30436 "Approval Users"
{
    ApplicationArea = All;
    Caption = 'Approval Users';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "User Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the salesperson or purchaser code that relates to the User ID field.';
                }
                field("Approver ID"; Rec."Approver ID")
                {
                    ToolTip = 'Specifies the user ID of the person who must approve records that are made by the user in the User ID field before the record can be released.';
                }
                field("Sales Amount Approval Limit"; Rec."Sales Amount Approval Limit")
                {
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                    Visible = AmountsVisible and SalesVisible;
                }
                field("Unlimited Sales Approval"; Rec."Unlimited Sales Approval")
                {
                    ToolTip = 'Specifies that the user on this line is allowed to approve sales records with no maximum amount. If you select this check box, then you cannot fill the Sales Amount Approval Limit field.';
                    Visible = AmountsVisible and SalesVisible;
                }
                field("Purchase Amount Approval Limit"; Rec."Purchase Amount Approval Limit")
                {
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                    Visible = AmountsVisible and PurchaseVisible;
                }
                field("Unlimited Purchase Approval"; Rec."Unlimited Purchase Approval")
                {
                    ToolTip = 'Specifies that the user on this line is allowed to approve purchase records with no maximum amount. If you select this check box, then you cannot fill the Purchase Amount Approval Limit field.';
                    Visible = AmountsVisible and PurchaseVisible;
                }
                field("Request Amount Approval Limit"; Rec."Request Amount Approval Limit")
                {
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                    Visible = AmountsVisible and RequestVisible;
                }
                field("Unlimited Request Approval"; Rec."Unlimited Request Approval")
                {
                    ToolTip = 'Specifies that the user on this line can approve all purchase quotes regardless of their amount. If you select this check box, then you cannot fill the Request Amount Approval Limit field.';
                    Visible = AmountsVisible and RequestVisible;
                }
                field(Substitute; Rec.Substitute)
                {
                    ToolTip = 'Specifies the User ID of the user who acts as a substitute for the original approver.';
                }
                field("Approval Administrator"; Rec."Approval Administrator")
                {
                    ToolTip = 'Specifies the user who has rights to unblock approval workflows, for example, by delegating approval requests to new substitute approvers and deleting overdue approval requests.';
                }
            }
        }
    }

    var
        AmountsVisible: Boolean;
        SalesVisible: Boolean;
        PurchaseVisible: Boolean;
        RequestVisible: Boolean;

    procedure SetAmountsVisible(AmountsVisibleIn: Boolean)
    begin
        AmountsVisible := AmountsVisibleIn;
    end;

    procedure SetWorkflowType(WorkflowType: Enum "Approval Workflow Type")
    begin
        SalesVisible := false;
        PurchaseVisible := false;
        RequestVisible := false;

        case WorkflowType of
            WorkflowType::Sales:
                SalesVisible := true;
            WorkflowType::Purchase:
                PurchaseVisible := true;
            WorkflowType::Request:
                RequestVisible := true;
        end;
    end;
}