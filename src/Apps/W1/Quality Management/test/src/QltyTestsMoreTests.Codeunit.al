// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.EServices.EDocument;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 139965 "Qlty. Tests - More Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        AssistEditTemplateValue: Text;
        ChooseFromLookupValue: Text;
        ChooseFromLookupValueVendorNo: Text;
        AttributeNameToValue: Dictionary of [Text, Text];
        MessageTxt: Text;
        IsInitialized: Boolean;
        TemplateCodeTok: Label 'TemplateCode', Locked = true;
        ResultCodeTxt: Label 'UNAVAILABLE';
        DefaultTopLeftTok: Label 'Inspection', Locked = true;
        DefaultMiddleLeftTok: Label 'Result', Locked = true;
        DefaultMiddleRightTok: Label 'Details', Locked = true;
        DefaultBottomLeftTok: Label 'Document', Locked = true;
        DefaultBottomRightTok: Label 'Status', Locked = true;
        ProdLineTok: Label 'PRODLINETOROUTING', Locked = true;
        CannotHaveATemplateWithReversedFromAndToErr: Label 'There is another template ''%1'' that reverses the from table and to table. You cannot have this combination to prevent recursive logic. Please change either this source configuration, or please change ''%1''', Comment = '%1=The other template code with conflicting configuration';
        TestValueTxt: Label 'test value.';
        OptionsTok: Label 'Option1,Option2,Option3', Locked = true;
        ConditionProductionFilterTok: Label 'WHERE(Order Type=FILTER(Production))', Locked = true;
        DefaultScheduleGroupTok: Label 'QM', Locked = true;
        InterestingDetectionErr: Label 'It looks like you are trying to do something interesting, or are trying to do something with a specific expectation that needs extra discussion, or are trying to configure something that might require a customization.';
        ExpressionFormulaTok: Label '[No.]';
        TestTypeErrInfoMsg: Label '%1Consider replacing this test in the template with a new one, or deleting existing inspections (if allowed). The test was last used on inspection %2.', Comment = '%1 = Error Title, %2 = Quality Inspection No.';
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';
        VendorFilterCountryTok: Label 'WHERE(Country/Region Code=FILTER(CA))', Locked = true;
        VendorFilterNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Vendor No.', Locked = true;
        ThereIsNoResultErr: Label 'There is no result called "%1". Please add the result, or change the existing result conditions.', Comment = '%1=the result';
        ReviewResultsErr: Label 'Advanced configuration required. Please review the result configurations for test "%1", for result "%2".', Comment = '%1=the test, %2=the result';
        OneDriveIntegrationNotConfiguredErr: Label 'The Quality Management Setup has been configured to upload pictures to OneDrive, however you have not yet configured Business Central to work with . Please configure OneDrive setup with Business Central first before using this feature.', Locked = true;
        FilterMandatoryErr: Label 'It is mandatory that an inspection generation rule have at least one filter defined to help prevent inadvertent over-generation of inspections. Navigate to the Quality Inspection Generation Rules and make sure at least one filter is set for each rule that matches the %1 schedule group.', Comment = '%1=the schedule group';
        ConditionFilterItemNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Item No.', Locked = true;
        ConditionFilterAttributeTok: Label '"%1"=Filter(%2)', Comment = '%1 = Attribute Name, %2 = Attribute Value', Locked = true;
        UnableToFindRecordErr: Label 'Unable to show inspections with the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheItemErr: Label 'Unable to identify the item for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheTrackingErr: Label 'Unable to identify the tracking for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheDocumentErr: Label 'Unable to identify the document for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        DefaultResult2PassCodeTok: Label 'PASS', Locked = true;
        ExpressionFormulaTestCodeTok: Label '[%1]', Comment = '%1=The first test code', Locked = true;
        TargetErr: Label 'When the target of the source configuration is an inspection, then all target fields must also refer to the inspection. Note that you can chain tables in another source configuration and still target inspection values. For example if you would like to ensure that a field from the Customer is included for a source configuration that is not directly related to a Customer then create another source configuration that links Customer to your record.';
        CanOnlyBeSetWhenToTypeIsInspectionErr: Label 'This is only used when the To Type is an inspection';
        OrderTypeProductionConditionFilterTok: Label 'WHERE(Order Type=FILTER(Production))', Locked = true;
        EntryTypeOutputConditionFilterTok: Label 'WHERE(Entry Type=FILTER(Output))', Locked = true;
        PassFailQuantityInvalidErr: Label 'The %1 and %2 cannot exceed the %3. The %3 is currently exceeded by %4.', Comment = '%1=the passed quantity caption, %2=the failed quantity caption, %3=the source quantity caption, %4=the quantity exceeded';

    [Test]
    [HandlerFunctions('LookupTableModalPageHandler_FirstRecord')]
    procedure TestCardPage_AssistEditLookupTable()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ToLoadQltyTest: Record "Qlty. Test";
        QltyTestCard: TestPage "Qlty. Test Card";
        TestCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to select a lookup table for a Table Lookup test value type
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Table Lookup" is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Insert();

        // [GIVEN] The Quality Test Card page is opened and navigated to the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [WHEN] AssistEdit is invoked on the "Lookup Table No." field
        QltyTestCard."Lookup Table No.".AssistEdit();
        QltyTestCard.Close();

        // [THEN] The first table from AllObjWithCaption is selected via modal handler
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();

        // [THEN] The test's Lookup Table No. is updated with the selected table ID
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(AllObjWithCaption."Object ID", ToLoadQltyTest."Lookup Table No.", 'Should be same table no.')
    end;

    [Test]
    procedure TestTable_ValidateExpressionFormula()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCode: Text;
    begin
        // [SCENARIO] Expression Formula can only be used with Expression field types, not Boolean
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Boolean" is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Boolean");
        ToLoadQltyTest.Insert();

        // [WHEN] Attempting to set Expression Formula on a Boolean test value type
        asserterror ToLoadQltyTest.Validate("Expression Formula", ExpressionFormulaTok);

        // [THEN] An error is raised indicating Expression Formula is only for Expression test value types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure TestCardPage_AssistEditLookupTableFilter()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        Vendor: Record Vendor;
        QltyTestCard: TestPage "Qlty. Test Card";
        TestCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to define a filter for the lookup table (e.g., filter Vendors by Country)
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyTest.Validate("Lookup Field No.", Vendor.FieldNo("No."));
        ToLoadQltyTest.Insert();

        // [GIVEN] A filter expression for Country/Region Code is prepared for the handler
        AssistEditTemplateValue := VendorFilterCountryTok;

        // [GIVEN] The Quality Test Card page is opened and navigated to the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [WHEN] AssistEdit is invoked on the "Lookup Table Filter" field
        QltyTestCard."Lookup Table Filter".AssistEdit();
        QltyTestCard.Close();

        // [THEN] The test's Lookup Table Filter is updated with the country filter expression
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(VendorFilterCountryTok, ToLoadQltyTest."Lookup Table Filter", 'Should be same filter.')
    end;

    [Test]
    procedure Test_OnInsert()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        TestCode: Text;
    begin
        // [SCENARIO] When a Table Lookup field is inserted with a filter, Allowable Values are auto-populated from the filtered records
        Initialize();

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Table Lookup" targeting Vendor table is configured
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyTest.Validate("Lookup Field No.", Vendor.FieldNo("No."));

        // [GIVEN] A filter limiting to the specific vendor number is applied
        ToLoadQltyTest.Validate("Lookup Table Filter", StrSubstNo(VendorFilterNoTok, Vendor."No."));

        // [WHEN] The test record is inserted with trigger execution
        ToLoadQltyTest.Insert(true);

        // [THEN] The Allowable Values are automatically populated with the vendor number from the filtered results
        LibraryAssert.AreEqual(Vendor."No.", ToLoadQltyTest."Allowable Values", 'Should be same vendor no.')
    end;

    [Test]
    procedure TestTable_AssistEditExpressionFormula_ShouldError()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        QltyTestExprCardPart: TestPage "Qlty. Test Expr. Card Part";
        TestCode: Text;
    begin
        // [SCENARIO] AssistEdit on Expression Formula should error when field type is Boolean
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Boolean" is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Boolean");
        ToLoadQltyTest.Insert();

        // [GIVEN] The Quality Test Expression Card Part page is opened and navigated to the test
        QltyTestExprCardPart.OpenEdit();
        QltyTestExprCardPart.GoToRecord(ToLoadQltyTest);

        // [WHEN] AssistEdit is invoked on the "Expression Formula" field for a Boolean type
        asserterror QltyTestExprCardPart."Expression Formula".AssistEdit();

        // [THEN] An error is raised indicating Expression Formula is only for Expression field types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandleChooseFromLookup_VendorNo')]
    procedure TestTable_AssistEditDefaultValue_TypeTableLookup()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ToLoadQltyTest: Record "Qlty. Test";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyTestCard: TestPage "Qlty. Test Card";
    begin
        // [SCENARIO] User can use AssistEdit to select a default value from the lookup table for a Table Lookup field
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Max Rows Field Lookups is set to allow the vendor count
        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := Vendor.Count() + 1;
        QltyManagementSetup.Modify();

        // [GIVEN] A quality test with Field Type "Table Lookup" targeting Vendor table is created
        QltyInspectionUtility.CreateTest(ToLoadQltyTest, ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyTest.Validate("Lookup Field No.", Vendor.FieldNo("No."));
        ToLoadQltyTest.Modify();

        // [GIVEN] The Quality Test Card page is opened and navigated to the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [GIVEN] The vendor number is prepared for selection via modal handler
        ChooseFromLookupValueVendorNo := Vendor."No.";

        // [WHEN] AssistEdit is invoked on the "Default Value" field
        QltyTestCard."Default Value".AssistEdit();
        QltyTestCard.Close();

        // [THEN] The test's Default Value is updated with the selected vendor number
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(Vendor."No.", ToLoadQltyTest."Default Value", 'Should be same vendor no.')
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure TestTable_AssistEditExpressionFormula()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        QltyTestExprCardPart: TestPage "Qlty. Test Expr. Card Part";
        TestCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to define an expression formula for a Text Expression field type
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Text Expression" is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Text Expression");
        ToLoadQltyTest.Insert();

        // [GIVEN] The Quality Test Expression Card Part page is opened and navigated to the test
        QltyTestExprCardPart.OpenEdit();
        QltyTestExprCardPart.GoToRecord(ToLoadQltyTest);

        // [GIVEN] An expression formula value is prepared for the handler
        AssistEditTemplateValue := ExpressionFormulaTok;

        // [WHEN] AssistEdit is invoked on the "Expression Formula" field
        QltyTestExprCardPart."Expression Formula".AssistEdit();

        // [THEN] The test's Expression Formula is updated with the prepared value
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(ExpressionFormulaTok, ToLoadQltyTest."Expression Formula", 'Should be same expression formula.')
    end;

    [Test]
    procedure TestTable_ValidateTestValueType_ShouldError()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Changing a test value type should error if the test is already used in an existing inspection
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The first inspection line is retrieved
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);

        // [GIVEN] The test used in the inspection line is retrieved
        ToLoadQltyTest.Get(QltyInspectionLine."Test Code");

        // [WHEN] Attempting to change the test value type to Boolean
        asserterror ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Boolean");

        // [THEN] An error is raised indicating the test value type cannot be changed because it's used in inspection
        LibraryAssert.ExpectedError(StrSubstNo(TestTypeErrInfoMsg, '', QltyInspectionHeader."No."));
    end;

    [Test]
    procedure TestTable_SetResultCondition_CannotGetResult_ShouldError()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] Setting a result condition should error if the result does not exist and ThrowError is true
        Initialize();

        // [GIVEN] Any existing result with code 'UNAVAILABLE' is deleted
        ToLoadQltyInspectionResult.SetRange(Code, ResultCodeTxt);
        if ToLoadQltyInspectionResult.FindFirst() then
            ToLoadQltyInspectionResult.Delete();

        // [WHEN] Attempting to set a result condition for a non-existent result with ThrowError = true
        asserterror ToLoadQltyTest.SetResultCondition(ResultCodeTxt, '', true);

        // [THEN] An error is raised indicating the result does not exist
        LibraryAssert.ExpectedError(StrSubstNo(ThereIsNoResultErr, ResultCodeTxt));
    end;

    [Test]
    procedure TestTable_SetResultCondition_CannotGetResult_ShouldExit()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] Setting a result condition should exit gracefully if the result does not exist and ThrowError is false
        Initialize();

        // [GIVEN] Any existing result with code 'UNAVAILABLE' is deleted
        ToLoadQltyInspectionResult.SetRange(Code, ResultCodeTxt);
        if ToLoadQltyInspectionResult.FindFirst() then
            ToLoadQltyInspectionResult.Delete();

        // [WHEN] Attempting to set a result condition for a non-existent result with ThrowError = false
        ToLoadQltyTest.SetResultCondition(ResultCodeTxt, '', false);

        // [THEN] The operation exits gracefully without raising an error
    end;

    [Test]
    procedure TestTable_SetResultCondition_CannotGetResultConfig_ShouldError()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyTest: Record "Qlty. Test";
        TestCodeTxt: Text;
    begin
        // [SCENARIO] Setting a result condition should error if the result exists but has no configuration and ThrowError is true
        Initialize();

        // [GIVEN] A result with code 'UNAVAILABLE' exists
        ToLoadQltyInspectionResult.SetRange(Code, ResultCodeTxt);
        if not ToLoadQltyInspectionResult.FindFirst() then begin
            ToLoadQltyInspectionResult.Validate(Code, ResultCodeTxt);
            ToLoadQltyInspectionResult.Insert();
        end;

        // [GIVEN] Any existing result condition configurations for this result are deleted
        ToLoadQltyIResultConditConf.SetRange("Result Code", ResultCodeTxt);
        if ToLoadQltyIResultConditConf.FindSet() then
            ToLoadQltyIResultConditConf.DeleteAll();

        // [GIVEN] A random test code is generated and a field is created
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCodeTxt);
        ToLoadQltyTest.Validate(Code, CopyStr(TestCodeTxt, 1, MaxStrLen(ToLoadQltyTest.Code)));

        // [WHEN] Attempting to set a result condition with no configuration and ThrowError = true
        asserterror ToLoadQltyTest.SetResultCondition(ResultCodeTxt, '', true);

        // [THEN] An error is raised indicating the result configuration needs review
        LibraryAssert.ExpectedError(StrSubstNo(ReviewResultsErr, TestCodeTxt, ResultCodeTxt));
    end;

    [Test]
    procedure TestTable_SetResultCondition_CannotGetResultConfig_ShouldExit()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] Setting a result condition should exit gracefully if the result exists but has no configuration and ThrowError is false
        Initialize();

        // [GIVEN] A result with code 'UNAVAILABLE' exists
        ToLoadQltyInspectionResult.SetRange(Code, ResultCodeTxt);
        if not ToLoadQltyInspectionResult.FindFirst() then begin
            ToLoadQltyInspectionResult.Validate(Code, ResultCodeTxt);
            ToLoadQltyInspectionResult.Insert();
        end;

        // [GIVEN] Any existing result condition configurations for this result are deleted
        ToLoadQltyIResultConditConf.SetRange("Result Code", ResultCodeTxt);
        if ToLoadQltyIResultConditConf.FindSet() then
            ToLoadQltyIResultConditConf.DeleteAll();

        // [WHEN] Attempting to set a result condition with no configuration and ThrowError = false
        ToLoadQltyTest.SetResultCondition(ResultCodeTxt, '', false);

        // [THEN] The operation exits gracefully without raising an error
    end;

    [Test]
    [HandlerFunctions('FieldsLookupModalPageHandler')]
    procedure TestTable_OnLookupFieldNo()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        Vendor: Record Vendor;
        QltyTestCard: TestPage "Qlty. Test Card";
        TestCode: Text;
    begin
        // [SCENARIO] User can use Lookup to select a field from the lookup table (e.g., select Vendor "No." field)
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyTest.Insert();

        // [GIVEN] The Quality Test Card page is opened and navigated to the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [GIVEN] The Vendor "No." field name is prepared for selection via modal handler
        ChooseFromLookupValue := Vendor.FieldName("No.");

        // [WHEN] Lookup is invoked on the "Lookup Field No." field
        QltyTestCard."Lookup Field No.".Lookup();
        QltyTestCard.Close();

        // [THEN] The test's Lookup Field No. is updated with the Vendor "No." field number
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(Vendor.FieldNo("No."), ToLoadQltyTest."Lookup Field No.", 'Should be same lookup field no.');
    end;

    [Test]
    [HandlerFunctions('FieldsLookupModalPageHandler')]
    procedure TestTable_AssistEditLookupField()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        Vendor: Record Vendor;
        QltyTestCard: TestPage "Qlty. Test Card";
        TestCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to select a field from the lookup table (e.g., select Vendor "No." field)
        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCode);

        // [GIVEN] A new quality test with Test Value Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyTest.Validate(Code, CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Table Lookup");
        ToLoadQltyTest.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyTest.Insert();

        // [GIVEN] The Quality Test Card page is opened and navigated to the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [GIVEN] The Vendor "No." field name is prepared for selection via modal handler
        ChooseFromLookupValue := Vendor.FieldName("No.");

        // [WHEN] AssistEdit is invoked on the "Lookup Field No." field
        QltyTestCard."Lookup Field No.".AssistEdit();
        QltyTestCard.Close();

        // [THEN] The test's Lookup Field No. is updated with the Vendor "No." field number
        ToLoadQltyTest.Get(ToLoadQltyTest.Code);
        LibraryAssert.AreEqual(Vendor.FieldNo("No."), ToLoadQltyTest."Lookup Field No.", 'Should be same lookup field no.');
    end;

    [Test]
    procedure SetupTable_ValidatePictureUploadBehavior()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] Picture Upload Behavior can be validated and changed to "Attach document"
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] The setup record is retrieved and Picture Upload Behavior is set to "Do nothing"
        QltyManagementSetup.Get();
        QltyManagementSetup."Picture Upload Behavior" := QltyManagementSetup."Picture Upload Behavior"::"Do nothing";
        QltyManagementSetup.Modify();

        // [WHEN] Picture Upload Behavior is validated and set to "Attach document"
        QltyManagementSetup.Validate("Picture Upload Behavior", QltyManagementSetup."Picture Upload Behavior"::"Attach document");

        // [THEN] The Picture Upload Behavior is successfully updated to "Attach document"
        LibraryAssert.IsTrue(QltyManagementSetup."Picture Upload Behavior" = QltyManagementSetup."Picture Upload Behavior"::"Attach document", 'Picture upload behavior should be valid and updated')
    end;

    [Test]
    procedure SetupTable_ValidatePictureUploadBehavior_StoreInOneDrive()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        DocumentServiceManagement: Codeunit "Document Service Management";

    begin
        // [SCENARIO] Setting Picture Upload Behavior to "Attach and upload to OneDrive" requires OneDrive configuration
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] The setup record is retrieved and Picture Upload Behavior is set to "Do nothing"
        QltyManagementSetup.Get();
        QltyManagementSetup."Picture Upload Behavior" := QltyManagementSetup."Picture Upload Behavior"::"Do nothing";
        QltyManagementSetup.Modify();

        // [WHEN] OneDrive is not configured
        if not DocumentServiceManagement.IsConfigured() then begin
            // [WHEN] Attempting to set Picture Upload Behavior to "Attach and upload to OneDrive"
            asserterror QltyManagementSetup.Validate("Picture Upload Behavior", QltyManagementSetup."Picture Upload Behavior"::"Attach and upload to OneDrive");

            // [THEN] An error is raised indicating OneDrive must be configured first
            LibraryAssert.ExpectedError(OneDriveIntegrationNotConfiguredErr);
        end else begin
            // [WHEN] OneDrive is configured and Picture Upload Behavior is set to "Attach and upload to OneDrive"
            QltyManagementSetup.Validate("Picture Upload Behavior", QltyManagementSetup."Picture Upload Behavior"::"Attach and upload to OneDrive");

            // [THEN] The Picture Upload Behavior is successfully updated
            LibraryAssert.IsTrue(QltyManagementSetup."Picture Upload Behavior" = QltyManagementSetup."Picture Upload Behavior"::"Attach and upload to OneDrive", 'Picture upload behavior should be valid and updated')
        end;
    end;

    [Test]
    procedure SetupTable_ValidateBinMoveBatchName()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO] Bin Move Batch Name can be validated and set to a Transfer journal batch
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] All existing item journal templates are deleted
        if not ItemJournalTemplate.IsEmpty() then
            ItemJournalTemplate.DeleteAll();

        // [GIVEN] A Transfer type item journal template and batch are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] The setup record is retrieved
        QltyManagementSetup.Get();

        // [WHEN] Bin Move Batch Name is validated and set to the created batch
        QltyManagementSetup.Validate("Bin Move Batch Name", ItemJournalBatch.Name);

        // [THEN] The Bin Move Batch Name is successfully updated
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Bin Move Batch Name", 'Bin move batch name should be valid and updated')
    end;

    [Test]
    procedure SetupTable_ValidateAdjustmentBatchName()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO] Adjustment Batch Name can be validated and set to an Item journal batch
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] All existing item journal templates are deleted
        if not ItemJournalTemplate.IsEmpty() then
            ItemJournalTemplate.DeleteAll();

        // [GIVEN] An Item type journal template and batch are created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] The setup record is retrieved
        QltyManagementSetup.Get();

        // [WHEN] Adjustment Batch Name is validated and set to the created batch
        QltyManagementSetup.Validate("Adjustment Batch Name", ItemJournalBatch.Name);

        // [THEN] The Adjustment Batch Name is successfully updated
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Adjustment Batch Name", 'Adjustment batch name should be valid and updated')
    end;

    [Test]
    procedure SetupTable_OnInsert_InitializeBrickHeaders()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] When Quality Management Setup is inserted, Brick Headers are initialized to default values
        Initialize();

        // [GIVEN] Any existing setup record is deleted
        if QltyManagementSetup.Get() then
            QltyManagementSetup.Delete();

        // [GIVEN] A new setup record is initialized
        QltyManagementSetup.Init();

        // [WHEN] The setup record is inserted with trigger execution
        QltyManagementSetup.Insert(true);

        // [THEN] Brick Top Left Header is set to default value 'Test'
        LibraryAssert.AreEqual(DefaultTopLeftTok, QltyManagementSetup."Brick Top Left Header", 'Top left header should be default value');

        // [THEN] Brick Middle Left Header is set to default value 'Result'
        LibraryAssert.AreEqual(DefaultMiddleLeftTok, QltyManagementSetup."Brick Middle Left Header", 'Middle left header should be default value');

        // [THEN] Brick Middle Right Header is set to default value 'Details'
        LibraryAssert.AreEqual(DefaultMiddleRightTok, QltyManagementSetup."Brick Middle Right Header", 'Middle right header should be default value');

        // [THEN] Brick Bottom Left Header is set to default value 'Document'
        LibraryAssert.AreEqual(DefaultBottomLeftTok, QltyManagementSetup."Brick Bottom Left Header", 'Bottom left header should be default value');

        // [THEN] Brick Bottom Right Header is set to default value 'Status'
        LibraryAssert.AreEqual(DefaultBottomRightTok, QltyManagementSetup."Brick Bottom Right Header", 'Bottom right header should be default value');
    end;

    [Test]
    procedure SetupTable_GetSetupVideoLink()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] GetSetupVideoLink returns an empty string
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] The setup record is retrieved
        QltyManagementSetup.Get();

        // [WHEN] GetSetupVideoLink is called
        // [THEN] An empty string is returned
        LibraryAssert.AreEqual('', QltyManagementSetup.GetSetupVideoLink(), 'Setup video link should be empty');
    end;

    [Test]
    procedure TemplateLineTable_OnModify_TextExpression()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TestCode: Text;
    begin
        // [SCENARIO] Template line can be modified to set Expression Formula for a Text Expression field type
        Initialize();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A new template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Text Expression field is created
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Text Expression");
        ToLoadQltyTest.Insert();

        // [GIVEN] A template line is created with the Text Expression field
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine."Test Code" := ToLoadQltyTest.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.CalcFields("Test Value Type");

        // [WHEN] Expression Formula is validated and the template line is modified
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Expression Formula", ExpressionFormulaTok);
        ConfigurationToLoadQltyInspectionTemplateLine.Modify(true);

        // [THEN] The Expression Formula is successfully updated on the template line
        LibraryAssert.AreEqual(ExpressionFormulaTok, ConfigurationToLoadQltyInspectionTemplateLine."Expression Formula", 'Expression formula should be updated');
    end;

    [Test]
    procedure TemplateLineTable_AssistEditExpressionFormula_ShouldError()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TestCode: Text;
    begin
        // [SCENARIO] Attempting to set Expression Formula on a template line with Boolean field type should error
        Initialize();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A new template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Boolean field is created
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Boolean");
        ToLoadQltyTest.Insert();

        // [GIVEN] A template line is created with the Boolean field
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine."Test Code" := ToLoadQltyTest.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.CalcFields("Test Value Type");

        // [WHEN] Attempting to validate Expression Formula on a Boolean field type
        asserterror ConfigurationToLoadQltyInspectionTemplateLine.Validate("Expression Formula", ExpressionFormulaTok);

        // [THEN] An error is raised indicating Expression Formula is only for Expression field types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    procedure GenerationRule_ValidateScheduleGroup_NoFilters_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Setting a Schedule Group on a generation rule without filters should error
        Initialize();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule is created without any filters
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule.Insert();

        // [GIVEN] A random schedule group code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, ScheduleGroupCode);

        // [WHEN] Attempting to validate Schedule Group without filters
        asserterror QltyInspectionGenRule.Validate("Schedule Group", ScheduleGroupCode);

        // [THEN] An error is raised indicating at least one filter is mandatory
        LibraryAssert.ExpectedError(StrSubstNo(FilterMandatoryErr, ScheduleGroupCode));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_ValidateScheduleGroup_NewScheduleGroup()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Setting a new Schedule Group on a generation rule with filters creates a job queue entry
        Initialize();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing job queue entries for schedule inspection are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule with filters and default schedule group is created
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionProductionFilterTok;
        QltyInspectionGenRule."Schedule Group" := DefaultScheduleGroupTok;
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] A random new schedule group code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, ScheduleGroupCode);

        // [GIVEN] Job Queue Entries page is trapped for verification
        JobQueueEntries.Trap();

        // [WHEN] Schedule Group is validated with the new schedule group code
        QltyInspectionGenRule.Validate("Schedule Group", ScheduleGroupCode);

        // [THEN] The Schedule Group is successfully updated
        LibraryAssert.IsTrue(QltyInspectionGenRule."Schedule Group" = ScheduleGroupCode, 'Schedule group should be updated');

        // [THEN] A job queue entry is created for the schedule inspection report
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_CreateJobQueueEntry()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
        QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] User can create an additional job queue entry for an existing generation rule with schedule group
        Initialize();

        // [GIVEN] All existing templates are deleted and a new template is created
        QltyInspectionTemplateHdr.DeleteAll();
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := QltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateHdr.Insert();

        // [GIVEN] A new generation rule with schedule group is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ScheduleGroupCode);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := OrderTypeProductionConditionFilterTok;
        QltyInspectionGenRule."Schedule Group" := CopyStr(ScheduleGroupCode, 1, MaxStrLen(QltyInspectionGenRule."Schedule Group"));
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] Any existing job queue entries for schedule inspection are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] Job queue entries page is trapped for verification
        JobQueueEntries.Trap();

        // [WHEN] CreateAnotherJobQueue action is invoked on the Generation Rules page
        QltyInspectionGenRules.OpenView();
        QltyInspectionGenRules.GoToRecord(QltyInspectionGenRule);
        QltyInspectionGenRules.CreateAnotherJobQueue.Invoke();

        // [THEN] A job queue entry is created for the schedule inspection report
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_DeleteScheduleGroup_ShouldDeleteEntry()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Clearing a schedule group from a generation rule deletes the associated job queue entry when it's the only rule using that group
        Initialize();

        // [GIVEN] All existing templates are deleted and a new template is created
        QltyInspectionTemplateHdr.DeleteAll();
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := QltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateHdr.Insert();

        // [GIVEN] Any existing job queue entries for schedule inspection are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] A generation rule with schedule group is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ScheduleGroupCode);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := OrderTypeProductionConditionFilterTok;
        QltyInspectionGenRule.Insert(true);
        JobQueueEntries.Trap();
        QltyInspectionGenRule.Validate("Schedule Group", ScheduleGroupCode);

        // [GIVEN] A job queue entry is created for the schedule group
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');

        // [WHEN] The schedule group is cleared from the generation rule
        QltyInspectionGenRule.Validate("Schedule Group", '');

        // [THEN] The job queue entry is deleted since no other rules use this schedule group
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 0, 'Should have deleted job queue entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_DeleteScheduleGroup_ShouldNotDeleteEntry()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        SecondQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Clearing a schedule group from one generation rule should not delete the job queue entry when other rules still use the same group
        Initialize();

        // [GIVEN] All existing templates are deleted and a new template is created
        QltyInspectionTemplateHdr.DeleteAll();
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := QltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateHdr.Insert();

        // [GIVEN] Any existing job queue entries for schedule inspection are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] A first generation rule with schedule group is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ScheduleGroupCode);
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := EntryTypeOutputConditionFilterTok;
        QltyInspectionGenRule.Insert(true);
        JobQueueEntries.Trap();
        QltyInspectionGenRule.Validate("Schedule Group", ScheduleGroupCode);

        // [GIVEN] A second generation rule with the same schedule group is created
        SecondQltyInspectionGenRule.Init();
        SecondQltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        SecondQltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        SecondQltyInspectionGenRule."Condition Filter" := OrderTypeProductionConditionFilterTok;
        SecondQltyInspectionGenRule.Insert(true);
        JobQueueEntries.Trap();
        SecondQltyInspectionGenRule.Validate("Schedule Group", ScheduleGroupCode);

        // [GIVEN] A job queue entry is created for the shared schedule group
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');

        // [WHEN] The schedule group is cleared from the first generation rule only
        QltyInspectionGenRule.Validate("Schedule Group", '');

        // [THEN] The job queue entry is preserved because the second rule still uses the same schedule group
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should not have deleted job queue entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_LookupJobQueue_Default()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        JobQueueEntry: Record "Job Queue Entry";
        QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
    begin
        // [SCENARIO] Using Lookup on Schedule Group creates default schedule group and job queue entry
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyInspectionUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule with filters but no schedule group is created
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionProductionFilterTok;
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] All existing job queue entries for schedule inspection are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInspectionGenRules.OpenEdit();
        QltyInspectionGenRules.GoToRecord(QltyInspectionGenRule);

        // [GIVEN] Job Queue Entries page is trapped for verification
        JobQueueEntries.Trap();

        // [WHEN] Lookup is invoked on the Schedule Group field
        QltyInspectionGenRules."Schedule Group".Drilldown();
        JobQueueEntries.Close();
        QltyInspectionGenRules.Close();

        // [THEN] The default schedule group 'QM' is assigned to the rule
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.AreEqual(DefaultScheduleGroupTok, QltyInspectionGenRule."Schedule Group", 'Default schedule group should be created');

        // [THEN] A job queue entry is created for the schedule inspection report
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');
    end;

    [Test]
    procedure GenerationRuleList_ValidateProductionTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Production Trigger can be validated and set to OnProductionOrderRelease
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Prod. Order Routing Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Prod. Order Routing Line";

        // [WHEN] Production Trigger is validated and set to OnProductionOrderRelease
        QltyInspectionGenRule.Validate("Production Trigger", QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease);

        // [THEN] The Production Trigger is successfully set to OnProductionOrderRelease
        LibraryAssert.AreEqual(QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease, QltyInspectionGenRule."Production Trigger", 'Production trigger should be set to on release');
    end;

    [Test]
    procedure GenerationRuleList_ValidateWarehouseReceiveTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Warehouse Receive Trigger can be validated and set to OnWarehouseReceiptCreate
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Warehouse Receipt Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Receipt Line";

        // [WHEN] Warehouse Receive Trigger is validated and set to OnWarehouseReceiptCreate
        QltyInspectionGenRule.Validate("Warehouse Receive Trigger", QltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate);

        // [THEN] The Warehouse Receive Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate, QltyInspectionGenRule."Warehouse Receive Trigger", 'Warehouse Receipt trigger should be set to on receipt create');
    end;

    [Test]
    procedure GenerationRuleList_ValidateWarehouseMovementTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Warehouse Movement Trigger can be validated and set to OnWhseMovementRegister
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Warehouse Entry with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Entry";

        // [WHEN] Warehouse Movement Trigger is validated and set to OnWhseMovementRegister
        QltyInspectionGenRule.Validate("Warehouse Movement Trigger", QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister);

        // [THEN] The Warehouse Movement Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister, QltyInspectionGenRule."Warehouse Movement Trigger", 'Warehouse Movement trigger should be set to into bin');
    end;

    [Test]
    procedure GenerationRuleList_ValidatePurchaseTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Purchase Trigger can be validated and set to OnPurchaseOrderPostReceive
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Purchase Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";

        // [WHEN] Purchase Trigger is validated and set to OnPurchaseOrderPostReceive
        QltyInspectionGenRule.Validate("Purchase Trigger", QltyInspectionGenRule."Purchase Trigger"::OnPurchaseOrderPostReceive);

        // [THEN] The Purchase Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Purchase Trigger"::OnPurchaseOrderPostReceive, QltyInspectionGenRule."Purchase Trigger", 'Purchase trigger should be set to on purchase post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateSalesReturnTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Sales Return Trigger can be validated and set to OnSalesReturnOrderPostReceive
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Sales Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Sales Line";

        // [WHEN] Sales Return Trigger is validated and set to OnSalesReturnOrderPostReceive
        QltyInspectionGenRule.Validate("Sales Return Trigger", QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);

        // [THEN] The Sales Return Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive, QltyInspectionGenRule."Sales Return Trigger", 'Sales Return trigger should be set to on sales return post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateTransferTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Transfer Trigger can be validated and set to OnTransferOrderPostReceive
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Transfer Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Transfer Line";

        // [WHEN] Transfer Trigger is validated and set to OnTransferOrderPostReceive
        QltyInspectionGenRule.Validate("Transfer Trigger", QltyInspectionGenRule."Transfer Trigger"::OnTransferOrderPostReceive);

        // [THEN] The Transfer Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Transfer Trigger"::OnTransferOrderPostReceive, QltyInspectionGenRule."Transfer Trigger", 'Transfer trigger should be set to on transfer receive post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateAssemblyTrigger()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Assembly Trigger can be validated and set to OnAssemblyOutputPost
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Assembly Line with Disabled activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::Disabled;
        QltyInspectionGenRule."Source Table No." := Database::"Assembly Line";

        // [WHEN] Assembly Trigger is validated and set to OnAssemblyOutputPost
        QltyInspectionGenRule.Validate("Assembly Trigger", QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost);

        // [THEN] The Assembly Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost, QltyInspectionGenRule."Assembly Trigger", 'Assembly trigger should be set to on any output posted ledger');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRuleList_ValidateAssemblyTrigger_ChangetoManualOrAuto()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Setting Assembly Trigger changes Activation Trigger from "Manual only" to "Manual or Automatic"
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new generation rule for Assembly Line with "Manual only" activation trigger is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := TemplateCodeTok;
        QltyInspectionGenRule."Activation Trigger" := QltyInspectionGenRule."Activation Trigger"::"Manual only";
        QltyInspectionGenRule."Source Table No." := Database::"Assembly Line";

        // [WHEN] Assembly Trigger is validated and set to OnAssemblyOutputPost
        QltyInspectionGenRule.Validate("Assembly Trigger", QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost);

        // [THEN] The Assembly Trigger is successfully set
        LibraryAssert.AreEqual(QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost, QltyInspectionGenRule."Assembly Trigger", 'Assembly trigger should be set to on any output posted ledger');

        // [THEN] The Activation Trigger is automatically changed to "Manual or Automatic"
        LibraryAssert.AreEqual(QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger", 'Activation trigger should be set to manual or automatic');
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure GenerationRuleList_AssistEditConditionTableFilter()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define a Condition Filter for generation rule
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInspectionGenRules.OpenEdit();
        QltyInspectionGenRules.GoToRecord(QltyInspectionGenRule);

        // [GIVEN] A production filter expression is prepared for the handler
        AssistEditTemplateValue := ConditionProductionFilterTok;

        // [WHEN] AssistEdit is invoked on the "Condition Filter" field
        QltyInspectionGenRules."Condition Filter".AssistEdit();
        QltyInspectionGenRules.Close();

        // [THEN] The Condition Filter is updated with the production filter expression
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.AreEqual(ConditionProductionFilterTok, QltyInspectionGenRule."Condition Filter", 'Condition filter should be set to the default');
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure GenerationRuleList_AssistEditConditionItemFilter()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define an Item Filter for generation rule
        Initialize();

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInspectionGenRules.OpenEdit();
        QltyInspectionGenRules.GoToRecord(QltyInspectionGenRule);

        // [GIVEN] An item filter expression for the created item is prepared for the handler
        AssistEditTemplateValue := StrSubstNo(ConditionFilterItemNoTok, Item."No.");

        // [WHEN] AssistEdit is invoked on the "Item Filter" field
        QltyInspectionGenRules."Item Filter".AssistEdit();
        QltyInspectionGenRules.Close();

        // [THEN] The Item Filter is updated with the item number filter expression
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.AreEqual(StrSubstNo(ConditionFilterItemNoTok, Item."No."), QltyInspectionGenRule."Item Filter", 'Item filter should be set to the item no.');
    end;

    [Test]
    [HandlerFunctions('FilterItemsbyAttributeModalPageHandler')]
    procedure GenerationRuleList_AssistEditConditionAttributeFilter()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define an Item Attribute Filter for generation rule
        Initialize();

        // [GIVEN] An item attribute with value 'Red' is created
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Option, 'Red');

        // [GIVEN] All existing generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInspectionGenRules.OpenEdit();
        QltyInspectionGenRules.GoToRecord(QltyInspectionGenRule);

        // [GIVEN] The attribute name and value are prepared for selection via modal handler
        AttributeNameToValue.Add(ItemAttribute.Name, ItemAttributeValue.Value);

        // [WHEN] AssistEdit is invoked on the "Item Attribute Filter" field
        QltyInspectionGenRules."Item Attribute Filter".AssistEdit();
        QltyInspectionGenRules.Close();

        // [THEN] The Item Attribute Filter is updated with the attribute filter expression
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.AreEqual(StrSubstNo(ConditionFilterAttributeTok, ItemAttribute.Name, ItemAttributeValue.Value), QltyInspectionGenRule."Item Attribute Filter", 'Attribute filter should be set to the attribute value.');
    end;

    [Test]
    procedure Table_ChangeSourceQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Negative Source Quantity value is converted to absolute positive value
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Source Quantity (Base) is validated with a negative value (-100)
        QltyInspectionHeader.Validate("Source Quantity (Base)", -100);

        // [THEN] Source Quantity (Base) is stored as the absolute value (100)
        LibraryAssert.AreEqual(100, QltyInspectionHeader."Source Quantity (Base)", 'Source quantity should be 100');
    end;

    [Test]
    procedure Table_ValidatePassQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Pass Quantity can be set to match Source Quantity
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Pass Quantity is validated with the Source Quantity value
        QltyInspectionHeader.Validate("Pass Quantity", QltyInspectionHeader."Source Quantity (Base)");

        // [THEN] Pass Quantity equals the Source Quantity
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Quantity (Base)", QltyInspectionHeader."Pass Quantity", 'Pass quantity should be the same as the source quantity');
    end;

    [Test]
    procedure Table_ValidatePassAndFailDoNotExceedSourceQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Ensure that pass and fail quantity combined do not exceed the source quantity.
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Pass Quantity exceeds the source quantity it should fail.
        ClearLastError();
        asserterror QltyInspectionHeader.Validate("Pass Quantity", QltyInspectionHeader."Source Quantity (Base)" + 1);

        // [THEN] An error is thrown indicating the quantities cannot exceed the source quantity.
        LibraryAssert.ExpectedError(StrSubstNo(PassFailQuantityInvalidErr, QltyInspectionHeader.FieldCaption("Pass Quantity"), QltyInspectionHeader.FieldCaption("Fail Quantity"), QltyInspectionHeader.FieldCaption("Source Quantity (Base)"), 1));

        // [WHEN] Fail Quantity exceeds the source quantity it should fail.
        ClearLastError();
        asserterror QltyInspectionHeader.Validate("Fail Quantity", QltyInspectionHeader."Source Quantity (Base)" + 2);

        // [THEN] An error is thrown indicating the quantities cannot exceed the source quantity.
        LibraryAssert.ExpectedError(StrSubstNo(PassFailQuantityInvalidErr, QltyInspectionHeader.FieldCaption("Pass Quantity"), QltyInspectionHeader.FieldCaption("Fail Quantity"), QltyInspectionHeader.FieldCaption("Source Quantity (Base)"), 2));

        // [WHEN] The pass and fail quantities combined would exceed the source quantity it should fail.
        ClearLastError();
        QltyInspectionHeader.Validate("Pass Quantity", 0);
        asserterror QltyInspectionHeader.Validate("Fail Quantity", QltyInspectionHeader."Source Quantity (Base)" + 5);

        // [THEN] An error is thrown indicating the quantities cannot exceed the source quantity.
        LibraryAssert.ExpectedError(StrSubstNo(PassFailQuantityInvalidErr, QltyInspectionHeader.FieldCaption("Pass Quantity"), QltyInspectionHeader.FieldCaption("Fail Quantity"), QltyInspectionHeader.FieldCaption("Source Quantity (Base)"), 5));

        // [WHEN] The pass and fail quantities match exactly the source quantity it should be allowed.
        ClearLastError();
        QltyInspectionHeader."Source Quantity (Base)" := 3;
        QltyInspectionHeader.Validate("Pass Quantity", 1);
        QltyInspectionHeader.Validate("Fail Quantity", 2);

        // [THEN] An error is thrown indicating the quantities cannot exceed the source quantity.
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Quantity (Base)", QltyInspectionHeader."Pass Quantity" + QltyInspectionHeader."Fail Quantity", 'The source quantity should match the total of the pass and fail quantity.');
    end;

    [Test]
    procedure Table_ValidateFailQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Fail Quantity can be set to match Source Quantity
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Fail Quantity is validated with the Source Quantity value
        QltyInspectionHeader.Validate("Fail Quantity", QltyInspectionHeader."Source Quantity (Base)");

        // [THEN] Fail Quantity equals the Source Quantity
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Quantity (Base)", QltyInspectionHeader."Fail Quantity", 'Fail quantity should be the same as the source quantity');
    end;

    [Test]
    procedure Table_GetRelatedItem_NoSourceItemNoOnInspection()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO] GetRelatedItem retrieves item from source document when Source Item No. is blank
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Source Item No. is cleared and the record is modified
        QltyInspectionHeader."Source Item No." := '';
        QltyInspectionHeader.Modify();

        // [WHEN] GetRelatedItem is called to retrieve the item
        QltyInspectionHeader.GetRelatedItem(Item);

        // [THEN] The item returned matches the item from the source production order line
        ProdOrderLine.SetRange(Status, QltyInspectionHeader."Source Type");
        ProdOrderLine.SetRange("Prod. Order No.", QltyInspectionHeader."Source Document No.");
        ProdOrderLine.SetRange("Line No.", QltyInspectionHeader."Source Document Line No.");
        ProdOrderLine.FindFirst();
        LibraryAssert.AreEqual(ProdOrderLine."Item No.", Item."No.", 'Source item should be the item from the production order routing line.');
    end;

    [Test]
    procedure Table_GetItemAttributeValue()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO] GetItemAttributeValue retrieves the correct attribute value for the source item
        Initialize();

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] An item attribute 'Red' is created with a value
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Option, 'Red');

        // [GIVEN] The attribute is mapped to the item
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Inspection header's Source Item No. is set to the created item
        QltyInspectionHeader."Source Item No." := Item."No.";

        // [WHEN] GetItemAttributeValue is called with the attribute name
        // [THEN] The returned value matches the item attribute value
        LibraryAssert.AreEqual(ItemAttributeValue.Value, QltyInspectionHeader.GetItemAttributeValue(ItemAttribute.Name), 'Item attribute value should be the same value.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_NullVariant()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ordId: RecordId;
    begin
        // [SCENARIO] SetRecordFiltersToFindInspectionFor throws an error when provided with a null RecordId
        Initialize();

        // [GIVEN] A null RecordId

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with the null RecordId
        asserterror QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, ordId, false, false, false);

        // [THEN] An error is thrown indicating the record cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(UnableToFindRecordErr, ordId));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_NoSourceItem()
    var
        Location: Record Location;
        Item: Record Item;
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindInspectionFor throws error when item cannot be identified
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Source field configuration for Purchase Line "No." field is deleted
        SpecificQltyInspectSrcFldConf.SetRange("From Table No.", Database::"Purchase Line");
        SpecificQltyInspectSrcFldConf.SetRange("From Field No.", PurchaseLine.FieldNo("No."));
        if SpecificQltyInspectSrcFldConf.FindFirst() then
            SpecificQltyInspectSrcFldConf.Delete();

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with requireItemFilter = true
        asserterror QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, PurchaseLine, true, false, false);

        // [THEN] An error is thrown indicating the item cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheItemErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_NoSourceTracking()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindInspectionFor throws error when tracking information cannot be identified
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with requireTrackingFilter = true
        asserterror QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, PurchaseLine, false, true, false);

        // [THEN] An error is thrown indicating tracking information cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheTrackingErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_NoSourceDocument()
    var
        Location: Record Location;
        Item: Record Item;
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindInspectionFor throws error when document information cannot be identified
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] Source field configuration for Purchase Line "Document No." field is deleted
        SpecificQltyInspectSrcFldConf.SetRange("From Table No.", Database::"Purchase Line");
        SpecificQltyInspectSrcFldConf.SetRange("From Field No.", PurchaseLine.FieldNo("Document No."));
        if SpecificQltyInspectSrcFldConf.FindFirst() then
            SpecificQltyInspectSrcFldConf.Delete();

        // [GIVEN] Inspection header has variant, lot, serial, and package tracking set
        QltyInspectionHeader."Source Variant Code" := 'Variant';
        QltyInspectionHeader."Source Lot No." := 'Lot';
        QltyInspectionHeader."Source Serial No." := 'Serial';
        QltyInspectionHeader."Source Package No." := 'Package';

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with requireDocumentFilter = true
        asserterror QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, PurchaseLine, false, false, true);

        // [THEN] An error is thrown indicating the document cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheDocumentErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure LineTable_OnInsert()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        // [SCENARIO] OnInsert trigger sets system timestamps on inspection line
        Initialize();

        // [GIVEN] An inspection header is inserted
        QltyInspectionHeader.Insert();

        // [GIVEN] An inspection line is initialized with header keys and line number
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine."Line No." := 10000;

        // [WHEN] The inspection line is inserted
        QltyInspectionLine.Insert(true);

        // [THEN] SystemCreatedAt and SystemModifiedAt timestamps are populated
        LibraryAssert.IsTrue(QltyInspectionLine.SystemCreatedAt <> 0DT, 'SystemCreatedAt should be set.');
        LibraryAssert.IsTrue(QltyInspectionLine.SystemModifiedAt <> 0DT, 'SystemModifiedAt should be set.');
    end;

    [Test]
    procedure LineTable_OnDelete()
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        // [SCENARIO] OnDelete trigger removes associated result condition configurations
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionLine.FindSet(true), 'Sanity check, there should be an inspection line.');
        repeat
            QltyInspectionHeader.SetTestValue(QltyInspectionLine."Test Code", '1');
        until QltyInspectionLine.Next() = 0;
        LibraryAssert.IsTrue(QltyInspectionLine.FindSet(true), 'Sanity check, there should be an inspection line.');

        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Inspection);
        ToLoadQltyIResultConditConf.SetRange("Target Code", QltyInspectionHeader."No.");
        ToLoadQltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionResult.SetRange("Copy Behavior", QltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        LibraryAssert.AreEqual(
            1 * (QltyInspectionResult.Count() * QltyInspectionLine.Count()),
            ToLoadQltyIResultConditConf.Count(),
            'Should be at least one result condition config per field per result');

        // [WHEN] The inspection line is deleted
        QltyInspectionLine.Delete(true);

        // [THEN] All associated result condition configurations are deleted
        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Inspection);
        ToLoadQltyIResultConditConf.SetRange("Target Code", QltyInspectionHeader."No.");
        ToLoadQltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        ToLoadQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        LibraryAssert.AreEqual(0, ToLoadQltyIResultConditConf.Count(), 'Should be no result condition config lines for the inspection line.');
        ToLoadQltyIResultConditConf.SetRange("Target Line No.");
        QltyInspectionHeader.Delete(true);
        LibraryAssert.AreEqual(0, ToLoadQltyIResultConditConf.Count(), 'Should be no result condition config lines for the inspection.');
    end;

    [Test]
    [HandlerFunctions('EditLargeTextModalPageHandler')]
    procedure LineTable_RunModalMeasurementNote()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionSubform: TestPage "Qlty. Inspection Subform";
    begin
        // [SCENARIO] User can edit measurement note via modal editor on inspection line
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The inspection line is retrieved and the inspection subform page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        QltyInspectionSubform.OpenEdit();
        QltyInspectionSubform.GoToRecord(QltyInspectionLine);

        // [WHEN] AssistEdit is invoked on the Measurement Note field
        QltyInspectionSubform.ChooseMeasurementNote.AssistEdit();

        // [THEN] The measurement note is updated with the text entered via modal
        LibraryAssert.AreEqual(TestValueTxt, QltyInspectionLine.GetMeasurementNote(), 'Measurement note should be set.');
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure LineTable_AssistEditChooseFromList()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyTest: Record "Qlty. Test";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] User can use AssistEdit to select from allowable values list for Test Value
        Initialize();

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Test Value Type Option field having allowable values
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, ToLoadQltyTest, ToLoadQltyTest."Test Value Type"::"Value Type Option");
        ToLoadQltyTest."Allowable Values" := OptionsTok;
        ToLoadQltyTest.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspection.Lines."Test Value".AssistEdit();
        QltyInspection.Close();

        // [THEN] The Test Value is set to the selected option from the list
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        LibraryAssert.AreEqual('Option1', QltyInspectionLine."Test Value", 'Test value should be set.');

        QltyInspectionGenRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandleChooseFromLookup')]
    procedure LineTable_AssistEditChooseFromTableLookup()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        LookupQltyTest: Record "Qlty. Test";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] User can use AssistEdit to select from table lookup for Test Value
        Initialize();

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Test Value Type Table Lookup field configured for Location table
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQltyTest, LookupQltyTest."Test Value Type"::"Value Type Table Lookup");
        LookupQltyTest."Lookup Table No." := Database::Location;
        LookupQltyTest."Lookup Field No." := Location.FieldNo(Code);
        LookupQltyTest.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [GIVEN] A location code is prepared for selection via modal handler
        ChooseFromLookupValue := Location.Code;

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspection.Lines."Test Value".AssistEdit();
        QltyInspection.Close();

        // [THEN] The Test Value is set to the selected location code from the lookup
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        LibraryAssert.AreEqual(Location.Code, QltyInspectionLine."Test Value", 'Test value should be set.');

        QltyInspectionGenRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    procedure LineTable_UpdateExpressionsInOtherInspectionLines_TextExpression()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ExpressionQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyTest: Record "Qlty. Test";
        TextExpressionQltyTest: Record "Qlty. Test";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] Updating a text field value automatically updates dependent text expression fields
        Initialize();

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A text field is added to the template
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextQltyTest, TextQltyTest."Test Value Type"::"Value Type Text");

        // [GIVEN] A text expression field is added to the template
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextExpressionQltyTest, TextExpressionQltyTest."Test Value Type"::"Value Type Text Expression");

        // [GIVEN] The text expression field is configured to reference the text field
        TextExpressionQltyTest.SetResultCondition(DefaultResult2PassCodeTok, StrSubstNo(ExpressionFormulaTestCodeTok, TextQltyTest.Code), true);
        TextExpressionQltyTest.Modify();
        ExpressionQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ExpressionQltyInspectionTemplateLine.SetRange("Test Code", TextExpressionQltyTest.Code);
        ExpressionQltyInspectionTemplateLine.FindFirst();
        ExpressionQltyInspectionTemplateLine."Expression Formula" := StrSubstNo(ExpressionFormulaTestCodeTok, TextQltyTest.Code);
        ExpressionQltyInspectionTemplateLine.Modify();
        ExpressionQltyInspectionTemplateLine.CalcFields("Test Value Type", "Allowable Values");

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line for the text field is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [WHEN] The Test Value is set to 'test' on the text field
        QltyInspection.Lines."Test Value".SetValue('test');
        QltyInspection.Close();

        // [THEN] The text field's Test Value is set to 'test'
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
        LibraryAssert.AreEqual('test', QltyInspectionLine."Test Value", 'Test value should be set.');

        // [THEN] The text expression field's Test Value is also automatically set to 'test'
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 20000);
        LibraryAssert.AreEqual('test', QltyInspectionLine."Test Value", 'Test value should be set.');

        QltyInspectionGenRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    procedure SourceConfigTable_ValidateType()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Validating To Type automatically sets the corresponding To Table No.
        Initialize();

        // [GIVEN] A source configuration record is initialized with a random code
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Validate(Code, CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code)));

        // [WHEN] To Type is validated and set to Inspection
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Inspection);

        // [THEN] To Table No. is automatically set to the Qlty. Inspection Header table
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Header", SpecificQltyInspectSourceConfig."To Table No.", 'To table should be test table.');
    end;

    [Test]
    procedure SourceConfigTable_UpdateRunOrder_OnInsert()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        MultipleQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
        MaxSortOrder: Integer;
    begin
        // [SCENARIO] OnInsert trigger automatically sets Sort Order to next available value
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] The maximum Sort Order is retrieved from existing source configurations
        MultipleQltyInspectSourceConfig.SetCurrentKey("Sort Order");
        MultipleQltyInspectSourceConfig.Ascending(false);
        MultipleQltyInspectSourceConfig.FindFirst();
        MaxSortOrder := MultipleQltyInspectSourceConfig."Sort Order";

        // [GIVEN] A new source configuration record is initialized with a random code
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(2, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));

        // [WHEN] The source configuration is inserted
        SpecificQltyInspectSourceConfig.Insert(true);

        // [THEN] Sort Order is automatically set to max + 10
        LibraryAssert.AreEqual(MaxSortOrder + 10, SpecificQltyInspectSourceConfig."Sort Order", 'Sort order should be the next one.');
    end;

    [Test]
    procedure SourceConfigTable_UpdateRunOrder_OnModify()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        MultipleQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
        MaxSortOrder: Integer;
    begin
        // [SCENARIO] OnModify trigger recalculates Sort Order when manually set to low value
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration record is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(2, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] The maximum Sort Order is retrieved from existing source configurations
        MultipleQltyInspectSourceConfig.SetCurrentKey("Sort Order");
        MultipleQltyInspectSourceConfig.Ascending(false);
        MultipleQltyInspectSourceConfig.FindFirst();
        MaxSortOrder := MultipleQltyInspectSourceConfig."Sort Order";

        // [GIVEN] Sort Order is manually set to 1
        SpecificQltyInspectSourceConfig."Sort Order" := 1;

        // [WHEN] The source configuration is modified
        SpecificQltyInspectSourceConfig.Modify(true);

        // [THEN] Sort Order is recalculated to max + 10
        LibraryAssert.AreEqual(MaxSortOrder + 10, SpecificQltyInspectSourceConfig."Sort Order", 'Sort order should be the next one.');
    end;

    [Test]
    procedure SourceConfigTable_PreventRecursion_InsertShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Insert throws error when attempting to create recursive configuration
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration is initialized with reversed From/To tables (Prod. Order Routing Line → Prod. Order Line)
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig."From Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSourceConfig."To Table No." := Database::"Prod. Order Line";

        // [WHEN] Attempting to insert the recursive configuration
        asserterror SpecificQltyInspectSourceConfig.Insert(true);

        // [THEN] An error is thrown indicating reversed configuration is not allowed
        LibraryAssert.ExpectedError(StrSubstNo(CannotHaveATemplateWithReversedFromAndToErr, ProdLineTok));
    end;

    [Test]
    procedure SourceConfigTable_PreventRecursion_ModifyShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Modify throws error when attempting to change to recursive configuration
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] From/To tables are set to create a reversed configuration (Prod. Order Routing Line → Prod. Order Line)
        SpecificQltyInspectSourceConfig."From Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSourceConfig."To Table No." := Database::"Prod. Order Line";

        // [WHEN] Attempting to modify the record with recursive configuration
        asserterror SpecificQltyInspectSourceConfig.Modify(true);

        // [THEN] An error is thrown indicating reversed configuration is not allowed
        LibraryAssert.ExpectedError(StrSubstNo(CannotHaveATemplateWithReversedFromAndToErr, ProdLineTok));
    end;

    [Test]
    procedure SourceConfigTable_OnDelete()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] OnDelete trigger removes associated source field configuration lines
        Initialize();

        // [GIVEN] A new source configuration record is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] A source field configuration line is created for the source configuration
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.Insert(true);

        // [WHEN] The source configuration is deleted
        SpecificQltyInspectSourceConfig.Delete(true);

        // [THEN] All associated source field configuration lines are deleted
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.SetRange(Code, SpecificQltyInspectSourceConfig.Code);
        LibraryAssert.IsTrue(SpecificQltyInspectSrcFldConf.IsEmpty(), 'Should be no source config lines for the source config.');
    end;

    [Test]
    procedure SourceConfigTable_DetectInterestingConfig_FromTable()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] DetectInterestingConfiguration throws error when From Table is Reservation Entry
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration is initialized with Reservation Entry as From Table
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig."From Table No." := Database::"Reservation Entry";

        // [WHEN] DetectInterestingConfiguration is called
        asserterror SpecificQltyInspectSourceConfig.DetectInterestingConfiguration();

        // [THEN] An error is thrown indicating interesting configuration detected
        LibraryAssert.ExpectedError(InterestingDetectionErr);
    end;

    [Test]
    procedure SourceConfigTable_DetectInterestingConfig_ToTable()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] DetectInterestingConfiguration throws error when To Table is Reservation Entry
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration is initialized with Reservation Entry as To Table
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig."To Table No." := Database::"Reservation Entry";

        // [WHEN] DetectInterestingConfiguration is called
        asserterror SpecificQltyInspectSourceConfig.DetectInterestingConfiguration();

        // [THEN] An error is thrown indicating interesting configuration detected
        LibraryAssert.ExpectedError(InterestingDetectionErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SourceConfigLineTable_ValidateToField_Custom()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] To Field No. can be validated to a custom field on inspection header
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new source configuration with To Type = Inspection is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Inspection);
        SpecificQltyInspectSourceConfig.Insert(true);

        // [GIVEN] A source field configuration line is initialized with To Type = Inspection
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf."Line No." := 10000;
        SpecificQltyInspectSrcFldConf.Validate("To Type", SpecificQltyInspectSrcFldConf."To Type"::Inspection);

        // [WHEN] To Field No. is validated to Source Custom 1 field
        SpecificQltyInspectSrcFldConf.Validate("To Field No.", QltyInspectionHeader.FieldNo("Source Custom 1"));

        // [THEN] To Field No. is successfully set to Source Custom 1
        LibraryAssert.AreEqual(QltyInspectionHeader.FieldNo("Source Custom 1"), SpecificQltyInspectSrcFldConf."To Field No.", 'To field should be set.');
    end;

    [Test]
    procedure SourceConfigLineTable_ValidateToType_ConfigMismatch_ShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Validating To Type throws error when mismatched with parent configuration
        Initialize();

        // [GIVEN] A new source configuration with To Type = Inspection is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Inspection);
        SpecificQltyInspectSourceConfig.Insert(true);

        // [GIVEN] A source field configuration line is initialized
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf."Line No." := 10000;

        // [WHEN] Attempting to validate To Type to "Chained table" (mismatched with parent config)
        asserterror SpecificQltyInspectSrcFldConf.Validate("To Type", SpecificQltyInspectSrcFldConf."To Type"::"Chained table");

        // [THEN] An error is thrown indicating target type mismatch
        LibraryAssert.ExpectedError(TargetErr);
    end;

    [Test]
    procedure SourceConfigLineTable_ValidateDisplayAs_NotToInspection_ShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Validating Display As throws error when To Type is not Inspection
        Initialize();

        // [GIVEN] A new source configuration with To Type = "Chained table" is created
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Insert(true);

        // [GIVEN] A source field configuration line with To Type = "Chained table" is initialized
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf."Line No." := 10000;
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";

        // [WHEN] Attempting to validate Display As field
        asserterror SpecificQltyInspectSrcFldConf.Validate("Display As", 'test');

        // [THEN] An error is thrown indicating Display As can only be set when To Type is Inspection
        LibraryAssert.ExpectedError(CanOnlyBeSetWhenToTypeIsInspectionErr);
    end;

    // Test disabled due to inconsistent behavior across environments
    // Bug 613059 to address the test stability issue
    [Test]
    procedure ApplicationAreaMgmt_IsQualityManagementApplicationAreaEnabled()
    var
        AllProfile: Record "All Profile";
        ApplicationAreaSetup: Record "Application Area Setup";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        // [SCENARIO] Quality Management application area is enabled by default on Essential experience
        Initialize();

        // [GIVEN] Application Area Setup exists or is created for current company and user
        if not ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then begin
            ApplicationAreaSetup.Init();
            ApplicationAreaSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ApplicationAreaSetup."Company Name"));
            ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApplicationAreaSetup."User ID"));
            ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
            ApplicationAreaSetup."Profile ID" := CopyStr(AllProfile."Profile ID", 1, MaxStrLen(ApplicationAreaSetup."Profile ID"));
            ApplicationAreaSetup.Insert();
        end;

        // [WHEN] Checking if Quality Management application area is enabled
        // [THEN] The application area is enabled
        LibraryAssert.AreEqual(true, QltyApplicationAreaMgmt.IsQualityManagementApplicationAreaEnabled(), 'Should be enabled.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [ModalPageHandler]
    procedure LookupTableModalPageHandler_FirstRecord(var Objects: TestPage Objects)
    begin
        Objects.First();
        Objects.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupTableModalPageHandler(var Objects: TestPage Objects)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object Caption", ChooseFromLookupValue);
        AllObjWithCaption.FindFirst();
        Objects.GoToRecord(AllObjWithCaption);
        Objects.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupFieldModalPageHandler_FirstRecord(var FieldsLookup: TestPage "Fields Lookup")
    begin
        FieldsLookup.First();
        FieldsLookup.OK().Invoke();
    end;

    [FilterPageHandler]
    procedure FilterPageHandler(var RecordRef: RecordRef): Boolean;
    begin
        RecordRef.SetView(AssistEditTemplateValue);
        exit(true);
    end;

    [ModalPageHandler]
    procedure ModalPageHandleChooseFromLookup_VendorNo(var QltyLookupFieldChoose: TestPage "Qlty. Lookup Field Choose")
    begin
        QltyLookupFieldChoose.First();
        repeat
            if QltyLookupFieldChoose.Code.Value() = ChooseFromLookupValueVendorNo then begin
                QltyLookupFieldChoose.OK().Invoke();
                exit;
            end;
        until QltyLookupFieldChoose.Next() = false;
    end;

    [ModalPageHandler]
    procedure ModalPageHandleChooseFromLookup(var QltyLookupFieldChoose: TestPage "Qlty. Lookup Field Choose")
    begin
        QltyLookupFieldChoose.First();
        repeat
            if QltyLookupFieldChoose.Code.Value() = ChooseFromLookupValue then begin
                QltyLookupFieldChoose.OK().Invoke();
                exit;
            end;
        until QltyLookupFieldChoose.Next() = false;
    end;

    [ModalPageHandler]
    procedure AssistEditTemplatePageHandler(var QltyInspectionTemplateEdit: TestPage "Qlty. Inspection Template Edit")
    begin
        QltyInspectionTemplateEdit.htmlContent.SetValue(AssistEditTemplateValue);
        QltyInspectionTemplateEdit.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
        MessageTxt := MessageText;
    end;

    [ModalPageHandler]
    procedure EditLargeTextModalPageHandler(var QltyEditLargeText: TestPage "Qlty. Edit Large Text")
    begin
        QltyEditLargeText.HtmlContent.SetValue(TestValueTxt);
        QltyEditLargeText.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure FieldsLookupModalPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    begin
        FieldsLookup.First();
        repeat
            if FieldsLookup.FieldName.Value() = ChooseFromLookupValue then begin
                FieldsLookup.OK().Invoke();
                exit;
            end;
        until FieldsLookup.Next() = false;
    end;

    [StrMenuHandler]
    procedure StrMenuPageHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure FilterItemsbyAttributeModalPageHandler(var FilterItemsByAttribute: TestPage "Filter Items by Attribute")
    begin
        FilterItemsByAttribute.Attribute.SetValue(AttributeNameToValue.Keys().Get(1));
        FilterItemsByAttribute.Value.SetValue(AttributeNameToValue.Values().Get(1));
        FilterItemsByAttribute.OK().Invoke();
    end;
}
