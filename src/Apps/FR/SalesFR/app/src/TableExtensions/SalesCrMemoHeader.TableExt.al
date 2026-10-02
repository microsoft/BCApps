// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.History;

tableextension 10802 "Sales Cr.Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(10802; "VAT Paid on Debits FR"; Boolean)
        {
            Caption = 'VAT Paid on Debits';
            DataClassification = CustomerContent;
        }
    }
}
