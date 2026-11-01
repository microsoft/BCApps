// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
#pragma warning disable AS0050
#endif
namespace Microsoft.Agent.PayablesAgent;

page 3313 "PA Known Senders"
{
    Extensible = false;
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
                    ToolTip = 'Specifies how an incoming email from this sender is handled. ''Ask'' requests human review. ''Approve'' processes without review (effective when overall email review is ''Manage per sender''). ''Reject'' ignores the email.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PAKnownSenders: Codeunit "PA Known Senders";
        PASetup: Codeunit "PA Setup";
        UnusedNotification: Notification;
        Impact: Enum "PA Setup Change Impact";
        SavedPolicy: Enum "PA Email Review Policy";
        SavedFolder: Text;
    begin
        PASetup.LoadStoredOrDefaults();
        SavedPolicy := PASetup.GetEmailReviewPolicy();
        SavedFolder := PASetup.GetEmailFolder();

        Impact := PAKnownSenders.ClassifyKnownSendersUnusedReason(SavedPolicy, SavedFolder);
        case Impact of
            Impact::KnownSendersIgnoredByFolder:
                UnusedNotification.Message := UnusedByFolderLbl;
            Impact::KnownSendersIgnoredByPolicy:
                UnusedNotification.Message := StrSubstNo(UnusedByPolicyLbl, PolicyLabel(SavedPolicy));
            else
                exit;
        end;
        UnusedNotification.Scope := NotificationScope::LocalScope;
        UnusedNotification.Send();
    end;

    var
        UnusedByFolderLbl: Label 'This list is currently unused. Emails arrive through the configured subfolder and are processed without consulting it.', Comment = '%1 = folder name';
        UnusedByPolicyLbl: Label 'This list doesn''t affect processing while review policy is set to ''%1''.', Comment = '%1 = review policy';

    local procedure PolicyLabel(Policy: Enum "PA Email Review Policy"): Text
    var
        AlwaysLbl: Label 'Always';
        NeverLbl: Label 'Never';
        OnlyIfUntrustedLbl: Label 'Manage per sender';
    begin
        case Policy of
            Policy::Always:
                exit(AlwaysLbl);
            Policy::Never:
                exit(NeverLbl);
            Policy::OnlyIfUntrusted:
                exit(OnlyIfUntrustedLbl);
        end;
        exit('');
    end;
}
#if not CLEAN27
#pragma warning restore AS0050
#endif