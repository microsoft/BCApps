// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Item;

report 5937 "Service Items Out of Warranty"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceItemsOutofWarranty.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Items Out of Warranty';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item"; "Service Item")
        {
            CalcFields = "No. of Active Contracts";
            DataItemTableView = sorting("Warranty Ending Date (Parts)", "Customer No.", "Ship-to Code");
            RequestFilterFields = "Warranty Ending Date (Parts)", "Customer No.", "Ship-to Code", Blocked;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServItmTblCptServItemFilt; TableCaption + ': ' + ServItemFilter)
            {
            }
            column(ServItemFilter; ServItemFilter)
            {
            }
            column(CustomerNo_ServItem; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(SerialNo_ServItem; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(WrntyEndgDtParts_ServItem; Format("Warranty Ending Date (Parts)"))
            {
            }
            column(No_ServItem; "No.")
            {
                IncludeCaption = true;
            }
            column(ShiptoCode_ServItem; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(Name_ServItem; Name)
            {
                IncludeCaption = true;
            }
            column(Description_ServItem; Description)
            {
                IncludeCaption = true;
            }
            column(NoofActvContrct_ServItem; "No. of Active Contracts")
            {
                IncludeCaption = true;
            }
            column(ServItemOutofWarrantyCptn; ServItemOutofWarrantyCptnLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ServItmWrntyEndgDtPrtCptn; ServItmWrntyEndgDtPrtCptnLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Name, "Ship-to Name");
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Warranty Ending Date (Parts)") = '' then
                    SetFilter("Warranty Ending Date (Parts)", '<>%1', 0D);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Items Out of Warranty';
        AboutText = 'Get an overview of service items that are out of warranty.';
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
        ServItemOutofWarrantyCptnLbl: Label 'Service Items Out of Warranty';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ServItmWrntyEndgDtPrtCptnLbl: Label 'Warranty Ending Date (Parts)';
}

