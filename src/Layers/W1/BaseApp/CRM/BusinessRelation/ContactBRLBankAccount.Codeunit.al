// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Bank.BankAccount;

codeunit 5561 "Contact BRL Bank Account" implements "Contact Business Relation Link"
{

    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        TableId := Database::"Bank Account";
        BankAccount.SetRange("No.", No);
        BankAccount.FindFirst();
        SystemId := BankAccount.SystemId;
        exit(BankAccount.Count() = 1);
    end;
}
