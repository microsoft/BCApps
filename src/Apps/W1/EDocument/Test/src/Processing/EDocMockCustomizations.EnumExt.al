// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

enumextension 133501 "E-Doc. Mock Customizations" extends "E-Doc. Proc. Customizations"
{
    value(133501; "Mock Create Purchase Invoice")
    {
        Implementation = IEDocumentCreatePurchaseInvoice = "E-Doc. Processing Mocks";
    }
}