// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

report 38 "Trial Balance by Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/TrialBalancebyPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance by Period';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Income/Balance", "Account Type", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Text015___FORMAT_Indent_; StrSubstNo(IndentationLevelCap, SelectStr(Indent + 1, IndentTxt)))
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(LastPageText50; LastPageText50Lbl)
            {
            }
            column(LastPageText51; LastPageText51Lbl)
            {
            }
            column(Text052; Text052Lbl)
            {
            }
            column(RoundingText; RoundingText)
            {
            }
            column(RoundingFactorInt; RoundingFactorInt)
            {
            }
            column(STRSUBSTNO___1__2__Header_1_1__Header_1_2__; StrSubstNo('%1 %2', Header[1, 1], Header[1, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_2_1__Header_2_2__; StrSubstNo('%1 %2', Header[2, 1], Header[2, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_4_1__Header_4_2__; StrSubstNo('%1 %2', Header[4, 1], Header[4, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_3_1__Header_3_2__; StrSubstNo('%1 %2', Header[3, 1], Header[3, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_7_1__Header_7_2__; StrSubstNo('%1 %2', Header[7, 1], Header[7, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_6_1__Header_6_2__; StrSubstNo('%1 %2', Header[6, 1], Header[6, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_5_1__Header_5_2__; StrSubstNo('%1 %2', Header[5, 1], Header[5, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_11_1__Header_11_2__; StrSubstNo('%1 %2', Header[11, 1], Header[11, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_10_1__Header_10_2__; StrSubstNo('%1 %2', Header[10, 1], Header[10, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_9_1__Header_9_2__; StrSubstNo('%1 %2', Header[9, 1], Header[9, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_8_1__Header_8_2__; StrSubstNo('%1 %2', Header[8, 1], Header[8, 2]))
            {
            }
            column(STRSUBSTNO___1__2__Header_12_1__Header_12_2__; StrSubstNo('%1 %2', Header[12, 1], Header[12, 2]))
            {
            }
            column(STRSUBSTNO_____1__FORMAT_CLOSINGDATE_StartDate_1____1___; StrSubstNo('..%1', Format(ClosingDate(StartDate[1] - 1))))
            {
            }
            column(LastPage; LastPage)
            {
            }
            column(Trial_Balance_by_PeriodCaption; Trial_Balance_by_PeriodCaptionLbl)
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
                column(ColumnValuesAsText_4_; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1_; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_10_; ColumnValuesAsText[10])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_9_; ColumnValuesAsText[9])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_8_; ColumnValuesAsText[8])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_7_; ColumnValuesAsText[7])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_6_; ColumnValuesAsText[6])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_13_; ColumnValuesAsText[13])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_12_; ColumnValuesAsText[12])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_11_; ColumnValuesAsText[11])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_5_; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLAccountType; GLAccountType)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(G_L_Account___No__of_Blank_Lines_; "G/L Account"."No. of Blank Lines")
                {
                }
                column(GLAccountNewPage; "G/L Account"."New Page")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GLAccountType := "G/L Account"."Account Type".AsInteger();
                    if IsNewPage then begin
                        PageGroupNo := PageGroupNo + 1;
                        IsNewPage := false;
                    end;

                    if "G/L Account"."New Page" then
                        IsNewPage := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                LastPage := false;
                Clear(ColumnValuesAsText);

                SetRange("Date Filter", 0D, ClosingDate(StartDate[1] - 1));
                CalcNetChange("G/L Account");
                ColumnValuesAsText[1] := RoundAmount("Net Change");

                for i := 2 to MaxCount do begin
                    SetRange("Date Filter", StartDate[i - 1], EndDate[i - 1]);
                    CalcNetChange("G/L Account");
                    ColumnValuesAsText[i] := RoundAmount("Net Change");
                end;
            end;

            trigger OnPreDataItem()
            begin
                RoundingFactorInt := RoundingFactor.AsInteger();
                PageGroupNo := 1;

                // Indentation Level
                case Indent of
                    Indent::"0":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 0);
                        end;
                    Indent::"1":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 1);
                        end;
                    Indent::"2":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 2);
                        end;
                    Indent::"3":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 3);
                        end;
                    Indent::"4":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 4);
                        end;
                    Indent::"5":
                        begin
                            SetFilter("Account Type", '%1|%2', "Account Type"::Posting,
                              "Account Type"::"End-Total");
                            SetRange(Indentation, 5);
                        end;
                end;

                CompanyInfo.CalcFields(Picture);

                if PeriodStartingDate = 0D then
                    Error(Text004);
                AccountingPeriod.Reset();
                if not AccountingPeriod.Get(PeriodStartingDate) then
                    Error(Text005);

                case RoundingFactor of
                    RoundingFactor::"1":
                        RoundingText := Text011;
                    RoundingFactor::"1000":
                        RoundingText := Text012;
                    RoundingFactor::"1000000":
                        RoundingText := Text013;
                end;

                StartDate[1] := PeriodStartingDate;
                EndDate[1] := AccPeriodEndDate(StartDate[1]);
                Header[1, 1] := Format(StartDate[1]);
                Header[1, 2] := Format(EndDate[1]);

                AccountingPeriod2.SetFilter("Starting Date", '>=%1', AccountingPeriod."Starting Date");
                MaxCount := AccountingPeriod2.Count();
                if MaxCount > 13 then
                    MaxCount := 13;

                for i := 2 to MaxCount do begin
                    AccountingPeriod.Next();

                    StartDate[i] := AccountingPeriod."Starting Date";
                    EndDate[i] := AccPeriodEndDate(StartDate[i]);

                    Header[i, 1] := Format(StartDate[i]);
                    Header[i, 2] := Format(EndDate[i]);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Trial Balance by Period';
        AboutText = 'Get a detailed breakdown of your closing balances over 12 accounting periods for each G/L account, or summarized by totaling accounts.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        ShowMandatory = true;
                    }
                    field(RoundingFactor; RoundingFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Factor';
                        ToolTip = 'Specifies a rounding factor that will be used in the balance.';
                    }
                    field(Indent; Indent)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Indentation Level';
                        OptionCaption = 'None,0,1,2,3,4,5';
                        ToolTip = 'Specifies the indentation level that sets the range filter for the accounts you want to be displayed or printed. For example, if you select Indentation Level 1, you filter all Level 1 accounts ranging from Begin-Total to End-Total. If there is both a Begin-Total and an End-Total account in the selected range, the report only shows the End-Total.';

                        trigger OnValidate()
                        begin
                            CheckIndent();
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
    end;

    var
        CompanyInfo: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriod2: Record "Accounting Period";
        GLIndent: Record "G/L Account";
        MatrixMgt: Codeunit "Matrix Management";
        i: Integer;
        RoundingFactorInt: Integer;
        PageGroupNo: Integer;
        GLAccountType: Integer;
        LastPage: Boolean;
#pragma warning disable AA0074
        Text004: Label 'Enter the starting date for the first period.';
        Text005: Label 'The starting date is not the starting date of an accounting period.';
        Text011: Label 'Amounts are rounded to 1';
        Text012: Label 'Amounts are in whole 1000s.';
        Text013: Label 'Amounts are in whole 1000000s.';
#pragma warning disable AA0470
        Text014: Label 'Indentation Level %1 is not used in the Chart of Accounts. This Chart of Accounts uses max. %2 levels.';
        IndentationLevelCap: Label 'Indentation Level : %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        IsNewPage: Boolean;
        MaxIndent: Text[5];
        LastPageText50Lbl: Label '/ Last Page';
        LastPageText51Lbl: Label '/ Continued';
        Text052Lbl: Label 'Page';
        Trial_Balance_by_PeriodCaptionLbl: Label 'Trial Balance by Period';
        IndentTxt: Label 'None,0,1,2,3,4,5';

    protected var
        GLFilter: Text;
        PeriodStartingDate: Date;
        StartDate: array[20] of Date;
        EndDate: array[20] of Date;
        ColumnValuesAsText: array[13] of Text[30];
        RoundingText: Text[80];
        Header: array[13, 2] of Text[100];
        RoundingFactor: Enum "Analysis Rounding Factor";
        MaxCount: Integer;
        Indent: Option "None","0","1","2","3","4","5";

    local procedure AccPeriodEndDate(UseStartDate: Date): Date
    var
        AccountingPeriod2: Record "Accounting Period";
    begin
        AccountingPeriod2."Starting Date" := UseStartDate;
        if AccountingPeriod2.Find('>') then
            exit(AccountingPeriod2."Starting Date" - 1);
        exit(DMY2Date(31, 12, 9999));
    end;

    local procedure CalcNetChange(var GLAccount: Record "G/L Account")
    begin
        GLAccount.CalcFields("Net Change");
        OnAfterCalcNetChange(GLAccount);
    end;

    procedure RoundAmount(Value: Decimal): Text[30]
    begin
        exit(MatrixMgt.FormatAmount(Value, RoundingFactor, false));
    end;

    procedure InitializeRequest(NewPeriodStartingDate: Date; NewRoundingFactor: Option; NewIndent: Option)
    begin
        PeriodStartingDate := NewPeriodStartingDate;
        RoundingFactor := "Analysis Rounding Factor".FromInteger(NewRoundingFactor);
        if NewIndent <> Indent::None then begin
            Indent := NewIndent;
            CheckIndent();
        end;
    end;

    local procedure CheckIndent()
    begin
        GLIndent.Reset();
        MaxIndent := '';
        if GLIndent.FindSet() then
            repeat
                if Format(GLIndent.Indentation) > MaxIndent then
                    MaxIndent := Format(GLIndent.Indentation);
            until GLIndent.Next() = 0;

        if Format(Indent) > MaxIndent then
            if Indent <> Indent::None then
                Error(Text014, SelectStr(Indent + 1, IndentTxt), MaxIndent);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcNetChange(var GLAccount: Record "G/L Account")
    begin
    end;
}

