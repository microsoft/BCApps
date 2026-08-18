// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

tableextension 13916 "E-Document DE" extends "E-Document"
{
    fields
    {
        field(13916; "Receiving Company Reg. No. DE"; Text[20])
        {
            Caption = 'Receiving Company Registration No.';
            DataClassification = CustomerContent;
        }
    }
}