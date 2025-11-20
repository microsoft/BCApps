// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;
using System.Utilities;

report 18 "Consolidated Trial Balance (4)"
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

            trigger OnAfterGetRecord()
            begin
                j := j + 1;
                if j > ArrayLen(BusUnitColumn) then
                    Error(Text002, ArrayLen(BusUnitColumn));
                BusUnitColumn[j] := "Business Unit";
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;

                j := 0;

                if BUFilter <> '' then
                    SetFilter(Code, BUFilter);
            end;
        }
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Business Unit Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO_Text003_PeriodText_; StrSubstNo(Text003, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(InThousands; InThousands)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(AmountType; AmountType)
            {
            }
            column(EmptyString; '')
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
            column(ConsolidStartDate; ConsolidStartDate)
            {
            }
            column(ConsolidEndDate; ConsolidEndDate)
            {
            }
            column(NextPageGroupNo; NextPageGroupNo)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(NewPage; "New Page")
            {
            }
            column(AccountType; Format("Account Type", 0, 2))
            {
            }
            column(NoBlankLines; "No. of Blank Lines")
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(Consolidated_Trial_Balance__4_Caption; Consolidated_Trial_Balance__4_CaptionLbl)
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
            column(Amount_1__Amount_2__Amount_3__Amount_4_Caption; Amount_1__Amount_2__Amount_3__Amount_4_CaptionLbl)
            {
            }
            column(EliminationAmountCaption; EliminationAmountCaptionLbl)
            {
            }
            column(Amount_1__Amount_2__Amount_3__Amount_4__EliminationAmountCaption; Amount_1__Amount_2__Amount_3__Amount_4__EliminationAmountCaptionLbl)
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
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_2_; Amount[2])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_3_; Amount[3])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_4_; Amount[4])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_1__Amount_2__Amount_3__Amount_4_; Amount[1] + Amount[2] + Amount[3] + Amount[4])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount; EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_1__Amount_2__Amount_3__Amount_4__EliminationAmount; Amount[1] + Amount[2] + Amount[3] + Amount[4] + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___No___Control30; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___2___G_L_Account__Name_Control31; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(Amount_1__Control32; Amount[1])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_2__Control33; Amount[2])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_3__Control34; Amount[3])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_4__Control35; Amount[4])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_1__Amount_2__Amount_3__Amount_4__Control36; Amount[1] + Amount[2] + Amount[3] + Amount[4])
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(EliminationAmount_Control37; EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Amount_1__Amount_2__Amount_3__Amount_4__EliminationAmount_Control38; Amount[1] + Amount[2] + Amount[3] + Amount[4] + EliminationAmount)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 0;
                }
                column(Integer_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                for i := j downto 1 do begin
                    SetRange("Business Unit Filter", BusUnitColumn[i].Code);
                    if (BusUnitColumn[i]."Starting Date" <> 0D) or (BusUnitColumn[i]."Ending Date" <> 0D) then
                        SetRange("Date Filter", BusUnitColumn[i]."Starting Date", BusUnitColumn[i]."Ending Date")
                    else
                        SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);

                    if AmountType = AmountType::"Net Change" then begin
                        CalcFields("Net Change");
                        Amount[i] := "Net Change";
                    end else begin
                        CalcFields("Balance at Date");
                        Amount[i] := "Balance at Date";
                    end;
                    if InThousands then
                        Amount[i] := Amount[i] / 1000;
                end;
                SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
                SetRange("Business Unit Filter", '');

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
                PageGroupNo := 1;
                NextPageGroupNo := 1;

                if j = 0 then
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
                        field(ConsolidStartDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which posted entries in the consolidated company will be shown.';
                        }
                        field(ConsolidEndDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the end date for the period to process. If a business unit has a different fiscal year than the group, enter the end date for this company in the Business Unit window.';
                        }
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show';
                        ToolTip = 'Specifies if the selected value is shown in the window.';
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
        GLFilter := "G/L Account".GetFilters();
        if ConsolidStartDate = 0D then
            Error(Text000);
        if ConsolidEndDate = 0D then
            Error(Text001);
        "G/L Account".SetRange("Date Filter", ConsolidStartDate, ConsolidEndDate);
        PeriodText := "G/L Account".GetFilter("Date Filter");

        BUFilter := "G/L Account".GetFilter("Business Unit Filter");
    end;

    var
        BusUnitColumn: array[4] of Record "Business Unit";
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        InThousands: Boolean;
        AmountType: Enum "Analysis Amount Type";
        EliminationAmount: Decimal;
        PeriodText: Text;
        Amount: array[4] of Decimal;
        i: Integer;
        j: Integer;
        BUFilter: Text;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'Enter the starting date for the consolidation period.';
        Text001: Label 'Enter the ending date for the consolidation period.';
#pragma warning disable AA0470
        Text002: Label 'A maximum of %1 consolidating companies can be included in this report.';
        Text003: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Consolidated_Trial_Balance__4_CaptionLbl: Label 'Consolidated Trial Balance (4)';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_whole_1000sCaptionLbl: Label 'Amounts are in whole 1000s.';
        PADSTR_____G_L_Account__Indentation___2___G_L_Account__NameCaptionLbl: Label 'Name';
        Amount_1__Amount_2__Amount_3__Amount_4_CaptionLbl: Label 'Total';
        EliminationAmountCaptionLbl: Label 'Eliminations';
        Amount_1__Amount_2__Amount_3__Amount_4__EliminationAmountCaptionLbl: Label 'Total Incl. Eliminations';

    protected var
        GLFilter: Text;
}

