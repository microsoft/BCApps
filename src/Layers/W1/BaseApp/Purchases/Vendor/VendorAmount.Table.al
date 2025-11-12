// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

table 267 "Vendor Amount"
{
    Caption = 'Vendor Amount';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(2; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(3; "Amount 2 (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount 2 (LCY)';
        }
    }

    keys
    {
        key(Key1; "Amount (LCY)", "Amount 2 (LCY)", "Vendor No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

