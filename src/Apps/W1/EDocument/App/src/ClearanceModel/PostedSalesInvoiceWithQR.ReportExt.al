// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.History;

reportextension 6166 "PostedSalesInvoiceWithQR" extends "Standard Sales - Invoice"
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
#if not CLEAN32
        layout("StandardSalesInvoice.docx")
        {
            Type = Word;
            LayoutFile = './.resources/Template/StandardSalesInvoicewithQR.docx';
            Caption = 'Standard Sales Invoice - E-Document (Word)';
            Summary = 'The "Standard Sales Invoice - E-Document (Word)" provides the layout including E-Document QR code support.';
            ObsoleteState = Pending;
            ObsoleteReason = 'This Word layout will be replaced by the new Report Layout Experience. Use the corresponding composite (body) layout instead. It will be removed in a future release.';
            ObsoleteTag = '32.0';
        }
#endif
        layout("StandardSalesInvoiceBody.docx")
        {
            Type = Word;
            //Subtype = Body;
            LayoutFile = './.resources/Template/StandardSalesInvoicewithQRBody.docx';
            Caption = 'Body-only: Standard Sales Invoice - E-Document (Word)';
            Summary = 'Portrait sales invoice with QR code. Customer and company address, header (references, due date, payment/shipping details, tracking), item lines with price, discount %, VAT % and amount, VAT-inclusive totals and a payment QR code.';
        }
    }
}
