namespace System.Integration;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;
using System.Reflection;

codeunit 1802 "Data Migration Notifier"
{

    trigger OnRun()
    begin
    end;

    var
        DataTypeManagement: Codeunit "Data Type Management";
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
        ShowListEmptyNotification(Rec, CustomerListPage.Caption());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnVendorListOpen(var Rec: Record Vendor)
    var
        VendorListPage: Page "Vendor List";
    begin
        ShowListEmptyNotification(Rec, VendorListPage.Caption());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnItemListOpen(var Rec: Record Item)
    var
        ItemListPage: Page "Item List";
    begin
        ShowListEmptyNotification(Rec, ItemListPage.Caption());
    end;

    local procedure ShowListEmptyNotification(RecordVariant: Variant; PageCaption: Text)
    var
        MyNotifications: Record "My Notifications";
        RecRef: RecordRef;
        NotificationId: Guid;
        NotificationMsg: Text;
        NotificationRemoveFunction: Text;
        SkipNotification: Boolean;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecRef);

        RecRef.Reset();

        if not RecRef.IsEmpty() then
            exit;

        SkipListEmptyNotification(RecRef.Number(), SkipNotification);
        if SkipNotification then
            exit;

        case RecRef.Number() of
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

        NotificationMsg := StrSubstNo(ListEmptyMsg, PageCaption);
        CreateNotification(NotificationId, NotificationMsg, NOTIFICATIONSCOPE::LocalScope, OpenDataMigrationTxt, 'OpenDataMigrationWizard', NotificationRemoveFunction);
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

#if not CLEAN27
    [Obsolete('This is very non-performant code. Existing callers should implement a query instead.', '27.0')]
    procedure ShowContactNotificationIfCustWithoutContExist()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if not IsNullGuid(CheckCustVendNotificationIdEnabled(DATABASE::Customer)) then
            if Customer.FindSet() then
                repeat
                    if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.") then begin
                        OnCustomerListGetCurrRec(Customer);
                        exit;
                    end;
                until Customer.Next() = 0;
    end;

    [Obsolete('This is very non-performant code. Existing callers should implement a query instead.', '27.0')]
    procedure ShowContactNotificationIfVendWithoutContExist()
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if not IsNullGuid(CheckCustVendNotificationIdEnabled(DATABASE::Vendor)) then
            if Vendor.FindSet() then
                repeat
                    if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.") then begin
                        OnVendorListGetCurrRec(Vendor);
                        exit;
                    end;
                until Vendor.Next() = 0;
    end;
#endif
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

