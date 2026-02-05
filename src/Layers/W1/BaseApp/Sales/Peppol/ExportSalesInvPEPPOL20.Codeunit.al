#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.History;
using System.IO;

/// <summary>
/// Exports sales invoices to PEPPOL 2.0 electronic document format.
/// </summary>
codeunit 1602 "Export Sales Inv. - PEPPOL 2.0"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'PEPPOL 2.0 is no longer supported.';
    ObsoleteTag = '26.0';
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    /// <summary>
    /// Generates an XML file in PEPPOL 2.0 format for the sales invoice.
    /// </summary>
    /// <param name="VariantRec">Specifies the sales invoice record to export.</param>
    /// <param name="OutStr">Returns the generated XML content as an output stream.</param>
    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOL20: XMLport "Sales Invoice - PEPPOL 2.0";
    begin
        SalesInvoicePEPPOL20.Initialize(VariantRec);
        SalesInvoicePEPPOL20.SetDestination(OutStr);
        SalesInvoicePEPPOL20.Export();
    end;
}
#endif
