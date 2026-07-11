// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.History;

tableextension 28008 WHTPurchCrMemoLine extends "Purch. Cr. Memo Line"
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "WHT Product Posting Group"; Code[20])
        {
            Caption = 'WHT Product Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Product Posting Group";
        }
        field(28042; "WHT Absorb Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'WHT Absorb Base';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(WHT; "Document No.", "WHT Business Posting Group", "WHT Product Posting Group")
        {
        }
    }
}
