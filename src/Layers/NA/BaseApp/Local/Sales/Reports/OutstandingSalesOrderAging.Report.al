// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 10055 "Outstanding Sales Order Aging"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/OutstandingSalesOrderAging.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Outstanding Sales Order Aging';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Code";
            column(Outstanding_Sales_Order_Aging_; 'Outstanding Sales Order Aging')
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
            column(Subtitle; Subtitle)
            {
            }
            column(PrintAmountsInLocal; PrintAmountsInLocal)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(PreviousDocNo; PreviousDocNo)
            {
            }
            column(PrintDetail; PrintDetail)
            {
            }
            column(LastDocNo; LastDocNo)
            {
            }
            column(Customer_TABLECAPTION__________FilterString; Customer.TableCaption + ': ' + FilterString)
            {
            }
            column(PeriodStartingDate_1_; PeriodStartingDate[1])
            {
            }
            column(PeriodStartingDate_2_; PeriodStartingDate[2])
            {
            }
            column(PeriodStartingDate_3_; PeriodStartingDate[3])
            {
            }
            column(PeriodStartingDate_1__Control17; PeriodStartingDate[1])
            {
            }
            column(PeriodStartingDate_2__1; PeriodStartingDate[2] - 1)
            {
            }
            column(PeriodStartingDate_3__1; PeriodStartingDate[3] - 1)
            {
            }
            column(PeriodStartingDate_4__1; PeriodStartingDate[4] - 1)
            {
            }
            column(PeriodStartingDate_4__1_Control21; PeriodStartingDate[4] - 1)
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
            column(PeriodOutstanding___1_; "PeriodOutstanding$"[1])
            {
            }
            column(PeriodOutstanding___2_; "PeriodOutstanding$"[2])
            {
            }
            column(PeriodOutstanding___3_; "PeriodOutstanding$"[3])
            {
            }
            column(PeriodOutstanding___4_; "PeriodOutstanding$"[4])
            {
            }
            column(PeriodOutstanding___5_; "PeriodOutstanding$"[5])
            {
            }
            column(TotalOutstanding__; "TotalOutstanding$")
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
            column(Control9Caption; CaptionClassTranslate('101,1,' + Text004))
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
            column(Name_DescriptionCaption; Name_DescriptionCaptionLbl)
            {
            }
            column(OutstandingExclTaxCaption; OutstandingExclTaxCaptionLbl)
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
            column(Control38Caption; CaptionClassTranslate('101,0,' + Text005))
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Bill-to Customer No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", "Bill-to Customer No.") where("Document Type" = const(Order));
                column(Sales_Line__Document_No__; "Document No.")
                {
                }
                column(Sales_Line__No__; "No.")
                {
                }
                column(Sales_Line_Description; Description)
                {
                }
                column(DetailOutstanding_1_; DetailOutstanding[1])
                {
                }
                column(DetailOutstanding_3_; DetailOutstanding[3])
                {
                }
                column(DetailOutstanding_4_; DetailOutstanding[4])
                {
                }
                column(DetailOutstanding_5_; DetailOutstanding[5])
                {
                }
                column(OutstandingExclTax; OutstandingExclTax)
                {
                }
                column(DetailOutstanding_2_; DetailOutstanding[2])
                {
                }
                column(Customer__No___Control50; Customer."No.")
                {
                }
                column(PeriodOutstanding_1_; PeriodOutstanding[1])
                {
                }
                column(PeriodOutstanding_2_; PeriodOutstanding[2])
                {
                }
                column(PeriodOutstanding_3_; PeriodOutstanding[3])
                {
                }
                column(PeriodOutstanding_4_; PeriodOutstanding[4])
                {
                }
                column(PeriodOutstanding_5_; PeriodOutstanding[5])
                {
                }
                column(TotalOutstanding; TotalOutstanding)
                {
                }
                column(PeriodOutstanding_1__Control58; PeriodOutstanding[1])
                {
                }
                column(PeriodOutstanding_2__Control59; PeriodOutstanding[2])
                {
                }
                column(PeriodOutstanding_3__Control60; PeriodOutstanding[3])
                {
                }
                column(PeriodOutstanding_4__Control61; PeriodOutstanding[4])
                {
                }
                column(PeriodOutstanding_5__Control62; PeriodOutstanding[5])
                {
                }
                column(TotalOutstanding_Control63; TotalOutstanding)
                {
                }
                column(Sales_Line_Document_Type; "Document Type")
                {
                }
                column(Sales_Line_Line_No_; "Line No.")
                {
                }
                column(Sales_Line_Bill_to_Customer_No_; "Bill-to Customer No.")
                {
                }
                column(Sales_Line_Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code")
                {
                }
                column(Sales_Line_Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code")
                {
                }
                column(Order_No_Caption; Order_No_CaptionLbl)
                {
                }
                column(Customer_TotalsCaption; Customer_TotalsCaptionLbl)
                {
                }
                column(Customer_TotalsCaption_Control64; Customer_TotalsCaption_Control64Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PreviousDocNo := LastDocNo;
                    LastDocNo := "Document No.";

                    Clear(DetailOutstanding);
                    PeriodNo := 1;
                    while "Shipment Date" >= PeriodStartingDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    OutstandingExclTax := Round("Line Amount" * "Outstanding Quantity" / Quantity);
                    if "Currency Code" = '' then
                        "OutstandingExclTax$" := OutstandingExclTax
                    else
                        "OutstandingExclTax$" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                              PeriodStartingDate[1],
                              "Currency Code",
                              '',
                              OutstandingExclTax));
                    if PrintAmountsInLocal then begin
                        if Customer."Currency Code" = '' then
                            OutstandingExclTax := "OutstandingExclTax$"
                        else
                            if Customer."Currency Code" <> "Currency Code" then
                                OutstandingExclTax :=
                                  Round(
                                    CurrExchRate.ExchangeAmtFCYToFCY(
                                      PeriodStartingDate[1],
                                      "Currency Code",
                                      Customer."Currency Code",
                                      OutstandingExclTax),
                                    Currency."Amount Rounding Precision");
                    end else
                        OutstandingExclTax := "OutstandingExclTax$";

                    PeriodOutstanding[PeriodNo] := PeriodOutstanding[PeriodNo] + OutstandingExclTax;
                    TotalOutstanding := TotalOutstanding + OutstandingExclTax;

                    DetailOutstanding[PeriodNo] := OutstandingExclTax;
                    "PeriodOutstanding$"[PeriodNo] := "PeriodOutstanding$"[PeriodNo] + "OutstandingExclTax$";
                    "TotalOutstanding$" := "TotalOutstanding$" + "OutstandingExclTax$";
                end;

                trigger OnPreDataItem()
                begin
                    LastDocNo := "Document No.";

                    Clear(PeriodOutstanding);
                    TotalOutstanding := 0;
                    SetFilter("Outstanding Quantity", '<>0');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GetCurrencyRecord(Currency, "Currency Code");
            end;

            trigger OnPreDataItem()
            begin
                if PrintDetail then
                    Subtitle := Text002
                else
                    Subtitle := Text003;
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
                    field(PrintAmountsInCustCurrency; PrintAmountsInLocal)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print Amounts in Customer''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if amounts are printed in the customer''s currency. Clear the check box to print all amounts in US dollars.';
                    }
                    field("PeriodStartingDate[1]"; PeriodStartingDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Begin Aging On';
                        ToolTip = 'Specifies the date from which to begin aging the vendor orders. The default is today''s date.';
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
            if PeriodStartingDate[1] = 0D then
                PeriodStartingDate[1] := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Customer.GetFilters();
        for i := 1 to 3 do
            PeriodStartingDate[i + 1] := CalcDate('<1M>', PeriodStartingDate[i]);
        PeriodStartingDate[5] := 99991231D;
    end;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        FilterString: Text;
        Subtitle: Text[88];
        PreviousDocNo: Code[20];
        PeriodStartingDate: array[5] of Date;
        OutstandingExclTax: Decimal;
        "OutstandingExclTax$": Decimal;
        DetailOutstanding: array[5] of Decimal;
        "PeriodOutstanding$": array[5] of Decimal;
        "TotalOutstanding$": Decimal;
        PeriodOutstanding: array[5] of Decimal;
        TotalOutstanding: Decimal;
        PrintAmountsInLocal: Boolean;
        PrintDetail: Boolean;
        i: Integer;
        PeriodNo: Integer;
        CompanyInformation: Record "Company Information";
        Text001: Label 'Currency: %1';
        Text002: Label '(Detail)';
        Text003: Label '(Summary)';
        Text004: Label 'Amounts are in the customer''s local currency (report totals are in %1).';
        Text005: Label 'Report Total (%1)';
        LastDocNo: Code[20];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        Customer__No__CaptionLbl: Label 'Customer';
        Name_DescriptionCaptionLbl: Label 'Name/Description';
        OutstandingExclTaxCaptionLbl: Label 'Total';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Order_No_CaptionLbl: Label 'Order No:';
        Customer_TotalsCaptionLbl: Label 'Customer Totals';
        Customer_TotalsCaption_Control64Lbl: Label 'Customer Totals';

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
                exit('101,1,' + Text001);

            GetCurrencyRecord(Currency, CurrencyCode);
            exit(StrSubstNo(Text001, Currency.Description));
        end;
        exit('');
    end;
}

