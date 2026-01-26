codeunit 142007 "Data Export Test Suite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Export]

        IsInitialized := false;
    end;

    var
        DataExportManagement: Codeunit "Data Export Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        GLAccTxt: Label 'GLAcc 2022';
        FAAccTxt: Label 'FAAcc 2022';
        ItemAccTxt: Label 'Item 2022';
        GLAccRenamedTxt: Label 'GLAcc22~1';
        FAAccRenamedTxt: Label 'FAAcc22~1';
        ItemAccRenamedTxt: Label 'Item 22~1';

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_SpecialSymbols()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has special characters replaces with converted values.
        // [SCENARIO 418608] Run function FormatForIndexXML of Data Export Management codeunit on strings with special characters.
        Initialize();

        // [GIVEN] Input string with any symbols of: ~!$^&*(){}[]\|;:"?/,<>@#`.-+=
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] Result does not contain symbols <, >, &, ' (single quote), " (double quote) and contains other special symbols.

        Assert.AreEqual('ab(){}[]cd', DataExportManagement.FormatForIndexXML('ab(){}[]<>cd'), '');
        Assert.AreEqual('ef+-=*/.gh', DataExportManagement.FormatForIndexXML('ef+-=*/.gh'), '');
        Assert.AreEqual('ij;:,!?kl', DataExportManagement.FormatForIndexXML('ij;:,!?kl'), '');
        Assert.AreEqual('mn$#@~^op', DataExportManagement.FormatForIndexXML('mn$#@&~^op'), '');
        Assert.AreEqual('qr|\`st', DataExportManagement.FormatForIndexXML('qr|\"`''st'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_GermanSymbols()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has German special characters replaces with converted values.
        Initialize();

        // [GIVEN] Input string with any symbols of: Ä ä Ö ö Ü ü ß
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] Result should not contain any special symbols

        Assert.AreEqual('Ae__ae', DataExportManagement.FormatForIndexXML('Ä__ä'), '');
        Assert.AreEqual('Oe__oe', DataExportManagement.FormatForIndexXML('Ö__ö'), '');
        Assert.AreEqual('Ue__ue', DataExportManagement.FormatForIndexXML('Ü__ü'), '');
        Assert.AreEqual('Strasse', DataExportManagement.FormatForIndexXML('Straße'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatForIndexXML_LongText()
    var
        InputTxt: Text[1024];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363817] The index.xml file created from the Business Data Export has maximum length of 50.
        Initialize();

        // [GIVEN] Input string with the length bigger then 50
        // [WHEN] DataExportManagement.FormatForIndexXML() is invoked
        // [THEN] The length of result should be 50 

        InputTxt := LibraryRandom.RandText(1024);
        Assert.AreEqual(CopyStr(InputTxt, 1, 50), DataExportManagement.FormatForIndexXML(InputTxt), '');
    end;

    procedure RunFormatFileNameOnSpecialSymbols()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418608] Run function FormatFileName of Data Export Management codeunit on strings with special characters.
        Initialize();

        // [GIVEN] Input string with any symbols of: ~!$^&*(){}[]\|;:"?/,<>@#`.-+=
        // [WHEN] DataExportManagement.FormatFileName() is invoked.
        // [THEN] Result does not contain any special symbols.

        Assert.AreEqual('abcd', DataExportManagement.FormatFileName('ab(){}[]<>cd'), '');
        Assert.AreEqual('efgh', DataExportManagement.FormatFileName('ef+-=*/.gh'), '');
        Assert.AreEqual('ijkl', DataExportManagement.FormatFileName('ij;:,!?kl'), '');
        Assert.AreEqual('mnop', DataExportManagement.FormatFileName('mn$#@&~^op'), '');
        Assert.AreEqual('qrst', DataExportManagement.FormatFileName('qr|\"`''st'), '');
    end;

    [Test]
    procedure DataExportTemplatesWhenOpenDataExportsPage()
    var
        DataExport: Record "Data Export";
        DataExportRecType: Record "Data Export Record Type";
        DataExportRecDef: Record "Data Export Record Definition";
        DataExports: TestPage "Data Exports";
    begin
        // [SCENARIO 418608] Three Data Export templates are created when "Data Exports" page is opened.
        Initialize();

        // [WHEN] Page "Data Exports" is opened.
        DataExports.OpenEdit();

        // [THEN] Template "GLAcc 2022" is created.
        DataExport.Get(GLAccTxt);
        DataExportRecType.Get(GLAccTxt);
        DataExportRecDef.Get(GLAccTxt, GLAccTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 14);

        // [THEN] Template "FAAcc 2022" is created.
        DataExport.Get(FAAccTxt);
        DataExportRecType.Get(FAAccTxt);
        DataExportRecDef.Get(FAAccTxt, FAAccTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 4);

        // [THEN] Template "Item 2022" is created.
        DataExport.Get(ItemAccTxt);
        DataExportRecType.Get(ItemAccTxt);
        DataExportRecDef.Get(ItemAccTxt, ItemAccTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 4);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
    end;

    [Test]
    procedure DataExportSetupWhenDataExportTemplatesAreCreated()
    var
        DataExport: Record "Data Export";
        DataExportSetup: Record "Data Export Setup";
        DataExports: TestPage "Data Exports";
    begin
        // [SCENARIO 418608] Data Export template codes are written to Data Export Setup when templates are created.
        Initialize();

        // [WHEN] Page "Data Exports" is opened.
        DataExports.OpenEdit();

        // [THEN] Data Export record "GLAcc 2022" is created, its code is written to "Data Export 2022 G/L Acc. Code" of Data Export Setup table.
        DataExportSetup.Get();
        DataExport.Get(GLAccTxt);
        DataExportSetup.TestField("Data Export 2022 G/L Acc. Code", DataExport.Code);

        // [THEN] Data Export record "FAAcc 2022" is created, its code is written to "Data Export 2022 G/L Acc. Code" of Data Export Setup table.
        DataExport.Get(FAAccTxt);
        DataExportSetup.TestField("Data Export 2022 FA Acc. Code", DataExport.Code);

        // [THEN] Data Export record "Item 2022" is created, its code is written to "Data Export 2022 G/L Acc. Code" of Data Export Setup table.
        DataExport.Get(ItemAccTxt);
        DataExportSetup.TestField("Data Export 2022 Item Acc Code", DataExport.Code);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
    end;

    [Test]
    procedure DataExportTemplatesWhenDataExportSetupFieldsSet()
    var
        DataExport: Record "Data Export";
        DataExportRecType: Record "Data Export Record Type";
        DataExportSetup: Record "Data Export Setup";
        DataExports: TestPage "Data Exports";
    begin
        // [SCENARIO 418608] Data Export templates are not created when "Data Exports" page is opened if Data Export Setup has corresponding fields set.
        Initialize();
        DataExport.DeleteAll(true);
        DataExportRecType.DeleteAll(true);

        // [GIVEN] Fields "Data Export 2022 Code" are set in Data Export Setup table.
        DataExportSetup.Insert();
        UpdateDataExportSetup('abc', 'def', 'ghi');

        // [WHEN] Page "Data Exports" is opened.
        DataExports.OpenEdit();

        // [THEN] No data export templates are created.
        Assert.TableIsEmpty(Database::"Data Export");
        Assert.TableIsEmpty(Database::"Data Export Record Type");
        Assert.TableIsEmpty(Database::"Data Export Record Definition");
    end;

    [Test]
    procedure DataExportTemplatesWhenSameCodesExist()
    var
        DataExport: Record "Data Export";
        DataExportRecType: Record "Data Export Record Type";
        DataExportRecDef: Record "Data Export Record Definition";
        DataExports: TestPage "Data Exports";
    begin
        // [SCENARIO 418608] Data Export templates with different names are created when templates with specific names exist.
        Initialize();

        // [GIVEN] Data Export records with codes "GLAcc 2022", "FAAcc 2022", "Item 2022".
        DataExports.OpenEdit();
        DataExports.Close();

        // [GIVEN] Fields "Data Export 2022 Code" are empty in Data Export Setup table.
        UpdateDataExportSetup('', '', '');

        // [WHEN] Open page "Data Exports".
        DataExports.OpenEdit();

        // [THEN] Data Export "GLAcc22~1" is created.
        DataExport.Get(GLAccRenamedTxt);
        DataExportRecType.Get(GLAccRenamedTxt);
        DataExportRecDef.Get(GLAccRenamedTxt, GLAccRenamedTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 14);

        // [THEN] Data Export "FAAcc22~1" is created.
        DataExport.Get(FAAccRenamedTxt);
        DataExportRecType.Get(FAAccRenamedTxt);
        DataExportRecDef.Get(FAAccRenamedTxt, FAAccRenamedTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 4);

        // [THEN] Data Export "Item 22~1" is created.
        DataExport.Get(ItemAccRenamedTxt);
        DataExportRecType.Get(ItemAccRenamedTxt);
        DataExportRecDef.Get(ItemAccRenamedTxt, ItemAccRenamedTxt);
        VerifyDataExportRecSourceCount(DataExportRecDef, 4);

        // tear down
        DeleteDataExportRecord(GLAccTxt, GLAccTxt);
        DeleteDataExportRecord(FAAccTxt, FAAccTxt);
        DeleteDataExportRecord(ItemAccTxt, ItemAccTxt);
        DeleteDataExportRecord(GLAccRenamedTxt, GLAccRenamedTxt);
        DeleteDataExportRecord(FAAccRenamedTxt, FAAccRenamedTxt);
        DeleteDataExportRecord(ItemAccRenamedTxt, ItemAccRenamedTxt);
    end;

    local procedure Initialize()
    var
        DataExportSetup: Record "Data Export Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Data Export Test Suite");
        DataExportSetup.DeleteAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Data Export Test Suite");
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Data Export Test Suite");
    end;

    local procedure DeleteDataExportRecord(DataExportCode: Code[10]; DataExportRecTypeCode: Code[10])
    var
        DataExport: Record "Data Export";
        DataExportRecType: Record "Data Export Record Type";
    begin
        DataExport.Get(DataExportCode);
        DataExport.Delete(true);
        DataExportRecType.Get(DataExportRecTypeCode);
        DataExportRecType.Delete(true);
    end;

    local procedure UpdateDataExportSetup(GLAcc22Code: Code[10]; FAAcc22Code: Code[10]; ItemAcc22Code: Code[10])
    var
        DataExportSetup: Record "Data Export Setup";
    begin
        DataExportSetup.Get();
        DataExportSetup."Data Export 2022 G/L Acc. Code" := GLAcc22Code;
        DataExportSetup."Data Export 2022 FA Acc. Code" := FAAcc22Code;
        DataExportSetup."Data Export 2022 Item Acc Code" := ItemAcc22Code;
        DataExportSetup.Modify();
    end;

    local procedure VerifyDataExportRecSourceCount(var DataExportRecDef: Record "Data Export Record Definition"; ExpectedCount: Integer)
    var
        DataExportRecSource: Record "Data Export Record Source";
    begin
        DataExportRecSource.SetRange("Data Export Code", DataExportRecDef."Data Export Code");
        DataExportRecSource.SetRange("Data Exp. Rec. Type Code", DataExportRecDef."Data Exp. Rec. Type Code");
        Assert.AreEqual(ExpectedCount, DataExportRecSource.Count, '');
    end;
}
