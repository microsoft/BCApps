// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;

report 5980 "Maintenance Visit - Planning"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/MaintenanceVisitPlanning.rdlc';
    ApplicationArea = Service;
    Caption = 'Maintenance Visit - Planning';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = sorting("Responsibility Center", "Service Zone Code", Status, "Contract Group Code") where("Contract Type" = const(Contract), Status = const(Signed));
            RequestFilterFields = "Responsibility Center", "Service Zone Code", "Contract Group Code", "Contract No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ServContractHdrTbCaptFltr; TableCaption + ': ' + ServContractFilter)
            {
            }
            column(ServContractLineTCaptFltr; "Service Contract Line".TableCaption + ': ' + ServContractLineFilter)
            {
            }
            column(EmptyStrCtrl1; '.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .')
            {
            }
            column(ServContractFilter; ServContractFilter)
            {
            }
            column(ServContractLineFilter; ServContractLineFilter)
            {
            }
            column(RespCntr_ServContractHdr; "Responsibility Center")
            {
                IncludeCaption = true;
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            column(MaintenanceVisitPlanningCaption; MaintenanceVisitPlanningCaptionLbl)
            {
            }
            column(ServiceZoneCodeCaption; ServiceZoneCodeCaptionLbl)
            {
            }
            column(GroupCodeCaption; GroupCodeCaptionLbl)
            {
            }
            column(CustShiptoNameCaption; CustShiptoNameCaptionLbl)
            {
            }
            column(NextPlannedCaption; NextPlannedCaptionLbl)
            {
            }
            column(LastActualCaption; LastActualCaptionLbl)
            {
            }
            column(LastPlannedCaption; LastPlannedCaptionLbl)
            {
            }
            column(ServiceDatesCaption; ServiceDatesCaptionLbl)
            {
            }
            dataitem("Service Contract Line"; "Service Contract Line")
            {
                DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                DataItemTableView = sorting("Contract Type", "Contract No.", "Line No.");
                RequestFilterFields = "Next Planned Service Date";
                column(ServZnCd_ServContractHdr; "Service Contract Header"."Service Zone Code")
                {
                }
                column(ContrGrpCd_ServContractHdr; "Service Contract Header"."Contract Group Code")
                {
                }
                column(ContrNo_ServContractLine; "Contract No.")
                {
                    IncludeCaption = true;
                }
                column(CustNo_ServContractLine; "Customer No.")
                {
                    IncludeCaption = true;
                }
                column(ShiptoCd_ServContractLine; "Ship-to Code")
                {
                    IncludeCaption = true;
                }
                column(CustShiptoName; CustShiptoName)
                {
                }
                column(ServPerd_ServContractLine; "Service Period")
                {
                    IncludeCaption = true;
                }
                column(NxtPlServDt_ServContractLine; Format("Next Planned Service Date"))
                {
                }
                column(LstServDt_ServContractLine; Format("Last Service Date"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                CustShiptoName := '';

                if "Ship-to Code" = '' then begin
                    if Cust.Get("Customer No.") then
                        CustShiptoName := Cust.Name;
                end else
                    if ShiptoAddr.Get("Customer No.", "Ship-to Code") then
                        CustShiptoName := ShiptoAddr.Name;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Maintenance Visit - Planning';
        AboutText = 'Generate a report that shows all your scheduled maintenance visits.';
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
        ServContractLineFilter := "Service Contract Line".GetFilters();
    end;

    var
        Cust: Record Customer;
        ShiptoAddr: Record "Ship-to Address";
        CustShiptoName: Text[100];
        ServContractFilter: Text;
        ServContractLineFilter: Text;
        CurrReportPAGENOCaptionLbl: Label 'Page';
        MaintenanceVisitPlanningCaptionLbl: Label 'Maintenance Visit - Planning';
        ServiceZoneCodeCaptionLbl: Label 'Service Zone Code';
        GroupCodeCaptionLbl: Label 'Group Code';
        CustShiptoNameCaptionLbl: Label 'Customer Name';
        NextPlannedCaptionLbl: Label 'Next Planned';
        LastActualCaptionLbl: Label 'Last Actual';
        LastPlannedCaptionLbl: Label 'Last Planned';
        ServiceDatesCaptionLbl: Label 'Service Dates';
}

