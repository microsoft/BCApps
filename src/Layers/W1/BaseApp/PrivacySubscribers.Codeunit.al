// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

using Microsoft.CRM.Team;
using Microsoft.CRM.Contact;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Apps;
using System.Reflection;
using System.Security.User;
using System.Security.AccessControl;

codeunit 1755 "Privacy Subscribers"
{

    trigger OnRun()
    begin
    end;

    var
        CustomerFilterTxt: Label 'WHERE(Partner Type=FILTER(Person))', Locked = true;
        VendorFilterTxt: Label 'WHERE(Partner Type=FILTER(Person))', Locked = true;
        ContactFilterTxt: Label 'WHERE(Type=FILTER(Person))', Locked = true;
        ResourceFilterTxt: Label 'WHERE(Type=FILTER(Person))', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Mgt.", 'OnCreateEvaluationData', '', false, false)]
    local procedure CreateEvaluationData()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.CreateEvaluationData();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Mgt.", 'OnGetDataPrivacyEntities', '', false, false)]
    local procedure OnGetDataPrivacyEntitiesSubscriber(var DataPrivacyEntities: Record "Data Privacy Entities")
    var
        DummyCustomer: Record Customer;
        DummyVendor: Record Vendor;
        DummyContact: Record Contact;
        DummyResource: Record Resource;
        DummyUser: Record User;
        DummyEmployee: Record Employee;
        DummySalespersonPurchaser: Record "Salesperson/Purchaser";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::Customer, PAGE::"Customer List",
          DummyCustomer.FieldNo("No."), CustomerFilterTxt, DummyCustomer.FieldNo("Privacy Blocked"));
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::Vendor, PAGE::"Vendor List",
          DummyVendor.FieldNo("No."), VendorFilterTxt, DummyVendor.FieldNo("Privacy Blocked"));
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::"Salesperson/Purchaser",
          PAGE::"Salespersons/Purchasers", DummySalespersonPurchaser.FieldNo(Code), ContactFilterTxt,
          DummySalespersonPurchaser.FieldNo("Privacy Blocked"));
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::Contact, PAGE::"Contact List",
          DummyContact.FieldNo("No."), ContactFilterTxt, DummyContact.FieldNo("Privacy Blocked"));
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::Employee, PAGE::"Employee List",
          DummyEmployee.FieldNo("No."), '', DummyEmployee.FieldNo("Privacy Blocked"));
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::User, PAGE::Users,
          DummyUser.FieldNo("User Name"), '', 0);
        DataClassificationMgt.InsertDataPrivacyEntity(DataPrivacyEntities, DATABASE::Resource, PAGE::"Resource List",
          DummyResource.FieldNo("No."), ResourceFilterTxt, DummyResource.FieldNo("Privacy Blocked"));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Extension Details", 'OnAfterActionEvent', 'Install', true, true)]
    local procedure AfterExtensionIsInstalled(var Rec: Record "Published Application")
    var
        DataSensitivity: Record "Data Sensitivity";
        ApplicationObjectMetadata: Record "Application Object Metadata";
        "Field": Record "Field";
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        RecRef: RecordRef;
        FilterText: Text;
    begin
        if DataClassificationMgt.IsDataSensitivityEmptyForCurrentCompany() then
            exit;

        ApplicationObjectMetadata.SetRange("Runtime Package ID", Rec."Runtime Package ID");
        ApplicationObjectMetadata.SetRange("Object Type", ApplicationObjectMetadata."Object Type"::Table);

        RecRef.GetTable(ApplicationObjectMetadata);
        FilterText := DataClassNotificationMgt.GetFilterTextForFieldValuesInTable(RecRef, ApplicationObjectMetadata.FieldNo("Object ID"));

        if FilterText <> '' then begin
            Field.SetFilter(TableNo, FilterText);
            Field.SetRange(Class, Field.Class::Normal);
            GetEnabledSensitiveFields(Field);

            if Field.FindSet() then begin
                repeat
                    if not DataSensitivity.Get(CompanyName, Field.TableNo, Field."No.") then
                        DataClassificationMgt.InsertDataSensitivityForField(Field.TableNo, Field."No.",
                          DataSensitivity."Data Sensitivity"::Unclassified);
                until Field.Next() = 0;

                DataClassNotificationMgt.ShowNotificationIfThereAreUnclassifiedFields();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Extension Details", 'OnAfterActionEvent', 'Uninstall', true, true)]
    local procedure AfterExtensionIsUninstalled(var Rec: Record "Published Application")
    var
        DataSensitivity: Record "Data Sensitivity";
        ApplicationObjectMetadata: Record "Application Object Metadata";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        RecRef: RecordRef;
        FilterText: Text;
    begin
        if DataClassificationMgt.IsDataSensitivityEmptyForCurrentCompany() then
            exit;

        // Remove the fields from the Data Sensitivity table without a confirmation through a notification
        ApplicationObjectMetadata.SetRange("Runtime Package ID", Rec."Runtime Package ID");
        ApplicationObjectMetadata.SetRange("Object Type", ApplicationObjectMetadata."Object Type"::Table);

        RecRef.GetTable(ApplicationObjectMetadata);
        FilterText := DataClassNotificationMgt.GetFilterTextForFieldValuesInTable(RecRef, ApplicationObjectMetadata.FieldNo("Object ID"));

        if FilterText <> '' then begin
            DataSensitivity.SetFilter("Table No", FilterText);
            DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
            DataSensitivity.DeleteAll();
        end;
    end;

    local procedure GetEnabledSensitiveFields(var "Field": Record "Field")
    begin
        Field.SetRange(Enabled, true);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetFilter(
          DataClassification,
          StrSubstNo('%1|%2|%3',
            Field.DataClassification::CustomerContent,
            Field.DataClassification::EndUserIdentifiableInformation,
            Field.DataClassification::EndUserPseudonymousIdentifiers));
    end;
}

