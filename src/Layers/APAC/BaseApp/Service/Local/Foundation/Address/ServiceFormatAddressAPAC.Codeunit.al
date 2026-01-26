// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 28042 "Service Format Address APAC"
{
    var
        FormatAddress: Codeunit "Format Address";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceOrderSellto', '', false, false)]
    local procedure OnAfterServiceOrderSellto(var ServHeader: Record "Service Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Header", ServHeader.GetPosition(), 3,
          ServHeader."Customer No.", ServHeader."Shortcut Dimension 1 Code", ServHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceOrderShipto', '', false, false)]
    local procedure OnAfterServiceOrderShipto(var ServHeader: Record "Service Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Header", ServHeader.GetPosition(), 2,
          ServHeader."Ship-to Code", ServHeader."Shortcut Dimension 1 Code", ServHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServContractSellto', '', false, false)]
    local procedure OnAfterServContractSellto(var ServiceContractHeader: Record "Service Contract Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Contract Header", ServiceContractHeader.GetPosition(), 3,
          ServiceContractHeader."Customer No.", ServiceContractHeader."Shortcut Dimension 1 Code", ServiceContractHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServContractShipTo', '', false, false)]
    local procedure OnAfterServContractShipTo(var ServiceContractHeader: Record "Service Contract Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Contract Header", ServiceContractHeader.GetPosition(), 2,
          ServiceContractHeader."Ship-to Code", ServiceContractHeader."Shortcut Dimension 1 Code", ServiceContractHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceInvBillTo', '', false, false)]
    local procedure OnAfterServiceInvBillTo(var ServiceInvHeader: Record "Service Invoice Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Invoice Header", ServiceInvHeader.GetPosition(), 1,
          ServiceInvHeader."Bill-to Customer No.", ServiceInvHeader."Shortcut Dimension 1 Code", ServiceInvHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceInvShipTo', '', false, false)]
    local procedure OnAfterServiceInvShipTo(var ServiceInvHeader: Record "Service Invoice Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Invoice Header", ServiceInvHeader.GetPosition(), 2,
          ServiceInvHeader."Ship-to Code", ServiceInvHeader."Shortcut Dimension 1 Code", ServiceInvHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceShptShipTo', '', false, false)]
    local procedure OnAfterServiceShptShipTo(var ServiceShptHeader: Record "Service Shipment Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Shipment Header", ServiceShptHeader.GetPosition(), 2,
          ServiceShptHeader."Ship-to Code", ServiceShptHeader."Shortcut Dimension 1 Code", ServiceShptHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceShptSellTo', '', false, false)]
    local procedure OnAfterServiceShptSellTo(var ServiceShptHeader: Record "Service Shipment Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Shipment Header", ServiceShptHeader.GetPosition(), 3,
          ServiceShptHeader."Customer No.", ServiceShptHeader."Shortcut Dimension 1 Code", ServiceShptHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceShptBillTo', '', false, false)]
    local procedure OnAfterServiceShptBillTo(var ServiceShptHeader: Record "Service Shipment Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Shipment Header", ServiceShptHeader.GetPosition(), 1,
          ServiceShptHeader."Bill-to Customer No.", ServiceShptHeader."Shortcut Dimension 1 Code", ServiceShptHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceCrMemoBillTo', '', false, false)]
    local procedure OnAfterServiceCrMemoBillTo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader.GetPosition(), 1,
          ServiceCrMemoHeader."Bill-to Customer No.", ServiceCrMemoHeader."Shortcut Dimension 1 Code", ServiceCrMemoHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceCrMemoShipTo', '', false, false)]
    local procedure OnAfterServiceCrMemoShipTo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Cr.Memo Header", ServiceCrMemoHeader.GetPosition(), 2,
          ServiceCrMemoHeader."Ship-to Code", ServiceCrMemoHeader."Shortcut Dimension 1 Code", ServiceCrMemoHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceHeaderSellTo', '', false, false)]
    local procedure OnAfterServiceHeaderSellTo(var ServiceHeader: Record "Service Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Header", ServiceHeader.GetPosition(), 3,
          ServiceHeader."Customer No.", ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceHeaderBillTo', '', false, false)]
    local procedure OnAfterServiceHeaderBillTo(var ServiceHeader: Record "Service Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Header", ServiceHeader.GetPosition(), 1,
          ServiceHeader."Bill-to Customer No.", ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Format Address", 'OnAfterServiceHeaderShipTo', '', false, false)]
    local procedure OnAfterServiceHeaderShipTo(var ServiceHeader: Record "Service Header")
    begin
        FormatAddress.CreateBarCode(
          DATABASE::"Service Header", ServiceHeader.GetPosition(), 2,
          ServiceHeader."Ship-to Code", ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code");
    end;
}