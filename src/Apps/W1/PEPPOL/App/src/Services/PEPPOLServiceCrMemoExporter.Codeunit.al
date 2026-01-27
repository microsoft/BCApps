// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using System.IO;

/// <summary>
/// Implementation of PEPPOL XML Exporter interface for Service Credit Memos.
/// Wraps the Sales Cr.Memo XMLport to provide proper abstraction for service documents.
/// </summary>
codeunit 37227 "PEPPOL Service CrMemo Exporter" implements "PEPPOL XML Exporter"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    /// <summary>
    /// Generates an XML file for a PEPPOL service credit memo.
    /// </summary>
    /// <param name="DocumentVariant">The service credit memo record to export.</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    /// <param name="Format">The PEPPOL 3.0 format to use for the export.</param>
    procedure GenerateXMLFile(DocumentVariant: Variant; var OutStr: OutStream; Format: Enum "PEPPOL 3.0 Format")
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL30";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(DocumentVariant, Format);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}
