// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 7000006 "Customer - Due Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerDuePayments.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Due Payments';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));
            PrintOnlyIfDetail = true;
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________CLETableFilter; "Cust. Ledger Entry".TableCaption + ': ' + CLETableFilter)
            {
            }
            column(CLETableFilter; CLETableFilter)
            {
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer___Due_PaymentsCaption; Customer___Due_PaymentsCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__Caption; "Cust. Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amount_Caption; "Cust. Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(Cust__Ledger_Entry__Currency_Code_Caption; "Cust. Ledger Entry".FieldCaption("Currency Code"))
            {
            }
            column(PaymentMethodCaption; PaymentMethodCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; "Cust. Ledger Entry".FieldCaption("Customer No."))
            {
            }
            column(Cust__Ledger_Entry_DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(Cust__Ledger_Entry__Due_Date_Caption; Cust__Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(AccumRemainingAmtLCYCaption; AccumRemainingAmtLCYCaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date") where(Open = const(true));
                RequestFilterFields = "Customer No.", "Document Type", "Due Date";
                column(Cust__Ledger_Entry__Cust__Ledger_Entry___Remaining_Amt___LCY__; "Cust. Ledger Entry"."Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(AccumRemainingAmtLCYTrans; AccumRemainingAmtLCYTrans)
                {
                    AutoFormatType = 1;
                }
                column(Cust__Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Cust__Ledger_Entry_Description; Description)
                {
                }
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amount_; "Remaining Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PaymentMethod; PaymentMethod)
                {
                }
                column(AccumRemainingAmtLCY; AccumRemainingAmtLCY)
                {
                    AutoFormatType = 1;
                }
                column(DueDateFormatted; Format("Due Date"))
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY___Control26; "Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(AccumRemainingAmtLCYTrans_Control27; AccumRemainingAmtLCYTrans)
                {
                    AutoFormatType = 1;
                }
                column(STRSUBSTNO_Text1100000_Date__Period_Name__DATE2DMY_Date__Period_Start__3__; StrSubstNo(Text1100000, Date."Period Name", Date2DMY(Date."Period Start", 3)))
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY___Control18; "Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(ContinuedCaption_Control22; ContinuedCaption_Control22Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(SalesInv);
                    PaymentMethod := '';
                    CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if SalesInv.Get("Document No.") then
                                PaymentMethod := SalesInv."Payment Method Code";
                        "Document Type"::Bill:
                            begin
                                Doc.SetCurrentKey(Type, "Document No.");
                                Doc.SetRange(Type, Doc.Type::Receivable);
                                Doc.SetRange("Document No.", "Document No.");
                                if Doc.FindFirst() then
                                    PaymentMethod := Doc."Payment Method Code"
                                else begin
                                    PostedDoc.SetCurrentKey(Type, "Document No.");
                                    PostedDoc.SetRange(Type, PostedDoc.Type::Receivable);
                                    PostedDoc.SetRange("Document No.", "Document No.");
                                    if PostedDoc.FindFirst() then
                                        PaymentMethod := PostedDoc."Payment Method Code"
                                    else begin
                                        ClosedDoc.SetCurrentKey(Type, "Document No.");
                                        ClosedDoc.SetRange(Type, ClosedDoc.Type::Receivable);
                                        ClosedDoc.SetRange("Document No.", "Document No.");
                                        if ClosedDoc.FindFirst() then
                                            PaymentMethod := ClosedDoc."Payment Method Code"
                                    end;
                                end;
                            end;
                    end;
                    AccumRemainingAmtLCYTrans := AccumRemainingAmtLCY;
                    AccumRemainingAmtLCY := AccumRemainingAmtLCY + "Remaining Amt. (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    FilterGroup(2);
                    SetRange("Due Date", FromDate, ToDate);
                    FilterGroup(0);
                    SetRange("Due Date", Date."Period Start", Date."Period End");
                end;
            }

            trigger OnPreDataItem()
            begin
                SetFilter("Period Start", '<=%1', FromDate);
                Find('+');
                StartFirstMonth := "Period Start";
                SetFilter("Period Start", '>%1', ToDate);
                Find('-');
                EndLastMonth := ClosingDate("Period Start" - 1);
                SetRange("Period Start", StartFirstMonth, EndLastMonth);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
    begin
        DueDateFilter := "Cust. Ledger Entry".GetFilter("Due Date");
        FromDate := "Cust. Ledger Entry".GetRangeMin("Due Date");
        ToDate := "Cust. Ledger Entry".GetRangeMax("Due Date");

        CLETableFilter := "Cust. Ledger Entry".GetFilters();
    end;

    var
        Text1100000: Label 'Total %1 %2';
        SalesInv: Record "Sales Invoice Header";
        DueDateFilter: Code[250];
        CLETableFilter: Code[250];
        FromDate: Date;
        ToDate: Date;
        StartFirstMonth: Date;
        EndLastMonth: Date;
        PaymentMethod: Code[10];
        Doc: Record "Cartera Doc.";
        PostedDoc: Record "Posted Cartera Doc.";
        ClosedDoc: Record "Closed Cartera Doc.";
        AccumRemainingAmtLCY: Decimal;
        AccumRemainingAmtLCYTrans: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer___Due_PaymentsCaptionLbl: Label 'Customer - Due Payments';
        PaymentMethodCaptionLbl: Label 'Pmt. Method Code';
        Cust__Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        AccumRemainingAmtLCYCaptionLbl: Label 'Accumulated Remaining Amt. (LCY)';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control22Lbl: Label 'Continued';
}

