// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 10807 "Sales FR Helper Procedures"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure TransferSalesFRFields()
    begin
        TransferFields(Database::Customer, 10805, 10806, ''); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        TransferFields(Database::Contact, 10805, 10806, ''); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        TransferFields(Database::"Sales Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        TransferFields(Database::"Sales Cr.Memo Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        TransferFields(Database::"Sales Invoice Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
    end;

    local procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer; DefaultValue: Variant)
    var
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(TableId, TableId);
        DataTransfer.AddSourceFilter(SourceFieldNo, '<>%1', DefaultValue);
        DataTransfer.AddFieldValue(SourceFieldNo, TargetFieldNo);
        DataTransfer.UpdateAuditFields := false;
        DataTransfer.CopyFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnCreateCustomerFromTemplateOnBeforeCustomerInsert', '', false, false)]
    local procedure InitializeCustomerSIRENNoFromContact(var Cust: Record Customer; CustomerTemplate: Code[20]; var Contact: Record Contact)
    begin
        Cust."SIREN No. FR" := Contact."SIREN No. FR";
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
