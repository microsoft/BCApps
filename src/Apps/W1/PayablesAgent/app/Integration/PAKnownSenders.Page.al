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
        UnusedNotification: Notification;
        SavedFolder: Text;
    begin
        SavedSetup.GetSetup();
        if OutlookSetup.FindFirst() then
            SavedFolder := OutlookSetup."Email Folder";

        Impact := PayablesAgentSetup.ClassifyKnownSendersUnusedReason(SavedSetup."Email Review Policy", SavedFolder);
        case Impact of
            Impact::KnownSendersIgnoredByFolder:
                UnusedNotification.Message := StrSubstNo(UnusedByFolderLbl, SavedFolder);
            Impact::KnownSendersIgnoredByPolicy:
                UnusedNotification.Message := StrSubstNo(UnusedByPolicyLbl, PayablesAgentSetup.PolicyLabel(SavedSetup."Email Review Policy"));
            else
                exit;
        end;
        UnusedNotification.Scope := NotificationScope::LocalScope;
        UnusedNotification.Send();
    end;

    var
        UnusedByFolderLbl: Label 'This list is currently unused. Emails arrive through subfolder ''%1'' and are processed without consulting it.', Comment = '%1 = folder name';
        UnusedByPolicyLbl: Label 'This list doesn''t affect processing while review policy is set to ''%1''.', Comment = '%1 = review policy';
}
