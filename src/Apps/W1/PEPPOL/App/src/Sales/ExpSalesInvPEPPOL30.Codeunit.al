// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.History;
using System.IO;

codeunit 37206 "Exp. Sales Inv. PEPPOL30"
{
    TableNo = "Record Export Buffer";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PeppolSetup: Record "PEPPOL 3.0 Setup";
        RecordRef: RecordRef;
        PEPPOL30Validation: Interface "PEPPOL30 Validation";
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);

        PeppolSetup.GetSetup();
        PEPPOL30Validation := PeppolSetup."PEPPOL 3.0 Sales Format";
        PEPPOL30Validation.ValidatePostedDocument(SalesInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesInvoiceHeader, OutStr, PeppolSetup."PEPPOL 3.0 Sales Format");
        Rec.Modify(false);
    end;

    /// <summary>
    /// Generates the XML file for a PEPPOL 3.0 sales invoice.
    /// </summary>
    /// <param name="VariantRec">The record containing the sales invoice data.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream; Format: Enum "PEPPOL 3.0 Format")
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL30";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(VariantRec, Format);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
    end;
}
