// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

#pragma warning disable AS0088
reportextension 7000129 "Purchase Credit Memo ES" extends "Purchase - Credit Memo"
{
    dataset
    {
        add(PageLoop)
        {
            column(CorrectInvcNo_PurchCrMemoHeader; "Purch. Cr. Memo Hdr."."Corrected Invoice No.")
            {
            }
            column(CorrectedInvoiceNoCaption; CorrectedInvoiceNoCaptionLbl)
            {
            }
        }
    }

    var
        CorrectedInvoiceNoCaptionLbl: Label 'Corrected Invoice No.';
}
