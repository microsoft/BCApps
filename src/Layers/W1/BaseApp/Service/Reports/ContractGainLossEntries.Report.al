// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;

report 5983 "Contract Gain/Loss Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ContractGainLossEntries.rdlc';
    ApplicationArea = Service;
    Caption = 'Contract Gain/Loss Entries';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Contract Gain/Loss Entry"; "Contract Gain/Loss Entry")
        {
            DataItemTableView = sorting("Contract No.", "Change Date", "Reason Code");
            RequestFilterFields = "Contract No.", "Change Date", "Reason Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TblCaptContGainLossFilter; TableCaption + ': ' + ContractGainLossFilter)
            {
            }
            column(ContractGainLossFilter; ContractGainLossFilter)
            {
            }
            column(ContNo_ContGainLossEntry; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(GrpCode_ContGainLossEntry; "Contract Group Code")
            {
                IncludeCaption = true;
            }
            column(ReaCode_ContGainLossEntry; "Reason Code")
            {
                IncludeCaption = true;
            }
            column(CustNo_ContGainLossEntry; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(ShipCode_ContGainLossEntry; "Ship-to Code")
            {
            }
            column(ContGain_ContGainLossEntry; ContractGain)
            {
                AutoFormatType = 1;
            }
            column(ContLoss_ContGainLossEntry; ContractLoss)
            {
                AutoFormatType = 1;
            }
            column(RespCent_ContGainLossEntry; "Responsibility Center")
            {
                IncludeCaption = true;
            }
            column(CustShiptoName; CustShiptoName)
            {
            }
            column(TypeofCng_ContGainLossEty; "Type of Change")
            {
                IncludeCaption = true;
            }
            column(TotalContractNo; Text000 + "Contract No.")
            {
            }
            column(GrFooterShowoutput; Abs(ContractLoss) + Abs(ContractGain) > 0)
            {
            }
            column(Total; TotalLbl)
            {
            }
            column(ContractGainLossEntriesCaption; ContractGainLossEntriesCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ShiptoCodeCaption; ShiptoCodeCaptionLbl)
            {
            }
            column(ContractGainCaption; ContractGainCaptionLbl)
            {
            }
            column(ContractLossCaption; ContractLossCaptionLbl)
            {
            }
            column(CustomerNameCaption; CustomerNameCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CustShiptoName := '';
                if "Ship-to Code" <> '' then
                    if ShiptoAddr.Get("Customer No.", "Ship-to Code") then
                        CustShiptoName := ShiptoAddr.Name;
                if CustShiptoName = '' then
                    if Cust.Get("Customer No.") then
                        CustShiptoName := Cust.Name;

                if Amount > 0 then
                    ContractGain := Amount
                else
                    ContractLoss := Abs(Amount);
            end;

            trigger OnPreDataItem()
            begin
                Clear(ContractLoss);
                Clear(ContractGain);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Contract Gain/Loss Entries';
        AboutText = 'Get an overview of service contract entries for gains and losses.';
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
        ContractGainLossFilter := "Contract Gain/Loss Entry".GetFilters();
    end;

    var
        Cust: Record Customer;
        ShiptoAddr: Record "Ship-to Address";
        ContractGainLossFilter: Text;
        CustShiptoName: Text[100];
        ContractGain: Decimal;
        ContractLoss: Decimal;
        TotalLbl: Label 'Total';

#pragma warning disable AA0074
        Text000: Label 'Total for Contract ';
#pragma warning restore AA0074
        ContractGainLossEntriesCaptionLbl: Label 'Contract Gain/Loss Entries';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ShiptoCodeCaptionLbl: Label 'Ship-to Code';
        ContractGainCaptionLbl: Label 'Contract Gain';
        ContractLossCaptionLbl: Label 'Contract Loss';
        CustomerNameCaptionLbl: Label 'Customer Name';
}

