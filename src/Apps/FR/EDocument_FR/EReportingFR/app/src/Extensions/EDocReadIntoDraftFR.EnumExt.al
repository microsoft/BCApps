// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 10971 "E-Doc. Read into Draft FR" extends "E-Doc. Read into Draft"
{
    value(10977; "Peppol BIS 3.0 FR")
    {
        Caption = 'Peppol BIS 3.0 FR';
        Implementation = IStructuredFormatReader = "E-Doc. Peppol BIS 3.0 FR Hdlr";
    }
    value(10978; "Factur-X FR")
    {
        Caption = 'Factur-X FR';
        Implementation = IStructuredFormatReader = "E-Document Factur-X Handler";
    }
}
