// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using System.Utilities;

report 5910 "Service Profit (Serv. Orders)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceProfitServOrders.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Profit (Serv. Orders)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Shipment Header"; "Service Shipment Header")
        {
            DataItemTableView = sorting("Order No.");
            RequestFilterFields = "Order No.", "Posting Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TblCptnServShptHdrFilter; TableCaption + ': ' + ServShipmentHeaderFilter)
            {
            }
            column(ServShptHdrFilter; ServShipmentHeaderFilter)
            {
            }
            column(OrderNoDesc_ServShptHeader; "Order No." + ' ' + Description)
            {
            }
            column(CustNoName_ServShptHeader; "Customer No." + ' ' + Name)
            {
            }
            column(ShowDetail; ShowDetail)
            {
            }
            column(ServiceProfitServiceOrdersCaption; ServiceProfitServiceOrdersCaptionLbl)
            {
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(ServiceAmountLCYCaption; ServiceAmountLCYCaptionLbl)
            {
            }
            column(ContractDiscAmountLCYCaption; ContractDiscAmountLCYCaptionLbl)
            {
            }
            column(ServiceDiscAmountLCYCaption; ServiceDiscAmountLCYCaptionLbl)
            {
            }
            column(ServiceCostAmountLCYCaption; ServiceCostAmountLCYCaptionLbl)
            {
            }
            column(ProfitAmountLCYCaption; ProfitAmountLCYCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ServiceOrderCaption; ServiceOrderCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            dataitem("Service Ledger Entry"; "Service Ledger Entry")
            {
                DataItemLink = "Service Order No." = field("Order No.");
                DataItemTableView = sorting("Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type, "Service Contract No.") where("Entry Type" = filter(Sale | Consume), Open = const(false));
                column(TotalForServOrder; TotalForServOrderLbl)
                {
                }
                column(AmountLCY; -"Amount (LCY)")
                {
                }
                column(ContractDiscAmount; -"Contract Disc. Amount")
                {
                }
                column(DiscountAmount; -"Discount Amount")
                {
                }
                column(CostAmount; -"Cost Amount")
                {
                }
                column(ProfitAmount; ProfitAmount)
                {
                    AutoFormatType = 1;
                }
                column(NCAmountLCY; NCAmount_LCY)
                {
                }
                column(NCCostAmount; NCCostAmount)
                {
                }
                column(NCContractDiscAmount; NCContractDiscAmount)
                {
                }
                column(NCDiscountAmount; NCDiscountAmount)
                {
                }
                column(EntryNo_ServLedgEntry; "Entry No.")
                {
                }
                column(ServOrdNo_ServLedgEntry; "Service Order No.")
                {
                }
                column(Quantity; -Quantity)
                {
                }
                column(EntryType_ServLedgEntry; Type)
                {
                }
                column(EntryNo_ServLedgEntryNo; "No.")
                {
                }
                dataitem("Service Ledger Entry 2"; "Service Ledger Entry")
                {
                    DataItemLink = "Service Order No." = field("Service Order No."), Type = field(Type), "No." = field("No.");
                    DataItemTableView = sorting(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Prepaid) where("Entry Type" = filter(Sale | Consume), Open = const(false));
                    column(Description2_ServLedgEntry; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(No2_ServLedgEntry; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Type2_ServLedgEntry; Type)
                    {
                        IncludeCaption = true;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    NCAmount_LCY -= "Amount (LCY)";
                    NCContractDiscAmount -= "Contract Disc. Amount";
                    NCDiscountAmount -= "Discount Amount";
                    NCCostAmount -= "Cost Amount";
                    NCTotalAmountLCY -= "Amount (LCY)";
                    NCTotalContractDiscAmount -= "Contract Disc. Amount";
                    NCTotalDiscountAmount -= "Discount Amount";
                    NCTotalCostAmount -= "Cost Amount";
                    NCTotalProfitAmount += "Cost Amount" - "Amount (LCY)";
                end;

                trigger OnPreDataItem()
                begin
                    NCAmount_LCY := 0;
                    NCContractDiscAmount := 0;
                    NCDiscountAmount := 0;
                    NCCostAmount := 0;

                    SetCurrentKey(Type, "No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if ("Order No." = '') or ("Order No." = LastOrderNo) then
                    CurrReport.Skip();
                LastOrderNo := "Order No.";
                ServLedgerEntry.SetRange("Service Order No.", "Order No.");

                if not ServLedgerEntry.FindFirst() then
                    CurrReport.Skip();
            end;
        }
        dataitem(GrandTotal; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(NCTotalAmountLCY; NCTotalAmountLCY)
            {
            }
            column(Total; TotalLbl)
            {
            }
            column(TotalContractDiscAmount; TotalContractDiscAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalDiscountAmount; TotalDiscountAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalCostAmount; TotalCostAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalProfitAmount; TotalProfitAmount)
            {
                AutoFormatType = 1;
            }
            column(NCTotalDiscountAmount; NCTotalDiscountAmount)
            {
            }
            column(NCTotalContractDiscAmount; NCTotalContractDiscAmount)
            {
            }
            column(NCTotalCostAmount; NCTotalCostAmount)
            {
            }
            column(NCTotalProfitAmount; NCTotalProfitAmount)
            {
            }
            column(ShowGT; ShowGT)
            {
            }

            trigger OnPreDataItem()
            begin
                ShowGT := true;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Profit (Serv. Orders)';
        AboutText = 'Get an overview of profit for service orders.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowDetail; ShowDetail)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want the report to show details for the posted service shipments.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        // The label 'l' could not be exported.
    }

    trigger OnPreReport()
    begin
        ServShipmentHeaderFilter := "Service Shipment Header".GetFilters();
        TotalDiscountAmount := 0;
        TotalContractDiscAmount := 0;
        TotalCostAmount := 0;
        TotalProfitAmount := 0;
    end;

    var
        ServLedgerEntry: Record "Service Ledger Entry";
        TotalDiscountAmount: Decimal;
        TotalContractDiscAmount: Decimal;
        TotalCostAmount: Decimal;
        TotalProfitAmount: Decimal;
        ProfitAmount: Decimal;
        ServShipmentHeaderFilter: Text;
        ShowDetail: Boolean;
        LastOrderNo: Code[20];
        NCAmount_LCY: Decimal;
        NCCostAmount: Decimal;
        NCTotalCostAmount: Decimal;
        NCTotalAmountLCY: Decimal;
        NCContractDiscAmount: Decimal;
        NCDiscountAmount: Decimal;
        NCTotalDiscountAmount: Decimal;
        NCTotalContractDiscAmount: Decimal;
        NCTotalProfitAmount: Decimal;
        ShowGT: Boolean;
        ServiceProfitServiceOrdersCaptionLbl: Label 'Service Profit (Service Orders)';
        CurrReportPAGENOCaptionLbl: Label 'Page';
        QuantityCaptionLbl: Label 'Quantity';
        ServiceAmountLCYCaptionLbl: Label 'Service Amount (LCY)';
        ContractDiscAmountLCYCaptionLbl: Label 'Contract Disc. Amount (LCY)';
        ServiceDiscAmountLCYCaptionLbl: Label 'Service Disc. Amount (LCY)';
        ServiceCostAmountLCYCaptionLbl: Label 'Service Cost Amount (LCY)';
        ProfitAmountLCYCaptionLbl: Label 'Profit Amount (LCY)';
        ProfitCaptionLbl: Label 'Profit %';
        ServiceOrderCaptionLbl: Label 'Service Order:';
        CustomerCaptionLbl: Label 'Customer:';
        TotalForServOrderLbl: Label 'Total for service order';
        TotalLbl: Label 'Total:';

    procedure InitializeRequest(NewShowDetail: Boolean)
    begin
        ShowDetail := NewShowDetail;
    end;
}

