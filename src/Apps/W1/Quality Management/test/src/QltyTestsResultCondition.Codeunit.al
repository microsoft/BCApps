// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139956 "Qlty. Tests - Result Condition"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        QltyField: Record "Qlty. Field";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        CondManagementQltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LibraryAssert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        DefaultResult2PassCodeTok: Label 'PASS', Locked = true;
        InitialConditionTok: Label '1..3';
        ChangedConditionTok: Label '2..4';
        DefaultResult2PassConditionNumberTok: Label '<>0', Locked = true;
        NewResult2PassConditionNumberTok: Label '<>1';
        DefaultResult2PassConditionTextTok: Label '<>''''', Locked = true;
        NewResult2PassConditionTextTok: Label '<>1', Locked = true;
        DefaultResult2PassConditionBooleanTok: Label 'Yes', Locked = true;
        NewResult2PassConditionBooleanTok: Label 'No', Locked = true;
        UpdateTemplatesQst: Label 'You have changed default conditions on the field %2, there are %1 template lines with earlier conditions for this result. Do you want to update the templates?', Comment = '%1=the amount of templates that have other conditions, %2=the field name';

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromFieldConfirmHandler_True')]
    procedure PromptUpdateTemplatesFromFields_ShouldUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update template result conditions when field result condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type and initial result condition is created
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyField.SetResultCondition(ToLoadQltyInspectionResult.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the field and results are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", QltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');

        // [WHEN] The field result condition is changed and user confirms template update
        QltyField.SetResultCondition(ToLoadQltyInspectionResult.Code, ChangedConditionTok, true);

        // [THEN] The field result condition is updated to the new value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'New result pass condition should match new values.');

        // [THEN] The template-specific result condition is created with the new value
        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Template);
        ToLoadQltyIResultConditConf.SetRange("Field Code", QltyField.Code);
        ToLoadQltyIResultConditConf.SetRange("Result Code", DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIResultConditConf.Count(), 'There should be a template-specific result condition.');
        ToLoadQltyIResultConditConf.FindFirst();
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match new pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromFieldConfirmHandler_False')]
    procedure PromptUpdateTemplatesFromFields_ShouldNotUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update template result conditions when field result condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type and initial result condition is created
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyField.SetResultCondition(ToLoadQltyInspectionResult.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the field and results are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", QltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');

        // [WHEN] The field result condition is changed and user declines template update
        QltyField.SetResultCondition(ToLoadQltyInspectionResult.Code, ChangedConditionTok, true);

        // [THEN] The field result condition is updated to the new value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'New result pass condition should match new values.');

        // [THEN] The template-specific result condition remains with the initial value
        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Template);
        ToLoadQltyIResultConditConf.SetRange("Field Code", QltyField.Code);
        ToLoadQltyIResultConditConf.SetRange("Result Code", DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIResultConditConf.Count(), 'There should be a template-specific result condition.');
        ToLoadQltyIResultConditConf.FindFirst();
        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_True')]
    procedure PromptUpdateFieldsFromResult_UpdateNumberCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field result conditions when result default number condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert(true);
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);

        // [GIVEN] The field result condition has the default number condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        // [WHEN] The result default number condition is changed and user confirms field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Number Condition", NewResult2PassConditionNumberTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition is updated with the new condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Number Condition", DefaultResult2PassConditionNumberTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_False')]
    procedure PromptUpdateFieldsFromResult_UpdateNumberCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field result conditions when result default number condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        // [WHEN] The result default number condition is changed and user declines field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Number Condition", NewResult2PassConditionNumberTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition remains unchanged with the default condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        QltyInspectionResult.Validate("Default Number Condition", DefaultResult2PassConditionNumberTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_True')]
    procedure PromptUpdateFieldsFromResult_UpdateTextCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field result conditions when result default text condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with text type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Text");
        QltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        // [WHEN] The result default text condition is changed and user confirms field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Text Condition", NewResult2PassConditionTextTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition is updated with the new text condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Text Condition", DefaultResult2PassConditionTextTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_False')]
    procedure PromptUpdateFieldsFromResult_UpdateTextCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field result conditions when result default text condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with text type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Text");
        QltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        // [WHEN] The result default text condition is changed and user declines field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Text Condition", NewResult2PassConditionTextTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition remains unchanged with the default text condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        QltyInspectionResult.Validate("Default Text Condition", DefaultResult2PassConditionTextTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_True')]
    procedure PromptUpdateFieldsFromResult_UpdateBooleanCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field result conditions when result default boolean condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with boolean type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Boolean");
        QltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default boolean condition.');

        // [WHEN] The result default boolean condition is changed and user confirms field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Boolean Condition", NewResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition is updated with the new boolean condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Boolean Condition", DefaultResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromResultConfirmHandler_False')]
    procedure PromptUpdateFieldsFromResult_UpdateBooleanCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field result conditions when result default boolean condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with boolean type is created and result conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Boolean");
        QltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default boolean condition.');

        // [WHEN] The result default boolean condition is changed and user declines field update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Boolean Condition", NewResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The field result condition remains unchanged with the default boolean condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        QltyInspectionResult.Validate("Default Boolean Condition", DefaultResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToTemplateLine()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadSecondQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Copy result conditions from one template line to another template line and verify conditions are copied correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A first quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A template line is created in the first template with custom result condition
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf.Condition := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A second quality inspection template is created with a template line using default result condition
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.EnsureResults(false);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'The template line result condition should match the new condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadSecondQltyIResultConditConf.Condition, 'The template line result condition should match the default condition.');

        // [WHEN] Result conditions are copied from the first template line to the second template line
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line now has the same result condition as the first template line
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, ToLoadSecondQltyIResultConditConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToTemplateLine_NoExistingConfigLine()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadSecondQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Copy result conditions from one template line to another template line when the destination has no existing config line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A first quality inspection template is created with a custom result condition
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf.Condition := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A second quality inspection template is created without ensuring results
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'The template line result condition should match the new condition.');

        // [WHEN] Result conditions are copied from the first template line to the second template line
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line receives the result condition configuration from the first template line
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, ToLoadSecondQltyIResultConditConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToInspection_NoExistingConfigLine()
    var
        Location: Record Location;
        Item: Record Item;
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        UnusedVariant: Code[10];
        FieldCode: Text;
    begin
        // [SCENARIO] Copy result conditions from a template line to an inspection when the inspection has no existing config line

        Initialize();

        // [GIVEN] A quality inspection template with a prioritized rule for purchase lines is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [GIVEN] A quality field with decimal type and default result conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromDefaultToField(ToLoadQltyField.Code);

        // [GIVEN] A template with a template line is created for the field
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [GIVEN] A purchase order is created and a quality inspection is created from it
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(true);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);

        // [WHEN] Result conditions are copied from the template line to the inspection
        CondManagementQltyResultConditionMgmt.CopyResultConditionsFromTemplateToInspection(ConfigurationToLoadQltyInspectionTemplateLine, QltyInspectionLine);

        // [THEN] The inspection receives the result condition configuration with the default value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Inspection, QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'The condition should match the default value.');
    end;

    [Test]
    procedure GetPromotedResultsForField()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted results for a field with custom result condition and verify the result information is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and custom result condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [WHEN] Promoted results for the field are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForField(ToLoadQltyField, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information matches the field result condition
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(ToLoadQltyIResultConditConf."Result Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForField_Default()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted results for a field without custom result condition and verify default result information is returned

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and no custom result condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [WHEN] Promoted results for the field are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForField(ToLoadQltyField, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information uses the default result condition
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForTemplateLine()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted results for a template line and verify the result information from the template is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and custom result condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A quality inspection template is created with a template line and results are ensured
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        // [WHEN] Promoted results for the template line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information matches the template line result condition
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(ToLoadQltyIResultConditConf."Result Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForTemplateLine_Default()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get default promoted results for a template line when no custom conditions exist

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field without custom result conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template with a template line is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted results for the template line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information matches the default result condition
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForTemplateLine_NoField()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
    begin
        // [SCENARIO] Get promoted results for a template line that has no associated field

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A quality inspection template with a template line without a field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted results for the template line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information uses default result conditions
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForInspectionLine()
    var
        Location: Record Location;
        ToLoadQltyField: Record "Qlty. Field";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted results for an inspection line and verify the result information from the inspection is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field with custom result condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A quality inspection template with a template line and ensured results is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);

        // [WHEN] Promoted results for the inspection line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Inspection, QltyInspectionHeader."No.", 0, 10000, ToLoadQltyField.Code, DefaultResult2PassCodeTok);

        // [THEN] The returned result information matches the inspection result condition
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(ToLoadQltyIResultConditConf."Result Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForInspectionLine_Default()
    var
        Location: Record Location;
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        FieldCode: Text;
    begin
        // [SCENARIO] Get default promoted results for an inspection line when no custom conditions exist at inspection level

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field without custom result conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template with a template line and ensured results is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResults(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);

        // [WHEN] Promoted results for the inspection line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information uses default result conditions
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForInspectionLine_NoTemplateLine()
    var
        Location: Record Location;
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecID: RecordId;
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted results for an inspection line that has no associated template line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template without template lines is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created with a manually inserted inspection line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Field Code" := ToLoadQltyField.Code;
        QltyInspectionLine.Insert();

        // [WHEN] Promoted results for the inspection line are retrieved
        CondManagementQltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned arrays are empty and visibility is false
        LibraryAssert.IsTrue(MatrixSourceRecordId[1] = RecID, 'Should be no array elements.');
        LibraryAssert.IsTrue(MatrixConditionCellData[1] = '', 'Should be no array elements.');
        LibraryAssert.IsTrue(MatrixConditionDescriptionCellData[1] = '', 'Should be no array elements.');
        LibraryAssert.IsTrue(MatrixCaptionSet[1] = '', 'Should be no array elements.');
        LibraryAssert.IsTrue(MatrixVisible[1] = false, 'Should be no array elements.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateTemplatesFromFieldConfirmHandler_True(Question: Text; var Reply: Boolean)
    begin
        LibraryAssert.AreEqual(StrSubstNo(UpdateTemplatesQst, 1, QltyField.Code), Question, 'Question should match field and number of template lines.');
        Reply := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateTemplatesFromFieldConfirmHandler_False(Question: Text; var Reply: Boolean)
    begin
        LibraryAssert.AreEqual(StrSubstNo(UpdateTemplatesQst, 1, QltyField.Code), Question, 'Question should match field and number of template lines.');
        Reply := false;
    end;

    [ConfirmHandler]
    procedure PromptUpdateFieldsFromResultConfirmHandler_True(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateFieldsFromResultConfirmHandler_False(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := false;
    end;
}
