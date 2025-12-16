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
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        AssistEditTemplateValue: Text;
        ChooseFromLookupValue: Text;
        ChooseFromLookupValueVendorNo: Text;
        AttributeNameToValue: Dictionary of [Text, Text];
        MessageTxt: Text;
        TemplateCodeTok: Label 'TemplateCode', Locked = true;
        GradeCodeTxt: Label 'UNAVAILABLE';
        DefaultTopLeftTok: Label 'Inspection', Locked = true;
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
        FieldTypeErrInfoMsg: Label '%1Consider replacing this field in the template with a new one, or deleting existing inspections (if allowed). The field was last used on inspection %2.', Comment = '%1 = Error Title, %2 = Quality Inspection No.';
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';
        VendorFilterCountryTok: Label 'WHERE(Country/Region Code=FILTER(CA))', Locked = true;
        VendorFilterNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Vendor No.', Locked = true;
        ThereIsNoGradeErr: Label 'There is no grade called "%1". Please add the grade, or change the existing grade conditions.', Comment = '%1=the grade';
        ReviewGradesErr: Label 'Advanced configuration required. Please review the grade configurations for field "%1", for grade "%2".', Comment = '%1=the field, %2=the grade';
        OneDriveIntegrationNotConfiguredErr: Label 'The Quality Management Setup has been configured to upload pictures to OneDrive, however you have not yet configured Business Central to work with . Please configure OneDrive setup with Business Central first before using this feature.', Locked = true;
        FilterMandatoryErr: Label 'It is mandatory that an inspection generation rule have at least one filter defined to help prevent inadvertent over-generation of inspections. Navigate to the Quality Inspection Generation Rules and make sure at least one filter is set for each rule that matches the %1 schedule group.', Comment = '%1=the schedule group';
        ConditionFilterItemNoTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1 = Item No.', Locked = true;
        ConditionFilterAttributeTok: Label '"%1"=Filter(%2)', Comment = '%1 = Attribute Name, %2 = Attribute Value', Locked = true;
        UnableToFindRecordErr: Label 'Unable to show inspections with the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheItemErr: Label 'Unable to identify the item for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheTrackingErr: Label 'Unable to identify the tracking for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheDocumentErr: Label 'Unable to identify the document for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        DefaultGrade2PassCodeTok: Label 'PASS', Locked = true;
        ExpressionFormulaFieldCodeTok: Label '[%1]', Comment = '%1=The first field code', Locked = true;
        TargetErr: Label 'When the target of the source configuration is an inspection, then all target fields must also refer to the inspection. Note that you can chain tables in another source configuration and still target inspection values. For example if you would like to ensure that a field from the Customer is included for a source configuration that is not directly related to a Customer then create another source configuration that links Customer to your record.';
        CanOnlyBeSetWhenToTypeIsInspectionErr: Label 'This is only used when the To Type is an inspection';
        OrderTypeProductionConditionFilterTok: Label 'WHERE(Order Type=FILTER(Production))', Locked = true;
        EntryTypeOutputConditionFilterTok: Label 'WHERE(Entry Type=FILTER(Output))', Locked = true;
        PassFailQuantityInvalidErr: Label 'The %1 and %2 cannot exceed the %3. The %3 is currently exceeded by %4.', Comment = '%1=the passed quantity caption, %2=the failed quantity caption, %3=the source quantity caption, %4=the quantity exceeded';

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Max Rows Field Lookups is set to allow the vendor count
        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := Vendor.Count() + 1;
        QltyManagementSetup.Modify();

        // [GIVEN] A quality field with Field Type "Table Lookup" targeting Vendor table is created
        QltyInspectionUtility.CreateField(ToLoadQltyField, ToLoadQltyField."Field Type"::"Field Type Table Lookup");
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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Changing a field type should error if the field is already used in an existing inspection

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The first inspection line is retrieved
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);

        // [GIVEN] The field used in the inspection line is retrieved
        ToLoadQltyField.Get(QltyInspectionLine."Field Code");

        // [WHEN] Attempting to change the field type to Boolean
        asserterror ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");

        // [THEN] An error is raised indicating the field cannot be changed because it's used in inspection
        LibraryAssert.ExpectedError(StrSubstNo(FieldTypeErrInfoMsg, '', QltyInspectionHeader."No."));
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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCodeTxt);
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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCode);

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
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Text Expression field is created
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
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
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A Boolean field is created
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TemplateCode: Text;
        ScheduleGroupCode: Text;
    begin
        // [SCENARIO] Setting a Schedule Group on a generation rule without filters should error

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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
        QltyInspectionGenRules."Schedule Group".Lookup();
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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Quality Management setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] A inspection header is inserted
        QltyInspectionHeader.Insert();

        // [GIVEN] A inspection line is initialized with header keys and line number
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
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
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        // [SCENARIO] OnDelete trigger removes associated grade condition configurations

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionLine.FindSet(true), 'Sanity check, theres hould be a inspection line.');
        repeat
            QltyInspectionHeader.SetTestValue(QltyInspectionLine."Field Code", '1');
        until QltyInspectionLine.Next() = 0;
        LibraryAssert.IsTrue(QltyInspectionLine.FindSet(true), 'Sanity check, theres hould be a inspection line.');

        Clear(ToLoadQltyIGradeConditionConf);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Inspection);
        ToLoadQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionHeader."No.");
        ToLoadQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionGrade.SetRange("Copy Behavior", QltyInspectionGrade."Copy Behavior"::"Automatically copy the grade");
        LibraryAssert.AreEqual(
            1 * (QltyInspectionGrade.Count() * QltyInspectionLine.Count()),
            ToLoadQltyIGradeConditionConf.Count(),
            'Should be at least one grade condition config per field per grade');

        // [WHEN] The inspection line is deleted
        QltyInspectionLine.Delete(true);

        // [THEN] All associated grade condition configurations are deleted
        Clear(ToLoadQltyIGradeConditionConf);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Inspection);
        ToLoadQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionHeader."No.");
        ToLoadQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionHeader."Reinspection No.");
        ToLoadQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        LibraryAssert.AreEqual(0, ToLoadQltyIGradeConditionConf.Count(), 'Should be no grade condition config lines for the inspection line.');
        ToLoadQltyIGradeConditionConf.SetRange("Target Line No.");
        QltyInspectionHeader.Delete(true);
        LibraryAssert.AreEqual(0, ToLoadQltyIGradeConditionConf.Count(), 'Should be no grade condition config lines for the inspection.');
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

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] The inspection line is retrieved and the inspection subform page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
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
        ToLoadQltyField: Record "Qlty. Field";
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

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Field Type Option field having allowable values
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, ToLoadQltyField, ToLoadQltyField."Field Type"::"Field Type Option");
        ToLoadQltyField."Allowable Values" := OptionsTok;
        ToLoadQltyField.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspection.Lines."Test Value".AssistEdit();
        QltyInspection.Close();

        // [THEN] The Test Value is set to the selected option from the list
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
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
        LookupQltyField: Record "Qlty. Field";
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

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created with a Field Type Table Lookup field configured for Location table
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQltyField, LookupQltyField."Field Type"::"Field Type Table Lookup");
        LookupQltyField."Lookup Table No." := Database::Location;
        LookupQltyField."Lookup Field No." := Location.FieldNo(Code);
        LookupQltyField.Modify();

        // [GIVEN] A purchase order is created, released, and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [GIVEN] A location code is prepared for selection via modal handler
        ChooseFromLookupValue := Location.Code;

        // [WHEN] AssistEdit is invoked on the Test Value field
        QltyInspection.Lines."Test Value".AssistEdit();
        QltyInspection.Close();

        // [THEN] The Test Value is set to the selected location code from the lookup
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
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
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] Updating a text field value automatically updates dependent text expression fields

        // [GIVEN] Setup exists, a full WMS location is created, and an item is created
        QltyInspectionUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A text field is added to the template
        QltyInspectionUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextQltyField, TextQltyField."Field Type"::"Field Type Text");

        // [GIVEN] A text expression field is added to the template
        QltyInspectionUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, TextExpressionQltyField, TextExpressionQltyField."Field Type"::"Field Type Text Expression");

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

        // [GIVEN] A generation rule is created and an inspection is created from the purchase line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] The inspection line for the text field is retrieved and the inspection page is opened
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);
        QltyInspection.Lines.GoToRecord(QltyInspectionLine);

        // [WHEN] The Test Value is set to 'test' on the text field
        QltyInspection.Lines."Test Value".SetValue('test');
        QltyInspection.Close();

        // [THEN] The text field's Test Value is set to 'test'
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
        LibraryAssert.AreEqual('test', QltyInspectionLine."Test Value", 'Test value should be set.');

        // [THEN] The text expression field's Test Value is also automatically set to 'test'
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 20000);
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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetup();

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
