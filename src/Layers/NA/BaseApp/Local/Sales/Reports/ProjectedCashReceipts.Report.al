// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10057 "Projected Cash Receipts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/ProjectedCashReceipts.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Projected Cash Receipts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code", Blocked;
            column(Projected_Cash_Receipts_; 'Projected Cash Receipts')
            {
            }
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
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(PAGENO_TakeAllDiscounts; TakeAllDiscounts)
            {
            }
            column(PAGENO_NotTakeAllDiscounts; not TakeAllDiscounts)
            {
            }
            column(PAGENO_FilterString; FilterString <> '')
            {
            }
            column(Customer_TABLECAPTION__________FilterString; Customer.TableCaption + ': ' + FilterString)
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
            column(PrintDetail; PrintDetail)
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
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(GrandTotalAmountDue_1_; GrandTotalAmountDue[1])
            {
            }
            column(GrandTotalAmountDue_2_; GrandTotalAmountDue[2])
            {
            }
            column(GrandTotalAmountDue_3_; GrandTotalAmountDue[3])
            {
            }
            column(GrandTotalAmountDue_4_; GrandTotalAmountDue[4])
            {
            }
            column(GrandTotalAmountDue_5_; GrandTotalAmountDue[5])
            {
            }
            column(GrandTotalAmountToPrint; GrandTotalAmountToPrint)
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
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
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(Customer_NameCaption; FieldCaption(Name))
            {
            }
            column(AmountToPrintCaption; AmountToPrintCaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(Discount_DateCaption; Discount_DateCaptionLbl)
            {
            }
            column(BeforeCaption_Control32; BeforeCaption_Control32Lbl)
            {
            }
            column(AfterCaption_Control33; AfterCaption_Control33Lbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(Due_DateCaption; Due_DateCaptionLbl)
            {
            }
            column(AmountToPrint_Control72Caption; AmountToPrint_Control72CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; Cust__Ledger_Entry__Document_No__CaptionLbl)
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
            column(Control55Caption; CaptionClassTranslate('101,0,' + Text006))
            {
            }
            dataitem(CustCurrency; "Integer")
            {
                DataItemTableView = sorting(Number);
                PrintOnlyIfDetail = true;
                column(Transactions_using_____TempCurrency_Code__________TempCurrency_Description; 'Transactions using ' + TempCurrency.Code + ': ' + TempCurrency.Description)
                {
                }
                column(SkipCurrencyTotal; SkipCurrencyTotal)
                {
                }
                column(CustTotalLabel; CustTotalLabel)
                {
                }
                column(CustTotalAmountDue_1_; CustTotalAmountDue[1])
                {
                }
                column(CustTotalAmountDue_2_; CustTotalAmountDue[2])
                {
                }
                column(CustTotalAmountDue_3_; CustTotalAmountDue[3])
                {
                }
                column(CustTotalAmountDue_4_; CustTotalAmountDue[4])
                {
                }
                column(CustTotalAmountDue_5_; CustTotalAmountDue[5])
                {
                }
                column(CustTotalAmountToPrint; CustTotalAmountToPrint)
                {
                }
                column(CustTotal_Label; CustTotalLabel)
                {
                }
                column(CustTotalAmountDue_1__Control83; CustTotalAmountDue[1])
                {
                }
                column(CustTotalAmountDue_2__Control84; CustTotalAmountDue[2])
                {
                }
                column(CustTotalAmountDue_3__Control85; CustTotalAmountDue[3])
                {
                }
                column(CustTotalAmountDue_4__Control86; CustTotalAmountDue[4])
                {
                }
                column(CustTotalAmountDue_5__Control87; CustTotalAmountDue[5])
                {
                }
                column(CustTotalAmountToPrint_Control88; CustTotalAmountToPrint)
                {
                }
                column(CustCurrency_Number; Number)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date") where(Open = const(true), "On Hold" = const(''));
                    column(AmountDue_1_; AmountDue[1])
                    {
                    }
                    column(AmountDue_2_; AmountDue[2])
                    {
                    }
                    column(AmountDue_3_; AmountDue[3])
                    {
                    }
                    column(AmountDue_4_; AmountDue[4])
                    {
                    }
                    column(AmountDue_5_; AmountDue[5])
                    {
                    }
                    column(AmountToPrint; AmountToPrint)
                    {
                    }
                    column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(Cust__Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Due_Date__; "Due Date")
                    {
                    }
                    column(Pmt__Discount_Date__; "Pmt. Discount Date")
                    {
                    }
                    column(AmountDue_1__Control67; AmountDue[1])
                    {
                    }
                    column(AmountDue_2__Control68; AmountDue[2])
                    {
                    }
                    column(AmountDue_3__Control69; AmountDue[3])
                    {
                    }
                    column(AmountDue_4__Control70; AmountDue[4])
                    {
                    }
                    column(AmountDue_5__Control71; AmountDue[5])
                    {
                    }
                    column(AmountToPrint_Control72; AmountToPrint)
                    {
                    }
                    column(AmountDue_1__Control73; AmountDue[1])
                    {
                    }
                    column(AmountDue_2__Control74; AmountDue[2])
                    {
                    }
                    column(AmountDue_3__Control75; AmountDue[3])
                    {
                    }
                    column(AmountDue_4__Control76; AmountDue[4])
                    {
                    }
                    column(AmountDue_5__Control77; AmountDue[5])
                    {
                    }
                    column(AmountToPrint_Control78; AmountToPrint)
                    {
                    }
                    column(Total_for______TempCurrency_Description; 'Total for ' + TempCurrency.Description)
                    {
                    }
                    column(AmountDue_4__Control89; AmountDue[4])
                    {
                    }
                    column(AmountToPrint_Control90; AmountToPrint)
                    {
                    }
                    column(AmountDue_5__Control91; AmountDue[5])
                    {
                    }
                    column(AmountDue_3__Control92; AmountDue[3])
                    {
                    }
                    column(AmountDue_2__Control93; AmountDue[2])
                    {
                    }
                    column(AmountDue_1__Control94; AmountDue[1])
                    {
                    }
                    column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Customer_No_; "Customer No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Cust__Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
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
                        CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                        if TakeAllDiscounts and
                           ("Remaining Pmt. Disc. Possible" > 0) and
                           ("Pmt. Discount Date" >= BeginProjectionDate)
                        then begin
                            DateToSelectColumn := "Pmt. Discount Date";
                            "AmountToPrint($)" := "Remaining Amt. (LCY)"
                              - ("Remaining Pmt. Disc. Possible"
                                 * "Remaining Amt. (LCY)"
                                 / "Remaining Amount");
                            AmountToPrint := "Remaining Amount" - "Remaining Pmt. Disc. Possible";
                        end else begin
                            DateToSelectColumn := "Due Date";
                            "AmountToPrint($)" := "Remaining Amt. (LCY)";
                            AmountToPrint := "Remaining Amount";
                        end;

                        if not PrintAmountsInLocal or (Customer."Currency Code" = '') then
                            AmountToPrintCust := "AmountToPrint($)"
                        else
                            if "Currency Code" = Customer."Currency Code" then
                                AmountToPrintCust := AmountToPrint
                            else
                                AmountToPrintCust :=
                                  Round(
                                    CurrExchRate.ExchangeAmtFCYToFCY(
                                      DateToSelectColumn,
                                      "Currency Code",
                                      Customer."Currency Code",
                                      AmountToPrint),
                                    Currency."Amount Rounding Precision");

                        i := 0;
                        while DateToSelectColumn >= PeriodStartingDate[i + 1] do
                            i := i + 1;

                        AmountDue[i] := AmountToPrint;
                        CustTotalAmountDue[i] := CustTotalAmountDue[i] + AmountToPrintCust;
                        CustTotalAmountToPrint := CustTotalAmountToPrint + AmountToPrintCust;
                        GrandTotalAmountDue[i] := GrandTotalAmountDue[i] + "AmountToPrint($)";
                        GrandTotalAmountToPrint := GrandTotalAmountToPrint + "AmountToPrint($)";
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
                    CustTotalLabel := 'Total for ' + Customer.TableCaption + ' ' + Customer."No." + ' (';
                    if PrintAmountsInLocal and (Customer."Currency Code" <> '') then
                        CustTotalLabel := CustTotalLabel + Customer."Currency Code"
                    else
                        CustTotalLabel := CustTotalLabel + GLSetup."LCY Code";
                    CustTotalLabel := CustTotalLabel + ')';
                    if TempCurrency.Count > 0 then
                        if Number = 1 then
                            TempCurrency.Find('-')
                        else
                            TempCurrency.Next();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempCurrency.Count);
                    case TempCurrency.Count of
                        0:
                            begin
                                SetRange(Number, 1);
                                SkipCurrencyTotal := true;
                            end;
                        1:
                            begin
                                TempCurrency.Find('-');
                                if PrintAmountsInLocal then
                                    SkipCurrencyTotal := (TempCurrency.Code = Customer."Currency Code")
                                else
                                    SkipCurrencyTotal := (TempCurrency.Code = '');
                            end;
                        else
                            SkipCurrencyTotal := false;
                    end;

                    Clear(CustTotalAmountDue);
                    CustTotalAmountToPrint := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Currency.FindSet() then begin
                    if PrintDetail then
                        SubTitle := Text002
                    else
                        SubTitle := Text003;
                    TempCurrency.DeleteAll();
                    CustLedgEntry2.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                    CustLedgEntry2.SetRange("Customer No.", Customer."No.");
                    CustLedgEntry2.SetRange(Open, true);
                    CustLedgEntry2.SetFilter("On Hold", '');
                    CustLedgEntry2.SetFilter("Currency Code", '=%1', '');
                    if CustLedgEntry2.FindFirst() then begin
                        TempCurrency.Init();
                        TempCurrency.Code := '';
                        TempCurrency.Description := GLSetup."LCY Code";
                        TempCurrency.Insert();
                    end;
                    repeat
                        CustLedgEntry2.SetRange("Currency Code", Currency.Code);
                        if CustLedgEntry2.FindFirst() then begin
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
                    field(PrintTotalsInCustomersCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Totals in Customer''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if totals are printed in the customer''s currency. Clear the check box to print all totals in US dollars.';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';
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
        FilterString := Customer.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        FilterString: Text;
        SubTitle: Text[88];
        CustTotalLabel: Text[50];
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
        AmountToPrintCust: Decimal;
        "AmountToPrint($)": Decimal;
        CustTotalAmountToPrint: Decimal;
        GrandTotalAmountToPrint: Decimal;
        AmountDue: array[5] of Decimal;
        CustTotalAmountDue: array[5] of Decimal;
        GrandTotalAmountDue: array[5] of Decimal;
        Text001: Label 'You cannot choose to print customer totals in customer currency unless you can use Multiple Currencies';
        Text002: Label '(Detail)';
        Text003: Label '(Summary)';
        Text004: Label 'Currency: %1';
        Text005: Label 'Customer totals are in the customer''s currency (report totals are in %1)';
        Text006: Label 'Report Totals (%1)';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Assumes_that_all_available_early_payment_discounts_are_taken_CaptionLbl: Label 'Assumes that all available early payment discounts are taken.';
        Assumes_that_invoices_are_not_paid_early_to_take_payment_discounts_CaptionLbl: Label 'Assumes that invoices are not paid early to take payment discounts.';
        Invoices_which_are_on_hold_are_not_included_CaptionLbl: Label 'Invoices which are on hold are not included.';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        Customer__No__CaptionLbl: Label 'Customer';
        AmountToPrintCaptionLbl: Label 'Balance';
        DocumentCaptionLbl: Label 'Document';
        Discount_DateCaptionLbl: Label 'Discount Date';
        BeforeCaption_Control32Lbl: Label 'Before';
        AfterCaption_Control33Lbl: Label 'After';
        TypeCaptionLbl: Label 'Type';
        Due_DateCaptionLbl: Label 'Due Date';
        AmountToPrint_Control72CaptionLbl: Label 'Balance';
        Cust__Ledger_Entry__Document_No__CaptionLbl: Label 'Number';
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
                exit('101,1,' + Text004);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(Text004, Currency.Description));
        end;
        exit('');
    end;
}

