// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;

report 5988 "Contr. Serv. Orders - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ContrServOrdersTest.rdlc';
    Caption = 'Contr. Serv. Orders - Test';

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = where("Contract Type" = const(Contract), "Change Status" = const(Locked), Status = const(Signed));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Contract No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(StartDate; Format(StartDate))
            {
            }
            column(EndDate; Format(EndDate))
            {
            }
            column(Service_Contract_Header__TABLECAPTION__________ServContractFilters; TableCaption + ': ' + ServContractFilters)
            {
            }
            column(ShowServContractFilters; ServContractFilters)
            {
            }
            column(ShowFullBody; ShowFullBody)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Contract_Service_Orders___TestCaption; Contract_Service_Orders___TestCaptionLbl)
            {
            }
            column(StartDateCaption; StartDateCaptionLbl)
            {
            }
            column(EndDateCaption; EndDateCaptionLbl)
            {
            }
            column(Service_Contract_Line__Next_Planned_Service_Date_Caption; Service_Contract_Line__Next_Planned_Service_Date_CaptionLbl)
            {
            }
            column(Service_Contract_Line__Last_Service_Date_Caption; Service_Contract_Line__Last_Service_Date_CaptionLbl)
            {
            }
            column(Service_Contract_Line__Last_Planned_Service_Date_Caption; Service_Contract_Line__Last_Planned_Service_Date_CaptionLbl)
            {
            }
            column(Service_Contract_Line_DescriptionCaption; "Service Contract Line".FieldCaption(Description))
            {
            }
            column(Service_Contract_Line__Serial_No__Caption; "Service Contract Line".FieldCaption("Serial No."))
            {
            }
            column(Service_Contract_Line__Contract_No__Caption; "Service Contract Line".FieldCaption("Contract No."))
            {
            }
            column(Customer_No_Caption; Customer_No_CaptionLbl)
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            dataitem("Service Contract Line"; "Service Contract Line")
            {
                DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                DataItemTableView = sorting("Contract Type", "Contract No.", "Line No.") order(ascending) where("Service Period" = filter(<> ''));
                column(Service_Contract_Line__Serial_No__; "Serial No.")
                {
                }
                column(Service_Contract_Line__Last_Planned_Service_Date_; Format("Last Planned Service Date"))
                {
                }
                column(Service_Contract_Line__Next_Planned_Service_Date_; Format("Next Planned Service Date"))
                {
                }
                column(Service_Contract_Line__Last_Service_Date_; Format("Last Service Date"))
                {
                }
                column(Service_Contract_Line_Description; Description)
                {
                }
                column(Service_Contract_Line__Contract_No__; "Contract No.")
                {
                }
                column(Cust__No__; Cust."No.")
                {
                }
                column(Cust_Name; Cust.Name)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Contract Expiration Date" <> 0D then begin
                        if "Contract Expiration Date" <= "Next Planned Service Date" then
                            CurrReport.Skip();
                    end else
                        if ("Service Contract Header"."Expiration Date" <> 0D) and
                           ("Service Contract Header"."Expiration Date" <= "Next Planned Service Date")
                        then
                            CurrReport.Skip();

                    Cust.Get("Service Contract Header"."Bill-to Customer No.");
                    if Cust.Blocked = Cust.Blocked::All then
                        CurrReport.Skip();

                    ServHeader.SetCurrentKey("Contract No.", Status, "Posting Date");
                    ServHeader.SetRange("Contract No.", "Contract No.");
                    ServHeader.SetRange(Status, ServHeader.Status::Pending);

                    if ServHeader.FindFirst() then begin
                        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
                        ServItemLine.SetRange("Document No.", ServHeader."No.");
                        ServItemLine.SetRange("Contract No.", "Contract No.");
                        ServItemLine.SetRange("Contract Line No.", "Line No.");
                        OnBeforeFindServiceItemLine(
                          ServItemLine, "Service Contract Header", "Service Contract Line", ServHeader);
                        if ServItemLine.FindFirst() then
                            CurrReport.Skip();
                    end;

                    if LastContractNo <> "Contract No." then begin
                        LastContractNo := "Contract No.";
                        ShowFullBody := true;
                    end else
                        ShowFullBody := false;
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate = 0D then
                        Error(Text000);
                    if EndDate < StartDate then
                        Error(Text001);

                    if StartDate <> 0D then
                        if EndDate - StartDate + 1 > ServMgtSetup."Contract Serv. Ord.  Max. Days" then
                            Error(
                              Text002,
                              ServMgtSetup.TableCaption());

                    if GetFilter("Contract No.") = '' then
                        SetFilter("Contract No.", '<>%1', '');
                    SetRange("Next Planned Service Date", StartDate, EndDate);
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Contr. Serv. Orders - Test';
        AboutText = 'Find service contracts that include service items that are due for service within a period you specify.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date for the period that you want to create contract service orders for. The report includes contracts with service items that have next planned service dates on or later than this date.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date for the period that you want to create contract service orders for. ';

                        trigger OnValidate()
                        begin
                            if EndDate < StartDate then
                                Error(Text001);
                        end;
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
        ServMgtSetup.Get();
        if StartDate = 0D then
            if ServMgtSetup."Last Contract Service Date" <> 0D then
                StartDate := ServMgtSetup."Last Contract Service Date" + 1;
    end;

    trigger OnPreReport()
    begin
        ServContractFilters := "Service Contract Header".GetFilters();
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        Cust: Record Customer;
        ServItemLine: Record "Service Item Line";
        LastContractNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        ServContractFilters: Text;
        ShowFullBody: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You must fill in the ending date field.';
        Text001: Label 'Starting Date is greater than Ending Date.';
#pragma warning disable AA0470
        Text002: Label 'The date range you have entered is a longer period than is allowed in the %1 table.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Contract_Service_Orders___TestCaptionLbl: Label 'Contract Service Orders - Test';
        StartDateCaptionLbl: Label 'Starting Date';
        EndDateCaptionLbl: Label 'Ending Date';
        Service_Contract_Line__Next_Planned_Service_Date_CaptionLbl: Label 'Next Planned Service Date';
        Service_Contract_Line__Last_Service_Date_CaptionLbl: Label 'Last Service Date';
        Service_Contract_Line__Last_Planned_Service_Date_CaptionLbl: Label 'Last Planned Service Date';
        Customer_No_CaptionLbl: Label 'Customer No.';
        Customer_NameCaptionLbl: Label 'Customer Name';

    procedure InitVariables(LocalStartDate: Date; LocalEndDate: Date)
    begin
        StartDate := LocalStartDate;
        EndDate := LocalEndDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line"; ServiceHeader: Record "Service Header")
    begin
    end;
}

