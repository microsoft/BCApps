// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using System.Environment.Configuration;
using System.Threading;

codeunit 104 "Update Name In Ledger Entries"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Phys. Inventory Ledger Entry" = rm,
                  TableData "Value Entry" = rm,
                  tabledata "Warehouse Entry" = rm;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        Update(Rec."Parameter String");
    end;

    var
        CustomerJobQueueDescrTxt: Label 'Update customer name in customer ledger entries.';
        ItemJobQueueDescrTxt: Label 'Update item name in item ledger entries.';
        WarehouseDescriptionJobQueueTxt: Label 'Update item name in warehouse entries.';
        VendorJobQueueDescrTxt: Label 'Update vendor name in vendor ledger entries.';
        ParameterNotSupportedErr: Label 'The Parameter String field must contain 18 for ''Customer'', 23 for ''Vendor'', or 27 for ''Item''. The current value ''%1'' is not supported.', Comment = '%1 - any text value';
        CustomerNamesUpdateMsg: Label '%1 customer ledger entries with empty Customer Name field were found. Do you want to update these entries by inserting the name from the customer cards?', Comment = '%1 = number of entries';
        VendorNamesUpdateMsg: Label '%1 vendor ledger entries with empty Vendor Name field were found. Do you want to update these entries by inserting the name from the vendor cards?', Comment = '%1 = number of entries';
        ItemDescriptionUpdateMsg: Label '%1 ledger entries with empty Description field were found. Do you want to update these entries by inserting the description from the item cards?', Comment = '%1 = number of entries';
        ItemDescriptionWarehouseEntriesUpdateMsg: Label '%1 warehouse entries with empty Description field were found. Do you want to update these entries by inserting the description from the item cards?', Comment = '%1 = number of entries, %2 - Table Caption';
        ScheduleUpdateMsg: Label 'Schedule update';

    procedure ScheduleUpdate(Notification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleAJob: Page "Schedule a Job";
    begin
        InsertJobQueueEntry(JobQueueEntry, Notification.GetData('TableNo'));
        ScheduleAJob.SetJob(JobQueueEntry);
        Commit();
        ScheduleAJob.RunModal();
    end;

    local procedure InsertJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; TableNo: Text)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := CopyStr(GetJobQueueDescrTxt(TableNo), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Update Name In Ledger Entries";
        JobQueueEntry."Parameter String" := CopyStr(TableNo, 1, MaxStrLen(JobQueueEntry."Parameter String"));
    end;

    local procedure GetJobQueueDescrTxt(TableNo: Text): Text;
    begin
        case TableNo of
            Format(Database::Customer):
                exit(CustomerJobQueueDescrTxt);
            Format(Database::Item):
                exit(ItemJobQueueDescrTxt);
            Format(Database::Vendor):
                exit(VendorJobQueueDescrTxt);
            Format(Database::"Warehouse Entry"):
                exit(WarehouseDescriptionJobQueueTxt);
        end;
    end;

    procedure NotifyAboutBlankNamesInLedgerEntries(SetupRecordID: RecordID)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
        Counter: Integer;
    begin
        Counter := CountEntriesWithBlankName(SetupRecordID.TableNo);
        if Counter = 0 then
            exit;
        case SetupRecordID.TableNo of
            DATABASE::"Sales & Receivables Setup":
                begin
                    Notification.Message(StrSubstNo(CustomerNamesUpdateMsg, Counter));
                    Notification.SetData('TableNo', Format(Database::Customer));
                end;
            DATABASE::"Purchases & Payables Setup":
                begin
                    Notification.Message(StrSubstNo(VendorNamesUpdateMsg, Counter));
                    Notification.SetData('TableNo', Format(Database::Vendor));
                end;
            DATABASE::"Inventory Setup":
                begin
                    Notification.Message(StrSubstNo(ItemDescriptionUpdateMsg, Counter));
                    Notification.SetData('TableNo', Format(Database::Item));
                end;
            Database::"Warehouse Setup":
                begin
                    Notification.Message(StrSubstNo(ItemDescriptionWarehouseEntriesUpdateMsg, Counter));
                    Notification.SetData('TableNo', Format(Database::"Warehouse Entry"));
                end;
        end;
        Notification.AddAction(ScheduleUpdateMsg, CODEUNIT::"Update Name In Ledger Entries", 'ScheduleUpdate');
        NotificationLifecycleMgt.SendNotification(Notification, SetupRecordID);
    end;

    local procedure CountEntriesWithBlankName(SetupTableNo: Integer): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WarehouseEntry: Record "Warehouse Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        case SetupTableNo of
            DATABASE::"Sales & Receivables Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Customer No."),
                    CustLedgerEntry.FieldNo("Customer Name")));
            DATABASE::"Purchases & Payables Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Vendor Ledger Entry", VendLedgerEntry.FieldNo("Vendor No."),
                    VendLedgerEntry.FieldNo("Vendor Name")));
            DATABASE::"Inventory Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Item No."),
                    ItemLedgerEntry.FieldNo(Description)) +
                  CountRecordsWithBlankField(
                    DATABASE::"Value Entry", ValueEntry.FieldNo("Item No."),
                    ValueEntry.FieldNo(Description)) +
                  CountRecordsWithBlankField(
                    DATABASE::"Phys. Inventory Ledger Entry", PhysInventoryLedgerEntry.FieldNo("Item No."),
                    PhysInventoryLedgerEntry.FieldNo(Description)));
            Database::"Warehouse Setup":
                exit(
                  CountRecordsWithBlankField(
                    DATABASE::"Warehouse Entry", WarehouseEntry.FieldNo("Item No."),
                    WarehouseEntry.FieldNo(Description)));
        end
    end;

    local procedure CountRecordsWithBlankField(TableNo: Integer; MasterFieldNo: Integer; FieldNo: Integer) Result: Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(MasterFieldNo);
        FieldRef.SetFilter(StrSubstNo('<>'''''));
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetRange('');
        if RecRef.IsEmpty() then
            Result := 0;
        Result := RecRef.Count();
        RecRef.Close();
    end;

    local procedure GetCustomer(CustomerNo: Code[20]; var Customer: Record Customer): Boolean
    begin
        if Customer."No." = CustomerNo then
            exit(true);
        exit(Customer.Get(CustomerNo));
    end;

    local procedure GetItem(ItemNo: Code[20]; var Item: Record Item): Boolean
    begin
        if Item."No." = ItemNo then
            exit(true);
        exit(Item.Get(ItemNo));
    end;

    local procedure GetItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; var ItemVariant: Record "Item Variant"): Boolean
    begin
        if VariantCode = '' then
            exit(false);
        if (ItemVariant."Item No." = ItemNo) and (ItemVariant.Code = VariantCode) then
            exit(true);
        exit(ItemVariant.Get(ItemNo, VariantCode));
    end;

    local procedure GetVendor(VendorNo: Code[20]; var Vendor: Record Vendor): Boolean
    begin
        if Vendor."No." = VendorNo then
            exit(true);
        exit(Vendor.Get(VendorNo));
    end;

    local procedure Update(Param: Text)
    begin
        case Param of
            Format(Database::Customer):
                UpdateCustNamesInLedgerEntries();
            Format(Database::Item):
                UpdateItemDescrInLedgerEntries();
            Format(Database::Vendor):
                UpdateVendNamesInLedgerEntries();
            Format(Database::"Warehouse Entry"):
                UpdateItemDescriptionInWarehouseEntries();
            else
                Error(ParameterNotSupportedErr, Param);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustNamesInLedgerEntries()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetFilter("Customer No.", '<>''''');
        CustLedgEntry.SetRange("Customer Name", '');
        CustLedgEntry.SetCurrentKey("Customer No.");
        if CustLedgEntry.FindSet(true) then
            repeat
                if GetCustomer(CustLedgEntry."Customer No.", Customer) then begin
                    CustLedgEntry."Customer Name" := Customer.Name;
                    OnUpdateCustNamesInLedgerEntriesOnBeforeModifyCustLedgEntry(CustLedgEntry, Customer);
                    CustLedgEntry.Modify();
                end;
            until CustLedgEntry.Next() = 0;

    end;

    [Scope('OnPrem')]
    procedure UpdateItemDescrInLedgerEntries()
    begin
        UpdateItemDescrInItemLedgerEntries();
        UpdateItemDescrInValueEntries();
        UpdateItemDescrInPhysInvLedgerEntries();
    end;

    local procedure UpdateItemDescrInItemLedgerEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetFilter("Item No.", '<>''''');
        ItemLedgerEntry.SetRange(Description, '');
        ItemLedgerEntry.SetCurrentKey("Item No.", "Variant Code");
        if ItemLedgerEntry.FindSet(true) then
            repeat
                if GetItem(ItemLedgerEntry."Item No.", Item) then begin
                    ItemLedgerEntry.Description := Item.Description;
                    if GetItemVariant(ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", ItemVariant) then
                        ItemLedgerEntry.Description := ItemVariant.Description;
                    ItemLedgerEntry.Modify();
                end;
            until ItemLedgerEntry.Next() = 0;

    end;

    local procedure UpdateItemDescrInPhysInvLedgerEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        PhysInventoryLedgerEntry.Reset();
        PhysInventoryLedgerEntry.SetFilter("Item No.", '<>''''');
        PhysInventoryLedgerEntry.SetRange(Description, '');
        PhysInventoryLedgerEntry.SetCurrentKey("Item No.", "Variant Code");
        if PhysInventoryLedgerEntry.FindSet(true) then
            repeat
                if GetItem(PhysInventoryLedgerEntry."Item No.", Item) then begin
                    PhysInventoryLedgerEntry.Description := Item.Description;
                    if GetItemVariant(PhysInventoryLedgerEntry."Item No.", PhysInventoryLedgerEntry."Variant Code", ItemVariant) then
                        PhysInventoryLedgerEntry.Description := ItemVariant.Description;
                    PhysInventoryLedgerEntry.Modify();
                end;
            until PhysInventoryLedgerEntry.Next() = 0;

    end;

    local procedure UpdateItemDescrInValueEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetFilter("Item No.", '<>''''');
        ValueEntry.SetRange(Description, '');
        ValueEntry.SetCurrentKey("Item No.", "Variant Code");
        if ValueEntry.FindSet(true) then
            repeat
                if GetItem(ValueEntry."Item No.", Item) then begin
                    ValueEntry.Description := Item.Description;
                    if GetItemVariant(ValueEntry."Item No.", ValueEntry."Variant Code", ItemVariant) then
                        ValueEntry.Description := ItemVariant.Description;
                    ValueEntry.Modify();
                end;
            until ValueEntry.Next() = 0;

    end;

    [Scope('OnPrem')]
    procedure UpdateVendNamesInLedgerEntries()
    var
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetFilter("Vendor No.", '<>''''');
        VendLedgEntry.SetRange("Vendor Name", '');
        VendLedgEntry.SetCurrentKey("Vendor No.");
        if VendLedgEntry.FindSet(true) then
            repeat
                if GetVendor(VendLedgEntry."Vendor No.", Vendor) then begin
                    VendLedgEntry."Vendor Name" := Vendor.Name;
                    OnUpdateVendNamesInLedgerEntriesOnBeforeModifyVendLedgEntry(VendLedgEntry, Vendor);
                    VendLedgEntry.Modify();
                end;
            until VendLedgEntry.Next() = 0;

    end;

    local procedure UpdateItemDescriptionInWarehouseEntries()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.Reset();
        WarehouseEntry.SetFilter("Item No.", '<>''''');
        WarehouseEntry.SetRange(Description, '');
        WarehouseEntry.SetCurrentKey("Item No.", "Variant Code");
        if WarehouseEntry.FindSet(true) then
            repeat
                if GetItem(WarehouseEntry."Item No.", Item) then begin
                    WarehouseEntry.Description := Item.Description;
                    if GetItemVariant(WarehouseEntry."Item No.", WarehouseEntry."Variant Code", ItemVariant) then
                        WarehouseEntry.Description := ItemVariant.Description;
                    OnUpdateDescriptionInWarehouseLedgerEntriesOnBeforeModifyWarehouseEntry(WarehouseEntry, Item, ItemVariant);
                    WarehouseEntry.Modify();
                end;
            until WarehouseEntry.Next() = 0;

    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustNamesInLedgerEntriesOnBeforeModifyCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendNamesInLedgerEntriesOnBeforeModifyVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDescriptionInWarehouseLedgerEntriesOnBeforeModifyWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; Item: Record Item; ItemVariant: Record "Item Variant")
    begin
    end;
}

