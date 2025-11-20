// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Environment.Configuration;
using System.Security.User;

page 663 "Approval User Setup"
{
    AdditionalSearchTerms = 'delegate approver,substitute approver';
    ApplicationArea = Basic, Suite;
    Caption = 'Approval User Setup';
    PageType = List;
    AboutTitle = 'About Approval User Setup';
    AboutText = 'Configure approval roles, limits, substitutes, and notification settings for users involved in approval workflows to control who can approve sales, purchases, and requests, and under what conditions.';
    RefreshOnActivate = true;
    SourceTable = "User Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the salesperson or purchaser code that relates to the User ID field.';
                }
                field("Approver ID"; Rec."Approver ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user ID of the person who must approve records that are made by the user in the User ID field before the record can be released.';
                }
                field("Sales Amount Approval Limit"; Rec."Sales Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Sales Approval"; Rec."Unlimited Sales Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line is allowed to approve sales records with no maximum amount. If you select this check box, then you cannot fill the Sales Amount Approval Limit field.';
                }
                field("Purchase Amount Approval Limit"; Rec."Purchase Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Purchase Approval"; Rec."Unlimited Purchase Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line is allowed to approve purchase records with no maximum amount. If you select this check box, then you cannot fill the Purchase Amount Approval Limit field.';
                }
                field("Request Amount Approval Limit"; Rec."Request Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Request Approval"; Rec."Unlimited Request Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line can approve all purchase quotes regardless of their amount. If you select this check box, then you cannot fill the Request Amount Approval Limit field.';
                }
                field(Substitute; Rec.Substitute)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the User ID of the user who acts as a substitute for the original approver.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the user in the User ID field.';
                }
                field(PhoneNo; Rec."Phone No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user''s phone number.';
                }
                field("Approval Administrator"; Rec."Approval Administrator")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who has rights to unblock approval workflows, for example, by delegating approval requests to new substitute approvers and deleting overdue approval requests.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Approval User Setup Test")
            {
                ApplicationArea = Suite;
                Caption = '&Approval User Setup Test';
                Image = Evaluate;
                ToolTip = 'Test the approval user setup, for example, to test if approvers are set up correctly.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Approval User Setup Test");
                end;
            }
        }
        area(navigation)
        {
            action("Notification Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Notification Setup';
                Image = Setup;
                RunObject = Page "Notification Setup";
                RunPageLink = "User ID" = field("User ID");
                ToolTip = 'Specify how the user receives notifications, for example about approval workflow steps.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Approval User Setup Test_Promoted"; "&Approval User Setup Test")
                {
                }
                actionref("Notification Setup_Promoted"; "Notification Setup")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.HideExternalUsers();
    end;
}

