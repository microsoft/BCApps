// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Service.Document;

tableextension 6468 "Serv. Extended Text Header" extends "Extended Text Header"
{
    fields
    {
        field(5900; "Service Order"; Boolean)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Service Order';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(5901; "Service Quote"; Boolean)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Service Quote';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(5902; "Service Invoice"; Boolean)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Service Invoice';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(5903; "Service Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Service Credit Memo';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }
}
