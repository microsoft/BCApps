// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.History;
using Microsoft.Service.Ledger;

report 5909 "Service Profit (Resp. Centers)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceProfitRespCenters.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Profit (Resp. Centers)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Shipment Header"; "Service Shipment Header")
        {
            DataItemTableView = sorting("Responsibility Center", "Posting Date");
            RequestFilterFields = "Responsibility Center", "Posting Date", "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TblCptnServShptHdrFilter; TableCaption + ': ' + ServShipmentHeaderFilter)
            {
            }
            column(ServShipmentHeaderFilter; ServShipmentHeaderFilter)
            {
            }
            column(RespCenter_ServShptHeader; "Responsibility Center")
            {
                IncludeCaption = true;
            }
            column(SalesAmount; SalesAmount)
            {
                AutoFormatType = 1;
            }
            column(ContractDiscAmount; ContractDiscAmount)
            {
                AutoFormatType = 1;
            }
            column(DiscountAmount; DiscountAmount)
            {
                AutoFormatType = 1;
            }
            column(CostAmount; CostAmount)
            {
                AutoFormatType = 1;
            }
            column(ProfitAmount; ProfitAmount)
            {
                AutoFormatType = 1;
            }
            column(ProfitPct; ProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(No_ServShptHeader; "No.")
            {
                IncludeCaption = true;
            }
            column(PostingDate_ServShptHeader; Format("Posting Date"))
            {
            }
            column(CustNo_ServShptHeader; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(ShipToCode_ServShptHeader; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(ShowDetail; ShowDetail)
            {
            }
            column(RespCenter; Text000 + FieldCaption("Responsibility Center") + ' ' + "Responsibility Center")
            {
            }
            column(TotalFor; TotalForLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ServProfitRespCentersCaption; ServProfitRespCentersCaptionLbl)
            {
            }
            column(ServiceAmountLCYCaption; ServiceAmountLCYCaptionLbl)
            {
            }
            column(ContractDiscAmountLCYCaption; ContractDiscAmountLCYCaptionLbl)
            {
            }
            column(ServDiscAmountLCYCaption; ServDiscAmountLCYCaptionLbl)
            {
            }
            column(ServCostAmountLCYCaption; ServCostAmountLCYCaptionLbl)
            {
            }
            column(ProfitAmountLCYCaption; ProfitAmountLCYCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ServShpHdrPostingDateCaption; ServShpHdrPostingDateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                SalesAmount := 0;
                DiscountAmount := 0;
                ContractDiscAmount := 0;
                CostAmount := 0;
                ProfitAmount := 0;

                ServLedgerEntry.SetRange("Service Order No.", "Order No.");
                ServLedgerEntry.SetRange("Entry Type", ServLedgerEntry."Entry Type"::Sale);
                ServLedgerEntry.SetRange(Open, false);
                if ServLedgerEntry.Find('-') then
                    repeat
                        DiscountAmount := DiscountAmount + -ServLedgerEntry."Discount Amount";
                        ContractDiscAmount := ContractDiscAmount + -ServLedgerEntry."Contract Disc. Amount";
                        CostAmount := CostAmount + -ServLedgerEntry."Cost Amount";
                        SalesAmount := SalesAmount + -ServLedgerEntry."Amount (LCY)";
                    until ServLedgerEntry.Next() = 0;

                if (SalesAmount = 0) and (CostAmount = 0) then
                    CurrReport.Skip();

                ProfitAmount := SalesAmount - CostAmount;
            end;

            trigger OnPreDataItem()
            begin
                Clear(SalesAmount);
                Clear(DiscountAmount);
                Clear(ContractDiscAmount);
                Clear(CostAmount);
                Clear(ProfitAmount);
                Clear(ServLedgerEntry);
                ServLedgerEntry.SetCurrentKey(
                  "Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Profit (Resp. Centers)';
        AboutText = 'Get an overview on profit for responsibility centers.';
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
    }

    trigger OnPreReport()
    begin
        ServShipmentHeaderFilter := "Service Shipment Header".GetFilters();
    end;

    var
        ServLedgerEntry: Record "Service Ledger Entry";
        SalesAmount: Decimal;
        DiscountAmount: Decimal;
        ContractDiscAmount: Decimal;
        CostAmount: Decimal;
        ProfitAmount: Decimal;
        ProfitPct: Decimal;
        ServShipmentHeaderFilter: Text;
        ShowDetail: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Total for ';
#pragma warning restore AA0074
        TotalForLbl: Label 'Total:';
        PageCaptionLbl: Label 'Page';
        ServProfitRespCentersCaptionLbl: Label 'Service Profit (Responsibility Centers)';
        ServiceAmountLCYCaptionLbl: Label 'Service Amount (LCY)';
        ContractDiscAmountLCYCaptionLbl: Label 'Contract Discount Amount (LCY)';
        ServDiscAmountLCYCaptionLbl: Label 'Service Discount Amount (LCY)';
        ServCostAmountLCYCaptionLbl: Label 'Service Cost Amount (LCY)';
        ProfitAmountLCYCaptionLbl: Label 'Profit Amount (LCY)';
        ProfitCaptionLbl: Label 'Profit %';
        ServShpHdrPostingDateCaptionLbl: Label 'Posting Date';

    procedure InitializeRequest(ShowDetailFrom: Boolean)
    begin
        ShowDetail := ShowDetailFrom;
    end;
}

