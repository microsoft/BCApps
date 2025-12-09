// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Service.History;
using Microsoft.Foundation.Company;
using System.IO;

codeunit 37212 "Exp. Serv.Inv. PEPPOL30"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CompanyInformation: Record "Company Information";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceInvoiceHeader);
        CompanyInformation.Get();

        PEPPOL30Validation := CompanyInformation."PEPPOL 3.0 Service Format";
        PEPPOL30Validation.ValidateInvoice(ServiceInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);

        GenerateXMLFile(ServiceInvoiceHeader, OutStr, CompanyInformation."PEPPOL 3.0 Service Format");

        Rec.Modify();
    end;

    /// <summary>
    /// Generates the XML file for a PEPPOL 3.0 service invoice.
    /// </summary>
    /// <param name="VariantRec">The record containing the service invoice data.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream; PEPPOL30Format: Enum "PEPPOL 3.0 Format")
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL30";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(VariantRec, PEPPOL30Format);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
    end;
}

