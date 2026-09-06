// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.TestLibraries.DynamicsFieldService;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Inventory.Item;
using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.Item;

codeunit 139205 "FS Integration Test Library"
{
    procedure RegisterConnection(var FSConnectionSetup: Record "FS Connection Setup")
    begin
        FSConnectionSetup.RegisterConnection();
    end;

    procedure UnregisterConnection(var FSConnectionSetup: Record "FS Connection Setup")
    begin
        FSConnectionSetup.UnregisterConnection();
    end;

    procedure SetPassword(var FSConnectionSetup: Record "FS Connection Setup"; Password: SecretText)
    begin
        FSConnectionSetup.SetPassword(Password);
    end;

    procedure PerformTestConnection(var FSConnectionSetup: Record "FS Connection Setup")
    begin
        FSConnectionSetup.PerformTestConnection();
    end;

    procedure ResetConfiguration(var FSConnectionSetup: Record "FS Connection Setup")
    var
        FSSetupDefaults: Codeunit "FS Setup Defaults";
    begin
        FSSetupDefaults.ResetConfiguration(FSConnectionSetup);
    end;

    procedure UpdateQuantities(FSWorkOrderProduct: Record "FS Work Order Product"; var ServiceLine: Record "Service Line"; ToFieldService: Boolean)
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.UpdateQuantities(FSWorkOrderProduct, ServiceLine, ToFieldService);
    end;

    procedure UpdateQuantities(FSWorkOrderService: Record "FS Work Order Service"; var ServiceLine: Record "Service Line"; ToFieldService: Boolean)
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.UpdateQuantities(FSWorkOrderService, ServiceLine, ToFieldService);
    end;

    procedure UpdateQuantities(FSBookableResourceBooking: Record "FS Bookable Resource Booking"; var ServiceLine: Record "Service Line")
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.UpdateQuantities(FSBookableResourceBooking, ServiceLine);
    end;

    procedure IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.IgnorePostedJobJournalLinesOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    procedure IgnoreArchievedServiceOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.IgnoreArchievedServiceOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    procedure IgnoreArchievedCRMWorkOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.IgnoreArchievedCRMWorkOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    /// <summary>
    /// Applies the legacy service item filter based on the coupled CRM product's Convert to Customer Asset flag. This filter is obsolete because service items are now always synchronized to Field Service customer assets.
    /// </summary>
    /// <param name="SourceRecordRef">A reference to the service item to evaluate.</param>
    /// <param name="IgnoreRecord">Set to true when the service item should be ignored according to the legacy filter.</param>
    [Obsolete('Remove calls to this procedure. Service items are always synchronized to Field Service customer assets; item-product synchronization disables customer asset conversion.', '30.0')]
    procedure IgnoreServiceItemsByConvertToCustomerAssetFlag(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        FSConnectionSetup: Record "FS Connection Setup";
        ServiceItem: Record "Service Item";
        Item: Record Item;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
    begin
        if not FSConnectionSetup.IsEnabled() then
            exit;

        if IgnoreRecord then
            exit;

        SourceRecordRef.SetTable(ServiceItem);
        if ServiceItem."Item No." = '' then
            exit;

        if CRMIntegrationRecord.FindByRecordID(ServiceItem.RecordId) then
            exit;

        if not Item.Get(ServiceItem."Item No.") then
            exit;

        if not CRMIntegrationRecord.FindByRecordID(Item.RecordId) then
            exit;

        if not CRMProduct.Get(CRMIntegrationRecord."CRM ID") then
            exit;

        if not CRMProduct.ConvertToCustomerAsset then
            IgnoreRecord := true;
    end;

    procedure MarkArchivedServiceOrder(ServiceHeader: Record "Service Header")
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.MarkArchivedServiceOrder(ServiceHeader);
    end;

    procedure MarkArchivedServiceOrderLine(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive")
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.MarkArchivedServiceOrderLine(ServiceLine, ServiceLineArchive);
    end;

    procedure ArchiveServiceOrder(ServiceHeader: Record "Service Header"; ArchivedServiceOrders: List of [Code[20]])
    var
        FSIntTableSubscriber: Codeunit "FS Int. Table Subscriber";
    begin
        FSIntTableSubscriber.ArchiveServiceOrder(ServiceHeader, ArchivedServiceOrders);
    end;

    procedure UpdateWorkOrderProduct(SalesLineArchive: Record "Service Line Archive"; var FSWorkOrderProduct: Record "FS Work Order Product")
    var
        FSArchivedServiceOrdersJob: Codeunit "FS Archived Service Orders Job";
    begin
        FSArchivedServiceOrdersJob.UpdateWorkOrderProduct(SalesLineArchive, FSWorkOrderProduct);
    end;

    procedure UpdateWorkOrderService(SalesLineArchive: Record "Service Line Archive"; var FSWorkOrderService: Record "FS Work Order Service")
    var
        FSArchivedServiceOrdersJob: Codeunit "FS Archived Service Orders Job";
    begin
        FSArchivedServiceOrdersJob.UpdateWorkOrderService(SalesLineArchive, FSWorkOrderService);
    end;
}