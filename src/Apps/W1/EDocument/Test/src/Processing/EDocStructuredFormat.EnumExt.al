// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 139782 EDocStructuredFormat extends "Structure Received E-Doc."
{
    value(139781; "PDF Mock")
    {
        Implementation = IStructureReceivedEDocument = "E-Doc PDF Mock";
    }
}