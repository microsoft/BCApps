// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Item;

report 5939 "Service Item - Resource Usage"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceItemResourceUsage.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Item - Resource Usage';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item"; "Service Item")
        {
            DataItemTableView = sorting("Item No.", "Serial No.") where("Type Filter" = const(Resource));
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ServiceItemCaption; TableCaption + ': ' + ServItemFilters)
            {
            }
            column(ServItemFilters; ServItemFilters)
            {
            }
            column(ShowDetail; ShowDetail)
            {
            }
            column(ItemNo_ServiceItem; "Item No.")
            {
                IncludeCaption = true;
            }
            column(ItemDesc_ServiceItem; "Item Description")
            {
            }
            column(No_ServiceItem; "No.")
            {
            }
            column(ServItemGrCode_ServiceItem; "Service Item Group Code")
            {
                IncludeCaption = true;
            }
            column(Desc_ServiceItem; Description)
            {
                IncludeCaption = true;
            }
            column(OrderProfit; OrderProfit)
            {
                AutoFormatType = 1;
            }
            column(OrderProfitPct; OrderProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(TotalQty_ServiceItem; "Total Quantity")
            {
            }
            column(UsageCost_ServiceItem; "Usage (Cost)")
            {
            }
            column(UsageAmt_ServiceItem; "Usage (Amount)")
            {
            }
            column(TotForItemNo_ServiceItem; Text0002 + ' ' + FieldCaption("Item No."))
            {
            }
            column(TotalForReport; TotalForReportLbl)
            {
            }
            column(ServItemResourceUsageCaption; ServItemResourceUsageCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ProfitAmtCaption; ProfitAmtCaptionLbl)
            {
            }
            column(UsageAmtCaption; UsageAmtCaptionLbl)
            {
            }
            column(UsageCostCaption; UsageCostCaptionLbl)
            {
            }
            column(TotalQtyCaption; TotalQtyCaptionLbl)
            {
            }
            column(ServItemNoCaption; ServItemNoCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Usage (Cost)", "Usage (Amount)", "Total Quantity");

                OrderProfit := "Usage (Amount)" - "Usage (Cost)";
                if "Usage (Amount)" <> 0 then
                    OrderProfitPct := Round(100 * OrderProfit / "Usage (Amount)", 0.1)
                else
                    OrderProfitPct := 0;
            end;

            trigger OnPreDataItem()
            begin
                Clear(OrderProfit);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Item - Resource Usage';
        AboutText = 'Analyze resource usage of service items.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Show Detail"; ShowDetail)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show detail';
                        ToolTip = 'Specifies if you want the report to show details for resource usage.';
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
        ServItemFilters := "Service Item".GetFilters();
    end;

    var
        OrderProfit: Decimal;
        OrderProfitPct: Decimal;
        ShowDetail: Boolean;
        ServItemFilters: Text;
#pragma warning disable AA0074
        Text0002: Label 'Total for';
#pragma warning restore AA0074
        TotalForReportLbl: Label 'Total for report';
        ServItemResourceUsageCaptionLbl: Label 'Service Item - Resource Usage';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ProfitCaptionLbl: Label 'Profit %';
        ProfitAmtCaptionLbl: Label 'Profit Amount';
        UsageAmtCaptionLbl: Label 'Usage (Amount)';
        UsageCostCaptionLbl: Label 'Usage (Cost)';
        TotalQtyCaptionLbl: Label 'Total Quantity';
        ServItemNoCaptionLbl: Label 'Service Item No.';

    procedure InitializeRequest(ShowDetailFrom: Boolean)
    begin
        ShowDetail := ShowDetailFrom;
    end;
}

