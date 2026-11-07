// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 10095 "Outstanding Purch. Order Aging"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/OutstandingPurchOrderAging.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Outstanding Purch. Order Aging';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group", "Currency Code";
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
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
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
            column(PeriodStartingDate_1__Control18; PeriodStartingDate[1])
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
            column(PeriodStartingDate_4__1_Control22; PeriodStartingDate[4] - 1)
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
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Outstanding_Purchase_Order_AgingCaption; Outstanding_Purchase_Order_AgingCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Control10Caption; CaptionClassTranslate('101,1,' + Text004))
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
            column(Control39Caption; CaptionClassTranslate('101,0,' + Text005))
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Buy-from Vendor No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(Purchase_Line__Document_No__; "Document No.")
                {
                }
                column(PreviousDocNo; PreviousDocNo)
                {
                }
                column(Purchase_Line__No__; "No.")
                {
                }
                column(Purchase_Line_Description; Description)
                {
                }
                column(DetailOutstanding_1_; DetailOutstanding[1])
                {
                }
                column(DetailOutstanding_2_; DetailOutstanding[2])
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
                column(PrintDetail; PrintDetail)
                {
                }
                column(Vendor__No___Control51; Vendor."No.")
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
                column(PeriodOutstanding_1__Control59; PeriodOutstanding[1])
                {
                }
                column(PeriodOutstanding_2__Control60; PeriodOutstanding[2])
                {
                }
                column(PeriodOutstanding_3__Control61; PeriodOutstanding[3])
                {
                }
                column(PeriodOutstanding_4__Control62; PeriodOutstanding[4])
                {
                }
                column(PeriodOutstanding_5__Control63; PeriodOutstanding[5])
                {
                }
                column(TotalOutstanding_Control64; TotalOutstanding)
                {
                }
                column(Purchase_Line_Document_Type; "Document Type")
                {
                }
                column(Purchase_Line_Line_No_; "Line No.")
                {
                }
                column(Purchase_Line_Buy_from_Vendor_No_; "Buy-from Vendor No.")
                {
                }
                column(Purchase_Line_Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code")
                {
                }
                column(Purchase_Line_Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code")
                {
                }
                column(Order_No_Caption; Order_No_CaptionLbl)
                {
                }
                column(Vendor_TotalsCaption; Vendor_TotalsCaptionLbl)
                {
                }
                column(Vendor_TotalsCaption_Control65; Vendor_TotalsCaption_Control65Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(DetailOutstanding);
                    PeriodNo := 1;
                    while "Expected Receipt Date" >= PeriodStartingDate[PeriodNo] do
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
                        if Vendor."Currency Code" = '' then
                            OutstandingExclTax := "OutstandingExclTax$"
                        else
                            if Vendor."Currency Code" <> "Currency Code" then
                                OutstandingExclTax :=
                                  Round(
                                    CurrExchRate.ExchangeAmtFCYToFCY(
                                      PeriodStartingDate[1],
                                      "Currency Code",
                                      Vendor."Currency Code",
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
                    Clear(PeriodOutstanding);
                    TotalOutstanding := 0;
                end;
            }

            trigger OnAfterGetRecord()
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
                    field(PrintAmountsInLocal; PrintAmountsInLocal)
                    {
                        Caption = 'Print Amounts in Vendor''s Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies that you want to print amounts in the vendor''s currency. If this field is not selected, the totals will print in U.S. dollars.';
                    }
                    field("PeriodStartingDate[1]"; PeriodStartingDate[1])
                    {
                        Caption = 'Begin Aging On';
                        ToolTip = 'Specifies the date from which to begin aging the vendor orders. The default is the current date.';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies that you want to see all of the order information listed. If this field is not selected, only summary information will print for each vendor.';
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
        for i := 1 to 3 do
            PeriodStartingDate[i + 1] := CalcDate('<1M>', PeriodStartingDate[i]);
        PeriodStartingDate[5] := 99991231D;
        CompanyInformation.Get();
        GLSetup.Get();
        FilterString := Vendor.GetFilters();
    end;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        FilterString: Text;
        Subtitle: Text[126];
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
        Text004: Label 'Amounts are in the vendor''s local currency (report totals are in %1).';
        Text005: Label 'Report Totals (%1)';
        Outstanding_Purchase_Order_AgingCaptionLbl: Label 'Outstanding Purchase Order Aging';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        BeforeCaptionLbl: Label 'Before';
        AfterCaptionLbl: Label 'After';
        Vendor__No__CaptionLbl: Label 'Vendor';
        Name_DescriptionCaptionLbl: Label 'Name/Description';
        OutstandingExclTaxCaptionLbl: Label 'Total';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Order_No_CaptionLbl: Label 'Order No:';
        Vendor_TotalsCaptionLbl: Label 'Vendor Totals';
        Vendor_TotalsCaption_Control65Lbl: Label 'Vendor Totals';

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

