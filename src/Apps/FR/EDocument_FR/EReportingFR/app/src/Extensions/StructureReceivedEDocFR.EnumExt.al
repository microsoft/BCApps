// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 10972 "Structure Received E-Doc. FR" extends "Structure Received E-Doc."
{
    value(10978; "Factur-X FR")
    {
        Caption = 'Factur-X FR';
        Implementation = IStructureReceivedEDocument = "E-Document Factur-X Handler";
    }
}
