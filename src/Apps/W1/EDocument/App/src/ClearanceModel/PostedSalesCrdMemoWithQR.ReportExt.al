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
#if not CLEAN29
        layout("StandardSalesInvoice.docx")
        {
            Type = Word;
            LayoutFile = './.resources/Template/StandardSalesCreditMemowithQR.docx';
            Caption = 'Standard Sales - Credit Memo - E-Document (Word)';
            Summary = 'The Standard Sales - Credit Memo - E-Document (Word) provides the layout including E-Document QR code support.';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the new Report Layout Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '29.0';
        }
#endif
        layout("StandardSalesInvoiceBody.docx")
        {
            Type = Word;
            //Subtype = Body;
            LayoutFile = './.resources/Template/StandardSalesCreditMemowithQRBody.docx';
            Caption = 'Body-only: Standard Sales - Credit Memo - E-Document (Word)';
            Summary = 'Portrait sales credit memo with QR code. Customer and company address, header (reference, salesperson, applies-to document, due date), item lines with price, discount %, VAT %, and amount, VAT-inclusive totals, and a QR code.';
        }
    }
}
