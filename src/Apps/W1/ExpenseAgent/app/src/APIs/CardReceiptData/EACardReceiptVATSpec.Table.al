// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Staged VAT specification line from a receipt. Added to the expense and its expense report line only when they have no VAT specification lines.
/// </summary>
table 7434 "EA Card Receipt VAT Spec."
{
    Access = Internal;
    Caption = 'Card Receipt VAT Specification';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Receipt Data Id"; Guid)
        {
            Caption = 'Receipt Data Id';
            ToolTip = 'Specifies the receipt data that the VAT specification line belongs to.';
            TableRelation = "EA Card Receipt Data".Id;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the VAT specification line.';
        }
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            ToolTip = 'Specifies the VAT rate.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Amount';
            ToolTip = 'Specifies the net amount that the VAT rate applies to.';
        }
        field(12; "VAT Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount for the rate.';
        }
        field(13; Amount; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount including VAT.';
        }
        field(14; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Amount (LCY)';
            ToolTip = 'Specifies the VAT amount in local currency.';
        }
        field(15; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Amount (LCY)';
            ToolTip = 'Specifies the VAT base amount in local currency.';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount (LCY)';
            ToolTip = 'Specifies the amount including VAT in local currency.';
        }
        field(20; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT business posting group of the VAT specification line.';
        }
        field(21; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group of the VAT specification line.';
        }
        field(30; Confidence; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Confidence';
            ToolTip = 'Specifies the confidence score (0-1) of the extracted VAT data.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
        }
    }

    keys
    {
        key(PK; "Receipt Data Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
