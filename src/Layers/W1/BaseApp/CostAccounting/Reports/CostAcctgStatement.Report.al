// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;
using Microsoft.Finance.GeneralLedger.Setup;

report 1126 "Cost Acctg. Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgStatement.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Cost Classification", Type, "Date Filter", "Cost Center Filter", "Cost Object Filter";
            column(StrsubstnodatePeriodtxt; StrSubstNo(Text000, PeriodTxt))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CostTypeTableCaptFilter; TableCaption + ': ' + CostTypeFilter)
            {
            }
            column(NetChange; -"Net Change")
            {
            }
            column(NetChange_CostType; "Net Change")
            {
            }
            column(PadstrIndentation2Name; PadStr('', Indentation * 2) + Name)
            {
            }
            column(No_CostType; "No.")
            {
            }
            column(LineType; LineType)
            {
            }
            column(BlankLine; "Blank Line")
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(AddCurrNetChange_CostType; "Add. Currency Net Change")
            {
            }
            column(ShowAddCurr; ShowAddCurr)
            {
            }
            column(AddCurrencyNetChange; -"Add. Currency Net Change")
            {
            }
            column(AddRepCurr_GLSetup; GLSetup."Additional Reporting Currency")
            {
            }
            column(LcyCode_GLSetup; GLSetup."LCY Code")
            {
            }
            column(AllAmountAre; AllAmountAreLbl)
            {
            }
            column(CAProfitLossStatementCaption; CAProfitLossStatementCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(CostTypeNetChangeCaption; CostTypeNetChangeCaptionLbl)
            {
            }
            column(PADSTRIndentation2NameCaption; PADSTRIndentation2NameCaptionLbl)
            {
            }
            column(CostTypeNoCaption; CostTypeNoCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Net Change");
                CalcFields("Add. Currency Net Change");

                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";

                LineType := Type.AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                PageGroupNo := 1;
                NewPage := false;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Statement';
        AboutText = 'The **Cost Accounting Statement** report provides a summarized view of all posted cost data across selected dimensions such as departments or cost centers. Use it for getting a high-level overview of total costs by dimension or category to support operational analysis.';

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
                    field(ShowAmountsInAddRepCurrency; ShowAddCurr)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Show Amounts in Additional Currency';
                        ToolTip = 'Specifies that you want to display amounts in additional currency.';
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
        PeriodTxt := "Cost Type".GetFilter("Date Filter");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CostTypeFilter: Text;
        PeriodTxt: Text;
        PageGroupNo: Integer;
        NewPage: Boolean;
        LineType: Integer;
        ShowAddCurr: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Date Filter: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AllAmountAreLbl: Label 'All amounts are in';
        CAProfitLossStatementCaptionLbl: Label 'Cost Acctg. Statement';
        CurrReportPageNoCaptionLbl: Label 'Page';
        NetChangeCaptionLbl: Label 'Net Change Credit';
        CostTypeNetChangeCaptionLbl: Label 'Net Change Debit';
        PADSTRIndentation2NameCaptionLbl: Label 'Name';
        CostTypeNoCaptionLbl: Label 'Cost Type';
}

