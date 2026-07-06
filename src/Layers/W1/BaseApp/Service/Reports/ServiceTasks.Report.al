// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Document;

report 5904 "Service Tasks"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceTasks.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Tasks';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item Line"; "Service Item Line")
        {
            DataItemTableView = sorting("Response Date", "Response Time", Priority);
            RequestFilterFields = "Repair Status Code", "Response Date", "Response Time", "Resource Filter", "Allocation Status Filter";
            column(TodayFormat; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServItem_ServItemLine; TableCaption + ': ' + ServItemLineFilter)
            {
            }
            column(ServItemLineFilter; ServItemLineFilter)
            {
            }
            column(ResponseDate_ServItemLine; Format("Response Date"))
            {
            }
            column(ResponseTime_ServItemLine; "Response Time")
            {
                IncludeCaption = true;
            }
            column(Priority_ServItemLine; Priority)
            {
                IncludeCaption = true;
            }
            column(DocNo_ServItemLine; "Document No.")
            {
                IncludeCaption = true;
            }
            column(RepairStatus_ServItemLine; "Repair Status Code")
            {
                IncludeCaption = true;
            }
            column(ServItemGr_ServItemLine; "Service Item Group Code")
            {
                IncludeCaption = true;
            }
            column(ServItemNo_ServItemLine; "Service Item No.")
            {
                IncludeCaption = true;
            }
            column(ItemNo_ServItemLine; "Item No.")
            {
                IncludeCaption = true;
            }
            column(SerialNo_ServItemLine; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(ServShelfNo_ServItemLine; "Service Shelf No.")
            {
                IncludeCaption = true;
            }
            column(Warranty_ServItemLine; Warranty)
            {
                IncludeCaption = true;
            }
            column(ContractNo_ServItemLine; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(FormatWarranty; Format(Warranty))
            {
            }
            column(ServiceTasksCaption; ServiceTasksCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ResponseDateCaption; ResponseDateCaptionLbl)
            {
            }

            trigger OnPreDataItem()
            begin
                if (GetFilter("Allocation Status Filter") <> '') or
                   (GetFilter("Resource Filter") <> '') or
                   (GetFilter("Resource Group Filter") <> '')
                then
                    SetFilter("No. of Allocations", '>0');
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Tasks';
        AboutText = 'Get an overview of service tasks.';
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
        ServItemLineFilter := "Service Item Line".GetFilters();
    end;

    var
        ServItemLineFilter: Text;
        ServiceTasksCaptionLbl: Label 'Service Tasks';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ResponseDateCaptionLbl: Label 'Response Date';
}

