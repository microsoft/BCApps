// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.Customer;

/// <summary>
/// Shared logic for preparing sales order drafts. Resolves customer and sales lines
/// from staging data populated by the PEPPOL handler.
/// </summary>
codeunit 6428 "EDoc Prepare Sales Draft"
{
    Access = Internal;

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters")
    var
        EDocumentSalesHeader: Record "E-Document Sales Header";
        EDocumentSalesLine: Record "E-Document Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        Customer: Record Customer;
        IUnitOfMeasureProvider: Interface IUnitOfMeasureProvider;
        ISalesLineProvider: Interface ISalesLineProvider;
    begin
        IUnitOfMeasureProvider := EDocImportParameters."Processing Customizations";
        ISalesLineProvider := EDocImportParameters."Processing Customizations";

        EDocumentSalesHeader.GetFromEDocument(EDocument);
        EDocumentSalesHeader.TestField("E-Document Entry No.");
        if EDocumentSalesHeader."[BC] Customer No." = '' then begin
            Customer := GetCustomer(EDocument, EDocImportParameters."Processing Customizations");
            if Customer."No." <> '' then
                EDocumentSalesHeader."[BC] Customer No." := Customer."No.";
        end;
        EDocumentSalesHeader.Modify();

        EDocumentSalesLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentSalesLine.FindSet() then
            repeat
                UnitOfMeasure := IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, EDocumentSalesLine."Line No.", EDocumentSalesLine."Unit of Measure");
                EDocumentSalesLine."[BC] Unit of Measure" := UnitOfMeasure.Code;
                ISalesLineProvider.GetSalesLine(EDocumentSalesLine);
                EDocumentSalesLine.Modify();
            until EDocumentSalesLine.Next() = 0;
    end;

    procedure GetCustomer(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Customer: Record Customer
    var
        ICustomerProvider: Interface ICustomerProvider;
    begin
        ICustomerProvider := Customizations;
        Customer := ICustomerProvider.GetCustomer(EDocument);
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    var
        EDocumentSalesHeader: Record "E-Document Sales Header";
        EDocumentSalesLine: Record "E-Document Sales Line";
    begin
        EDocumentSalesHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentSalesHeader.IsEmpty() then
            EDocumentSalesHeader.DeleteAll(true);

        EDocumentSalesLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocumentSalesLine.IsEmpty() then
            EDocumentSalesLine.DeleteAll(true);
    end;
}
