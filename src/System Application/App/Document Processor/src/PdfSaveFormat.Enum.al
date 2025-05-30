// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

/// <summary>
/// Enum for the PDf formats that can be used.
/// </summary>

enum 3109 "PDF Save Format"
{
    Extensible = false;

    /// <summary>
    /// Save the PDF in the default format (traditionally PDF version 1.7). Platform will decide the PDF version.
    /// </summary>
    value(0; Default)
    {
    }

    /// <summary>
    /// Save the PDF in the PDF/A-3B format. This will not update the embedded XMP metadata.
    /// </summary>
    value(1; PdfA3B)
    {
    }

    /// <summary>
    /// Save the PDF in the PDF/A-3B format and add the embedded XMP metadata requried by E-Invoice standards like ZUGFeRD/Facturec.
    /// </summary>
    value(2; Einvoice)
    {
    }
}
