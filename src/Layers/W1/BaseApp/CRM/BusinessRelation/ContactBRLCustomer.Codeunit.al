// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Sales.Customer;

codeunit 5558 "Contact BRL Customer" implements "Contact Business Relation Link"
{

    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
    var
        Customer: Record Customer;
    begin
        TableId := Database::Customer;
        Customer.SetRange("No.", No);
        Customer.FindFirst();
        SystemId := Customer.SystemId;
        exit(Customer.Count() = 1);
    end;
}
