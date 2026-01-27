// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using System.IO;

/// <summary>
/// Interface for exporting PEPPOL documents to XML format.
/// Provides abstraction for XMLport operations to ensure proper encapsulation.
/// </summary>
interface "PEPPOL XML Exporter"
{
    /// <summary>
    /// Generates an XML file for a PEPPOL document and writes it to the provided output stream.
    /// </summary>
    /// <param name="DocumentVariant">The document record to export (e.g., Sales Invoice Header, Sales Cr.Memo Header).</param>
    /// <param name="OutStr">The output stream to write the XML data to.</param>
    /// <param name="Format">The PEPPOL 3.0 format to use for the export.</param>
    procedure GenerateXMLFile(DocumentVariant: Variant; var OutStr: OutStream; Format: Enum "PEPPOL 3.0 Format")
}
