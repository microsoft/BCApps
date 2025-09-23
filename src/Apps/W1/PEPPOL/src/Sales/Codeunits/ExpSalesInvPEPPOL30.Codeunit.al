// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Sales.History;
using System.IO;

codeunit 37206 "Exp. Sales Inv. PEPPOL30"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInformation: Record "Company Information";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);
        CompanyInformation.Get();

        PEPPOL30Validation := CompanyInformation."E-Document Format";
        PEPPOL30Validation.CheckSalesInvoice(SalesInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL30";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(VariantRec);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
    end;
}

