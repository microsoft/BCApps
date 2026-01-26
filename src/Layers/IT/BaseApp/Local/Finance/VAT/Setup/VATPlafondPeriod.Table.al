// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Ledger;

table 12187 "VAT Plafond Period"
{
    Caption = 'VAT Plafond Period';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Year; Integer)
        {
            Caption = 'Year';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Date Filter" := GetInitialDateFilter(Year);
            end;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(4; "Calculated Amount"; Decimal)
        {
            CalcFormula = sum("VAT Entry".Base where(Type = const(Purchase),
                                                      "Document Date" = field(filter("Date Filter")),
                                                      "Plafond Entry" = const(true)));
            Caption = 'Calculated Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Date Filter"; Text[80])
        {
            Caption = 'Date Filter';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Year)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1..%2';
        Text001: Label 'VAT Plafond Amount exceeded.';
        Text002: Label 'Dates %1 and %2 must belong to the same year.';

    local procedure GetDateFilter(Date1: Date; Date2: Date): Text[30]
    begin
        exit(Format(StrSubstNo(Text000, Date1, Date2)));
    end;

    local procedure GetInitialDateFilter(Year: Integer): Text[30]
    begin
        exit(GetDateFilter(DMY2Date(1, 1, Year), DMY2Date(31, 12, Year)));
    end;

    procedure CheckAmount(Date: Date; NewAmount: Decimal)
    begin
        if Get(Date2DMY(Date, 3)) then begin
            CalcFields("Calculated Amount");
            if "Calculated Amount" + NewAmount > Amount then
                Error(Text001);
        end;
    end;

    procedure CalcAmounts(StartingDate: Date; EndingDate: Date; var UsedAmount: Decimal; var RemAmount: Decimal): Boolean
    begin
        if not Get(Date2DMY(EndingDate, 3)) then
            exit(false);

        if Date2DMY(StartingDate, 3) <> Date2DMY(EndingDate, 3) then
            Error(Text002, StartingDate, EndingDate);

        "Date Filter" := GetDateFilter(StartingDate, EndingDate);
        CalcFields("Calculated Amount");
        UsedAmount := "Calculated Amount";

        "Date Filter" := GetDateFilter(CalcDate('<-CY>', EndingDate), CalcDate('<-1D>', StartingDate));
        CalcFields("Calculated Amount");
        RemAmount := Amount - "Calculated Amount";

        exit(true);
    end;
}

