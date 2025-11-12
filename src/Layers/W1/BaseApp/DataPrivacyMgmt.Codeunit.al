// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.Integration.Entity;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Environment;

codeunit 1180 "Data Privacy Mgmt"
{

    trigger OnRun()
    var
        ActivityLog: Record "Activity Log";
        ActivityLogPage: Page "Activity Log";
    begin
        Clear(ActivityLogPage);
        ActivityLog.FilterGroup(2);
        ActivityLog.SetRange(Context, ActivityContextTxt);
        ActivityLog.FilterGroup(0);
        ActivityLogPage.SetTableView(ActivityLog);
        ActivityLogPage.Run();
    end;

    var
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        TypeHelper: Codeunit "Type Helper";
        ProgressBarText: Text;

        ActivityContextTxt: Label 'Privacy Activity';
        CreatingFieldDataTxt: Label 'Creating field data...';
        RemovingConfigPackageTxt: Label 'Removing config package...';
        ConfigDeleteStatusTxt: Label 'records.';

    procedure CreateData(EntityTypeTableNo: Integer; EntityNo: Code[50]; var PackageCode: Code[20]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified)
    var
        RecRef: RecordRef;
    begin
        if EntityTypeTableNo in
           [DATABASE::Customer, DATABASE::Vendor, DATABASE::Contact, DATABASE::Resource,
            DATABASE::Employee, DATABASE::"Salesperson/Purchaser"]
        then begin
            if GetRecRefForPrivacyMasterTable(RecRef, EntityTypeTableNo, EntityNo) then
                CreateRelatedData(RecRef, EntityTypeTableNo, EntityNo, PackageCode, ActionType, DataSensitivityOption);
        end else
            if EntityTypeTableNo = DATABASE::User then begin
                if GetRecRefForUserTable(RecRef, EntityNo) then
                    CreateRelatedData(RecRef, DATABASE::"User Setup", EntityNo, PackageCode, ActionType, DataSensitivityOption);
            end else
                OnCreateData(EntityTypeTableNo, EntityNo, PackageCode, ActionType, DataSensitivityOption);
    end;

    local procedure GetRecRefForPrivacyMasterTable(var RecRef: RecordRef; EntityTypeTableNo: Integer; EntityNo: Code[50]): Boolean
    var
        TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);

        if TempDataPrivacyEntities.Get(EntityTypeTableNo) then begin
            RecRef.Open(EntityTypeTableNo);
            RecRefGet(RecRef, TempDataPrivacyEntities."Key Field No.", Format(EntityNo, 20));
            if RecRef.FindFirst() then
                exit(true);
        end;
    end;

    local procedure GetRecRefForUserTable(var RecRef: RecordRef; EntityNo: Code[50]): Boolean
    var
        User: Record User;
        UserRecRef: RecordRef;
        FieldRef: FieldRef;
        UserNameFieldNo: Integer;
    begin
        // Find the user with "User Name" EntityNo
        UserNameFieldNo := User.FieldNo("User Name");

        UserRecRef.Open(DATABASE::User);
        FieldRef := UserRecRef.Field(UserNameFieldNo);
        FieldRef.SetRange(EntityNo);

        // If the user exists, create related data using the User Setup table
        if UserRecRef.FindFirst() then begin
            RecRef.Open(DATABASE::"User Setup");
            RecRefGet(RecRef, 1, EntityNo);
            if RecRef.FindFirst() then
                exit(true);
        end;
    end;

    procedure CreateRelatedData(var RecRef: RecordRef; EntityTypeTableNo: Integer; EntityNo: Code[50]; var PackageCode: Code[20]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified)
    var
        ConfigPackage: Record "Config. Package";
        PackageName: Text[50];
    begin
        PackageCode := GetPackageCode(EntityTypeTableNo, EntityNo, ActionType);
        PackageName := CopyStr(StrSubstNo('Privacy Package for %1 %2',
              Format(RecRef.Caption, 10), DelChr(Format(EntityNo, 20), '<', ' ')), 1, 50);

        if ConfigPackage.Get(PackageCode) then begin
            if ActionType = ActionType::"Export a data subject's data" then
                // Recreate the package if they chose the option to create the config package or are using the "temp" config package,
                // otherwise use the one already created
                if StrPos(PackageCode, '*') = 0 then
                    exit;

            DeletePackage(PackageCode);
        end;

        CreatePackage(RecRef.Number, EntityTypeTableNo, EntityNo, PackageCode, PackageName, DataSensitivityOption);
    end;

    procedure GetPackageCode(EntityTypeTableNo: Integer; EntityNo: Code[50]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        PackageCodeTemp: Code[20];
        PackageCodePerm: Code[20];
    begin
        if EntityTypeTableNo in
           [DATABASE::Customer, DATABASE::Vendor, DATABASE::Contact, DATABASE::Resource,
            DATABASE::Employee, DATABASE::"Salesperson/Purchaser", DATABASE::"User Setup"]
        then
            GetPermAndTempPackageCodes(PackageCodePerm, PackageCodeTemp, EntityTypeTableNo, EntityNo)
        else
            OnAfterGetPackageCode(EntityTypeTableNo, EntityNo, ActionType, PackageCodeTemp, PackageCodePerm);

        if ActionType = ActionType::"Create a data privacy configuration package" then
            exit(PackageCodePerm);

        if ConfigPackage.Get(PackageCodePerm) then
            exit(PackageCodePerm);

        exit(PackageCodeTemp);
    end;

    local procedure GetShortenedEntityNo(EntityNo: Code[50]): Code[17]
    begin
        if StrLen(EntityNo) <= 17 then
            exit(CopyStr(EntityNo, 1, StrLen(EntityNo)));

        exit(CopyStr(EntityNo, StrLen(EntityNo) - 16, 17));
    end;

    local procedure GetPermAndTempPackageCodes(var PackageCodePerm: Code[20]; var PackageCodeTemp: Code[20]; EntityTypeTableNo: Integer; EntityNo: Code[50])
    var
        TableName: Text;
        ShortenedEntityNo: Code[17];
    begin
        TableName := GetTableName(EntityTypeTableNo);

        ShortenedEntityNo := GetShortenedEntityNo(EntityNo);

        PackageCodePerm := StrSubstNo('%1%2', CopyStr(TableName, 1, 3), ShortenedEntityNo);
        PackageCodeTemp := StrSubstNo('%1*%2', CopyStr(TableName, 1, 2), ShortenedEntityNo);
    end;

    local procedure GetTableName(TableNo: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableNo) then
            exit(AllObjWithCaption."Object Name");
    end;

    procedure DeletePackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
    begin
        ConfigProgressBar.Init(4, 1, RemovingConfigPackageTxt);

        ProgressBarText := Format(ConfigPackage.TableCaption()) + ' ' + ConfigDeleteStatusTxt;
        ConfigProgressBar.Update(ProgressBarText);
        ConfigPackage.SetRange(Code, PackageCode);
        ConfigPackage.DeleteAll(true);

        ConfigProgressBar.Close();
    end;

    [Scope('OnPrem')]
    procedure CreatePackage(TableNo: Integer; EntityTypeTableNo: Integer; EntityNo: Code[50]; PackageCode: Code[20]; PackageName: Code[50]; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified)
    var
        ConfigPackage: Record "Config. Package";
        ProcessingOrder: Integer;
        EntityKeyField: Integer;
    begin
        GetPrivacyEntityKeyFieldAndTableNo(EntityKeyField, EntityTypeTableNo);

        CreateConfigPackage(ConfigPackage, PackageCode, PackageName);
        CreatePackageTable(PackageCode, EntityTypeTableNo);
        CreatePackageFieldsAndFiltersForPrimaryKeys(PackageCode, EntityTypeTableNo, EntityKeyField, EntityNo, ProcessingOrder);
        CreatePackageFieldsForDataSensitiveFields(PackageCode, TableNo, DataSensitivityOption, ProcessingOrder);
        CreateDataForRelatedTables(ConfigPackage, TableNo, EntityKeyField, EntityNo, DataSensitivityOption, ProcessingOrder);
        CreateDataForChangeLogEntries(PackageCode, EntityNo, EntityTypeTableNo);
    end;

    [Scope('OnPrem')]
    procedure GetPrivacyEntityKeyFieldAndTableNo(var EntityKeyField: Integer; var EntityTypeTableNo: Integer)
    var
        TempDataPrivacyEntities: Record "Data Privacy Entities" temporary;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.RaiseOnGetDataPrivacyEntities(TempDataPrivacyEntities);

        if EntityTypeTableNo = DATABASE::"User Setup" then
            EntityTypeTableNo := DATABASE::User;

        if TempDataPrivacyEntities.Get(EntityTypeTableNo) then
            if EntityTypeTableNo = DATABASE::User then begin
                EntityKeyField := 1;
                EntityTypeTableNo := DATABASE::"User Setup";
            end else
                EntityKeyField := TempDataPrivacyEntities."Key Field No.";
    end;

    local procedure CreatePackageFieldsAndFiltersForPrimaryKeys(PackageCode: Code[20]; EntityTypeTableNo: Integer; EntityKeyField: Integer; EntityNo: Code[50]; var ProcessingOrder: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
        IndicesFound: Integer;
        AreAllIndicesFound: Boolean;
        FieldCount: Integer;
    begin
        RecRef.Open(EntityTypeTableNo);

        FieldCount := RecRef.FieldCount;
        for FieldIndex := 1 to FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);

            if IsInPrimaryKey(FieldRef, IndicesFound, AreAllIndicesFound) then begin
                ProcessingOrder += 1;
                CreatePackageField(PackageCode, EntityTypeTableNo, FieldRef.Number, ProcessingOrder);
                CreatePackageFilter(PackageCode, EntityTypeTableNo, EntityKeyField, Format(EntityNo));

                if AreAllIndicesFound then begin
                    RecRef.Close();
                    exit;
                end;
            end;
        end;
    end;

    local procedure CreatePackageFieldsForPrimaryKeys(PackageCode: Code[20]; EntityTypeTableNo: Integer; var ProcessingOrder: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
        IndicesFound: Integer;
        AreAllIndicesFound: Boolean;
        FieldCount: Integer;
    begin
        RecRef.Open(EntityTypeTableNo);

        FieldCount := RecRef.FieldCount;
        for FieldIndex := 1 to FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);

            if IsInPrimaryKey(FieldRef, IndicesFound, AreAllIndicesFound) then begin
                ProcessingOrder += 1;
                CreatePackageField(PackageCode, EntityTypeTableNo, FieldRef.Number, ProcessingOrder);

                if AreAllIndicesFound then begin
                    RecRef.Close();
                    exit;
                end;
            end;
        end;
    end;

    local procedure CreatePackageFieldsForDataSensitiveFields(PackageCode: Code[20]; TableNo: Integer; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified; var ProcessingOrder: Integer)
    var
        DataSensitivity: Record "Data Sensitivity";
    begin
        FilterDataSensitivityByDataSensitivityOption(DataSensitivity, TableNo, DataSensitivityOption);
        if DataSensitivity.FindSet() then begin
            CreatePackageTable(PackageCode, DataSensitivity."Table No");

            repeat
                ProcessingOrder += 1;
                CreatePackageField(PackageCode, DataSensitivity."Table No", DataSensitivity."Field No", ProcessingOrder);
            until DataSensitivity.Next() = 0;
        end;
    end;

    local procedure CreateDataForRelatedTables(ConfigPackage: Record "Config. Package"; TableNo: Integer; EntityKeyField: Integer; EntityNo: Code[50]; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified; var ProcessingOrder: Integer)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        GetRelatedFields(TableRelationsMetadata, TableNo, EntityKeyField);

        ConfigProgressBar.Init(TableRelationsMetadata.Count, 1, CreatingFieldDataTxt);

        if TableRelationsMetadata.FindSet() then
            CreateRelatedDataFields(TableRelationsMetadata, ConfigPackage, EntityNo, DataSensitivityOption, ProcessingOrder);

        ConfigProgressBar.Close();
    end;

    local procedure CreateRelatedDataFields(var TableRelationsMetadata: Record "Table Relations Metadata"; var ConfigPackage: Record "Config. Package"; EntityNo: Code[50]; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified; var ProcessingOrder: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        FilterCreated: Boolean;
        CurrentTableID: Integer;
    begin
        CurrentTableID := 0;
        repeat
            if DataClassificationMgt.IsSupportedTable(TableRelationsMetadata."Table ID") then begin

                ConfigProgressBar.Update(TableRelationsMetadata.TableName);

                FilterCreated := CreatePackageFilter(ConfigPackage.Code,
                    TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.", EntityNo);

                if FilterCreated then begin
                    if CurrentTableID <> TableRelationsMetadata."Table ID" then begin
                        CurrentTableID := TableRelationsMetadata."Table ID";
                        CreatePackageTable(ConfigPackage.Code, TableRelationsMetadata."Table ID");
                        CreatePackageFieldsForPrimaryKeys(ConfigPackage.Code, TableRelationsMetadata."Table ID", ProcessingOrder);
                        CreatePackageFieldsForDataSensitiveFields(
                            ConfigPackage.Code, TableRelationsMetadata."Table ID", DataSensitivityOption, ProcessingOrder);
                    end;

                    ProcessingOrder += 1;
                    CreatePackageField(
                        ConfigPackage.Code, TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.", ProcessingOrder);
                end;
            end;
        until TableRelationsMetadata.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateConfigPackage(var ConfigPackage: Record "Config. Package"; PackageCode: Code[20]; PackageName: Text[50])
    var
        Language: Codeunit Language;
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        ConfigPackage.Init();
        ConfigPackage.Code := PackageCode;
        ConfigPackage."Package Name" := PackageName;
        ConfigPackage."Language ID" := Language.GetDefaultApplicationLanguageId();
        ConfigPackage."Product Version" :=
          CopyStr(ApplicationSystemConstants.ApplicationVersion(), 1, StrLen(ConfigPackage."Product Version"));
        if not ConfigPackage.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure CreatePackageTable(PackageCode: Code[20]; TableId: Integer)
    begin
        InsertPackageTable(PackageCode, TableId, false);  // Do NOT fire the trigger as it will create the ConfigPackageField
    end;

    [Scope('OnPrem')]
    procedure InsertPackageTable(PackageCode: Code[20]; TableId: Integer; FireInsertTrigger: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.Init();
        ConfigPackageTable."Package Code" := PackageCode;
        ConfigPackageTable.Validate("Table ID", TableId);
        ConfigPackageTable."Cross-Column Filter" := true;
        if not ConfigPackageTable.Insert(FireInsertTrigger) then;
    end;

    [Scope('OnPrem')]
    procedure CreatePackageField(ConfigPackageCode: Code[20]; TableId: Integer; FieldId: Integer; ProcessingOrder: Integer): Boolean
    var
        ConfigPackageField: Record "Config. Package Field";
        "Field": Record "Field";
    begin
        if IsValidField(TableId, FieldId, Field) then begin
            InitPackageField(ConfigPackageField, Field, ConfigPackageCode, TableId, ProcessingOrder, FieldId);
            exit(ConfigPackageField.Insert(true));
        end;
    end;

    local procedure InitPackageField(var ConfigPackageField: Record "Config. Package Field"; var "Field": Record "Field"; PackageCode: Code[20]; TableId: Integer; ProcessingOrder: Integer; FieldId: Integer)
    begin
        ConfigPackageField.Init();
        ConfigPackageField."Package Code" := PackageCode;
        ConfigPackageField."Table ID" := TableId;
        ConfigPackageField.Validate("Field Name", Field.FieldName);
        ConfigPackageField."Field Caption" := Field."Field Caption";
        ConfigPackageField."Field ID" := FieldId;
        ConfigPackageField."Processing Order" := ProcessingOrder;
        ConfigPackageField.Validate("Validate Field", true);
        ConfigPackageField.Validate("Include Field", true);
    end;

    [Scope('OnPrem')]
    procedure CreatePackageFilter(ConfigPackageCode: Code[20]; TableId: Integer; EntityKeyField: Integer; FieldValue: Text[250]): Boolean
    var
        "Field": Record "Field";
        ConfigPackage: Record "Config. Package";
    begin
        if ConfigPackage.Get(ConfigPackageCode) then
            if TypeHelper.GetField(TableId, EntityKeyField, Field) then
                if (Field.Class = Field.Class::Normal) and
                   ((Field.Type = Field.Type::Integer) or (Field.Type = Field.Type::Text) or
                    (Field.Type = Field.Type::Code) or (Field.Type = Field.Type::Option))
                then begin
                    FieldValue := GetPackageFilter(TableId, FieldValue);
                    exit(InsertPackageFilter(ConfigPackageCode, TableId, EntityKeyField, FieldValue));
                end;
    end;

    local procedure GetPackageFilter(TableNo: Integer; FieldValue: Text[250]): Text[250]
    var
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
    begin
        if IsContactPersonTable(TableNo) then begin
            if ContactPerson.Get(Format(FieldValue, 20)) then // FieldValue is the EntityNo for this method
                if ContactCompany.Get(ContactPerson."Company No.") then
                    FieldValue := FieldValue + ' | ' + ContactCompany."No.";
        end else
            OnGetPackageFilterTableNoCaseElse(TableNo, FieldValue);

        exit(FieldValue);
    end;

    local procedure IsContactPersonTable(TableNo: Integer) Result: Boolean
    begin
        Result :=
            TableNo in [
                        DATABASE::Contact,
                        DATABASE::"Contact Alt. Address",
                        DATABASE::"Sales Header",
                        DATABASE::"Purchase Header",
                        DATABASE::"Sales Shipment Header",
                        DATABASE::"Sales Invoice Header",
                        DATABASE::"Sales Cr.Memo Header",
                        DATABASE::"Purch. Rcpt. Header",
                        DATABASE::"Purch. Inv. Header",
                        Database::"Purch. Cr. Memo Entity Buffer",
                        DATABASE::"Purch. Cr. Memo Hdr.",
                        DATABASE::"Sales Header Archive",
                        DATABASE::"Purchase Header Archive",
                        DATABASE::"Sales Invoice Entity Aggregate",
                        DATABASE::"Sales Order Entity Buffer",
                        DATABASE::"Sales Quote Entity Buffer",
                        DATABASE::"Sales Cr. Memo Entity Buffer",
                        DATABASE::"Return Shipment Header",
                        DATABASE::"Return Receipt Header",
                        DATABASE::"Interaction Log Entry"
                       ];

        OnAfterIsContactPersonTable(TableNo, Result);
    end;

    local procedure InsertPackageFilter(PackageCode: Code[20]; TableId: Integer; FieldId: Integer; FieldFilter: Text[250]): Boolean
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Package Code" := PackageCode;
        ConfigPackageFilter."Table ID" := TableId;
        ConfigPackageFilter.Validate("Field ID", FieldId);
        ConfigPackageFilter.Validate("Field Filter", FieldFilter);
        exit(ConfigPackageFilter.Insert());
    end;

    [Scope('OnPrem')]
    procedure CreateDataForChangeLogEntries(PackageCode: Code[20]; EntityNo: Code[50]; EntityTableID: Integer)
    var
        ConfigPackage: Record "Config. Package";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        if ConfigPackage.Get(PackageCode) then begin
            // Create package table for Change Log table (405) and fire the insert trigger
            // as it will create the ConfigPackageField
            InsertPackageTable(PackageCode, DATABASE::"Change Log Entry", true);

            // Create package filter for Table No = Change Log table (405) AND Primary key Field 1 value = Entity No
            InsertPackageFilter(PackageCode, DATABASE::"Change Log Entry",
              ChangeLogEntry.FieldNo("Table No."), Format(EntityTableID));
            InsertPackageFilter(PackageCode, DATABASE::"Change Log Entry",
              ChangeLogEntry.FieldNo("Primary Key Field 1 Value"), Format(EntityNo));
        end;
    end;

    procedure SetPrivacyBlocked(EntityTypeTableNo: Integer; EntityNo: Code[50])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Resource: Record Resource;
        Employee: Record Employee;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        case EntityTypeTableNo of
            DATABASE::Customer:
                SetPrivacyBlockedForPrivacyEntity(DATABASE::Customer, Customer.FieldNo("Privacy Blocked"), EntityNo);
            DATABASE::Vendor:
                SetPrivacyBlockedForPrivacyEntity(DATABASE::Vendor, Vendor.FieldNo("Privacy Blocked"), EntityNo);
            DATABASE::Contact:
                SetPrivacyBlockedForPrivacyEntity(DATABASE::Contact, Contact.FieldNo("Privacy Blocked"), EntityNo);
            DATABASE::Resource:
                SetPrivacyBlockedForPrivacyEntity(DATABASE::Resource, Resource.FieldNo("Privacy Blocked"), EntityNo);
            DATABASE::Employee:
                SetPrivacyBlockedForPrivacyEntity(DATABASE::Employee, Employee.FieldNo("Privacy Blocked"), EntityNo);
            DATABASE::"Salesperson/Purchaser":
                SetPrivacyBlockedForPrivacyEntity(DATABASE::"Salesperson/Purchaser",
                  SalespersonPurchaser.FieldNo("Privacy Blocked"), EntityNo);
            else
                OnAfterSetPrivacyBlocked(EntityTypeTableNo, EntityNo);
        end;
    end;

    local procedure SetPrivacyBlockedForPrivacyEntity(TableNo: Integer; PrivacyBlockedFieldNo: Integer; EntityNo: Code[50])
    var
        RecRef: RecordRef;
        PrivacyBlockedFieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        RecRefGet(RecRef, 1, EntityNo);

        if RecRef.FindFirst() then begin
            PrivacyBlockedFieldRef := RecRef.Field(PrivacyBlockedFieldNo);
            PrivacyBlockedFieldRef.Validate(true);
            RecRef.Modify();
        end;
    end;

    local procedure IsInPrimaryKey(FieldRef: FieldRef; var IndicesFound: Integer; var AreAllIndicesFound: Boolean): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldIndex: Integer;
        NumberOfKeys: Integer;
    begin
        RecRef := FieldRef.Record();

        KeyRef := RecRef.KeyIndex(1);
        NumberOfKeys := KeyRef.FieldCount;

        for FieldIndex := 1 to NumberOfKeys do
            if KeyRef.FieldIndex(FieldIndex).Number = FieldRef.Number then begin
                IndicesFound += 1;

                if IndicesFound = NumberOfKeys then
                    AreAllIndicesFound := true;

                exit(true);
            end;

        exit(false);
    end;

    local procedure IsValidField(TableId: Integer; FieldId: Integer; var "Field": Record "Field"): Boolean
    begin
        if TypeHelper.GetField(TableId, FieldId, Field) then
            if (not ((Field.Type = Field.Type::Media) or
                     (Field.Type = Field.Type::MediaSet) or (Field.Type = Field.Type::BLOB) or (Field.Type = Field.Type::GUID))) and
               (Field.Class = Field.Class::Normal)
            then
                exit(true);
    end;

    local procedure GetRelatedFields(var TableRelationsMetadata: Record "Table Relations Metadata"; TableId: Integer; EntityKeyField: Integer)
    begin
        TableRelationsMetadata.Reset();
        TableRelationsMetadata.SetRange("Related Table ID", TableId);
        TableRelationsMetadata.SetRange("Related Field No.", EntityKeyField);
        TableRelationsMetadata.SetRange("Validate Table Relation", true);
        TableRelationsMetadata.SetRange("Condition Field No.", 0);
        TableRelationsMetadata.SetFilter("Table ID", '<>%1', TableId);
    end;

    [Scope('OnPrem')]
    procedure FilterDataSensitivityByDataSensitivityOption(var DataSensitivity: Record "Data Sensitivity"; TableID: Integer; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified)
    begin
        DataSensitivity.Reset();
        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Table No", TableID);

        case DataSensitivityOption of
            DataSensitivityOption::Sensitive:
                DataSensitivity.SetFilter("Data Sensitivity", '%1', DataSensitivity."Data Sensitivity"::Sensitive);
            DataSensitivityOption::Personal:
                DataSensitivity.SetFilter("Data Sensitivity", '%1|%2',
                  DataSensitivity."Data Sensitivity"::Sensitive,
                  DataSensitivity."Data Sensitivity"::Personal);
            DataSensitivityOption::"Company Confidential":
                DataSensitivity.SetFilter("Data Sensitivity", '%1|%2|%3',
                  DataSensitivity."Data Sensitivity"::Sensitive,
                  DataSensitivity."Data Sensitivity"::Personal,
                  DataSensitivity."Data Sensitivity"::"Company Confidential");
            DataSensitivityOption::Normal:
                DataSensitivity.SetFilter("Data Sensitivity", '%1|%2|%3|%4',
                  DataSensitivity."Data Sensitivity"::Sensitive,
                  DataSensitivity."Data Sensitivity"::Personal,
                  DataSensitivity."Data Sensitivity"::"Company Confidential",
                  DataSensitivity."Data Sensitivity"::Normal);
            DataSensitivityOption::Unclassified:
                DataSensitivity.SetFilter("Data Sensitivity", '%1', DataSensitivity."Data Sensitivity"::Unclassified);
        end;
    end;

    [Scope('OnPrem')]
    procedure RecRefGet(var RecRef: RecordRef; PrimaryKeyFieldNo: Integer; "Filter": Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(PrimaryKeyFieldNo);
        FieldRef.SetRange(Filter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateData(EntityTypeTableNo: Integer; EntityNo: Code[50]; var PackageCode: Code[20]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"; DataSensitivityOption: Option Sensitive,Personal,"Company Confidential",Normal,Unclassified)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPackageFilterTableNoCaseElse(TableNo: Integer; var FieldValue: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPackageCode(EntityTypeTableNo: Integer; EntityNo: Code[50]; ActionType: Option "Export a data subject's data","Create a data privacy configuration package"; var PackageCodeTemp: Code[20]; var PackageCodeKeep: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrivacyBlocked(EntityTypeTableNo: Integer; EntityNo: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsContactPersonTable(TableNo: Integer; var Result: Boolean);
    begin
    end;
}

