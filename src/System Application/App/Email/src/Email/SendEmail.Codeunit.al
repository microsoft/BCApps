// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

codeunit 8890 "Send Email"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    TableNo = "Email Message";

    trigger OnRun()
    var
        EmailMessage: Codeunit "Email Message";
        EmailImpl: Codeunit "Email Impl";
        EmailConnector: Interface "Email Connector";
#if not CLEAN26
#pragma warning disable AL0432
        EmailConnectorv2: Interface "Email Connector v2";
#pragma warning restore AL0432
#endif
#if not CLEAN28
#pragma warning disable AL0432
        EmailConnectorv3: Interface "Email Connector v3";
#pragma warning restore AL0432
#endif
        EmailConnectorv4: Interface "Email Connector v4";
    begin
        EmailMessage.Get(Rec.Id);

        if EmailMessage.GetExternalId() <> '' then begin
            EmailConnector := GlobalEmailConnector;
#if not CLEAN26
#pragma warning disable AL0432
            if EmailImpl.CheckAndGetEmailConnectorv2(EmailConnector, EmailConnectorv2) then
#pragma warning restore AL0432
                EmailConnectorv2.Reply(EmailMessage, AccountId);
#endif
#if not CLEAN28
#pragma warning disable AL0432
            if EmailImpl.CheckAndGetEmailConnectorv3(EmailConnector, EmailConnectorv3) then
                EmailConnectorv3.Reply(EmailMessage, AccountId);
#pragma warning restore AL0432
#endif
            if EmailImpl.CheckAndGetEmailConnectorv4(EmailConnector, EmailConnectorv4) then
                EmailConnectorv4.Reply(EmailMessage, AccountId);
        end else
            GlobalEmailConnector.Send(EmailMessage, AccountId);
    end;

    procedure SetConnector(NewEmailConnector: Interface "Email Connector")
    begin
        GlobalEmailConnector := NewEmailConnector;
    end;

    procedure SetAccount(NewAccountId: Guid)
    begin
        AccountId := NewAccountId;
    end;

    var
        GlobalEmailConnector: Interface "Email Connector";
        AccountId: Guid;
}