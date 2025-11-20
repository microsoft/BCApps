// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Privacy;
using System.IO;
using System.Reflection;

codeunit 1754 "Data Classif. Import/Export"
{

    trigger OnRun()
    begin
    end;

    var
        ImportTitleTxt: Label 'Choose the Excel worksheet where data classifications have been added.';
        ExcelFileNameTxt: Label 'Classifications.xlsx';
        WrongFormatExcelFileErr: Label 'Looks like the Excel worksheet you provided is not formatted correctly.';
        WrongSensitivityValueErr: Label '%1 is not a valid classification. Classifications can be %2.', Comment = '%1=Given Sensitivity %2=Available Options';

    [Scope('OnPrem')]
    procedure ImportExcelSheet()
    var
        DataSensitivity: Record "Data Sensitivity";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        ShouldUploadFile: Boolean;
    begin
        DataSensitivity.SetRange("Company Name", CompanyName);
        if DataSensitivity.IsEmpty() then
            DataClassificationMgt.PopulateDataSensitivityTable();

        ShouldUploadFile := true;
        OnUploadExcelSheet(TempExcelBuffer, ShouldUploadFile);

        if ShouldUploadFile then
            ReadExcelSheet(TempExcelBuffer);

        ProcessExcelSheet(TempExcelBuffer);

        TempExcelBuffer.CloseBook();
    end;

    local procedure ReadExcelSheet(var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        FileManagement: Codeunit "File Management";
        DataClassificationWorksheet: Page "Data Classification Worksheet";
        ExcelStream: InStream;
        FileName: Text;
    begin
        FileName := '';
        UploadIntoStream(ImportTitleTxt, '',
          FileManagement.GetToFilterText('', ExcelFileNameTxt), FileName, ExcelStream);

        if FileName = '' then
            Error('');

        TempExcelBuffer.OpenBookStream(ExcelStream, DataClassificationWorksheet.Caption);
        TempExcelBuffer.ReadSheet();
    end;

    local procedure ProcessExcelSheet(var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        TableNoColumn: Integer;
        FieldNoColumn: Integer;
        ClassColumn: Integer;
        NumberOfRows: Integer;
        NumberOfColumns: Integer;
        RowIndex: Integer;
        TableNo: Integer;
        FieldNo: Integer;
    begin
        if TempExcelBuffer.FindLast() then;

        NumberOfRows := TempExcelBuffer."Row No.";
        NumberOfColumns := TempExcelBuffer."Column No.";
        if (NumberOfRows < 2) or (NumberOfColumns < 6) then
            Error(WrongFormatExcelFileErr);

        TableNoColumn := 1;
        FieldNoColumn := 2;
        ClassColumn := 6;

        for RowIndex := 2 to NumberOfRows do begin
            TableNo := GetValueAtRowAndColumn(TempExcelBuffer, RowIndex, TableNoColumn);

            if TableNo <> 0 then begin
                FieldNo := GetValueAtRowAndColumn(TempExcelBuffer, RowIndex, FieldNoColumn);

                if FieldNo <> 0 then
                    if TempExcelBuffer.Get(RowIndex, ClassColumn) then
                        UpdateDataSensitivity(TableNo, FieldNo, TempExcelBuffer."Cell Value as Text");
            end;
        end;
    end;

    local procedure GetValueAtRowAndColumn(var TempExcelBuffer: Record "Excel Buffer" temporary; RowIndex: Integer; ColumnIndex: Integer): Integer
    var
        Value: Integer;
    begin
        if TempExcelBuffer.Get(RowIndex, ColumnIndex) then
            Evaluate(Value, TempExcelBuffer."Cell Value as Text");

        exit(Value);
    end;

    local procedure UpdateDataSensitivity(TableNo: Integer; FieldNo: Integer; ClassValue: Text)
    var
        DataSensitivity: Record "Data Sensitivity";
        TypeHelper: Codeunit "Type Helper";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Class: Integer;
    begin
        if DataSensitivity.Get(CompanyName, TableNo, FieldNo) then begin
            Class := TypeHelper.GetOptionNo(ClassValue, DataClassificationMgt.GetDataSensitivityOptionString());

            if Class < 0 then begin
                // Try the English version
                RecordRef.Open(DATABASE::"Data Sensitivity");
                FieldRef := RecordRef.Field(DataSensitivity.FieldNo("Data Sensitivity"));
                Class := TypeHelper.GetOptionNo(ClassValue, FieldRef.OptionMembers);
                RecordRef.Close();
            end;

            if Class < 0 then
                Error(WrongSensitivityValueErr, ClassValue, DataClassificationMgt.GetDataSensitivityOptionString());

            if Class <> DataSensitivity."Data Sensitivity"::Unclassified then
                ClassifyDataSensitivity(DataSensitivity, Class);
        end;
    end;

    local procedure ClassifyDataSensitivity(DataSensitivity: Record "Data Sensitivity"; Class: Integer)
    begin
        DataSensitivity.Validate("Data Sensitivity", Class);
        DataSensitivity.Validate("Last Modified By", UserSecurityId());
        DataSensitivity.Validate("Last Modified", CurrentDateTime);
        DataSensitivity.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ExportToExcelSheet()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        ShouldOpenFile: Boolean;
    begin
        DataSensitivity.SetRange("Company Name", CompanyName);
        if not DataSensitivity.FindFirst() then
            DataClassificationMgt.PopulateDataSensitivityTable();

        CreateExcelSheet(TempExcelBuffer, DataSensitivity);

        ShouldOpenFile := true;
        OnOpenExcelSheet(TempExcelBuffer, ShouldOpenFile);
        if ShouldOpenFile then
            TempExcelBuffer.OpenExcelWithName(ExcelFileNameTxt);
    end;

    local procedure CreateExcelSheet(var TempExcelBuffer: Record "Excel Buffer" temporary; var DataSensitivity: Record "Data Sensitivity")
    var
        DataClassificationWorksheet: Page "Data Classification Worksheet";
    begin
        TempExcelBuffer.CreateNewBook(DataClassificationWorksheet.Caption);

        CreateExcelSheetColumnHeaders(TempExcelBuffer, DataSensitivity);

        CreateExcelSheetRows(TempExcelBuffer, DataSensitivity);

        TempExcelBuffer.WriteSheet(DataClassificationWorksheet.Caption, CompanyName, UserId);

        TempExcelBuffer.CloseBook();
    end;

    local procedure CreateExcelSheetColumnHeaders(var TempExcelBuffer: Record "Excel Buffer" temporary; DataSensitivity: Record "Data Sensitivity")
    begin
        TempExcelBuffer.NewRow();

        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Table No"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Field No"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Table Caption"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Field Caption"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Field Type"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Data Sensitivity"));
        AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity.FieldName("Data Classification"));
    end;

    local procedure CreateExcelSheetRows(var TempExcelBuffer: Record "Excel Buffer" temporary; var DataSensitivity: Record "Data Sensitivity")
    begin
        if DataSensitivity.FindSet() then
            repeat
                DataSensitivity.CalcFields("Table Caption");
                DataSensitivity.CalcFields("Field Caption");
                DataSensitivity.CalcFields("Field Type");

                if (DataSensitivity."Table Caption" <> '') and (DataSensitivity."Field Caption" <> '') then begin
                    TempExcelBuffer.NewRow();

                    AddNumericColumnToExcelSheet(TempExcelBuffer, DataSensitivity."Table No");
                    AddNumericColumnToExcelSheet(TempExcelBuffer, DataSensitivity."Field No");
                    AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity."Table Caption");
                    AddTextColumnToExcelSheet(TempExcelBuffer, DataSensitivity."Field Caption");
                    AddDataTypeColumn(TempExcelBuffer, DataSensitivity);
                    AddDataSensitivityColumn(TempExcelBuffer, DataSensitivity);
                    AddTextColumnToExcelSheet(TempExcelBuffer, Format(DataSensitivity."Data Classification", 0, '<Text>'));
                end;
            until DataSensitivity.Next() = 0;
    end;

    local procedure AddTextColumnToExcelSheet(var TempExcelBuffer: Record "Excel Buffer" temporary; Text: Text)
    begin
        TempExcelBuffer.AddColumn(Text, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure AddNumericColumnToExcelSheet(var TempExcelBuffer: Record "Excel Buffer" temporary; Number: Integer)
    begin
        TempExcelBuffer.AddColumn(Number, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
    end;

    local procedure AddDataTypeColumn(var TempExcelBuffer: Record "Excel Buffer" temporary; DataSensitivity: Record "Data Sensitivity")
    var
        "Field": Record "Field";
        FieldTypeText: Text;
    begin
        DataSensitivity.CalcFields("Field Type");

        // Running FORMAT on DataSensitivity."Field Type" does not retrieve the option caption; the value must be
        // assigned to Field.Type and then FORMAT will work correctly
        Field.Type := DataSensitivity."Field Type";

        FieldTypeText := Format(Field.Type, 0, '<Text>');

        TempExcelBuffer.AddColumn(FieldTypeText, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure AddDataSensitivityColumn(var TempExcelBuffer: Record "Excel Buffer" temporary; DataSensitivity: Record "Data Sensitivity")
    var
        DataPrivacyEntities: Record "Data Privacy Entities";
    begin
        DataPrivacyEntities."Default Data Sensitivity" := DataSensitivity."Data Sensitivity";
        AddTextColumnToExcelSheet(TempExcelBuffer, Format(DataPrivacyEntities."Default Data Sensitivity", 0, '<Text>'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenExcelSheet(var ExcelBuffer: Record "Excel Buffer"; var ShouldOpenFile: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUploadExcelSheet(var ExcelBuffer: Record "Excel Buffer"; var ShouldUploadFile: Boolean)
    begin
    end;
}

