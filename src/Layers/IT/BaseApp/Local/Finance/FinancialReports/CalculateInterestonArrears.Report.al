// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 12107 "Calculate Interest on Arrears"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/FinancialReports/CalculateInterestonArrears.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate Interest on Arrears';
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(IntLedgerEntrySource; IntLedgerEntrySource)
            {
            }
            column(IntLedgerEntryTotal; IntLedgerEntryTotal)
            {
            }
            column(Customer_No_; "No.")
            {
            }
            column(Interest_AmountCaption; Interest_AmountCaptionLbl)
            {
            }
            column(Interest_RateCaption; Interest_RateCaptionLbl)
            {
            }
            column(No__of_Interest_DaysCaption; No__of_Interest_DaysCaptionLbl)
            {
            }
            column(Calculation_Starting_DateCaption; Calculation_Starting_DateCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__Caption; "Cust. Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Due_Date_Caption; Cust__Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Posting_Date_Caption; Cust__Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry__Document_Type_Caption; "Cust. Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; "Cust. Ledger Entry".FieldCaption("Customer No."))
            {
            }
            column(Ending_DateCaption; Ending_DateCaptionLbl)
            {
            }
            column(Base_AmountCaption; Base_AmountCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Paid_Int__Arrears_Amount_Caption; "Cust. Ledger Entry".FieldCaption("Paid Int. Arrears Amount"))
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Interest_on_ArrearsCaption; Interest_on_ArrearsCaptionLbl)
            {
            }
            column(Total_for_CustomerCaption; Total_for_CustomerCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Document Occurrence", "Customer No.", Open) where("Document Type" = const(Invoice));
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Customer_Name; Customer.Name)
                {
                }
                column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Due_Date__Control1130014; Format("Due Date"))
                {
                }
                column(TotalDayDiff; TotalDayDiff)
                {
                }
                column(RateLabel; RateLabel)
                {
                }
                column(IntLedgerEntry; IntLedgerEntry)
                {
                }
                column(RateInterestDate; Format(RateInterestDate))
                {
                }
                column(Cust__Ledger_Entry__Paid_Int__Arrears_Amount_; "Paid Int. Arrears Amount")
                {
                }
                column(Customer__No__; Customer."No.")
                {
                }
                column(Customer_Name_Control1130093; Customer.Name)
                {
                }
                column(Cust__Ledger_Entry__Document_Type__Control1130094; "Document Type")
                {
                }
                column(Cust__Ledger_Entry__Document_No___Control1130095; "Document No.")
                {
                }
                column(Cust__Ledger_Entry__Posting_Date__Control1130096; Format("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Due_Date__Control1130097; Format("Due Date"))
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY___Control1130098; "Remaining Amt. (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Paid_Int__Arrears_Amount__Control1130099; "Paid Int. Arrears Amount")
                {
                }
                column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                dataitem("<CustInteger>"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(IntLedgerEntryDetail_Number_; IntLedgerEntryDetail[Number])
                    {
                    }
                    column(RateLabelDetail_Number_; RateLabelDetail[Number])
                    {
                    }
                    column(DayDiffDetail_Number_; DayDiffDetail[Number])
                    {
                    }
                    column(RateInterestDateDetail_Number_; Format(RateInterestDateDetail[Number]))
                    {
                    }
                    column(PostingDate_Number_; Format(PostingDate[Number]))
                    {
                    }
                    column(DocNo_Number_; DocNo[Number])
                    {
                    }
                    column(DocType_Number_; DocType[Number])
                    {
                    }
                    column(DueDate_Number_; Format(DueDate[Number]))
                    {
                    }
                    column(BaseAmount_Number_; BaseAmount[Number])
                    {
                    }
                    column(CustInteger__Number; Number)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not PrintDetail then
                            CurrReport.Break();
                        SetRange(Number, 1, (ix + 1));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RateInterestDate := RateInterestDateTmp;
                    for j := 1 to ix do begin
                        DocType[j] := DocType::" ";
                        DocNo[j] := '';
                        PostingDate[j] := 0D;
                        DueDate[j] := 0D;
                        RateInterestDateDetail[j] := 0D;
                        BaseAmount[j] := 0;
                        DayDiffDetail[j] := 0;
                        RateLabelDetail[j] := '';
                        IntLedgerEntryDetail[j] := 0;
                    end;
                    ix2 := 0;
                    IntLedgerEntry := 0;
                    TotalDayDiff := 0;
                    CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                    TotalAmount := "Amount (LCY)";
                    CustLedgerEntry := "Cust. Ledger Entry";
                    CreateCustLedgEntry := "Cust. Ledger Entry";
                    PrevIntLedgerEntrySource := IntLedgerEntrySource;
                    ix2 := ix2 + 1;
                    DueDateTmp[ix2] := "Due Date";

                    CustLedgerEntry.Reset();
                    CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    CustLedgerEntry.SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
                    CustLedgerEntry.SetFilter("Posting Date", '<%1', CreateCustLedgEntry."Due Date");
                    if CustLedgerEntry.FindSet() then
                        repeat
                            CustLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                            TotalAmount := TotalAmount + CustLedgerEntry."Amount (LCY)";
                        until CustLedgerEntry.Next() = 0;
                    CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    CustLedgerEntry.SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
                    CustLedgerEntry.SetFilter("Posting Date", '>=%1', CreateCustLedgEntry."Due Date");
                    if CustLedgerEntry.FindSet() then
                        repeat
                            ix2 := ix2 + 1;
                            DueDateTmp[ix2] := CustLedgerEntry."Posting Date";
                        until CustLedgerEntry.Next() = 0;
                    ix := 0;
                    CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    CustLedgerEntry.SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
                    CustLedgerEntry.SetFilter("Posting Date", '>=%1 & <=%2', CreateCustLedgEntry."Due Date", RateInterestDate);
                    if (not CustLedgerEntry.FindFirst()) and (not CustLedgerEntry.Get("Closed by Entry No.")) then begin
                        ix := ix + 1;
                        BaseAmount[ix] := TotalAmount;
                        IntLedgerEntryDetail[ix] :=
                          Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Customer."Int. on Arrears Code"),
                            GLSetup."Amount Rounding Precision");
                        DueDate[ix] := RateInterestDate;
                        DocType[ix] := "Document Type";
                        DocNo[ix] := "Document No.";
                        PostingDate[ix] := "Posting Date";
                        IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                        IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                        RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                    end else begin
                        CustLedgerEntry.SetCurrentKey("Closed by Entry No.");
                        CustLedgerEntry.SetRange("Closed by Entry No.", CreateCustLedgEntry."Entry No.");
                        CustLedgerEntry.SetFilter("Posting Date", '>=%1', CreateCustLedgEntry."Due Date");
                        if CustLedgerEntry.FindSet() then
                            repeat
                                CustLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                                ix := ix + 1;
                                if ix <= ix2 - 1 then begin
                                    ixBefore := ix;
                                    if CustLedgerEntry."Posting Date" <= RateInterestDate then begin
                                        BaseAmount[ix] := TotalAmount;
                                        IntLedgerEntryDetail[ix] :=
                                          Round(
                                            Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], CustLedgerEntry."Posting Date", Customer."Int. on Arrears Code"),
                                            GLSetup."Amount Rounding Precision");
                                        DueDate[ix] := CustLedgerEntry."Posting Date";
                                        TotalAmount := TotalAmount + CustLedgerEntry."Amount (LCY)";
                                        DocType[ix] := CustLedgerEntry."Document Type";
                                        DocNo[ix] := CustLedgerEntry."Document No.";
                                        PostingDate[ix] := CustLedgerEntry."Posting Date";
                                    end else begin
                                        BaseAmount[ix] := TotalAmount;
                                        IntLedgerEntryDetail[ix] :=
                                          Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Customer."Int. on Arrears Code"),
                                            GLSetup."Amount Rounding Precision");
                                        DueDate[ix] := RateInterestDate;
                                        DocType[ix] := DocType[ix] ::" ";
                                        DocNo[ix] := '';
                                        PostingDate[ix] := 0D;
                                    end;
                                    IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                                    IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                                    RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                                end;
                            until CustLedgerEntry.Next() = 0;
                    end;
                    if CustLedgerEntry.Get("Closed by Entry No.") then begin
                        ix := ix + 1;

                        if CustLedgerEntry."Posting Date" < "Due Date" then
                            exit;

                        if CustLedgerEntry."Posting Date" <= RateInterestDate then begin
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], CustLedgerEntry."Posting Date", Customer."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DocType[ix] := CustLedgerEntry."Document Type";
                            DocNo[ix] := CustLedgerEntry."Document No.";
                            PostingDate[ix] := CustLedgerEntry."Posting Date";
                            DueDate[ix] := CustLedgerEntry."Posting Date";
                        end else begin
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Customer."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DueDate[ix] := RateInterestDate;
                            DocType[ix] := DocType[ix] ::" ";
                            DocNo[ix] := '';
                            PostingDate[ix] := 0D;
                        end;
                        IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                        IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                        RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                    end else
                        if DueDate[ix] <> RateInterestDate then begin
                            ix := ix + 1;
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Customer."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DueDate[ix] := RateInterestDate;
                            DocType[ix] := DocType[ix] ::" ";
                            DocNo[ix] := '';
                            PostingDate[ix] := 0D;
                            IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                            IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                            RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                        end;
                    if (IntLedgerEntry = "Int. Arrears Amount to Pay") and OnlyOpen then begin
                        IntLedgerEntrySource := PrevIntLedgerEntrySource;
                        CurrReport.Skip();
                    end;
                    "Int. Arrears Amount to Pay" := IntLedgerEntry;
                    Modify();

                    FinanceChargeTerms.Get(Customer."Int. on Arrears Code");

                    if IntLedgerEntry < FinanceChargeTerms."Minimum Amount (LCY)" then begin
                        IntLedgerEntrySource := PrevIntLedgerEntrySource;
                        CurrReport.Skip();
                    end;
                    IntLedgerEntryTotal += IntLedgerEntry;
                end;

                trigger OnPreDataItem()
                begin
                    if RateInterestDateTmp <> RateInterestDate then
                        RateInterestDate := RateInterestDateTmp;
                    "Cust. Ledger Entry".SetFilter("Due Date", '..%1', RateInterestDate);
                    if (FromDate <> 0D) and (ToDate <> 0D) then
                        "Cust. Ledger Entry".SetFilter("Posting Date", '%1..%2', FromDate, ToDate);
                    if (FromDate <> 0D) and (ToDate = 0D) then
                        "Cust. Ledger Entry".SetFilter("Posting Date", '%1..', FromDate);
                    if (FromDate = 0D) and (ToDate <> 0D) then
                        "Cust. Ledger Entry".SetFilter("Posting Date", '..%1', ToDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IntLedgerEntry := 0;
                RateInterestDate := RateInterestDateTmp;
                IntLedgerEntrySource := 0;
            end;

            trigger OnPreDataItem()
            begin
                if PrintType = PrintType::Vendor then
                    CurrReport.Break();
            end;
        }
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
            column(USERID_Control1130086; UserId)
            {
            }
            column(COMPANYNAME_Control1130087; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4__Control1130091; Format(Today, 0, 4))
            {
            }
            column(PrintDetail_Control1130116; PrintDetail)
            {
            }
            column(IntLedgerEntrySource_Control1130113; IntLedgerEntrySource)
            {
            }
            column(IntLedgerEntryTotal_Control1130033; IntLedgerEntryTotal)
            {
            }
            column(Vendor_No_; "No.")
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; "Vendor Ledger Entry".FieldCaption("Vendor No."))
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; "Vendor Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; Vendor_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; Vendor_Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amt___LCY__Caption; "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Calculation_Starting_DateCaption_Control1130036; Calculation_Starting_DateCaption_Control1130036Lbl)
            {
            }
            column(No__of_Interest_DaysCaption_Control1130035; No__of_Interest_DaysCaption_Control1130035Lbl)
            {
            }
            column(Interest_RateCaption_Control1130034; Interest_RateCaption_Control1130034Lbl)
            {
            }
            column(Ending_DateCaption_Control1130061; Ending_DateCaption_Control1130061Lbl)
            {
            }
            column(Base_AmountCaption_Control1130062; Base_AmountCaption_Control1130062Lbl)
            {
            }
            column(Vendor_Ledger_Entry__Paid_Int__Arrears_Amount_Caption; "Vendor Ledger Entry".FieldCaption("Paid Int. Arrears Amount"))
            {
            }
            column(Interest_AmountCaption_Control1130079; Interest_AmountCaption_Control1130079Lbl)
            {
            }
            column(CurrReport_PAGENO_Control1130089Caption; CurrReport_PAGENO_Control1130089CaptionLbl)
            {
            }
            column(Interest_on_ArrearsCaption_Control1130090; Interest_on_ArrearsCaption_Control1130090Lbl)
            {
            }
            column(Total_for_VendorCaption; Total_for_VendorCaptionLbl)
            {
            }
            column(TotalCaption_Control1130060; TotalCaption_Control1130060Lbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") where("Document Type" = const(Invoice));
                column(IntLedgerEntry_Control1130022; IntLedgerEntry)
                {
                }
                column(RateLabel_Control1130023; RateLabel)
                {
                }
                column(TotalDayDiff_Control1130024; TotalDayDiff)
                {
                }
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(Vendor_Ledger_Entry__Due_Date_; Format("Due Date"))
                {
                }
                column(Vendor_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Vendor_Name; Vendor.Name)
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(RateInterestDate_Control1130063; Format(RateInterestDate))
                {
                }
                column(Vendor_Ledger_Entry__Due_Date__Control1130064; Format("Due Date"))
                {
                }
                column(Vendor_Ledger_Entry__Paid_Int__Arrears_Amount_; "Paid Int. Arrears Amount")
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No___Control1130102; "Vendor No.")
                {
                }
                column(Vendor_Name_Control1130103; Vendor.Name)
                {
                }
                column(Vendor_Ledger_Entry__Document_Type__Control1130104; "Document Type")
                {
                }
                column(Vendor_Ledger_Entry__Document_No___Control1130105; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry__Posting_Date__Control1130106; Format("Posting Date"))
                {
                }
                column(Vendor_Ledger_Entry__Paid_Int__Arrears_Amount__Control1130107; "Paid Int. Arrears Amount")
                {
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                dataitem("<VenInteger>"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(DocType_Number__Control1130067; DocType[Number])
                    {
                    }
                    column(DocNo_Number__Control1130068; DocNo[Number])
                    {
                    }
                    column(PostingDate_Number__Control1130069; Format(PostingDate[Number]))
                    {
                    }
                    column(RateInterestDateDetail_Number__Control1130070; Format(RateInterestDateDetail[Number]))
                    {
                    }
                    column(DueDate_Number__Control1130071; Format(DueDate[Number]))
                    {
                    }
                    column(BaseAmount_Number__Control1130072; BaseAmount[Number])
                    {
                    }
                    column(DayDiffDetail_Number__Control1130073; DayDiffDetail[Number])
                    {
                    }
                    column(RateLabelDetail_Number__Control1130074; RateLabelDetail[Number])
                    {
                    }
                    column(IntLedgerEntryDetail_Number__Control1130075; IntLedgerEntryDetail[Number])
                    {
                    }
                    column(VenInteger__Number; Number)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not PrintDetail then
                            CurrReport.Break();
                        SetRange(Number, 1, (ix + 1));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RateInterestDate := RateInterestDateTmp;
                    for j := 1 to ix do begin
                        DocType[j] := DocType::" ";
                        DocNo[j] := '';
                        PostingDate[j] := 0D;
                        DueDate[j] := 0D;
                        RateInterestDateDetail[j] := 0D;
                        BaseAmount[j] := 0;
                        DayDiffDetail[j] := 0;
                        RateLabelDetail[j] := '';
                        IntLedgerEntryDetail[j] := 0;
                    end;
                    ix2 := 0;
                    IntLedgerEntry := 0;
                    TotalDayDiff := 0;
                    CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                    TotalAmount := "Amount (LCY)";
                    VenLedgerEntry := "Vendor Ledger Entry";
                    CreateVendLedgEntry := "Vendor Ledger Entry";
                    PrevIntLedgerEntrySource := IntLedgerEntrySource;
                    ix2 := ix2 + 1;
                    DueDateTmp[ix2] := "Due Date";
                    VenLedgerEntry.Reset();
                    VenLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    VenLedgerEntry.SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
                    VenLedgerEntry.SetFilter("Posting Date", '<%1', CreateVendLedgEntry."Due Date");
                    if VenLedgerEntry.FindSet() then
                        repeat
                            VenLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                            TotalAmount := TotalAmount + VenLedgerEntry."Amount (LCY)";
                        until VenLedgerEntry.Next() = 0;

                    VenLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    VenLedgerEntry.SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
                    VenLedgerEntry.SetFilter("Posting Date", '>=%1', CreateVendLedgEntry."Due Date");
                    if VenLedgerEntry.FindSet() then
                        repeat
                            ix2 := ix2 + 1;
                            DueDateTmp[ix2] := VenLedgerEntry."Posting Date";
                        until VenLedgerEntry.Next() = 0;

                    ix := 0;
                    VenLedgerEntry.SetCurrentKey("Closed by Entry No.");
                    VenLedgerEntry.SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
                    VenLedgerEntry.SetFilter("Posting Date", '>=%1 & <= %2', CreateVendLedgEntry."Due Date", RateInterestDate);
                    if (not VenLedgerEntry.FindFirst()) and (not VenLedgerEntry.Get("Closed by Entry No.")) then begin
                        ix := ix + 1;
                        BaseAmount[ix] := TotalAmount;
                        IntLedgerEntryDetail[ix] :=
                          Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Vendor."Int. on Arrears Code"),
                            GLSetup."Amount Rounding Precision");
                        DueDate[ix] := RateInterestDate;
                        IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                        IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                        RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                        DocType[ix] := "Document Type";
                        DocNo[ix] := "Document No.";
                        PostingDate[ix] := "Posting Date";
                    end else begin
                        VenLedgerEntry.SetCurrentKey("Closed by Entry No.");
                        VenLedgerEntry.SetRange("Closed by Entry No.", CreateVendLedgEntry."Entry No.");
                        VenLedgerEntry.SetFilter("Posting Date", '>=%1', CreateVendLedgEntry."Due Date");
                        if VenLedgerEntry.FindSet() then
                            repeat
                                VenLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                                ix := ix + 1;
                                if ix <= ix2 - 1 then begin
                                    ixBefore := ix;
                                    if VenLedgerEntry."Posting Date" <= RateInterestDate then begin
                                        BaseAmount[ix] := TotalAmount;
                                        IntLedgerEntryDetail[ix] :=
                                          Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], VenLedgerEntry."Posting Date", Vendor."Int. on Arrears Code"),
                                            GLSetup."Amount Rounding Precision");
                                        DueDate[ix] := VenLedgerEntry."Posting Date";
                                        TotalAmount := TotalAmount + VenLedgerEntry."Amount (LCY)";
                                        DocType[ix] := VenLedgerEntry."Document Type";
                                        DocNo[ix] := VenLedgerEntry."Document No.";
                                        PostingDate[ix] := VenLedgerEntry."Posting Date";
                                    end else begin
                                        BaseAmount[ix] := TotalAmount;
                                        IntLedgerEntryDetail[ix] :=
                                          Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Vendor."Int. on Arrears Code"),
                                            GLSetup."Amount Rounding Precision");
                                        DueDate[ix] := RateInterestDate;
                                        DocType[ix] := DocType[ix] ::" ";
                                        DocNo[ix] := '';
                                        PostingDate[ix] := 0D;
                                    end;
                                    IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                                    IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                                    RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                                end;
                            until VenLedgerEntry.Next() = 0;
                    end;

                    if VenLedgerEntry.Get("Closed by Entry No.") then begin
                        ix := ix + 1;

                        if VenLedgerEntry."Posting Date" < "Due Date" then
                            exit;

                        if VenLedgerEntry."Posting Date" <= RateInterestDate then begin
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], VenLedgerEntry."Posting Date", Vendor."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DocType[ix] := VenLedgerEntry."Document Type";
                            DocNo[ix] := VenLedgerEntry."Document No.";
                            PostingDate[ix] := VenLedgerEntry."Posting Date";
                            DueDate[ix] := VenLedgerEntry."Posting Date";
                        end else begin
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Vendor."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DueDate[ix] := RateInterestDate;
                            DocType[ix] := DocType[ix] ::" ";
                            DocNo[ix] := '';
                            PostingDate[ix] := 0D;
                        end;
                        IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                        IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                        RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                    end else
                        if DueDate[ix] <> RateInterestDate then begin
                            ix := ix + 1;
                            BaseAmount[ix] := TotalAmount;
                            IntLedgerEntryDetail[ix] :=
                              Round(Abs(BaseAmount[ix]) * CalcIntArrOr(DueDateTmp[ix], RateInterestDate, Vendor."Int. on Arrears Code"),
                                GLSetup."Amount Rounding Precision");
                            DueDate[ix] := RateInterestDate;
                            DocType[ix] := DocType[ix] ::" ";
                            DocNo[ix] := '';
                            PostingDate[ix] := 0D;
                            IntLedgerEntry := IntLedgerEntry + IntLedgerEntryDetail[ix];
                            IntLedgerEntrySource := IntLedgerEntrySource + IntLedgerEntryDetail[ix];
                            RateInterestDateDetail[ix] := CalcDate('<+1D>', DueDateTmp[ix]);
                        end;
                    if (IntLedgerEntry = "Int. Arrears Amount to Pay") and OnlyOpen then begin
                        IntLedgerEntrySource := PrevIntLedgerEntrySource;
                        CurrReport.Skip();
                    end;

                    "Int. Arrears Amount to Pay" := IntLedgerEntry;
                    Modify();

                    FinanceChargeTerms.Get(Vendor."Int. on Arrears Code");

                    if IntLedgerEntry < FinanceChargeTerms."Minimum Amount (LCY)" then begin
                        IntLedgerEntrySource := PrevIntLedgerEntrySource;
                        CurrReport.Skip();
                    end;
                    IntLedgerEntryTotal += IntLedgerEntry;
                end;

                trigger OnPreDataItem()
                begin
                    if RateInterestDateTmp <> RateInterestDate then
                        RateInterestDate := RateInterestDateTmp;
                    SetFilter("Due Date", '..%1', RateInterestDate);
                    if (FromDate <> 0D) and (ToDate <> 0D) then
                        SetFilter("Posting Date", '%1..%2', FromDate, ToDate);
                    if (FromDate <> 0D) and (ToDate = 0D) then
                        SetFilter("Posting Date", '%1..', FromDate);
                    if (FromDate = 0D) and (ToDate <> 0D) then
                        SetFilter("Posting Date", '..%1', ToDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IntLedgerEntry := 0;
                RateInterestDate := RateInterestDateTmp;
            end;

            trigger OnPreDataItem()
            begin
                if PrintType = PrintType::Customer then
                    CurrReport.Break();
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
                    field(CustomerVendor; PrintType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Vendor';
                        OptionCaption = 'Customer,Vendor';
                        ToolTip = 'Specifies the customer or vendor.';
                    }
                    field(InterestCalculationAsOf; RateInterestDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interest Calculation As of';
                        ToolTip = 'Specifies the date for calculating interest from.';
                    }
                    field(PrintDetails; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Details';
                        ToolTip = 'Specifies if you want to print the details section.';
                    }
                    field(OpenEntriesOnly; OnlyOpen)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open Entries Only';
                        ToolTip = 'Specifies if you want to see only open entries.';
                    }
                    field(FromPostingDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Posting Date';
                        ToolTip = 'Specifies the start date of the posting date range.';
                    }
                    field(ToPostingDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Posting Date';
                        ToolTip = 'Specifies the last posting date.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            RateInterestDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RateInterestDateTmp := RateInterestDate;
        if (FromDate > ToDate) and (ToDate <> 0D) and (FromDate <> 0D) then
            Error(Text1130031);
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FinanceChargeTerms: Record "Finance Charge Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CreateCustLedgEntry: Record "Cust. Ledger Entry";
        VenLedgerEntry: Record "Vendor Ledger Entry";
        CreateVendLedgEntry: Record "Vendor Ledger Entry";
        PrintType: Option Customer,Vendor;
        RateInterestDate: Date;
        RateInterestDateTmp: Date;
        RateInterestDateDetail: array[100] of Date;
        IntLedgerEntry: Decimal;
        IntLedgerEntrySource: Decimal;
        IntLedgerEntryTotal: Decimal;
        IntLedgerEntryDetail: array[100] of Decimal;
        TotalDayDiff: Integer;
        DayDiffDetail: array[100] of Integer;
        RateLabel: Text[30];
        RateLabelDetail: array[100] of Text[30];
        TotalAmount: Decimal;
        BaseAmount: array[100] of Decimal;
        DueDateTmp: array[100] of Date;
        ix: Integer;
        ix2: Integer;
        DocType: array[100] of Enum "Gen. Journal Document Type";
        DocNo: array[100] of Code[20];
        PostingDate: array[100] of Date;
        DueDate: array[100] of Date;
        FromDate: Date;
        ToDate: Date;
        PrintDetail: Boolean;
        OnlyOpen: Boolean;
        Text1130031: Label 'The Starting Date is later than the Ending Date.';
        PrevIntLedgerEntrySource: Decimal;
        ixBefore: Integer;
        j: Integer;
        InvalidCalcPeriodErr: Label 'There is no calculation period earlier than %1 in table Interest on Arrears for code %2.', Comment = 'Parameter 1 - due date, 2 - interest code';
        VariableRateLbl: Label 'Variable Rate';
        Interest_AmountCaptionLbl: Label 'Interest Amount';
        Interest_RateCaptionLbl: Label 'Interest Rate';
        No__of_Interest_DaysCaptionLbl: Label 'No. of Interest Days';
        Calculation_Starting_DateCaptionLbl: Label 'Calculation Starting Date';
        Cust__Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        Cust__Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Customer_NameCaptionLbl: Label 'Customer Name';
        Ending_DateCaptionLbl: Label 'Ending Date';
        Base_AmountCaptionLbl: Label 'Base Amount';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Interest_on_ArrearsCaptionLbl: Label 'Interest on Arrears';
        Total_for_CustomerCaptionLbl: Label 'Total for Customer';
        TotalCaptionLbl: Label 'Total';
        Vendor_NameCaptionLbl: Label 'Vendor Name';
        Vendor_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Vendor_Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        Calculation_Starting_DateCaption_Control1130036Lbl: Label 'Calculation Starting Date';
        No__of_Interest_DaysCaption_Control1130035Lbl: Label 'No. of Interest Days';
        Interest_RateCaption_Control1130034Lbl: Label 'Interest Rate';
        Ending_DateCaption_Control1130061Lbl: Label 'Ending Date';
        Base_AmountCaption_Control1130062Lbl: Label 'Base Amount';
        Interest_AmountCaption_Control1130079Lbl: Label 'Interest Amount';
        CurrReport_PAGENO_Control1130089CaptionLbl: Label 'Page';
        Interest_on_ArrearsCaption_Control1130090Lbl: Label 'Interest on Arrears';
        Total_for_VendorCaptionLbl: Label 'Total for Vendor';
        TotalCaption_Control1130060Lbl: Label 'Total';

    [Scope('OnPrem')]
    procedure CalcIntArrOr(DueDate: Date; EndingDate: Date; InterestCode: Code[10]): Decimal
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        InterestonArrears: Record "Interest on Arrears";
        InterestonArrearsNext: Record "Interest on Arrears";
        StartDate: Date;
        DayDiff: Integer;
        DateFirst: Date;
        DateSecond: Date;
        RateFirst: Decimal;
        IntAmount: Decimal;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        if DueDate >= EndingDate then
            exit;

        RateLabel := '';
        InterestonArrears.SetCurrentKey(Code, "Starting Date");
        InterestonArrears.SetRange(Code, InterestCode);
        InterestonArrears.SetFilter("Starting Date", '<=%1', CalcDate('<+1D>', DueDate));
        if InterestonArrears.FindLast() then
            StartDate := InterestonArrears."Starting Date"
        else
            Error(InvalidCalcPeriodErr, DueDate, InterestonArrears.TableCaption(), InterestCode);
        InterestonArrears.Ascending(true);
        InterestonArrears.SetRange(Code, InterestCode);
        InterestonArrears.SetFilter("Starting Date", '>%1', StartDate);
        if InterestonArrears.FindFirst() then
            DateSecond := InterestonArrears."Starting Date"
        else
            DateSecond := EndingDate;
        DateFirst := DueDate;
        if ixBefore <> ix then
            DayDiffDetail[ix] := 0;
        FinanceChargeTerms.Get(InterestCode);
        InterestonArrears.SetFilter("Starting Date", '%1..%2', StartDate, EndingDate);
        TotalCount := InterestonArrears.Count();
        CurrentCount := 0;
        if InterestonArrears.FindSet() then
            repeat
                RateFirst := InterestonArrears."Interest Rate";
                if (RateLabel <> Format(InterestonArrears."Interest Rate")) and (RateLabel <> '') then
                    RateLabel := VariableRateLbl;
                if RateLabel <> VariableRateLbl then
                    RateLabel := Format(InterestonArrears."Interest Rate");
                RateLabelDetail[ix] := RateLabel;
                CurrentCount := CurrentCount + 1;
                if (DateSecond >= EndingDate) and (CurrentCount >= TotalCount) then begin
                    DayDiff := EndingDate - DateFirst;
                    DayDiffDetail[ix] += DayDiff;
                    TotalDayDiff += DayDiff;
                    IntAmount += (DayDiff / FinanceChargeTerms."Interest Period (Days)") * RateFirst / 100;
                    exit(IntAmount);
                end;
                DayDiff := DateSecond - DateFirst - 1;
                DayDiffDetail[ix] += DayDiff;
                TotalDayDiff += DayDiff;
                IntAmount += (DayDiff / FinanceChargeTerms."Interest Period (Days)") * RateFirst / 100;
                DateFirst := CalcDate('<-1D>', DateSecond);
                InterestonArrearsNext.Reset();
                InterestonArrearsNext.SetRange(Code, InterestCode);
                InterestonArrearsNext.SetFilter("Starting Date", '%1..', CalcDate('<+1D>', DateSecond));
                if InterestonArrearsNext.FindFirst() then begin
                    if EndingDate > InterestonArrearsNext."Starting Date" then
                        DateSecond := InterestonArrearsNext."Starting Date"
                    else
                        DateSecond := EndingDate;
                end else
                    DateSecond := EndingDate;
            until InterestonArrears.Next() = 0;
    end;
}

