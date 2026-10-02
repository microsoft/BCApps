// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.TestLibraries.DynamicsFieldService;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Integration.SyncEngine;
using Microsoft.Service.Archive;
using Microsoft.Service.Document;

codeunit 139205 "FS Integration Test Library"
{
    EventSubscriberInstance = Manual;

    var
        SynchronizationCandidates: List of [RecordId];
        EmptySynchronizationRequests: Integer;
        UnchangedServiceOrders: Integer;

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
    /// Retained for compatibility. Service items are now always synchronized to Field Service customer assets, so this procedure leaves the synchronization decision unchanged.
    /// </summary>
    /// <param name="SourceRecordRef">A reference to the service item to evaluate.</param>
    /// <param name="IgnoreRecord">The existing synchronization decision, which is left unchanged.</param>
#pragma warning disable AS0105
    [Obsolete('Remove calls to this procedure. Service items are always synchronized to Field Service customer assets; item-product synchronization disables customer asset conversion.', '30.0')]
    procedure IgnoreServiceItemsByConvertToCustomerAssetFlag(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;
#pragma warning restore AS0105

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

    procedure ClearSynchronizationCandidates()
    begin
        Clear(SynchronizationCandidates);
        EmptySynchronizationRequests := 0;
        UnchangedServiceOrders := 0;
    end;

    procedure WasSelectedForSynchronization(CandidateRecordId: RecordId): Boolean
    begin
        exit(SynchronizationCandidates.Contains(CandidateRecordId));
    end;

    procedure GetSynchronizationCandidateCount(TableId: Integer) CandidateCount: Integer
    var
        CandidateRecordId: RecordId;
    begin
        foreach CandidateRecordId in SynchronizationCandidates do
            if CandidateRecordId.TableNo() = TableId then
                CandidateCount += 1;
    end;

    procedure GetEmptySynchronizationRequestCount(): Integer
    begin
        exit(EmptySynchronizationRequests);
    end;

    procedure GetUnchangedServiceOrderCount(): Integer
    begin
        exit(UnchangedServiceOrders);
    end;

    local procedure CaptureSynchronizationCandidates(var RecordsToSynchRecordRef: RecordRef)
    begin
        // Observe the production-selected set without applying any mapping filters in the test.
        if RecordsToSynchRecordRef.FindSet() then
            repeat
                SynchronizationCandidates.Add(RecordsToSynchRecordRef.RecordId());
            until RecordsToSynchRecordRef.Next() = 0
        else
            EmptySynchronizationRequests += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnBeforeSynchRecordsFromIntegrationTable', '', false, false)]
    local procedure CaptureAuxiliaryImport(var RecordsToSynchRecordRef: RecordRef; var IsHandled: Boolean)
    begin
        if not (RecordsToSynchRecordRef.Number() in
                [Database::"FS Work Order Incident", Database::"FS Work Order Product",
                 Database::"FS Work Order Service", Database::"FS Bookable Resource Booking"]) then
            exit;

        CaptureSynchronizationCandidates(RecordsToSynchRecordRef);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnBeforeSynchRecordsToIntegrationTable', '', false, false)]
    local procedure CaptureAuxiliaryExport(var RecordsToSynchRecordRef: RecordRef; var IsHandled: Boolean)
    begin
        if not (RecordsToSynchRecordRef.Number() in [Database::"Service Header", Database::"Service Item Line"]) then
            exit;

        CaptureSynchronizationCandidates(RecordsToSynchRecordRef);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Table Synch.", 'OnBeforeSynchronize', '', false, false)]
    local procedure CaptureServiceLineExport(var SourceRecordRef: RecordRef; var IsHandled: Boolean)
    begin
        case SourceRecordRef.Number() of
            Database::"Service Line":
                begin
                    SynchronizationCandidates.Add(SourceRecordRef.RecordId());
                    IsHandled := true;
                end;
            Database::"Service Header":
                // Scheduled header tests observe the auxiliary record-set call, not the initial pass.
                IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeIgnoreUnchangedRecordHandled', '', false, false)]
    local procedure CaptureUnchangedServiceOrder(SourceRecordRef: RecordRef)
    begin
        if SourceRecordRef.Number() in [Database::"Service Header", Database::"FS Work Order"] then
            UnchangedServiceOrders += 1;
    end;
}