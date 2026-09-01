// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10086 "Cash Application"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/CashApplication.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Application';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Purchaser Code", Priority, "Payment Method Code";
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
            column(PaymentDateString; PaymentDateString)
            {
            }
            column(LastDueDate; LastDueDate)
            {
            }
            column(TakeDiscounts; TakeDiscounts)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Invoices_are_included_which_are_due_through_____FORMAT_LastDueDate_______; 'Invoices are included which are due through ' + Format(LastDueDate) + '.')
            {
            }
            column(Invoices_which_are_not_yet_due_may_be_included; 'Invoices which are not yet due may be included so that all available payment discounts can be taken up to ' + Format(DiscountDate) + '.')
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(BlockedDescription; BlockedDescription)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(Vendor_Contact; Contact)
            {
            }
            column(GTotAmountDue; GTotAmountDue)
            {
            }
            column(GTotDiscountToTake; GTotDiscountToTake)
            {
            }
            column(GTotAmountToPay; GTotAmountToPay)
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Cash_Application_WorksheetCaption; Cash_Application_WorksheetCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(No_invoices_which_are_due_are_included_Caption; No_invoices_which_are_due_are_included_CaptionLbl)
            {
            }
            column(Control17Caption; CaptionClassTranslate('101,1,' + Text005))
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; "Vendor Ledger Entry".FieldCaption("Due Date"))
            {
            }
            column(Vendor_Ledger_Entry__Pmt__Discount_Date_Caption; Vendor_Ledger_Entry__Pmt__Discount_Date_CaptionLbl)
            {
            }
            column(InvoiceAmountCaption; InvoiceAmountCaptionLbl)
            {
            }
            column(AmountDueCaption; AmountDueCaptionLbl)
            {
            }
            column(DiscountToTakeCaption; DiscountToTakeCaptionLbl)
            {
            }
            column(AmountToPayCaption; AmountToPayCaptionLbl)
            {
            }
            column(Actual_Amount_to_PayCaption; Actual_Amount_to_PayCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_Caption; Vendor_Ledger_Entry__Currency_Code_CaptionLbl)
            {
            }
            column(Vendor__Phone_No__Caption; Vendor__Phone_No__CaptionLbl)
            {
            }
            column(Vendor_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Control1020000Caption; CaptionClassTranslate(GetCurrencyCaptionCode("Currency Code")))
            {
            }
            column(Control44Caption; CaptionClassTranslate('101,0,' + Text006))
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true), Positive = const(false), "On Hold" = const(''));
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(DocNo; DocNo)
                {
                }
                column(Vendor_Ledger_Entry__Due_Date_; "Due Date")
                {
                }
                column(Vendor_Ledger_Entry__Pmt__Discount_Date_; "Pmt. Discount Date")
                {
                }
                column(InvoiceAmount; InvoiceAmount)
                {
                }
                column(AmountDue; AmountDue)
                {
                }
                column(DiscountToTake; DiscountToTake)
                {
                }
                column(AmountToPay; AmountToPay)
                {
                }
                column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Vendor_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    AnyDetails := true;
                    SetRange("Date Filter", PaymentDate, DiscountDate);
                    CalcAmounts("Vendor Ledger Entry");
                    if UseExternalDocNo then
                        DocNo := "External Document No."
                    else
                        DocNo := "Document No.";
                end;

                trigger OnPreDataItem()
                begin
                    // Round One:  Payment Discounts
                    if not TakeDiscounts then
                        CurrReport.Break();
                    SetRange("Pmt. Discount Date", PaymentDate, DiscountDate);
                    SetFilter("Original Pmt. Disc. Possible", '<0');
                end;
            }
            dataitem("Vendor Ledger Entry 2"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true), Positive = const(false));
                column(Vendor_Ledger_Entry_2__Document_Type_; "Document Type")
                {
                }
                column(DocNo_Control54; DocNo)
                {
                }
                column(Vendor_Ledger_Entry_2__Due_Date_; "Due Date")
                {
                }
                column(Vendor_Ledger_Entry_2__Pmt__Discount_Date_; "Pmt. Discount Date")
                {
                }
                column(InvoiceAmount_Control57; InvoiceAmount)
                {
                }
                column(AmountDue_Control58; AmountDue)
                {
                }
                column(DiscountToTake_Control59; DiscountToTake)
                {
                }
                column(AmountToPay_Control60; AmountToPay)
                {
                }
                column(Vendor_Ledger_Entry_2__Currency_Code_; "Currency Code")
                {
                }
                column(Vendor_Ledger_Entry_2_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Ledger_Entry_2_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry_2_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Vendor_Ledger_Entry_2_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    /* check and see if we already took care of this one above */
                    if TakeDiscounts and // if it is relevant
                       ("Pmt. Discount Date" <= DiscountDate) and
                       ("Pmt. Discount Date" >= PaymentDate) and
                       ("Original Pmt. Disc. Possible" < 0)
                    then
                        CurrReport.Skip();
                    AnyDetails := true;
                    CalcAmounts("Vendor Ledger Entry 2");

                    if UseExternalDocNo then
                        DocNo := "External Document No."
                    else
                        DocNo := "Document No.";

                end;

                trigger OnPreDataItem()
                begin
                    // Round Two:  Items Due at or before Last Due Date
                    SetRange("Pmt. Discount Date");        // remove old filters
                    SetRange("Original Pmt. Disc. Possible");
                    if LastDueDate = 0D then                  // do not include invoices
                        CurrReport.Break(); // just because they are

                    SetRange("Due Date", 0D, LastDueDate);  // add new filter
                end;
            }
            dataitem("Vendor Totals"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Vendor__No___Control61; Vendor."No.")
                {
                }
                column(VTotAmountDue; VTotAmountDue)
                {
                }
                column(VTotDiscountToTake; VTotDiscountToTake)
                {
                }
                column(VTotAmountToPay; VTotAmountToPay)
                {
                }
                column(Vendor_Totals_Number; Number)
                {
                }
                column(Control1020001Caption; CaptionClassTranslate(GetCurrencyCaptionCode(Vendor."Currency Code")))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not AnyDetails then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AnyDetails := false;
                VTotAmountDue := 0;
                VTotDiscountToTake := 0;
                VTotAmountToPay := 0;
                if "Privacy Blocked" then
                    BlockedDescription := PrivacyBlockedTxt
                else
                    BlockedDescription := '';
                if Blocked <> Blocked::" " then
                    BlockedDescription := StrSubstNo(Text002, Blocked)
                else
                    BlockedDescription := '';
                if PrintAmountsInLocal then
                    GetCurrencyRecord(Currency, "Currency Code");
                if PaymentDate = 0D then
                    PaymentDate := WorkDate();
                if TakeDiscounts and (DiscountDate < PaymentDate) then
                    DiscountDate := PaymentDate;
                PaymentDateString := '(For Payment on ' + Format(PaymentDate, 0, 4) + ')';
            end;

            trigger OnPreDataItem()
            begin
                if (LastDueDate = 0D) and not TakeDiscounts then
                    Error(Text000
                      + Text001);
                GTotAmountDue := 0;
                GTotDiscountToTake := 0;
                GTotAmountToPay := 0;
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
                    field(PaymentDate; PaymentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Date';
                        ToolTip = 'Specifies the date when the payment was made.';
                    }
                    field(LastDueDate; LastDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Due Date to Pay';
                        ToolTip = 'Specifies the payment due date.';
                    }
                    field(TakePaymentDiscounts; TakeDiscounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Take Payment Discounts';
                        ToolTip = 'Specifies if you want to print payment amounts and dates that assume payments will be eligible for all available payment discounts.';
                    }
                    field(LastDiscDateToTake; DiscountDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Disc. Date to Take';
                        ToolTip = 'Specifies a payment discount due date. Payment discounts that lapse before the selected date will not be included in the report.';
                    }
                    field(PrintAmountsInLocal; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the vendor''s currency. Clear the check box to print all amounts in US dollars.';
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

        trigger OnClosePage()
        begin
            if not TakeDiscounts then
                DiscountDate := 0D
            else
                if DiscountDate < PaymentDate then
                    DiscountDate := PaymentDate;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Vendor.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        FilterString: Text;
        PaymentDate: Date;
        LastDueDate: Date;
        TakeDiscounts: Boolean;
        DiscountDate: Date;
        PrintAmountsInLocal: Boolean;
        PaymentDateString: Text[40];
        InvoiceAmount: Decimal;
        AmountDue: Decimal;
        DiscountToTake: Decimal;
        AmountToPay: Decimal;
        "AmountDue($)": Decimal;
        "DiscountToTake($)": Decimal;
        "AmountToPay($)": Decimal;
        VTotAmountDue: Decimal;
        VTotDiscountToTake: Decimal;
        VTotAmountToPay: Decimal;
        GTotAmountDue: Decimal;
        GTotDiscountToTake: Decimal;
        GTotAmountToPay: Decimal;
        BlockedDescription: Text[80];
        AnyDetails: Boolean;
        UseExternalDocNo: Boolean;
        DocNo: Code[50];
        Text000: Label 'You must select either to Take Discounts or enter a ';
        Text001: Label 'Last Due Date, or both if you want.';
        Text002: Label '*** This vendor is blocked for %1 processing ***';
        PrivacyBlockedTxt: Label '*** This vendor is blocked for privacy ***.';
        Text003: Label 'Amounts are in %1';
        Text005: Label 'Amounts are in the vendor''s local currency (report total is in %1).';
        Text006: Label 'Report Total (%1)';
        Cash_Application_WorksheetCaptionLbl: Label 'Cash Application Worksheet';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        No_invoices_which_are_due_are_included_CaptionLbl: Label 'No invoices which are due are included.';
        DocumentCaptionLbl: Label 'Document';
        Vendor__No__CaptionLbl: Label 'Vendor';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        DocNoCaptionLbl: Label 'Number';
        Vendor_Ledger_Entry__Pmt__Discount_Date_CaptionLbl: Label 'Discount Date';
        InvoiceAmountCaptionLbl: Label 'Orig. Invoice Amount';
        AmountDueCaptionLbl: Label 'Amount Due';
        DiscountToTakeCaptionLbl: Label 'Discount Available';
        AmountToPayCaptionLbl: Label 'Suggested Amount to Pay';
        Actual_Amount_to_PayCaptionLbl: Label 'Actual Amount to Pay';
        Vendor_Ledger_Entry__Currency_Code_CaptionLbl: Label 'Orig. Inv. Currency';
        Vendor__Phone_No__CaptionLbl: Label 'Phone';

    procedure CalcAmounts(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Date Filter", 0D, LastDueDate);
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount", "Remaining Amt. (LCY)");
        InvoiceAmount := -VendorLedgerEntry.Amount;
        "AmountDue($)" := -VendorLedgerEntry."Remaining Amt. (LCY)";

        if (VendorLedgerEntry."Original Pmt. Disc. Possible" < 0) and
           (VendorLedgerEntry."Pmt. Discount Date" >= PaymentDate)
        then
            DiscountToTake := -VendorLedgerEntry."Original Pmt. Disc. Possible"
        else
            DiscountToTake := 0;

        if Vendor."Currency Code" <> '' then begin
            "DiscountToTake($)" := DiscountToTake * VendorLedgerEntry."Remaining Amt. (LCY)" / VendorLedgerEntry."Remaining Amount";
            if PrintAmountsInLocal then begin
                if VendorLedgerEntry."Currency Code" = Vendor."Currency Code" then
                    AmountDue := -VendorLedgerEntry."Remaining Amount"
                else begin
                    AmountDue :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToFCY(
                          PaymentDate,
                          VendorLedgerEntry."Currency Code",
                          Vendor."Currency Code",
                          -VendorLedgerEntry."Remaining Amount"),
                        Currency."Amount Rounding Precision");
                    DiscountToTake :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToFCY(
                          PaymentDate,
                          VendorLedgerEntry."Currency Code",
                          Vendor."Currency Code",
                          DiscountToTake),
                        Currency."Amount Rounding Precision");
                end;
            end else begin
                AmountDue := "AmountDue($)";
                DiscountToTake := "DiscountToTake($)";
            end;
        end else begin
            AmountDue := "AmountDue($)";
            "DiscountToTake($)" := DiscountToTake;
        end;

        if (Vendor.Blocked <> Vendor.Blocked::" ") or Vendor."Privacy Blocked" then begin
            AmountToPay := 0;
            "AmountToPay($)" := 0;
        end else begin
            AmountToPay := AmountDue - DiscountToTake;
            "AmountToPay($)" := "AmountDue($)" - "DiscountToTake($)";
        end;

        VTotAmountDue := VTotAmountDue + AmountDue;
        VTotDiscountToTake := VTotDiscountToTake + DiscountToTake;
        VTotAmountToPay := VTotAmountToPay + AmountToPay;
        GTotAmountDue := GTotAmountDue + "AmountDue($)";
        GTotDiscountToTake := GTotDiscountToTake + "DiscountToTake($)";
        GTotAmountToPay := GTotAmountToPay + "AmountToPay($)";
    end;

    local procedure GetCurrencyRecord(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.Description := GLSetup."LCY Code";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
        end else
            if Currency.Code <> CurrencyCode then
                Currency.Get(CurrencyCode);
    end;

    local procedure GetCurrencyCaptionCode(CurrencyCode: Code[10]): Text[80]
    begin
        if PrintAmountsInLocal then begin
            if CurrencyCode = '' then
                exit('101,1,' + Text003);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(Text003, Currency.Description));
        end;
        exit('');
    end;
}

