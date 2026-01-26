// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using System.Utilities;

/// <summary>
/// Generates consolidated trial balance report with four-column layout for comprehensive financial analysis.
/// Provides enhanced trial balance view with multiple period comparisons and detailed account breakdowns.
/// </summary>
/// <remarks>
/// Extended trial balance report with four-column format for period-over-period analysis across consolidated entities.
/// Supports advanced filtering by consolidation dates, amount types, and currency conversion options.
/// Integrates with consolidated G/L entries for multi-company financial reporting and analysis.
/// </remarks>
report 10008 "Consolidated Trial Balance (4)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/ConsolidatedTrialBalance4.rdlc';
    ApplicationArea = Suite;
    Caption = 'Consolidated Trial Balance (4)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Business Unit"; "Business Unit")
        {
            DataItemTableView = sorting(Code) where(Consolidate = const(true));
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                NumBusUnits := NumBusUnits + 1;
                if NumBusUnits > ArrayLen(BusUnitColumn) then
                    Error(Text004, ArrayLen(BusUnitColumn), TableCaption);
                BusUnitColumn[NumBusUnits] := "Business Unit";
            end;

            trigger OnPreDataItem()
            begin
                NumBusUnits := 0;
            end;
        }
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(MainTitle; MainTitle)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(G_L_Account__No__of_Blank_Lines_; "No. of Blank Lines")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(BusUnitFilter; BusUnitFilter)
            {
            }
            column(InThousands; InThousands)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(Business_Unit__TABLECAPTION__________BusUnitFilter; "Business Unit".TableCaption + ': ' + BusUnitFilter)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(AmountType; AmountType)
            {
            }
            column(BusUnitColumn_1__Code; BusUnitColumn[1].Code)
            {
            }
            column(BusUnitColumn_2__Code; BusUnitColumn[2].Code)
            {
            }
            column(BusUnitColumn_3__Code; BusUnitColumn[3].Code)
            {
            }
            column(BusUnitColumn_4__Code; BusUnitColumn[4].Code)
            {
            }
            column(AnyAmountsNotZero; AnyAmountsNotZero())
            {
            }
            column(TotalBusUnitAmounts; TotalBusUnitAmounts())
            {
            }
            column(G_L_Account__G_L_Account___Account_Type_; "G/L Account"."Account Type")
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Amounts_are_in_whole_1000sCaption; Amounts_are_in_whole_1000sCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl)
            {
            }
            column(TotalBusUnitAmounts__Caption; TotalBusUnitAmounts__CaptionLbl)
            {
            }
            column(EliminationAmountCaption; EliminationAmountCaptionLbl)
            {
            }
            column(TotalBusUnitAmounts___EliminationAmountCaption; TotalBusUnitAmounts___EliminationAmountCaptionLbl)
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
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(Amount_1_; Amount[1])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_2_; Amount[2])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_3_; Amount[3])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_4_; Amount[4])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBusUnitAmounts__; TotalBusUnitAmounts())
                {
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount; EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBusUnitAmounts___EliminationAmount; TotalBusUnitAmounts() + EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ShowCondition_Integer_Body_1; (AnyAmountsNotZero() and ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting)))
                {
                }
                column(G_L_Account___No___Control30; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control31; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(Amount_1__Control32; Amount[1])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_2__Control33; Amount[2])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_3__Control34; Amount[3])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_4__Control35; Amount[4])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBusUnitAmounts___Control36; TotalBusUnitAmounts())
                {
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount_Control37; EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBusUnitAmounts___EliminationAmount_Control38; TotalBusUnitAmounts() + EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ShowCondition_Integer_Body_2; ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting))
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnPostDataItem()
                begin
                    if "G/L Account"."New Page" then
                        PageGroupNo := PageGroupNo + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                for CurBusUnit := NumBusUnits downto 1 do begin
                    SetRange("Business Unit Filter", BusUnitColumn[CurBusUnit].Code);
                    if (BusUnitColumn[CurBusUnit]."Starting Date" <> 0D) or (BusUnitColumn[CurBusUnit]."Ending Date" <> 0D) then
                        SetRange("Date Filter", BusUnitColumn[CurBusUnit]."Starting Date", BusUnitColumn[CurBusUnit]."Ending Date")
                    else
                        SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    if UseAddRptCurr then
                        if AmountType = AmountType::"Net Change" then begin
                            CalcFields("Additional-Currency Net Change");
                            Amount[CurBusUnit] := "Additional-Currency Net Change";
                        end else begin
                            CalcFields("Add.-Currency Balance at Date");
                            Amount[CurBusUnit] := "Add.-Currency Balance at Date";
                        end
                    else
                        if AmountType = AmountType::"Net Change" then begin
                            CalcFields("Net Change");
                            Amount[CurBusUnit] := "Net Change";
                        end else begin
                            CalcFields("Balance at Date");
                            Amount[CurBusUnit] := "Balance at Date";
                        end;
                    if InThousands then
                        Amount[CurBusUnit] := Amount[CurBusUnit] / 1000;
                end;
                SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                SetRange("Business Unit Filter", '');

                if UseAddRptCurr then
                    if AmountType = AmountType::"Net Change" then begin
                        CalcFields("Additional-Currency Net Change");
                        EliminationAmount := "Additional-Currency Net Change";
                    end else begin
                        CalcFields("Add.-Currency Balance at Date");
                        EliminationAmount := "Add.-Currency Balance at Date";
                    end
                else
                    if AmountType = AmountType::"Net Change" then begin
                        CalcFields("Net Change");
                        EliminationAmount := "Net Change";
                    end else begin
                        CalcFields("Balance at Date");
                        EliminationAmount := "Balance at Date";
                    end;
                if InThousands then
                    EliminationAmount := EliminationAmount / 1000;
            end;

            trigger OnPreDataItem()
            begin
                if NumBusUnits = 0 then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Consolidated Trial Balance (4)';
        AboutText = 'Offers enhanced visibility into financial performance across companies with breakdowns by company, adjustments, and totals in one report. Use this report when you need a detailed breakdown of consolidation components.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Consolidation Period")
                    {
                        Caption = 'Consolidation Period';
                        field(StartingDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the start date for the period to process. If a business unit has a different fiscal year than the group, enter the start date for this company in the Business Unit window.';
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the period to process. If a business unit has a different fiscal year than the group, enter the end date for this company in the Business Unit window.';
                        }
                    }
                    field(Show; AmountType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show';
                        ToolTip = 'Specifies if the selected value is shown in the window.';
                    }
                    field(AmountsInWhole1000s; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies that you want to print amounts in whole 1,000 dollar increments.';
                    }
                    field(UseAdditionalReportingCurrency; UseAddRptCurr)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use Additional Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want all amounts to be printed by using the additional reporting currency. If this field is not selected, all amounts will be printed in U.S. dollars.';
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
        CompanyInformation.Get();
        GLFilter := "G/L Account".GetFilters();
        BusUnitFilter := "Business Unit".GetFilters();
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");
        MainTitle := StrSubstNo(Text002, PeriodText);
        if UseAddRptCurr then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := StrSubstNo(Text003, Currency.Description);
        end;
    end;

    var
        CompanyInformation: Record "Company Information";
        BusUnitColumn: array[4] of Record "Business Unit";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        InThousands: Boolean;
        AmountType: Enum "Analysis Amount Type";
        BusUnitFilter: Text;
        MainTitle: Text;
        SubTitle: Text;
        EliminationAmount: Decimal;
        PeriodText: Text;
        Amount: array[4] of Decimal;
        CurBusUnit: Integer;
        NumBusUnits: Integer;
        UseAddRptCurr: Boolean;
        PageGroupNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Please enter the starting date for the consolidation period.';
        Text001: Label 'Please enter the ending date for the consolidation period.';
#pragma warning disable AA0470
        Text002: Label 'Consolidated Trial Balance for %1';
        Text003: Label '(amounts are in %1)';
        Text004: Label 'A maximum of %1 consolidating companies can be included in this report. Set a filter on the %2 tab.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_whole_1000sCaptionLbl: Label 'Amounts are in whole 1000s';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl: Label 'Name';
        TotalBusUnitAmounts__CaptionLbl: Label 'Total';
        EliminationAmountCaptionLbl: Label 'Eliminations';
        TotalBusUnitAmounts___EliminationAmountCaptionLbl: Label 'Total Incl. Eliminations';

    protected var
        GLFilter: Text;

    procedure AnyAmountsNotZero(): Boolean
    var
        i: Integer;
    begin
        if EliminationAmount <> 0 then
            exit(true);
        for i := 1 to NumBusUnits do
            if Amount[i] <> 0 then
                exit(true);
        exit(false);
    end;

    procedure TotalBusUnitAmounts(): Decimal
    var
        i: Integer;
        TotAmt: Decimal;
    begin
        TotAmt := 0;
        for i := 1 to NumBusUnits do
            TotAmt := TotAmt + Amount[i];
        exit(TotAmt);
    end;
}

