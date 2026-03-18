// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Service.Document;
using Microsoft.Warehouse.Document;

reportextension 5753 "Serv. Get Source Documents" extends "Get Source Documents"
{
    dataset
    {
        addafter("Transfer Header")
        {
            dataitem("Service Header"; "Service Header")
            {
                DataItemLink = "Document Type" = field("Source Subtype"), "No." = field("Source No.");
                DataItemTableView = sorting("Document Type", "No.");
                dataitem("Service Line"; "Service Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeServiceLineOnAfterGetRecord("Service Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if ("Location Code" = "Warehouse Request"."Location Code") and IsInventoriableItem() then
                            case RequestType of
                                RequestType::Ship:
                                    if ServiceWarehouseMgt.CheckIfFromServiceLine2ShptLine("Service Line", ReservedFromStock) then begin
                                        IsHandled := false;
                                        OnServiceLineOnAfterGetRecordOnBeforeCreateShptHeader("Service Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated, IsHandled);
                                        if not IsHandled then begin
                                            if not OneHeaderCreated and not WhseHeaderCreated then
                                                CreateShptHeader();
                                            if not ServiceWarehouseMgt.FromServiceLine2ShptLine(WhseShptHeader, "Service Line") then
                                                ErrorOccured := true;
                                            LineCreated := true;
                                        end;
                                    end;
                            end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Type, Type::Item);
                        if (("Warehouse Request".Type = "Warehouse Request".Type::Outbound) and
                            ("Warehouse Request"."Source Document" = "Warehouse Request"."Source Document"::"Service Order"))
                        then
                            SetFilter("Outstanding Quantity", '>0')
                        else
                            SetFilter("Outstanding Quantity", '<0');
                        SetRange("Job No.", '');

                        OnAfterServiceLineOnPreDataItem("Service Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;

                    trigger OnPostDataItem()
                    begin
                        OnAfterProcessServiceLine(WhseShptHeader, "Warehouse Request", LineCreated, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TestField("Bill-to Customer No.");
                    Customer.Get("Bill-to Customer No.");
                    if not SkipBlockedCustomer then
                        Customer.CheckBlockedCustOnDocs(Customer, "Document Type", false, false)
                    else
                        if Customer.Blocked <> Customer.Blocked::" " then
                            CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> Database::"Service Line" then
                        CurrReport.Break();
                end;
            }
        }
    }

    [IntegrationEvent(true, false)]
    local procedure OnAfterServiceLineOnPreDataItem(var ServiceLine: Record "Service Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessServiceLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; var LineCreated: Boolean; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineOnAfterGetRecord(ServiceLine: Record "Service Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceLineOnAfterGetRecordOnBeforeCreateShptHeader(ServiceLine: Record "Service Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean; var IsHandled: Boolean)
    begin
    end;
}
