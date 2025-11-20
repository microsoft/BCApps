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
            column(VendDatetFilterPeriod; StrSubstNo(Text000, VendDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendorTblCapVendFltr; TableCaption + ': ' + VendFilter)
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
            column(AmountCaption; AmountCaption)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(RemainingAmtCaption; RemainingAmtCaption)
            {
                AutoFormatExpression = "Currency Code";
                AutoFormatType = 1;
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(StartBalanceLCY; StartBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(StartBalAdjLCY; StartBalAdjLCY)
            {
                AutoFormatType = 1;
            }
            column(VendBalanceLCY; VendBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(StrtBalLCYStartBalAdjLCY; StartBalanceLCY + StartBalAdjLCY)
            {
                AutoFormatType = 1;
            }
            column(VendDetailTrialBalCap; VendDetailTrialBalCapLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(ReportIncludesvendorshavebalanceCaption; ReportIncludesvendorshavebalanceCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(BalanceLCYCaption; BalanceLCYCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(AdjofOpeningBalanceCaption; AdjofOpeningBalanceCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(TotalAdjofOpenBalCaption; TotalAdjofOpenBalCaptionLbl)
            {
            }
            column(TotalLCYBeforePeriodCaption; TotalLCYBeforePeriodCaptionLbl)
            {
            }
            column(ExternalDocNoCaption; ExternalDocNoCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Vendor No.", "Posting Date");
                column(PostingDate_VendLedgEntry; Format("Posting Date"))
                {
                }
                column(DocType_VendLedgEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocNo_VendLedgerEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(ExtDocNo_VendLedgerEntry; "External Document No.")
                {
                }
                column(Desc_VendLedgerEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(VendAmount; VendAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendBalLCY2; VendBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(VendRemainAmount; VendRemainAmount)
                {
                    AutoFormatExpression = VendCurrencyCode;
                    AutoFormatType = 1;
                }
                column(VendEntryDueDate; Format(VendEntryDueDate))
                {
                }
                column(EntryNo_VendorLedgerEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(VendCurrencyCode; VendCurrencyCode)
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date") where("Entry Type" = const("Correction of Remaining Amount"));
                    column(EntryTyp_DetVendLedgEntry; "Entry Type")
                    {
                    }
                    column(Correction; Correction)
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
                    column(Entry_DetVendLedgEntry2; "Entry Type")
                    {
                    }
                    column(VendBalanceLCY3; VendBalanceLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(ApplicationRounding; ApplicationRounding)
                    {
                        AutoFormatType = 1;
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
                    CalcFields(Amount, "Remaining Amount", "Amount (LCY)", "Remaining Amt. (LCY)");

                    VendLedgEntryExists := true;
                    if PrintAmountsInLCY then begin
                        VendAmount := "Amount (LCY)";
                        VendRemainAmount := "Remaining Amt. (LCY)";
                        VendCurrencyCode := '';
                    end else begin
                        VendAmount := Amount;
                        VendRemainAmount := "Remaining Amount";
                        VendCurrencyCode := "Currency Code";
                    end;
                    VendBalanceLCY := VendBalanceLCY + "Amount (LCY)";
                    if ("Document Type" = "Document Type"::Payment) or ("Document Type" = "Document Type"::Refund) then
                        VendEntryDueDate := 0D
                    else
                        VendEntryDueDate := "Due Date";
                end;

                trigger OnPreDataItem()
                begin
                    VendLedgEntryExists := false;
                    Clear(VendAmount);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(VendBalanceLCY4; VendBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(StartBalAdjLCY1; StartBalAdjLCY)
                {
                }
                column(StartBalanceLCY1; StartBalanceLCY)
                {
                }
                column(VendBalStrtBalStrtBalAdj; VendBalanceLCY - StartBalanceLCY)
                {
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
                    end;
                    SetFilter("Date Filter", VendDateFilter);
                    CalcFields("Net Change (LCY)");
                    StartBalAdjLCY := -"Net Change (LCY)";
                    VendorLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendorLedgerEntry.SetRange("Vendor No.", "No.");
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
        VendAmount: Decimal;
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

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Period: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VendDetailTrialBalCapLbl: Label 'Vendor - Detail Trial Balance';
        PageCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        ReportIncludesvendorshavebalanceCaptionLbl: Label 'This report also includes vendors that only have balances.';
        PostingDateCaptionLbl: Label 'Posting Date';
        BalanceLCYCaptionLbl: Label 'Balance (LCY)';
        DueDateCaptionLbl: Label 'Due Date';
        AdjofOpeningBalanceCaptionLbl: Label 'Adj. of Opening Balance';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        TotalAdjofOpenBalCaptionLbl: Label 'Total Adj. of Opening Balance';
        TotalLCYBeforePeriodCaptionLbl: Label 'Total (LCY) Before Period';
        ExternalDocNoCaptionLbl: Label 'External Doc. No.';

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

