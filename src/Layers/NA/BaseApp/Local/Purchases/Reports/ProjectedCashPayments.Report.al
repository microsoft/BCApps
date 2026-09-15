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

report 10098 "Projected Cash Payments"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/ProjectedCashPayments.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Projected Cash Payments';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code", Blocked;
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
            column(SubTitle; SubTitle)
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(Text003; Text003Lbl)
            {
            }
            column(Text004; Text004Lbl)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(TakeAllDiscounts; TakeAllDiscounts)
            {
            }
            column(UseExternalDocNo; UseExternalDocNo)
            {
            }
            column(Document_Number_is______Vendor_Ledger_Entry__FIELDCAPTION__External_Document_No___; 'Document Number is ' + "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(PeriodStartingDate_2_; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3_; PeriodStartingDate[3])
            {
            }
            column(PeriodStartingDate_4_; PeriodStartingDate[4])
            {
            }
            column(PeriodStartingDate_2__Control19; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3____1; PeriodStartingDate[3] - 1)
            {
            }
            column(PeriodStartingDate_4____1; PeriodStartingDate[4] - 1)
            {
            }
            column(PeriodStartingDate_5____1; PeriodStartingDate[5] - 1)
            {
            }
            column(PeriodStartingDate_5____1_Control23; PeriodStartingDate[5] - 1)
            {
            }
            column(PeriodStartingDate_2__Control27; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3__Control28; PeriodStartingDate[3])
            {
            }
            column(PeriodStartingDate_4__Control29; PeriodStartingDate[4])
            {
            }
            column(PeriodStartingDate_2__Control34; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3____1_Control35; PeriodStartingDate[3] - 1)
            {
            }
            column(PeriodStartingDate_4____1_Control36; PeriodStartingDate[4] - 1)
            {
            }
            column(PeriodStartingDate_5____1_Control37; PeriodStartingDate[5] - 1)
            {
            }
            column(PeriodStartingDate_5____1_Control38; PeriodStartingDate[5] - 1)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(Vendor_Contact; Contact)
            {
            }
            column(GrandTotalAmountDue_1_; -GrandTotalAmountDue[1])
            {
            }
            column(GrandTotalAmountDue_2_; -GrandTotalAmountDue[2])
            {
            }
            column(GrandTotalAmountDue_3_; -GrandTotalAmountDue[3])
            {
            }
            column(GrandTotalAmountDue_4_; -GrandTotalAmountDue[4])
            {
            }
            column(GrandTotalAmountDue_5_; -GrandTotalAmountDue[5])
            {
            }
            column(GrandTotalAmountToPrint; -GrandTotalAmountToPrint)
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Projected_Cash_PaymentsCaption; Projected_Cash_PaymentsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Control9Caption; CaptionClassTranslate('101,1,' + Text005))
            {
            }
            column(Assumes_that_all_available_early_payment_discounts_are_taken_Caption; Assumes_that_all_available_early_payment_discounts_are_taken_CaptionLbl)
            {
            }
            column(Assumes_that_invoices_are_not_paid_early_to_take_payment_discounts_Caption; Assumes_that_invoices_are_not_paid_early_to_take_payment_discounts_CaptionLbl)
            {
            }
            column(Invoices_which_are_on_hold_are_not_included_Caption; Invoices_which_are_on_hold_are_not_included_CaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Pmt__Discount_Date_Caption; Vendor_Ledger_Entry__Pmt__Discount_Date_CaptionLbl)
            {
            }
            column(BeforeCaption_Control32; BeforeCaption_Control32Lbl)
            {
            }
            column(AfterCaption_Control33; AfterCaption_Control33Lbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; "Vendor Ledger Entry".FieldCaption("Due Date"))
            {
            }
            column(BalanceCaption_Control41; BalanceCaption_Control41Lbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }
            column(Control1020000Caption; CaptionClassTranslate(GetCurrencyCaptionCode("Currency Code")))
            {
            }
            column(Control115Caption; CaptionClassTranslate('101,0,' + Text006))
            {
            }
            dataitem(VendCurrency; "Integer")
            {
                DataItemTableView = sorting(Number);
                PrintOnlyIfDetail = true;
                column(Transactions_using_____TempCurrency_Code__________TempCurrency_Description; 'Transactions using ' + TempCurrency.Code + ': ' + TempCurrency.Description)
                {
                }
                column(SkipCurrencyTotal; SkipCurrencyTotal)
                {
                }
                column(TempCurrency_Code; TempCurrency.Code)
                {
                }
                column(VendTotalLabel; VendTotalLabel)
                {
                }
                column(VendTotalAmountDue_1_; -VendTotalAmountDue[1])
                {
                }
                column(VendTotalAmountDue_2_; -VendTotalAmountDue[2])
                {
                }
                column(VendTotalAmountDue_3_; -VendTotalAmountDue[3])
                {
                }
                column(VendTotalAmountDue_4_; -VendTotalAmountDue[4])
                {
                }
                column(VendTotalAmountDue_5_; -VendTotalAmountDue[5])
                {
                }
                column(VendTotalAmountToPrint; -VendTotalAmountToPrint)
                {
                }
                column(VendTotalAmountDue_1__Control103; -VendTotalAmountDue[1])
                {
                }
                column(VendTotalAmountDue_2__Control104; -VendTotalAmountDue[2])
                {
                }
                column(VendTotalAmountDue_3__Control105; -VendTotalAmountDue[3])
                {
                }
                column(VendTotalAmountDue_4__Control106; -VendTotalAmountDue[4])
                {
                }
                column(VendTotalAmountDue_5__Control107; -VendTotalAmountDue[5])
                {
                }
                column(VendTotalAmountToPrint_Control108; -VendTotalAmountToPrint)
                {
                }
                column(VendCurrency_Number; Number)
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Vendor;
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true), "On Hold" = const(''));
                    column(AmountDue_1_; -AmountDue[1])
                    {
                    }
                    column(AmountDue_2_; -AmountDue[2])
                    {
                    }
                    column(AmountDue_3_; -AmountDue[3])
                    {
                    }
                    column(AmountDue_4_; -AmountDue[4])
                    {
                    }
                    column(AmountDue_5_; -AmountDue[5])
                    {
                    }
                    column(AmountToPrint; -AmountToPrint)
                    {
                    }
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
                    column(AmountDue_1__Control67; -AmountDue[1])
                    {
                    }
                    column(AmountDue_2__Control68; -AmountDue[2])
                    {
                    }
                    column(AmountDue_3__Control69; -AmountDue[3])
                    {
                    }
                    column(AmountDue_4__Control70; -AmountDue[4])
                    {
                    }
                    column(AmountDue_5__Control71; -AmountDue[5])
                    {
                    }
                    column(AmountToPrint_Control72; -AmountToPrint)
                    {
                    }
                    column(AmountDue_1__Control73; -AmountDue[1])
                    {
                    }
                    column(AmountDue_2__Control74; -AmountDue[2])
                    {
                    }
                    column(AmountDue_3__Control75; -AmountDue[3])
                    {
                    }
                    column(AmountDue_4__Control76; -AmountDue[4])
                    {
                    }
                    column(AmountDue_5__Control77; -AmountDue[5])
                    {
                    }
                    column(AmountToPrint_Control78; -AmountToPrint)
                    {
                    }
                    column(Total_for______TempCurrency_Description; 'Total for ' + TempCurrency.Description)
                    {
                    }
                    column(AmountDue_1__Control5; -AmountDue[1])
                    {
                    }
                    column(AmountDue_2__Control6; -AmountDue[2])
                    {
                    }
                    column(AmountDue_3__Control7; -AmountDue[3])
                    {
                    }
                    column(AmountDue_4__Control8; -AmountDue[4])
                    {
                    }
                    column(AmountDue_5__Control88; -AmountDue[5])
                    {
                    }
                    column(AmountToPrint_Control95; -AmountToPrint)
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
                    column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
                    {
                    }
                    column(Balance_to_Carry_ForwardCaption; Balance_to_Carry_ForwardCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        for i := 1 to 5 do
                            AmountDue[i] := 0;

                        CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                        if TakeAllDiscounts and
                           ("Original Pmt. Disc. Possible" < 0) and
                           ("Pmt. Discount Date" >= BeginProjectionDate)
                        then begin
                            DateToSelectColumn := "Pmt. Discount Date";
                            "AmountToPrint($)" := "Remaining Amt. (LCY)"
                              - ("Original Pmt. Disc. Possible"
                                 * "Remaining Amt. (LCY)"
                                 / "Remaining Amount");
                            AmountToPrint := "Remaining Amount" - "Original Pmt. Disc. Possible";
                        end else begin
                            DateToSelectColumn := "Due Date";
                            "AmountToPrint($)" := "Remaining Amt. (LCY)";
                            AmountToPrint := "Remaining Amount";
                        end;

                        if not PrintAmountsInLocal or (Vendor."Currency Code" = '') then
                            AmountToPrintVend := "AmountToPrint($)"
                        else
                            if "Currency Code" = Vendor."Currency Code" then
                                AmountToPrintVend := AmountToPrint
                            else
                                AmountToPrintVend :=
                                  Round(
                                    CurrExchRate.ExchangeAmtFCYToFCY(
                                      DateToSelectColumn,
                                      "Currency Code",
                                      Vendor."Currency Code",
                                      AmountToPrint),
                                    Currency."Amount Rounding Precision");

                        i := 0;
                        while DateToSelectColumn >= PeriodStartingDate[i + 1] do
                            i := i + 1;

                        AmountDue[i] := AmountToPrint;
                        VendTotalAmountDue[i] := VendTotalAmountDue[i] + AmountToPrintVend;
                        VendTotalAmountToPrint := VendTotalAmountToPrint + AmountToPrintVend;
                        GrandTotalAmountDue[i] := GrandTotalAmountDue[i] + "AmountToPrint($)";
                        GrandTotalAmountToPrint := GrandTotalAmountToPrint + "AmountToPrint($)";

                        if UseExternalDocNo then
                            DocNo := "External Document No."
                        else
                            DocNo := "Document No.";
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(AmountToPrint);
                        Clear(AmountDue);
                        if Currency.ReadPermission then
                            SetRange("Currency Code", TempCurrency.Code);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Currency.ReadPermission then
                        if Number = 1 then
                            TempCurrency.Find('-')
                        else
                            TempCurrency.Next();
                    VendTotalLabel := 'Total for ' + Vendor.TableCaption + ' ' + Vendor."No." + ' (';
                    if PrintAmountsInLocal and (Vendor."Currency Code" <> '') then
                        VendTotalLabel := VendTotalLabel + Vendor."Currency Code"
                    else
                        VendTotalLabel := VendTotalLabel + GLSetup."LCY Code";
                    VendTotalLabel := VendTotalLabel + ')';
                end;

                trigger OnPreDataItem()
                begin
                    if Currency.ReadPermission then begin
                        SetRange(Number, 1, TempCurrency.Count);
                        case TempCurrency.Count of
                            0:
                                CurrReport.Break();
                            1:
                                begin
                                    TempCurrency.Find('-');
                                    if PrintAmountsInLocal then
                                        SkipCurrencyTotal := (TempCurrency.Code = Vendor."Currency Code")
                                    else
                                        SkipCurrencyTotal := (TempCurrency.Code = '');
                                end;
                            else
                                SkipCurrencyTotal := false;
                        end;
                    end else begin
                        SetRange(Number, 1);
                        SkipCurrencyTotal := true;
                    end;

                    Clear(VendTotalAmountDue);
                    VendTotalAmountToPrint := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Currency.ReadPermission then begin
                    TempCurrency.DeleteAll();
                    VendLedgEntry2.SetCurrentKey("Vendor No.", Open, Positive, "Due Date", "Currency Code");
                    VendLedgEntry2.SetRange("Vendor No.", Vendor."No.");
                    VendLedgEntry2.SetRange(Open, true);
                    VendLedgEntry2.SetFilter("On Hold", '');
                    VendLedgEntry2.SetFilter("Currency Code", '=%1', '');
                    if VendLedgEntry2.FindFirst() then begin
                        TempCurrency.Init();
                        TempCurrency.Code := '';
                        TempCurrency.Description := GLSetup."LCY Code";
                        TempCurrency.Insert();
                    end;
                    if Currency.Find('-') then
                        repeat
                            VendLedgEntry2.SetRange("Currency Code", Currency.Code);
                            if VendLedgEntry2.FindFirst() then begin
                                TempCurrency.Init();
                                TempCurrency.Code := Currency.Code;
                                TempCurrency.Description := Currency.Description;
                                TempCurrency.Insert();
                            end;
                        until Currency.Next() = 0;
                end;

                GetCurrencyRecord(Currency, "Currency Code");
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
                    field(BeginProjectionDate; BeginProjectionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Begin Projections on';
                        ToolTip = 'Specifies, in the MMDDYY format, when projections begin. The default is today''s date.';
                    }
                    field(PeriodCalculation; PeriodCalculation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Period';
                        ToolTip = 'Specifies the time increment by which to project the customer balances. For example: 30D = 30 days, 1M = one month, which is different from 30 days.';
                    }
                    field(TakeAllDiscounts; TakeAllDiscounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Assume all Payment Discounts are Taken';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print amounts and dates that assume that invoices are paid early in order to take advantage of all available payment discounts. Payment discounts that lapse before the Begin Projections on date are not available. If you do not select this field, this report will print amounts and dates that assume that invoices are not to be paid until their due date.';
                    }
                    field(PrintTotalsInVendorsCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Totals in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if totals are printed in the customer''s currency. Clear the check box to print all totals in US dollars.';
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
            if Format(PeriodCalculation) = '' then
                Evaluate(PeriodCalculation, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if PrintAmountsInLocal and not Currency.ReadPermission then
            Error(Text001);
        if BeginProjectionDate = 0D then
            BeginProjectionDate := WorkDate();
        if Format(PeriodCalculation) = '' then
            Evaluate(PeriodCalculation, '<1M>');
        PeriodStartingDate[1] := 0D;
        PeriodStartingDate[2] := BeginProjectionDate;
        for i := 3 to 5 do
            PeriodStartingDate[i] := CalcDate(PeriodCalculation, PeriodStartingDate[i - 1]);
        PeriodStartingDate[6] := 99991231D;
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Vendor.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        FilterString: Text;
        SubTitle: Text[88];
        VendTotalLabel: Text[50];
        PeriodCalculation: DateFormula;
        PeriodStartingDate: array[6] of Date;
        BeginProjectionDate: Date;
        DateToSelectColumn: Date;
        TakeAllDiscounts: Boolean;
        PrintAmountsInLocal: Boolean;
        PrintDetail: Boolean;
        SkipCurrencyTotal: Boolean;
        i: Integer;
        AmountToPrint: Decimal;
        AmountToPrintVend: Decimal;
        "AmountToPrint($)": Decimal;
        VendTotalAmountToPrint: Decimal;
        GrandTotalAmountToPrint: Decimal;
        AmountDue: array[5] of Decimal;
        VendTotalAmountDue: array[5] of Decimal;
        GrandTotalAmountDue: array[5] of Decimal;
        UseExternalDocNo: Boolean;
        DocNo: Code[50];
        Text001: Label 'You cannot choose to print vendor totals in vendor currency unless you can use Multiple Currencies';
        Text002: Label 'Currency: %1';
        Text005: Label 'Vendor totals are in the vendor''s currency (report totals are in %1).';
        Text006: Label 'Report Totals (%1)';
        Text003Lbl: Label '(Detail)';
        Text004Lbl: Label '(Summary)';
        Projected_Cash_PaymentsCaptionLbl: Label 'Projected Cash Payments';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Assumes_that_all_available_early_payment_discounts_are_taken_CaptionLbl: Label 'Assumes that all available early payment discounts are taken.';
        Assumes_that_invoices_are_not_paid_early_to_take_payment_discounts_CaptionLbl: Label 'Assumes that invoices are not paid early to take payment discounts.';
        Invoices_which_are_on_hold_are_not_included_CaptionLbl: Label 'Invoices which are on hold are not included.';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        Vendor__No__CaptionLbl: Label 'Vendor';
        BalanceCaptionLbl: Label 'Balance';
        DocumentCaptionLbl: Label 'Document';
        Vendor_Ledger_Entry__Pmt__Discount_Date_CaptionLbl: Label 'Discount Date';
        BeforeCaption_Control32Lbl: Label 'Before';
        AfterCaption_Control33Lbl: Label 'After';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Type';
        BalanceCaption_Control41Lbl: Label 'Balance';
        DocNoCaptionLbl: Label 'Number';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Balance_to_Carry_ForwardCaptionLbl: Label 'Balance to Carry Forward';

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
                exit('101,1,' + Text002);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(Text002, Currency.Description));
        end;
        exit('');
    end;
}

