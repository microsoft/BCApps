// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

/// <summary>
/// Read-only view of the email a Payables Agent v2 task came from. The email is read live from the Email module.
/// </summary>
page 3338 "PA Email Review"
{
    Caption = 'Email Review';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Payables Agent Task Source";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = r;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                Caption = 'Header';

                field(EmailFrom; EmailFrom)
                {
                    Caption = 'From';
                    ToolTip = 'Specifies the sender of the email.';
                }
                field(EmailSubject; EmailSubject)
                {
                    Caption = 'Subject';
                    ToolTip = 'Specifies the subject of the email.';
                }
                field(EmailReceivedAt; EmailReceivedAt)
                {
                    Caption = 'Received';
                    ToolTip = 'Specifies when the email was received.';
                }
            }
            group(Body)
            {
                Caption = 'Body';

                field(EmailBody; EmailBody)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ToolTip = 'Specifies the body of the email.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        LoadEmail();
    end;

    local procedure LoadEmail()
    var
        EmailInbox: Record "Email Inbox";
        EmailMessage: Codeunit "Email Message";
    begin
        Clear(EmailFrom);
        Clear(EmailSubject);
        Clear(EmailReceivedAt);
        Clear(EmailBody);
        if not EmailInbox.Get(Rec."Email Inbox Id") then begin
            EmailSubject := EmailNotAvailableTxt;
            exit;
        end;

        EmailFrom := StrSubstNo(EmailFromTxt, EmailInbox."Sender Name", EmailInbox."Sender Address");
        EmailSubject := EmailInbox.Description;
        EmailReceivedAt := EmailInbox."Received DateTime";
        if not EmailMessage.Get(EmailInbox."Message Id") then
            exit;
        EmailBody := EmailMessage.GetBody();
    end;

    var
        EmailFrom: Text;
        EmailSubject: Text;
        EmailReceivedAt: DateTime;
        EmailBody: Text;
        EmailFromTxt: Label '%1 <%2>', Comment = '%1 = sender name, %2 = sender email address';
        EmailNotAvailableTxt: Label 'This email is no longer available.';
}
