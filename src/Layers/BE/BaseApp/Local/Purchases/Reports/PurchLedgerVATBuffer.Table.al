// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

table 11302 "Purch. Ledger VAT Buffer"
{
    Caption = 'Purchase Ledger VAT Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "VAT Base Amount"; Decimal)
        {
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "G/L Entry No.")
        {
            Clustered = true;
        }
    }
}
