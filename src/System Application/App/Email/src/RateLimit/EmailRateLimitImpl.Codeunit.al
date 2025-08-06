// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

codeunit 8999 "Email Rate Limit Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "Email Rate Limit" = rimd,
                    tabledata "Email Account" = r,
                    tabledata "Email Outbox" = r,
                    tabledata "Sent Email" = r;

    procedure RegisterRateLimit(var EmailRateLimit: Record "Email Rate Limit"; RegisteredAccount: Record "Email Account"; RateLimit: Integer)
    var
        NewRateLimit: Record "Email Rate Limit";
    begin
        if NewRateLimit.Get(RegisteredAccount."Account Id", RegisteredAccount.Connector) then begin
            NewRateLimit."Rate Limit" := RateLimit;
            NewRateLimit.Modify();
        end else begin
            NewRateLimit."Account Id" := RegisteredAccount."Account Id";
            NewRateLimit.Connector := RegisteredAccount.Connector;
            NewRateLimit."Email Address" := RegisteredAccount."Email Address";
            NewRateLimit."Rate Limit" := RateLimit;
            NewRateLimit.Insert();
        end;

        EmailRateLimit."Account Id" := NewRateLimit."Account Id";
        EmailRateLimit.Connector := NewRateLimit.Connector;
        EmailRateLimit."Email Address" := NewRateLimit."Email Address";
        EmailRateLimit."Rate Limit" := NewRateLimit."Rate Limit";
    end;

    procedure UpdateRateLimit(RegisteredAccount: Record "Email Account")
    var
        EmailRateLimit: Record "Email Rate Limit";
        EmailRateLimitWizard: Page "Email Rate Limit Wizard";
    begin
        EmailRateLimit.Get(RegisteredAccount."Account Id", RegisteredAccount.Connector);
        EmailRateLimitWizard.SetRecord(EmailRateLimit);
        EmailRateLimitWizard.SetEmailAccountName(RegisteredAccount.Name);
        EmailRateLimitWizard.RunModal();
    end;

    procedure IsRateLimitExceeded(AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250]; var RateLimitDuration: Duration): Boolean
    var
        SentEmail: Record "Sent Email";
        EmailOutboxCurrent: Record "Email Outbox";
        EmailImpl: Codeunit "Email Impl";
        RateLimit: Integer;
    begin
        SentEmail.ReadIsolation := IsolationLevel::ReadUncommitted;
        EmailOutboxCurrent.ReadIsolation := IsolationLevel::ReadUncommitted;
        RateLimit := GetRateLimit(AccountId, Connector, EmailAddress);
        if RateLimit = 0 then
            exit(false);

        RateLimitDuration := EmailImpl.GetEmailOutboxSentEmailWithinRateLimit(SentEmail, EmailOutboxCurrent, AccountId);
        exit((EmailOutboxCurrent.Count() + SentEmail.Count()) >= RateLimit);
    end;

    procedure IsConcurrencyLimitExceeded(AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250]): Boolean
    begin
        exit(GetEmailOutboxCurrentProcessingCount(AccountId) > GetConcurrencyLimit(AccountId, Connector, EmailAddress))
    end;

    /// <summary>
    /// Returns the current count of emails in the outbox that are being processed for current user.
    /// </summary>
    /// <returns>The count of the email which is being sending for the account</returns>
    internal procedure GetEmailOutboxCurrentProcessingCount(AccountId: Guid): Integer
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.ReadIsolation := IsolationLevel::ReadUncommitted;
        EmailOutbox.SetRange(Status, EmailOutbox.Status::Processing);
        EmailOutbox.SetRange("Account Id", AccountId);
        if EmailOutbox.IsEmpty() then
            exit(0);

        exit(EmailOutbox.Count());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Email Rate Limit", 'ri')]
    procedure GetRateLimit(AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250]): Integer
    var
        EmailRateLimit: Record "Email Rate Limit";
    begin
        if EmailRateLimit.Get(AccountId, Connector) then
            exit(EmailRateLimit."Rate Limit");

        InitEmailRateLimitRecord(EmailRateLimit, AccountId, Connector, EmailAddress);

        exit(EmailRateLimit."Rate Limit");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Email Rate Limit", 'ri')]
    procedure GetConcurrencyLimit(AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250]): Integer
    var
        EmailRateLimit: Record "Email Rate Limit";
    begin
        if EmailRateLimit.Get(AccountId, Connector) then
            exit(EmailRateLimit."Concurrency Limit");

        InitEmailRateLimitRecord(EmailRateLimit, AccountId, Connector, EmailAddress);

        exit(EmailRateLimit."Concurrency Limit");
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Email Rate Limit", 'ri')]
    procedure GetMaxRetryLimit(AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250]): Integer
    var
        EmailRateLimit: Record "Email Rate Limit";
    begin
        if EmailRateLimit.Get(AccountId, Connector) then
            exit(EmailRateLimit."Max. Retry Limit");

        InitEmailRateLimitRecord(EmailRateLimit, AccountId, Connector, EmailAddress);

        exit(EmailRateLimit."Concurrency Limit");
    end;

    local procedure GetDefaultRateLimit(): Integer
    begin
        exit(0); // Default rate limit is 0, meaning no limit.
    end;

    internal procedure GetDefaultConcurrencyLimit(): Integer
    begin
        exit(3);
    end;

    local procedure GetDefaultMaxRetryLimit(): Integer
    begin
        exit(10);
    end;

    local procedure InitEmailRateLimitRecord(var EmailRateLimit: Record "Email Rate Limit"; AccountId: Guid; Connector: Enum "Email Connector"; EmailAddress: Text[250])
    begin
        EmailRateLimit.Validate("Account Id", AccountId);
        EmailRateLimit.Validate(Connector, Connector);
        EmailRateLimit.Validate("Email Address", EmailAddress);
        EmailRateLimit.Validate("Rate Limit", GetDefaultRateLimit());
        EmailRateLimit.Validate("Concurrency Limit", GetDefaultConcurrencyLimit());
        EmailRateLimit.Validate("Max. Retry Limit", GetDefaultMaxRetryLimit());
        EmailRateLimit.Insert();
    end;
}