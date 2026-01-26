// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 304 "Vendor - Detail Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorDetailTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Detail Trial Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Date Filter";
            column(DateFilter; StrSubstNo(Text000, VendDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableFilter; Vendor.TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(ExcludeBalanceOnly; ExcludeBalanceOnly)
            {
            }
            column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(RemainingAmtCaption; RemainingAmtCaption)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(No_Vend; "No.")
            {
            }
            column(Name_Vend; Name)
            {
            }
            column(PhoneNo_Vend; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(StartBalanceLCY; StartBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(StartVendDebitAmtAdj; StartVendDebitAmountAdj)
            {
                AutoFormatType = 1;
            }
            column(StartVendCreditAmtAdj; StartVendCreditAmountAdj)
            {
                AutoFormatType = 1;
            }
            column(VendBalanceLCY; VendBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(BalLBalAdjLVendLedgEntryAmtLCY; StartBalanceLCY + StartBalAdjLCY + "Vendor Ledger Entry"."Amount (LCY)" + Correction + ApplicationRounding)
            {
                AutoFormatType = 1;
            }
            column(VendDebitAmtDebitCorrDebit; StartVendDebitAmount + DebitCorrection + DebitApplicationRounding)
            {
                AutoFormatType = 1;
            }
            column(StartBalanceLCYStartBalAdjLCY; StartBalanceLCY + StartBalAdjLCY)
            {
                AutoFormatType = 1;
            }
            column(VendCreditAmtCreditCredit; StartVendCreditAmount + CreditCorrection + CreditApplicationRounding)
            {
                AutoFormatType = 1;
            }
            column(StartVendDebitAmtTotal; StartVendDebitAmountTotal)
            {
            }
            column(StartVendCreditAmtTotal; StartVendCreditAmountTotal)
            {
            }
            column(CreditAppRound; CreditApplicationRounding)
            {
            }
            column(DebitAppRound; DebitApplicationRounding)
            {
            }
            column(CreditCorrect; CreditCorrection)
            {
            }
            column(DebitCorrect; DebitCorrection)
            {
            }
            column(DateFilter1_Vend; "Date Filter")
            {
            }
            column(GlobalDim2Filter_Vend; "Global Dimension 2 Filter")
            {
            }
            column(VendorDetailTrialBalCaption; VendorDetailTrialBalCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(vendorsbalancesCaption; vendorsbalancesCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(BalanceLCYCaption; BalanceLCYCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(AdjofOpeningBalanceCaption; AdjofOpeningBalanceCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(TotalAdjofOpeningBalCaption; TotalAdjofOpeningBalCaptionLbl)
            {
            }
            column(TotalLCYBeforePeriodCaption; TotalLCYBeforePeriodCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Vendor No.", "Posting Date");
                column(StartBalLCYAmtLCY; StartBalanceLCY + "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PostingDate_VendLedgEntry; Format("Posting Date"))
                {
                }
                column(DocType_VendLedgEntry; "Document Type")
                {
                }
                column(DocNo_VendLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(ExtDocNo_VendLedgEntry; "External Document No.")
                {
                    IncludeCaption = true;
                }
                column(VendLedgEntryDescp; Description)
                {
                    IncludeCaption = true;
                }
                column(VendCreditAmt; VendCreditAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendDebitAmt; VendDebitAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendBalLCY; VendBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(VendRemainAmt; VendRemainAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendEntryDueDate; Format(VendEntryDueDate))
                {
                }
                column(EntryNo_VendLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(VendCurrencyCode; VendCurrencyCode)
                {
                }
                column(VendorNo_VendLedgEntry; "Vendor No.")
                {
                }
                column(GlbalDim1Code_VendLedgEntry; "Global Dimension 1 Code")
                {
                }
                column(DateFilter_VendLedgEntry; "Date Filter")
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const("Correction of Remaining Amount"));
                    column(DocNo1_VendLedgEntry; "Vendor Ledger Entry"."Document No.")
                    {
                    }
                    column(EntryType_DtdVendLedgEntry; "Entry Type")
                    {
                    }
                    column(DebitCorrection; DebitCorrection)
                    {
                        AutoFormatType = 1;
                    }
                    column(CreditCorrection; CreditCorrection)
                    {
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Correction := Correction + "Amount (LCY)";
                        VendBalanceLCY := VendBalanceLCY + "Amount (LCY)";
                    end;

                    trigger OnPostDataItem()
                    begin
                        SumCorrections := SumCorrections + Correction;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Posting Date", VendDateFilter);
                        Correction := 0;
                    end;
                }
                dataitem("Detailed Vendor Ledg. Entry2"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const("Appln. Rounding"));
                    column(EntryType_DtdVendLedgEntry2; "Entry Type")
                    {
                    }
                    column(VendBalanceLCY1; VendBalanceLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(DebitAppRounding; DebitApplicationRounding)
                    {
                        AutoFormatType = 1;
                    }
                    column(CreditApplicationRounding; CreditApplicationRounding)
                    {
                        AutoFormatType = 1;
                    }
                    column(DocType_VendLedgEntry2; "Vendor Ledger Entry"."Document Type")
                    {
                    }
                    column(VendLEtrNo_DtdVendLedgEntry2; "Vendor Ledger Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ApplicationRounding := ApplicationRounding + "Amount (LCY)";
                        VendBalanceLCY := VendBalanceLCY + "Amount (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin

                        SetFilter("Posting Date", VendDateFilter);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Amount, "Remaining Amount", "Credit Amount (LCY)", "Debit Amount (LCY)", "Amount (LCY)", "Remaining Amt. (LCY)",
                      "Credit Amount", "Debit Amount");

                    VendLedgEntryExists := true;
                    if PrintAmountsInLCY then begin
                        VendCreditAmount := "Credit Amount (LCY)";
                        VendDebitAmount := "Debit Amount (LCY)";
                        VendRemainAmount := "Remaining Amt. (LCY)";
                        VendCurrencyCode := '';
                    end else begin
                        VendCreditAmount := "Credit Amount";
                        VendDebitAmount := "Debit Amount";
                        VendRemainAmount := "Remaining Amount";
                        VendCurrencyCode := "Currency Code";
                    end;
                    VendBalanceLCY := VendBalanceLCY + "Amount (LCY)";
                    StartVendCreditAmount := StartVendCreditAmount + "Credit Amount (LCY)";
                    StartVendDebitAmount := StartVendDebitAmount + "Debit Amount (LCY)";
                    if ("Document Type" = "Document Type"::Payment) or ("Document Type" = "Document Type"::Refund) then
                        VendEntryDueDate := 0D
                    else
                        VendEntryDueDate := "Due Date";

                    StartVendCreditAmountTotal := StartVendCreditAmountTotal + "Credit Amount (LCY)";
                    StartVendDebitAmountTotal := StartVendDebitAmountTotal + "Debit Amount (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    VendLedgEntryExists := false;
                    StartVendDebitAmount := 0;
                    StartVendCreditAmount := 0;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(VendorName; Vendor.Name)
                {
                }
                column(VendBalanceLCY2; VendBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(StartBalAdjLCY; StartBalAdjLCY)
                {
                }
                column(StartBalanceLCY1; StartBalanceLCY)
                {
                }
                column(VendBalLCYDebitAmtDebitAmtAdj; StartVendDebitAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendBalLCYCreditAmtCreditAmtAdj; StartVendCreditAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    if not VendLedgEntryExists and ((StartBalanceLCY = 0) or ExcludeBalanceOnly) then begin
                        StartBalanceLCY := 0;
                        CurrReport.Skip();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPage then
                    PageGroupNo := PageGroupNo + 1;

                StartBalanceLCY := 0;
                StartBalAdjLCY := 0;
                if VendDateFilter <> '' then begin
                    if GetRangeMin("Date Filter") <> 0D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change (LCY)");
                        StartBalanceLCY := -"Net Change (LCY)";
                        StartVendDebitAmount := "Vendor Ledger Entry"."Debit Amount (LCY)";
                        StartVendCreditAmount := "Vendor Ledger Entry"."Credit Amount (LCY)";
                    end;
                    SetFilter("Date Filter", VendDateFilter);
                    CalcFields("Net Change (LCY)");
                    StartBalAdjLCY := -"Net Change (LCY)";
                    VendorLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
                    VendorLedgerEntry.SetFilter("Posting Date", VendDateFilter);
                    if VendorLedgerEntry.Find('-') then
                        repeat
                            OnOnAfterGetRecordOnVendorLedgerEntryLoopStart(VendorLedgerEntry, VendDateFilter);
                            VendorLedgerEntry.SetFilter("Date Filter", VendDateFilter);
                            VendorLedgerEntry.CalcFields("Amount (LCY)");
                            StartBalAdjLCY := StartBalAdjLCY - VendorLedgerEntry."Amount (LCY)";
                            "Detailed Vendor Ledg. Entry".SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                            "Detailed Vendor Ledg. Entry".SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                            "Detailed Vendor Ledg. Entry".SetFilter("Entry Type", '%1|%2',
                              "Detailed Vendor Ledg. Entry"."Entry Type"::"Correction of Remaining Amount",
                              "Detailed Vendor Ledg. Entry"."Entry Type"::"Appln. Rounding");
                            "Detailed Vendor Ledg. Entry".SetFilter("Posting Date", VendDateFilter);
                            if "Detailed Vendor Ledg. Entry".Find('-') then
                                repeat
                                    OnOnAfterGetRecordOnDetailedVendorLedgEntryLoopStart("Detailed Vendor Ledg. Entry");
                                    StartBalAdjLCY := StartBalAdjLCY - "Detailed Vendor Ledg. Entry"."Amount (LCY)";
                                until "Detailed Vendor Ledg. Entry".Next() = 0;
                            "Detailed Vendor Ledg. Entry".Reset();
                        until VendorLedgerEntry.Next() = 0;
                end;
                CurrReport.PrintOnlyIfDetail := ExcludeBalanceOnly or (StartBalanceLCY = 0);
                VendBalanceLCY := StartBalanceLCY + StartBalAdjLCY;
                if StartBalAdjLCY > 0 then begin
                    StartVendDebitAmountAdj := StartBalAdjLCY;
                    StartVendCreditAmountAdj := 0;
                end else begin
                    StartVendDebitAmountAdj := 0;
                    StartVendCreditAmountAdj := StartBalAdjLCY;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                SumCorrections := 0;

                Clear(StartBalanceLCY);
                Clear(StartBalAdjLCY);
                Clear(Correction);
                Clear(ApplicationRounding);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Vendor - Detail Trial Balance';
        AboutText = 'View vendor balances at the end of a period, including the opening balance, each transaction within the period, and the closing balance grouped by vendor. View details for remaining amounts and due dates.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(NewPageperVendor; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor''s information is printed on a new page if you have chosen two or more vendors to be included in the report.';
                    }
                    field(ExcludeCustHaveaBalanceOnly; ExcludeBalanceOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude Vendors That Have A Balance Only';
                        MultiLine = true;
                        ToolTip = 'Specifies if you do not want the report to include entries for vendors that have a balance but do not have a net change during the selected time period.';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        VendDateFilter := Vendor.GetFilter("Date Filter");

        if PrintAmountsInLCY then begin
            AmountCaption := "Vendor Ledger Entry".FieldCaption("Amount (LCY)");
            RemainingAmtCaption := "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)");
        end else begin
            AmountCaption := "Vendor Ledger Entry".FieldCaption(Amount);
            RemainingAmtCaption := "Vendor Ledger Entry".FieldCaption("Remaining Amount");
        end;
    end;

    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendRemainAmount: Decimal;
        VendEntryDueDate: Date;
        StartBalanceLCY: Decimal;
        ApplicationRounding: Decimal;
        ExcludeBalanceOnly: Boolean;
        PrintOnlyOnePerPage: Boolean;
        VendLedgEntryExists: Boolean;
        RemainingAmtCaption: Text[30];
        PageGroupNo: Integer;
        SumCorrections: Decimal;
        VendDebitAmount: Decimal;
        VendCreditAmount: Decimal;
        StartVendCreditAmount: Decimal;
        StartVendDebitAmount: Decimal;
        StartVendDebitAmountAdj: Decimal;
        StartVendCreditAmountAdj: Decimal;
        DebitCorrection: Decimal;
        CreditCorrection: Decimal;
        DebitApplicationRounding: Decimal;
        CreditApplicationRounding: Decimal;
        StartVendDebitAmountTotal: Decimal;
        StartVendCreditAmountTotal: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Period: %1';
        VendorDetailTrialBalCaptionLbl: Label 'Vendor - Detail Trial Balance';
        PageNoCaptionLbl: Label 'Page';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        vendorsbalancesCaptionLbl: Label 'This report also includes vendors that only have balances.';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentTypeCaptionLbl: Label 'Document Type';
        BalanceLCYCaptionLbl: Label 'Balance (LCY)';
        DueDateCaptionLbl: Label 'Due Date';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        AdjofOpeningBalanceCaptionLbl: Label 'Adj. of Opening Balance';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        TotalAdjofOpeningBalCaptionLbl: Label 'Total Adj. of Opening Balance';
        TotalLCYBeforePeriodCaptionLbl: Label 'Total (LCY) Before Period';

    protected var
        AmountCaption: Text[30];
        Correction: Decimal;
        PrintAmountsInLCY: Boolean;
        StartBalAdjLCY: Decimal;
        VendBalanceLCY: Decimal;
        VendFilter: Text;
        VendDateFilter: Text;
        VendCurrencyCode: Code[10];

    procedure InitializeRequest(NewPrintAmountsInLCY: Boolean; NewPrintOnlyOnePerPage: Boolean; NewExcludeBalanceOnly: Boolean)
    begin
        PrintAmountsInLCY := NewPrintAmountsInLCY;
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        ExcludeBalanceOnly := NewExcludeBalanceOnly;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOnAfterGetRecordOnVendorLedgerEntryLoopStart(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOnAfterGetRecordOnDetailedVendorLedgEntryLoopStart(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;
}

