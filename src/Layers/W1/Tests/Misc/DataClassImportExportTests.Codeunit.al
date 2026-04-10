codeunit 135156 "Data Class Import/Export Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Classification]      
    end;

    var
        DataClassImportExportTests: Codeunit "Data Class Import/Export Tests";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestImportExcelSheet()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassifImportExport: Codeunit "Data Classif. Import/Export";
    begin
        BindSubscription(DataClassImportExportTests);
        // [GIVEN] There are some Entries in Data Sensitivity Table
        DataSensitivity.DeleteAll();

        DataClassificationMgt.InsertDataSensitivityForField(3, 1, DataSensitivity."Data Sensitivity"::Unclassified);
        DataClassificationMgt.InsertDataSensitivityForField(3, 2, DataSensitivity."Data Sensitivity"::Unclassified);

        // [GIVEN] There are some Classification in the Excel Sheet
        // This happens on the Event Subscriber OnUploadExcelSheetubscriber

        // [WHEN] ImportExcelSheet function is called
        DataClassifImportExport.ImportExcelSheet();

        // [THEN] Data Sensitivities are filled
        DataSensitivity.Get(CompanyName, 3, 1);
        Assert.AreEqual(
          DataSensitivity."Data Sensitivity"::Normal,
          DataSensitivity."Data Sensitivity",
          'Field was expected to be Normal.');

        DataSensitivity.Get(CompanyName, 3, 2);
        Assert.AreEqual(
          DataSensitivity."Data Sensitivity"::Personal,
          DataSensitivity."Data Sensitivity",
          'Field was expected to be Personal.');

        UnbindSubscription(DataClassImportExportTests);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestExportExcelSheet()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassifImportExport: Codeunit "Data Classif. Import/Export";
    begin
        // [SCENARIO] An Excel Sheet can be generated with the contents of Data Sensitivity Table for current company

        BindSubscription(DataClassImportExportTests);
        // [GIVEN] There are some Entries in Data Sensitivity Table
        DataSensitivity.DeleteAll();

        DataClassificationMgt.InsertDataSensitivityForField(3, 1, DataSensitivity."Data Sensitivity"::Normal);
        DataClassificationMgt.InsertDataSensitivityForField(3, 2, DataSensitivity."Data Sensitivity"::Personal);
        InsertDataSensitivityFieldForAnotherCompany(3, 1, DataSensitivity."Data Sensitivity"::Unclassified);

        // [WHEN] ExportToExcelSheet function is called
        DataClassifImportExport.ExportToExcelSheet();

        // [THEN] An Excel File is generated with the correct data
        // Verify on the Event Subscriber OnOpenExcelSheetSubscriber

        UnbindSubscription(DataClassImportExportTests);
    end;

    local procedure InsertDataSensitivityFieldForAnotherCompany(TableNo: Integer; FieldNo: Integer; DataSensitivityOption: Option)
    var
        DataSensitivity: Record "Data Sensitivity";
        CompanyNameLen: Integer;
    begin
        DataSensitivity.Init();
        CompanyNameLen := MaxStrLen(DataSensitivity."Company Name");
        DataSensitivity."Company Name" := CopyStr(LibraryRandom.RandText(CompanyNameLen), 1, CompanyNameLen);
        DataSensitivity."Table No" := TableNo;
        DataSensitivity."Field No" := FieldNo;
        DataSensitivity."Data Sensitivity" := DataSensitivityOption;
        DataSensitivity.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classif. Import/Export", 'OnOpenExcelSheet', '', false, false)]
    local procedure OnOpenExcelSheetSubscriber(var ExcelBuffer: Record "Excel Buffer"; var ShouldOpenFile: Boolean)
    var
        DataSensitivity: Record "Data Sensitivity";
        "Field": Record "Field";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        ShouldOpenFile := false;
        Assert.RecordCount(ExcelBuffer, 21); // 3 rows * 7 columns
        ExcelBuffer.Get(2, 1);
        Assert.AreEqual('3', ExcelBuffer."Cell Value as Text", 'Table Number was expected to be 3.');
        ExcelBuffer.Get(2, 2);
        Assert.AreEqual('1', ExcelBuffer."Cell Value as Text", 'Field Number was expected to be 1.');
        ExcelBuffer.Get(2, 3);
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, 3);
        Assert.AreEqual(
          AllObjWithCaption."Object Caption",
          ExcelBuffer."Cell Value as Text",
          'A different table caption was expected.');
        ExcelBuffer.Get(2, 4);
        Field.Get(3, 1);
        Assert.AreEqual(Field."Field Caption", ExcelBuffer."Cell Value as Text", 'A different field caption was expected.');
        ExcelBuffer.Get(2, 5);
        Assert.AreEqual(Format(Field.Type), ExcelBuffer."Cell Value as Text", 'A different field type was expected.');
        ExcelBuffer.Get(2, 6);
        Assert.AreEqual(
          Format(DataSensitivity."Data Sensitivity"::Normal),
          ExcelBuffer."Cell Value as Text",
          'A different field sensitivity was expected.');
        ExcelBuffer.Get(2, 7);
        Assert.AreEqual(
          Format(DataSensitivity."Data Classification"::CustomerContent),
          ExcelBuffer."Cell Value as Text",
          'A different data classification was expected'
        );

        ExcelBuffer.Get(3, 1);
        Assert.AreEqual('3', ExcelBuffer."Cell Value as Text", 'Table Number was expected to be 3.');
        ExcelBuffer.Get(3, 2);
        Assert.AreEqual('2', ExcelBuffer."Cell Value as Text", 'Field Number was expected to be 2.');
        ExcelBuffer.Get(3, 3);
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, 3);
        Assert.AreEqual(
          AllObjWithCaption."Object Caption",
          ExcelBuffer."Cell Value as Text",
          'A different table caption was expected.');
        ExcelBuffer.Get(3, 4);
        Field.Get(3, 2);
        Assert.AreEqual(Field."Field Caption", ExcelBuffer."Cell Value as Text", 'A different field caption was expected.');
        ExcelBuffer.Get(3, 5);
        Assert.AreEqual(Format(Field.Type), ExcelBuffer."Cell Value as Text", 'A different field type was expected.');
        ExcelBuffer.Get(3, 6);
        Assert.AreEqual(
          Format(DataSensitivity."Data Sensitivity"::Personal),
          ExcelBuffer."Cell Value as Text",
          'A different field sensitivity was expected.');
        ExcelBuffer.Get(3, 7);
        Assert.AreEqual(
          Format(DataSensitivity."Data Classification"::CustomerContent),
          ExcelBuffer."Cell Value as Text",
          'A different data classification was expected'
        );
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classif. Import/Export", 'OnUploadExcelSheet', '', false, false)]
    local procedure OnUploadExcelSheetSubscriber(var ExcelBuffer: Record "Excel Buffer"; var ShouldUploadFile: Boolean)
    begin
        ShouldUploadFile := false;
        FillExcelBuffer(ExcelBuffer);
    end;

    [Scope('OnPrem')]
    procedure FillExcelBuffer(var ExcelBuffer: Record "Excel Buffer")
    begin
        InsertValueInExcelBuffer(ExcelBuffer, 1, 1, 'Header 1');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 2, 'Header 2');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 3, 'Header 3');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 4, 'Header 4');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 5, 'Header 5');
        InsertValueInExcelBuffer(ExcelBuffer, 1, 6, 'Header 6');

        InsertValueInExcelBuffer(ExcelBuffer, 2, 1, '3');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 2, '1');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 3, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 4, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 5, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 2, 6, 'Normal');

        InsertValueInExcelBuffer(ExcelBuffer, 3, 1, '3');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 2, '2');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 3, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 4, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 5, 'some value');
        InsertValueInExcelBuffer(ExcelBuffer, 3, 6, 'Personal');
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InsertValueInExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColumnNo: Integer; Value: Text[250])
    begin
        ExcelBuffer."Row No." := RowNo;
        ExcelBuffer."Column No." := ColumnNo;
        ExcelBuffer."Cell Value as Text" := Value;
        ExcelBuffer.Insert();
    end;
}

