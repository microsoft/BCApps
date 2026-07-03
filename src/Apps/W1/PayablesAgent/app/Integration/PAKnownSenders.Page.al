// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;

page 3313 "PA Known Senders"
{
    Caption = 'Payables Agent Known Senders', Comment = 'Payables Agent is a term, and should not be translated.';
    PageType = List;
    SourceTable = "PA Known Sender";
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address of a sender whose e-documents have been processed by the Payables Agent.';
                }
                field("Sender Policy"; Rec."Sender Policy")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how an incoming email from this sender is handled. ''Ask'' requests human review. ''Approve'' processes without review (effective when overall email review is ''Only if untrusted''). ''Reject'' ignores the email.';

                    trigger OnValidate()
                    begin
                        if Rec."Sender Policy" = Rec."Sender Policy"::Approve then
                            Session.LogSecurityAudit(Rec.TableName(), SecurityOperationResult::Success, StrSubstNo(SenderApprovedAuditLbl, Rec.Email), AuditCategory::PolicyManagement);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SavedSetup: Record "Payables Agent Setup";
        OutlookSetup: Record "Outlook Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        Impact: Enum "PA Setup Change Impact";
        InertNotification: Notification;
        SavedFolder: Text;
    begin
        SavedSetup.GetSetup();
        if OutlookSetup.FindFirst() then
            SavedFolder := OutlookSetup."Email Folder";

        Impact := PayablesAgentSetup.ClassifyKnownSendersInertReason(SavedSetup."Email Review Policy", SavedFolder);
        case Impact of
            Impact::KnownSendersIgnoredByFolder:
                InertNotification.Message := StrSubstNo(IgnoredByFolderLbl, SavedFolder);
            Impact::KnownSendersIgnoredByPolicy:
                InertNotification.Message := StrSubstNo(IgnoredByPolicyLbl, PayablesAgentSetup.PolicyLabel(SavedSetup."Email Review Policy"));
            else
                exit;
        end;
        InertNotification.Scope := NotificationScope::LocalScope;
        InertNotification.Send();
    end;

    var
        IgnoredByFolderLbl: Label 'This list is currently ignored. Emails arrive through subfolder ''%1'' and are processed without consulting it.', Comment = '%1 = folder name';
        IgnoredByPolicyLbl: Label 'This list doesn''t affect processing while review policy is set to ''%1''.', Comment = '%1 = review policy';
        SenderApprovedAuditLbl: Label 'Known sender %1 was set to Approve, allowing its emails to be processed without review.', Locked = true;
}
