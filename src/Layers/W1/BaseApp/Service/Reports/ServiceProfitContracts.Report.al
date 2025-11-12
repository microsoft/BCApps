// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Contract;
using Microsoft.Service.Ledger;

report 5976 "Service Profit (Contracts)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceProfitContracts.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Profit (Contracts)';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Service Contract Header";

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = Name;
            DataItemTableView = sorting("Responsibility Center", "Service Zone Code", Status, "Contract Group Code") where("Contract Type" = const(Contract));
            RequestFilterFields = "Responsibility Center", "Contract Group Code", "Contract No.", "Posted Service Order Filter", "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ServContractFilter_ServContract; TableCaption + ': ' + ServContractFilter)
            {
            }
            column(ServContractFilter; ServContractFilter)
            {
            }
            column(RespCenter_ServContract; "Responsibility Center")
            {
            }
            column(AmountLCY_ServLedgEntry; -"Service Ledger Entry"."Amount (LCY)")
            {
            }
            column(ContractDiscAmt_ServLedgEntry; -"Service Ledger Entry"."Contract Disc. Amount")
            {
            }
            column(DisAmt_ServLedgEntry; -"Service Ledger Entry"."Discount Amount")
            {
            }
            column(CostAmt_ServLedgEntry; -"Service Ledger Entry"."Cost Amount")
            {
            }
            column(RespCenter; RespCenterLbl)
            {
            }
            column(ProfitAmt_ServContract; ProfitAmount)
            {
                AutoFormatType = 1;
            }
            column(ProfitPct_ServContract; ProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(Total; TotalLbl)
            {
            }
            column(TotalProfitAmt; TotalProfitAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalCostAmt; TotalCostAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalDiscountAmt; TotalDiscountAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalContractDiscAmount; TotalContractDiscAmount)
            {
                AutoFormatType = 1;
            }
            column(TotalSalesAmount; TotalSalesAmount)
            {
                AutoFormatType = 1;
            }
            column(ServiceProfitServiceContractsCaption; ServiceProfitServiceContractsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(ProfitAmountLCYCaption; ProfitAmountLCYCaptionLbl)
            {
            }
            column(ServiceCostAmountLCYCaption; ServiceCostAmountLCYCaptionLbl)
            {
            }
            column(ServiceDiscAmountLCYCaption; ServiceDiscAmountLCYCaptionLbl)
            {
            }
            column(ContractDiscAmountLCYCaption; ContractDiscAmountLCYCaptionLbl)
            {
            }
            column(ServiceAmountLCYCaption; ServiceAmountLCYCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(ResponsibilityCenterCaption; ResponsibilityCenterCaptionLbl)
            {
            }
            dataitem("Service Ledger Entry"; "Service Ledger Entry")
            {
                DataItemLink = "Service Contract No." = field("Contract No."), "Posting Date" = field("Date Filter"), "Service Order No." = field("Posted Service Order Filter");
                DataItemTableView = sorting("Service Contract No.") where("Entry Type" = const(Sale), Open = const(false));
                column(CustNoName_ServContract; "Service Contract Header"."Customer No." + ' ' + "Service Contract Header".Name)
                {
                }
                column(Desc_ServContract; "Service Contract Header"."Contract No." + ' ' + "Service Contract Header".Description)
                {
                }
                column(ProfitPct_ServLedgEntry; ProfitPct)
                {
                    DecimalPlaces = 1 : 1;
                }
                column(ProfitAmount_ServLedgEntry; ProfitAmount)
                {
                    AutoFormatType = 1;
                }
                column(Type_ServLedgEntry; Type)
                {
                    IncludeCaption = true;
                }
                column(No_ServLedgEntry; "No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(AmountLCY; -"Amount (LCY)")
                {
                }
                column(ContractDiscAmt; -"Contract Disc. Amount")
                {
                }
                column(DiscountAmt; -"Discount Amount")
                {
                }
                column(CostAmt; -"Cost Amount")
                {
                }
                column(PostingDate_ServLedgEntry; Format("Posting Date"))
                {
                }
                column(ShowDetail; ShowDetail)
                {
                }
                column(ServContract; ServContractLbl)
                {
                }
                column(ServContractNo_ServLedgEntry; "Service Contract No.")
                {
                }
                column(CustomerCaption; CustomerCaptionLbl)
                {
                }
                column(ServiceContractCaption; ServiceContractCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ProfitAmount := -"Amount (LCY)" + "Cost Amount";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ServLedgerEntry.SetRange("Service Contract No.");
                ServLedgerEntry.SetFilter("Posting Date", GetFilter("Date Filter"));

                if not ServLedgerEntry.FindFirst() then
                    CurrReport.Skip();

                ProfitAmount := -"Service Ledger Entry"."Amount (LCY)" + "Service Ledger Entry"."Cost Amount";
            end;

            trigger OnPreDataItem()
            begin
                ServLedgerEntry.SetCurrentKey("Service Contract No.");
                ServLedgerEntry.SetRange("Entry Type", ServLedgerEntry."Entry Type"::Sale);
                ServLedgerEntry.SetRange(Open, false);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Profit (Contracts)';
        AboutText = 'Get an overview of profit for service contracts.';
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
                        ToolTip = 'Specifies if you want the report to show details for the contracts.';
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
        TypeCaption = 'Type';
    }

    trigger OnPreReport()
    begin
        ServContractFilter := "Service Contract Header".GetFilters();
        TotalSalesAmount := 0;
        TotalDiscountAmount := 0;
        TotalContractDiscAmount := 0;
        TotalCostAmount := 0;
        TotalProfitAmount := 0;
    end;

    var
        ServLedgerEntry: Record "Service Ledger Entry";
        TotalSalesAmount: Decimal;
        TotalDiscountAmount: Decimal;
        TotalContractDiscAmount: Decimal;
        TotalCostAmount: Decimal;
        TotalProfitAmount: Decimal;
        ProfitAmount: Decimal;
        ProfitPct: Decimal;
        ServContractFilter: Text;
        ShowDetail: Boolean;
        RespCenterLbl: Label 'Total for Responsibility Center';
        TotalLbl: Label 'Total:';
        ServiceProfitServiceContractsCaptionLbl: Label 'Service Profit (Service Contracts)';
        PageCaptionLbl: Label 'Page';
        ProfitCaptionLbl: Label 'Profit %';
        ProfitAmountLCYCaptionLbl: Label 'Profit Amount (LCY)';
        ServiceCostAmountLCYCaptionLbl: Label 'Service Cost Amount (LCY)';
        ServiceDiscAmountLCYCaptionLbl: Label 'Service Disc. Amount (LCY)';
        ContractDiscAmountLCYCaptionLbl: Label 'Contract Disc. Amount (LCY)';
        ServiceAmountLCYCaptionLbl: Label 'Service Amount (LCY)';
        PostingDateCaptionLbl: Label 'Posting Date';
        ResponsibilityCenterCaptionLbl: Label 'Responsibility Center:';
        ServContractLbl: Label 'Total for Service Contract';
        CustomerCaptionLbl: Label 'Customer:';
        ServiceContractCaptionLbl: Label 'Service Contract:';

    procedure InitializeRequest(ShowDetailFrom: Boolean)
    begin
        ShowDetail := ShowDetailFrom;
    end;
}

