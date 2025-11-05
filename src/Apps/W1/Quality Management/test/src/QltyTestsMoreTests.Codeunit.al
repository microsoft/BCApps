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
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Setup.Setup;
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
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        AssistEditTemplateValue: Text;
        ChooseFromLookupValue: Text;
        ChooseFromLookupValueVendorNo: Text;
        AttributeNameToValue: Dictionary of [Text, Text];
        MessageTxt: Text;
        TemplateCodeTok: Label 'TemplateCode', Locked = true;
        GradeCodeTxt: Label 'UNAVAILABLE';
        DefaultTopLeftTok: Label 'Test', Locked = true;
        DefaultMiddleLeftTok: Label 'Grade', Locked = true;
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
        FieldTypeErrInfoMsg: Label '%1Consider replacing this field in the template with a new one, or deleting existing tests (if allowed). The field was last used on test %2.', Comment = '%1 = Error Title, %2 = Quality Inspection Test No.';
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';
        VendorFilterCountryTok: Label 'WHERE(Country/Region Code=FILTER(CA))', Locked = true;
        VendorFilterNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Vendor No.', Locked = true;
        ThereIsNoGradeErr: Label 'There is no grade called "%1". Please add the grade, or change the existing grade conditions.', Comment = '%1=the grade';
        ReviewGradesErr: Label 'Advanced configuration required. Please review the grade configurations for field "%1", for grade "%2".', Comment = '%1=the field, %2=the grade';
        OneDriveIntegrationNotConfiguredErr: Label 'The Quality Management Setup has been configured to upload pictures to OneDrive, however you have not yet configured Business Central to work with . Please configure OneDrive setup with Business Central first before using this feature.', Locked = true;
        FilterMandatoryErr: Label 'It is mandatory that a test generation rule have at least one filter defined to help prevent inadvertent over-generation of tests. Navigate to the Quality Inspection Test Generation Rules and make sure at least one filter is set for each rule that matches the %1 schedule group.', Comment = '%1=the schedule group';
        ConditionFilterItemNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Item No.', Locked = true;
        ConditionFilterAttributeTok: Label '"%1"=Filter(%2)', Comment = '%1 = Attribute Name, %2 = Attribute Value', Locked = true;
        UnableToFindRecordErr: Label 'Unable to show tests with the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheItemErr: Label 'Unable to identify the item for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheTrackingErr: Label 'Unable to identify the tracking for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheDocumentErr: Label 'Unable to identify the document for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        DefaultGrade2PassCodeTok: Label 'PASS', Locked = true;
        ExpressionFormulaFieldCodeTok: Label '[%1]', Comment = '%1=The first field code', Locked = true;
        TargetErr: Label 'When the target of the source configuration is a test, then all target fields must also refer to the test. Note that you can chain tables in another source configuration and still target test values. For example if you would like to ensure that a field from the Customer is included for a source configuration that is not directly related to a Customer then create another source configuration that links Customer to your record. ';
        CanOnlyBeSetWhenToTypeIsTestErr: Label 'This is only used when the To Type is a test';

    [Test]
    [HandlerFunctions('LookupTableModalPageHandler_FirstRecord')]
    procedure FieldCardPage_AssistEditLookupTable()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ToLoadQltyField: Record "Qlty. Field";
        QltyFieldCard: TestPage "Qlty. Field Card";
        FieldCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to select a lookup table for a Table Lookup field type

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Table Lookup" is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Insert();

        // [GIVEN] The Quality Field Card page is opened and navigated to the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [WHEN] AssistEdit is invoked on the "Lookup Table No." field
        QltyFieldCard."Lookup Table No.".AssistEdit();
        QltyFieldCard.Close();

        // [THEN] The first table from AllObjWithCaption is selected via modal handler
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();

        // [THEN] The field's Lookup Table No. is updated with the selected table ID
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(AllObjWithCaption."Object ID", ToLoadQltyField."Lookup Table No.", 'Should be same table no.')
    end;

    [Test]
    procedure FieldTable_ValidateExpressionFormula()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCode: Text;
    begin
        // [SCENARIO] Expression Formula can only be used with Expression field types, not Boolean

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Boolean" is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");
        ToLoadQltyField.Insert();

        // [WHEN] Attempting to set Expression Formula on a Boolean field type
        asserterror ToLoadQltyField.Validate("Expression Formula", ExpressionFormulaTok);

        // [THEN] An error is raised indicating Expression Formula is only for Expression field types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure FieldCardPage_AssistEditLookupTableFilter()
    var
        ToLoadQltyField: Record "Qlty. Field";
        Vendor: Record Vendor;
        QltyFieldCard: TestPage "Qlty. Field Card";
        FieldCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to define a filter for the lookup table (e.g., filter Vendors by Country)

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyField.Validate("Lookup Field No.", Vendor.FieldNo("No."));
        ToLoadQltyField.Insert();

        // [GIVEN] A filter expression for Country/Region Code is prepared for the handler
        AssistEditTemplateValue := VendorFilterCountryTok;

        // [GIVEN] The Quality Field Card page is opened and navigated to the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [WHEN] AssistEdit is invoked on the "Lookup Table Filter" field
        QltyFieldCard."Lookup Table Filter".AssistEdit();
        QltyFieldCard.Close();

        // [THEN] The field's Lookup Table Filter is updated with the country filter expression
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(VendorFilterCountryTok, ToLoadQltyField."Lookup Table Filter", 'Should be same filter.')
    end;

    [Test]
    procedure Field_OnInsert()
    var
        ToLoadQltyField: Record "Qlty. Field";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        FieldCode: Text;
    begin
        // [SCENARIO] When a Table Lookup field is inserted with a filter, Allowable Values are auto-populated from the filtered records

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Table Lookup" targeting Vendor table is configured
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyField.Validate("Lookup Field No.", Vendor.FieldNo("No."));

        // [GIVEN] A filter limiting to the specific vendor number is applied
        ToLoadQltyField.Validate("Lookup Table Filter", StrSubstNo(VendorFilterNoTok, Vendor."No."));

        // [WHEN] The field record is inserted with trigger execution
        ToLoadQltyField.Insert(true);

        // [THEN] The Allowable Values are automatically populated with the vendor number from the filtered results
        LibraryAssert.AreEqual(Vendor."No.", ToLoadQltyField."Allowable Values", 'Should be same vendor no.')
    end;

    [Test]
    procedure FieldTable_AssistEditExpressionFormula_ShouldError()
    var
        ToLoadQltyField: Record "Qlty. Field";
        QltyFieldExprCardPart: TestPage "Qlty. Field Expr. Card Part";
        FieldCode: Text;
    begin
        // [SCENARIO] AssistEdit on Expression Formula should error when field type is Boolean

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Boolean" is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");
        ToLoadQltyField.Insert();

        // [GIVEN] The Quality Field Expression Card Part page is opened and navigated to the field
        QltyFieldExprCardPart.OpenEdit();
        QltyFieldExprCardPart.GoToRecord(ToLoadQltyField);

        // [WHEN] AssistEdit is invoked on the "Expression Formula" field for a Boolean type
        asserterror QltyFieldExprCardPart."Expression Formula".AssistEdit();

        // [THEN] An error is raised indicating Expression Formula is only for Expression field types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandleChooseFromLookup_VendorNo')]
    procedure FieldTable_AssistEditDefaultValue_TypeTableLookup()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ToLoadQltyField: Record "Qlty. Field";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyFieldCard: TestPage "Qlty. Field Card";
    begin
        // [SCENARIO] User can use AssistEdit to select a default value from the lookup table for a Table Lookup field

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Max Rows Field Lookups is set to allow the vendor count
        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := Vendor.Count() + 1;
        QltyManagementSetup.Modify();

        // [GIVEN] A quality field with Field Type "Table Lookup" targeting Vendor table is created
        QltyTestsUtility.CreateField(ToLoadQltyField, ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyField.Validate("Lookup Field No.", Vendor.FieldNo("No."));
        ToLoadQltyField.Modify();

        // [GIVEN] The Quality Field Card page is opened and navigated to the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [GIVEN] The vendor number is prepared for selection via modal handler
        ChooseFromLookupValueVendorNo := Vendor."No.";

        // [WHEN] AssistEdit is invoked on the "Default Value" field
        QltyFieldCard."Default Value".AssistEdit();
        QltyFieldCard.Close();

        // [THEN] The field's Default Value is updated with the selected vendor number
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(Vendor."No.", ToLoadQltyField."Default Value", 'Should be same vendor no.')
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure FieldTable_AssistEditExpressionFormula()
    var
        ToLoadQltyField: Record "Qlty. Field";
        QltyFieldExprCardPart: TestPage "Qlty. Field Expr. Card Part";
        FieldCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to define an expression formula for a Text Expression field type

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Text Expression" is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Text Expression");
        ToLoadQltyField.Insert();

        // [GIVEN] The Quality Field Expression Card Part page is opened and navigated to the field
        QltyFieldExprCardPart.OpenEdit();
        QltyFieldExprCardPart.GoToRecord(ToLoadQltyField);

        // [GIVEN] An expression formula value is prepared for the handler
        AssistEditTemplateValue := ExpressionFormulaTok;

        // [WHEN] AssistEdit is invoked on the "Expression Formula" field
        QltyFieldExprCardPart."Expression Formula".AssistEdit();

        // [THEN] The field's Expression Formula is updated with the prepared value
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(ExpressionFormulaTok, ToLoadQltyField."Expression Formula", 'Should be same expression formula.')
    end;

    [Test]
    procedure FieldTable_ValidateFieldType_ShouldError()
    var
        ToLoadQltyField: Record "Qlty. Field";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Changing a field type should error if the field is already used in an existing test

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The first test line is retrieved
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);

        // [GIVEN] The field used in the test line is retrieved
        ToLoadQltyField.Get(QltyInspectionTestLine."Field Code");

        // [WHEN] Attempting to change the field type to Boolean
        asserterror ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");

        // [THEN] An error is raised indicating the field cannot be changed because it's used in test
        LibraryAssert.ExpectedError(StrSubstNo(FieldTypeErrInfoMsg, '', QltyInspectionTestHeader."No."));
    end;

    [Test]
    procedure FieldTable_SetGradeCondition_CannotGetGrade_ShouldError()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] Setting a grade condition should error if the grade does not exist and ThrowError is true

        // [GIVEN] Any existing grade with code 'UNAVAILABLE' is deleted
        ToLoadQltyInspectionGrade.SetRange(Code, GradeCodeTxt);
        if ToLoadQltyInspectionGrade.FindFirst() then
            ToLoadQltyInspectionGrade.Delete();

        // [WHEN] Attempting to set a grade condition for a non-existent grade with ThrowError = true
        asserterror ToLoadQltyField.SetGradeCondition(GradeCodeTxt, '', true);

        // [THEN] An error is raised indicating the grade does not exist
        LibraryAssert.ExpectedError(StrSubstNo(ThereIsNoGradeErr, GradeCodeTxt));
    end;

    [Test]
    procedure FieldTable_SetGradeCondition_CannotGetGrade_ShouldExit()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] Setting a grade condition should exit gracefully if the grade does not exist and ThrowError is false

        // [GIVEN] Any existing grade with code 'UNAVAILABLE' is deleted
        ToLoadQltyInspectionGrade.SetRange(Code, GradeCodeTxt);
        if ToLoadQltyInspectionGrade.FindFirst() then
            ToLoadQltyInspectionGrade.Delete();

        // [WHEN] Attempting to set a grade condition for a non-existent grade with ThrowError = false
        ToLoadQltyField.SetGradeCondition(GradeCodeTxt, '', false);

        // [THEN] The operation exits gracefully without raising an error
    end;

    [Test]
    procedure FieldTable_SetGradeCondition_CannotGetGradeConfig_ShouldError()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        FieldCodeTxt: Text;
    begin
        // [SCENARIO] Setting a grade condition should error if the grade exists but has no configuration and ThrowError is true

        // [GIVEN] A grade with code 'UNAVAILABLE' exists
        ToLoadQltyInspectionGrade.SetRange(Code, GradeCodeTxt);
        if not ToLoadQltyInspectionGrade.FindFirst() then begin
            ToLoadQltyInspectionGrade.Validate(Code, GradeCodeTxt);
            ToLoadQltyInspectionGrade.Insert();
        end;

        // [GIVEN] Any existing grade condition configurations for this grade are deleted
        ToLoadQltyIGradeConditionConf.SetRange("Grade Code", GradeCodeTxt);
        if ToLoadQltyIGradeConditionConf.FindSet() then
            ToLoadQltyIGradeConditionConf.DeleteAll();

        // [GIVEN] A random field code is generated and a field is created
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCodeTxt);
        ToLoadQltyField.Validate(Code, CopyStr(FieldCodeTxt, 1, MaxStrLen(ToLoadQltyField.Code)));

        // [WHEN] Attempting to set a grade condition with no configuration and ThrowError = true
        asserterror ToLoadQltyField.SetGradeCondition(GradeCodeTxt, '', true);

        // [THEN] An error is raised indicating the grade configuration needs review
        LibraryAssert.ExpectedError(StrSubstNo(ReviewGradesErr, FieldCodeTxt, GradeCodeTxt));
    end;

    [Test]
    procedure FieldTable_SetGradeCondition_CannotGetGradeConfig_ShouldExit()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] Setting a grade condition should exit gracefully if the grade exists but has no configuration and ThrowError is false

        // [GIVEN] A grade with code 'UNAVAILABLE' exists
        ToLoadQltyInspectionGrade.SetRange(Code, GradeCodeTxt);
        if not ToLoadQltyInspectionGrade.FindFirst() then begin
            ToLoadQltyInspectionGrade.Validate(Code, GradeCodeTxt);
            ToLoadQltyInspectionGrade.Insert();
        end;

        // [GIVEN] Any existing grade condition configurations for this grade are deleted
        ToLoadQltyIGradeConditionConf.SetRange("Grade Code", GradeCodeTxt);
        if ToLoadQltyIGradeConditionConf.FindSet() then
            ToLoadQltyIGradeConditionConf.DeleteAll();

        // [WHEN] Attempting to set a grade condition with no configuration and ThrowError = false
        ToLoadQltyField.SetGradeCondition(GradeCodeTxt, '', false);

        // [THEN] The operation exits gracefully without raising an error
    end;

    [Test]
    [HandlerFunctions('FieldsLookupModalPageHandler')]
    procedure FieldTable_OnLookupFieldNo()
    var
        ToLoadQltyField: Record "Qlty. Field";
        Vendor: Record Vendor;
        QltyFieldCard: TestPage "Qlty. Field Card";
        FieldCode: Text;
    begin
        // [SCENARIO] User can use Lookup to select a field from the lookup table (e.g., select Vendor "No." field)

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyField.Insert();

        // [GIVEN] The Quality Field Card page is opened and navigated to the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [GIVEN] The Vendor "No." field name is prepared for selection via modal handler
        ChooseFromLookupValue := Vendor.FieldName("No.");

        // [WHEN] Lookup is invoked on the "Lookup Field No." field
        QltyFieldCard."Lookup Field No.".Lookup();
        QltyFieldCard.Close();

        // [THEN] The field's Lookup Field No. is updated with the Vendor "No." field number
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(Vendor.FieldNo("No."), ToLoadQltyField."Lookup Field No.", 'Should be same lookup field no.');
    end;

    [Test]
    [HandlerFunctions('FieldsLookupModalPageHandler')]
    procedure FieldTable_AssistEditLookupField()
    var
        ToLoadQltyField: Record "Qlty. Field";
        Vendor: Record Vendor;
        QltyFieldCard: TestPage "Qlty. Field Card";
        FieldCode: Text;
    begin
        // [SCENARIO] User can use AssistEdit to select a field from the lookup table (e.g., select Vendor "No." field)

        // [GIVEN] A random field code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, FieldCode);

        // [GIVEN] A new quality field with Field Type "Table Lookup" targeting Vendor table is created
        ToLoadQltyField.Validate(Code, CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Table Lookup");
        ToLoadQltyField.Validate("Lookup Table No.", Database::Vendor);
        ToLoadQltyField.Insert();

        // [GIVEN] The Quality Field Card page is opened and navigated to the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [GIVEN] The Vendor "No." field name is prepared for selection via modal handler
        ChooseFromLookupValue := Vendor.FieldName("No.");

        // [WHEN] AssistEdit is invoked on the "Lookup Field No." field
        QltyFieldCard."Lookup Field No.".AssistEdit();
        QltyFieldCard.Close();

        // [THEN] The field's Lookup Field No. is updated with the Vendor "No." field number
        ToLoadQltyField.Get(ToLoadQltyField.Code);
        LibraryAssert.AreEqual(Vendor.FieldNo("No."), ToLoadQltyField."Lookup Field No.", 'Should be same lookup field no.');
    end;

    [Test]
    procedure SetupTable_ValidatePictureUploadBehavior()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] Picture Upload Behavior can be validated and changed to "Attach document"

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [GIVEN] Any existing setup record is deleted
        if QltyManagementSetup.Get() then
            QltyManagementSetup.Delete();

        // [GIVEN] A new setup record is initialized
        QltyManagementSetup.Init();

        // [WHEN] The setup record is inserted with trigger execution
        QltyManagementSetup.Insert(true);

        // [THEN] Brick Top Left Header is set to default value 'Test'
        LibraryAssert.AreEqual(DefaultTopLeftTok, QltyManagementSetup."Brick Top Left Header", 'Top left header should be default value');

        // [THEN] Brick Middle Left Header is set to default value 'Grade'
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

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] The setup record is retrieved
        QltyManagementSetup.Get();

        // [WHEN] GetSetupVideoLink is called
        // [THEN] An empty string is returned
        LibraryAssert.AreEqual('', QltyManagementSetup.GetSetupVideoLink(), 'Setup video link should be empty');
    end;

    [Test]
    procedure TemplateLineTable_OnModify_TextExpression()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        FieldCode: Text;
    begin
        // [SCENARIO] Template line can be modified to set Expression Formula for a Text Expression field type

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A new template is created
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Text Expression field is created
        ToLoadQltyField.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Text Expression");
        ToLoadQltyField.Insert();

        // [GIVEN] A template line is created with the Text Expression field
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine."Field Code" := ToLoadQltyField.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.CalcFields("Field Type");

        // [WHEN] Expression Formula is validated and the template line is modified
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Expression Formula", ExpressionFormulaTok);
        ConfigurationToLoadQltyInspectionTemplateLine.Modify(true);

        // [THEN] The Expression Formula is successfully updated on the template line
        LibraryAssert.AreEqual(ExpressionFormulaTok, ConfigurationToLoadQltyInspectionTemplateLine."Expression Formula", 'Expression formula should be updated');
    end;

    [Test]
    procedure TemplateLineTable_AssistEditExpressionFormula_ShouldError()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        FieldCode: Text;
    begin
        // [SCENARIO] Attempting to set Expression Formula on a template line with Boolean field type should error

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A new template is created
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Boolean field is created
        ToLoadQltyField.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");
        ToLoadQltyField.Insert();

        // [GIVEN] A template line is created with the Boolean field
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine."Field Code" := ToLoadQltyField.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.CalcFields("Field Type");

        // [WHEN] Attempting to validate Expression Formula on a Boolean field type
        asserterror ConfigurationToLoadQltyInspectionTemplateLine.Validate("Expression Formula", ExpressionFormulaTok);

        // [THEN] An error is raised indicating Expression Formula is only for Expression field types
        LibraryAssert.ExpectedError(OnlyFieldExpressionErr);
    end;

    [Test]
    procedure GenerationRule_ValidateScheduleGroup_NoFilters_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Setting a Schedule Group on a generation rule without filters should error

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyTestsUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule is created without any filters
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInTestGenerationRule.Insert();

        // [GIVEN] A random schedule group code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, ScheduleGroupCode);

        // [WHEN] Attempting to validate Schedule Group without filters
        asserterror QltyInTestGenerationRule.Validate("Schedule Group", ScheduleGroupCode);

        // [THEN] An error is raised indicating at least one filter is mandatory
        LibraryAssert.ExpectedError(StrSubstNo(FilterMandatoryErr, ScheduleGroupCode));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_ValidateScheduleGroup_NewScheduleGroup()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Setting a new Schedule Group on a generation rule with filters creates a job queue entry

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyTestsUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule with filters and default schedule group is created
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInTestGenerationRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInTestGenerationRule."Condition Filter" := ConditionProductionFilterTok;
        QltyInTestGenerationRule."Schedule Group" := DefaultScheduleGroupTok;
        QltyInTestGenerationRule.Insert();

        // [GIVEN] A random new schedule group code is generated
        QltyTestsUtility.GenerateRandomCharacters(20, ScheduleGroupCode);

        // [GIVEN] Job Queue Entries page is trapped for verification
        JobQueueEntries.Trap();

        // [WHEN] Schedule Group is validated with the new schedule group code
        QltyInTestGenerationRule.Validate("Schedule Group", ScheduleGroupCode);

        // [THEN] The Schedule Group is successfully updated
        LibraryAssert.IsTrue(QltyInTestGenerationRule."Schedule Group" = ScheduleGroupCode, 'Schedule group should be updated');

        // [THEN] A job queue entry is created for the schedule inspection test report
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection Test");
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRule_LookupJobQueue_Default()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        JobQueueEntry: Record "Job Queue Entry";
        QltyInTestGeneratRules: TestPage "Qlty. In. Test Generat. Rules";
        JobQueueEntries: TestPage "Job Queue Entries";
        TemplateCode: Text;
    begin
        // [SCENARIO] Using Lookup on Schedule Group creates default schedule group and job queue entry

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] All existing templates are deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.DeleteAll();

        // [GIVEN] A random template code is generated and a template is created
        QltyTestsUtility.GenerateRandomCharacters(20, TemplateCode);
        TemplateCode := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateHdr.Insert();

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule with filters but no schedule group is created
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInTestGenerationRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInTestGenerationRule."Condition Filter" := ConditionProductionFilterTok;
        QltyInTestGenerationRule.Insert();

        // [GIVEN] All existing job queue entries for schedule inspection test are deleted
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection Test");
        if JobQueueEntry.FindSet() then
            JobQueueEntry.DeleteAll();

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInTestGeneratRules.OpenEdit();
        QltyInTestGeneratRules.GoToRecord(QltyInTestGenerationRule);

        // [GIVEN] Job Queue Entries page is trapped for verification
        JobQueueEntries.Trap();

        // [WHEN] Lookup is invoked on the Schedule Group field
        QltyInTestGeneratRules."Schedule Group".Lookup();
        JobQueueEntries.Close();
        QltyInTestGeneratRules.Close();

        // [THEN] The default schedule group 'QM' is assigned to the rule
        QltyInTestGenerationRule.Get(QltyInTestGenerationRule."Entry No.");
        LibraryAssert.AreEqual(DefaultScheduleGroupTok, QltyInTestGenerationRule."Schedule Group", 'Default schedule group should be created');

        // [THEN] A job queue entry is created for the schedule inspection test report
        LibraryAssert.IsTrue(JobQueueEntry.Count() = 1, 'Should have created a job queue entry');
    end;

    [Test]
    procedure GenerationRuleList_ValidateProductionTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Production Trigger can be validated and set to OnProductionOrderRelease

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Prod. Order Routing Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Prod. Order Routing Line";

        // [WHEN] Production Trigger is validated and set to OnProductionOrderRelease (value 2)
        QltyInTestGenerationRule.Validate("Production Trigger", 2); // OnProductionOrderRelease

        // [THEN] The Production Trigger is successfully set to OnProductionOrderRelease
        LibraryAssert.AreEqual(2, QltyInTestGenerationRule."Production Trigger", 'Production trigger should be set to on release');
    end;

    [Test]
    procedure GenerationRuleList_ValidateWarehouseReceiveTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Warehouse Receive Trigger can be validated and set to OnWarehouseReceiptCreate

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Warehouse Receipt Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Warehouse Receipt Line";

        // [WHEN] Warehouse Receive Trigger is validated and set to OnWarehouseReceiptCreate
        QltyInTestGenerationRule.Validate("Warehouse Receive Trigger", QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate);

        // [THEN] The Warehouse Receive Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate, QltyInTestGenerationRule."Warehouse Receive Trigger", 'Warehouse Receipt trigger should be set to on receipt create');
    end;

    [Test]
    procedure GenerationRuleList_ValidateWarehouseMovementTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Warehouse Movement Trigger can be validated and set to OnWhseMovementRegister

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Warehouse Entry with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Warehouse Entry";

        // [WHEN] Warehouse Movement Trigger is validated and set to OnWhseMovementRegister
        QltyInTestGenerationRule.Validate("Warehouse Movement Trigger", QltyInTestGenerationRule."Warehouse Movement Trigger"::OnWhseMovementRegister);

        // [THEN] The Warehouse Movement Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Warehouse Movement Trigger"::OnWhseMovementRegister, QltyInTestGenerationRule."Warehouse Movement Trigger", 'Warehouse Movement trigger should be set to into bin');
    end;

    [Test]
    procedure GenerationRuleList_ValidatePurchaseTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Purchase Trigger can be validated and set to OnPurchaseOrderPostReceive

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Purchase Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Purchase Line";

        // [WHEN] Purchase Trigger is validated and set to OnPurchaseOrderPostReceive
        QltyInTestGenerationRule.Validate("Purchase Trigger", QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive);

        // [THEN] The Purchase Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive, QltyInTestGenerationRule."Purchase Trigger", 'Purchase trigger should be set to on purchase post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateSalesReturnTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Sales Return Trigger can be validated and set to OnSalesReturnOrderPostReceive

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Sales Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Sales Line";

        // [WHEN] Sales Return Trigger is validated and set to OnSalesReturnOrderPostReceive
        QltyInTestGenerationRule.Validate("Sales Return Trigger", QltyInTestGenerationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive);

        // [THEN] The Sales Return Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive, QltyInTestGenerationRule."Sales Return Trigger", 'Sales Return trigger should be set to on sales return post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateTransferTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Transfer Trigger can be validated and set to OnTransferOrderPostReceive

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Transfer Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Transfer Line";

        // [WHEN] Transfer Trigger is validated and set to OnTransferOrderPostReceive
        QltyInTestGenerationRule.Validate("Transfer Trigger", QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive);

        // [THEN] The Transfer Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Transfer Trigger"::OnTransferOrderPostReceive, QltyInTestGenerationRule."Transfer Trigger", 'Transfer trigger should be set to on transfer receive post');
    end;

    [Test]
    procedure GenerationRuleList_ValidateAssemblyTrigger()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Assembly Trigger can be validated and set to OnAssemblyOutputPost

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Assembly Line with Disabled activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::Disabled;
        QltyInTestGenerationRule."Source Table No." := Database::"Assembly Line";

        // [WHEN] Assembly Trigger is validated and set to OnAssemblyOutputPost
        QltyInTestGenerationRule.Validate("Assembly Trigger", QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost);

        // [THEN] The Assembly Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost, QltyInTestGenerationRule."Assembly Trigger", 'Assembly trigger should be set to on any output posted ledger');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GenerationRuleList_ValidateAssemblyTrigger_ChangetoManualOrAuto()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        // [SCENARIO] Setting Assembly Trigger changes Activation Trigger from "Manual only" to "Manual or Automatic"

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new generation rule for Assembly Line with "Manual only" activation trigger is initialized
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Template Code" := TemplateCodeTok;
        QltyInTestGenerationRule."Activation Trigger" := QltyInTestGenerationRule."Activation Trigger"::"Manual only";
        QltyInTestGenerationRule."Source Table No." := Database::"Assembly Line";

        // [WHEN] Assembly Trigger is validated and set to OnAssemblyOutputPost
        QltyInTestGenerationRule.Validate("Assembly Trigger", QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost);

        // [THEN] The Assembly Trigger is successfully set
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost, QltyInTestGenerationRule."Assembly Trigger", 'Assembly trigger should be set to on any output posted ledger');

        // [THEN] The Activation Trigger is automatically changed to "Manual or Automatic"
        LibraryAssert.AreEqual(QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger", 'Activation trigger should be set to manual or automatic');
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure GenerationRuleList_AssistEditConditionTableFilter()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInTestGeneratRules: TestPage "Qlty. In. Test Generat. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define a Condition Filter for generation rule

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInTestGenerationRule.Insert();

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInTestGeneratRules.OpenEdit();
        QltyInTestGeneratRules.GoToRecord(QltyInTestGenerationRule);

        // [GIVEN] A production filter expression is prepared for the handler
        AssistEditTemplateValue := ConditionProductionFilterTok;

        // [WHEN] AssistEdit is invoked on the "Condition Filter" field
        QltyInTestGeneratRules."Condition Filter".AssistEdit();
        QltyInTestGeneratRules.Close();

        // [THEN] The Condition Filter is updated with the production filter expression
        QltyInTestGenerationRule.Get(QltyInTestGenerationRule."Entry No.");
        LibraryAssert.AreEqual(ConditionProductionFilterTok, QltyInTestGenerationRule."Condition Filter", 'Condition filter should be set to the default');
    end;

    [Test]
    [HandlerFunctions('FilterPageHandler')]
    procedure GenerationRuleList_AssistEditConditionItemFilter()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        QltyInTestGeneratRules: TestPage "Qlty. In. Test Generat. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define an Item Filter for generation rule

        // [GIVEN] Quality Management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInTestGenerationRule.Insert();

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInTestGeneratRules.OpenEdit();
        QltyInTestGeneratRules.GoToRecord(QltyInTestGenerationRule);

        // [GIVEN] An item filter expression for the created item is prepared for the handler
        AssistEditTemplateValue := StrSubstNo(ConditionFilterItemNoTok, Item."No.");

        // [WHEN] AssistEdit is invoked on the "Item Filter" field
        QltyInTestGeneratRules."Item Filter".AssistEdit();
        QltyInTestGeneratRules.Close();

        // [THEN] The Item Filter is updated with the item number filter expression
        QltyInTestGenerationRule.Get(QltyInTestGenerationRule."Entry No.");
        LibraryAssert.AreEqual(StrSubstNo(ConditionFilterItemNoTok, Item."No."), QltyInTestGenerationRule."Item Filter", 'Item filter should be set to the item no.');
    end;

    [Test]
    [HandlerFunctions('FilterItemsbyAttributeModalPageHandler')]
    procedure GenerationRuleList_AssistEditConditionAttributeFilter()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyInTestGeneratRules: TestPage "Qlty. In. Test Generat. Rules";
    begin
        // [SCENARIO] User can use AssistEdit to define an Item Attribute Filter for generation rule

        // [GIVEN] An item attribute with value 'Red' is created
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Option, 'Red');

        // [GIVEN] All existing generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A new generation rule for Item Ledger Entry is created
        QltyInTestGenerationRule.Init();
        QltyInTestGenerationRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInTestGenerationRule.Insert();

        // [GIVEN] The Generation Rules page is opened and navigated to the rule
        QltyInTestGeneratRules.OpenEdit();
        QltyInTestGeneratRules.GoToRecord(QltyInTestGenerationRule);

        // [GIVEN] The attribute name and value are prepared for selection via modal handler
        AttributeNameToValue.Add(ItemAttribute.Name, ItemAttributeValue.Value);

        // [WHEN] AssistEdit is invoked on the "Item Attribute Filter" field
        QltyInTestGeneratRules."Item Attribute Filter".AssistEdit();
        QltyInTestGeneratRules.Close();

        // [THEN] The Item Attribute Filter is updated with the attribute filter expression
        QltyInTestGenerationRule.Get(QltyInTestGenerationRule."Entry No.");
        LibraryAssert.AreEqual(StrSubstNo(ConditionFilterAttributeTok, ItemAttribute.Name, ItemAttributeValue.Value), QltyInTestGenerationRule."Item Attribute Filter", 'Attribute filter should be set to the attribute value.');
    end;

    [Test]
    procedure Table_ChangeSourceQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        // [SCENARIO] Negative Source Quantity value is converted to absolute positive value

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Source Quantity (Base) is validated with a negative value (-100)
        QltyInspectionTestHeader.Validate("Source Quantity (Base)", -100);

        // [THEN] Source Quantity (Base) is stored as the absolute value (100)
        LibraryAssert.AreEqual(100, QltyInspectionTestHeader."Source Quantity (Base)", 'Source quantity should be 100');
    end;

    [Test]
    procedure Table_ValidatePassQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        // [SCENARIO] Pass Quantity can be set to match Source Quantity

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Pass Quantity is validated with the Source Quantity value
        QltyInspectionTestHeader.Validate("Pass Quantity", QltyInspectionTestHeader."Source Quantity (Base)");

        // [THEN] Pass Quantity equals the Source Quantity
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Source Quantity (Base)", QltyInspectionTestHeader."Pass Quantity", 'Pass quantity should be the same as the source quantity');
    end;

    [Test]
    procedure Table_ValidateFailQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        // [SCENARIO] Fail Quantity can be set to match Source Quantity

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [WHEN] Fail Quantity is validated with the Source Quantity value
        QltyInspectionTestHeader.Validate("Fail Quantity", QltyInspectionTestHeader."Source Quantity (Base)");

        // [THEN] Fail Quantity equals the Source Quantity
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Source Quantity (Base)", QltyInspectionTestHeader."Fail Quantity", 'Fail quantity should be the same as the source quantity');
    end;

    [Test]
    procedure Table_GetRelatedItem_NoSourceItemNoOnTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO] GetRelatedItem retrieves item from source document when Source Item No. is blank

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Source Item No. is cleared and the record is modified
        QltyInspectionTestHeader."Source Item No." := '';
        QltyInspectionTestHeader.Modify();

        // [WHEN] GetRelatedItem is called to retrieve the item
        QltyInspectionTestHeader.GetRelatedItem(Item);

        // [THEN] The item returned matches the item from the source production order line
        ProdOrderLine.SetRange(Status, QltyInspectionTestHeader."Source Type");
        ProdOrderLine.SetRange("Prod. Order No.", QltyInspectionTestHeader."Source Document No.");
        ProdOrderLine.SetRange("Line No.", QltyInspectionTestHeader."Source Document Line No.");
        ProdOrderLine.FindFirst();
        LibraryAssert.AreEqual(ProdOrderLine."Item No.", Item."No.", 'Source item should be the item from the production order routing line.');
    end;

    [Test]
    procedure Table_GetItemAttributeValue()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO] GetItemAttributeValue retrieves the correct attribute value for the source item

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] An item attribute 'Red' is created with a value
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Option, 'Red');

        // [GIVEN] The attribute is mapped to the item
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Test header's Source Item No. is set to the created item
        QltyInspectionTestHeader."Source Item No." := Item."No.";

        // [WHEN] GetItemAttributeValue is called with the attribute name
        // [THEN] The returned value matches the item attribute value
        LibraryAssert.AreEqual(ItemAttributeValue.Value, QltyInspectionTestHeader.GetItemAttributeValue(ItemAttribute.Name), 'Item attribute value should be the same value.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_NullVariant()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ordId: RecordId;
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor throws an error when provided with a null RecordId

        // [GIVEN] A null RecordId

        // [WHEN] SetRecordFiltersToFindTestFor is called with the null RecordId
        asserterror QltyInspectionTestHeader.SetRecordFiltersToFindTestFor(true, ordId, false, false, false);

        // [THEN] An error is thrown indicating the record cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(UnableToFindRecordErr, ordId));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_NoSourceItem()
    var
        Location: Record Location;
        Item: Record Item;
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor throws error when item cannot be identified

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [WHEN] SetRecordFiltersToFindTestFor is called with requireItemFilter = true
        asserterror QltyInspectionTestHeader.SetRecordFiltersToFindTestFor(true, PurchaseLine, true, false, false);

        // [THEN] An error is thrown indicating the item cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheItemErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_NoSourceTracking()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor throws error when tracking information cannot be identified

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [WHEN] SetRecordFiltersToFindTestFor is called with requireTrackingFilter = true
        asserterror QltyInspectionTestHeader.SetRecordFiltersToFindTestFor(true, PurchaseLine, false, true, false);

        // [THEN] An error is thrown indicating tracking information cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheTrackingErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_NoSourceDocument()
    var
        Location: Record Location;
        Item: Record Item;
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor throws error when document information cannot be identified

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

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

        // [GIVEN] Test header has variant, lot, serial, and package tracking set
        QltyInspectionTestHeader."Source Variant Code" := 'Variant';
        QltyInspectionTestHeader."Source Lot No." := 'Lot';
        QltyInspectionTestHeader."Source Serial No." := 'Serial';
        QltyInspectionTestHeader."Source Package No." := 'Package';

        // [WHEN] SetRecordFiltersToFindTestFor is called with requireDocumentFilter = true
        asserterror QltyInspectionTestHeader.SetRecordFiltersToFindTestFor(true, PurchaseLine, false, false, true);

        // [THEN] An error is thrown indicating the document cannot be identified
        LibraryAssert.ExpectedError(StrSubstNo(UnableToIdentifyTheDocumentErr, PurchaseLine.RecordId()));
    end;

    [Test]
    procedure LineTable_OnInsert()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
    begin
        // [SCENARIO] OnInsert trigger sets system timestamps on test line

        // [GIVEN] A test header is inserted
        QltyInspectionTestHeader.Insert();

        // [GIVEN] A test line is initialized with header keys and line number
        QltyInspectionTestLine."Test No." := QltyInspectionTestHeader."No.";
        QltyInspectionTestLine."Retest No." := QltyInspectionTestHeader."Retest No.";
        QltyInspectionTestLine."Line No." := 10000;

        // [WHEN] The test line is inserted
        QltyInspectionTestLine.Insert(true);

        // [THEN] SystemCreatedAt and SystemModifiedAt timestamps are populated
        LibraryAssert.IsTrue(QltyInspectionTestLine.SystemCreatedAt <> 0DT, 'SystemCreatedAt should be set.');
        LibraryAssert.IsTrue(QltyInspectionTestLine.SystemModifiedAt <> 0DT, 'SystemModifiedAt should be set.');
    end;

    [Test]
    procedure LineTable_OnDelete()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        // [SCENARIO] OnDelete trigger removes associated grade condition configurations

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);

        // [GIVEN] A grade condition configuration is created for the test line
        ToLoadQltyIGradeConditionConf."Condition Type" := ToLoadQltyIGradeConditionConf."Condition Type"::Test;
        ToLoadQltyIGradeConditionConf."Target Code" := QltyInspectionTestHeader."No.";
        ToLoadQltyIGradeConditionConf."Target Retest No." := QltyInspectionTestHeader."Retest No.";
        ToLoadQltyIGradeConditionConf."Target Line No." := 10000;
        ToLoadQltyIGradeConditionConf."Grade Code" := DefaultGrade2PassCodeTok;
        ToLoadQltyIGradeConditionConf."Field Code" := QltyInspectionTestLine."Field Code";
        ToLoadQltyIGradeConditionConf.Insert();

        // [WHEN] The test line is deleted
        QltyInspectionTestLine.Delete(true);

        // [THEN] All associated grade condition configurations are deleted
        Clear(ToLoadQltyIGradeConditionConf);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Test);
        ToLoadQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTestHeader."No.");
        ToLoadQltyIGradeConditionConf.SetRange("Target Retest No.", QltyInspectionTestHeader."Retest No.");
        ToLoadQltyIGradeConditionConf.SetRange("Target Line No.", 10000);
        LibraryAssert.IsTrue(ToLoadQltyIGradeConditionConf.IsEmpty(), 'Should be no grade condition config lines for the test line.');
    end;

    [Test]
    [HandlerFunctions('EditLargeTextModalPageHandler')]
    procedure LineTable_RunModalMeasurementNote()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestSubform: TestPage "Qlty. Inspection Test Subform";
    begin
        // [SCENARIO] User can edit measurement note via modal editor on test line

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The test line is retrieved and the test subform page is opened
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        QltyInspectionTestSubform.OpenEdit();
        QltyInspectionTestSubform.GoToRecord(QltyInspectionTestLine);

        // [WHEN] AssistEdit is invoked on the Measurement Note field
        QltyInspectionTestSubform.ChooseMeasurementNote.AssistEdit();

        // [THEN] The measurement note is updated with the text entered via modal
        LibraryAssert.AreEqual(TestValueTxt, QltyInspectionTestLine.GetMeasurementNote(), 'Measurement note should be set.');
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure LineTable_AssistEditChooseFromList()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyField: Record "Qlty. Field";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
    begin
        // [SCENARIO] User can use AssistEdit to select from allowable values list for Test Value

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Field Type Option field having allowable values
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, ToLoadQltyField, ToLoadQltyField."Field Type"::"Field Type Option");
        ToLoadQltyField."Allowable Values" := OptionsTok;
        ToLoadQltyField.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and a test is created from the purchase line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        QltyTestsUtility.CreateTestWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionTestHeader);

        // [GIVEN] The test line is retrieved and the test page is opened
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        QltyInspectionTest.OpenEdit();
        QltyInspectionTest.GoToRecord(QltyInspectionTestHeader);
        QltyInspectionTest.Lines.GoToRecord(QltyInspectionTestLine);

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspectionTest.Lines."Test Value".AssistEdit();
        QltyInspectionTest.Close();

        // [THEN] The Test Value is set to the selected option from the list
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        LibraryAssert.AreEqual('Option1', QltyInspectionTestLine."Test Value", 'Test value should be set.');

        QltyInTestGenerationRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ModalPageHandleChooseFromLookup')]
    procedure LineTable_AssistEditChooseFromTableLookup()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        LookupQltyField: Record "Qlty. Field";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
    begin
        // [SCENARIO] User can use AssistEdit to select from table lookup for Test Value

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Field Type Table Lookup field configured for Location table
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQltyField, LookupQltyField."Field Type"::"Field Type Table Lookup");
        LookupQltyField."Lookup Table No." := Database::Location;
        LookupQltyField."Lookup Field No." := Location.FieldNo(Code);
        LookupQltyField.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and a test is created from the purchase line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        QltyTestsUtility.CreateTestWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionTestHeader);

        // [GIVEN] The test line is retrieved and the test page is opened
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        QltyInspectionTest.OpenEdit();
        QltyInspectionTest.GoToRecord(QltyInspectionTestHeader);
        QltyInspectionTest.Lines.GoToRecord(QltyInspectionTestLine);

        // [GIVEN] A location code is prepared for selection via modal handler
        ChooseFromLookupValue := Location.Code;

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspectionTest.Lines."Test Value".AssistEdit();
        QltyInspectionTest.Close();

        // [THEN] The Test Value is set to the selected location code from the lookup
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        LibraryAssert.AreEqual(Location.Code, QltyInspectionTestLine."Test Value", 'Test value should be set.');

        QltyInTestGenerationRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    procedure LineTable_UpdateExpressionsInOtherTestLines_TextExpression()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ExpressionQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyField: Record "Qlty. Field";
        TextExpressionQltyField: Record "Qlty. Field";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
    begin
        // [SCENARIO] Updating a text field value automatically updates dependent text expression fields

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A text field is added to the template
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextQltyField, TextQltyField."Field Type"::"Field Type Text");

        // [GIVEN] A text expression field is added to the template
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextExpressionQltyField, TextExpressionQltyField."Field Type"::"Field Type Text Expression");

        // [GIVEN] The text expression field is configured to reference the text field
        TextExpressionQltyField.SetGradeCondition(DefaultGrade2PassCodeTok, StrSubstNo(ExpressionFormulaFieldCodeTok, TextQltyField.Code), true);
        TextExpressionQltyField.Modify();
        ExpressionQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ExpressionQltyInspectionTemplateLine.SetRange("Field Code", TextExpressionQltyField.Code);
        ExpressionQltyInspectionTemplateLine.FindFirst();
        ExpressionQltyInspectionTemplateLine."Expression Formula" := StrSubstNo(ExpressionFormulaFieldCodeTok, TextQltyField.Code);
        ExpressionQltyInspectionTemplateLine.Modify();
        ExpressionQltyInspectionTemplateLine.CalcFields("Field Type", "Allowable Values");

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and a test is created from the purchase line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        QltyTestsUtility.CreateTestWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionTestHeader);

        // [GIVEN] The test line for the text field is retrieved and the test page is opened
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        QltyInspectionTest.OpenEdit();
        QltyInspectionTest.GoToRecord(QltyInspectionTestHeader);
        QltyInspectionTest.Lines.GoToRecord(QltyInspectionTestLine);

        // [WHEN] The Test Value is set to 'test' on the text field
        QltyInspectionTest.Lines."Test Value".SetValue('test');
        QltyInspectionTest.Close();

        // [THEN] The text field's Test Value is set to 'test'
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 10000);
        LibraryAssert.AreEqual('test', QltyInspectionTestLine."Test Value", 'Test value should be set.');

        // [THEN] The text expression field's Test Value is also automatically set to 'test'
        QltyInspectionTestLine.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", 20000);
        LibraryAssert.AreEqual('test', QltyInspectionTestLine."Test Value", 'Test value should be set.');

        QltyInTestGenerationRule.Delete();
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    procedure SourceConfigTable_ValidateType()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Validating To Type automatically sets the corresponding To Table No.

        // [GIVEN] A source configuration record is initialized with a random code
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Validate(Code, CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code)));

        // [WHEN] To Type is validated and set to Test
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Test);

        // [THEN] To Table No. is automatically set to the Qlty. Inspection Test Header table
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Test Header", SpecificQltyInspectSourceConfig."To Table No.", 'To table should be test table.');
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] The maximum Sort Order is retrieved from existing source configurations
        MultipleQltyInspectSourceConfig.SetCurrentKey("Sort Order");
        MultipleQltyInspectSourceConfig.Ascending(false);
        MultipleQltyInspectSourceConfig.FindFirst();
        MaxSortOrder := MultipleQltyInspectSourceConfig."Sort Order";

        // [GIVEN] A new source configuration record is initialized with a random code
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(2, SourceConfigCode);
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration record is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(2, SourceConfigCode);
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration is initialized with reversed From/To tables (Prod. Order Routing Line → Prod. Order Line)
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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

        // [GIVEN] A new source configuration record is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration is initialized with Reservation Entry as From Table
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration is initialized with Reservation Entry as To Table
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] To Field No. can be validated to a custom field on test header

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new source configuration with To Type = Test is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Test);
        SpecificQltyInspectSourceConfig.Insert(true);

        // [GIVEN] A source field configuration line is initialized with To Type = Test
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf."Line No." := 10000;
        SpecificQltyInspectSrcFldConf.Validate("To Type", SpecificQltyInspectSrcFldConf."To Type"::Test);

        // [WHEN] To Field No. is validated to Source Custom 1 field
        SpecificQltyInspectSrcFldConf.Validate("To Field No.", QltyInspectionTestHeader.FieldNo("Source Custom 1"));

        // [THEN] To Field No. is successfully set to Source Custom 1
        LibraryAssert.AreEqual(QltyInspectionTestHeader.FieldNo("Source Custom 1"), SpecificQltyInspectSrcFldConf."To Field No.", 'To field should be set.');
    end;

    [Test]
    procedure SourceConfigLineTable_ValidateToType_ConfigMismatch_ShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;

    begin
        // [SCENARIO] Validating To Type throws error when mismatched with parent configuration

        // [GIVEN] A new source configuration with To Type = Test is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Validate("To Type", SpecificQltyInspectSourceConfig."To Type"::Test);
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
    procedure SourceConfigLineTable_ValidateDisplayAs_NotToTest_ShouldError()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SourceConfigCode: Text;
    begin
        // [SCENARIO] Validating Display As throws error when To Type is not Test

        // [GIVEN] A new source configuration with To Type = "Chained table" is created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(20, SourceConfigCode);
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

        // [THEN] An error is thrown indicating Display As can only be set when To Type is Test
        LibraryAssert.ExpectedError(CanOnlyBeSetWhenToTypeIsTestErr);
    end;

    [Test]
    procedure ApplicationAreaMgmt_IsQualityManagementApplicationAreaEnabled()
    var
        AllProfile: Record "All Profile";
        ApplicationAreaSetup: Record "Application Area Setup";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";

    begin
        // [SCENARIO] Quality Management application area is enabled by default

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
