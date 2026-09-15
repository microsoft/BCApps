// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

codeunit 1060 "Paypal Account Proxy"
{

    trigger OnRun()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetPaypalAccount(var Account: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetPaypalAccount(Account: Text[250]; Silent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetAlwaysIncludePaypalOnDocuments(NewAlwaysIncludeOnDocuments: Boolean; HideDialogs: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetAlwaysIncludeMsPayOnDocuments(NewAlwaysIncludeOnDocuments: Boolean; HideDialogs: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetPaypalSetupOptions(var Enabled: Boolean; var IncludeInAllDocuments: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure GetMsPayIsEnabled(var Enabled: Boolean)
    begin
    end;
}

