// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.History;

reportextension 5429 "Sample Purchase Invoice" extends "Purchase - Invoice"
{
    rendering
    {
        layout(SamplePurchaseInvoice)
        {
            Type = RDLC;
            Caption = 'Sample Purchase Invoice';
            LayoutFile = './EDocumentInvoices/SamplePurchaseInvoice.rdlc';
        }
    }
}