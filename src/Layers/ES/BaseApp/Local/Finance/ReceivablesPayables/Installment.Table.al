// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.PaymentTerms;

table 7000018 Installment
{
    Caption = 'Installment';
    DrillDownPageID = Installments;
    LookupPageID = Installments;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "% of Total"; Decimal)
        {
            Caption = '% of Total';
            DecimalPlaces = 2 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                CheckTotalInstallmentPerc();
            end;
        }
        field(4; "Gap between Installments"; Code[20])
        {
            Caption = 'Gap between Installments';
            DateFormula = true;
        }
    }

    keys
    {
        key(Key1; "Payment Terms Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckTotalInstallmentPerc();
    end;

    var
        Text10700: Label 'The total of "% of Total" cannot be greater than 100.';

    [Scope('OnPrem')]
    procedure CheckTotalInstallmentPerc()
    var
        Installment: Record Installment;
    begin
        Installment.SetRange("Payment Terms Code", "Payment Terms Code");
        Installment.SetFilter("Line No.", '<>%1', "Line No.");
        Installment.CalcSums("% of Total");
        if Installment."% of Total" + "% of Total" > 100 then
            Error(Text10700);
    end;
}

