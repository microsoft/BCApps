// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11006 "Vendor Detailed Aging"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorDetailedAging.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Detailed Aging';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Currency Filter", "Payment Terms Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(EndDateFormatted; StrSubstNo(Text1140000, Format(EndDate)))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendTableCaptVendFilter; Vendor.TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(No_Vend; "No.")
            {
            }
            column(Name_Vend; Name)
            {
            }
            column(PhoneNo_Vend; "Phone No.")
            {
            }
            column(GlobalDim2Filter_Vend; "Global Dimension 2 Filter")
            {
            }
            column(GlobalDim1Filter_Vend; "Global Dimension 1 Filter")
            {
            }
            column(CurrencyFilter_Vend; "Currency Filter")
            {
            }
            column(DateFilter_Vend; "Date Filter")
            {
            }
            column(VendDetailedAgingCaption; VendDetailedAgingCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(PostingDateCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(DocumentNoCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(DescriptionCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(OverDueMonthsCaption; OverDueMonthsCaptionLbl)
            {
            }
            column(RemAmtCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(CurrCodeCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption("Currency Code"))
            {
            }
            column(RemAmtLCYCaption_VendLedgEntry; "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(PhoneNoCaption_Vend; FieldCaption("Phone No."))
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Currency Code" = field("Currency Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") where(Open = const(true));
                column(PostingDate_VendLedgEntry; "Posting Date")
                {
                }
                column(DocumentNo_VendLedgEntry; "Document No.")
                {
                }
                column(Description_VendLedgEntry; Description)
                {
                }
                column(DueDate_VendLedgEntry; "Due Date")
                {
                }
                column(OverDueMonths; OverDueMonths)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(RemainingAmount_VendLedgEntry; "Remaining Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrencyCode_VendLedgEntry; "Currency Code")
                {
                }
                column(RemainingAmtLCY_VendLedgEntry; "Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(Counter; Counter)
                {
                    AutoFormatType = 1;
                }
                column(EntryNo_VendLedgEntry; "Entry No.")
                {
                }
                column(VendorNo_VendLedgEntry; "Vendor No.")
                {
                }
                column(GlobalDim2Code_VendLedgEntry; "Global Dimension 2 Code")
                {
                }
                column(GlobalDim1Code_VendLedgEntry; "Global Dimension 1 Code")
                {
                }
                column(DateFilter_VendLedgEntry; "Date Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Due Date" = 0D then
                        "Due Date" := "Posting Date";
                    OverDueMonths :=
                      (Date2DMY(EndDate, 3) - Date2DMY("Due Date", 3)) * 12 +
                      Date2DMY(EndDate, 2) - Date2DMY("Due Date", 2);
                    if Date2DMY(EndDate, 1) < Date2DMY("Due Date", 1) then
                        OverDueMonths := OverDueMonths - 1;

                    CurrencyTotalBuffer.UpdateTotal(
                      "Currency Code", "Remaining Amount", "Remaining Amt. (LCY)", Counter);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Due Date", 0D, EndDate);
                    SetRange("Date Filter", 0D, EndDate);
                    Counter := 0;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(CurrTotalBufferTotAmt; CurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrTotalBufferCurrCode; CurrencyTotalBuffer."Currency Code")
                {
                }
                column(VendorName; Vendor.Name)
                {
                }
                column(CurrTotalBufferTotAmtLCY; CurrencyTotalBuffer."Total Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(VLERemainingAmtLCY; "Vendor Ledger Entry"."Remaining Amt. (LCY)")
                {
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := CurrencyTotalBuffer.FindSet()
                    else
                        OK := CurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();
                    CurrencyTotalBuffer2.UpdateTotal(
                      CurrencyTotalBuffer."Currency Code",
                      CurrencyTotalBuffer."Total Amount",
                      CurrencyTotalBuffer."Total Amount (LCY)", Counter1);
                end;

                trigger OnPostDataItem()
                begin
                    CurrencyTotalBuffer.DeleteAll();
                end;
            }
        }
        dataitem(Integer2; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CurrTotalBuffer2CurrCode; CurrencyTotalBuffer2."Currency Code")
            {
            }
            column(CurrTotalBuffer2TotAmt; CurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                AutoFormatType = 1;
            }
            column(CurrTotalBuffer2TotAmtLCY; CurrencyTotalBuffer2."Total Amount (LCY)")
            {
                AutoFormatType = 1;
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := CurrencyTotalBuffer2.FindSet()
                else
                    OK := CurrencyTotalBuffer2.Next() <> 0;
                if not OK then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                CurrencyTotalBuffer2.DeleteAll();
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
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if EndDate = 0D then
                EndDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        VendFilter := Vendor.GetFilters();
    end;

    var
        Text1140000: Label 'As of %1';
        CurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        CurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        VendFilter: Text;
        OverDueMonths: Integer;
        OK: Boolean;
        Counter: Integer;
        Counter1: Integer;
        VendDetailedAgingCaptionLbl: Label 'Vendor Detailed Aging';
        CurrReportPageNoCaptionLbl: Label 'Page';
        DueDateCaptionLbl: Label 'Due Date';
        OverDueMonthsCaptionLbl: Label 'Months Due';
        TotalCaptionLbl: Label 'Total';

    protected var
        EndDate: Date;
}

