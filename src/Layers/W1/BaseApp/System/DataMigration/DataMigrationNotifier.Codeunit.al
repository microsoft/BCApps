namespace System.Integration;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;

codeunit 1802 "Data Migration Notifier"
{
    Permissions = tabledata "G/L Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        DataMigrationMgt: Codeunit "Data Migration Mgt.";

        ListEmptyMsg: Label 'There isn''t data here yet. Want to import %1?', Comment = '%1 - Type of records to import. Either Customers, Vendors or Items';
        OpenDataMigrationTxt: Label 'Open Data Migration';
        ListSuggestCreateContactsCustomersMsg: Label 'You can create contacts automatically from newly created customers.';
        ListSuggestCreateContactsVendorsMsg: Label 'You can create contacts automatically from newly created vendors.';
        OpenCreateContactsFromCustomersTxt: Label 'Create contacts from customers';
        OpenCreateContactsFromVendorsTxt: Label 'Create contacts from vendors';
        DisableNotificationTxt: Label 'Disable notification';

    [EventSubscriber(ObjectType::Page, Page::"Customer List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnCustomerListOpen(var Rec: Record Customer)
    var
        CustomerListPage: Page "Customer List";
    begin
        ShowListEmptyNotification(Database::Customer, CustomerListPage.Caption());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnVendorListOpen(var Rec: Record Vendor)
    var
        VendorListPage: Page "Vendor List";
    begin
        ShowListEmptyNotification(Database::Vendor, VendorListPage.Caption());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnItemListOpen(var Rec: Record Item)
    var
        ItemListPage: Page "Item List";
    begin
        ShowListEmptyNotification(Database::Item, ItemListPage.Caption());
    end;

    local procedure ShowListEmptyNotification(TableId: Integer; PageCaption: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
        NotificationMsg: Text;
        NotificationRemoveFunction: Text;
        SkipNotification: Boolean;
    begin
        if not IsTableEmpty(TableId) then
            exit;

        SkipListEmptyNotification(TableId, SkipNotification);
        if SkipNotification then
            exit;

        case TableId of
            DATABASE::Customer:
                begin
                    NotificationId := DataMigrationMgt.GetCustomerListEmptyNotificationId();
                    NotificationRemoveFunction := 'RemoveCustomerEmptyListNotification'
                end;
            DATABASE::Vendor:
                begin
                    NotificationId := DataMigrationMgt.GetVendorListEmptyNotificationId();
                    NotificationRemoveFunction := 'RemoveVendorEmptyListNotification'
                end;
            DATABASE::Item:
                begin
                    NotificationId := DataMigrationMgt.GetItemListEmptyNotificationId();
                    NotificationRemoveFunction := 'RemoveItemEmptyListNotification'
                end;
            else
                exit;
        end;

        if not MyNotifications.IsEnabled(NotificationId) then
            exit;

        // A company with posted G/L entries is in use, so do not suggest importing data.
        if not IsTableEmpty(Database::"G/L Entry") then
            exit;

        NotificationMsg := StrSubstNo(ListEmptyMsg, PageCaption);
        CreateNotification(NotificationId, NotificationMsg, NOTIFICATIONSCOPE::LocalScope, OpenDataMigrationTxt, 'OpenDataMigrationWizard', NotificationRemoveFunction);
    end;

    local procedure IsTableEmpty(TableId: Integer): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        RecRef.SecurityFiltering(SecurityFilter::Ignored);
        exit(RecRef.IsEmpty());
    end;

    procedure RemoveCustomerEmptyListNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetCustomerListEmptyNotificationId()) then
            DataMigrationMgt.InsertDefaultCustomerListEmptyNotification(false);
    end;

    procedure RemoveVendorEmptyListNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetVendorListEmptyNotificationId()) then
            DataMigrationMgt.InsertDefaultVendorListEmptyNotification(false);
    end;

    procedure RemoveItemEmptyListNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetItemListEmptyNotificationId()) then
            DataMigrationMgt.InsertDefaultItemListEmptyNotification(false);
    end;

    procedure OpenDataMigrationWizard(ListEmptyNotification: Notification)
    begin
        PAGE.Run(PAGE::"Data Migration Wizard");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnGetInstructions', '', true, true)]
    local procedure OnGetInstructionsSubscriber(var Sender: Record "Data Migrator Registration"; var Instructions: Text; var Handled: Boolean)
    begin
        Session.LogMessage('00001DB', Sender.Description, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL ' + Sender.TableName);
    end;

    procedure RunCreateContactsFromCustomersReport(ListEmptyNotification: Notification)
    begin
        REPORT.Run(REPORT::"Create Conts. from Customers");
    end;

    procedure RunCreateContactsFromVendorsReport(ListEmptyNotification: Notification)
    begin
        REPORT.Run(REPORT::"Create Conts. from Vendors");
    end;

    procedure RemoveCustomerContactNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetCustomerContactNotificationId()) then
            DataMigrationMgt.InsertDefaultCustomerContactNotification(false);
    end;

    procedure RemoveVendorContactNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetVendorContactNotificationId()) then
            DataMigrationMgt.InsertDefaultVendorContactNotification(false);
    end;

    local procedure CreateNotification(NotificationGUID: Guid; MessageText: Text; NotificaitonScope: NotificationScope; ActionText: Text; ActionFunction: Text; RemoveNotificationFunction: Text)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationGUID;
        Notification.Message := MessageText;
        Notification.Scope := NotificaitonScope;
        Notification.AddAction(ActionText, CODEUNIT::"Data Migration Notifier", ActionFunction);
        if RemoveNotificationFunction <> '' then
            Notification.AddAction(DisableNotificationTxt, CODEUNIT::"Data Migration Notifier", RemoveNotificationFunction);
        Notification.Send();
    end;

    local procedure ShowCustomerContactCreationNotification(SourceNo: Code[20]; SourceTableID: Integer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        NotificationID: Guid;
        SkipNotification: Boolean;
    begin
        SkipShowingCustomerContactCreationNotification(SkipNotification);
        if SkipNotification then
            exit;

        NotificationID := CheckCustVendNotificationIdEnabled(SourceTableID);
        if IsNullGuid(NotificationID) then
            exit;
        case SourceTableID of
            DATABASE::Customer:
                if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, SourceNo) then
                    CreateNotification(
                      NotificationID,
                      ListSuggestCreateContactsCustomersMsg, NOTIFICATIONSCOPE::LocalScope,
                      OpenCreateContactsFromCustomersTxt, 'RunCreateContactsFromCustomersReport',
                      'RemoveCustomerContactNotification')
                else
                    RecallNotification(NotificationID);
            DATABASE::Vendor:
                if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, SourceNo) then
                    CreateNotification(
                      NotificationID,
                      ListSuggestCreateContactsVendorsMsg, NOTIFICATIONSCOPE::LocalScope,
                      OpenCreateContactsFromVendorsTxt, 'RunCreateContactsFromVendorsReport',
                      'RemoveVendorContactNotification')
                else
                    RecallNotification(NotificationID);
        end;
    end;

    procedure CheckCustVendNotificationIdEnabled(SourceTableID: Integer) NotificationID: Guid
    var
        MyNotifications: Record "My Notifications";
    begin
        case SourceTableID of
            DATABASE::Customer:
                NotificationID := DataMigrationMgt.GetCustomerContactNotificationId();
            DATABASE::Vendor:
                NotificationID := DataMigrationMgt.GetVendorContactNotificationId();
            else
                exit;
        end;
        if not MyNotifications.IsEnabled(NotificationID) then
            Clear(NotificationID);
    end;

    local procedure RecallNotification(NotificationID: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationID;
        if Notification.Recall() then;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer List", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnCustomerListGetCurrRec(var Rec: Record Customer)
    begin
        ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Customer);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnCustomerCardGetCurrRec(var Rec: Record Customer)
    begin
        if Rec.Find() then
            ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Customer);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor List", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnVendorListGetCurrRec(var Rec: Record Vendor)
    begin
        ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Vendor);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnVendorCardGetCurrRec(var Rec: Record Vendor)
    begin
        if Rec.Find() then
            ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Vendor);
    end;

    [IntegrationEvent(false, false)]
    local procedure SkipShowingCustomerContactCreationNotification(var SkipNotification: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure SkipListEmptyNotification(TableId: Integer; var SkipNotification: Boolean)
    begin
    end;
}

