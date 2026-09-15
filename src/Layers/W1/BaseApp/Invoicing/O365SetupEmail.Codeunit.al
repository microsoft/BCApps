// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 2135 "O365 Setup Email"
{

    trigger OnRun()
    begin
        SetupEmail(false);
    end;

    var
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.';

    procedure SetupEmail(ForceSetup: Boolean)
    begin
        Page.RunModal(Page::"Email Account Wizard");
    end;

    procedure CheckMailSetup()
    var
        EmailAccount: Codeunit "Email Account";
    begin
        if not EmailAccount.IsAnyAccountRegistered() then
            Error(MailNotConfiguredErr);
    end;
}

