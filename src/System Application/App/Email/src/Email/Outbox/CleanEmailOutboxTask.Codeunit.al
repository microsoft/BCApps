// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

codeunit 8908 "Clean Email Outbox Task"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    TableNo = "Email Outbox";

    trigger OnRun()
    var
        EmailImpl: Codeunit "Email Impl";
    begin
        EmailImpl.UpdateFailedEmailOutboxStatusToError();
    end;
}