// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

#pragma warning disable AS0088
reportextension 7000128 "Standard Sales Credit Memo ES" extends "Standard Sales - Credit Memo"
{
    dataset
    {
        add(Header)
        {
            column(CorrectedInvoiceNo; Header."Corrected Invoice No.")
            {
            }
        }
    }
}
