// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.History;

tableextension 6167 PostedSalesCrdMemoWithQR extends "Sales Cr.Memo Header"
{
    fields
    {
        field(6167; "QR Code Image"; MediaSet)
        {
            Caption = 'QR Code Image';
            DataClassification = CustomerContent;
        }

        field(6168; "QR Code Base64"; Blob)
        {
            Caption = 'QR Code Base64';
            DataClassification = CustomerContent;
        }
    }
}
