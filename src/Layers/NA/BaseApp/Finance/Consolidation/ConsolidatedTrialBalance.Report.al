// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using System.Utilities;

/// <summary>
/// Generates consolidated trial balance report showing account balances from multiple business units.
/// Provides comprehensive trial balance view across consolidated companies with period comparisons.
/// </summary>
/// <remarks>
/// Report aggregates G/L account balances from consolidated business units with period and dimension filtering.
/// Supports currency conversion and multiple reporting options including thousands display.
/// Integration with consolidated G/L entries for multi-company reporting scenarios.
/// </remarks>
report 10007 "Consolidated Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/ConsolidatedTrialBalance.rdlc';
    ApplicationArea = Suite;
    Caption = 'Consolidated Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
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
            column(SubTitle; SubTitle)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(InThousands; InThousands)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(G_L_Account__No__of_Blank_Lines_; "No. of Blank Lines")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Consolidated_Trial_BalanceCaption; Consolidated_Trial_BalanceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Amounts_are_in_whole_1000sCaption; Amounts_are_in_whole_1000sCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Amount_Incl__EliminationsCaption; Amount_Incl__EliminationsCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control26Caption; PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control26CaptionLbl)
            {
            }
            column(GLAccNetChange_Control27Caption; GLAccNetChange_Control27CaptionLbl)
            {
            }
            column(GLBalance_Control28Caption; GLBalance_Control28CaptionLbl)
            {
            }
            column(EliminationAmountCaption; EliminationAmountCaptionLbl)
            {
            }
            column(GLAccNetChange_EliminationAmountCaption; GLAccNetChange_EliminationAmountCaptionLbl)
            {
            }
            column(GLBalance_EliminationAmountCaption; GLBalance_EliminationAmountCaptionLbl)
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
                column(Integer_Number; Number)
                {
                }
            }
            dataitem("Business Unit"; "Business Unit")
            {
                DataItemTableView = sorting(Code) where(Consolidate = const(true));
                column(PADSTR_____G_L_Account__Indentation___2___2__Code; PadStr('', "G/L Account".Indentation * 2 + 2) + Code)
                {
                }
                column(GLAccNetChange; GLAccNetChange)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBalance; GLBalance)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Business_Unit_Code; Code)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Business Unit Filter", Code);
                    if ("Starting Date" <> 0D) or ("Ending Date" <> 0D) then
                        "G/L Account".SetRange("Date Filter", "Starting Date", "Ending Date")
                    else
                        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    if UseAddRptCurr then begin
                        "G/L Account".CalcFields("Additional-Currency Net Change", "Add.-Currency Balance at Date");
                        GLAccNetChange := "G/L Account"."Additional-Currency Net Change";
                        GLBalance := "G/L Account"."Add.-Currency Balance at Date";
                    end else begin
                        "G/L Account".CalcFields("Net Change", "Balance at Date");
                        GLAccNetChange := "G/L Account"."Net Change";
                        GLBalance := "G/L Account"."Balance at Date";
                    end;

                    if (GLAccNetChange = 0) and (GLBalance = 0) then
                        CurrReport.Skip();

                    if InThousands then begin
                        GLAccNetChange := GLAccNetChange / 1000;
                        GLBalance := GLBalance / 1000;
                    end;
                    GLAccNetChangeSum += GLAccNetChange;
                    GLBalanceSum += GLBalance;
                end;

                trigger OnPreDataItem()
                begin
                    if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
                       ("G/L Account".Totaling = '')
                    then
                        CurrReport.Break();
                    GLAccNetChangeSum := 0;
                    GLBalanceSum := 0;
                end;
            }
            dataitem(ConsolidCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control26; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLAccNetChange_Control27; GLAccNetChangeSum)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBalance_Control28; GLBalanceSum)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount; EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLAccNetChange_EliminationAmount; GLAccNetChangeSum + EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(GLBalance_EliminationAmount; GLBalanceSum + EliminationAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ConsolidCounter_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                    "G/L Account".SetRange("Business Unit Filter", '');
                    if UseAddRptCurr then begin
                        "G/L Account".CalcFields("Additional-Currency Net Change");
                        EliminationAmount := "G/L Account"."Additional-Currency Net Change";
                    end else begin
                        "G/L Account".CalcFields("Net Change");
                        EliminationAmount := "G/L Account"."Net Change";
                    end;

                    if (GLAccNetChange = 0) and (GLBalance = 0) and (EliminationAmount = 0) then
                        CurrReport.Skip();
                    if InThousands then
                        EliminationAmount := EliminationAmount / 1000;
                end;

                trigger OnPreDataItem()
                begin
                    if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
                       ("G/L Account".Totaling = '')
                    then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Consolidated Trial Balance';
        AboutText = 'Combines financial data across companies, allowing finance teams to analyze consolidated performance and ensure alignment across entities. Use this report when reviewing financial results across multiple companies within an organization.';
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
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the last date until which information in the report is shown. If left blank, the report shows information until the present time.';
                        }
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
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        GLFilter := "G/L Account".GetFilters();
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");
        SubTitle := StrSubstNo(Text002, PeriodText);
        if UseAddRptCurr then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := SubTitle + '  ' + StrSubstNo(Text003, Currency.Description);
        end;
    end;

    var
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        SubTitle: Text;
        InThousands: Boolean;
        UseAddRptCurr: Boolean;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        GLAccNetChange: Decimal;
        GLAccNetChangeSum: Decimal;
        GLBalance: Decimal;
        GLBalanceSum: Decimal;
        EliminationAmount: Decimal;
        PeriodText: Text;
#pragma warning disable AA0074
        Text000: Label 'Please enter the starting date for the consolidation period.';
        Text001: Label 'Please enter the ending date for the consolidation period.';
#pragma warning disable AA0470
        Text002: Label 'Period: %1';
#pragma warning restore AA0470
        Text003: Label '(using %1)';
#pragma warning restore AA0074
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Consolidated_Trial_BalanceCaptionLbl: Label 'Consolidated Trial Balance';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_whole_1000sCaptionLbl: Label 'Amounts are in whole 1000s';
        AmountCaptionLbl: Label 'Amount';
        Amount_Incl__EliminationsCaptionLbl: Label 'Amount Incl. Eliminations';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control26CaptionLbl: Label 'Name';
        GLAccNetChange_Control27CaptionLbl: Label 'Net Change';
        GLBalance_Control28CaptionLbl: Label 'Balance';
        EliminationAmountCaptionLbl: Label 'Eliminations';
        GLAccNetChange_EliminationAmountCaptionLbl: Label 'Net Change';
        GLBalance_EliminationAmountCaptionLbl: Label 'Balance';

    protected var
        GLFilter: Text;
}

