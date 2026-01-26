// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;

report 7000005 "Bank - Risk"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Reports/BankRisk.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank - Risk';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(BankAcc; "Bank Account")
        {
            CalcFields = "Posted Receiv. Bills Rmg. Amt.";
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group";
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(BankAcc_TABLECAPTION__________BankAccTableFilter; TableCaption + ': ' + BankAccTableFilter)
            {
            }
            column(BankAccTableFilter; BankAccTableFilter)
            {
            }
            column(BankAcc__No__; "No.")
            {
            }
            column(BankAcc_Name; Name)
            {
            }
            column(BankAcc__Credit_Limit_for_Discount_; "Credit Limit for Discount")
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAcc__Posted_Receiv__Bills_Rmg__Amt__; "Posted Receiv. Bills Rmg. Amt.")
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(NonPostedDiscAmt; NonPostedDiscAmt)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(Credit_Limit_for_Discount___Posted_Receiv__Bills_Rmg__Amt; ("Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt." + Abs("Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt.")) / 2)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(Credit_Limit_for_Discount___Posted_Receiv__Bills_Rmg__Amt___NonPostedDiscAmt; (("Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt." - NonPostedDiscAmt) + Abs("Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt." - NonPostedDiscAmt)) / 2)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAcc__Currency_Code_; "Currency Code")
            {
            }
            column(CreditLimitForDiscLCY__Posted_R_Bills_Rmg__Amt___LCY___NonPostedDiscAmtLCY; ((CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)" - NonPostedDiscAmtLCY) + Abs(CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)" - NonPostedDiscAmtLCY)) / 2)
            {
                AutoFormatType = 1;
            }
            column(NonPostedDiscAmtLCY; NonPostedDiscAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(CreditLimitForDiscLCY__Posted_R_Bills_Rmg__Amt___LCY_____ABS_CreditLimitForDiscLCY; (CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)" + Abs(CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)")) / 2)
            {
                AutoFormatType = 1;
            }
            column(BankAcc__Posted_R_Bills_Rmg__Amt___LCY__; "Posted R.Bills Rmg. Amt. (LCY)")
            {
                AutoFormatType = 1;
            }
            column(CreditLimitForDiscLCY; CreditLimitForDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(BankAcc__Currency_Code__Control35; "Currency Code")
            {
            }
            column(BankAcc_Name_Control36; Name)
            {
            }
            column(BankAcc__No___Control37; "No.")
            {
            }
            column(BankAcc__Credit_Limit_for_Discount__BankAcc__Posted_Receiv__Bills_Rmg__Amt___NonPostedDiscAmt; "Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt." - NonPostedDiscAmt)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(NonPostedDiscAmt_Control24; NonPostedDiscAmt)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAcc__Credit_Limit_for_Discount__BankAcc__Posted_Receiv__Bills_Rmg__Amt__; "Credit Limit for Discount" - "Posted Receiv. Bills Rmg. Amt.")
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAcc_BankAcc__Posted_Receiv__Bills_Rmg__Amt__; "Posted Receiv. Bills Rmg. Amt.")
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(BankAcc_BankAcc__Credit_Limit_for_Discount_; "Credit Limit for Discount")
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(CreditLimitForDiscLCY_BankAcc__Posted_R_Bills_Rmg__Amt___LCY___NonPostedDiscAmtLCY; CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)" - NonPostedDiscAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(NonPostedDiscAmtLCY_Control39; NonPostedDiscAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(CreditLimitForDiscLCY_BankAcc__Posted_R_Bills_Rmg__Amt___LCY__; CreditLimitForDiscLCY - "Posted R.Bills Rmg. Amt. (LCY)")
            {
                AutoFormatType = 1;
            }
            column(BankAcc_BankAcc__Posted_R_Bills_Rmg__Amt___LCY__; "Posted R.Bills Rmg. Amt. (LCY)")
            {
                AutoFormatType = 1;
            }
            column(CreditLimitForDiscLCY_Control42; CreditLimitForDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(Bank___RiskCaption; Bank___RiskCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(BankAcc__No__Caption; FieldCaption("No."))
            {
            }
            column(BankAcc_NameCaption; FieldCaption(Name))
            {
            }
            column(BankAcc__Credit_Limit_for_Discount_Caption; FieldCaption("Credit Limit for Discount"))
            {
            }
            column(BankAcc__Posted_Receiv__Bills_Rmg__Amt__Caption; FieldCaption("Posted Receiv. Bills Rmg. Amt."))
            {
            }
            column(NonPostedDiscAmtCaption; NonPostedDiscAmtCaptionLbl)
            {
            }
            column(Credit_Limit_for_Discount___Posted_Receiv__Bills_Rmg__Amt_____ABS__Credit_Limit_for_Discount_Caption; ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_VATInLbl)
            {
            }
            column(Credit_Limit_for_Discount___Posted_Receiv__Bills_Rmg__Amt___NonPostedDiscAmt__ABS__Credit_Limit_for_Discount_Caption; Credit_Limit_for_Discount_Posted_Receiv_Bills_Rmg_Amt_NonPostedDiscAmt_ABS_Credit_Limit_for_Discount_Posted_Receiv_Lbl)
            {
            }
            column(BankAcc__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalCaption_Control43; TotalCaption_Control43Lbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                NonPostedDiscAmt := 0;
                NonPostedDiscAmtLCY := 0;

                if PrintAmountsInLCY then
                    CreditLimitForDiscLCY :=
                      CurrExchRate.ExchangeAmount("Credit Limit for Discount", "Currency Code", '', WorkDate());
                BillGr.SetRange("Bank Account No.", "No.");
                BillGr.SetRange("Dealing Type", DealingType::Discount);
                if BillGr.FindSet() then
                    if PrintAmountsInLCY then
                        repeat
                            BillGr.CalcFields("Amount (LCY)");
                            NonPostedDiscAmtLCY := NonPostedDiscAmtLCY + BillGr."Amount (LCY)";
                        until BillGr.Next() = 0
                    else
                        repeat
                            BillGr.CalcFields(Amount);
                            NonPostedDiscAmt := NonPostedDiscAmt + BillGr.Amount;
                        until BillGr.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Dealing Type Filter", DealingType::Discount);
                Clear(NonPostedDiscAmt);
                Clear(NonPostedDiscAmtLCY);
                Clear("Credit Limit for Discount");
                Clear(CreditLimitForDiscLCY);
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
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
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
        BankAccTableFilter := BankAcc.GetFilters();
    end;

    var
        BillGr: Record "Bill Group";
        CurrExchRate: Record "Currency Exchange Rate";
        BankAccTableFilter: Code[250];
        NonPostedDiscAmt: Decimal;
        NonPostedDiscAmtLCY: Decimal;
        PrintAmountsInLCY: Boolean;
        CreditLimitForDiscLCY: Decimal;
        DealingType: Option Collection,Discount;
        Bank___RiskCaptionLbl: Label 'Bank - Risk';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        NonPostedDiscAmtCaptionLbl: Label 'Non-posted Bills for Discount (Amt.)';
        ReminderInterestAmount_VAT_Amount_Issued_Reminder_Header_Additional_Fee_AddFeeInclVAT_VATInterest_100_1_VATInLbl: Label 'Discount Possible';
        Credit_Limit_for_Discount_Posted_Receiv_Bills_Rmg_Amt_NonPostedDiscAmt_ABS_Credit_Limit_for_Discount_Posted_Receiv_Lbl: Label 'Disc. Possible after Posting';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control43Lbl: Label 'Total';
}

