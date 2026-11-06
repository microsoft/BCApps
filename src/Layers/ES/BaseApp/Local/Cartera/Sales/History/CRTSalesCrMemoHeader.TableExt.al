// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

tableextension 7000098 "CRT Sales Cr.Memo Header" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
    }
}

