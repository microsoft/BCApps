// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;

report 7000004 "Bank - Summ. Bill Group"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Receivables/BankSummBillGroup.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank - Summ. Bill Group';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(BankAcc; "Bank Account")
        {
            CalcFields = "Posted Receiv. Bills Amt.", "Posted Receiv Bills Amt. (LCY)", "Closed Receiv. Bills Amt.", "Closed Receiv Bills Amt. (LCY)";
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(BankAcc_TABLECAPTION__________BankAccTableFilter; TableCaption + ': ' + BankAccTableFilter)
            {
            }
            column(BankAccTableFilter; BankAccTableFilter)
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(BankAcc__No__; "No.")
            {
            }
            column(BankAcc_Name; Name)
            {
            }
            column(BankAcc__Bank_Acc__Posting_Group_; "Bank Acc. Posting Group")
            {
            }
            column(BankAcc__Our_Contact_Code_; "Our Contact Code")
            {
            }
            column(BankAddr_5_; BankAddr[5])
            {
            }
            column(BankAcc_Contact; Contact)
            {
            }
            column(BankAcc__Phone_No__; "Phone No.")
            {
            }
            column(BankAddr_6_; BankAddr[6])
            {
            }
            column(BankAddr_7_; BankAddr[7])
            {
            }
            column(BankAddr_4_; BankAddr[4])
            {
            }
            column(BankAddr_3_; BankAddr[3])
            {
            }
            column(BankAddr_1_; BankAddr[1])
            {
            }
            column(BankAddr_2_; BankAddr[2])
            {
            }
            column(BankAcc__Operation_Fees_Code_; "Operation Fees Code")
            {
            }
            column(BankAcc__Last_Bill_Gr__No__; "Last Bill Gr. No.")
            {
            }
            column(BankAcc__Date_of_Last_Post__Bill_Gr__; Format("Date of Last Post. Bill Gr."))
            {
            }
            column(PostedBillAmt; PostedBillAmt)
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(ClosedBillAmt; ClosedBillAmt)
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(BankAcc__Currency_Code_; "Currency Code")
            {
            }
            column(PostedBillAmt_Control5; PostedBillAmt)
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(ClosedBillAmt_Control6; ClosedBillAmt)
            {
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
            }
            column(Bank___Summ__Bill_GroupCaption; Bank___Summ__Bill_GroupCaptionLbl)
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
            column(BankAcc__Bank_Acc__Posting_Group_Caption; FieldCaption("Bank Acc. Posting Group"))
            {
            }
            column(BankAcc__Our_Contact_Code_Caption; FieldCaption("Our Contact Code"))
            {
            }
            column(BankAcc__Operation_Fees_Code_Caption; FieldCaption("Operation Fees Code"))
            {
            }
            column(BankAcc__Last_Bill_Gr__No__Caption; FieldCaption("Last Bill Gr. No."))
            {
            }
            column(BankAcc__Date_of_Last_Post__Bill_Gr__Caption; BankAcc__Date_of_Last_Post__Bill_Gr__CaptionLbl)
            {
            }
            column(PostedBillAmtCaption; PostedBillAmtCaptionLbl)
            {
            }
            column(ClosedBillAmtCaption; ClosedBillAmtCaptionLbl)
            {
            }
            column(BankAcc_ContactCaption; FieldCaption(Contact))
            {
            }
            column(BankAcc__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(BankAcc__Currency_Code_Caption; BankAcc__Currency_Code_CaptionLbl)
            {
            }
            column(PostedBillAmt_Control5Caption; PostedBillAmt_Control5CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddress.FormatAddr(
                  BankAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");

                if PrintAmountsInLCY then begin
                    PostedBillAmt := "Posted Receiv Bills Amt. (LCY)";
                    ClosedBillAmt := "Closed Receiv Bills Amt. (LCY)";
                end else begin
                    PostedBillAmt := "Posted Receiv. Bills Amt.";
                    ClosedBillAmt := "Closed Receiv. Bills Amt.";
                end;
            end;

            trigger OnPreDataItem()
            begin
                Clear(PostedBillAmt);
                Clear(ClosedBillAmt);
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
        FormatAddress: Codeunit "Format Address";
        BankAddr: array[8] of Text[100];
        BankAccTableFilter: Text[250];
        PrintAmountsInLCY: Boolean;
        ClosedBillAmt: Decimal;
        PostedBillAmt: Decimal;
        Bank___Summ__Bill_GroupCaptionLbl: Label 'Bank - Summ. Bill Group';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        BankAcc__Date_of_Last_Post__Bill_Gr__CaptionLbl: Label 'Date of Last Post. Bill Gr.';
        PostedBillAmtCaptionLbl: Label 'Posted Receiv. Bills Amt.';
        ClosedBillAmtCaptionLbl: Label 'Closed Receiv. Bills Amt.';
        BankAcc__Currency_Code_CaptionLbl: Label 'Currency Code';
        PostedBillAmt_Control5CaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if PrintAmountsInLCY then
            exit('');

        exit(BankAcc."Currency Code");
    end;
}

