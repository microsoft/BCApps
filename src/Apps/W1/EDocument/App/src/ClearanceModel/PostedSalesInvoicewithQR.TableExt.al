// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.History;

tableextension 6166 "Posted Sales Invoice with QR" extends "Sales Invoice Header"
{
    fields
    {
        field(6169; "SalesInv QR Code Image"; MediaSet)
        {
            Caption = 'QR Code Image';
            DataClassification = CustomerContent;
        }
        field(6170; "SalesInv QR Code Base64"; Blob)
        {
            Caption = 'QR Code Base64';
            DataClassification = CustomerContent;
        }

#if not CLEANSCHEMA31
        field(6165; "QR Code Image"; MediaSet)
        {
            Caption = 'QR Code Image';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field 6169 "SalesInv QR Code Image".';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
        field(6166; "QR Code Base64"; Blob)
        {
            Caption = 'QR Code Base64';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Replaced by field 6170 "SalesInv QR Code Base64".';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
#endif
    }
}
