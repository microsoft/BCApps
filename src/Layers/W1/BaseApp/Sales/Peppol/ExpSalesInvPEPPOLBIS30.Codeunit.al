// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.History;
using System.IO;

/// <summary>
/// Exports sales invoices to PEPPOL BIS 3.0 electronic document format with validation.
/// </summary>
codeunit 1610 "Exp. Sales Inv. PEPPOL BIS3.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PEPPOLValidation: Codeunit "PEPPOL Validation";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);

        PEPPOLValidation.CheckSalesInvoice(SalesInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    /// <summary>
    /// Generates an XML file in PEPPOL BIS 3.0 format for the sales invoice.
    /// </summary>
    /// <param name="VariantRec">Specifies the sales invoice record to export.</param>
    /// <param name="OutStr">Returns the generated XML content as an output stream.</param>
    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL BIS 3.0";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(VariantRec);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
    end;
}

