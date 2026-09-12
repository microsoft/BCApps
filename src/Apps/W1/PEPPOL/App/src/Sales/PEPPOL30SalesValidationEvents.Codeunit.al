// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 37224 "PEPPOL30 Sales Val. Events"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [IntegrationEvent(false, false)]
    internal procedure OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo(SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnCheckSalesDocumentOnBeforeCheckYourReference(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header"; CompanyInfo: Record "Company Information")
    begin
    end;
}