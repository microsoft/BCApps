// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;
using System.Utilities;

report 8 Budget
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/Budget.rdlc';
    ApplicationArea = Suite;
    Caption = 'Budget';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLBudgetFilter; GLBudgetFilter)
            {
            }
            column(NoOfBlankLines_GLAcc; "No. of Blank Lines")
            {
            }
            column(AmtsInThousands; InThousands)
            {
            }
            column(GLFilterTableCaption_GLAcc; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(Type_GLAcc; "Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate6; Format(PeriodStartDate[6], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate7; Format(PeriodStartDate[7], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate8; Format(PeriodStartDate[8], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate9; Format(PeriodStartDate[9], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate10; Format(PeriodStartDate[10], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate11; Format(PeriodStartDate[11], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate12; Format(PeriodStartDate[12], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate51; Format(PeriodStartDate[5] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate61; Format(PeriodStartDate[6] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate71; Format(PeriodStartDate[7] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate81; Format(PeriodStartDate[8] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate91; Format(PeriodStartDate[9] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate101; Format(PeriodStartDate[10] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate111; Format(PeriodStartDate[11] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate121; Format(PeriodStartDate[12] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate131; Format(PeriodStartDate[13] - 1, 0, '<Month Text,3>'))
            {
            }
            column(No_GLAcc; "No.")
            {
                IncludeCaption = true;
            }
            column(BudgetCaption; BudgetCaptionTxt)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BudgetFilterCaption; BudgetFilterCaptionLbl)
            {
            }
            column(AmtsAreInwhole1000sCaptn; AmtsAreInwhole1000sCaptnLbl)
            {
            }
            column(GLAccNameCaption; GLAccNameCaptionLbl)
            {
            }
            column(TotalCaption; TotalLbl)
            {
            }
            column(RowNumber; RowNumber)
            {
            }
            column(StartingDateAsText; StartingDateAsText)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GLAccNo_BlankLineCounter; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(PADSTRIndentName_GLAcc; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLBudgetedAmount1; GLBudgetedAmount[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount2; GLBudgetedAmount[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount3; GLBudgetedAmount[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount4; GLBudgetedAmount[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount5; GLBudgetedAmount[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount6; GLBudgetedAmount[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount7; GLBudgetedAmount[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount8; GLBudgetedAmount[8])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount9; GLBudgetedAmount[9])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount10; GLBudgetedAmount[10])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount11; GLBudgetedAmount[11])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount12; GLBudgetedAmount[12])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TotalBudgetAmount; TotalBudgetAmount)
                {
                    DecimalPlaces = 0 : 5;
                }
            }

            trigger OnAfterGetRecord()
            begin
                TotalBudgetAmount := 0;
                for i := 1 to ArrayLen(GLBudgetedAmount) do begin
                    SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CalcFields("Budgeted Amount");
                    if InThousands then
                        "Budgeted Amount" := "Budgeted Amount" / 1000;
                    GLBudgetedAmount[i] := MatrixMgt.RoundAmount("Budgeted Amount", RndFactor);
                    TotalBudgetAmount += GLBudgetedAmount[i];
                end;
                SetRange("Date Filter", PeriodStartDate[1], PeriodStartDate[ArrayLen(PeriodStartDate)] - 1);

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
                RowNumber += 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(InThousands; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                    field(RoundingFactor; RndFactor)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Rounding Factor';
                        ToolTip = 'Specifies the factor that is used to round the amounts.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := CalcDate('<-CY+1D>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        GLBudgetFilter := "G/L Account".GetFilter("Budget Filter");
        if PeriodStartDate[1] = 0D then
            PeriodStartDate[1] := WorkDate();
        for i := 2 to ArrayLen(PeriodStartDate) do
            PeriodStartDate[i] := CalcDate(PeriodLength, PeriodStartDate[i - 1]);

        BudgetCaptionTxt := StrSubstNo(BudgetCaptionTok, Format(PeriodStartDate[1], 0, '<Year4>'));
        StartingDateAsText := StrSubstNo(StartingDateTok, PeriodStartDate[1]);
    end;

    var
        MatrixMgt: Codeunit "Matrix Management";
        PeriodLength: DateFormula;
        InThousands: Boolean;
        GLBudgetFilter: Text[250];
        BudgetCaptionTxt: Text;
        GLBudgetedAmount: array[12] of Decimal;
        TotalBudgetAmount: Decimal;
        PeriodStartDate: array[13] of Date;
        i: Integer;
        RowNumber: Integer;
        GLAccountTypePosting: Boolean;
        RndFactor: Enum "Analysis Rounding Factor";
        StartingDateAsText: Text;

        BudgetCaptionTok: Label 'Budget for %1', Comment = '%1 - year';
        PageCaptionLbl: Label 'Page';
        BudgetFilterCaptionLbl: Label 'Budget Filter';
        AmtsAreInwhole1000sCaptnLbl: Label 'Amounts are in whole 1000s.';
        GLAccNameCaptionLbl: Label 'Name';
        TotalLbl: Label 'Total';
        StartingDateTok: Label 'Starting Date: %1', Comment = '%1 - date';

    protected var
        GLFilter: Text;

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: Text[30]; NewInThousands: Boolean)
    begin
        PeriodStartDate[1] := NewPeriodStartDate;
        Evaluate(PeriodLength, NewPeriodLength);
        InThousands := NewInThousands;
    end;

    procedure SetRoundingFactor(NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        RndFactor := NewRoundingFactor;
    end;

    procedure GetPeriodLength(): DateFormula
    begin
        exit(PeriodLength);
    end;

    procedure GetPeriodStartDate(): Date
    begin
        exit(PeriodStartDate[1]);
    end;
}

