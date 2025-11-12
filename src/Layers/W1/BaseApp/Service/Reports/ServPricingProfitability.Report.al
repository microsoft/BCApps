// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;

report 6080 "Serv. Pricing Profitability"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServPricingProfitability.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Pricing Profitability';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Price Group"; "Service Price Group")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServPriceGrFilterCaption; TableCaption + ':' + ServPriceGrFilter)
            {
            }
            column(ServPriceGrpSetupCaption; "Serv. Price Group Setup".TableCaption + ':' + ServPriceGrSetupFilter)
            {
            }
            column(CustomerCaption; Customer.TableCaption + ':' + CustomerFilter)
            {
            }
            column(ServicePriceGroupCode; Code)
            {
            }
            column(ProfitAmt; ProfitAmt)
            {
            }
            column(Profit; ProfitPct)
            {
            }
            column(CostAmt; CostAmt)
            {
            }
            column(DiscountAmt; DiscountAmt)
            {
            }
            column(InvoiceAmt; InvoiceAmt)
            {
            }
            column(UsageAmt; UsageAmt)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ServicePricingProfitabilityCaption; ServicePricingProfitabilityCaptionLbl)
            {
            }
            column(ServicePriceGroupCodeCaption; ServicePriceGroupCodeCaptionLbl)
            {
            }
            column(TotalforGroupCaption; TotalforGroupCaptionLbl)
            {
            }
            dataitem("Serv. Price Group Setup"; "Serv. Price Group Setup")
            {
                DataItemLink = "Service Price Group Code" = field(Code);
                DataItemTableView = sorting("Service Price Group Code");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Adjustment Type", "Starting Date";
                column(AdjmtType_ServPriceGrpSetup; "Adjustment Type")
                {
                }
                column(Amt_ServPriceGroupSetup; Amount)
                {
                }
                column(AdjmtType_ServPriceGrpSetupCaption; FieldCaption("Adjustment Type"))
                {
                }
                column(Amt_ServPriceGroupSetupCaption; FieldCaption(Amount))
                {
                }
                column(ServPriceGrpCode_ServPriceGrpSetup; "Service Price Group Code")
                {
                }
                column(FaultAreaCode_ServPriceGrpSetup; "Fault Area Code")
                {
                }
                column(CustPriceGrpCode_ServPriceGrpSetup; "Cust. Price Group Code")
                {
                }
                column(CurrencyCode_ServPriceGrpSetup; "Currency Code")
                {
                }
                column(StarteDate_ServPriceGrpSetup; "Starting Date")
                {
                }
                column(CustNo_ServShpItemLineCaption; "Service Shipment Item Line".FieldCaption("Customer No."))
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(UsageAmountCaption; UsageAmountCaptionLbl)
                {
                }
                column(InvoiceAmountCaption; InvoiceAmountCaptionLbl)
                {
                }
                column(DiscountAmountCaption; DiscountAmountCaptionLbl)
                {
                }
                column(CostAmountCaption; CostAmountCaptionLbl)
                {
                }
                column(ProfitAmountCaption; ProfitAmountCaptionLbl)
                {
                }
                column(ProfitCaption; ProfitCaptionLbl)
                {
                }
                dataitem("Service Shipment Item Line"; "Service Shipment Item Line")
                {
                    DataItemLink = "Service Price Group Code" = field("Service Price Group Code");
                    DataItemTableView = sorting("Service Price Group Code", "Adjustment Type", "Base Amount to Adjust", "Customer No.");
                    RequestFilterFields = "Customer No.";
                    column(CustNo_ServShpItemLine; "Customer No.")
                    {
                    }
                    column(CustomerName; Customer.Name)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        UsageAmt := 0;
                        InvoiceAmt := 0;
                        DiscountAmt := 0;
                        CostAmt := 0;
                        ProfitPct := 0;
                        ProfitAmt := 0;

                        if not Customer.Get("Customer No.") then
                            Customer.Name := '';
                        SetRange("Customer No.", "Customer No.");
                        repeat
                            GetServShipmentHeader();
                            if NewHeader then begin
                                ServLedgerEntry.Reset();
                                ServLedgerEntry.SetCurrentKey(
                                  "Service Order No.",
                                  "Service Item No. (Serviced)",
                                  "Entry Type",
                                  "Moved from Prepaid Acc.",
                                  "Posting Date",
                                  Open,
                                  Type);
                                ServLedgerEntry.SetRange("Service Order No.", ServShipmentHeader."Order No.");
                                ServLedgerEntry.SetRange("Entry Type", ServLedgerEntry."Entry Type"::Usage);
                                ServLedgerEntry.SetRange("Posting Date", ServShipmentHeader."Posting Date");
                                ServLedgerEntry.CalcSums("Amount (LCY)");
                                UsageAmt += ServLedgerEntry."Amount (LCY)";
                            end;
                            ServInvHeader.Reset();
                            ServInvHeader.SetCurrentKey("Order No.");
                            ServInvHeader.SetRange("Order No.", ServShipmentHeader."Order No.");
                            if ServInvHeader.Find('-') then
                                repeat
                                    ServInvLine.Reset();
                                    ServInvLine.SetCurrentKey("Document No.", "Service Item Line No.", Type, "No.");
                                    ServInvLine.SetRange("Document No.", ServInvHeader."No.");
                                    ServInvLine.SetRange("Service Item Line No.", "Service Shipment Item Line"."Line No.");
                                    if ServInvLine.Find('-') then
                                        repeat
                                            CostAmt += Round(ServInvLine."Unit Cost (LCY)" * ServInvLine.Quantity, Currency."Amount Rounding Precision");
                                            InvoiceAmt += CurrExchRate.ExchangeAmtFCYToLCY(
                                                ServShipmentHeader."Posting Date",
                                                ServShipmentHeader."Currency Code",
                                                Round(ServInvLine."Unit Price" * ServInvLine.Quantity, Currency."Amount Rounding Precision"),
                                                ServShipmentHeader."Currency Factor");
                                            DiscountAmt += CurrExchRate.ExchangeAmtFCYToLCY(
                                                ServShipmentHeader."Posting Date",
                                                ServShipmentHeader."Currency Code",
                                                ServInvLine."Line Discount Amount",
                                                ServShipmentHeader."Currency Factor");
                                        until ServInvLine.Next() = 0;
                                until ServInvHeader.Next() = 0;

                        until Next() = 0;
                        SetRange("Customer No.");

                        ProfitAmt := InvoiceAmt - CostAmt;
                        if InvoiceAmt <> 0 then
                            ProfitPct := Round(ProfitAmt * 100 / InvoiceAmt, 0.00001)
                        else
                            ProfitPct := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(UsageAmt);
                        Clear(InvoiceAmt);
                        Clear(DiscountAmt);
                        Clear(CostAmt);
                        Clear(ProfitAmt);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    Clear(UsageAmt);
                    Clear(InvoiceAmt);
                    Clear(DiscountAmt);
                    Clear(CostAmt);
                    Clear(ProfitAmt);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(UsageAmt);
                Clear(InvoiceAmt);
                Clear(DiscountAmt);
                Clear(CostAmt);
                Clear(ProfitAmt);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Pricing Profitability';
        AboutText = 'Analyze profits from your service pricing.';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        Currency.InitRoundingPrecision();
        ServPriceGrFilter := "Service Price Group".GetFilters();
        ServPriceGrSetupFilter := "Serv. Price Group Setup".GetFilters();
        CustomerFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        ServShipmentHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServInvLine: Record "Service Invoice Line";
        ServLedgerEntry: Record "Service Ledger Entry";
        Currency: Record Currency;
        ServPriceGrFilter: Text;
        ServPriceGrSetupFilter: Text;
        CustomerFilter: Text;
        UsageAmt: Decimal;
        InvoiceAmt: Decimal;
        DiscountAmt: Decimal;
        CostAmt: Decimal;
        ProfitPct: Decimal;
        ProfitAmt: Decimal;
        NewHeader: Boolean;
        PageCaptionLbl: Label 'Page';
        ServicePricingProfitabilityCaptionLbl: Label 'Service Pricing Profitability';
        ServicePriceGroupCodeCaptionLbl: Label 'Service Price Group Code';
        TotalforGroupCaptionLbl: Label 'Total for Group';
        NameCaptionLbl: Label 'Name';
        UsageAmountCaptionLbl: Label 'Usage Amount';
        InvoiceAmountCaptionLbl: Label 'Invoice Amount';
        DiscountAmountCaptionLbl: Label 'Discount Amount';
        CostAmountCaptionLbl: Label 'Cost Amount';
        ProfitAmountCaptionLbl: Label 'Profit Amount';
        ProfitCaptionLbl: Label 'Profit %';
        TotalCaptionLbl: Label 'Total';

    local procedure GetServShipmentHeader()
    begin
        NewHeader := false;
        if ServShipmentHeader."No." <> "Service Shipment Item Line"."No." then begin
            ServShipmentHeader.Get("Service Shipment Item Line"."No.");
            NewHeader := true;
        end;
    end;
}

