// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;

report 5981 "Contr. Gain/Loss - Resp. Ctr."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ContrGainLossRespCtr.rdlc';
    ApplicationArea = Service;
    Caption = 'Contr. Gain/Loss - Resp. Ctr.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Contract Gain/Loss Entry"; "Contract Gain/Loss Entry")
        {
            DataItemTableView = sorting("Responsibility Center", "Type of Change", "Reason Code");
            RequestFilterFields = "Responsibility Center", "Change Date";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TblCaptContGnLossFilter; TableCaption + ': ' + ContractGainLossFilter)
            {
            }
            column(ContractGainLossFilter; ContractGainLossFilter)
            {
            }
            column(ShowContGainLossDetails; ShowContractGainLossDetails)
            {
            }
            column(RespCenter_ContGnLossEty; "Responsibility Center")
            {
                IncludeCaption = true;
            }
            column(TypeofCng_ContGnLossEty; "Type of Change")
            {
                IncludeCaption = true;
            }
            column(ReasonCode_ContGnLossEty; "Reason Code")
            {
                IncludeCaption = true;
            }
            column(ContNo_ContGnLossEty; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(ContGrpCode_ContGnLossEty; "Contract Group Code")
            {
                IncludeCaption = true;
            }
            column(CustNo_ContGnLossEty; "Customer No.")
            {
                IncludeCaption = true;
            }
            column(Amt_ContGnLossEty; Amount)
            {
                IncludeCaption = true;
            }
            column(ChangeDt_ContGnLossEty; Format("Change Date"))
            {
            }
            column(CustName_ContGnLossEty; CustName)
            {
            }
            column(ShiptoCode_ContGnLossEty; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(TotalFieldCaptReasonCode; StrSubstNo(Text001, "Reason Code", FieldCaption("Reason Code")))
            {
            }
            column(GrandTotFildCaptTypeofCng; StrSubstNo(Text001, "Type of Change", FieldCaption("Type of Change")))
            {
            }
            column(GrandTotFieldCaptRespCent; StrSubstNo(Text001, "Responsibility Center", FieldCaption("Responsibility Center")))
            {
            }
            column(GrandTotal; GrandTotalLbl)
            {
            }
            column(CntrctGainLossRespCenterCaption; CntrctGainLossRespCenterCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CustomerNameCaption; CustomerNameCaptionLbl)
            {
            }
            column(CntrctGainLossEntryChangeDtCaption; CntrctGainLossEntryChangeDtCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CustName := '';
                if "Ship-to Code" <> '' then
                    if ShiptoAddr.Get("Customer No.", "Ship-to Code") then
                        CustName := ShiptoAddr.Name;
                if CustName = '' then
                    if Cust.Get("Customer No.") then
                        CustName := Cust.Name;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Contr. Gain/Loss - Resp. Ctr.';
        AboutText = 'Analyze gains and losses made on contracts attached to responsibility centers.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowContractGainLossDetails; ShowContractGainLossDetails)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want the report to show details of the contract gain/loss entry.';
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
        ContractGainLossFilter := "Contract Gain/Loss Entry".GetFilters();
    end;

    var
        Cust: Record Customer;
        ShiptoAddr: Record "Ship-to Address";
        ContractGainLossFilter: Text;
        CustName: Text[100];
        ShowContractGainLossDetails: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The total of entries grouped by the %1 %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GrandTotalLbl: Label 'Grand Total:';
        CntrctGainLossRespCenterCaptionLbl: Label 'Contract Gain/Loss - Responsibility Center';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CustomerNameCaptionLbl: Label 'Customer Name';
        CntrctGainLossEntryChangeDtCaptionLbl: Label 'Change Date';

    procedure InitializeRequest(ShowContractGainLossDetailFrom: Boolean)
    begin
        ShowContractGainLossDetails := ShowContractGainLossDetailFrom;
    end;
}

