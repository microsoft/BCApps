// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Contract;

report 5977 "Service Contract - Customer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceContractCustomer.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Contract - Customer';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = Name;
            DataItemTableView = sorting("Customer No.", "Ship-to Code") where("Contract Type" = const(Contract));
            RequestFilterFields = "Customer No.", "Ship-to Code", "Contract No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ServContractHdrCaption; TableCaption + ': ' + ServContractFilter)
            {
            }
            column(ServContractFilter; ServContractFilter)
            {
            }
            column(CustomerNoNameCaption; FieldCaption("Customer No.") + ' ' + "Customer No." + ' ' + Name)
            {
            }
            column(ContractNo_ServContract; "Contract No.")
            {
                IncludeCaption = true;
            }
            column(Status_ServContract; Format(Status))
            {
            }
            column(AmtperPeriod_ServContract; "Amount per Period")
            {
            }
            column(NextInvDate_ServContract; Format("Next Invoice Date"))
            {
            }
            column(InvPeriod_ServContract; Format("Invoice Period"))
            {
            }
            column(AnnualAmount_ServContract; "Annual Amount")
            {
                IncludeCaption = true;
            }
            column(Description_ServContract; Description)
            {
                IncludeCaption = true;
            }
            column(Prepaid_ServContract; Prepaid)
            {
                IncludeCaption = true;
            }
            column(ShiptoCode_ServContract; "Ship-to Code")
            {
                IncludeCaption = true;
            }
            column(AmtOnExpiredLines; AmountOnExpiredLines)
            {
            }
            column(PrepaidFmt_ServContract; Format(Prepaid))
            {
            }
            column(TotalForCustomerNoName; Text000 + FieldCaption("Customer No.") + ' ' + "Customer No." + ' ' + Name)
            {
            }
            column(CustomerNo_ServContract; "Customer No.")
            {
            }
            column(ServContractsCustCaption; ServContractsCustCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(StatusCaption; StatusCaptionLbl)
            {
            }
            column(AmtperPeriodCaption; AmtperPeriodCaptionLbl)
            {
            }
            column(ServContHdrNextInvDtCptn; ServContHdrNextInvDtCptnLbl)
            {
            }
            column(InvoicePeriodCaption; InvoicePeriodCaptionLbl)
            {
            }
            column(AmtonExpiredLinesCaption; AmtonExpiredLinesCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                AmountOnExpiredLines := 0;
                ServContractLine.SetRange("Contract Type", "Contract Type");
                ServContractLine.SetRange("Contract No.", "Contract No.");
                if ServContractLine.Find('-') then
                    repeat
                        if (("Expiration Date" <> 0D) and
                            ("Expiration Date" <= WorkDate())) or
                           ((ServContractLine."Contract Expiration Date" <> 0D) and
                            (ServContractLine."Contract Expiration Date" <= WorkDate()))
                        then
                            AmountOnExpiredLines := AmountOnExpiredLines + ServContractLine."Line Amount";
                    until ServContractLine.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                Clear(AmountOnExpiredLines);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Contract - Customer';
        AboutText = 'Get an overview of service contracts for each customer in a selected time period.';
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
        ServContractFilter := "Service Contract Header".GetFilters();
    end;

    var
        ServContractLine: Record "Service Contract Line";
        ServContractFilter: Text;
        AmountOnExpiredLines: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Total for ';
#pragma warning restore AA0074
        ServContractsCustCaptionLbl: Label 'Service Contracts - Customer';
        CurrReportPageNoCaptionLbl: Label 'Page';
        StatusCaptionLbl: Label 'Status';
        AmtperPeriodCaptionLbl: Label 'Amount per Period';
        ServContHdrNextInvDtCptnLbl: Label 'Next Invoice Date';
        InvoicePeriodCaptionLbl: Label 'Invoice Period';
        AmtonExpiredLinesCaptionLbl: Label 'Amount on Expired Lines';
        TotalCaptionLbl: Label 'Total';
}

