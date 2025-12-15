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
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139956 "Qlty. Test Grade Condition"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        QltyField: Record "Qlty. Field";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        CondManagementQltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        QltyInspectionsUtility: Codeunit "Qlty. Inspections - Utility";
        LibraryAssert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        DefaultGrade2PassCodeTok: Label 'PASS', Locked = true;
        InitialConditionTok: Label '1..3';
        ChangedConditionTok: Label '2..4';
        DefaultGrade2PassConditionNumberTok: Label '<>0', Locked = true;
        NewGrade2PassConditionNumberTok: Label '<>1';
        DefaultGrade2PassConditionTextTok: Label '<>''''', Locked = true;
        NewGrade2PassConditionTextTok: Label '<>1', Locked = true;
        DefaultGrade2PassConditionBooleanTok: Label 'Yes', Locked = true;
        NewGrade2PassConditionBooleanTok: Label 'No', Locked = true;
        UpdateTemplatesQst: Label 'You have changed default conditions on the field %2, there are %1 template lines with earlier conditions for this grade. Do you want to update the templates?', Comment = '%1=the amount of templates that have other conditions, %2=the field name';

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromFieldConfirmHandler_True')]
    procedure PromptUpdateTemplatesFromFields_ShouldUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update template grade conditions when field grade condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type and initial grade condition is created
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyField.SetGradeCondition(ToLoadQltyInspectionGrade.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the field and grades are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", QltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition should match initial pass condition.');

        // [WHEN] The field grade condition is changed and user confirms template update
        QltyField.SetGradeCondition(ToLoadQltyInspectionGrade.Code, ChangedConditionTok, true);

        // [THEN] The field grade condition is updated to the new value
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'New grade pass condition should match new values.');

        // [THEN] The template-specific grade condition is created with the new value
        Clear(ToLoadQltyIGradeConditionConf);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadQltyIGradeConditionConf.SetRange("Field Code", QltyField.Code);
        ToLoadQltyIGradeConditionConf.SetRange("Grade Code", DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIGradeConditionConf.Count(), 'There should be a template-specific grade condition.');
        ToLoadQltyIGradeConditionConf.FindFirst();
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition should match new pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromFieldConfirmHandler_False')]
    procedure PromptUpdateTemplatesFromFields_ShouldNotUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update template grade conditions when field grade condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type and initial grade condition is created
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyField.SetGradeCondition(ToLoadQltyInspectionGrade.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the field and grades are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", QltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition should match initial pass condition.');

        // [WHEN] The field grade condition is changed and user declines template update
        QltyField.SetGradeCondition(ToLoadQltyInspectionGrade.Code, ChangedConditionTok, true);

        // [THEN] The field grade condition is updated to the new value
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'New grade pass condition should match new values.');

        // [THEN] The template-specific grade condition remains with the initial value
        Clear(ToLoadQltyIGradeConditionConf);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadQltyIGradeConditionConf.SetRange("Field Code", QltyField.Code);
        ToLoadQltyIGradeConditionConf.SetRange("Grade Code", DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIGradeConditionConf.Count(), 'There should be a template-specific grade condition.');
        ToLoadQltyIGradeConditionConf.FindFirst();
        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition should match initial pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_True')]
    procedure PromptUpdateFieldsFromGrade_UpdateNumberCondition_ShouldUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field grade conditions when grade default number condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert(true);
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);

        // [GIVEN] The field grade condition has the default number condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default number condition.');

        // [WHEN] The grade default number condition is changed and user confirms field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Number Condition", NewGrade2PassConditionNumberTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition is updated with the new condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        QltyInspectionGrade.Validate("Default Number Condition", DefaultGrade2PassConditionNumberTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_False')]
    procedure PromptUpdateFieldsFromGrade_UpdateNumberCondition_ShouldNotUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field grade conditions when grade default number condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Decimal");
        QltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default number condition.');

        // [WHEN] The grade default number condition is changed and user declines field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Number Condition", NewGrade2PassConditionNumberTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition remains unchanged with the default condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default number condition.');

        QltyInspectionGrade.Validate("Default Number Condition", DefaultGrade2PassConditionNumberTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_True')]
    procedure PromptUpdateFieldsFromGrade_UpdateTextCondition_ShouldUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field grade conditions when grade default text condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with text type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Text");
        QltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionTextTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default text condition.');

        // [WHEN] The grade default text condition is changed and user confirms field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Text Condition", NewGrade2PassConditionTextTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition is updated with the new text condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        QltyInspectionGrade.Validate("Default Text Condition", DefaultGrade2PassConditionTextTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_False')]
    procedure PromptUpdateFieldsFromGrade_UpdateTextCondition_ShouldNotUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field grade conditions when grade default text condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with text type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Text");
        QltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionTextTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default text condition.');

        // [WHEN] The grade default text condition is changed and user declines field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Text Condition", NewGrade2PassConditionTextTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition remains unchanged with the default text condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(DefaultGrade2PassConditionTextTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default text condition.');

        QltyInspectionGrade.Validate("Default Text Condition", DefaultGrade2PassConditionTextTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_True')]
    procedure PromptUpdateFieldsFromGrade_UpdateBooleanCondition_ShouldUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Update field grade conditions when grade default boolean condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with boolean type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Boolean");
        QltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionBooleanTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default boolean condition.');

        // [WHEN] The grade default boolean condition is changed and user confirms field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Boolean Condition", NewGrade2PassConditionBooleanTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition is updated with the new boolean condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        QltyInspectionGrade.Validate("Default Boolean Condition", DefaultGrade2PassConditionBooleanTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateFieldsFromGradeConfirmHandler_False')]
    procedure PromptUpdateFieldsFromGrade_UpdateBooleanCondition_ShouldNotUpdate()
    var
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Do not update field grade conditions when grade default boolean condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with boolean type is created and grade conditions are copied from default
        Clear(QltyField);
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Validate("Field Type", QltyField."Field Type"::"Field Type Boolean");
        QltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(QltyField.Code);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionBooleanTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default boolean condition.');

        // [WHEN] The grade default boolean condition is changed and user declines field update
        QltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        QltyInspectionGrade.Validate("Default Boolean Condition", NewGrade2PassConditionBooleanTok);
        QltyInspectionGrade.Modify(true);

        // [THEN] The field grade condition remains unchanged with the default boolean condition
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, QltyField.Code, 0, 0, QltyField.Code, DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(DefaultGrade2PassConditionBooleanTok, ToLoadQltyIGradeConditionConf.Condition, 'Grade condition config should have default text condition.');

        QltyInspectionGrade.Validate("Default Boolean Condition", DefaultGrade2PassConditionBooleanTok);
        QltyInspectionGrade.Modify();
    end;

    [Test]
    procedure CopyGradeConditionsFromTemplateLineToTemplateLine()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadSecondQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Copy grade conditions from one template line to another template line and verify conditions are copied correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A first quality inspection template is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality field with decimal type is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A template line is created in the first template with custom grade condition
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadQltyIGradeConditionConf.Condition := InitialConditionTok;
        ToLoadQltyIGradeConditionConf.Modify();

        // [GIVEN] A second quality inspection template is created with a template line using default grade condition
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadSecondQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'The template line grade condition should match the new condition.');
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, ToLoadSecondQltyIGradeConditionConf.Condition, 'The template line grade condition should match the default condition.');

        // [WHEN] Grade conditions are copied from the first template line to the second template line
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line now has the same grade condition as the first template line
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadSecondQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf.Condition, ToLoadSecondQltyIGradeConditionConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyGradeConditionsFromTemplateLineToTemplateLine_NoExistingConfigLine()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadSecondQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        FieldCode: Text;
    begin
        // [SCENARIO] Copy grade conditions from one template line to another template line when the destination has no existing config line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A first quality inspection template is created with a custom grade condition
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadQltyIGradeConditionConf.Condition := InitialConditionTok;
        ToLoadQltyIGradeConditionConf.Modify();

        // [GIVEN] A second quality inspection template is created without ensuring grades
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIGradeConditionConf.Condition, 'The template line grade condition should match the new condition.');

        // [WHEN] Grade conditions are copied from the first template line to the second template line
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line receives the grade condition configuration from the first template line
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadSecondQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf.Condition, ToLoadSecondQltyIGradeConditionConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyGradeConditionsFromTemplateLineToTest_NoExistingConfigLine()
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
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        UnusedVariant: Code[10];
        FieldCode: Text;
    begin
        // [SCENARIO] Copy grade conditions from a template line to a test when the test has no existing config line

        Initialize();

        // [GIVEN] A quality inspection template with a prioritized rule for purchase lines is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [GIVEN] A quality field with decimal type and default grade conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromDefaultToField(ToLoadQltyField.Code);

        // [GIVEN] A template with a template line is created for the field
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
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
        QltyInspectionCreate.SetPreventDisplayingTestEvenIfConfigured(true);
        QltyInspectionCreate.CreateTest(RecordRef, false);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [WHEN] Grade conditions are copied from the template line to the test
        CondManagementQltyGradeConditionMgmt.CopyGradeConditionsFromTemplateToInspection(ConfigurationToLoadQltyInspectionTemplateLine, QltyInspectionLine);

        // [THEN] The test receives the grade condition configuration with the default value
        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Test, QltyInspectionHeader."No.", QltyInspectionHeader."Retest No.", 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, ToLoadQltyIGradeConditionConf.Condition, 'The condition should match the default value.');
    end;

    [Test]
    procedure GetPromotedGradesForField()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted grades for a field with custom grade condition and verify the grade information is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and custom grade condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetGradeCondition(DefaultGrade2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadQltyIGradeConditionConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIGradeConditionConf.Modify();

        // [WHEN] Promoted grades for the field are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForField(ToLoadQltyField, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information matches the field grade condition
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf.Condition, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(ToLoadQltyIGradeConditionConf."Grade Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForField_Default()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted grades for a field without custom grade condition and verify default grade information is returned

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and no custom grade condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [WHEN] Promoted grades for the field are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForField(ToLoadQltyField, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information uses the default grade condition
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTemplateLine()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get promoted grades for a template line and verify the grade information from the template is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality field with decimal type and custom grade condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetGradeCondition(DefaultGrade2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadQltyIGradeConditionConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIGradeConditionConf.Modify();

        // [GIVEN] A quality inspection template is created with a template line and grades are ensured
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);

        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        // [WHEN] Promoted grades for the template line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information matches the template line grade condition
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf.Condition, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(ToLoadQltyIGradeConditionConf."Grade Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTemplateLine_Default()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyField: Record "Qlty. Field";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        FieldCode: Text;
    begin
        // [SCENARIO] Get default promoted grades for a template line when no custom conditions exist

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field without custom grade conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template with a template line is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted grades for the template line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information matches the default grade condition
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTemplateLine_NoField()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
    begin
        // [SCENARIO] Get promoted grades for a template line that has no associated field

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template with a template line without a field is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted grades for the template line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information uses default grade conditions
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTestLine()
    var
        Location: Record Location;
        ToLoadQltyField: Record "Qlty. Field";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
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
        // [SCENARIO] Get promoted grades for a inspection line and verify the grade information from the test is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field with custom grade condition is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();
        ToLoadQltyField.SetGradeCondition(DefaultGrade2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyField.Modify();

        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Field, ToLoadQltyField.Code, 0, 0, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);
        ToLoadQltyIGradeConditionConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIGradeConditionConf.Modify();

        // [GIVEN] A quality inspection template with a template line and ensured grades is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location)
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateTest(RecordRef, false);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Retest No.", 10000);

        // [WHEN] Promoted grades for the inspection line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTestLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        ToLoadQltyIGradeConditionConf.Get(ToLoadQltyIGradeConditionConf."Condition Type"::Test, QltyInspectionHeader."No.", 0, 10000, ToLoadQltyField.Code, DefaultGrade2PassCodeTok);

        // [THEN] The returned grade information matches the test grade condition
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf.Condition, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(ToLoadQltyIGradeConditionConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(ToLoadQltyIGradeConditionConf."Grade Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTestLine_Default()
    var
        Location: Record Location;
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
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
        // [SCENARIO] Get default promoted grades for a inspection line when no custom conditions exist at test level

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field without custom grade conditions is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template with a template line and ensured grades is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Field Code", ToLoadQltyField.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureGrades(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateTest(RecordRef, fan
          QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Retest No.", 10000);

        // [WHEN] Promoted grades for the inspection line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTestLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned grade information uses default grade conditions
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match grade condition.');
        LibraryAssert.AreEqual(DefaultGrade2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match grade condition description.');
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Description, MatrixCaptionSet[1], 'Returned description should match grade description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedGradesForTestLine_NoTemplateLine()
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
        // [SCENARIO] Get promoted grades for a inspection line that has no associated template line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A decimal type quality field is created
        Clear(ToLoadQltyField);
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] A quality inspection template without template lines is created
        QltyInspectionsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created with a manually inserted inspection line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurcha seOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate.CreateTest(Re;
        Q QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        QltyInspectionLine.Init();
        QltyInspectionLine."Test No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Retest No." := QltyInspectionHeader."Retest No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Field Code" := ToLoadQltyField.Code;
        QltyInspectionLine.Insert();

        // [WHEN] Promoted grades for the inspection line are retrieved
        CondManagementQltyGradeConditionMgmt.GetPromotedGradesForTestLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
    procedure PromptUpdateFieldsFromGradeConfirmHandler_True(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateFieldsFromGradeConfirmHandler_False(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := false;
    end;
}
