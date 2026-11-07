// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 13919 "ZUGFeRD Structure Received" extends "Structure Received E-Doc."
{
    value(13919; "ZUGFeRD")
    {
        Caption = 'ZUGFeRD';
        Implementation = IStructureReceivedEDocument = "E-Document ZUGFeRD Handler";
    }
}
