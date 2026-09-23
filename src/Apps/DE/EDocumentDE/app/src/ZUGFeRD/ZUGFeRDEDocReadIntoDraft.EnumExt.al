// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 13916 "ZUGFeRD EDoc Read into Draft" extends "E-Doc. Read into Draft"
{
    value(13916; "ZUGFeRD")
    {
        Caption = 'ZUGFeRD';
        Implementation = IStructuredFormatReader = "E-Document ZUGFeRD Handler";
    }
}
