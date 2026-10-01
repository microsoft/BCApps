// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Sales.Customer;

codeunit 10807 "Sales FR Helper Procedures"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer; DefaultValue: Variant)
    var
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(TableId, TableId);
        DataTransfer.AddSourceFilter(SourceFieldNo, '<>%1', DefaultValue);
        DataTransfer.AddFieldValue(SourceFieldNo, TargetFieldNo);
        DataTransfer.UpdateAuditFields := false;
        DataTransfer.CopyFields();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustVendBank-Update", 'OnAfterUpdateCustomer', '', false, false)]
    local procedure PreserveCustomerSIRENNo(var Customer: Record Customer)
    var
        StoredCustomer: Record Customer;
    begin
        StoredCustomer.Get(Customer."No.");
        Customer."SIREN No. FR" := StoredCustomer."SIREN No. FR";
    end;
}
