// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Item;
using Microsoft.Service.Ledger;

report 5938 "Service Profit (Service Items)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceProfitServiceItems.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Profit (Service Items)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Item"; "Service Item")
        {
            DataItemTableView = sorting("Item No.", "Serial No.");
            RequestFilterFields = "Item No.", "Variant Code", "No.", "Date Filter", Blocked;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ToadayFormatted; Format(Today, 0, 4))
            {
            }
            column(Filter_ServItem; TableCaption + ': ' + ServItemFilter)
            {
            }
            column(ShowFilter; ServItemFilter)
            {
            }
            column(CostAmount; CostAmount)
            {
                AutoFormatType = 1;
            }
            column(DiscountAmount; DiscountAmount)
            {
                AutoFormatType = 1;
            }
            column(SalesAmount; SalesAmount)
            {
                AutoFormatType = 1;
            }
            column(ItemNo_ServItem; "Item No.")
            {
                IncludeCaption = true;
            }
            column(Desc_ServItem; Description)
            {
                IncludeCaption = true;
            }
            column(No_ServItem; "No.")
            {
                IncludeCaption = true;
            }
            column(ProfitAmount; ProfitAmount)
            {
                AutoFormatType = 1;
            }
            column(ProfitPct; ProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(ContractDiscAmount; ContractDiscAmount)
            {
                AutoFormatType = 1;
            }
            column(ShowDetail; ShowDetail)
            {
            }
            column(ItemNoCaptionItemNo; Text000 + FieldCaption("Item No.") + ' ' + "Item No.")
            {
            }
            column(Total; TotalLbl)
            {
            }
            column(ServiceProfitServItemsCaption; ServiceProfitServItemsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ServCostAmtLCYCaption; ServCostAmtLCYCaptionLbl)
            {
            }
            column(ServDiscAmtLCYCaption; ServDiscAmtLCYCaptionLbl)
            {
            }
            column(ServAmtLCYCaption; ServAmtLCYCaptionLbl)
            {
            }
            column(ProfitAmtLCYCaption; ProfitAmtLCYCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ContractDiscAmtLCYCaption; ContractDiscAmtLCYCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                SalesAmount := 0;
                DiscountAmount := 0;
                ContractDiscAmount := 0;
                CostAmount := 0;
                ProfitAmount := 0;

                ServLedgerEntry.SetRange("Service Item No. (Serviced)", "No.");
                ServLedgerEntry.SetFilter(
                  "Entry Type", '%1|%2', ServLedgerEntry."Entry Type"::Sale,
                  ServLedgerEntry."Entry Type"::Consume);
                ServLedgerEntry.SetFilter("Posting Date", GetFilter("Date Filter"));
                ServLedgerEntry.SetRange(Open, false);
                if ServLedgerEntry.FindSet() then
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
                ServLedgerEntry.SetCurrentKey("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date", Open);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Profit (Service Items)';
        AboutText = 'Get an overview of profit for service items.';
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
                        ToolTip = 'Specifies if you want the report to show details for the posted service headers.';
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
        ServItemFilter := "Service Item".GetFilters();
    end;

    var
        ServLedgerEntry: Record "Service Ledger Entry";
        SalesAmount: Decimal;
        DiscountAmount: Decimal;
        ContractDiscAmount: Decimal;
        CostAmount: Decimal;
        ProfitAmount: Decimal;
        ProfitPct: Decimal;
        ServItemFilter: Text;
        ShowDetail: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Total for ';
#pragma warning restore AA0074
        TotalLbl: Label 'Total:';
        ServiceProfitServItemsCaptionLbl: Label 'Service Profit (Service Items)';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ServCostAmtLCYCaptionLbl: Label 'Service Cost Amount (LCY)';
        ServDiscAmtLCYCaptionLbl: Label 'Service Disc. Amount (LCY)';
        ServAmtLCYCaptionLbl: Label 'Service Amount (LCY)';
        ProfitAmtLCYCaptionLbl: Label 'Profit Amount (LCY)';
        ProfitCaptionLbl: Label 'Profit %';
        ContractDiscAmtLCYCaptionLbl: Label 'Contract Disc. Amount (LCY)';

    procedure InitializeRequest(NewShowDetail: Boolean)
    begin
        ShowDetail := NewShowDetail;
    end;
}

