// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

report 1125 "Cost Types Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostTypesDetails.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Types Details';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            CalcFields = "Debit Amount", "Credit Amount";
            DataItemTableView = where(Type = const("Cost Type"));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Combine Entries", "Date Filter", "Cost Center Filter", "Cost Object Filter";
            column(DtFltrCostTypeDateFilter; Text000 + ' ' + CostTypeDateFilter)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAllWithBalance; PrintAllWithBalance)
            {
            }
            column(PrintClosingEntries; PrintClosingEntries)
            {
            }
            column(CostTypeFilter; CostTypeFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(GLSetupAddiReporCurr; GLSetup."Additional Reporting Currency")
            {
            }
            column(GLSetupLCYCode; GLSetup."LCY Code")
            {
            }
            column(AllAmountAreIn; AllAmountAreInLbl)
            {
            }
            column(TableCaptCostTypeFilter; TableCaption + ': ' + CostTypeFilter)
            {
            }
            column(No_CostType; "No.")
            {
            }
            column(DateFilter_CostType; "Date Filter")
            {
            }
            column(CostCenterFltr_CostType; "Cost Center Filter")
            {
            }
            column(CostObjectFltr_CostType; "Cost Object Filter")
            {
            }
            column(CostAccountDetailsCaption; CostAccountDetailsCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(IncGLaccHavBalCaption; IncGLaccHavBalCaptionLbl)
            {
            }
            column(ClosingentrieswithinperiodCaption; ClosingentrieswithinperiodCaptionLbl)
            {
            }
            column(PostDateCaption; PostDateCaptionLbl)
            {
            }
            column(CostEntryDebitAmtCaption; CostEntryDebitAmtCaptionLbl)
            {
            }
            column(CostEntryCreditAmTCaption; CostEntryCreditAmTCaptionLbl)
            {
            }
            column(CostTypeBalanceCaption; CostTypeBalanceCaptionLbl)
            {
            }
            column(CCCaption; CCCaptionLbl)
            {
            }
            column(COCaption; COCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Name_CostType; "Cost Type".Name)
                {
                }
                column(StartBalance; StartBalance)
                {
                }
                column(StartBalanceAddCurr; StartBalanceAddCurrency)
                {
                }
                dataitem("Cost Entry"; "Cost Entry")
                {
                    DataItemLink = "Cost Type No." = field("No."), "Posting Date" = field("Date Filter"), "Cost Center Code" = field("Cost Center Filter"), "Cost Object Code" = field("Cost Object Filter");
                    DataItemLinkReference = "Cost Type";
                    DataItemTableView = sorting("Cost Type No.", "Posting Date");
                    column(DebitAmount_CostEntry; "Debit Amount")
                    {
                    }
                    column(CreditAmount_CostEntry; "Credit Amount")
                    {
                    }
                    column(FmtPostingDate_CostEntry; Format("Posting Date"))
                    {
                    }
                    column(DocumentNo_CostEntry; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Text_CostEntry; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(CostTypeBalance; CostTypeBalance)
                    {
                    }
                    column(EntryNo_CostEntry; "Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(CostObjectCode_CostEntry; "Cost Object Code")
                    {
                    }
                    column(CostCenterCode_CostEntry; "Cost Center Code")
                    {
                    }
                    column(AddCurrCrdtAmt_CostEntry; "Add.-Currency Credit Amount")
                    {
                    }
                    column(AddCurrDbtAmt_CostEntry; "Add.-Currency Debit Amount")
                    {
                    }
                    column(ShowAddCurr; ShowAddCurr)
                    {
                    }
                    column(CostTypeAddCurrBalance; CostTypeAddCurrBalance)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ("Posting Date" = ClosingDate("Posting Date")) and not PrintClosingEntries then begin
                            "Debit Amount" := 0;
                            "Credit Amount" := 0;
                        end;
                        CostTypeBalance := CostTypeBalance + Amount;
                        CostEntryLineNo := CostEntryLineNo + 1;
                        CumulatedDebitAmount := CumulatedDebitAmount + "Debit Amount";
                        CumulatedCreditAmount := CumulatedCreditAmount + "Credit Amount";
                        CostTypeAddCurrBalance := CostTypeAddCurrBalance + "Additional-Currency Amount";
                        CumulatedAddCurrDebit := CumulatedAddCurrDebit + "Add.-Currency Debit Amount";
                        CumulatedAddCurrCredit := CumulatedAddCurrCredit + "Add.-Currency Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        CostTypeBalance := StartBalance;
                        CostTypeAddCurrBalance := StartBalanceAddCurrency;
                        CostEntryLineNo := 0;
                        CumulatedDebitAmount := 0;
                        CumulatedCreditAmount := 0;
                        CumulatedAddCurrDebit := 0;
                        CumulatedAddCurrCredit := 0;
                    end;
                }
                dataitem(AccTotal; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(TotalCostTypeName; Text002 + "Cost Type".Name)
                    {
                    }
                    column(CumulatedDebitAmount; CumulatedDebitAmount)
                    {
                    }
                    column(CumulatedCreditAmt; CumulatedCreditAmount)
                    {
                    }
                    column(CostEntryLineNo; CostEntryLineNo)
                    {
                    }
                    column(CumulatedAddCurrDbt_AccTotal; CumulatedAddCurrDebit)
                    {
                    }
                    column(ShowAddCurr_AccTotal; ShowAddCurr)
                    {
                    }
                    column(CumulatedAddCurrCdt_AccTotal; CumulatedAddCurrCredit)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if CostEntryLineNo = 0 then
                            CurrReport.Skip();

                        if (CumulatedDebitAmount = 0) and
                           (CumulatedCreditAmount = 0) and
                           ((StartBalance = 0) or
                            not PrintAllWithBalance)
                        then
                            CurrReport.Skip();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CurrReport.PrintOnlyIfDetail := not (PrintAllWithBalance and (StartBalance <> 0));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                StartBalance := 0;
                StartBalanceAddCurrency := 0;
                if CostTypeDateFilter <> '' then
                    if GetRangeMin("Date Filter") <> 0D then begin
                        SetRange("Date Filter", 0D, ClosingDate(GetRangeMin("Date Filter") - 1));
                        CalcFields("Net Change");
                        StartBalance := "Net Change";
                        CalcFields("Add. Currency Net Change");
                        StartBalanceAddCurrency := "Add. Currency Net Change";
                        SetFilter("Date Filter", CostTypeDateFilter);
                    end;

                if PrintOnlyOnePerPage then begin
                    PageGroupNo := NextPageGroupNo;
                    NextPageGroupNo := PageGroupNo + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Types Details';
        AboutText = 'The **Cost Types Details** report provides a categorized breakdown of total costs by cost type—such as labor, materials, and overhead. Use it for detailed cost tracking and analysis when you need to understand how each cost type contributes to overall expenses.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'New Page per Cost Type';
                        ToolTip = 'Specifies that you want a new page to start immediately after each cost type, when you print the chart of cost types.';
                    }
                    field(PrintAllWithBalance; PrintAllWithBalance)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Process Cost Types with Balance at Date Within the Period';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want to show the balance at date for each cost type.';
                    }
                    field(PrintClosingEntries; PrintClosingEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Include Closing Entries within the Period';
                        MultiLine = true;
                        ToolTip = 'Specifies whether to include closing entries within the period.';
                    }
                    field(ShowAmountsInAddRepCurrency; ShowAddCurr)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
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
        CostTypeFilter := "Cost Type".GetFilters();
        CostTypeDateFilter := "Cost Type".GetFilter("Date Filter");

        PageGroupNo := 1;
        NextPageGroupNo := 1;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CostTypeDateFilter: Text;
        CostTypeFilter: Text;
        CostTypeBalance: Decimal;
        StartBalance: Decimal;
        StartBalanceAddCurrency: Decimal;
        PrintOnlyOnePerPage: Boolean;
        PrintAllWithBalance: Boolean;
        PrintClosingEntries: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        CostEntryLineNo: Integer;
        CumulatedDebitAmount: Decimal;
        CumulatedCreditAmount: Decimal;
        CostTypeAddCurrBalance: Decimal;
        CumulatedAddCurrDebit: Decimal;
        CumulatedAddCurrCredit: Decimal;
        ShowAddCurr: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Date filter:';
        Text002: Label 'Total';
#pragma warning restore AA0074
        AllAmountAreInLbl: Label 'All amounts are in';
        CostAccountDetailsCaptionLbl: Label 'Cost Types Details';
        PageNoCaptionLbl: Label 'Page';
        IncGLaccHavBalCaptionLbl: Label 'This report includes general ledger accounts that only have a balance.';
        ClosingentrieswithinperiodCaptionLbl: Label 'This report contains closing entries within the period.';
        PostDateCaptionLbl: Label 'Post. Date';
        CostEntryDebitAmtCaptionLbl: Label 'Debit';
        CostEntryCreditAmTCaptionLbl: Label 'Credit';
        CostTypeBalanceCaptionLbl: Label 'Balance';
        CCCaptionLbl: Label 'CC';
        COCaptionLbl: Label 'CO';
}

