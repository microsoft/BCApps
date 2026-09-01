// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.History;

report 5908 "Service Order - Response Time"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceOrderResponseTime.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Order - Response Time';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Shipment Header"; "Service Shipment Header")
        {
            DataItemTableView = sorting("Responsibility Center", "Posting Date");
            RequestFilterFields = "Responsibility Center", "Posting Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServShipHeadFilter1; TableCaption + ': ' + ServShipmentHeaderFilter)
            {
            }
            column(ServShipHeadFilter2; ServShipmentHeaderFilter)
            {
            }
            column(OrderNo_ServShptHdr; "Order No.")
            {
                IncludeCaption = true;
            }
            column(CustNo_ServShptHdr; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(OrderDate_ServShptHdr; Format("Order Date"))
            {
            }
            column(OrderTime_ServShptHdr; Format("Order Time"))
            {
            }
            column(Name_ServShptHdr; Name)
            {
                IncludeCaption = true;
            }
            column(ActualResTimHrs_ServShptHdr; "Actual Response Time (Hours)")
            {
                IncludeCaption = true;
            }
            column(StartingDate_ServShptHdr; Format("Starting Date"))
            {
            }
            column(StartingTime_ServShptHdr; Format("Starting Time"))
            {
            }
            column(TotalTime; TotalTime)
            {
            }
            column(TotalCalls; TotalCalls)
            {
            }
            column(TotalTimeFooter; TotalTimeFooter)
            {
            }
            column(TotalCallsFooter; TotalCallsFooter)
            {
            }
            column(AvgResTimeRespCenter; Text000 + FieldCaption("Responsibility Center") + ' ' + "Responsibility Center")
            {
            }
            column(RoundTotalTimeTotalCalls; ActRespTime)
            {
                DecimalPlaces = 0 : 5;
            }
            column(AvgResponseTime; AvgResponseTimeLbl)
            {
            }
            column(RespCenter_ServShptHdr; "Responsibility Center")
            {
            }
            column(ServOrderRespTimeCaption; ServOrderRespTimeCaptionLbl)
            {
            }
            column(CurrReportPageNOCaption; CurrReportPageNOCaptionLbl)
            {
            }
            column(ServShptHdrOrderDtCaption; ServShptHdrOrderDtCaptionLbl)
            {
            }
            column(ServShptHdrOrdTimeCaption; ServShptHdrOrdTimeCaptionLbl)
            {
            }
            column(ServShptHdrStartDtCaption; ServShptHdrStartDtCaptionLbl)
            {
            }
            column(ServShptHdrStrtTimCaption; ServShptHdrStrtTimCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if LastRespCenterCode <> "Responsibility Center" then begin
                    TotalCalls := 0;
                    TotalTime := 0;
                end;

                if ("Order No." <> '') and (LastOrderNo <> "Order No.") then begin
                    TotalCalls := TotalCalls + 1;
                    TotalTime := TotalTime + "Actual Response Time (Hours)";
                    TotalCallsFooter += 1;
                    TotalTimeFooter += "Actual Response Time (Hours)";
                    LastOrderNo := "Order No.";
                end else
                    CurrReport.Skip();

                LastRespCenterCode := "Responsibility Center";
            end;

            trigger OnPreDataItem()
            begin
                TotalTime := 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Order - Response Time';
        AboutText = 'Analyze response times for service orders that are shipped.';
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
    begin
        ServShipmentHeaderFilter := "Service Shipment Header".GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Average Response Time Per ';
#pragma warning restore AA0074
        ServShipmentHeaderFilter: Text;
        TotalTime: Decimal;
        TotalCalls: Integer;
        LastOrderNo: Code[20];
        ActRespTime: Decimal;
        TotalCallsFooter: Integer;
        TotalTimeFooter: Decimal;
        LastRespCenterCode: Code[10];
        AvgResponseTimeLbl: Label 'Average Response Time';
        ServOrderRespTimeCaptionLbl: Label 'Service Order - Response Time';
        CurrReportPageNOCaptionLbl: Label 'Page';
        ServShptHdrOrderDtCaptionLbl: Label 'Order Date';
        ServShptHdrOrdTimeCaptionLbl: Label 'Order Time';
        ServShptHdrStartDtCaptionLbl: Label 'Starting Date';
        ServShptHdrStrtTimCaptionLbl: Label 'Starting Time';
}

