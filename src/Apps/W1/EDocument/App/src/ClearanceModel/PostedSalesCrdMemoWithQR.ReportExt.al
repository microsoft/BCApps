// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.History;

reportextension 6168 PostedSalesCrdMemoWithQR extends "Standard Sales - Credit Memo"
{
    dataset
    {
        add(Header)
        {
            column(QR_Code_Image; "QR Code Image")
            {
            }
            column(QR_Code_Image_Lbl; FieldCaption("QR Code Image"))
            {
            }
        }
    }

    rendering
    {
        layout("StandardSalesInvoice.docx")
        {
            Type = Word;
            LayoutFile = './.resources/Template/StandardSalesCreditMemowithQR.docx';
            Caption = 'Standard Sales - Credit Memo - E-Document (Word)';
            Summary = 'The Standard Sales - Credit Memo - E-Document (Word) provides the layout including E-Document QR code support.';
        }
    }
}
