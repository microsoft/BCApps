// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Environment.Configuration;
using System.Privacy;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.CRM.Contact;
using Microsoft.Projects.Resources.Resource;
using Microsoft.HumanResources.Employee;

codeunit 1756 "Data Class. Notification Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        DataClassificationNotificationActionTxt: Label 'Open Data Classification Guide';
        DataClassificationNotificationMsg: Label 'It looks like you are either doing business in the EU or you have EU vendors, customers, contacts, resources or employees. Have you classified your data? We can help you do that.', Comment = '%1=Data Subject';
        DontShowAgainTok: Label 'Don''t show me again';
        SyncFieldsInFieldTableMsg: Label 'Your fields are %1 days old.', Comment = '%1=Number of days';
        SyncAllFieldsTxt: Label 'Synchronize all fields';
        UnclassifiedFieldsExistMsg: Label 'You have unclassified fields that require your attention.';
        OpenWorksheetActionLbl: Label 'Open worksheet';
        SyncFieldsReminderNotificationTxt: Label 'Data Classifications sync reminder';
        SyncFieldsReminderNotificationDescriptionTxt: Label 'Remind me to find unclassified fields every 30 days';
        UnclassifiedFieldsNotificationTxt: Label 'Data Sensitivities are missing';
        UnclassifiedFieldsNotificationDescriptionTxt: Label 'Show a warning when there are fields with missing Data Sensitivity';
        ReviewPrivacySettingsNotificationTxt: Label 'Review your privacy settings reminder';
        ReviewPrivacySettingsNotificationDescriptionTxt: Label 'Show a warning to review your privacy settings when persons from EU are found in your system';
        DataClassificationNotificationIdTxt: Label '23593a8e-947b-4b09-8382-36a8aaf89e01';
        SyncFieldsNotificationIdTxt: Label '3bce2004-361a-4e7f-9ae6-2df91f29a195';
        UnclassifiedFieldsNotificationIdTxt: Label 'fe7fc3ad-2382-4cbd-93f8-79bcd5b538ae';

    [Scope('OnPrem')]
    procedure FireDataClassificationNotification()
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(DataClassificationNotificationIdTxt) then
            exit;

        CreateNotification(Notification, DataClassificationNotificationIdTxt, DataClassificationNotificationMsg);
        Notification.AddAction(DataClassificationNotificationActionTxt,
          CODEUNIT::"Data Class. Notification Mgt.", 'OpenDataClassificationWizard');
        Notification.Send();
    end;

    [Scope('OnPrem')]
    procedure FireSyncFieldsNotification(DaysSinceLastSync: Integer)
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
        NotificationMessage: Text;
    begin
        if not MyNotifications.IsEnabled(SyncFieldsNotificationIdTxt) then
            exit;

        NotificationMessage := StrSubstNo(SyncFieldsInFieldTableMsg, DaysSinceLastSync);

        CreateNotification(Notification, SyncFieldsNotificationIdTxt, NotificationMessage);
        Notification.AddAction(SyncAllFieldsTxt, CODEUNIT::"Data Class. Notification Mgt.", 'SyncAllFieldsFromNotification');
        Notification.Send();
    end;

    [Scope('OnPrem')]
    procedure FireUnclassifiedFieldsNotification()
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(UnclassifiedFieldsNotificationIdTxt) then
            exit;

        CreateNotification(Notification, UnclassifiedFieldsNotificationIdTxt, UnclassifiedFieldsExistMsg);
        Notification.AddAction(OpenWorksheetActionLbl, CODEUNIT::"Data Class. Notification Mgt.", 'OpenClassificationWorksheetPage');
        Notification.Send();
    end;

    local procedure CreateNotification(var Notification: Notification; Id: Text; Message: Text)
    begin
        Notification.Id := Id;
        Notification.Message(Message);
        Notification.AddAction(DontShowAgainTok, CODEUNIT::"Data Class. Notification Mgt.", 'DisableNotifications');
    end;

    procedure ShowNotifications()
    var
        DataSensitivity: Record "Data Sensitivity";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        RecRef: RecordRef;
        EURegionFilter: Text;
    begin
        if not DataSensitivity.WritePermission then
            exit;

        if CompanyInformation.Get() then;
        if CompanyInformation."Demo Company" then
            exit;

        DataSensitivity.SetRange("Company Name", CompanyName);

        if not DataSensitivity.IsEmpty() then
            FireNotificationForNonEmptyDataSensitivityTable(DataSensitivity)
        else
            if CompanyInformationMgt.IsEUCompany(CompanyInformation) and DataClassificationMgt.DataPrivacyEntitiesExist() then
                FireDataClassificationNotification()
            else begin
                CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
                RecRef.GetTable(CountryRegion);
                EURegionFilter := GetFilterTextForFieldValuesInTable(RecRef, CountryRegion.FieldNo(Code));

                if EURegionFilter = '' then
                    exit;

                if CompanyHasVendorsInRegion(EURegionFilter) or CompanyHasCustomersInRegion(EURegionFilter) or
                   CompanyHasContactsInRegion(EURegionFilter) or CompanyHasResourcesInRegion(EURegionFilter) or
                   CompanyHasEmployeesInRegion(EURegionFilter)
                then
                    FireDataClassificationNotification();
            end;
    end;

    local procedure FireNotificationForNonEmptyDataSensitivityTable(DataSensitivity: Record "Data Sensitivity")
    begin
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        if DataSensitivity.FindFirst() then
            FireUnclassifiedFieldsNotification()
        else
            ShowSyncFieldsNotificationIfThereAreUnsynchedFields();
    end;

    local procedure CompanyHasVendorsInRegion(RegionFilter: Text): Boolean
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("Partner Type", Vendor."Partner Type"::Person);
        Vendor.SetFilter("Country/Region Code", RegionFilter);
        if Vendor.FindFirst() then
            exit(true);
        exit(false);
    end;

    local procedure CompanyHasCustomersInRegion(RegionFilter: Text): Boolean
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("Partner Type", Customer."Partner Type"::Person);
        Customer.SetFilter("Country/Region Code", RegionFilter);
        exit(not Customer.IsEmpty());
    end;

    local procedure CompanyHasContactsInRegion(RegionFilter: Text): Boolean
    var
        Contact: Record Contact;
    begin
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("Country/Region Code", RegionFilter);
        if Contact.FindFirst() then
            exit(true);
        exit(false);
    end;

    local procedure CompanyHasResourcesInRegion(RegionFilter: Text): Boolean
    var
        Resource: Record Resource;
    begin
        Resource.SetRange(Type, Resource.Type::Person);
        Resource.SetFilter("Country/Region Code", RegionFilter);
        if Resource.FindFirst() then
            exit(true);
        exit(false);
    end;

    local procedure CompanyHasEmployeesInRegion(RegionFilter: Text): Boolean
    var
        Employee: Record Employee;
    begin
        Employee.SetFilter("Country/Region Code", RegionFilter);
        if Employee.FindFirst() then
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure DisableNotifications(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        case Notification.Id of
            GetDataClassificationNotificationId():
                MyNotifications.InsertDefault(Notification.Id, ReviewPrivacySettingsNotificationTxt,
                  ReviewPrivacySettingsNotificationDescriptionTxt, false);
            GetSyncFieldsNotificationId():
                MyNotifications.InsertDefault(Notification.Id, SyncFieldsReminderNotificationTxt,
                  SyncFieldsReminderNotificationDescriptionTxt, false);
            GetUnclassifiedFieldsNotificationId():
                MyNotifications.InsertDefault(Notification.Id, UnclassifiedFieldsNotificationTxt,
                  UnclassifiedFieldsNotificationDescriptionTxt, false);
        end;

        MyNotifications.Disable(Notification.Id);
    end;

    procedure ShowSyncFieldsNotificationIfThereAreUnsynchedFields()
    var
        CompanyInformation: Record "Company Information";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DaysSinceLastSync: Integer;
        LastStatusSyncDateTime: DateTime;
    begin
        if CompanyInformation.Get() then;
        if CompanyInformation."Demo Company" then
            exit;

        LastStatusSyncDateTime := DataClassificationMgt.GetLastSyncStatusDate();

        if LastStatusSyncDateTime <> 0DT then begin
            DaysSinceLastSync := Round((CurrentDateTime - LastStatusSyncDateTime) / 1000 / 3600 / 24, 1);
            if DaysSinceLastSync > 30 then
                FireSyncFieldsNotification(DaysSinceLastSync);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFilterTextForFieldValuesInTable(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FilterText: Text;
    begin
        if RecRef.FindSet() then begin
            repeat
                FilterText := StrSubstNo('%1|%2', FilterText, RecRef.Field(FieldNo));
            until RecRef.Next() = 0;

            // remove the first vertical bar from the filter text
            FilterText := DelChr(FilterText, '<', '|');
        end;

        exit(FilterText);
    end;

    [Scope('OnPrem')]
    procedure OpenDataClassificationWizard(Notification: Notification)
    begin
        PAGE.Run(PAGE::"Data Classification Wizard");
    end;

    [Scope('OnPrem')]
    procedure OpenClassificationWorksheetPage(Notification: Notification)
    var
        DataSensitivity: Record "Data Sensitivity";
    begin
        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);

        PAGE.Run(PAGE::"Data Classification Worksheet", DataSensitivity);
    end;

    [Scope('OnPrem')]
    procedure GetDataClassificationNotificationId(): Guid
    begin
        exit(DataClassificationNotificationIdTxt);
    end;

    [Scope('OnPrem')]
    procedure GetSyncFieldsNotificationId(): Guid
    begin
        exit(SyncFieldsNotificationIdTxt);
    end;

    [Scope('OnPrem')]
    procedure GetUnclassifiedFieldsNotificationId(): Guid
    begin
        exit(UnclassifiedFieldsNotificationIdTxt);
    end;

    [Scope('OnPrem')]
    procedure SyncAllFieldsFromNotification(Notification: Notification)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SyncAllFields();
        ShowNotificationIfThereAreUnclassifiedFields();
    end;

    [Scope('OnPrem')]
    procedure ShowNotificationIfThereAreUnclassifiedFields()
    var
        CompanyInformation: Record "Company Information";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        if DataClassificationMgt.AreAllFieldsClassified() then
            exit;

        if CompanyInformation.Get() then;
        if CompanyInformation."Demo Company" then
            exit;

        FireUnclassifiedFieldsNotification();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Mgt.", 'OnShowSyncFieldsNotification', '', false, false)]
    local procedure OnShowSyncFieldsNotificationSubscriber()
    begin
        ShowSyncFieldsNotificationIfThereAreUnsynchedFields();
    end;
}

