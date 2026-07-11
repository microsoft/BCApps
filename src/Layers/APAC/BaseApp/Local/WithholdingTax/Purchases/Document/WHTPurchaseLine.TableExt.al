// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Document;

tableextension 28006 WHTPurchaseLine extends "Purchase Line"
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
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'WHT Absorb Base';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(WHT; "Document Type", "Document No.", "WHT Business Posting Group", "WHT Product Posting Group")
        {
            IncludedFields = "Prepmt. Amt. Inv.", "Prepmt Amt to Deduct";
        }
    }
}
