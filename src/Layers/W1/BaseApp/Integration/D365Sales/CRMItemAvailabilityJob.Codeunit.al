// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5356 "CRM Item Availability Job"
{
    trigger OnRun()
    begin
        CheckItemLedgerEntries();
    end;

    var
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        StartingToRefreshItemAvailabilityMsg: Label 'Starting to refresh item availability based on item ledger entry activity.', Locked = true;
        ScheduledItemSyncJobForSelectedRecordsMsg: Label 'Scheduled item sync job for selected records.', Locked = true;
        FinishedRefreshingItemAvailabilityMsg: Label 'Finished refreshing item availability based on item ledger entry activity.', Locked = true;
        TelemetryCategoryTok: Label 'AL CRM Integration';

    local procedure CheckItemLedgerEntries()
    var
        Item: Record Item;
        CRMSynchStatus: Record "CRM Synch Status";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMProductName: Codeunit "CRM Product Name";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ItemNumber: Code[20];
        NewItemAvailabilitySynchTime: DateTime;
        ItemNumbers: List of [Code[20]];
        CRMIdList: List of [Guid];
        BCIdList: List of [Guid];
        IdDictionary: Dictionary of [Guid, Guid];
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        if CRMSynchStatus.Get() then begin
            NewItemAvailabilitySynchTime := CurrentDateTime();
            Session.LogMessage('0000E44', StartingToRefreshItemAvailabilityMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            AddItemsWithLedgerEntryActivity(CRMSynchStatus."Item Availability Synch. Time", ItemNumbers);

            foreach ItemNumber in ItemNumbers do
                if Item.Get(ItemNumber) then begin
                    CRMIntegrationRecord.Reset();
                    CRMIntegrationRecord.SetRange("Table ID", Database::Item);
                    CRMIntegrationRecord.SetRange(Skipped, false);
                    CRMIntegrationRecord.SetRange("Integration ID", Item.SystemId);
                    if CRMIntegrationRecord.FindFirst() then
                        if not IdDictionary.ContainsKey(CRMIntegrationRecord."CRM ID") then
                            IdDictionary.Add(CRMIntegrationRecord."CRM ID", Item.SystemId);
                end;

            CRMIdList := IdDictionary.Keys();
            if CRMIdList.Count() > 0 then begin
                IntegrationTableMapping.Get('ITEM-PRODUCT');
                BCIdList := IdDictionary.Values();
                CRMIntegrationManagement.EnqueueSyncJob(IntegrationTableMapping, BCIdList, CRMIdList, IntegrationTableMapping.Direction, IntegrationTableMapping."Synch. Only Coupled Records");
                Session.LogMessage('0000E45', ScheduledItemSyncJobForSelectedRecordsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            end;

            CRMSynchStatus."Item Availability Synch. Time" := NewItemAvailabilitySynchTime;
            CRMSynchStatus.Modify();
            Session.LogMessage('0000E46', FinishedRefreshingItemAvailabilityMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        end;
    end;

    local procedure AddItemsWithLedgerEntryActivity(StartDateTime: DateTime; var ItemNumbers: List of [Code[20]]);
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if StartDateTime = 0DT then begin
            IntegrationTableMapping.Get('ITEM-PRODUCT');
            StartDateTime := IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.";
        end;

        ItemLedgerEntry.SetFilter(SystemModifiedAt, '>%1', StartDateTime);
        if ItemLedgerEntry.FindSet() then
            repeat
                if not ItemNumbers.Contains(ItemLedgerEntry."Item No.") then
                    ItemNumbers.Add(ItemLedgerEntry."Item No.");
            until ItemLedgerEntry.Next() = 0;
    end;
}