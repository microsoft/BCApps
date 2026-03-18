// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Item;

report 5935 "Service Items"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceItems.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Items';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item"; "Service Item")
        {
            CalcFields = "No. of Active Contracts";
            DataItemTableView = sorting("Customer No.", "Ship-to Code", "Item No.", "Serial No.");
            RequestFilterFields = "Customer No.", "Ship-to Code", Blocked;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServItemFltr; TableCaption + ': ' + ServItemFilter)
            {
            }
            column(ServItemFilter; ServItemFilter)
            {
            }
            column(CustomerNo_ServItem; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(ShiptoCode_ServItem; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(No_ServItem; "No.")
            {
                IncludeCaption = true;
            }
            column(SerialNo_ServItem; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(Description_ServItem; Description)
            {
                IncludeCaption = true;
            }
            column(ServiceItemGroupCode_ServItem; "Service Item Group Code")
            {
                IncludeCaption = true;
            }
            column(ItemNo_ServItem; "Item No.")
            {
                IncludeCaption = true;
            }
            column(VariantCode_ServItem; "Variant Code")
            {
                IncludeCaption = true;
            }
            column(NoofActiveContracts_ServItem; "No. of Active Contracts")
            {
                IncludeCaption = true;
            }
            column(ServiceItemsCaption; ServiceItemsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Items';
        AboutText = 'Get an overview of registered service items, grouped by customer.';
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
        ServItemFilter := "Service Item".GetFilters();
    end;

    var
        ServItemFilter: Text;
        ServiceItemsCaptionLbl: Label 'Service Items';
        CurrReportPageNoCaptionLbl: Label 'Page';
}

