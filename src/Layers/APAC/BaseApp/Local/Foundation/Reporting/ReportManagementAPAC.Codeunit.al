// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

codeunit 28020 "Report Management APAC"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Amounts are in whole 10s';
        Text002: Label 'Amounts are in whole 100s';
        Text003: Label 'Amounts are in whole 1,000s';
        Text004: Label 'Amounts are in whole 100,000s';
        Text005: Label 'Amounts are in whole 1,000,000s';
        Text006: Label 'Amounts are not rounded';

    procedure RoundAmount(Amount: Decimal; Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions): Decimal
    begin
        case Rounding of
            Rounding::" ":
                exit(Amount);
            Rounding::Tens:
                exit(Round(Amount / 10, 0.1));
            Rounding::Hundreds:
                exit(Round(Amount / 100, 0.1));
            Rounding::Thousands:
                exit(Round(Amount / 1000, 1));
            Rounding::"Hundred Thousands":
                exit(Round(Amount / 100000, 0.1));
            Rounding::Millions:
                exit(Round(Amount / 1000000, 0.1));
        end;
    end;

    procedure RoundDescription(Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions): Text[50]
    begin
        case Rounding of
            Rounding::" ":
                exit(Text006);
            Rounding::Tens:
                exit(Text001);
            Rounding::Hundreds:
                exit(Text002);
            Rounding::Thousands:
                exit(Text003);
            Rounding::"Hundred Thousands":
                exit(Text004);
            Rounding::Millions:
                exit(Text005);
        end;
    end;
}
