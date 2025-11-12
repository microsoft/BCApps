// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

report 17 "Consolidated Trial Balance"
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
            column(PeriodText; StrSubstNo(Text002, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLAccountGLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(No_GLAcc; "No.")
            {
                IncludeCaption = true;
            }
            column(InThousands; InThousands)
            {
            }
            column(ConsolidatedTrialBalCaption; ConsolidatedTrialBalCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(Amtsinwhole1000sCaption; Amtsinwhole1000sCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(AmtInclEliminationsCaption; AmtInclEliminationsCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(EliminationsCaption; EliminationsCaptionLbl)
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
                column(No_GLAcc1; "G/L Account"."No.")
                {
                }
                column(GLAccIndentation2GLAccName; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(AccountType_GLAcc; "G/L Account"."Account Type")
                {
                }
                column(AccountTypePosting; GLAccountTypePosting)
                {
                }
            }
            dataitem("Business Unit"; "Business Unit")
            {
                DataItemTableView = sorting(Code) where(Consolidate = const(true));
                column(GLAccIndentation22Code; PadStr('', "G/L Account".Indentation * 2 + 2) + Code)
                {
                }
                column(GLAccNetChange; GLAccNetChange)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(GLBalance; GLBalance)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Business Unit Filter", Code);
                    if ("Starting Date" <> 0D) and ("Ending Date" <> 0D) then
                        "G/L Account".SetRange("Date Filter", "Starting Date", "Ending Date")
                    else
                        if ("Starting Date" <> 0D) and ("Ending Date" = 0D) then
                            "G/L Account".SetRange("Date Filter", "Starting Date", ConsolidEndDate)
                        else
                            "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    "G/L Account".CalcFields("Net Change", "Balance at Date");
                    GLAccNetChange := "G/L Account"."Net Change";
                    GLBalance := "G/L Account"."Balance at Date";

                    if (GLAccNetChange = 0) and (GLBalance = 0) then
                        CurrReport.Skip();

                    if InThousands then begin
                        GLAccNetChange := GLAccNetChange / 1000;
                        GLBalance := GLBalance / 1000;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(GLAccNetChange);
                    Clear(GLBalance);

                    if BUFilter <> '' then
                        SetFilter(Code, BUFilter);
                end;
            }
            dataitem(ConsolidCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GLAccIndentation2GLAccName2; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(EliminationAmount; EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(GLAccNetChangeElmntnAmt; GLAccNetChange + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(GLBalanceEliminationAmt; GLBalance + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(NoBlankLines_GLAcc; "G/L Account"."No. of Blank Lines")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                    "G/L Account".SetRange("Business Unit Filter", '');
                    "G/L Account".CalcFields("Net Change");
                    EliminationAmount := "G/L Account"."Net Change";
                    if InThousands then
                        EliminationAmount := EliminationAmount / 1000;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
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
                        field(StartingDt; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which posted entries in the consolidated company will be shown.';
                        }
                        field(EndingDt; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the end date for the period to process. If a business unit has a different fiscal year than the group, enter the end date for this company in the Business Unit window.';
                        }
                    }
                    field(InThousands; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
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
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        GLFilter := "G/L Account".GetFilters();
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");

        BUFilter := "G/L Account".GetFilter("Business Unit Filter");
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Enter the starting date for the consolidation period.';
        Text001: Label 'Enter the ending date for the consolidation period.';
#pragma warning disable AA0470
        Text002: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InThousands: Boolean;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        GLAccNetChange: Decimal;
        GLBalance: Decimal;
        EliminationAmount: Decimal;
        PeriodText: Text;
        BUFilter: Text;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        ConsolidatedTrialBalCaptionLbl: Label 'Consolidated Trial Balance';
        PageNoCaptionLbl: Label 'Page';
        Amtsinwhole1000sCaptionLbl: Label 'Amounts are in whole 1000s.';
        AmountCaptionLbl: Label 'Amount';
        AmtInclEliminationsCaptionLbl: Label 'Amount Incl. Eliminations';
        NameCaptionLbl: Label 'Name';
        NetChangeCaptionLbl: Label 'Net Change';
        BalanceCaptionLbl: Label 'Balance';
        EliminationsCaptionLbl: Label 'Eliminations';
        GLAccountTypePosting: Boolean;

    protected var
        GLFilter: Text;
}

