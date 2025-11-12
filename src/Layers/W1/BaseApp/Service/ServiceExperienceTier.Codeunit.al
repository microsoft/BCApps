// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Ledger;
using Microsoft.Service.Contract;
using Microsoft.Service.Posting;
using Microsoft.Service.Email;
using Microsoft.Service.History;

codeunit 5999 "Service Experience Tier"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        ServiceExperienceTier: Codeunit "Service Experience Tier";
        CannotInsertErr: Label 'You cannot insert into table %1. Premium features are blocked since you are accessing a non-premium company.', Comment = '%1 - Table caption';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Experience Tier", 'OnCheckExperienceTierForUserPlanPremium', '', false, false)]
    local procedure OnCheckExperienceTierForUserPlanPremium()
    begin
        BindSubscription(ServiceExperienceTier);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHeader(RunTrigger: Boolean; var Rec: Record "Service Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLine(RunTrigger: Boolean; var Rec: Record "Service Item Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLine(RunTrigger: Boolean; var Rec: Record "Service Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Type", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderType(RunTrigger: Boolean; var Rec: Record "Service Order Type")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemGroup(RunTrigger: Boolean; var Rec: Record "Service Item Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCost(RunTrigger: Boolean; var Rec: Record "Service Cost")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCommentLine(RunTrigger: Boolean; var Rec: Record "Service Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLedgerEntry(RunTrigger: Boolean; var Rec: Record "Service Ledger Entry")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Hour", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHour(RunTrigger: Boolean; var Rec: Record "Service Hour")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Document Log", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceDocumentLog(RunTrigger: Boolean; var Rec: Record "Service Document Log")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Status Priority Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceStatusPrioritySetup(RunTrigger: Boolean; var Rec: Record "Service Status Priority Setup")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shelf", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShelf(RunTrigger: Boolean; var Rec: Record "Service Shelf")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Posting Buffer", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderPostingBuffer(RunTrigger: Boolean; var Rec: Record "Service Order Posting Buffer")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Register", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceRegister(RunTrigger: Boolean; var Rec: Record "Service Register")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Email Queue", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceEmailQueue(RunTrigger: Boolean; var Rec: Record "Service Email Queue")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Document Register", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceDocumentRegister(RunTrigger: Boolean; var Rec: Record "Service Document Register")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItem(RunTrigger: Boolean; var Rec: Record "Service Item")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Component", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemComponent(RunTrigger: Boolean; var Rec: Record "Service Item Component")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Log", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLog(RunTrigger: Boolean; var Rec: Record "Service Item Log")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Allocation", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderAllocation(RunTrigger: Boolean; var Rec: Record "Service Order Allocation")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Zone", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceZone(RunTrigger: Boolean; var Rec: Record "Service Zone")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractLine(RunTrigger: Boolean; var Rec: Record "Service Contract Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractHeader(RunTrigger: Boolean; var Rec: Record "Service Contract Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Template", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractTemplate(RunTrigger: Boolean; var Rec: Record "Service Contract Template")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Filed Service Contract Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFiledServiceContractHeader(RunTrigger: Boolean; var Rec: Record "Filed Service Contract Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contract/Service Discount", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertContractServiceDiscount(RunTrigger: Boolean; var Rec: Record "Contract/Service Discount")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Account Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractAccountGroup(RunTrigger: Boolean; var Rec: Record "Service Contract Account Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Item Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentItemLine(RunTrigger: Boolean; var Rec: Record "Service Shipment Item Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentHeader(RunTrigger: Boolean; var Rec: Record "Service Shipment Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentLine(RunTrigger: Boolean; var Rec: Record "Service Shipment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceInvoiceHeader(RunTrigger: Boolean; var Rec: Record "Service Invoice Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceInvoiceLine(RunTrigger: Boolean; var Rec: Record "Service Invoice Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCrMemoHeader(RunTrigger: Boolean; var Rec: Record "Service Cr.Memo Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCrMemoLine(RunTrigger: Boolean; var Rec: Record "Service Cr.Memo Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Price Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServicePriceGroup(RunTrigger: Boolean; var Rec: Record "Service Price Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Serv. Price Group Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServPriceGroupSetup(RunTrigger: Boolean; var Rec: Record "Serv. Price Group Setup")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Price Adjustment Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServicePriceAdjustmentGroup(RunTrigger: Boolean; var Rec: Record "Service Price Adjustment Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Serv. Price Adjustment Detail", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServPriceAdjustmentDetail(RunTrigger: Boolean; var Rec: Record "Serv. Price Adjustment Detail")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line Price Adjmt.", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLinePriceAdjmt(RunTrigger: Boolean; var Rec: Record "Service Line Price Adjmt.")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHeaderArchive(RunTrigger: Boolean; var Rec: Record "Service Header Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLineArchive(RunTrigger: Boolean; var Rec: Record "Service Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Comment Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCommentLineArchive(RunTrigger: Boolean; var Rec: Record "Service Comment Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLineArchive(RunTrigger: Boolean; var Rec: Record "Service Item Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Allocat. Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderAllocArchive(RunTrigger: Boolean; var Rec: Record "Service Order Allocat. Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;
}