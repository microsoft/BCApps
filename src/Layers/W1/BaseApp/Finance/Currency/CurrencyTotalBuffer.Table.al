// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Temporary buffer table for accumulating currency totals across multiple transactions.
/// Used for calculating and displaying currency-specific totals in reports and processing routines.
/// </summary>
/// <remarks>
/// Non-replicating buffer table for performance optimization in currency total calculations.
/// Commonly used in financial reports and batch processing scenarios where currency
/// totals need to be grouped and summarized before presentation or posting.
/// </remarks>
table 332 "Currency Total Buffer"
{
    Caption = 'Currency Total Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(2; "Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "Total Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Total Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(4; Counter; Integer)
        {
            Caption = 'Counter';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure UpdateTotal(CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; var Counter: Integer)
    begin
        if Get(CurrencyCode) then begin
            "Total Amount" := "Total Amount" + Amount;
            "Total Amount (LCY)" := "Total Amount (LCY)" + AmountLCY;
            Modify();
        end else begin
            "Currency Code" := CurrencyCode;
            "Total Amount" := Amount;
            "Total Amount (LCY)" := AmountLCY;
            Counter := Counter + 1;
            Insert();
        end;
    end;
}
