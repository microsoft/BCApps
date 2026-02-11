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
        field(6165; "QRCode Pic"; MediaSet)
        {
            Caption = 'QR Code Image';
            DataClassification = CustomerContent;
        }
        field(6166; "QRCode Base64 Data"; Blob)
        {
            Caption = 'QR Code Base64';
            DataClassification = CustomerContent;
        }

#if not CLEAN28
        field(6167; "QR Code Image"; MediaSet)
        {
            Caption = 'QR Code Image';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field 6165 "QRCode Pic" to align with Sales Invoice Header.';
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
        }
        field(6168; "QR Code Base64"; Blob)
        {
            Caption = 'QR Code Base64';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field 6166 "QRCode Base64 Data" to align with Sales Invoice Header.';
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
        }
#endif
    }
}
