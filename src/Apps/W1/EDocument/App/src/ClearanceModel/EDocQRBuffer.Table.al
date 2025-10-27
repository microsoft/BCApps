// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument;

table 6166 "EDoc QR Buffer"
{
    Caption = 'E-Doc QR Buffer';
    DataClassification = SystemMetadata;
    ReplicateData = false;
    Access = Internal;
    TableType = Temporary;

    fields
    {
        field(1; "Document Type"; Text[30]) { }
        field(2; "Document No."; Code[50]) { }
        field(10; "QR Code Base64"; Blob) { SubType = Memo; }
        field(11; "QR Code Image"; MediaSet)
        {
            Caption = 'QR Image';
            DataClassification = CustomerContent;
        }
    }
}