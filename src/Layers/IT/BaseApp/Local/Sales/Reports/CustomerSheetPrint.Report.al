// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

report 12104 "Customer Sheet - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerSheetPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Sheet - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Currency Filter";
            column(CompAddr4; CompAddr[4])
            {
            }
            column(CompAddr5; CompAddr[5])
            {
            }
            column(CompAddr3; CompAddr[3])
            {
            }
            column(CompAddr2; CompAddr[2])
            {
            }
            column(AllCustDateFilter; PeriodCaptionLbl + CustDateFilter)
            {
            }
            column(CompAddr1; CompAddr[1])
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Filters1; Filters[1])
            {
            }
            column(Filters2; Filters[2])
            {
            }
            column(CustFilterNo; CustFilterNo)
            {
            }
            column(AmtsAreInGLSetupLCYCode; Text002 + GLSetup."LCY Code")
            {
            }
            column(CustDateFilter; CustDateFilter)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(CustCustNoCustName; Text003 + ': ' + Customer."No." + ' - ' + Customer.Name)
            {
            }
            column(No_Customer; Customer."No.")
            {
            }
            column(CurrencyFilter_Customer; "Currency Filter")
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(CustomerSheetCaption; CustomerSheetCaptionLbl)
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(DepartmentCodeCaption; DepartmentCodeCaptionLbl)
            {
            }
            column(ProjectNoCaption; ProjectNoCaptionLbl)
            {
            }
            column(IcreasesAmntCaption; DebitAmountCaptionLbl)
            {
            }
            column(DecreasesAmntCaption; CreditAmountCaptionLbl)
            {
            }
            column(AmntCaption; BalanceCaptionLbl)
            {
            }
            column(CustLedgEntryEntryNoCaption; "Cust. Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(CustLedgEntryTransNoCaption; "Cust. Ledger Entry".FieldCaption("Transaction No."))
            {
            }
            column(CustLedgEntryPostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(CustLedgEntryDocNoCaption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(CustLedgEntryDocDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(CustLedgEntryExternalDocNoCaption; "Cust. Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(CustLedgEntryDescCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(OrigAmountCaption; OrigAmountCaptionLbl)
            {
            }
            column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(StartOnHand; StartOnHand)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 5;
                }
                column(ProgressiveTotAtMinDateFormat; ProgressiveTotAtCaptionLbl + Format(MinimunDate))
                {
                }
                column(ProgressiveTotalAt; ProgressiveTotAtCaptionLbl)
                {
                }
                column(MinimunDate; MinimunDate)
                {
                }
                column(PrintedEntriesTotalCaption; PrintedEntriesTotCaptionLbl)
                {
                }
                column(PrintedEntriesTotProgressiveTotCaption; PrintedEntriesTotProgressiveTotCaptionLbl)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Posting Date" = field("Date Filter"), "Currency Code" = field("Currency Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Posting Date", "Transaction No.", "Entry No.") order(ascending);
                    column(StartOnHandAmountLCY; StartOnHand + AmountLCY)
                    {
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }
                    column(EntryNo_CustLedgerEntry; "Entry No.")
                    {
                    }
                    column(TransactionNo_CustLedgEntry; "Transaction No.")
                    {
                    }
                    column(PostingDateFormat_CustLedgerEntry; Format("Posting Date"))
                    {
                    }
                    column(DocNo_CustLedgEntry; "Document No.")
                    {
                    }
                    column(DocDateFormat_CustLedgEntry; Format("Document Date"))
                    {
                    }
                    column(ExternalDocNo_CustLedgEntry; "External Document No.")
                    {
                    }
                    column(Desc_CustLedgerEntry; Description)
                    {
                    }
                    column(IcreasesAmnt; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DecreasesAmnt; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(Amnt; Amnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(OrigAmount; OrigAmount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrencyCode; CurrencyCode)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amnt2; Amnt2)
                    {
                    }
                    column(DecreasesAmnt2; DecreasesAmnt2)
                    {
                    }
                    column(IcreasesAmnt2; IcreasesAmnt2)
                    {
                    }
                    column(AmountLCY2; AmountLCY2)
                    {
                    }
                    column(DetCustLedgEntryCount; DetCustLedgEntry.Count)
                    {
                    }
                    column(AmountLCY; AmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(CustNo_CustLedgerEntry; "Customer No.")
                    {
                    }
                    column(CurrCode_CustLedgerEntry; "Currency Code")
                    {
                    }
                    column(TotalAmtForRTC; TotalAmtForRTC)
                    {
                    }
                    column(TotalIcreasesAmtForRTC; TotalIcreasesAmtForRTC)
                    {
                    }
                    column(TotalDecreasesAmtForRTC; TotalDecreasesAmtForRTC)
                    {
                    }
                    column(TotalAmountLCYForRTC; TotalAmountLCYForRTC)
                    {
                    }
                    dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                    {
                        column(TransactionNo_DtldCustLedgEntry; "Transaction No.")
                        {
                        }
                        column(PostingDateFormat_DtldCustLedgEntry; Format("Posting Date"))
                        {
                        }
                        column(DocNo_DtldCustLedgEntry; "Document No.")
                        {
                        }
                        column(CustLedgEntryDocDateFormat; Format("Cust. Ledger Entry"."Document Date"))
                        {
                        }
                        column(CustLedgEntryExternalDocNo; "Cust. Ledger Entry"."External Document No.")
                        {
                        }
                        column(EntryType_DtldCustLedgEntry; "Entry Type")
                        {
                        }
                        column(DebitAmtLCY_DtldCustLedgEntry; "Debit Amount (LCY)")
                        {
                        }
                        column(CrAmtLCY_DtldCustLedgEntry; "Credit Amount (LCY)")
                        {
                        }
                        column(CustLedgEntryNo_DtldCustLedgEntry; "Cust. Ledger Entry No.")
                        {
                        }
                        column(EntryNo_DtldCustLedgEntry; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Amnt := Amnt + "Amount (LCY)";
                            IcreasesAmnt := IcreasesAmnt + "Debit Amount (LCY)";
                            DecreasesAmnt := DecreasesAmnt + "Credit Amount (LCY)";
                            AmountLCY := AmountLCY + "Amount (LCY)";

                            TotalAmtForRTC += "Amount (LCY)";
                            TotalIcreasesAmtForRTC += "Debit Amount (LCY)";
                            TotalDecreasesAmtForRTC += "Credit Amount (LCY)";
                            TotalAmountLCYForRTC += "Amount (LCY)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Document Type", "Cust. Ledger Entry"."Document Type");
                            SetRange("Document No.", "Cust. Ledger Entry"."Document No.");
                            SetRange("Entry Type", "Entry Type"::"Correction of Remaining Amount");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        AmountLCY := 0;
                        IcreasesAmnt := 0;
                        DecreasesAmnt := 0;

                        DetCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                        DetCustLedgEntry.SetRange("Cust. Ledger Entry No.", "Entry No.");

                        DetCustLedgEntry.SetFilter("Entry Type",
                          StrSubstNo('<>%1 & <>%2 & <>%3',
                            DetCustLedgEntry."Entry Type"::Application,
                            DetCustLedgEntry."Entry Type"::"Appln. Rounding",
                            DetCustLedgEntry."Entry Type"::"Correction of Remaining Amount"));

                        DetCustLedgEntry.SetFilter("Posting Date", CustDateFilter);
                        DetCustLedgEntry.CalcSums("Amount (LCY)");
                        AmountLCY := DetCustLedgEntry."Amount (LCY)";

                        Amnt := Amnt + AmountLCY;

                        if AmountLCY > 0 then
                            IcreasesAmnt := AmountLCY
                        else
                            DecreasesAmnt := Abs(AmountLCY);

                        CalcFields(Amount);

                        if "Currency Code" <> '' then begin
                            CurrencyCode := "Currency Code";
                            OrigAmount := Format(Amount);
                        end else begin
                            CurrencyCode := '';
                            OrigAmount := '';
                        end;

                        Amnt2 := Amnt;
                        IcreasesAmnt2 := IcreasesAmnt;
                        DecreasesAmnt2 := DecreasesAmnt;
                        AmountLCY2 := AmountLCY;

                        TotalAmtForRTC += Amnt2;
                        TotalIcreasesAmtForRTC += IcreasesAmnt2;
                        TotalDecreasesAmtForRTC += DecreasesAmnt2;
                        TotalAmountLCYForRTC += AmountLCY2;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmtForRTC := 0;
                        TotalIcreasesAmtForRTC := 0;
                        TotalDecreasesAmtForRTC := 0;
                        TotalAmountLCYForRTC := 0;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                StartOnHand := 0;
                if CustDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change (LCY)");
                        StartOnHand := "Net Change (LCY)";
                        SetFilter("Date Filter", CustDateFilter);
                    end;
                Amnt := StartOnHand;

                if Customer.GetFilter("No.") <> '' then
                    CustFilterNo := Customer.GetFilter("No.")
                else
                    CustFilterNo := Text001;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompAddr[1] := CompanyInfo.Name;
                CompAddr[2] := CompanyInfo.Address;
                CompAddr[3] := CompanyInfo."Post Code";
                CompAddr[4] := CompanyInfo.City;
                CompAddr[5] := CompanyInfo."Fiscal Code";
                CompressArray(CompAddr);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        GLSetup.Get();
        CustDateFilter := Customer.GetFilter("Date Filter");
        if CustDateFilter <> '' then begin
            MinimunDate := Customer.GetRangeMin("Date Filter") - 1;
            ITReportManagement.CheckSalesDocNoGaps(Customer.GetRangeMax("Date Filter"), false);
        end else
            ITReportManagement.CheckSalesDocNoGaps(0D, false);
    end;

    var
        Text001: Label 'ALL';
        Text002: Label 'Amounts are in ';
        Text003: Label 'Customer';
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        DetCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CompAddr: array[5] of Text[100];
        CustFilterNo: Text[30];
        CustDateFilter: Text;
        Filters: array[2] of Text[20];
        OrigAmount: Text[30];
        Amnt: Decimal;
        StartOnHand: Decimal;
        IcreasesAmnt: Decimal;
        DecreasesAmnt: Decimal;
        AmountLCY: Decimal;
        CurrencyCode: Code[10];
        MinimunDate: Date;
        Amnt2: Decimal;
        IcreasesAmnt2: Decimal;
        DecreasesAmnt2: Decimal;
        AmountLCY2: Decimal;
        PeriodCaptionLbl: Label 'Period: ';
        PageNoCaptionLbl: Label 'Page';
        CustomerSheetCaptionLbl: Label 'Customer Sheet';
        AccountNoCaptionLbl: Label 'Account No.';
        DepartmentCodeCaptionLbl: Label 'Department Code';
        ProjectNoCaptionLbl: Label 'Project No.';
        DebitAmountCaptionLbl: Label 'Debit Amount';
        CreditAmountCaptionLbl: Label 'Credit Amount';
        BalanceCaptionLbl: Label 'Balance';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentDateCaptionLbl: Label 'Document Date';
        OrigAmountCaptionLbl: Label 'Original Amount';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        ProgressiveTotAtCaptionLbl: Label 'Progressive Total at ';
        PrintedEntriesTotCaptionLbl: Label 'Printed Entries Total';
        PrintedEntriesTotProgressiveTotCaptionLbl: Label 'Printed Entries Total + Progressive Total';
        TotalAmtForRTC: Decimal;
        TotalIcreasesAmtForRTC: Decimal;
        TotalDecreasesAmtForRTC: Decimal;
        TotalAmountLCYForRTC: Decimal;
}

