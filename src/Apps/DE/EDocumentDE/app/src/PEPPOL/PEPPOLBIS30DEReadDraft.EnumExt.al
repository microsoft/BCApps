// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 13915 "PEPPOL BIS 3.0 DE Read Draft" extends "E-Doc. Read into Draft"
{
    value(13915; "PEPPOL BIS 3.0 DE")
    {
        Caption = 'PEPPOL BIS 3.0 DE';
        Implementation = IStructuredFormatReader = "E-Doc. PEPPOL BIS 3.0 DE Hdlr";
    }
}
