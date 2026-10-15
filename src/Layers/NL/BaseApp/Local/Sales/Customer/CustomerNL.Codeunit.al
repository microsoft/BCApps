// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.Payment;

/// <summary>
/// NL-specific event subscribers for the Customer table.
/// Handles Transaction Mode checks during Partner Type validation and contact updates.
/// </summary>
codeunit 11473 "Customer NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnBeforeModifyContactUpdate', '', false, false)]
    local procedure OnBeforeModifyContactUpdate(var Customer: Record Customer)
    var
        TransactionMode: Record "Transaction Mode";
        AccountType: Option Customer,Vendor,Employee;
    begin
        if not TransactionMode.CheckTransactionModePartnerType(AccountType::Customer, Customer."Transaction Mode Code", Customer."Partner Type") then
            Error(PartnerTypeMismatchErr);
    end;

    var
        PartnerTypeMismatchErr: Label 'The Partner Type does not match the Partner Type defined in Transaction Mode.';
}
