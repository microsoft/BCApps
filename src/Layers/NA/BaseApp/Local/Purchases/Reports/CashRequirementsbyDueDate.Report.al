// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 10088 "Cash Requirements by Due Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/CashRequirementsbyDueDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Requirements by Due Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting(Open, "Due Date") where(Open = const(true), "On Hold" = const(''));
            RequestFilterFields = "Vendor No.", "Due Date", "Purchaser Code", "Document Type";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Subtitle; Subtitle)
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_; "Due Date")
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
            {
            }
            column(Vendor_Ledger_Entry__Pmt__Discount_Date_; "Pmt. Discount Date")
            {
            }
            column(Remaining_Amt___LCY__; -"Remaining Amt. (LCY)")
            {
            }
            column(PaymentDiscToPrint; -PaymentDiscToPrint)
            {
            }
            column(NetRequired; -NetRequired)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date__Control43; "Due Date")
            {
            }
            column(Remaining_Amt___LCY___Control44; -"Remaining Amt. (LCY)")
            {
            }
            column(PaymentDiscToPrint_Control45; -PaymentDiscToPrint)
            {
            }
            column(NetRequired_Control46; -NetRequired)
            {
            }
            column(RequiredToDate; -RequiredToDate)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date__Control49; "Due Date")
            {
            }
            column(Remaining_Amt___LCY___Control50; -"Remaining Amt. (LCY)")
            {
            }
            column(PaymentDiscToPrint_Control51; -PaymentDiscToPrint)
            {
            }
            column(NetRequired_Control52; -NetRequired)
            {
            }
            column(RequiredToDate_Control53; -RequiredToDate)
            {
            }
            column(Remaining_Amt___LCY___Control54; -"Remaining Amt. (LCY)")
            {
            }
            column(PaymentDiscToPrint_Control55; -PaymentDiscToPrint)
            {
            }
            column(NetRequired_Control56; -NetRequired)
            {
            }
            column(Remaining_Amt___LCY___Control58; -"Remaining Amt. (LCY)")
            {
            }
            column(PaymentDiscToPrint_Control59; -PaymentDiscToPrint)
            {
            }
            column(NetRequired_Control60; -NetRequired)
            {
            }
            column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
            {
            }
            column(Cash_Requirements_by_Due_DateCaption; Cash_Requirements_by_Due_DateCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date__Control49Caption; FieldCaption("Due Date"))
            {
            }
            column(Remaining_Amt___LCY___Control50Caption; Remaining_Amt___LCY___Control50CaptionLbl)
            {
            }
            column(PaymentDiscToPrint_Control51Caption; PaymentDiscToPrint_Control51CaptionLbl)
            {
            }
            column(NetRequired_Control52Caption; NetRequired_Control52CaptionLbl)
            {
            }
            column(RequiredToDate_Control53Caption; RequiredToDate_Control53CaptionLbl)
            {
            }
            column(Due_DateCaption; Due_DateCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; FieldCaption("Posting Date"))
            {
            }
            column(Discount_DateCaption; Discount_DateCaptionLbl)
            {
            }
            column(Amount_DueCaption; Amount_DueCaptionLbl)
            {
            }
            column(PaymentDiscToPrintCaption; PaymentDiscToPrintCaptionLbl)
            {
            }
            column(NetRequiredCaption; NetRequiredCaptionLbl)
            {
            }
            column(Cash_Req__to_DateCaption; Cash_Req__to_DateCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Date_TotalCaption; Date_TotalCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if BeginProjectionDate > "Pmt. Discount Date" then
                    PaymentDiscToPrint := 0
                else
                    if "Currency Code" = '' then
                        PaymentDiscToPrint := "Original Pmt. Disc. Possible"
                    else
                        if "Remaining Amount" <> 0 then
                            PaymentDiscToPrint := "Original Pmt. Disc. Possible" * "Remaining Amt. (LCY)" / "Remaining Amount"
                        else
                            PaymentDiscToPrint := 0;   // should never happen, since trx is open anyway

                if not Vendor.Get("Vendor No.") then
                    Clear(Vendor);
                NetRequired := "Remaining Amt. (LCY)" - PaymentDiscToPrint;

                if UseExternalDocNo then
                    DocNo := "External Document No."
                else
                    DocNo := "Document No.";

                RequiredToDate += NetRequired;
            end;

            trigger OnPreDataItem()
            begin
                Clear(PaymentDiscToPrint);
                Clear(NetRequired);
                RequiredToDate := 0;
                SetRange("Date Filter", 0D, BeginProjectionDate);
                if PrintDetail then
                    Subtitle := '(' + Format(Text000) + ' '
                else
                    Subtitle := '(' + Format(Text001) + ' ';
                Subtitle := Subtitle + Format(BeginProjectionDate, 0, 4) + ')';
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
                    field(ForPaymentOn; BeginProjectionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'For Payment On';
                        ToolTip = 'Specifies the due date of the cash requirement. Based on the specified due date, calculations will be performed based on the amount due and the due date of the vendor ledger entry.';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';
                    }
                    field(UseExternalDocNo; UseExternalDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Doc. No.';
                        ToolTip = 'Specifies if you want to print the vendor''s document numbers, such as the invoice number, on all transactions. Clear this check box to print only internal document numbers.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if BeginProjectionDate = 0D then
                BeginProjectionDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FilterString := "Vendor Ledger Entry".GetFilters();
    end;

    var
        FilterString: Text;
        Subtitle: Text[88];
        Vendor: Record Vendor;
        NetRequired: Decimal;
        RequiredToDate: Decimal;
        PaymentDiscToPrint: Decimal;
        BeginProjectionDate: Date;
        PrintDetail: Boolean;
        CompanyInformation: Record "Company Information";
        UseExternalDocNo: Boolean;
        DocNo: Code[35];
        Text000: Label 'Detail for payments as of';
        Text001: Label 'Summary for payments as of';
        Cash_Requirements_by_Due_DateCaptionLbl: Label 'Cash Requirements by Due Date';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Remaining_Amt___LCY___Control50CaptionLbl: Label 'Amount Due';
        PaymentDiscToPrint_Control51CaptionLbl: Label 'Discount Available';
        NetRequired_Control52CaptionLbl: Label 'Net Cash Required';
        RequiredToDate_Control53CaptionLbl: Label 'Cash Required to Date';
        Due_DateCaptionLbl: Label 'Due Date';
        VendorCaptionLbl: Label 'Vendor';
        NameCaptionLbl: Label 'Name';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        Discount_DateCaptionLbl: Label 'Discount Date';
        Amount_DueCaptionLbl: Label 'Amount Due';
        PaymentDiscToPrintCaptionLbl: Label 'Discount Available';
        NetRequiredCaptionLbl: Label 'Net Cash Required';
        Cash_Req__to_DateCaptionLbl: Label 'Cash Req. to Date';
        DocNoCaptionLbl: Label 'Number';
        DocumentCaptionLbl: Label 'Document';
        Date_TotalCaptionLbl: Label 'Date Total';
        Report_TotalCaptionLbl: Label 'Report Total';
        TotalCaptionLbl: Label 'Total';
}

