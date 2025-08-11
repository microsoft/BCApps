// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

codeunit 8909 "Email Retry Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    TableNo = "Email Retry";
    Permissions = tabledata "Sent Email" = ri,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email Retry" = rimd,
                  tabledata "Email Message" = r,
                  tabledata "Email Error" = ri;

    var
        EmailRetryCancelledByUserLbl: Label 'Sending email cancelled by user.';


    internal procedure CleanEmailRetryByMessageId(MessageId: Guid)
    var
        EmailRetry: Record "Email Retry";
        EmailOutbox: Record "Email Outbox";
    begin
        EmailRetry.SetRange("Message Id", MessageId);
        if not EmailRetry.IsEmpty() then
            EmailRetry.DeleteAll();

        EmailOutbox.SetRange("Message Id", MessageId);
        if not EmailOutbox.FindFirst() then
            exit;
        EmailOutbox.Validate("Retry No.", 1);
        EmailOutbox.Modify();
    end;

    internal procedure CancelRetryByMessageId(MessageId: Guid): Boolean
    var
        EmailRetry: Record "Email Retry";
        EmailOutbox: Record "Email Outbox";
    begin
        EmailRetry.SetRange("Message Id", MessageId);
        if not EmailRetry.FindLast() then
            exit(false);
        if not TaskScheduler.CancelTask(EmailRetry."Task Scheduler Id") then exit(false);

        EmailRetry.Validate(Status, EmailRetry.Status::Failed);
        EmailRetry.Validate("Error Message", EmailRetryCancelledByUserLbl);
        EmailRetry.Validate("Date Failed", CurrentDateTime());
        EmailRetry.Modify();

        EmailOutbox.SetRange("Message Id", MessageId);
        if not EmailOutbox.FindFirst() then
            exit(false);
        EmailOutbox.Validate("Error Message", EmailRetryCancelledByUserLbl);
        EmailOutbox.Validate(Status, EmailOutbox.Status::Failed);
        EmailOutbox.Validate("Date Failed", CurrentDateTime());
        EmailOutbox.Modify();
        exit(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Email Retry", 'rd')]
    internal procedure CleanEmailRetry(MessageId: Guid)
    var
        EmailRetry: Record "Email Retry";
    begin
        EmailRetry.SetRange("Message Id", MessageId);
        if EmailRetry.IsEmpty() then
            exit;

        EmailRetry.DeleteAll();
    end;

    internal procedure CreateEmailRetry(var EmailOutbox: Record "Email Outbox")
    var
        EmailRetry: Record "Email Retry";
    begin
        EmailRetry.Init();
        EmailRetry.Validate("Message Id", EmailOutbox."Message Id");
        EmailRetry.Validate("User Security Id", EmailOutbox."User Security Id");
        EmailRetry.Validate("Account Id", EmailOutbox."Account Id");
        EmailRetry.Validate("Retry No.", EmailOutbox."Retry No.");
        EmailRetry.Validate("Date Sending", EmailOutbox."Date Sending");
        EmailRetry.Validate("Send From", EmailOutbox."Send From");
        EmailRetry.Validate(Description, EmailOutbox.Description);
        EmailRetry.Validate(Connector, EmailOutbox.Connector);
        EmailRetry.Validate(Status, EmailOutbox.Status);
        EmailRetry.Validate("Task Scheduler Id", EmailOutbox."Task Scheduler Id");
        EmailRetry.Insert();
    end;

    internal procedure UpdateEmailRetryRecord(MessageId: Guid; RetryNo: Integer; Status: Enum "Email Status"; ErrorMessage: Text;
                                                                                          DateQueued: DateTime;
                                                                                          DateFailed: DateTime;
                                                                                          DateSending: DateTime)
    var
        EmailRetry: Record "Email Retry";
    begin
        EmailRetry.SetRange("Message Id", MessageId);
        EmailRetry.SetRange("Retry No.", RetryNo);
        if not EmailRetry.FindFirst() then
            exit;

        EmailRetry.Validate(Status, Status);
        EmailRetry.Validate("Error Message", CopyStr(ErrorMessage, 1, MaxStrLen(EmailRetry."Error Message")));
        EmailRetry.Validate("Date Queued", DateQueued);
        EmailRetry.Validate("Date Failed", DateFailed);
        EmailRetry.Validate("Date Sending", DateSending);

        EmailRetry.Modify();
    end;
}