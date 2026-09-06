// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Utilities;

codeunit 11344 "Bank Account NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnValidateBankAccount', '', false, false)]
    local procedure OnValidateBankAccount(var BankAccount: Record "Bank Account"; FieldToValidate: Text)
    begin
        if FieldToValidate <> 'Bank Account No.' then
            exit;

        if not LocalFunctionalityMgt.CheckBankAccNo(BankAccount."Bank Account No.", BankAccount."Country/Region Code", BankAccount."Bank Account No.") then
            Message(IncorrectBankAccountNoMsg, BankAccount.FieldCaption("Bank Account No."), BankAccount."Bank Account No.");
    end;

    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        IncorrectBankAccountNoMsg: Label '%1 %2 may not be filled out correctly.';
}
