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
        IEmailConnector: Interface "Email Connector";
#if not CLEAN26
#pragma warning disable AL0432
        IEmailConnectorv2: Interface "Email Connector v2";
#pragma warning restore AL0432
#endif
        IEmailConnectorv3: Interface "Email Connector v3";
    begin
        EmailMessage.Get(Rec.Id);

        if EmailMessage.GetExternalId() <> '' then begin
            IEmailConnector := EmailConnector;
#if not CLEAN26
#pragma warning disable AL0432
            if EmailImpl.CheckAndGetEmailConnectorv2(IEmailConnector, IEmailConnectorv2) then
#pragma warning restore AL0432
                IEmailConnectorv2.Reply(EmailMessage, AccountId);
#endif
            if EmailImpl.CheckAndGetEmailConnectorv3(IEmailConnector, IEmailConnectorv3) then
                IEmailConnectorv3.Reply(EmailMessage, AccountId);
        end else
            EmailConnector.Send(EmailMessage, AccountId);
    end;

    procedure SetConnector(NewEmailConnector: Interface "Email Connector")
    begin
        EmailConnector := NewEmailConnector;
    end;

    procedure SetAccount(NewAccountId: Guid)
    begin
        AccountId := NewAccountId;
    end;

    var
        EmailConnector: Interface "Email Connector";
        AccountId: Guid;
}