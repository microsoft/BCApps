codeunit 132541 "Test Bank Mapping Generic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Mapping]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        TableErrorMsg: Label '%1 Line:%2';
        AssertMsg: Label '%1 Field:"%2" different from expected.';
        MissingValueErr: Label 'The file that you are trying to import, %1, is different from the specified %2, %3.\\The value in line %4, column %5 is missing.', Comment = 'N/A';
        IncorrectFormatOrTypeErr: Label 'The file that you are trying to import, %1, is different from the specified %2, %3.\\The value in line %4, column %5 has incorrect format or type.\Expected format: %6, according to the %7 and %8 of the %9.\Actual value: "%10"', Comment = 'N/A';
        ExpectedErrorFailedErr: Label 'Assert.ExpectedError failed. Expected: %1. Actual: %2.';

    [Test]
    [Scope('OnPrem')]
    procedure TestImportMultiRowMultiColumns()
    var
        AllObj: Record AllObj;
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempExpectedTestDataExchDestTable: Record "Test Data Exch. Dest Table" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        AllObj.SetRange("Object Type", AllObj."Object Type"::XMLport);
        AllObj.FindFirst();
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", AllObj."Object ID", 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchDef.Modify(true); // Adds test coverage.
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'SomeTextColumn   ',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'SomeDateColumn   ',
          true, DataExchColumnDef."Data Type"::Date, 'ddMMyyyy', 'da-DK', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 3, 'SomeDecimalColumn',
          true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.Modify(true);  // Adds test coverage.

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 2, 3, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 3, 4, false, 1);

        // Generate Input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Text1', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 2, '01012013', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 3, '1234', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'Text2', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 2, '02022013', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 3, '5678', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 3, 1, 'A text that is to long for the destination field', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 3, 2, '02022013', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 3, 3, '5678', DataExchLineDef.Code);

        // Run Mapping
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify Table Layout
        TempExpectedTestDataExchDestTable.InsertRec(10000, 'Text1', DMY2Date(1, 1, 2013), 1234, 1, 'SOMECODE', 'NONE', DataExch."Entry No.", 1);
        TempExpectedTestDataExchDestTable.InsertRec(20000, 'Text2', DMY2Date(2, 2, 2013), 5678, 1, 'SOMECODE', 'NONE', DataExch."Entry No.", 2);
        TempExpectedTestDataExchDestTable.InsertRec(30000, 'A text that is to long for the', DMY2Date(2, 2, 2013), 5678, 1, 'SOMECODE', 'NONE',
          DataExch."Entry No.", 3);
        AssertDataInTable(TempExpectedTestDataExchDestTable, TestDataExchDestTable, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportMissingColumns()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'SomeTextColumn   ',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'SomeDateColumn   ',
          true, DataExchColumnDef."Data Type"::Date, 'ddMMyyyy', 'da-DK', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 3, 'SomeDecimalColumn',
          true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 2, 3, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 3, 4, false, 1);

        // Generate Input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\FileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Text1', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 2, '01012013', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'Text2', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 2, '02022013', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 3, '5678', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        asserterror ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify Table Layout
        AssertExpectedError(
          StrSubstNo(MissingValueErr, 'C:\FileName.txt', DataExchDef.Type::"Bank Statement Import",
            DataExchDef.Code, 1, 3));
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingMultipleColumnsToOneField()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'TextColumn1', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'TextColumn2', true, DataExchColumnDef."Data Type"::Text, '', '', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 2, 2, false, 0);

        // Generate Input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'abcOverflowChars', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual('ABCDEFGHIJKLMNOPQRSTUVWXYZ abc', RecRef.Field(2).Value, 'The values were not concatenated as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingRepeatedColumnToOneField()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'TextColumn1', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'TextColumn2', true, DataExchColumnDef."Data Type"::Text, '', '', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);

        // Generate Input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '1-1', 'Instance1Line1', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '1-2', 'Instance2Line1', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 2, '1-3', 'AnyText', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 2, 1, '2-1', 'Instance1Line2', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual('Instance1Line1 Instance2Line1', RecRef.Field(2).Value, 'The values were not concatenated as expected');
        RecRef.Next();
        Assert.AreEqual('Instance1Line2', RecRef.Field(2).Value, 'The values were not concatenated as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingRepeatedColumnToOneFieldTrimTrailingSpaces()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'TextColumn1', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'TextColumn2', true, DataExchColumnDef."Data Type"::Text, '', '', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);

        // Generate Input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '1-1', 'L1C1Inst1   ', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '1-2', 'L1C1Inst2   ', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 2, '1-3', 'AnyText   ', DataExchLineDef.Code);
        DataExchField.InsertRecXMLField(DataExch."Entry No.", 2, 1, '2-1', 'L2C1Inst2   ', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual('L1C1Inst1 L1C1Inst2', RecRef.Field(2).Value, 'The values were not trimmed as expected');
        RecRef.Next();
        Assert.AreEqual('L2C1Inst2', RecRef.Field(2).Value, 'The value was not trimmed as expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingOptionalField()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'SomeTextColumn',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'SomeDateColumn',
          true, DataExchColumnDef."Data Type"::Date, 'ddMMyyyy', 'da-DK', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 3, 'SomeDecimalColumn',
          true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 2, false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 2, 3, true, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 3, 4, false, 1);

        // Generate Input Table (skip optional field)
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Text1', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 3, '5678', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual('Text1', RecRef.Field(2).Value, '');
        Assert.AreEqual('', Format(RecRef.Field(3).Value), '');
        Assert.AreEqual(5678, RecRef.Field(4).Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingCreditField()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'Amount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 2, 'Credit/Debit', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef."Negative-Sign Identifier" := 'CRDT';
        DataExchColumnDef.Modify(true);

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 'Test Mapping', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 1, 4, false, 1);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", 2, 4, false, 0);

        // Generate Input Table (skip optional field)
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, '123', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'CRDT', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 1, '456.70', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 2, 2, 'DBIT', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 3, 1, '0', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 3, 2, 'CRDT', DataExchLineDef.Code);

        // Exercise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual(-123, RecRef.Field(4).Value, '');
        RecRef.Next();
        Assert.AreEqual(456.7, RecRef.Field(4).Value, '');
        RecRef.Next();
        Assert.AreEqual(0, RecRef.Field(4).Value, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonIntegerPrimaryKey()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
        CustName: Text[250];
    begin
        // Setup file definition
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Definition for non-integer key',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'SomeTextColumn   ', true, DataExchColumnDef."Data Type"::Text, '', '', '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::Customer, 'Test Mapping', 0, 0, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::Customer, 1, 2, false, 1);

        // Generate Input Table (skip optional field)
        CustName := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer);
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, CustName, DataExchLineDef.Code);

        // Exercise
        RecRef.GetTable(Customer);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        Customer.SetRange(Name, CustName);
        Customer.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShortTextMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Text, '', '', 'A short text', 2, 0, 'A short text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLongTextMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(
          1, DataExchColumnDef."Data Type"::Text, '', '', 'A text that is to long for the destination field', 2, 0,
          'A text that is to long for the');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTextMappingWithNonZeroMultiplier()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Text, '', '', 'A short text', 2, 1, 'A short text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateddMMyyyyMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Date, 'ddMMyyyy', 'da-DK', '10112021', 3, 0, DMY2Date(10, 11, 2021));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateddMMyyWithDashMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Date, 'dd-MM-yy', 'da-DK', '09-10-23', 3, 0, DMY2Date(9, 10, 2023));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateMMddyyForwardSlashMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Date, 'MM/dd/yy', 'en-US', '09/10/23', 3, 0, DMY2Date(10, 9, 2023));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateyyyyMMddNoSeparatorMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Date, 'yyyyMMdd', 'en-US', '20120227', 3, 0, DMY2Date(27, 2, 2012));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorInTypeNotADate()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ErrorMsg: Text[1024];
    begin
        ErrorMsg :=
          StrSubstNo(IncorrectFormatOrTypeErr, '%1', '%2', '%3', 1, 1, 'Date', DataExchColumnDef.FieldCaption("Data Format"),
            DataExchColumnDef.FieldCaption("Data Formatting Culture"), DataExchColumnDef.TableCaption(), 'This is not a date 010101');

        VerifyFieldMappingError(1, DataExchColumnDef."Data Type"::Date, 'yyyy-MM-dd', 'en-US', 'This is not a date 010101', 3, 0, ErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorInWrongFormatedDate()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ErrorMsg: Text[1024];
    begin
        ErrorMsg :=
          StrSubstNo(IncorrectFormatOrTypeErr, '%1', '%2', '%3', 1, 1, 'Date', DataExchColumnDef.FieldCaption("Data Format"),
            DataExchColumnDef.FieldCaption("Data Formatting Culture"), DataExchColumnDef.TableCaption(), '010102');

        VerifyFieldMappingError(1, DataExchColumnDef."Data Type"::Date, 'ddMMyyyy', 'en-US', '010102', 3, 0, ErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecimalDotSeperatorMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '12,345.67', 4, 1, 12345.67);
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '12345.67', 4, 1, 12345.67);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecimalCommaSeperatorMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Decimal, '', 'da-DK', '12.345,67', 4, 1, 12345.67);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecimalWithNonZeroMapping()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '12,345.67', 4, -100, -1234567);
        VerifyFieldMapping(1, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '12345.67', 4, 0.01, 123.4567);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorInTypeNotDecimal()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ErrorMsg: Text[1024];
    begin
        ErrorMsg :=
          StrSubstNo(IncorrectFormatOrTypeErr, '%1', '%2', '%3', 1, 1, 'Decimal', DataExchColumnDef.FieldCaption("Data Format"),
            DataExchColumnDef.FieldCaption("Data Formatting Culture"), DataExchColumnDef.TableCaption(), 'This is not a decimal 123');

        VerifyFieldMappingError(1, DataExchColumnDef."Data Type"::Decimal, '', 'da-DK', 'This is not a decimal 123', 4, 1, ErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorInWrongDecimalFormat()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ErrorMsg: Text[1024];
    begin
        ErrorMsg :=
          StrSubstNo(IncorrectFormatOrTypeErr, '%1', '%2', '%3', 1, 1, 'Decimal', DataExchColumnDef.FieldCaption("Data Format"),
            DataExchColumnDef.FieldCaption("Data Formatting Culture"), DataExchColumnDef.TableCaption(), '12,345,670');

        VerifyFieldMappingError(1, DataExchColumnDef."Data Type"::Decimal, '', 'da-DK', '12,345,670', 4, 1, ErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorNonSupportedType()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        VerifyFieldMappingError(1, DataExchColumnDef."Data Type"::Date, '', '', 'Yes', 10, 0, 'Boolean field, which is not supported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOnDataLinePositive()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup file definition
        DataExchDef.InsertRec(
          LibraryUtility.GenerateGUID(), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchLineDef."Data Line Tag" := LibraryUtility.GenerateGUID();
        DataExchLineDef.Modify();

        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'Amount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.Path := CopyStr(DataExchLineDef."Data Line Tag" + DataExchColumnDef.Name, 1, MaxStrLen(DataExchColumnDef.Path));
        DataExchColumnDef.Modify();

        // Verify.
        Assert.IsTrue(DataExchColumnDef.IsOfDataLine(), 'Column should be on the data line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOnDataLineNegative()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup file definition
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchLineDef."Data Line Tag" := LibraryUtility.GenerateGUID();
        DataExchLineDef.Modify();

        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'Amount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.Path := CopyStr(DataExchLineDef."Data Line Tag", 1, StrLen(DataExchLineDef."Data Line Tag") - 1);
        DataExchColumnDef.Modify();

        // Verify.
        Assert.IsFalse(DataExchColumnDef.IsOfDataLine(), 'Column should not be on the data line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOnDataLineFlatFile()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup file definition
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchDef."File Type" := DataExchDef."File Type"::"Fixed Text";
        DataExchDef.Modify();
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'Amount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.Path := LibraryUtility.GenerateGUID();
        DataExchColumnDef.Modify();

        // Verify.
        Assert.IsTrue(DataExchColumnDef.IsOfDataLine(), 'Column should be on the data line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOnEmptyDataLine()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup file definition
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'Just a Test Mapping',
          DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'Amount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.Path := LibraryUtility.GenerateGUID();
        DataExchColumnDef.Modify();

        // Verify.
        Assert.IsTrue(DataExchColumnDef.IsOfDataLine(), 'Column should be on the data line.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingForOption()
    var
        AllObj: Record AllObj;
        DataExch: Record "Data Exch.";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DummyDataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        TempBlob: Codeunit "Temp Blob";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        InStream: InStream;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379670] Field mapping should work for fields with Option type

        AllObj.SetRange("Object Type", AllObj."Object Type"::XMLport);
        AllObj.FindFirst();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), LibraryUTUtility.GetNewCode10(),
          DataExchDef.Type::"Generic Import", AllObj."Object ID", 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(
          DataExchDef.Code, DataExchLineDef.Code, 1, LibraryUTUtility.GetNewCode10(), true, DataExchColumnDef."Data Type"::Text, '', '', '');

        RecRef.GetTable(CurrencyExchangeRate);

        DummyDataExchFieldMapping."Data Exch. Def Code" := DataExchDef.Code;
        DummyDataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DummyDataExchFieldMapping."Field ID" := CurrencyExchangeRate.FieldNo("Fix Exchange Rate Amount");

        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec(LibraryUTUtility.GetNewCode10(), InStream, DataExchDef.Code);
        DataExchField.InsertRec(
          DataExch."Entry No.", 1, 1, Format(CurrencyExchangeRate."Fix Exchange Rate Amount"::Both), DataExchLineDef.Code);

        ProcessDataExch.SetField(RecRef, DummyDataExchFieldMapping, DataExchField, Integer);
        FieldRef := RecRef.Field(CurrencyExchangeRate.FieldNo("Fix Exchange Rate Amount"));
        FieldRef.TestField(Format(CurrencyExchangeRate."Fix Exchange Rate Amount"::Both));
    end;

    local procedure VerifyFieldMapping(ColumnNo: Integer; DataType: Option; DataFormat: Text[30]; DataFormattingCulture: Text[10]; InputText: Text[250]; FieldNo: Integer; Multiplier: Decimal; ExpectedValue: Variant)
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), '', DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', ColumnNo, 'SomeColumn', true, DataType, DataFormat, DataFormattingCulture, '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", '', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", ColumnNo, FieldNo, false, Multiplier);

        // Generate input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, ColumnNo, InputText, DataExchLineDef.Code);

        // Execise
        CreateTemplate(RecRef, TestDataExchDestTable);
        ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        TestDataExchDestTable.FindFirst();
        RecRef.GetTable(TestDataExchDestTable);
        Assert.AreEqual(ExpectedValue, RecRef.Field(FieldNo).Value, '');
    end;

    local procedure VerifyFieldMappingError(ColumnNo: Integer; DataType: Option; DataFormat: Text[30]; DataFormattingCulture: Text[10]; InputText: Text[250]; FieldNo: Integer; Multiplier: Decimal; ExpectedError: Text[1024])
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TestDataExchDestTable: Record "Test Data Exch. Dest Table";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        // Setup file definition
        TestDataExchDestTable.DeleteAll();
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), '', DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', ColumnNo, 'SomeColumn', true, DataType, DataFormat, DataFormattingCulture, '');

        // Setup file mapping
        DataExchMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", '', 0,
          TestDataExchDestTable.FieldNo(ExchNo), TestDataExchDestTable.FieldNo(LineNo));
        DataExchFieldMapping.InsertRec(DataExchDef.Code, '', DATABASE::"Test Data Exch. Dest Table", ColumnNo, FieldNo, false, Multiplier);

        // Generate input Table
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, ColumnNo, InputText, DataExchLineDef.Code);

        // Execise
        CreateTemplate(RecRef, TestDataExchDestTable);
        asserterror ProcessDataExchColumnMapping(DataExch, RecRef);

        // Verify
        AssertExpectedError(StrSubstNo(ExpectedError, '', DataExchDef.Type::"Bank Statement Import", DataExchDef.Code));
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    local procedure CreateTemplate(var RecRef: RecordRef; var TestDataExchDestTable: Record "Test Data Exch. Dest Table")
    begin
        TestDataExchDestTable.Init();
        TestDataExchDestTable.KeyH1 := 1;
        TestDataExchDestTable.KeyH2 := 'SomeCode';
        TestDataExchDestTable.NonKey := 'None';
        RecRef.GetTable(TestDataExchDestTable);
    end;

    local procedure AssertDataInTable(var ExpectedTestDataExchDestTable: Record "Test Data Exch. Dest Table"; var ActualTestDataExchDestTable: Record "Test Data Exch. Dest Table"; Msg: Text)
    var
        LineNo: Integer;
    begin
        ExpectedTestDataExchDestTable.FindFirst();
        ActualTestDataExchDestTable.FindFirst();
        repeat
            LineNo += 1;
            AreEqualRecords(ExpectedTestDataExchDestTable, ActualTestDataExchDestTable, StrSubstNo(TableErrorMsg, Msg, LineNo));
        until (ExpectedTestDataExchDestTable.Next() = 0) or (ActualTestDataExchDestTable.Next() = 0);
        Assert.AreEqual(ExpectedTestDataExchDestTable.Count, ActualTestDataExchDestTable.Count, 'Row count does not match');
    end;

    local procedure AreEqualRecords(ExpectedRecord: Variant; ActualRecord: Variant; Msg: Text)
    var
        ExpectedRecRef: RecordRef;
        ActualRecRef: RecordRef;
        i: Integer;
    begin
        ExpectedRecRef.GetTable(ExpectedRecord);
        ActualRecRef.GetTable(ActualRecord);

        Assert.AreEqual(ExpectedRecRef.Number, ActualRecRef.Number, 'Tables are not the same');

        for i := 1 to ExpectedRecRef.FieldCount do
            if IsSupportedType(ExpectedRecRef.FieldIndex(i).Value) then
                Assert.AreEqual(ExpectedRecRef.FieldIndex(i).Value, ActualRecRef.FieldIndex(i).Value,
                  StrSubstNo(AssertMsg, Msg, ExpectedRecRef.FieldIndex(i).Name));
    end;

    local procedure IsSupportedType(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsTime);
    end;

    local procedure AssertExpectedError(Expected: Text[1024])
    begin
        if StrPos(GetLastErrorText, Expected) = 0 then
            Error(ExpectedErrorFailedErr, Expected, GetLastErrorText);
    end;

    local procedure ProcessDataExchColumnMapping(DataExch: Record "Data Exch."; RecRef: RecordRef)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        ProcessDataExch: Codeunit "Process Data Exch.";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst();
        ProcessDataExch.ProcessColumnMapping(DataExch, DataExchLineDef, RecRef);
    end;
}

