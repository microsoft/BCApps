// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Utilities;

report 3010801 "Quote Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/QuoteAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Quote Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ComapanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(UserID; UserId)
            {
            }
            column(WithDetails; WithDetails)
            {
            }
            column(PagePerSalesperson; PagePerSalesperson)
            {
            }
            column(Group; GroupNum)
            {
            }
            column(Code_SalespersonPurchaser; Code)
            {
            }
            column(Name_SalespersonPurchaser; Name)
            {
            }
            column(SalespersonPurchaserCaption; SalespersonPurchaserCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AllAmountsinLocalCurrencyCaption; AllAmountsinLocalCurrencyCaptionLbl)
            {
            }
            column(No_SalesHeadCaption; SalesHead.FieldCaption("No."))
            {
            }
            column(SellToCustomerCaption; SellToCustomerCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(ActualQuoteCaption; ActualQuoteCaptionLbl)
            {
            }
            column(ActualOrderCaption; ActualOrderCaptionLbl)
            {
            }
            column(CompletedOrderCaption; CompletedOrderCaptionLbl)
            {
            }
            column(NoOrderCaption; NoOrderCaptionLbl)
            {
            }
            column(OrderInCaption; OrderInCaptionLbl)
            {
            }
            column(VerCaption; VerCaptionLbl)
            {
            }
            column(DocType_ArchSalesHeadCaption; ArchSalesHead.FieldCaption("Document Type"))
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            dataitem(SalesHead; "Sales Header")
            {
                DataItemLink = "Salesperson Code" = field(Code);
                DataItemTableView = sorting("Salesperson Code", "Document Type") where("Document Type" = filter(Quote .. Order));
                column(No_SalesHead; "No.")
                {
                }
                column(SellToCustNo_SalesHead; "Sell-to Customer No.")
                {
                }
                column(Name_Customer; Customer.Name)
                {
                }
                column(DocDate_SalesHead; Format("Document Date"))
                {
                }
                column(ActQuote; ActQuote)
                {
                }
                column(ActOrder; ActOrder)
                {
                }
                column(DocType_SalesHead; "Document Type")
                {
                }
                column(SalespersonCode_SalesHead; "Salesperson Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ActQuote := 0;
                    ActOrder := 0;
                    DocAmount := CalcHeaderAmount(DATABASE::"Sales Header");

                    if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                        DocAmount := CalcLCYAmount(DocAmount, "Currency Factor");

                    case "Document Type" of
                        "Document Type"::Quote:
                            begin
                                ActQuote := DocAmount;
                                TotalActQuote := TotalActQuote + ActQuote;
                                TotalActQuoteRTC := TotalActQuoteRTC + ActQuote;
                            end;

                        "Document Type"::Order:
                            begin
                                ActOrder := DocAmount;
                                TotalActOrder := TotalActOrder + ActOrder;
                                TotalActOrderRTC := TotalActOrderRTC + ActOrder;
                            end;
                    end;

                    if not Customer.Get("Sell-to Customer No.") then
                        Clear(Customer);
                end;
            }
            dataitem(ArchSalesHead; "Sales Header Archive")
            {
                DataItemLink = "Salesperson Code" = field(Code);
                DataItemTableView = sorting("Document Type", "No.", "Quote Status") where("Quote Status" = filter(<> " "));
                column(CompletedOrder; CompletedOrder)
                {
                }
                column(NoOrder; NoOrder)
                {
                }
                column(No_ArchSalesHead; "No.")
                {
                }
                column(SellToCustNo_ArchSalesHead; "Sell-to Customer No.")
                {
                }
                column(Name_Customer1; Customer.Name)
                {
                }
                column(VersionNo_ArchSalesHead; "Version No.")
                {
                }
                column(DocType_ArchSalesHead; "Document Type")
                {
                }
                column(DocNoOccurrence_ArchSalesHead; "Doc. No. Occurrence")
                {
                }
                column(SalespersonCode_ArchSalesHead; "Salesperson Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    BecameOrder := 0;
                    CompletedOrder := 0;
                    NoOrder := 0;
                    DocAmount := CalcHeaderAmount(DATABASE::"Sales Header Archive");

                    if ("Currency Code" <> '') and ("Currency Factor" <> 0) then
                        DocAmount := CalcLCYAmount(DocAmount, "Currency Factor");

                    case "Quote Status" of
                        "Quote Status"::"Converted to Order":
                            begin
                                BecameOrder := DocAmount;
                                TotalBecameOrder := TotalBecameOrder + BecameOrder;
                            end;

                        "Quote Status"::"Posted Order":
                            begin
                                CompletedOrder := DocAmount;
                                TotalCompletedOrder := TotalCompletedOrder + CompletedOrder;
                            end;

                        "Quote Status"::Deleted:
                            begin
                                NoOrder := DocAmount;
                                TotalNoOrder := TotalNoOrder + NoOrder;
                            end;
                    end;

                    if not Customer.Get("Sell-to Customer No.") then
                        Clear(Customer);
                end;
            }
            dataitem(SalesPersonTotal; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Name_SalespersonPurchaser1; "Salesperson/Purchaser".Name)
                {
                }
                column(TotalActOrder; TotalActOrder)
                {
                }
                column(TotalActQuote; TotalActQuote)
                {
                }
                column(TotalCompletedOrder; TotalCompletedOrder)
                {
                }
                column(TotalNoOrder; TotalNoOrder)
                {
                }
                column(OrderPct; OrderPct)
                {
                }
                column(Code_SalespersonPurchaser1; "Salesperson/Purchaser".Code)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(SalesPersonTotal_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if (TotalActOrder + NewTotalCompletedOrderForRTC + NewTotalNoOrderForRTC) <> 0 then
                        OrderPct := (TotalActOrder + NewTotalCompletedOrderForRTC) /
                          (TotalActOrder + NewTotalCompletedOrderForRTC + NewTotalNoOrderForRTC) * 100;
                end;

                trigger OnPreDataItem()
                begin
                    if PagePerSalesperson then begin
                        NewTotalCompletedOrderForRTC := NewTotalCompletedOrderForRTC + TotalCompletedOrder;
                        NewTotalNoOrderForRTC := NewTotalNoOrderForRTC + TotalNoOrder;
                        GroupNum := GroupNum + 1;
                    end;
                    if (TotalActQuote = 0) and (TotalActOrder = 0) and
                       (TotalBecameOrder = 0) and (TotalCompletedOrder = 0) and
                       (TotalNoOrder = 0)
                    then
                        CurrReport.Break();
                end;
            }

            trigger OnPostDataItem()
            begin
                if NewSalesPerson then
                    Salesperson.Delete();
            end;

            trigger OnPreDataItem()
            begin
                Salesperson.Init();
                Salesperson.Code := '';
                Salesperson.Name := Text000;
                NewSalesPerson := Salesperson.Insert();

                Currency.InitRoundingPrecision();
                Clear(TotalActQuote);
                Clear(TotalActOrder);
                Clear(TotalBecameOrder);
                Clear(TotalCompletedOrder);
                Clear(TotalNoOrder);
            end;
        }
        dataitem(Total; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TotalActQuote1; TotalActQuote)
            {
            }
            column(TotalActOrder1; TotalActOrder)
            {
            }
            column(TotalCompletedOrder1; TotalCompletedOrder)
            {
            }
            column(TotalNoOrder1; TotalNoOrder)
            {
            }
            column(OrderPct1; OrderPct)
            {
            }
            column(NewTotalCompletedOrderForRTC; NewTotalCompletedOrderForRTC)
            {
            }
            column(NewTotalNoOrderForRTC; NewTotalNoOrderForRTC)
            {
            }
            column(Total_ReportCaption; TotalReportCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if (TotalActOrder + NewTotalCompletedOrderForRTC + NewTotalNoOrderForRTC) <> 0 then
                    OrderPct := (TotalActOrder + NewTotalCompletedOrderForRTC) /
                      (TotalActOrder + NewTotalCompletedOrderForRTC + NewTotalNoOrderForRTC) * 100;
            end;

            trigger OnPreDataItem()
            begin
                TotalActQuote := TotalActQuoteRTC;
                TotalActOrder := TotalActOrderRTC;
                if (TotalActQuote = 0) and (TotalActOrder = 0) and
                   (TotalBecameOrder = 0) and (TotalCompletedOrder = 0) and
                   (TotalNoOrder = 0)
                then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PagePerSalesperson; PagePerSalesperson)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New page per salesperson';
                        ToolTip = 'Specifies if you want to print a new page for each sales person.';
                    }
                    field(WithDetails; WithDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Details';
                        ToolTip = 'Specifies if the details of the quote will be printed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            WithDetails := true;
        end;
    }

    labels
    {
    }

    var
        Customer: Record Customer;
        Salesperson: Record "Salesperson/Purchaser";
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        CalcInvDisc: Codeunit "Sales-Calc. Discount";
        ActQuote: Decimal;
        ActOrder: Decimal;
        CompletedOrder: Decimal;
        NoOrder: Decimal;
        BecameOrder: Decimal;
        TotalActQuote: Decimal;
        TotalActOrder: Decimal;
        TotalCompletedOrder: Decimal;
        TotalNoOrder: Decimal;
        TotalBecameOrder: Decimal;
        OrderPct: Decimal;
        DocAmount: Decimal;
        PagePerSalesperson: Boolean;
        Text000: Label 'W/O Salesperson code';
        NewSalesPerson: Boolean;
        WithDetails: Boolean;
        TotalActQuoteRTC: Decimal;
        TotalActOrderRTC: Decimal;
        GroupNum: Decimal;
        NewTotalCompletedOrderForRTC: Decimal;
        NewTotalNoOrderForRTC: Decimal;
        SalespersonPurchaserCaptionLbl: Label 'Salesperson/Purchaser';
        PageNoCaptionLbl: Label 'Page';
        AllAmountsinLocalCurrencyCaptionLbl: Label 'All amounts in local currency';
        SellToCustomerCaptionLbl: Label 'Sell-to Customer';
        DateCaptionLbl: Label 'Date';
        ActualQuoteCaptionLbl: Label 'Actual Quote';
        ActualOrderCaptionLbl: Label 'Actual Order';
        CompletedOrderCaptionLbl: Label 'Completed Order';
        NoOrderCaptionLbl: Label 'No Order';
        OrderInCaptionLbl: Label 'Order in %';
        VerCaptionLbl: Label 'Ver.';
        CodeCaptionLbl: Label 'Code';
        TotalCaptionLbl: Label 'Total';
        TotalReportCaptionLbl: Label 'Total Report';

    [Scope('OnPrem')]
    procedure CalcHeaderAmount(_TableType: Integer) Result: Decimal
    var
        TmpSalesHeader: Record "Sales Header" temporary;
        TmpSalesLine: Record "Sales Line" temporary;
        TmpSalesLine2: Record "Sales Line" temporary;
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        SalesLine2: Record "Sales Line";
        ArchSalesLine2: Record "Sales Line Archive";
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcHeaderAmount(SalesHead, _TableType, Result, IsHandled, ArchSalesHead);
        if IsHandled then
            exit(Result);

        case _TableType of
            DATABASE::"Sales Header":
                begin

                    SalesLine2.SetRange("Document Type", SalesHead."Document Type");
                    SalesLine2.SetRange("Document No.", SalesHead."No.");
                    if SalesLine2.Find('-') then begin
                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then
                            CalcInvDisc.Run(SalesLine2);
                    end;

                    if SalesHead.Status = SalesHead.Status::Released then begin
                        SalesHead.CalcFields(Amount);
                        exit(SalesHead.Amount);
                    end;
                    TmpSalesHeader := SalesHead;

                    SalesLine2.SetRange(Type, SalesLine2.Type::"G/L Account", SalesLine2.Type::"Charge (Item)");
                    SalesLine2.SetRange("Quote Variant", SalesLine2."Quote Variant"::" ", SalesLine2."Quote Variant"::"Calculate only");

                    if SalesLine2.Find('-') then
                        repeat
                            TmpSalesLine := SalesLine2;
                            TmpSalesLine.Insert();
                        until SalesLine2.Next() = 0;
                end;
            DATABASE::"Sales Header Archive":
                begin
                    if ArchSalesHead.Status = ArchSalesHead.Status::Released then begin
                        ArchSalesHead.CalcFields(Amount);
                        exit(ArchSalesHead.Amount);
                    end;
                    TmpSalesHeader.TransferFields(ArchSalesHead);
                    ArchSalesLine2.SetRange("Document Type", ArchSalesHead."Document Type");
                    ArchSalesLine2.SetRange("Document No.", ArchSalesHead."No.");
                    ArchSalesLine2.SetRange("Doc. No. Occurrence", ArchSalesHead."Doc. No. Occurrence");
                    ArchSalesLine2.SetRange("Version No.", ArchSalesHead."Version No.");

                    ArchSalesLine2.SetRange(Type, SalesLine2.Type::"G/L Account", SalesLine2.Type::"Charge (Item)");
                    ArchSalesLine2.SetRange("Quote Variant", SalesLine2."Quote Variant"::" ", SalesLine2."Quote Variant"::"Calculate only");

                    if ArchSalesLine2.Find('-') then
                        repeat
                            TmpSalesLine.TransferFields(ArchSalesLine2);
                            TmpSalesLine.Insert();
                        until ArchSalesLine2.Next() = 0;
                end;
        end;

        if TmpSalesLine.Find('-') then begin
            TmpSalesHeader.Status := TmpSalesHeader.Status::Released;
            repeat
                TmpSalesLine2 := TmpSalesLine;
                TmpSalesLine2.Insert();
                TmpSalesLine2.SetSalesHeader(TmpSalesHeader);
                TmpSalesLine2.CalcVATAmountLines(0, TmpSalesHeader, TmpSalesLine2, TempVATAmountLine0);
                TmpSalesLine2.CalcVATAmountLines(1, TmpSalesHeader, TmpSalesLine2, TempVATAmountLine1);
                TmpSalesLine2.UpdateVATOnLines(0, TmpSalesHeader, TmpSalesLine2, TempVATAmountLine0);
                TmpSalesLine2.UpdateVATOnLines(1, TmpSalesHeader, TmpSalesLine2, TempVATAmountLine1);
                TotalAmount := TotalAmount + TmpSalesLine2.Amount;
            until TmpSalesLine.Next() = 0;
        end;
        exit(TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcLCYAmount(_FCAmount: Decimal; _Factor: Decimal): Decimal
    begin
        exit(Round(_FCAmount / _Factor, Currency."Amount Rounding Precision"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcHeaderAmount(SalesHeader: Record "Sales Header"; _TableType: Integer; var Result: Decimal; var IsHandled: Boolean; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;
}

