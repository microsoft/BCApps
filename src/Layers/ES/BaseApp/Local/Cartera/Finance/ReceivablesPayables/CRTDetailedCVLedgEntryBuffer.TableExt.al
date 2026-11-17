// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft;
using Microsoft.Sales.Receivables;

tableextension 7000088 "CRT DetailedCVLedgEntryBuffer" extends "Detailed CV Ledg. Entry Buffer"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = SystemMetadata;
        }
        field(7000001; "Document Situation"; Enum "ES Document Situation")
        {
            Caption = 'Document Situation';
            DataClassification = SystemMetadata;
        }
        field(7000002; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = SystemMetadata;
        }
        field(7000003; "Document Status"; Enum "ES Document Status")
        {
            Caption = 'Document Status';
            DataClassification = SystemMetadata;
        }
    }
}