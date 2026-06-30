// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Enums;
using Microsoft.Utilities;

codeunit 11364 "Employee NL"
{

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEvent(var Rec: Record Employee; var xRec: Record Employee)
    var
        TransactionMode: Record "Transaction Mode";
        AccountType: Option Customer,Vendor,Employee;
    begin
        if not TransactionMode.CheckTransactionModePartnerType(AccountType::Employee, Rec."Transaction Mode Code", Enum::"Partner Type"::" ") then
            Error(PartnerTypeMismatchErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterValidateEvent', 'Bank Account No.', false, false)]
    local procedure OnAfterValidateBankAccountNoEvent(var Rec: Record Employee; var xRec: Record Employee)
    begin
        if not LocalFunctionalityMgt.CheckBankAccNo(Rec."Bank Account No.", Rec."Country/Region Code", Rec."Bank Account No.") then
            Message(BankAccNoMsg, Rec."Bank Account No.");
    end;

    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        BankAccNoMsg: Label 'Bank Account No. %1 may be incorrect.', Comment = '%1 - bank account no';
        PartnerTypeMismatchErr: Label 'The Partner Type field must be blank because the transaction is related to an employee.';
}
