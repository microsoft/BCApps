// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Inventory.Location;
using Microsoft.Service.Contract;
using Microsoft.Service.History;

report 5982 "Maintenance Performance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/MaintenancePerformance.rdlc';
    ApplicationArea = Service;
    Caption = 'Maintenance Performance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = sorting("Responsibility Center", "Service Zone Code", Status, "Contract Group Code") where(Status = const(Signed), "Contract Type" = const(Contract));
            RequestFilterFields = "Responsibility Center";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(SrvcContractHdrFltr; TableCaption + ': ' + ServContractFilter)
            {
            }
            column(ServContractFilter; ServContractFilter)
            {
            }
            column(CurrentDateFormatted; Text001 + Format(CalcDate('<-CY>', CurrentDate)) + ' .. ' + Format(CurrentDate))
            {
            }
            column(ActualAmount; ActualAmount)
            {
                DecimalPlaces = 0 : 0;
            }
            column(ExpectedAmount; ExpectedAmount)
            {
                DecimalPlaces = 0 : 0;
            }
            column(AnnualAmount; AnnualAmount)
            {
                DecimalPlaces = 0 : 0;
            }
            column(ResponsCntr_ServiceContractHdr; "Responsibility Center")
            {
                IncludeCaption = true;
            }
            column(RespCenterName; RespCenter.Name)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(MaintenancePerformanceCaption; MaintenancePerformanceCaptionLbl)
            {
            }
            column(RealizedCaption; RealizedCaptionLbl)
            {
            }
            column(RealizedAmountCaption; RealizedAmountCaptionLbl)
            {
            }
            column(ExpectedAmountCaption; ExpectedAmountCaptionLbl)
            {
            }
            column(AnnualAmountCaption; AnnualAmountCaptionLbl)
            {
            }
            column(RespCenterNameCaption; RespCenterNameCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ServContractLine.SetRange("Contract Type", "Contract Type");
                ServContractLine.SetRange("Contract No.", "Contract No.");
                ServContractLine.SetFilter("Next Planned Service Date", '<>%1', 0D);
                if not ServContractLine.FindFirst() then
                    CurrReport.Skip();

                AnnualAmount := 0;
                ExpectedAmount := 0;
                ActualAmount := 0;

                AnnualServices := CalcNoOfVisits("Service Period", "Starting Date", 0D, true);
                ExpectedServices := CalcNoOfVisits("Service Period",
                    "Starting Date", ServContractLine."Next Planned Service Date", false);

                Clear(ServShptHeader);
                ServShptHeader.SetCurrentKey("Contract No.", "Posting Date");
                ServShptHeader.SetRange("Contract No.", "Contract No.");
                ServShptHeader.SetRange("Posting Date", StartingDate, WorkDate());
                ActualServices := 0;
                if ServShptHeader.Find('-') then
                    repeat
                        if (ServShptHeader."Posting Date" >= StartingDate) and (ServShptHeader."Posting Date" <= EndingDate) then
                            ActualServices := ActualServices + 1
                    until ServShptHeader.Next() = 0;

                if AnnualServices > 0 then begin
                    RoundedAmount := Round("Annual Amount", 1);
                    AnnualAmount := AnnualAmount + RoundedAmount;
                    ExpectedAmount := ExpectedAmount + Round((RoundedAmount / AnnualServices) * ExpectedServices, 1);
                    ActualAmount := ActualAmount + Round((RoundedAmount / AnnualServices) * ActualServices, 1);
                end;

                if AnnualAmount = 0 then
                    CurrReport.Skip();

                if not RespCenter.Get("Responsibility Center") then
                    Clear(RespCenter);
            end;

            trigger OnPreDataItem()
            begin
                if CurrentDate = 0D then
                    Error(Text000);

                Clear(AnnualAmount);
                Clear(ExpectedAmount);
                Clear(ActualAmount);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Maintenance Performance';
        AboutText = 'Analyze maintenance performance for responsibility centers.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CurrentDate; CurrentDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Current Date';
                        ToolTip = 'Specifies the date with the year that you want the report to cover.';
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

    trigger OnInitReport()
    begin
        CurrentDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        ServContractFilter := "Service Contract Header".GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You must enter the current date.';
        Text001: Label 'Service Period: ';
#pragma warning restore AA0074
        ServContractLine: Record "Service Contract Line";
        ServShptHeader: Record "Service Shipment Header";
        RespCenter: Record "Responsibility Center";
        AnnualServices: Decimal;
        ExpectedServices: Decimal;
        ActualServices: Decimal;
        RoundedAmount: Decimal;
        AnnualAmount: Decimal;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
        ServContractFilter: Text;
        StartingDate: Date;
        EndingDate: Date;
        CurrentDate: Date;
        PageCaptionLbl: Label 'Page';
        MaintenancePerformanceCaptionLbl: Label 'Maintenance Performance';
        RealizedCaptionLbl: Label 'Realized %';
        RealizedAmountCaptionLbl: Label 'Realized Amount';
        ExpectedAmountCaptionLbl: Label 'Expected Amount';
        AnnualAmountCaptionLbl: Label 'Annual Amount';
        RespCenterNameCaptionLbl: Label 'Responsibility Center Name';
        TotalCaptionLbl: Label 'Total';

    local procedure CalcNoOfVisits(ServPeriod: DateFormula; FirstDate: Date; NextServiceDate: Date; AllYear: Boolean): Integer
    var
        TempDate: Date;
        i: Integer;
    begin
        if Format(ServPeriod) <> '' then begin
            i := 0;
            StartingDate := CalcDate('<-CY>', CurrentDate);
            if FirstDate > StartingDate then
                StartingDate := FirstDate;
            if AllYear then
                EndingDate := CalcDate('<+CY>', CurrentDate)
            else
                EndingDate := CurrentDate;
            TempDate := StartingDate;
            repeat
                if AllYear then begin
                    if TempDate <= EndingDate then
                        i := i + 1;
                end else
                    if (TempDate <= EndingDate) and (CalcDate(ServPeriod, TempDate) <= NextServiceDate) then
                        i := i + 1;
                TempDate := CalcDate(ServPeriod, TempDate);
            until TempDate >= EndingDate;
            exit(i);
        end;
        exit(0);
    end;

    procedure InitializeRequest(CurrentDateFrom: Date)
    begin
        CurrentDate := CurrentDateFrom;
    end;
}

