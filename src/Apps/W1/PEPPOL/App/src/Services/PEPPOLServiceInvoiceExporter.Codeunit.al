// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using System.IO;

/// <summary>
/// Implementation of PEPPOL XML Exporter interface for Service Invoices.
/// Wraps the Sales Invoice XMLport to provide proper abstraction for service documents.
/// </summary>
codeunit 37226 "PEPPOL Service Invoice Exporter" implements "PEPPOL XML Exporter"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    /// <summary>
    /// Generates an XML file for a PEPPOL service invoice.
    /// </summary>
    /// <param name="DocumentVariant">The service invoice record to export.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    /// <param name="Format">The PEPPOL 3.0 format to use for the export.</param>
    procedure GenerateXMLFile(DocumentVariant: Variant; var OutStr: OutStream; Format: Enum "PEPPOL 3.0 Format")
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL30";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(DocumentVariant, Format);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
    end;
}
