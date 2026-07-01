// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft;

tableextension 7000100 "CRT DetailedCustLedgEntry" extends "Detailed Cust. Ledg. Entry"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Document Situation"; Enum "ES Document Situation")
        {
            Caption = 'Document Situation';
            DataClassification = CustomerContent;
        }
        field(7000002; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000003; "Document Status"; Enum "ES Document Status")
        {
            Caption = 'Document Status';
            DataClassification = CustomerContent;
        }
    }
}
