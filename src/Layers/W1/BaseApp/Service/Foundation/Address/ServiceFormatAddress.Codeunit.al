// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Service.Document;
using Microsoft.Service.Contract;
using Microsoft.Service.History;

codeunit 6001 "Service Format Address"
{
    var
        FormatAddress: Codeunit "Format Address";

    procedure ServiceOrderSellto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceOrderSellto(AddrArray, ServHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceOrderSellto(AddrArray, ServHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServHeader.Name, ServHeader."Name 2", ServHeader."Contact Name", ServHeader.Address, ServHeader."Address 2",
            ServHeader.City, ServHeader."Post Code", ServHeader.County, ServHeader."Country/Region Code");

        OnAfterServiceOrderSellto(AddrArray, ServHeader);
    end;

    procedure ServiceOrderShipto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceOrderShipto(AddrArray, ServHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceOrderShipto(AddrArray, ServHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServHeader."Ship-to Name", ServHeader."Ship-to Name 2", ServHeader."Ship-to Contact", ServHeader."Ship-to Address", ServHeader."Ship-to Address 2",
            ServHeader."Ship-to City", ServHeader."Ship-to Post Code", ServHeader."Ship-to County", ServHeader."Ship-to Country/Region Code");

        OnAfterServiceOrderShipto(AddrArray, ServHeader);
    end;

    procedure ServContractSellto(var AddrArray: array[8] of Text[100]; ServContract: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServContractSellto(AddrArray, ServContract, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServContractSellto(AddrArray, ServContract, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServContract."Language Code");
        ServContract.CalcFields(Name, "Name 2", Address, "Address 2", "Post Code", City, County, "Country/Region Code");
        FormatAddress.FormatAddr(
          AddrArray, ServContract.Name, ServContract."Name 2", ServContract."Contact Name", ServContract.Address, ServContract."Address 2",
          ServContract.City, ServContract."Post Code", ServContract.County, ServContract."Country/Region Code");

        OnAfterServContractSellto(AddrArray, ServContract);
    end;

    procedure ServContractShipto(var AddrArray: array[8] of Text[100]; ServiceContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        ServiceContractHeader.CalcFields(
            "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2",
            "Ship-to Post Code", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code");

        IsHandled := false;
        OnBeforeServContractShipTo(AddrArray, ServiceContractHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServContractShipTo(AddrArray, ServiceContractHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceContractHeader."Language Code");
        FormatAddress.FormatAddr(
          AddrArray, ServiceContractHeader."Ship-to Name", ServiceContractHeader."Ship-to Name 2", ServiceContractHeader."Contact Name", ServiceContractHeader."Ship-to Address", ServiceContractHeader."Ship-to Address 2",
          ServiceContractHeader."Ship-to City", ServiceContractHeader."Ship-to Post Code", ServiceContractHeader."Ship-to County", ServiceContractHeader."Ship-to Country/Region Code");

        OnAfterServContractShipTo(AddrArray, ServiceContractHeader);
    end;

    procedure ServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvBillTo(AddrArray, ServiceInvHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceInvBillTo(AddrArray, ServiceInvHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceInvHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceInvHeader."Bill-to Name", ServiceInvHeader."Bill-to Name 2", ServiceInvHeader."Bill-to Contact", ServiceInvHeader."Bill-to Address", ServiceInvHeader."Bill-to Address 2",
            ServiceInvHeader."Bill-to City", ServiceInvHeader."Bill-to Post Code", ServiceInvHeader."Bill-to County", ServiceInvHeader."Bill-to Country/Region Code");

        OnAfterServiceInvBillTo(AddrArray, ServiceInvHeader);
    end;

    procedure ServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
        i: Integer;
    begin
        IsHandled := false;
        OnBeforeServiceInvShipTo(AddrArray, CustAddr, ServiceInvHeader, IsHandled, Result);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceInvShipTo(AddrArray, CustAddr, ServiceInvHeader, IsHandled, Result);
#endif
        if IsHandled then
            exit(Result);

        FormatAddress.SetLanguageCode(ServiceInvHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceInvHeader."Ship-to Name", ServiceInvHeader."Ship-to Name 2", ServiceInvHeader."Ship-to Contact", ServiceInvHeader."Ship-to Address", ServiceInvHeader."Ship-to Address 2",
            ServiceInvHeader."Ship-to City", ServiceInvHeader."Ship-to Post Code", ServiceInvHeader."Ship-to County", ServiceInvHeader."Ship-to Country/Region Code");

        OnAfterServiceInvShipTo(AddrArray, CustAddr, ServiceInvHeader);

        if ServiceInvHeader."Customer No." <> ServiceInvHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptShipTo(AddrArray, ServiceShptHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceShptShipTo(AddrArray, ServiceShptHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceShptHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceShptHeader."Ship-to Name", ServiceShptHeader."Ship-to Name 2", ServiceShptHeader."Ship-to Contact", ServiceShptHeader."Ship-to Address", ServiceShptHeader."Ship-to Address 2",
            ServiceShptHeader."Ship-to City", ServiceShptHeader."Ship-to Post Code", ServiceShptHeader."Ship-to County", ServiceShptHeader."Ship-to Country/Region Code");

        OnAfterServiceShptShipTo(AddrArray, ServiceShptHeader);
    end;

    procedure ServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptSellTo(AddrArray, ServiceShptHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceShptSellTo(AddrArray, ServiceShptHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceShptHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceShptHeader.Name, ServiceShptHeader."Name 2", ServiceShptHeader."Contact Name", ServiceShptHeader.Address, ServiceShptHeader."Address 2",
            ServiceShptHeader.City, ServiceShptHeader."Post Code", ServiceShptHeader.County, ServiceShptHeader."Country/Region Code");

        OnAfterServiceShptSellTo(AddrArray, ServiceShptHeader);
    end;

    procedure ServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
        i: Integer;
    begin
        IsHandled := false;
        OnBeforeServiceShptBillTo(AddrArray, ShipToAddr, ServiceShptHeader, IsHandled, Result);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceShptBillTo(AddrArray, ShipToAddr, ServiceShptHeader, IsHandled, Result);
#endif
        if IsHandled then
            exit(Result);

        FormatAddress.SetLanguageCode(ServiceShptHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceShptHeader."Bill-to Name", ServiceShptHeader."Bill-to Name 2", ServiceShptHeader."Bill-to Contact", ServiceShptHeader."Bill-to Address", ServiceShptHeader."Bill-to Address 2",
            ServiceShptHeader."Bill-to City", ServiceShptHeader."Bill-to Post Code", ServiceShptHeader."Bill-to County", ServiceShptHeader."Bill-to Country/Region Code");

        OnAfterServiceShptBillTo(AddrArray, ShipToAddr, ServiceShptHeader);

        if ServiceShptHeader."Bill-to Customer No." <> ServiceShptHeader."Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if ShipToAddr[i] <> AddrArray[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceCrMemoBillTo(AddrArray, ServiceCrMemoHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceCrMemoBillTo(AddrArray, ServiceCrMemoHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceCrMemoHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceCrMemoHeader."Bill-to Name", ServiceCrMemoHeader."Bill-to Name 2", ServiceCrMemoHeader."Bill-to Contact", ServiceCrMemoHeader."Bill-to Address", ServiceCrMemoHeader."Bill-to Address 2",
            ServiceCrMemoHeader."Bill-to City", ServiceCrMemoHeader."Bill-to Post Code", ServiceCrMemoHeader."Bill-to County", ServiceCrMemoHeader."Bill-to Country/Region Code");

        OnAfterServiceCrMemoBillTo(AddrArray, ServiceCrMemoHeader);
    end;

    procedure ServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
        i: Integer;
    begin
        IsHandled := false;
        OnBeforeServiceCrMemoShipTo(AddrArray, CustAddr, ServiceCrMemoHeader, IsHandled, Result);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceCrMemoShipTo(AddrArray, CustAddr, ServiceCrMemoHeader, IsHandled, Result);
#endif
        if IsHandled then
            exit(Result);

        FormatAddress.SetLanguageCode(ServiceCrMemoHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceCrMemoHeader."Ship-to Name", ServiceCrMemoHeader."Ship-to Name 2", ServiceCrMemoHeader."Ship-to Contact", ServiceCrMemoHeader."Ship-to Address", ServiceCrMemoHeader."Ship-to Address 2",
            ServiceCrMemoHeader."Ship-to City", ServiceCrMemoHeader."Ship-to Post Code", ServiceCrMemoHeader."Ship-to County", ServiceCrMemoHeader."Ship-to Country/Region Code");

        OnAfterServiceCrMemoShipTo(AddrArray, CustAddr, ServiceCrMemoHeader);

        if ServiceCrMemoHeader."Customer No." <> ServiceCrMemoHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderSellTo(AddrArray, ServiceHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceHeaderSellTo(AddrArray, ServiceHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceHeader.Name, ServiceHeader."Name 2", ServiceHeader."Contact Name", ServiceHeader.Address, ServiceHeader."Address 2",
            ServiceHeader.City, ServiceHeader."Post Code", ServiceHeader.County, ServiceHeader."Country/Region Code");

        OnAfterServiceHeaderSellTo(AddrArray, ServiceHeader);
    end;

    procedure ServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderBillTo(AddrArray, ServiceHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceHeaderBillTo(AddrArray, ServiceHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceHeader."Bill-to Name", ServiceHeader."Bill-to Name 2", ServiceHeader."Bill-to Contact", ServiceHeader."Bill-to Address", ServiceHeader."Bill-to Address 2",
            ServiceHeader."Bill-to City", ServiceHeader."Bill-to Post Code", ServiceHeader."Bill-to County", ServiceHeader."Bill-to Country/Region Code");

        OnAfterServiceHeaderBillTo(AddrArray, ServiceHeader);
    end;

    procedure ServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderShipTo(AddrArray, ServiceHeader, IsHandled);
#if not CLEAN25
        FormatAddress.RunOnBeforeServiceHeaderShipTo(AddrArray, ServiceHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        FormatAddress.SetLanguageCode(ServiceHeader."Language Code");
        FormatAddress.FormatAddr(
            AddrArray, ServiceHeader."Ship-to Name", ServiceHeader."Ship-to Name 2", ServiceHeader."Ship-to Contact", ServiceHeader."Ship-to Address", ServiceHeader."Ship-to Address 2",
            ServiceHeader."Ship-to City", ServiceHeader."Ship-to Post Code", ServiceHeader."Ship-to County", ServiceHeader."Ship-to Country/Region Code");

        OnAfterServiceHeaderShipTo(AddrArray, ServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceOrderSellto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceOrderSellto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceOrderShipto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceOrderShipto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServContractSellto(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractSellto(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServContractShipTo(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractShipTo(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}
