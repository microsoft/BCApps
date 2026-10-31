// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.GLAccount;

codeunit 8413 "IC G/L Account Deletion"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Account", 'OnBeforeOnDelete', '', false, false)]
    local procedure OnBeforeOnDelete(var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        if IsHandled then
            exit;

        ICGLAccount.SetRange("Map-to G/L Acc. No.", GLAccount."No.");
        if not ICGLAccount.IsEmpty() then
            ICGLAccount.ModifyAll("Map-to G/L Acc. No.", '');
    end;
}
