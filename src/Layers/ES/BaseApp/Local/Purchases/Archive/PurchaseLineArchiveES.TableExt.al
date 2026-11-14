// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

tableextension 7000096 "Purchase Line Archive ES" extends "Purchase Line Archive"
{
    fields
    {
        field(10700; "Pmt. Disc. Given Amount (Old)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Pmt. Disc. Given Amount (Old)';
            DataClassification = CustomerContent;
        }
        field(10701; "EC %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'EC %';
            DataClassification = CustomerContent;
        }
        field(10702; "EC Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'EC Difference';
            DataClassification = CustomerContent;
        }
        field(10703; "Prepayment EC %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment EC %';
            DataClassification = CustomerContent;
        }
    }
}
