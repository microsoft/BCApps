// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Reports;
using Microsoft.Service.Setup;

report 6036 "Create Contract Service Orders"
{
    ApplicationArea = Service;
    Caption = 'Create Contract Service Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = where("Contract Type" = const(Contract), "Change Status" = const(Locked), Status = const(Signed));
            RequestFilterFields = "Contract No.";
            dataitem("Service Contract Line"; "Service Contract Line")
            {
                DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                DataItemTableView = where("Service Period" = filter(<> ''));

                trigger OnAfterGetRecord()
                var
                    ServContractManagement: Codeunit ServContractManagement;
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

                    ServContractManagement.CheckServiceItemBlockedForAll("Service Contract Line");
                    ServContractManagement.CheckItemServiceBlocked("Service Contract Line");

                    ServHeader.SetCurrentKey("Contract No.", Status, "Posting Date");
                    ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
                    ServHeader.SetRange("Contract No.", "Contract No.");
                    ServHeader.SetRange(Status, ServHeader.Status::Pending);

                    ServOrderExist := ServHeader.FindFirst();
                    if ServOrderExist then begin
                        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
                        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
                        ServItemLine.SetRange("Document No.", ServHeader."No.");
                        ServItemLine.SetRange("Contract No.", "Contract No.");
                        ServItemLine.SetRange("Contract Line No.", "Line No.");
                        OnBeforeFindServiceItemLineOnServiceContractLineAfterGetRecord(
                          ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
                        if ServItemLine.FindFirst() then
                            CurrReport.Skip();
                    end;
                    CreateOrAddToServOrder();
                end;

                trigger OnPreDataItem()
                begin
                    if EndDate = 0D then
                        Error(Text002);
                    if EndDate < StartDate then
                        Error(Text003);

                    if StartDate <> 0D then
                        if EndDate - StartDate + 1 > ServMgtSetup."Contract Serv. Ord.  Max. Days" then
                            Error(
                              Text004,
                              ServMgtSetup.TableCaption());

                    SetRange("Next Planned Service Date", StartDate, EndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VerifyServiceContractHeader();
            end;

            trigger OnPostDataItem()
            begin
                OnServiceContractHeaderPostDataItem();
            end;

            trigger OnPreDataItem()
            begin
                OnServiceContractHeaderPreDataItem("Service Contract Header", "Service Contract Line", StartDate, EndDate, CreateServOrders);
                if CreateServOrders = CreateServOrders::"Print Only" then begin
                    Clear(ContrServOrdersTest);
                    ContrServOrdersTest.InitVariables(StartDate, EndDate);
                    ContrServOrdersTest.SetTableView("Service Contract Header");
                    ContrServOrdersTest.RunModal();
                    CurrReport.Break();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date for the period that you want to create contract service orders for. The batch job includes contracts with service items that have next planned service dates on or later than this date.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date for the period that you want to create contract service orders for. The batch job includes contracts with service items with next planned service date on or earlier than this date.';

                        trigger OnValidate()
                        begin
                            if EndDate < StartDate then
                                Error(Text003);
                        end;
                    }
                    field(CreateServiceOrders; CreateServOrders)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Create Service Order,Print Only';
                        ToolTip = 'Specifies the desired action relating to contract service orders.';
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
        if ServMgtSetup."Last Contract Service Date" <> 0D then
            StartDate := ServMgtSetup."Last Contract Service Date" + 1;
    end;

    trigger OnPostReport()
    begin
        if CreateServOrders = CreateServOrders::"Create Service Order" then begin
            ServMgtSetup.Get();
            ServMgtSetup."Last Contract Service Date" := EndDate;
            ServMgtSetup.Modify();

            if not HideDialog then
                if ServOrderCreated > 1 then
                    Message(Text000, ServOrderCreated)
                else
                    Message(Text001, ServOrderCreated)
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        Cust: Record Customer;
        ServItem: Record "Service Item";
        Salesperson: Record "Salesperson/Purchaser";
        ContrServOrdersTest: Report "Contr. Serv. Orders - Test";
        ServOrderCreated: Integer;
        StartDate: Date;
        EndDate: Date;
        CreateServOrders: Option "Create Service Order","Print Only";
        ServOrderExist: Boolean;
        HideDialog: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 service orders were created.';
        Text001: Label '%1 service order was created.';
#pragma warning restore AA0470
        Text002: Label 'You must fill in the ending date field.';
        Text003: Label 'The starting date is after the ending date.';
#pragma warning disable AA0470
        Text004: Label 'The date range you have entered is a longer period than is allowed in the %1 table.';
        Text005: Label 'A service order cannot be created for contract no. %1 because customer no. %2 does not have a %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CreateOrAddToServOrder()
    var
        NextLineNo: Integer;
        CreateHeader: Boolean;
    begin
        CreateHeader := ServMgtSetup."One Service Item Line/Order";
        if not CreateHeader then
            CreateHeader := not FindPendingServiceOrderFromContract();

        if CreateHeader then begin
            CreateServiceHeader(ServHeader, "Service Contract Header");
            ServOrderCreated := ServOrderCreated + 1;
        end;

        NextLineNo := 0;
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader."No.");
        if ServItemLine.FindLast() then
            NextLineNo := ServItemLine."Line No."
        else
            NextLineNo := 0;

        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Service Item No.");
        ServItemLine.SetRange("Document Type", ServHeader."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader."No.");
        ServItemLine.SetRange("Contract No.", "Service Contract Line"."Contract No.");
        ServItemLine.SetRange("Contract Line No.", "Service Contract Line"."Line No.");
        OnBeforeFindServiceItemLineOnCreateServiceHeader(ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
        if not ServItemLine.FindFirst() then
            CreateServiceItemLine(ServHeader, "Service Contract Line", NextLineNo);
    end;

    local procedure FindPendingServiceOrderFromContract(): Boolean
    begin
        ServHeader.Reset();
        ServHeader.SetCurrentKey("Contract No.", Status, "Posting Date");
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
        ServHeader.SetRange("Contract No.", "Service Contract Header"."Contract No.");
        ServHeader.SetRange(Status, ServHeader.Status::Pending);
        ServHeader.SetFilter("Order Date", '>=%1', "Service Contract Line"."Next Planned Service Date");
        OnBeforeFindServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
        exit(ServHeader.FindFirst());
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
        Clear(ServiceHeader);
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        OnBeforeInsertServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
        ServiceHeader.Insert(true);
        ServiceHeader.SetHideValidationDialog(true);
        ServiceHeader."Contract No." := ServiceContractHeader."Contract No.";
        ServiceHeader.Validate("Order Date", "Service Contract Line"."Next Planned Service Date");
        ServiceHeader.Validate("Customer No.", ServiceContractHeader."Customer No.");
        ServiceHeader.Validate("Bill-to Customer No.", ServiceContractHeader."Bill-to Customer No.");
        ServiceHeader."Default Response Time (Hours)" := ServiceContractHeader."Response Time (Hours)";
        ServiceHeader.Validate("Ship-to Code", ServiceContractHeader."Ship-to Code");
        ServiceHeader."Service Order Type" := ServiceContractHeader."Service Order Type";
        ServiceHeader.Validate("Currency Code", ServiceContractHeader."Currency Code");
        SetSalespersonCode(ServiceContractHeader."Salesperson Code", ServiceHeader."Salesperson Code");
        ServiceHeader."Max. Labor Unit Price" := ServiceContractHeader."Max. Labor Unit Price";
        ServiceHeader."Your Reference" := ServiceContractHeader."Your Reference";
        ServiceHeader."Service Zone Code" := ServiceContractHeader."Service Zone Code";
        ServiceHeader."Shortcut Dimension 1 Code" := ServiceContractHeader."Shortcut Dimension 1 Code";
        ServiceHeader."Shortcut Dimension 2 Code" := ServiceContractHeader."Shortcut Dimension 2 Code";
        ServiceHeader.Validate("Service Order Type", ServiceContractHeader."Service Order Type");
        ServiceHeader."Dimension Set ID" := ServiceContractHeader."Dimension Set ID";
        OnBeforeModifyServiceHeader(ServHeader, "Service Contract Header", "Service Contract Line");
        ServiceHeader.Modify(true);
        OnAfterCreateServiceHeader(ServiceHeader, ServiceContractHeader);
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header"; ServiceContractLine: Record "Service Contract Line"; var NextLineNo: Integer)
    var
        RepairStatus: Record "Repair Status";
    begin
        ServItemLine.Init();
        ServItemLine.SetHideDialogBox(true);
        ServItemLine."Document No." := ServiceHeader."No.";
        ServItemLine."Document Type" := ServiceHeader."Document Type";
        RepairStatus.Reset();
        RepairStatus.Initial := true;
        ServItemLine."Repair Status Code" := RepairStatus.ReturnStatusCode(RepairStatus);
        NextLineNo := NextLineNo + 10000;
        ServItemLine."Line No." := NextLineNo;
        if "Service Contract Line"."Service Item No." <> '' then begin
            ServItem.Get("Service Contract Line"."Service Item No.");
            ServItemLine.Validate("Service Item No.", ServItem."No.");
            ServItemLine."Location of Service Item" := ServItem."Location of Service Item";
            ServItemLine.Priority := ServItem.Priority;
        end else
            ServItemLine.Description := "Service Contract Line".Description;
        ServItemLine."Serial No." := "Service Contract Line"."Serial No.";
        ServItemLine."Item No." := "Service Contract Line"."Item No.";
        ServItemLine."Variant Code" := "Service Contract Line"."Variant Code";
        ServItemLine."Contract No." := "Service Contract Line"."Contract No.";
        ServItemLine."Contract Line No." := "Service Contract Line"."Line No.";
        ServItemLine.UpdateResponseTimeHours();
        OnBeforeInsertServiceItemLine(ServItemLine, ServHeader, "Service Contract Header", "Service Contract Line");
        ServItemLine.Insert(true);

        OnAfterInsertServItemLine(ServItemLine, ServiceContractLine);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure InitializeRequest(StartDateFrom: Date; EndDateFrom: Date; CreateServOrdersFrom: Option)
    begin
        StartDate := StartDateFrom;
        EndDate := EndDateFrom;
        CreateServOrders := CreateServOrdersFrom;
    end;

    local procedure VerifyServiceContractHeader()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if "Service Contract Header"."Ship-to Code" <> '' then
            if not ShipToAddress.Get("Service Contract Header"."Customer No.", "Service Contract Header"."Ship-to Code") then begin
                Message(Text005, "Service Contract Header"."Contract No.", "Service Contract Header"."Customer No.", "Service Contract Header"."Ship-to Code");
                CurrReport.Skip();
            end;
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck <> '' then
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    SalesPersonCodeToAssign := ''
                else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderPreDataItem(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; StartDate: Date; EndDate: Date; CreateServOrders: Option "Create Service Order","Print Only")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceContractHeaderPostDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyServiceHeader(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceItemLineOnServiceContractLineAfterGetRecord(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceItemLineOnCreateServiceHeader(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

