// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10748 "Vendor - Overdue Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorOverduePayments.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Overdue Payments';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ShowPayments; Format(ShowPayments))
            {
            }
            column(FORMAT_StartDate___________FORMAT_EndDate_; Format(StartDate) + '..' + Format(EndDate))
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(Vendor_TABLECAPTION_______; Vendor.TableCaption + ': ')
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(DaysOverdue; DaysOverdue)
            {
                DecimalPlaces = 0 : 0;
            }
            column(Vendor_Name_Control1100026; Name)
            {
            }
            column(ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___; Abs(VendTotalAmount))
            {
            }
            column(ABS_TotalPaymentWithinDueDate_; Abs(TotalPaymentWithinLegalDueDate))
            {
            }
            column(ABS_TotalPaymentOutsideDueDate_; Abs(TotalPaymentOutsideLegalDueDate))
            {
            }
            column(DataItem1100037; FormatRatio(TotalPaymentWithinLegalDueDate, VendTotalAmount))
            {
            }
            column(DataItem1100039; FormatRatio(TotalPaymentOutsideLegalDueDate, VendTotalAmount))
            {
            }
            column(TotalPaymentOutsideDueDate; Abs(AppldVendLedgEntryTmp."Amount (LCY)"))
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___; GetWeightedExceededAmountPerVendor())
            {
            }
            column(WeightedExceededAmount1; WeightedExceededAmount)
            {
            }
            column(DaysOverdue_Control1100027; DaysOverdue)
            {
                DecimalPlaces = 0 : 0;
            }
            column(ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100031; Abs(TotalAmount))
            {
            }
            column(ABS_TotalPaymentWithinDueDate__Control1100044; Abs(TotalPaymentWithinLegalDueDate))
            {
            }
            column(ABS_TotalPaymentOutsideDueDate__Control1100045; Abs(TotalPaymentOutsideLegalDueDate))
            {
            }
            column(DataItem1100046; FormatRatio(TotalPaymentWithinLegalDueDate, TotalAmount))
            {
            }
            column(DataItem1100047; FormatRatio(TotalPaymentOutsideLegalDueDate, TotalAmount))
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100057; GetWeightedExceededAmountPerTotal())
            {
            }
            column(Vendor_Date_Filter; "Date Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor___Overdue_PaymentsCaption; Vendor___Overdue_PaymentsCaptionLbl)
            {
            }
            column(ShowPaymentsCaption; ShowPaymentsCaptionLbl)
            {
            }
            column(FORMAT_StartDate___________FORMAT_EndDate_Caption; FORMAT_StartDate___________FORMAT_EndDate_CaptionLbl)
            {
            }
            column(ABS_TotalPaymentWithinDueDate_Caption; ABS_TotalPaymentWithinDueDate_CaptionLbl)
            {
            }
            column(ABS_TotalPaymentOutsideDueDate_Caption; ABS_TotalPaymentOutsideDueDate_CaptionLbl)
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___Caption; WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___CaptionLbl)
            {
            }
            column(WeightedOpenAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____CaptionLbl; WeightedOpenAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____CaptionLbl)
            {
            }
            column(Average_Payment_Period_To_Suppliers_Caption; AveragePaymentPeriodToSuppliersLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100057Caption; WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100057CaptionLbl)
            {
            }
            column(ABS_TotalPaymentWithinDueDate__Control1100044Caption; ABS_TotalPaymentWithinDueDate__Control1100044CaptionLbl)
            {
            }
            column(ABS_TotalPaymentOutsideDueDate__Control1100045Caption; ABS_TotalPaymentOutsideDueDate__Control1100045CaptionLbl)
            {
            }
            column(ABS_TotalOpenPaymentOutsideLegalLimit__Control1100046Caption; ABS_TotalOpenPaymentOutsideLegalLimit__Control1100046CaptionLbl)
            {
            }
            column(ABS_TotalOpenPaymentWithinLegalLimitCaption; ABS_TotalOpenPaymentWithinLegalLimit_Lbl)
            {
            }
            column(InvoicesPaidWithinLegalDueDateCountCaption; InvoicesPaidWithinLegalDueDateCountLbl)
            {
            }
            column(InvoicesPaidToTotalCountPctCaption; InvoicesPaidToTotalCountPctLbl)
            {
            }
            column(CalcVendorRatioOfPaidTransactions_; CalcVendorRatioOfPaidTransactions())
            {
            }
            column(CalcTotalRatioOfPaidTransactions_; CalcTotalRatioOfPaidTransactions())
            {
            }
            column(CalcVendorRatioOfOutstandingPaymentTransactions_; CalcVendorRatioOfOutstandingPaymentTransactions())
            {
            }
            column(CalcTotalRatioOfOutstandingPaymentTransactions_; CalcTotalRatioOfOutstandingPaymentTransactions())
            {
            }
            column(CalcAveragePaymentPeriodToVendor_; CalcAveragePaymentPeriodToVendor())
            {
            }
            column(CalcTotalAveragePaymentPeriodToVendors_; CalcTotalAveragePaymentPeriodToVendors())
            {
            }
            column(OpenVendPaymentOutsideDueDate; OpenVendPaymentOutsideLegalDueDate)
            {
            }
            column(TotalOpenPaymentOutsideDueDate; TotalOpenPaymentOutsideLegalDueDate)
            {
            }
            column(VendPaymentOutsideDueDate; VendPaymentOutsideLegalDueDate)
            {
            }
            column(VendPaymentWithinDueDate; VendPaymentWithinLegalDueDate)
            {
            }
            column(TotalPaymentWithinDueDate; TotalPaymentWithinLegalDueDate)
            {
            }
            column(OpenVendPaymentWithinDueDate; OpenVendPaymentWithinLegalDueDate)
            {
            }
            column(TotalOpenPaymentWithinDueDate; TotalOpenPaymentWithinLegalDueDate)
            {
            }
            column(InvPaidWithinLegalDueDateCountPerVendorVal; InvPaidWithinLegalDueDateCountPerVendor)
            {
            }
            column(InvPaidToTotalCountPctPerVendorVal; InvoicesPaidToTotalCountPctPerVendor)
            {
                DecimalPlaces = 0 : 2;
            }
            column(InvPaidWithinLegalDueDateTotalCountVal; InvPaidWithinLegalDueDateTotalCount)
            {
            }
            column(InvoicesPaidToTotalCountPctValue; InvoicesPaidToTotalCountPct)
            {
                DecimalPlaces = 0 : 2;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("Document Type" = filter(Invoice | Bill));
                PrintOnlyIfDetail = true;
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry_Posting_Date; "Posting Date")
                {
                }
                column(Vendor_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Vendor_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Vendor_Ledger_Entry_Date_Filter; "Date Filter")
                {
                }
                column(Vend__Ledger_Entry___Document_No__Caption; Vend__Ledger_Entry___Document_No__CaptionLbl)
                {
                }
                column(Vend__Ledger_Entry__DescriptionCaption; Vend__Ledger_Entry__DescriptionCaptionLbl)
                {
                }
                column(Detailed_Vend__Ledg__Entry__Document_No__Caption; Detailed_Vend__Ledg__Entry__Document_No__CaptionLbl)
                {
                }
                column(Detailed_Vend__Ledg__Entry__Posting_Date_Caption; Detailed_Vend__Ledg__Entry__Posting_Date_CaptionLbl)
                {
                }
                column(Detailed_Vend__Ledg__Entry__Initial_Entry_Due_Date_Caption; CaptionClassTranslate(GetDueDateCaption()))
                {
                }
                column(Detailed_Vend__Ledg__Entry__Currency_Code_Caption; Detailed_Vend__Ledg__Entry__Currency_Code_CaptionLbl)
                {
                }
                column(ABS_Amount_Caption; ABS_Amount_CaptionLbl)
                {
                }
                column(ABS__Amount__LCY___Caption; ABS__Amount__LCY___CaptionLbl)
                {
                }
                column(DaysOverdue_Control1100024Caption; DaysOverdue_Control1100024CaptionLbl)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(Vend__Ledger_Entry___Document_No__; "Vendor Ledger Entry"."Document No.")
                    {
                    }
                    column(Vend__Ledger_Entry__Description; "Vendor Ledger Entry".Description)
                    {
                    }
                    column(Detailed_Vend__Ledg__Entry__Document_No__; AppldVendLedgEntryTmp."Document No.")
                    {
                    }
                    column(Detailed_Vend__Ledg__Entry__Posting_Date_; AppldVendLedgEntryTmp."Posting Date")
                    {
                    }
                    column(Detailed_Vend__Ledg__Entry__Initial_Entry_Due_Date_; AppldVendLedgEntryTmp."Initial Entry Due Date")
                    {
                    }
                    column(Detailed_Vend__Ledg__Entry__Currency_Code_; AppldVendLedgEntryTmp."Currency Code")
                    {
                    }
                    column(ABS_Amount_; Abs(AppldVendLedgEntryTmp.Amount))
                    {
                    }
                    column(ABS__Amount__LCY___; Abs(AppldVendLedgEntryTmp."Amount (LCY)"))
                    {
                    }
                    column(DaysOverdue_Control1100024; DaysOverdue)
                    {
                        DecimalPlaces = 0 : 0;
                    }
                    column(Integer_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        LegalDueDate: Date;
                    begin
                        if Number = 1 then begin
                            if not AppldVendLedgEntryTmp.FindSet() then
                                CurrReport.Break();
                        end else
                            if AppldVendLedgEntryTmp.Next() = 0 then
                                CurrReport.Break();

                        LegalDueDate := DtldEntryNoToLegalDueDateMap.Get(AppldVendLedgEntryTmp."Entry No.");
                        if AppldVendLedgEntryTmp."Posting Date" > LegalDueDate then
                            if AppldVendLedgEntryTmp."Applied Vend. Ledger Entry No." = 0 then begin
                                OpenVendPaymentOutsideLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                                TotalOpenPaymentOutsideLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                            end else begin
                                VendPaymentOutsideLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                                TotalPaymentOutsideLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                            end
                        else
                            if AppldVendLedgEntryTmp."Applied Vend. Ledger Entry No." = 0 then begin
                                OpenVendPaymentWithinLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                                TotalOpenPaymentWithinLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                            end else begin
                                VendPaymentWithinLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                                TotalPaymentWithinLegalDueDate += AppldVendLedgEntryTmp."Amount (LCY)";
                            end;

                        TempDetailedVendorLedgEntry.Get(AppldVendLedgEntryTmp."Entry No.");
                        DaysOverdue := AppldVendLedgEntryTmp."Posting Date" - TempDetailedVendorLedgEntry."Posting Date";
                        if AppldVendLedgEntryTmp."Entry Type" = AppldVendLedgEntryTmp."Entry Type"::"Initial Entry" then begin
                            VendOpenAmount += Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            TotalOpenAmount += Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            VendWeightedOpenPaymentAmount += DaysOverdue * Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            TotalWeightedOpenPaymentAmount += DaysOverdue * Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            AppldVendLedgEntryTmp."Posting Date" := 0D
                        end else begin
                            VendApplAmount += Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            TotalApplAmount += Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            VendWeightedExceededAmount += DaysOverdue * Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                            TotalWeightedExceededAmount += DaysOverdue * Abs(AppldVendLedgEntryTmp."Amount (LCY)");
                        end;

                        VendDaysOverdue += DaysOverdue;
                        TotalDaysOverdue += DaysOverdue;

                        VendTotalAmount :=
                            VendPaymentOutsideLegalDueDate + VendPaymentWithinLegalDueDate +
                            OpenVendPaymentOutsideLegalDueDate + OpenVendPaymentWithinLegalDueDate;
                        TotalAmount :=
                            TotalPaymentOutsideLegalDueDate + TotalPaymentWithinLegalDueDate +
                            TotalOpenPaymentOutsideLegalDueDate + TotalOpenPaymentWithinLegalDueDate;
                    end;

                    trigger OnPreDataItem()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeVendorLedgerEntryOnPreDataItem("Vendor Ledger Entry", Vendor, StartDate, EndDate, ShowPayments, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();
                        DaysOverdue := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    LegalDueDate: Date;
                begin
                    FindAppliedPayments("Entry No.");
                    FindOpenInvoices("Entry No.");

                    if "Document Type" = "Document Type"::Invoice then begin
                        InvoicesCountPerVendor += 1;
                        InvoicesTotalCount += 1;
                    end;

                    LegalDueDate := CalcMaxDueDate("Vendor Ledger Entry");
                    if (not Open) and ("Closed at Date" <= LegalDueDate) and (not CheckIfCreateBills("Vendor Ledger Entry")) then begin
                        InvPaidWithinLegalDueDateCountPerVendor += 1;
                        InvPaidWithinLegalDueDateTotalCount += 1;
                    end;

                    if InvoicesCountPerVendor <> 0 then
                        InvoicesPaidToTotalCountPctPerVendor := 100 * InvPaidWithinLegalDueDateCountPerVendor / InvoicesCountPerVendor
                    else
                        InvoicesPaidToTotalCountPctPerVendor := 0;

                    if InvoicesTotalCount <> 0 then
                        InvoicesPaidToTotalCountPct := 100 * InvPaidWithinLegalDueDateTotalCount / InvoicesTotalCount
                    else
                        InvoicesPaidToTotalCountPct := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ClearVendAmount();
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(ShowPayments; ShowPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Payments';
                        OptionCaption = 'Overdue,Legally Overdue,All';
                        ToolTip = 'Specifies if you want to show only payments that are overdue, payments that are outside the legal limit, or all payments.';
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
        VendFilter := Vendor.GetFilters();
        if StartDate = 0D then
            Error(Text1100001);
        if EndDate = 0D then
            Error(Text1100002);

        if StartDate > EndDate then
            Error(Text1100003);
    end;

    var
        AppldVendLedgEntryTmp: Record "Detailed Vendor Ledg. Entry" temporary;
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        DtldEntryNoToLegalDueDateMap: Dictionary of [Integer, Date];
        StartDate: Date;
        EndDate: Date;
        VendFilter: Text[250];
        TotalPaymentWithinLegalDueDate: Decimal;
        TotalPaymentOutsideLegalDueDate: Decimal;
        DaysOverdue: Decimal;
        WeightedExceededAmount: Decimal;
        Text001: Label 'Max. Allowed Due Date';
        Text1100001: Label 'You must specify the start date for the period.';
        Text1100002: Label 'You must specify the end date for the period.';
        Text1100003: Label 'The start date cannot be later than the end date.';
        VendTotalAmount: Decimal;
        TotalAmount: Decimal;
        ShowPayments: Option Overdue,"Legally Overdue",All;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendor___Overdue_PaymentsCaptionLbl: Label 'Vendor - Overdue Payments';
        ShowPaymentsCaptionLbl: Label 'Show payments:';
        FORMAT_StartDate___________FORMAT_EndDate_CaptionLbl: Label 'Period:';
        ABS_TotalPaymentWithinDueDate_CaptionLbl: Label 'Payments within the legal limit (LCY):';
        ABS_TotalPaymentOutsideDueDate_CaptionLbl: Label 'Payments outside the legal limit (LCY):';
        WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___CaptionLbl: Label 'Ratio of paid transactions:';
        TotalCaptionLbl: Label 'Total';
        WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100057CaptionLbl: Label 'Ratio of paid transactions:';
        WeightedOpenAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____CaptionLbl: Label 'Ratio of outstanding payment transactions:';
        AveragePaymentPeriodToSuppliersLbl: Label 'Average payment period to suppliers:';
        ABS_TotalPaymentWithinDueDate__Control1100044CaptionLbl: Label 'Payments within the legal limit (LCY):';
        ABS_TotalPaymentOutsideDueDate__Control1100045CaptionLbl: Label 'Payments outside the legal limit (LCY):';
        Vend__Ledger_Entry___Document_No__CaptionLbl: Label 'Invoice No.';
        Vend__Ledger_Entry__DescriptionCaptionLbl: Label 'Invoice Description';
        Detailed_Vend__Ledg__Entry__Document_No__CaptionLbl: Label 'Document No. (Payment)';
        Detailed_Vend__Ledg__Entry__Posting_Date_CaptionLbl: Label 'Posting Date (Payment)';
        Detailed_Vend__Ledg__Entry__Currency_Code_CaptionLbl: Label 'Currency Code';
        ABS_Amount_CaptionLbl: Label 'Amount';
        ABS__Amount__LCY___CaptionLbl: Label 'Amount(LCY)';
        DaysOverdue_Control1100024CaptionLbl: Label 'Days Overdue';
        ABS_TotalOpenPaymentOutsideLegalLimit__Control1100046CaptionLbl: Label 'Open Payments outside the legal limit (LCY):';
        ABS_TotalOpenPaymentWithinLegalLimit_Lbl: Label 'Open Payments within the legal limit (LCY):';
        InvoicesPaidWithinLegalDueDateCountLbl: Label 'No. of invoices paid within the legal limit:';
        InvoicesPaidToTotalCountPctLbl: Label '% of invoices paid within the legal limit:';
        OpenVendPaymentOutsideLegalDueDate: Decimal;
        TotalOpenPaymentOutsideLegalDueDate: Decimal;
        OpenVendPaymentWithinLegalDueDate: Decimal;
        TotalOpenPaymentWithinLegalDueDate: Decimal;
        VendDaysOverdue: Decimal;
        VendWeightedExceededAmount: Decimal;
        VendPaymentOutsideLegalDueDate: Decimal;
        VendPaymentWithinLegalDueDate: Decimal;
        VendApplAmount: Decimal;
        TotalApplAmount: Decimal;
        VendOpenAmount: Decimal;
        TotalOpenAmount: Decimal;
        TotalWeightedExceededAmount: Decimal;
        VendWeightedOpenPaymentAmount: Decimal;
        TotalWeightedOpenPaymentAmount: Decimal;
        TotalDaysOverdue: Decimal;
        InvPaidWithinLegalDueDateCountPerVendor: Integer;
        InvoicesCountPerVendor: Integer;
        InvoicesPaidToTotalCountPctPerVendor: Decimal;
        InvPaidWithinLegalDueDateTotalCount: Integer;
        InvoicesTotalCount: Integer;
        InvoicesPaidToTotalCountPct: Decimal;

    local procedure FindAppliedPayments(VendLedgEntryNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        AppldVendLedgEntryTmp.Reset();
        AppldVendLedgEntryTmp.DeleteAll();
        TempDetailedVendorLedgEntry.DeleteAll();
        InvVendLedgEntry.Get(VendLedgEntryNo);

        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        DtldVendLedgEntry.SetRange("Posting Date", StartDate, EndDate);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if DtldVendLedgEntry."Vendor Ledger Entry No." = DtldVendLedgEntry."Applied Vend. Ledger Entry No." then
                    FindAppPaymToInv(DtldVendLedgEntry."Applied Vend. Ledger Entry No.", InvVendLedgEntry)
                else
                    FindAppInvToPaym(DtldVendLedgEntry, InvVendLedgEntry);
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure FindAppPaymToInv(AppliedVendLedgEntryNo: Integer; InvVendLedgEntry: Record "Vendor Ledger Entry")
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PayVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange(
          "Applied Vend. Ledger Entry No.", AppliedVendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        DtldVendLedgEntry.SetRange("Posting Date", StartDate, EndDate);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if DtldVendLedgEntry."Vendor Ledger Entry No." <> DtldVendLedgEntry."Applied Vend. Ledger Entry No." then
                    if IsPaymentEntry(DtldVendLedgEntry."Vendor Ledger Entry No.", PayVendLedgEntry) and
                       PrintEntry(InvVendLedgEntry, DtldVendLedgEntry."Posting Date")
                    then begin
                        AppldVendLedgEntryTmp := DtldVendLedgEntry;
                        AppldVendLedgEntryTmp."Document No." := PayVendLedgEntry."Document No.";
                        AppldVendLedgEntryTmp."Currency Code" := PayVendLedgEntry."Currency Code";
                        AppldVendLedgEntryTmp."Initial Entry Due Date" := InvVendLedgEntry."Due Date";
                        AppldVendLedgEntryTmp.Amount := -AppldVendLedgEntryTmp.Amount;
                        AppldVendLedgEntryTmp."Amount (LCY)" := -AppldVendLedgEntryTmp."Amount (LCY)";
                        if AppldVendLedgEntryTmp.Insert() then;
                        InsertDtldVLEDocumentDateBuffer(AppldVendLedgEntryTmp."Entry No.", InvVendLedgEntry."Document Date");
                        if not DtldEntryNoToLegalDueDateMap.ContainsKey(AppldVendLedgEntryTmp."Entry No.") then
                            DtldEntryNoToLegalDueDateMap.Add(AppldVendLedgEntryTmp."Entry No.", CalcMaxDueDate(InvVendLedgEntry));
                    end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure FindAppInvToPaym(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; InvVendLedgEntry: Record "Vendor Ledger Entry")
    var
        PayVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if IsPaymentEntry(DtldVendLedgEntry."Applied Vend. Ledger Entry No.", PayVendLedgEntry) and
           PrintEntry(InvVendLedgEntry, DtldVendLedgEntry."Posting Date")
        then begin
            AppldVendLedgEntryTmp := DtldVendLedgEntry;
            AppldVendLedgEntryTmp."Vendor Ledger Entry No." := AppldVendLedgEntryTmp."Applied Vend. Ledger Entry No.";
            AppldVendLedgEntryTmp."Document No." := PayVendLedgEntry."Document No.";
            AppldVendLedgEntryTmp."Currency Code" := PayVendLedgEntry."Currency Code";
            if AppldVendLedgEntryTmp.Insert() then;
            InsertDtldVLEDocumentDateBuffer(AppldVendLedgEntryTmp."Entry No.", InvVendLedgEntry."Document Date");
            DtldEntryNoToLegalDueDateMap.Add(AppldVendLedgEntryTmp."Entry No.", CalcMaxDueDate(InvVendLedgEntry));
        end;
    end;

    local procedure PrintEntry(InvVendLedgEntry: Record "Vendor Ledger Entry"; PaymentAppDate: Date): Boolean
    var
        MaxAllowedDueDate: Date;
    begin
        if ShowPayments = ShowPayments::All then
            exit(true);

        MaxAllowedDueDate := CalcMaxDueDate(InvVendLedgEntry);

        case ShowPayments of
            ShowPayments::Overdue:
                exit(PaymentAppDate > InvVendLedgEntry."Due Date");
            ShowPayments::"Legally Overdue":
                exit(PaymentAppDate > MaxAllowedDueDate);
        end;
    end;

    local procedure CalcMaxDueDate(InvVendLedgEntry: Record "Vendor Ledger Entry"): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(InvVendLedgEntry."Payment Terms Code") and (PaymentTerms."Max. No. of Days till Due Date" > 0) then
            exit(PaymentTerms.CalculateMaxDueDate(InvVendLedgEntry."Document Date"));

        exit(InvVendLedgEntry."Due Date");
    end;

    local procedure GetDueDateCaption(): Text[100]
    begin
        case ShowPayments of
            ShowPayments::Overdue,
          ShowPayments::All:
                exit("Vendor Ledger Entry".FieldCaption("Due Date"));
            ShowPayments::"Legally Overdue":
                exit(Text001);
        end;
    end;

    local procedure FormatRatio(Amount: Decimal; Total: Decimal): Text[30]
    begin
        exit('(' + Format(GetDivisionAmount(Amount, Total) * 100, 0, '<Precision,2><Standard Format,1>') + '%)');
    end;

    [Scope('OnPrem')]
    procedure InitReportParameters(NewStartDate: Date; NewEndDate: Date; NewShowPayments: Option)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        ShowPayments := NewShowPayments;
    end;

    local procedure FindOpenInvoices(VendLedgEntryNo: Integer)
    var
        InvVendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        InvVendLedgEntry.Get(VendLedgEntryNo);
        InvVendLedgEntry.SetRange("Date Filter", 0D, EndDate);
        InvVendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if InvVendLedgEntry."Remaining Amount" <> 0 then
            if PrintEntry(InvVendLedgEntry, EndDate) then begin
                DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
                DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", InvVendLedgEntry."Entry No.");
                DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Initial Entry");
                if DtldVendLedgEntry.FindFirst() then begin
                    AppldVendLedgEntryTmp := DtldVendLedgEntry;
                    AppldVendLedgEntryTmp."Initial Entry Due Date" := InvVendLedgEntry."Due Date";
                    AppldVendLedgEntryTmp.Amount := -InvVendLedgEntry."Remaining Amount";
                    AppldVendLedgEntryTmp."Amount (LCY)" := -InvVendLedgEntry."Remaining Amt. (LCY)";
                    AppldVendLedgEntryTmp."Document No." := '';
                    AppldVendLedgEntryTmp."Posting Date" := EndDate;
                    if AppldVendLedgEntryTmp.Insert() then;
                    InsertDtldVLEDocumentDateBuffer(AppldVendLedgEntryTmp."Entry No.", InvVendLedgEntry."Document Date");
                    DtldEntryNoToLegalDueDateMap.Add(AppldVendLedgEntryTmp."Entry No.", CalcMaxDueDate(InvVendLedgEntry));
                end;
            end;
    end;

    local procedure IsPaymentEntry(VendLedgEntryNo: Integer; var PayVendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        if not (PayVendLedgEntry.Get(VendLedgEntryNo) and
                (PayVendLedgEntry."Document Type" = PayVendLedgEntry."Document Type"::Payment))
        then
            exit(false);

        exit(true);
    end;

    local procedure ClearVendAmount()
    begin
        VendTotalAmount := 0;
        VendDaysOverdue := 0;
        VendWeightedExceededAmount := 0;
        VendPaymentOutsideLegalDueDate := 0;
        VendPaymentWithinLegalDueDate := 0;
        OpenVendPaymentOutsideLegalDueDate := 0;
        OpenVendPaymentWithinLegalDueDate := 0;
        VendApplAmount := 0;
        VendWeightedOpenPaymentAmount := 0;
        VendOpenAmount := 0;
        InvPaidWithinLegalDueDateCountPerVendor := 0;
        InvoicesCountPerVendor := 0;
        InvoicesPaidToTotalCountPctPerVendor := 0;
    end;

    local procedure CalcVendorRatioOfPaidTransactions(): Decimal
    begin
        // In case no payment was made, return 0%
        if VendApplAmount = 0 then
            exit(0);
        exit(VendWeightedExceededAmount / Abs(VendApplAmount));
    end;

    local procedure CalcTotalRatioOfPaidTransactions(): Decimal
    begin
        if TotalApplAmount = 0 then
            exit(0);
        exit(TotalWeightedExceededAmount / Abs(TotalApplAmount));
    end;

    local procedure CalcVendorRatioOfOutstandingPaymentTransactions(): Decimal
    begin
        if VendOpenAmount = 0 then
            exit(0);
        exit(VendWeightedOpenPaymentAmount / Abs(VendOpenAmount));
    end;

    local procedure CalcTotalRatioOfOutstandingPaymentTransactions(): Decimal
    begin
        if TotalOpenAmount = 0 then
            exit(0);
        exit(TotalWeightedOpenPaymentAmount / Abs(TotalOpenAmount));
    end;

    local procedure CalcAveragePaymentPeriodToVendor(): Decimal
    begin
        if VendApplAmount + VendOpenAmount = 0 then
            exit(0);
        exit((VendWeightedExceededAmount + VendWeightedOpenPaymentAmount) / Abs(VendApplAmount + VendOpenAmount));
    end;

    local procedure CalcTotalAveragePaymentPeriodToVendors(): Decimal
    begin
        if TotalApplAmount + TotalOpenAmount = 0 then
            exit(0);
        exit((TotalWeightedExceededAmount + TotalWeightedOpenPaymentAmount) / Abs(TotalApplAmount + TotalOpenAmount));
    end;

    local procedure GetDivisionAmount(Amount: Decimal; Divider: Decimal): Decimal
    begin
        if Divider = 0 then
            exit(0);
        exit(Amount / Divider);
    end;

    local procedure GetWeightedExceededAmountPerVendor(): Decimal
    begin
        if VendTotalAmount = 0 then
            exit(0);
        exit(WeightedExceededAmount / Abs(VendTotalAmount));
    end;

    local procedure GetWeightedExceededAmountPerTotal(): Decimal
    begin
        if TotalAmount = 0 then
            exit(0);
        exit(WeightedExceededAmount / Abs(TotalAmount));
    end;

    local procedure CheckIfCreateBills(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PaymentMethod: Record "Payment Method";
    begin
        if (VendorLedgerEntry.Open) or (VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice) then
            exit(false);

        if not PaymentMethod.Get("Vendor Ledger Entry"."Payment Method Code") then
            exit(false);

        exit(PaymentMethod."Create Bills");
    end;

    [Scope('OnPrem')]
    procedure InsertDtldVLEDocumentDateBuffer(EntryNo: Integer; DocumentDate: Date)
    begin
        TempDetailedVendorLedgEntry.Init();
        TempDetailedVendorLedgEntry."Entry No." := EntryNo;
        TempDetailedVendorLedgEntry."Posting Date" := DocumentDate;
        if TempDetailedVendorLedgEntry.Insert() then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorLedgerEntryOnPreDataItem(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Vendor: Record Vendor; var InitDate: Date; var EndDate: Date; var ShowPayments: Option Overdue,"Legally Overdue",All; var IsHandled: Boolean)
    begin
    end;
}

