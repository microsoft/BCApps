// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

tableextension 13410 "Service Invoice Header FI" extends "Service Invoice Header"
{
    fields
    {
        field(32000000; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
            DataClassification = CustomerContent;
            Editable = true;
        }
    }
}