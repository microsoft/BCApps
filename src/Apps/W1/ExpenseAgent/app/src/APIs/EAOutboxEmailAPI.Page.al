// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6983 "EA Outbox Email API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'EA Outbox Email';
    EntitySetCaption = 'EA Outbox Emails';
    DelayedInsert = true;
    EntityName = 'outboxEmail';
    EntitySetName = 'outboxEmails';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "EA Outbox Email";
    AboutText = 'Allows inserting emails into the outbox, which will be queued for sending.';
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec.Id)
                {
                    Caption = 'No.';
                }
                field(body; LocalBody)
                {
                    Caption = 'Body';
                }
                field(subject; Rec.Subject)
                {
                    Caption = 'Subject';
                }
                field(toLine; Rec.ToLine)
                {
                    Caption = 'To line';
                }
                field(ccLine; Rec.CCLine)
                {
                    Caption = 'Cc line';
                }
                field(bccLine; Rec.BCCLine)
                {
                    Caption = 'Bcc line';
                }
                field(correlationId; Rec."Correlation Id")
                {
                    Caption = 'Correlation Id';
                }
                field(notificationType; Rec."Notification Type")
                {
                    Caption = 'Notification type';
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnInsertRecord(Belowxrec: Boolean): Boolean
    begin
        Rec.Insert();
        Rec.WriteBody(LocalBody);
        Rec.Modify();

        exit(false);
    end;

    var
        LocalBody: Text;
}