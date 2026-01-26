// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10747 "Customer - Overdue Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerOverduePayments.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Overdue Payments';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
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
            column(CustFilter; CustFilter)
            {
            }
            column(Customer_TABLECAPTION_______; Customer.TableCaption + ': ')
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(DaysOverdue; DaysOverdue)
            {
                DecimalPlaces = 0 : 0;
            }
            column(Customer_Name_Control1100026; Name)
            {
            }
            column(ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___; Abs(CustTotalAmount))
            {
            }
            column(ABS_TotalPaymentWithinDueDate_; Abs(TotalPaymentWithinLegalDueDate))
            {
            }
            column(ABS_TotalPaymentOutsideDueDate_; Abs(TotalPaymentOutsideLegalDueDate))
            {
            }
            column(DataItem1100037; FormatRatio(TotalPaymentWithinLegalDueDate, CustTotalAmount))
            {
            }
            column(DataItem1100039; FormatRatio(TotalPaymentOutsideLegalDueDate, CustTotalAmount))
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___; GetWeightedExceededAmountPerCustomer())
            {
            }
            column(WeightedExceededAmount1; WeightedExceededAmount)
            {
            }
            column(DaysOverdue_Control1100027; DaysOverdue)
            {
                DecimalPlaces = 0 : 0;
            }
            column(ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100031; Abs(TotalAmount))
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
            column(WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100057; GetWeightedExceededAmountPerTotal())
            {
            }
            column(Customer_Date_Filter; "Date Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer___Overdue_PaymentsCaption; Customer___Overdue_PaymentsCaptionLbl)
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
            column(WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___Caption; WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100057Caption; WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100057CaptionLbl)
            {
            }
            column(ABS_TotalPaymentWithinDueDate__Control1100044Caption; ABS_TotalPaymentWithinDueDate__Control1100044CaptionLbl)
            {
            }
            column(ABS_TotalPaymentOutsideDueDate__Control1100045Caption; ABS_TotalPaymentOutsideDueDate__Control1100045CaptionLbl)
            {
            }
            column(CalcWeightedExceededAmt; CalcWeightedExceededAmt())
            {
            }
            column(CalcTotalWeightedExceededAmt; CalcTotalWeightedExceededAmt())
            {
            }
            column(CustPaymentOutsideDueDate; Abs(CustPaymentOutsideLegalDueDate))
            {
            }
            column(CustPaymentWithinDueDate; Abs(CustPaymentWithinLegalDueDate))
            {
            }
            column(TotalPaymentOutsideDueDate; Abs(TotalPaymentOutsideLegalDueDate))
            {
            }
            column(TotalPaymentWithinDueDate; Abs(TotalPaymentWithinLegalDueDate))
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Document Type", "Customer No.", "Posting Date", "Currency Code") where("Document Type" = filter(Invoice | Bill));
                PrintOnlyIfDetail = true;
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Cust__Ledger_Entry_Customer_No_; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry_Posting_Date; "Posting Date")
                {
                }
                column(Cust__Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Cust__Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Cust__Ledger_Entry_Date_Filter; "Date Filter")
                {
                }
                column(Cust__Ledger_Entry___Document_No__Caption; Cust__Ledger_Entry___Document_No__CaptionLbl)
                {
                }
                column(Cust__Ledger_Entry__DescriptionCaption; Cust__Ledger_Entry__DescriptionCaptionLbl)
                {
                }
                column(Detailed_Cust__Ledg__Entry__Document_No__Caption; Detailed_Cust__Ledg__Entry__Document_No__CaptionLbl)
                {
                }
                column(Detailed_Cust__Ledg__Entry__Posting_Date_Caption; Detailed_Cust__Ledg__Entry__Posting_Date_CaptionLbl)
                {
                }
                column(Detailed_Cust__Ledg__Entry__Initial_Entry_Due_Date_Caption; CaptionClassTranslate(GetDueDateCaption()))
                {
                }
                column(Detailed_Cust__Ledg__Entry__Currency_Code_Caption; Detailed_Cust__Ledg__Entry__Currency_Code_CaptionLbl)
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
                    column(Cust__Ledger_Entry___Document_No__; "Cust. Ledger Entry"."Document No.")
                    {
                    }
                    column(Cust__Ledger_Entry__Description; "Cust. Ledger Entry".Description)
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Document_No__; AppldCustLedgEntryTmp."Document No.")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Posting_Date_; AppldCustLedgEntryTmp."Posting Date")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Initial_Entry_Due_Date_; AppldCustLedgEntryTmp."Initial Entry Due Date")
                    {
                    }
                    column(Detailed_Cust__Ledg__Entry__Currency_Code_; AppldCustLedgEntryTmp."Currency Code")
                    {
                    }
                    column(ABS_Amount_; Abs(AppldCustLedgEntryTmp.Amount))
                    {
                    }
                    column(ABS__Amount__LCY___; Abs(AppldCustLedgEntryTmp."Amount (LCY)"))
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
                        DueDate: Date;
                        LegalDueDate: Date;
                    begin
                        if Number = 1 then begin
                            if not AppldCustLedgEntryTmp.FindSet() then
                                CurrReport.Break();
                        end else
                            if AppldCustLedgEntryTmp.Next() = 0 then
                                CurrReport.Break();

                        LegalDueDate := DtldEntryNoToLegalDueDateMap.Get(AppldCustLedgEntryTmp."Entry No.");
                        if AppldCustLedgEntryTmp."Posting Date" > LegalDueDate then begin
                            CustPaymentOutsideLegalDueDate += AppldCustLedgEntryTmp."Amount (LCY)";
                            TotalPaymentOutsideLegalDueDate += AppldCustLedgEntryTmp."Amount (LCY)";
                        end else begin
                            CustPaymentWithinLegalDueDate += AppldCustLedgEntryTmp."Amount (LCY)";
                            TotalPaymentWithinLegalDueDate += AppldCustLedgEntryTmp."Amount (LCY)";
                        end;

                        DueDate := AppldCustLedgEntryTmp."Initial Entry Due Date";
                        if ShowPayments = ShowPayments::"Legally Overdue" then
                            DueDate := LegalDueDate;

                        DaysOverdue := AppldCustLedgEntryTmp."Posting Date" - DueDate;
                        if DaysOverdue < 0 then
                            DaysOverdue := 0;

                        if AppldCustLedgEntryTmp."Entry Type" = AppldCustLedgEntryTmp."Entry Type"::"Initial Entry" then
                            AppldCustLedgEntryTmp."Posting Date" := 0D
                        else begin
                            CustApplAmount += Abs(AppldCustLedgEntryTmp."Amount (LCY)");
                            TotalApplAmount += Abs(AppldCustLedgEntryTmp."Amount (LCY)");
                            CustWeightedExceededAmount += DaysOverdue * Abs(AppldCustLedgEntryTmp."Amount (LCY)");
                            TotalWeightedExceededAmount += DaysOverdue * Abs(AppldCustLedgEntryTmp."Amount (LCY)");
                        end;

                        CustDaysOverdue += DaysOverdue;
                        TotalDaysOverdue += DaysOverdue;

                        CustTotalAmount := CustPaymentOutsideLegalDueDate + CustPaymentWithinLegalDueDate;
                        TotalAmount := TotalPaymentOutsideLegalDueDate + TotalPaymentWithinLegalDueDate;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    FindAppliedPayments("Entry No.");
                    FindOpenInvoices("Entry No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ClearCustAmount();
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
        CustFilter := Customer.GetFilters();
        if StartDate = 0D then
            Error(Text1100001);
        if EndDate = 0D then
            Error(Text1100002);

        if StartDate > EndDate then
            Error(Text1100003);
    end;

    var
        AppldCustLedgEntryTmp: Record "Detailed Cust. Ledg. Entry" temporary;
        DtldEntryNoToLegalDueDateMap: Dictionary of [Integer, Date];
        StartDate: Date;
        EndDate: Date;
        CustFilter: Text[250];
        Text001: Label 'Max. Allowed Due Date';
        Text1100001: Label 'You must specify the start date for the period.';
        Text1100002: Label 'You must specify the end date for the period.';
        Text1100003: Label 'The start date cannot be later than the end date.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer___Overdue_PaymentsCaptionLbl: Label 'Customer - Overdue Payments';
        ShowPaymentsCaptionLbl: Label 'Show payments:';
        FORMAT_StartDate___________FORMAT_EndDate_CaptionLbl: Label 'Period:';
        ABS_TotalPaymentWithinDueDate_CaptionLbl: Label 'Payments within the legal limit (LCY):';
        ABS_TotalPaymentOutsideDueDate_CaptionLbl: Label 'Payments outside the legal limit (LCY):';
        WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___CaptionLbl: Label 'Weighted average term exceeded:';
        TotalCaptionLbl: Label 'Total';
        WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100057CaptionLbl: Label 'Weighted average term exceeded:';
        ABS_TotalPaymentWithinDueDate__Control1100044CaptionLbl: Label 'Payments within the legal limit (LCY):';
        ABS_TotalPaymentOutsideDueDate__Control1100045CaptionLbl: Label 'Payments outside the legal limit (LCY):';
        Cust__Ledger_Entry___Document_No__CaptionLbl: Label 'Invoice No.';
        Cust__Ledger_Entry__DescriptionCaptionLbl: Label 'Invoice Description';
        Detailed_Cust__Ledg__Entry__Document_No__CaptionLbl: Label 'Document No. (Payment)';
        Detailed_Cust__Ledg__Entry__Posting_Date_CaptionLbl: Label 'Posting Date (Payment)';
        Detailed_Cust__Ledg__Entry__Currency_Code_CaptionLbl: Label 'Currency Code';
        ABS_Amount_CaptionLbl: Label 'Amount';
        ABS__Amount__LCY___CaptionLbl: Label 'Amount(LCY)';
        DaysOverdue_Control1100024CaptionLbl: Label 'Days Overdue';
        TotalPaymentWithinLegalDueDate: Decimal;
        TotalPaymentOutsideLegalDueDate: Decimal;
        DaysOverdue: Decimal;
        CustWeightedExceededAmount: Decimal;
        WeightedExceededAmount: Decimal;
        CustApplAmount: Decimal;
        TotalApplAmount: Decimal;
        CustTotalAmount: Decimal;
        TotalAmount: Decimal;
        CustPaymentOutsideLegalDueDate: Decimal;
        CustPaymentWithinLegalDueDate: Decimal;
        CustDaysOverdue: Decimal;
        TotalDaysOverdue: Decimal;
        TotalWeightedExceededAmount: Decimal;
        ShowPayments: Option Overdue,"Legally Overdue",All;

    local procedure FindAppliedPayments(CustLedgEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        AppldCustLedgEntryTmp.Reset();
        AppldCustLedgEntryTmp.DeleteAll();
        InvCustLedgEntry.Get(CustLedgEntryNo);

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        DtldCustLedgEntry.SetRange("Posting Date", StartDate, EndDate);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." = DtldCustLedgEntry."Applied Cust. Ledger Entry No." then
                    FindAppPaymToInv(DtldCustLedgEntry."Applied Cust. Ledger Entry No.", InvCustLedgEntry)
                else
                    FindAppInvToPaym(DtldCustLedgEntry, InvCustLedgEntry);
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure FindAppPaymToInv(AppliedCustLedgEntryNo: Integer; InvCustLedgEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PayCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange(
          "Applied Cust. Ledger Entry No.", AppliedCustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        DtldCustLedgEntry.SetRange("Posting Date", StartDate, EndDate);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." <> DtldCustLedgEntry."Applied Cust. Ledger Entry No." then
                    if IsPaymentEntry(DtldCustLedgEntry."Cust. Ledger Entry No.", PayCustLedgEntry) and
                       PrintEntry(InvCustLedgEntry, DtldCustLedgEntry."Posting Date")
                    then begin
                        AppldCustLedgEntryTmp := DtldCustLedgEntry;
                        AppldCustLedgEntryTmp."Document No." := PayCustLedgEntry."Document No.";
                        AppldCustLedgEntryTmp."Currency Code" := PayCustLedgEntry."Currency Code";
                        AppldCustLedgEntryTmp."Initial Entry Due Date" := InvCustLedgEntry."Due Date";
                        AppldCustLedgEntryTmp.Amount := -AppldCustLedgEntryTmp.Amount;
                        AppldCustLedgEntryTmp."Amount (LCY)" := -AppldCustLedgEntryTmp."Amount (LCY)";
                        if AppldCustLedgEntryTmp.Insert() then;
                        DtldEntryNoToLegalDueDateMap.Add(AppldCustLedgEntryTmp."Entry No.", CalcMaxDueDate(InvCustLedgEntry));
                    end;
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure FindAppInvToPaym(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; InvCustLedgEntry: Record "Cust. Ledger Entry")
    var
        PayCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if IsPaymentEntry(DtldCustLedgEntry."Applied Cust. Ledger Entry No.", PayCustLedgEntry) and
           PrintEntry(InvCustLedgEntry, DtldCustLedgEntry."Posting Date")
        then begin
            AppldCustLedgEntryTmp := DtldCustLedgEntry;
            AppldCustLedgEntryTmp."Cust. Ledger Entry No." := AppldCustLedgEntryTmp."Applied Cust. Ledger Entry No.";
            AppldCustLedgEntryTmp."Document No." := PayCustLedgEntry."Document No.";
            AppldCustLedgEntryTmp."Currency Code" := PayCustLedgEntry."Currency Code";
            if AppldCustLedgEntryTmp.Insert() then;
            DtldEntryNoToLegalDueDateMap.Add(AppldCustLedgEntryTmp."Entry No.", CalcMaxDueDate(InvCustLedgEntry));
        end;
    end;

    local procedure PrintEntry(InvCustLedgEntry: Record "Cust. Ledger Entry"; PaymentAppDate: Date): Boolean
    var
        MaxAllowedDueDate: Date;
    begin
        if ShowPayments = ShowPayments::All then
            exit(true);

        MaxAllowedDueDate := CalcMaxDueDate(InvCustLedgEntry);

        case ShowPayments of
            ShowPayments::Overdue:
                exit(PaymentAppDate > InvCustLedgEntry."Due Date");
            ShowPayments::"Legally Overdue":
                exit(PaymentAppDate > MaxAllowedDueDate);
        end;
    end;

    local procedure CalcMaxDueDate(InvCustLedgEntry: Record "Cust. Ledger Entry"): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(InvCustLedgEntry."Payment Terms Code") and (PaymentTerms."Max. No. of Days till Due Date" > 0) then
            exit(PaymentTerms.CalculateMaxDueDate(InvCustLedgEntry."Document Date"));

        exit(InvCustLedgEntry."Due Date");
    end;

    local procedure GetDueDateCaption(): Text[100]
    begin
        case ShowPayments of
            ShowPayments::Overdue,
          ShowPayments::All:
                exit("Cust. Ledger Entry".FieldCaption("Due Date"));
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

    local procedure FindOpenInvoices(CustLedgEntryNo: Integer)
    var
        InvCustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        InvCustLedgEntry.Get(CustLedgEntryNo);
        InvCustLedgEntry.SetRange("Date Filter", 0D, EndDate);
        InvCustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if InvCustLedgEntry."Remaining Amount" <> 0 then
            if PrintEntry(InvCustLedgEntry, EndDate) then begin
                DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
                DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", InvCustLedgEntry."Entry No.");
                DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
                if DtldCustLedgEntry.FindFirst() then begin
                    AppldCustLedgEntryTmp := DtldCustLedgEntry;
                    AppldCustLedgEntryTmp."Initial Entry Due Date" := InvCustLedgEntry."Due Date";
                    AppldCustLedgEntryTmp.Amount := -InvCustLedgEntry."Remaining Amount";
                    AppldCustLedgEntryTmp."Amount (LCY)" := -InvCustLedgEntry."Remaining Amt. (LCY)";
                    AppldCustLedgEntryTmp."Document No." := '';
                    AppldCustLedgEntryTmp."Posting Date" := EndDate;
                    if AppldCustLedgEntryTmp.Insert() then;
                    DtldEntryNoToLegalDueDateMap.Add(AppldCustLedgEntryTmp."Entry No.", CalcMaxDueDate(InvCustLedgEntry));
                end;
            end;
    end;

    local procedure IsPaymentEntry(CustLedgEntryNo: Integer; var PayCustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        if not (PayCustLedgEntry.Get(CustLedgEntryNo) and
                (PayCustLedgEntry."Document Type" = PayCustLedgEntry."Document Type"::Payment))
        then
            exit(false);

        exit(true);
    end;

    local procedure ClearCustAmount()
    begin
        CustTotalAmount := 0;
        CustDaysOverdue := 0;
        CustWeightedExceededAmount := 0;
        CustPaymentOutsideLegalDueDate := 0;
        CustPaymentWithinLegalDueDate := 0;
        CustApplAmount := 0;
    end;

    local procedure CalcWeightedExceededAmt(): Decimal
    begin
        if CustApplAmount = 0 then
            exit(0);
        exit(CustWeightedExceededAmount / Abs(CustApplAmount));
    end;

    local procedure CalcTotalWeightedExceededAmt(): Decimal
    begin
        if TotalApplAmount = 0 then
            exit(0);
        exit(TotalWeightedExceededAmount / Abs(TotalApplAmount));
    end;

    local procedure GetDivisionAmount(Amount: Decimal; Divider: Decimal): Decimal
    begin
        if Divider = 0 then
            exit(0);
        exit(Amount / Divider);
    end;

    local procedure GetWeightedExceededAmountPerCustomer(): Decimal
    begin
        if CustTotalAmount = 0 then
            exit(0);
        exit(WeightedExceededAmount / Abs(CustTotalAmount));
    end;

    local procedure GetWeightedExceededAmountPerTotal(): Decimal
    begin
        if TotalAmount = 0 then
            exit(0);
        exit(WeightedExceededAmount / Abs(TotalAmount));
    end;
}

