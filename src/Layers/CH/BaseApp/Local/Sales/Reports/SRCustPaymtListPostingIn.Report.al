// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 11570 "SR Cust. Paymt List Posting In"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustPaymtListPostingIn.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Payments List Posting Info';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.", "Posting Date");
            RequestFilterFields = "Customer No.", "Posting Date", "Customer Posting Group", "Currency Code", Open, "Salesperson Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(LayoutPostingInfo; Text006)
            {
            }
            column(SortingTypeNo; SortingTypeNo)
            {
            }
            column(Filters; Text004 + GetFilters)
            {
            }
            column(NoOfPmts; NoOfPmts)
            {
            }
            column(AmtLCY_CustLedgerEntry; "Amount (LCY)")
            {
            }
            column(AccNo; AccNo)
            {
            }
            column(EntryNo_CustLedgerEntry; "Entry No.")
            {
            }
            column(CustPostingGrp_CustLedgerEntry; "Customer Posting Group")
            {
            }
            column(GlobalDim1Code_CustLedgerEntry; "Global Dimension 1 Code")
            {
            }
            column(GlobalDim2Code_CustLedgerEntry; "Global Dimension 2 Code")
            {
            }
            column(SalespersonCode_CustLedgerEntry; "Salesperson Code")
            {
            }
            column(UserID_CustLedgerEntry; "User ID")
            {
            }
            column(SourceCode_CustLedgerEntry; "Source Code")
            {
            }
            column(TransactionNo_CustLedgerEntry; "Transaction No.")
            {
            }
            column(PostingDate_CustLedgerEntry; Format("Posting Date"))
            {
            }
            column(DocType_CustLedgerEntry; CopyStr(Format("Document Type"), 1, 1))
            {
            }
            column(DocNo_CustLedgerEntry; "Document No.")
            {
            }
            column(TotalCustomer; Text005 + ' ' + Customer."No." + ', ' + Customer.Name)
            {
            }
            column(PmtDiscLCY; PmtDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(PaymentLCY; PaymentLCY)
            {
                AutoFormatType = 1;
            }
            column(CustomerPaymentsListCaption; CustomerPaymentsListCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AmtLCYCaption; AmtLCYCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
            column(SrcCaption; SrcCaptionLbl)
            {
            }
            column(UserIDCaption; UserIDCaptionLbl)
            {
            }
            column(SPCaption; SPCaptionLbl)
            {
            }
            column(COCaption; COCaptionLbl)
            {
            }
            column(CCCaption; CCCaptionLbl)
            {
            }
            column(TrNoCaption; TrNoCaptionLbl)
            {
            }
            column(PostGrCaption; PostGrCaptionLbl)
            {
            }
            column(EntryNoCaption_CustLedgerEntry; FieldCaption("Entry No."))
            {
            }
            column(DocCaption; DocCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(CustNo_CustLedgerEntry; "Customer No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not ("Document Type" in ["Document Type"::Payment]) then
                    CurrReport.Skip();

                CalcFields("Original Amt. (LCY)");

                AccNo := "Cust. Ledger Entry"."Customer No.";

                if Sorting = Sorting::Customer then begin
                    LinesPerGrp := LinesPerGrp + 1;
                    if LinesPerGrp > 1 then
                        AccNo := '';
                end;

                NoOfPmts := NoOfPmts + 1;
                if NoOfRSPG = 0 then
                    NoOfRSPG := 1;

                Customer.Get("Customer No.");
            end;

            trigger OnPreDataItem()
            begin
                if Sorting = Sorting::Chronological then
                    "Cust. Ledger Entry".SetCurrentKey("Entry No.");

                GlSetup.Get();
                Clear(PmtDiscLCY);
                Clear(PaymentLCY);
                Clear(NoOfRSPG);
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
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Customer with Group Total,Chronological by Entry No.';
                        ToolTip = 'Specifies how the information is sorted.';
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
        SortingTypeNo := Sorting;
    end;

    var
        Text004: Label 'Filter: ';
        Text005: Label 'Total Customer';
        GlSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Sorting: Option Customer,Chronological;
        LinesPerGrp: Integer;
        NoOfPmts: Integer;
        AccNo: Code[20];
        Text006: Label 'Layout Posting Info';
        PmtDiscLCY: Decimal;
        PaymentLCY: Decimal;
        SortingTypeNo: Integer;
        NoOfRSPG: Decimal;
        CustomerPaymentsListCaptionLbl: Label 'Customer Payments List';
        PageNoCaptionLbl: Label 'Page';
        AmtLCYCaptionLbl: Label 'Amt. LCY';
        CustomerNoCaptionLbl: Label 'Customer No.';
        SrcCaptionLbl: Label 'Src';
        UserIDCaptionLbl: Label 'User ID';
        SPCaptionLbl: Label 'S.P.';
        COCaptionLbl: Label 'CO';
        CCCaptionLbl: Label 'CC';
        TrNoCaptionLbl: Label 'Tr No';
        PostGrCaptionLbl: Label 'Post Gr.';
        DocCaptionLbl: Label 'Doc.';
        DateCaptionLbl: Label 'Date';
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure CalcExrate(FcyAmt: Decimal; LcyAmt: Decimal) ExRate: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (FcyAmt <> 0) and (FcyAmt <> LcyAmt) then begin
            CurrExchRate.SetRange("Currency Code", "Cust. Ledger Entry"."Currency Code");
            CurrExchRate.SetFilter("Starting Date", '<=%1', "Cust. Ledger Entry"."Posting Date");
            if CurrExchRate.FindLast() then;
            ExRate := Round(LcyAmt * CurrExchRate."Exchange Rate Amount" / FcyAmt, 0.001);
        end else
            ExRate := 0;
    end;
}

