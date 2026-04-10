// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Globalization;
using System.IO;
using System.Reflection;

codeunit 1806 "Excel Data Migrator"
{

    trigger OnRun()
    begin
    end;

    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";

        PackageCodeTxt: Label 'GB.ENU.EXCEL';
        PackageNameTxt: Label 'Excel Data Migration';
        DataMigratorDescriptionTxt: Label 'Import from Excel';
        Instruction1Txt: Label '1) Download the Excel template.';
        Instruction2Txt: Label '2) Fill in the template with your data.';
        Instruction3Txt: Label '3) Optional, but important: Specify import settings. These help ensure that you can use your data right away.';
        Instruction4Txt: Label '4) Choose Next to upload your data file.';
        ImportingMsg: Label 'Importing Data...';
        ApplyingMsg: Label 'Applying Data...';
        ImportFromExcelTxt: Label 'Import from Excel';
        ExcelFileExtensionTok: Label '*.xlsx';
        ExcelValidationErr: Label 'The file that you imported is corrupted. It contains columns that cannot be mapped to %1.', Comment = '%1 - product name';
        OpenAdvancedQst: Label 'The advanced setup experience requires you to specify how database tables are configured. We recommend that you only access the advanced setup if you are familiar with RapidStart Services.\\Do you want to continue?';
        ExcelFileNameTok: Label 'DataImport_Dynamics365%1.xlsx', Comment = '%1 = String generated from current datetime to make sure file names are unique ';
        SettingsMissingQst: Label 'Wait a minute. You have not specified import settings. To avoid extra work and potential errors, we recommend that you specify import settings now, rather than update the data later.\\Do you want to specify the settings?';
        ValidateErrorsBeforeApplyQst: Label 'Some of the fields will not be applied because errors were found in the imported data.\\Do you want to continue?';

    [Scope('OnPrem')]
    procedure ImportExcelData(): Boolean
    var
        FileManagement: Codeunit "File Management";
        ServerFile: Text[250];
    begin
        OnUploadFile(ServerFile);
        if ServerFile = '' then
            ServerFile := CopyStr(FileManagement.UploadFile(ImportFromExcelTxt, ExcelFileExtensionTok),
                1, MaxStrLen(ServerFile));

        if ServerFile <> '' then begin
            ImportExcelDataByFileName(ServerFile);
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ImportExcelDataByFileName(FileName: Text[250])
    var
        FileManagement: Codeunit "File Management";
        Window: Dialog;
    begin
        Window.Open(ImportingMsg);

        FileManagement.ValidateFileExtension(FileName, ExcelFileExtensionTok);
        CreatePackageMetadata();
        ValidateTemplateAndImportData(FileName);

        Window.Close();
    end;

    procedure ImportExcelDataStream(): Boolean
    var
        FileManagement: Codeunit "File Management";
        FileStream: InStream;
        Name: Text;
    begin
        ClearLastError();

        // There is no way to check if NVInStream is null before using it after calling the
        // UPLOADINTOSTREAM therefore if result is false this is the only way we can throw the error.
        Name := ExcelFileExtensionTok;

        if not UploadIntoStream(ImportFromExcelTxt, '', FileManagement.GetToFilterText('', '.xlsx'), Name, FileStream) then
            exit(false);
        ImportExcelDataByStream(FileStream);
        exit(true);
    end;

    procedure ImportExcelDataByStream(FileStream: InStream)
    var
        Window: Dialog;
    begin
        Window.Open(ImportingMsg);

        CreatePackageMetadata();
        ValidateTemplateAndImportDataStream(FileStream);

        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure ExportExcelTemplate(): Boolean
    var
        FileName: Text;
        HideDialog: Boolean;
    begin
        OnDownloadTemplate(HideDialog);
        exit(ExportExcelTemplateByFileName(FileName, HideDialog));
    end;

    [Scope('OnPrem')]
    procedure ExportExcelTemplateByFileName(var FileName: Text; HideDialog: Boolean): Boolean
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        if FileName = '' then
            FileName :=
              StrSubstNo(ExcelFileNameTok, Format(CurrentDateTime, 0, '<Day,2>_<Month,2>_<Year4>_<Hours24>_<Minutes,2>_<Seconds,2>'));

        CreatePackageMetadata();
        ConfigPackageTable.SetRange("Package Code", PackageCodeTxt);
        ConfigExcelExchange.SetHideDialog(HideDialog);
        exit(ConfigExcelExchange.ExportExcel(FileName, ConfigPackageTable, false, true));
    end;

    procedure GetPackageCode(): Code[20]
    begin
        exit(PackageCodeTxt);
    end;

    local procedure CreatePackageMetadata()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        Language: Codeunit Language;
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        ConfigPackage.SetRange(Code, PackageCodeTxt);
        ConfigPackage.DeleteAll(true);

        ConfigPackageManagement.InsertPackage(ConfigPackage, PackageCodeTxt, PackageNameTxt, false);
        ConfigPackage."Language ID" := Language.GetDefaultApplicationLanguageId();
        ConfigPackage."Product Version" :=
          CopyStr(ApplicationSystemConstants.ApplicationVersion(), 1, StrLen(ConfigPackage."Product Version"));
        ConfigPackage.Modify();

        InsertPackageTables();
        InsertPackageFields();
    end;

    local procedure InsertPackageTables()
    var
        ConfigPackageField: Record "Config. Package Field";
        DataMigrationSetup: Record "Data Migration Setup";
    begin
        if not DataMigrationSetup.Get() then begin
            DataMigrationSetup.Init();
            DataMigrationSetup.Insert();
        end;

        InsertPackageTableCustomer(DataMigrationSetup);
        InsertPackageTableVendor(DataMigrationSetup);
        InsertPackageTableItem(DataMigrationSetup);
        InsertPackageTableAccount(DataMigrationSetup);

        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.ModifyAll("Include Field", false);
    end;

    local procedure InsertPackageFields()
    begin
        InsertPackageFieldsCustomer();
        InsertPackageFieldsVendor();
        InsertPackageFieldsItem();
        InsertPackageFieldsAccount();
    end;

    local procedure InsertPackageTableCustomer(var DataMigrationSetup: Record "Data Migration Setup")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCodeTxt, DATABASE::Customer);
        ConfigPackageTable."Data Template" := DataMigrationSetup."Default Customer Template";
        ConfigPackageTable.Modify();
        ConfigPackageManagement.InsertProcessingRuleCustom(
          ConfigTableProcessingRule, ConfigPackageTable, 100000, CODEUNIT::"Excel Post Processor");
    end;

    local procedure InsertPackageFieldsCustomer()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageField.DeleteAll(true);

        InsertPackageField(DATABASE::Customer, 1, 1);     // No.
        InsertPackageField(DATABASE::Customer, 2, 2);     // Name
        InsertPackageField(DATABASE::Customer, 3, 3);     // Search Name
        InsertPackageField(DATABASE::Customer, 5, 4);     // Address
        InsertPackageField(DATABASE::Customer, 7, 5);     // City
        InsertPackageField(DATABASE::Customer, 92, 6);    // County
        InsertPackageField(DATABASE::Customer, 91, 7);    // Post Code
        InsertPackageField(DATABASE::Customer, 35, 8);    // Country/Region Code
        InsertPackageField(DATABASE::Customer, 8, 9);     // Contact
        InsertPackageField(DATABASE::Customer, 9, 10);    // Phone No.
        InsertPackageField(DATABASE::Customer, 102, 11);  // E-Mail
        InsertPackageField(DATABASE::Customer, 20, 12);   // Credit Limit (LCY)
        InsertPackageField(DATABASE::Customer, 21, 13);   // Customer Posting Group
        InsertPackageField(DATABASE::Customer, 27, 14);   // Payment Terms Code
        InsertPackageField(DATABASE::Customer, 88, 15);   // Gen. Bus. Posting Group
    end;

    local procedure InsertPackageTableVendor(var DataMigrationSetup: Record "Data Migration Setup")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCodeTxt, DATABASE::Vendor);
        ConfigPackageTable."Data Template" := DataMigrationSetup."Default Vendor Template";
        ConfigPackageTable.Modify();
        ConfigPackageManagement.InsertProcessingRuleCustom(
          ConfigTableProcessingRule, ConfigPackageTable, 100000, CODEUNIT::"Excel Post Processor");
    end;

    local procedure InsertPackageFieldsVendor()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.SetRange("Table ID", DATABASE::Vendor);
        ConfigPackageField.DeleteAll(true);

        InsertPackageField(DATABASE::Vendor, 1, 1);     // No.
        InsertPackageField(DATABASE::Vendor, 2, 2);     // Name
        InsertPackageField(DATABASE::Vendor, 3, 3);     // Search Name
        InsertPackageField(DATABASE::Vendor, 5, 4);     // Address
        InsertPackageField(DATABASE::Vendor, 7, 5);     // City
        InsertPackageField(DATABASE::Vendor, 92, 6);    // County
        InsertPackageField(DATABASE::Vendor, 91, 7);    // Post Code
        InsertPackageField(DATABASE::Vendor, 35, 8);    // Country/Region Code
        InsertPackageField(DATABASE::Vendor, 8, 9);     // Contact
        InsertPackageField(DATABASE::Vendor, 9, 10);    // Phone No.
        InsertPackageField(DATABASE::Vendor, 102, 11);  // E-Mail
        InsertPackageField(DATABASE::Vendor, 21, 12);   // Vendor Posting Group
        InsertPackageField(DATABASE::Vendor, 27, 13);   // Payment Terms Code
        InsertPackageField(DATABASE::Vendor, 88, 14);   // Gen. Bus. Posting Group
    end;

    local procedure InsertPackageTableItem(var DataMigrationSetup: Record "Data Migration Setup")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCodeTxt, DATABASE::Item);
        ConfigPackageTable."Data Template" := DataMigrationSetup."Default Item Template";
        ConfigPackageTable.Modify();
        ConfigPackageManagement.InsertProcessingRuleCustom(
          ConfigTableProcessingRule, ConfigPackageTable, 100000, CODEUNIT::"Excel Post Processor")
    end;

    local procedure InsertPackageFieldsItem()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.SetRange("Table ID", DATABASE::Item);
        ConfigPackageField.DeleteAll(true);

        InsertPackageField(DATABASE::Item, 1, 1);     // No.
        InsertPackageField(DATABASE::Item, 3, 2);     // Description
        InsertPackageField(DATABASE::Item, 4, 3);     // Search Description
        InsertPackageField(DATABASE::Item, 8, 4);     // Base Unit of Measure
        InsertPackageField(DATABASE::Item, 18, 5);    // Unit Price
        InsertPackageField(DATABASE::Item, 22, 6);    // Unit Cost
        InsertPackageField(DATABASE::Item, 24, 7);    // Standard Cost
        InsertPackageField(DATABASE::Item, 68, 8);    // Inventory
        InsertPackageField(DATABASE::Item, 35, 9);    // Maximum Inventory
        InsertPackageField(DATABASE::Item, 121, 10);  // Prevent Negative Inventory
        InsertPackageField(DATABASE::Item, 34, 11);   // Reorder Point
        InsertPackageField(DATABASE::Item, 36, 12);   // Reorder Quantity
        InsertPackageField(DATABASE::Item, 38, 13);   // Unit List Price
        InsertPackageField(DATABASE::Item, 41, 14);   // Gross Weight
        InsertPackageField(DATABASE::Item, 42, 15);   // Net Weight
        InsertPackageField(DATABASE::Item, 5411, 16); // Minimum Order Quantity
        InsertPackageField(DATABASE::Item, 5412, 17); // Maximum Order Quantity
        InsertPackageField(DATABASE::Item, 5413, 18); // Safety Stock Quantity
    end;

    local procedure InsertPackageField(TableNo: Integer; FieldNo: Integer; ProcessingOrderNo: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(FieldNo);

        ConfigPackageManagement.InsertPackageField(ConfigPackageField, PackageCodeTxt, TableNo,
          FieldRef.Number, FieldRef.Name, FieldRef.Caption, true, true, false, false);
        ConfigPackageField.Validate("Processing Order", ProcessingOrderNo);
        ConfigPackageField.Modify(true);
    end;

    local procedure GetCodeunitNumber(): Integer
    begin
        exit(CODEUNIT::"Excel Data Migrator");
    end;

    local procedure ValidateTemplateAndImportData(FileName: Text)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackage.Get(PackageCodeTxt);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);

        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageField.Reset();

                // Check if Excel file contains data sheets with the supported master tables (Customer, Vendor, Item)
                if IsTableInExcel(TempExcelBuffer, FileName, ConfigPackageTable) then
                    ValidateTemplateAndImportDataCommon(TempExcelBuffer, ConfigPackageField, ConfigPackageTable)
                else begin
                    // Table is removed from the configuration package because it doen't exist in the Excel file
                    TempExcelBuffer.CloseBook();
                    ConfigPackageTable.Delete(true);
                end;
            until ConfigPackageTable.Next() = 0;
    end;

    local procedure ValidateTemplateAndImportDataStream(FileStream: InStream)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackage.Get(PackageCodeTxt);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);

        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageField.Reset();

                // Check if Excel file contains data sheets with the supported master tables (Customer, Vendor, Item)
                if IsTableInExcelStream(TempExcelBuffer, FileStream, ConfigPackageTable) then
                    ValidateTemplateAndImportDataCommon(TempExcelBuffer, ConfigPackageField, ConfigPackageTable)
                else begin
                    // Table is removed from the configuration package because it doen't exist in the Excel file
                    TempExcelBuffer.CloseBook();
                    ConfigPackageTable.Delete(true);
                end;
            until ConfigPackageTable.Next() = 0;
    end;

    local procedure ValidateTemplateAndImportDataCommon(var TempExcelBuffer: Record "Excel Buffer" temporary; var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ColumnHeaderRow: Integer;
        ColumnCount: Integer;
        RecordNo: Integer;
        FieldID: array[250] of Integer;
        I: Integer;
    begin
        ColumnHeaderRow := 3; // Data is stored in the Excel sheets starting from row 3

        TempExcelBuffer.ReadSheet();
        // Jump to the Columns' header row
        TempExcelBuffer.SetFilter("Row No.", '%1..', ColumnHeaderRow);

        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");

        ColumnCount := 0;

        if TempExcelBuffer.FindSet() then
            repeat
                if TempExcelBuffer."Row No." = ColumnHeaderRow then begin // Columns' header row
                    ConfigPackageField.SetRange("Field Caption", TempExcelBuffer."Cell Value as Text");

                    // Column can be mapped to a field, data will be imported to NAV
                    if ConfigPackageField.FindFirst() then begin
                        FieldID[TempExcelBuffer."Column No."] := ConfigPackageField."Field ID";
                        ConfigPackageField."Include Field" := true;
                        ConfigPackageField.Modify();
                        ColumnCount += 1;
                    end else // Error is thrown when the template is corrupted (i.e., there are columns in Excel file that cannot be mapped to NAV)
                        Error(ExcelValidationErr, PRODUCTNAME.Marketing());
                end else begin // Read data row by row
                               // A record is created with every new row
                    ConfigPackageManagement.InitPackageRecord(ConfigPackageRecord, PackageCodeTxt,
                      ConfigPackageTable."Table ID");
                    RecordNo := ConfigPackageRecord."No.";
                    case ConfigPackageTable."Table ID" of
                        15:
                            for I := 1 to ColumnCount do
                                if TempExcelBuffer.Get(TempExcelBuffer."Row No.", I) then // Mapping for Account fields
                                    InsertAccountsFieldData(ConfigPackageTable."Table ID", RecordNo, FieldID[I], TempExcelBuffer."Cell Value as Text");
                        else
                            for I := 1 to ColumnCount do
                                if TempExcelBuffer.Get(TempExcelBuffer."Row No.", I) then
                                    // Fields are populated in the record created
                                    InsertFieldData(
                                        ConfigPackageTable."Table ID", RecordNo, FieldID[I], TempExcelBuffer."Cell Value as Text")
                                else
                                    InsertFieldData(
                                        ConfigPackageTable."Table ID", RecordNo, FieldID[I], '');
                    end;

                    // Go to next line
                    TempExcelBuffer.SetFilter("Row No.", '%1..', TempExcelBuffer."Row No." + 1);
                end;
            until TempExcelBuffer.Next() = 0;

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.CloseBook();
    end;

    [TryFunction]
    local procedure IsTableInExcel(var TempExcelBuffer: Record "Excel Buffer" temporary; FileName: Text; ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.CalcFields("Table Name", "Table Caption");

        if not TryOpenExcel(TempExcelBuffer, FileName, ConfigPackageTable."Table Name") then
            if not TryOpenExcel(TempExcelBuffer, FileName, ConfigPackageTable."Table Caption") then
                TryOpenExcel(TempExcelBuffer, FileName, CopyStr(Format(ConfigPackageTable."Table ID") + ' ' + ConfigPackageTable."Table Name", 1, 250));
    end;

    [TryFunction]
    local procedure TryOpenExcel(var TempExcelBuffer: Record "Excel Buffer" temporary; FileName: Text; SheetName: Text[250])
    begin
        TempExcelBuffer.OpenBook(FileName, SheetName);
    end;

    local procedure IsTableInExcelStream(var TempExcelBuffer: Record "Excel Buffer" temporary; FileStream: InStream; ConfigPackageTable: Record "Config. Package Table"): Boolean
    begin
        ConfigPackageTable.CalcFields("Table Name", "Table Caption");

        if OpenExcelStream(TempExcelBuffer, FileStream, ConfigPackageTable."Table Name") = '' then
            exit(true);
        if OpenExcelStream(TempExcelBuffer, FileStream, ConfigPackageTable."Table Caption") = '' then
            exit(true);
        exit(false);
    end;

    local procedure OpenExcelStream(var TempExcelBuffer: Record "Excel Buffer" temporary; FileStream: InStream; SheetName: Text[250]): Text
    begin
        exit(TempExcelBuffer.OpenBookStream(FileStream, SheetName));
    end;

    local procedure InsertFieldData(TableNo: Integer; RecordNo: Integer; FieldNo: Integer; Value: Text[250])
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageManagement.InsertPackageData(ConfigPackageData, PackageCodeTxt,
          TableNo, RecordNo, FieldNo, Value, false);
    end;

    local procedure CreateDataMigrationEntites(var DataMigrationEntity: Record "Data Migration Entity")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackage.Get(PackageCodeTxt);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        DataMigrationEntity.DeleteAll();

        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageTable.CalcFields("No. of Package Records");
                DataMigrationEntity.InsertRecord(ConfigPackageTable."Table ID", ConfigPackageTable."No. of Package Records");
            until ConfigPackageTable.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnRegisterDataMigrator', '', false, false)]
    local procedure RegisterExcelDataMigrator(var Sender: Record "Data Migrator Registration")
    begin
        Sender.RegisterDataMigrator(GetCodeunitNumber(), DataMigratorDescriptionTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasSettings', '', false, false)]
    local procedure HasSettings(var Sender: Record "Data Migrator Registration"; var HasSettings: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasSettings := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnOpenSettings', '', false, false)]
    local procedure OpenSettings(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        PAGE.RunModal(PAGE::"Data Migration Settings");
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnValidateSettings', '', false, false)]
    local procedure ValidateSettings(var Sender: Record "Data Migrator Registration")
    var
        DataMigrationSetup: Record "Data Migration Setup";
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        DataMigrationSetup.Get();
        if (DataMigrationSetup."Default Customer Template" = '') and
           (DataMigrationSetup."Default Vendor Template" = '') and
           (DataMigrationSetup."Default Item Template" = '')
        then
            if Confirm(SettingsMissingQst, true) then
                PAGE.RunModal(PAGE::"Data Migration Settings");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasTemplate', '', false, false)]
    local procedure HasTemplate(var Sender: Record "Data Migrator Registration"; var HasTemplate: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasTemplate := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnGetInstructions', '', false, false)]
    local procedure GetInstructions(var Sender: Record "Data Migrator Registration"; var Instructions: Text; var Handled: Boolean)
    var
        TypeHelper: Codeunit "Type Helper";
        CRLF: Text[2];
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        CRLF := TypeHelper.CRLFSeparator();

        Instructions := Instruction1Txt + CRLF + Instruction2Txt + CRLF + Instruction3Txt + CRLF + Instruction4Txt;

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnDownloadTemplate', '', false, false)]
    local procedure DownloadTemplate(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if ExportExcelTemplate() then begin
            Handled := true;
            exit;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnDataImport', '', false, false)]
    local procedure ImportData(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if ImportExcelData() then begin
            Handled := true;
            exit;
        end;

        Handled := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnSelectDataToApply', '', false, false)]
    local procedure SelectDataToApply(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        CreateDataMigrationEntites(DataMigrationEntity);

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasAdvancedApply', '', false, false)]
    local procedure HasAdvancedApply(var Sender: Record "Data Migrator Registration"; var HasAdvancedApply: Boolean)
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        HasAdvancedApply := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnOpenAdvancedApply', '', false, false)]
    local procedure OpenAdvancedApply(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    var
        ConfigPackage: Record "Config. Package";
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        if not Confirm(OpenAdvancedQst, true) then
            exit;

        ConfigPackage.Get(PackageCodeTxt);
        PAGE.RunModal(PAGE::"Config. Package Card", ConfigPackage);

        CreateDataMigrationEntites(DataMigrationEntity);
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnApplySelectedData', '', false, false)]
    local procedure ApplySelectedData(var Sender: Record "Data Migrator Registration"; var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageManagement: Codeunit "Config. Package Management";
        Window: Dialog;
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        ConfigPackage.Get(PackageCodeTxt);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);

        // Validate the package
        ConfigPackageManagement.SetHideDialog(true);
        ConfigPackageManagement.CleanPackageErrors(PackageCodeTxt, '');
        DataMigrationEntity.SetRange(Selected, true);
        if DataMigrationEntity.FindSet() then
            repeat
                ConfigPackageTable.SetRange("Table ID", DataMigrationEntity."Table ID");
                ConfigPackageManagement.ValidatePackageRelations(ConfigPackageTable, TempConfigPackageTable, true);
            until DataMigrationEntity.Next() = 0;
        DataMigrationEntity.SetRange(Selected);
        ConfigPackageTable.SetRange("Table ID");
        ConfigPackageManagement.SetHideDialog(false);
        ConfigPackage.CalcFields("No. of Errors");
        ConfigPackageManagement.CleanPackageErrors(PackageCodeTxt, '');

        if ConfigPackage."No. of Errors" <> 0 then
            if not Confirm(ValidateErrorsBeforeApplyQst) then
                exit;

        if DataMigrationEntity.FindSet() then
            repeat
                if not DataMigrationEntity.Selected then begin
                    ConfigPackageTable.Get(PackageCodeTxt, DataMigrationEntity."Table ID");
                    ConfigPackageTable.Delete(true);
                end;
            until DataMigrationEntity.Next() = 0;

        Window.Open(ApplyingMsg);
        RemoveDemoData(ConfigPackageTable);// Remove the demo data before importing Accounts(if any)
        ConfigPackageManagement.ApplyPackage(ConfigPackage, ConfigPackageTable, true);
        Window.Close();
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnHasErrors', '', false, false)]
    local procedure HasErrors(var Sender: Record "Data Migrator Registration"; var HasErrors: Boolean)
    var
        ConfigPackage: Record "Config. Package";
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        ConfigPackage.Get(PackageCodeTxt);
        ConfigPackage.CalcFields("No. of Errors");
        HasErrors := ConfigPackage."No. of Errors" <> 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migrator Registration", 'OnShowErrors', '', false, false)]
    local procedure ShowErrors(var Sender: Record "Data Migrator Registration"; var Handled: Boolean)
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        if Sender."No." <> GetCodeunitNumber() then
            exit;

        ConfigPackageError.SetRange("Package Code", PackageCodeTxt);
        PAGE.RunModal(PAGE::"Config. Package Errors", ConfigPackageError);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUploadFile(var ServerFileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDownloadTemplate(var HideDialog: Boolean)
    begin
    end;

    local procedure InsertPackageTableAccount(var DataMigrationSetup: Record "Data Migration Setup")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCodeTxt, DATABASE::"G/L Account");
        ConfigPackageTable."Data Template" := DataMigrationSetup."Default Account Template";
        ConfigPackageTable.Modify();
        ConfigPackageManagement.InsertProcessingRuleCustom(
          ConfigTableProcessingRule, ConfigPackageTable, 100000, CODEUNIT::"Excel Post Processor");
    end;

    local procedure InsertPackageFieldsAccount()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", PackageCodeTxt);
        ConfigPackageField.SetRange("Table ID", DATABASE::"G/L Account");
        ConfigPackageField.DeleteAll(true);

        InsertPackageField(DATABASE::"G/L Account", 1, 1);     // No.
        InsertPackageField(DATABASE::"G/L Account", 2, 2);     // Name
        InsertPackageField(DATABASE::"G/L Account", 3, 3);     // Search Name
        InsertPackageField(DATABASE::"G/L Account", 4, 4);     // Account Type
        InsertPackageField(DATABASE::"G/L Account", 8, 5);     // Account Category
        InsertPackageField(DATABASE::"G/L Account", 9, 6);     // Income/Balance
        InsertPackageField(DATABASE::"G/L Account", 10, 7);    // Debit/Credit
        InsertPackageField(DATABASE::"G/L Account", 13, 8);    // Blocked
        InsertPackageField(DATABASE::"G/L Account", 43, 9);   // Gen. Posting Type
        InsertPackageField(DATABASE::"G/L Account", 44, 10);   // Gen. Bus. Posting Group
        InsertPackageField(DATABASE::"G/L Account", 45, 11);   // Gen. Prod. Posting Group
        InsertPackageField(DATABASE::"G/L Account", 80, 12);   // Account Subcategory Entry No.
    end;

    local procedure RemoveDemoData(var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        if ConfigPackageTable.Get(PackageCodeTxt, DATABASE::"G/L Account") then begin
            ConfigPackageRecord.SetRange("Package Code", ConfigPackageTable."Package Code");
            ConfigPackageRecord.SetRange("Table ID", ConfigPackageTable."Table ID");
            if ConfigPackageRecord.FindFirst() then begin
                ConfigPackageData.SetRange("Package Code", ConfigPackageRecord."Package Code");
                ConfigPackageData.SetRange("Table ID", ConfigPackageRecord."Table ID");
                if ConfigPackageData.FindFirst() then
                    CODEUNIT.Run(CODEUNIT::"Data Migration Del G/L Account");
            end;
        end;
    end;

    local procedure InsertAccountsFieldData(TableNo: Integer; RecordNo: Integer; FieldNo: Integer; Value: Text[250])
    var
        GLAccount: Record "G/L Account";
    begin
        if FieldNo = 4 then begin
            if Value = '0' then
                InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Type"::Posting))
            else
                if Value = '1' then
                    InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Type"::Heading))
                else
                    if Value = '2' then
                        InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Type"::Total))
                    else
                        if Value = '3' then
                            InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Type"::"Begin-Total"))
                        else
                            if Value = '4' then
                                InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Type"::"End-Total"))
        end else
            if FieldNo = 8 then begin
                if Value = '0' then
                    InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::" "))
                else
                    if Value = '1' then
                        InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::Assets))
                    else
                        if Value = '2' then
                            InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::Liabilities))
                        else
                            if Value = '3' then
                                InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::Equity))
                            else
                                if Value = '4' then
                                    InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::Income))
                                else
                                    if Value = '5' then
                                        InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::"Cost of Goods Sold"))
                                    else
                                        if Value = '6' then
                                            InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Account Category"::Expense))
            end else
                if FieldNo = 9 then begin
                    if Value = '0' then
                        InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Income/Balance"::"Income Statement"))
                    else
                        if Value = '1' then
                            InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Income/Balance"::"Balance Sheet"))
                end else
                    if FieldNo = 10 then begin
                        if Value = '0' then
                            InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Debit/Credit"::Both))
                        else
                            if Value = '1' then
                                InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Debit/Credit"::Debit))
                            else
                                if Value = '2' then
                                    InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Debit/Credit"::Credit))
                    end else
                        if FieldNo = 43 then begin
                            if Value = '0' then
                                InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Gen. Posting Type"::" "))
                            else
                                if Value = '1' then
                                    InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Gen. Posting Type"::Purchase))
                                else
                                    if Value = '2' then
                                        InsertFieldData(TableNo, RecordNo, FieldNo, Format(GLAccount."Gen. Posting Type"::Sale))
                        end else
                            InsertFieldData(TableNo, RecordNo, FieldNo, Value)
    end;
}

