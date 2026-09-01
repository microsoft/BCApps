// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Document;

report 5955 "Dispatch Board"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/DispatchBoard.rdlc';
    AdditionalSearchTerms = 'service schedule';
    ApplicationArea = Service;
    Caption = 'Dispatch Board';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Service Header";

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting(Status, "Response Date", "Response Time", Priority);
            RequestFilterFields = "Document Type", "No.", Status, "Response Date", "Customer No.", "Service Zone Code", "Contract No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableCaptionFilter_ServHeader; TableCaption + ': ' + ServHeaderFilter)
            {
            }
            column(ServHeaderFilter; ServHeaderFilter)
            {
            }
            column(ResponseDate_ServHeader; Format("Response Date"))
            {
            }
            column(ResponseTime_ServHeader; "Response Time")
            {
                IncludeCaption = true;
            }
            column(Priority_ServHeader; Priority)
            {
                IncludeCaption = true;
            }
            column(No_ServHeader; "No.")
            {
                IncludeCaption = true;
            }
            column(Status_ServHeader; Status)
            {
                IncludeCaption = true;
            }
            column(CustNo_ServHeader; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(ShiptoCode_ServHeader; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(Name_ServHeader; Name)
            {
                IncludeCaption = true;
            }
            column(ContractNo_ServHeader; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(ServiceZoneCode_ServHeader; "Service Zone Code")
            {
                IncludeCaption = true;
            }
            column(NoofAllocations_ServHeader; "No. of Allocations")
            {
                IncludeCaption = true;
            }
            column(OrderDate_ServHeader; Format("Order Date"))
            {
            }
            column(Dispatch_BoardCaption; Dispatch_BoardCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ResponseDate_ServHeaderCaption; ResponseDate_ServHeaderCaptionLbl)
            {
            }
            column(OrderDate_ServHeaderCaption; OrderDate_ServHeaderCaptionLbl)
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Dispatch Board';
        AboutText = 'Get an overview of your dispatch board.';
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
        ServHeaderFilter := "Service Header".GetFilters();
    end;

    var
        ServHeaderFilter: Text;
        Dispatch_BoardCaptionLbl: Label 'Dispatch Board';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ResponseDate_ServHeaderCaptionLbl: Label 'Response Date';
        OrderDate_ServHeaderCaptionLbl: Label 'Order Date';
}

