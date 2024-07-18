// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

page 8881 "Email Inbox"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Email Inbox";
    Editable = false;
    Extensible = false;
    Permissions = tabledata "Email Inbox" = rimd;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the email inbox record.';
                }
                field("Conversation Id"; Rec."Conversation Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the conversation from the external source.';

                    trigger OnDrillDown()
                    begin
                        EmailInboxViewer.SetRecord(Rec);
                        EmailInboxViewer.Run();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the email inbox record.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetrieveEmails)
            {
                ApplicationArea = All;
                Image = Download;
                Caption = 'Retrieve Emails';
                ToolTip = 'Retrieve Emails';

                trigger OnAction()
                var
                    TempEmailAccounts: Record "Email Account" temporary;
                    Email: Codeunit Email;
                    EmailAccount: Codeunit "Email Account";
                begin
                    EmailAccount.GetAllAccounts(false, TempEmailAccounts);
                    Email.RetrieveEmails(TempEmailAccounts."Account Id", TempEmailAccounts.Connector, Rec);
                end;
            }
            action(MarkAsRead)
            {
                ApplicationArea = All;
                Image = Closed;
                Caption = 'Mark as Read';
                ToolTip = 'Mark as Read';

                trigger OnAction()
                var
                    TempEmailAccounts: Record "Email Account" temporary;
                    Email: Codeunit Email;
                    EmailAccount: Codeunit "Email Account";
                begin
                    EmailAccount.GetAllAccounts(false, TempEmailAccounts);
                    Email.MarkAsRead(TempEmailAccounts."Account Id", TempEmailAccounts.Connector, Rec."External Message Id");
                end;
            }
            action(DeleteAll)
            {
                ApplicationArea = All;
                Image = Delete;
                Caption = 'Delete All';
                ToolTip = 'Delete All';

                trigger OnAction()
                var
                    EmailInbox: Record "Email Inbox";
                begin
                    EmailInbox.DeleteAll(true);
                end;
            }
            action(Reply)
            {
                ApplicationArea = All;
                Image = Return;
                Caption = 'Reply';
                ToolTip = 'Reply';

                trigger OnAction()
                var
                    EmailOutbox: Record "Email Outbox";
                    TempEmailAccounts: Record "Email Account" temporary;
                    Email: Codeunit Email;
                    EmailAccount: Codeunit "Email Account";
                    EmailMessage: Codeunit "Email Message";
                begin
                    EmailAccount.GetAllAccounts(false, TempEmailAccounts);

                    EmailMessage.CreateReplyAll('Thank you for your email. \r\nWe will process it momentarily.\r\nPlease wait for another email from us with the confirmed details.', false, Rec."External Message Id");
                    Email.ReplyAll(EmailMessage, Rec."External Message Id", TempEmailAccounts."Account Id", TempEmailAccounts.Connector, EmailOutbox);
                end;
            }
        }
    }

    var
        EmailInboxViewer: Page "Email Inbox Viewer";
}