// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using System.Utilities;

report 7000007 "Vendor - Due Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorDuePayments.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Due Payments';
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
            column(Vendor_Ledger_Entry__TABLECAPTION__________VLETableFilter; "Vendor Ledger Entry".TableCaption + ': ' + VLETableFilter)
            {
            }
            column(VLETableFilter; VLETableFilter)
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
            column(Vendor___Due_PaymentsCaption; Vendor___Due_PaymentsCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amt___LCY__Caption; "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amount_Caption; "Vendor Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_Caption; "Vendor Ledger Entry".FieldCaption("Currency Code"))
            {
            }
            column(PaymentMethodCaption; PaymentMethodCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; "Vendor Ledger Entry".FieldCaption("Vendor No."))
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; Vendor_Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(AccumRemainingAmtLCYCaption; AccumRemainingAmtLCYCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true));
                RequestFilterFields = "Vendor No.", "Document Type", "Due Date";
                column(Vendor_Ledger_Entry__Vendor_Ledger_Entry___Remaining_Amt___LCY__; "Vendor Ledger Entry"."Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(AccumRemainingAmtLCYTrans; AccumRemainingAmtLCYTrans)
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Vendor_Ledger_Entry_Description; Description)
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Vendor_Ledger_Entry__Remaining_Amount_; "Remaining Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
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
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY___Control26; "Remaining Amt. (LCY)")
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
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY___Control18; "Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(ContinuedCaption_Control22; ContinuedCaption_Control22Lbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    PurchCrMemo: Record "Purch. Cr. Memo Hdr.";
                begin
                    Clear(PurchInv);
                    PaymentMethod := '';
                    CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if PurchInv.Get("Document No.") then
                                PaymentMethod := PurchInv."Payment Method Code";
                        "Document Type"::Bill:
                            begin
                                Doc.SetCurrentKey(Type, "Document No.");
                                Doc.SetRange(Type, Doc.Type::Payable);
                                Doc.SetRange("Document No.", "Document No.");
                                if Doc.FindFirst() then
                                    PaymentMethod := Doc."Payment Method Code"
                                else begin
                                    PostedDoc.SetCurrentKey(Type, "Document No.");
                                    PostedDoc.SetRange(Type, PostedDoc.Type::Payable);
                                    PostedDoc.SetRange("Document No.", "Document No.");
                                    if PostedDoc.FindFirst() then
                                        PaymentMethod := PostedDoc."Payment Method Code"
                                    else begin
                                        ClosedDoc.SetCurrentKey(Type, "Document No.");
                                        ClosedDoc.SetRange(Type, ClosedDoc.Type::Payable);
                                        ClosedDoc.SetRange("Document No.", "Document No.");
                                        if ClosedDoc.FindFirst() then
                                            PaymentMethod := ClosedDoc."Payment Method Code";
                                    end;
                                end;
                            end;
                        "Document Type"::"Credit Memo":
                            if PurchCrMemo.Get("Document No.") then
                                PaymentMethod := PurchCrMemo."Payment Method Code";
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
        DueDateFilter := "Vendor Ledger Entry".GetFilter("Due Date");
        FromDate := "Vendor Ledger Entry".GetRangeMin("Due Date");
        ToDate := "Vendor Ledger Entry".GetRangeMax("Due Date");

        VLETableFilter := "Vendor Ledger Entry".GetFilters();
    end;

    var
        Text1100000: Label 'Total %1 %2';
        PurchInv: Record "Purch. Inv. Header";
        DueDateFilter: Code[250];
        VLETableFilter: Code[250];
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
        Vendor___Due_PaymentsCaptionLbl: Label 'Vendor - Due Payments';
        PaymentMethodCaptionLbl: Label 'Pmt. Method Code';
        Vendor_Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        AccumRemainingAmtLCYCaptionLbl: Label 'Accumulated Remaining Amt. (LCY)';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control22Lbl: Label 'Continued';
}

