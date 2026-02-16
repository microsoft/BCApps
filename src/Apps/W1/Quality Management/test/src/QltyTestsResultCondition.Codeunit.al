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
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139956 "Qlty. Tests - Result Condition"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        QltyTest: Record "Qlty. Test";
        QltyInspectionResult: Record "Qlty. Inspection Result";
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
        UpdateTemplatesQst: Label 'You have changed default conditions on the test %2, there are %1 template lines with earlier conditions for this result. Do you want to update the templates?', Comment = '%1=the amount of templates that have other conditions, %2=the test name';

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromTestConfirmHandler_True')]
    procedure PromptUpdateTemplatesFromTests_ShouldUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Update template result conditions when test result condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality test with decimal type and initial result condition is created
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Decimal");
        QltyTest.Insert();
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyTest.SetResultCondition(ToLoadQltyInspectionResult.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the test and results are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", QltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');

        // [WHEN] The test result condition is changed and user confirms template update
        QltyTest.SetResultCondition(ToLoadQltyInspectionResult.Code, ChangedConditionTok, true);

        // [THEN] The test result condition is updated to the new value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'New result pass condition should match new values.');

        // [THEN] The template-specific result condition is created with the new value
        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Template);
        ToLoadQltyIResultConditConf.SetRange("Test Code", QltyTest.Code);
        ToLoadQltyIResultConditConf.SetRange("Result Code", DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIResultConditConf.Count(), 'There should be a template-specific result condition.');
        ToLoadQltyIResultConditConf.FindFirst();
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match new pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTemplatesFromTestConfirmHandler_False')]
    procedure PromptUpdateTemplatesFromTests_ShouldNotUpdate()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Do not update template result conditions when test result condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality test with decimal type and initial result condition is created
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Decimal");
        QltyTest.Insert();
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyTest.SetResultCondition(ToLoadQltyInspectionResult.Code, InitialConditionTok, true);

        // [GIVEN] A template line is created with the test and results are ensured
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", QltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');

        // [WHEN] The test result condition is changed and user declines template update
        QltyTest.SetResultCondition(ToLoadQltyInspectionResult.Code, ChangedConditionTok, true);

        // [THEN] The test result condition is updated to the new value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ChangedConditionTok, ToLoadQltyIResultConditConf.Condition, 'New result pass condition should match new values.');

        // [THEN] The template-specific result condition remains with the initial value
        Clear(ToLoadQltyIResultConditConf);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Template);
        ToLoadQltyIResultConditConf.SetRange("Test Code", QltyTest.Code);
        ToLoadQltyIResultConditConf.SetRange("Result Code", DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(1, ToLoadQltyIResultConditConf.Count(), 'There should be a template-specific result condition.');
        ToLoadQltyIResultConditConf.FindFirst();
        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'Result condition should match initial pass condition.');
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_True')]
    procedure PromptUpdateTestsFromResult_UpdateNumberCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Update test result conditions when result default number condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with decimal type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Decimal");
        QltyTest.Insert(true);
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);

        // [GIVEN] The test result condition has the default number condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        // [WHEN] The result default number condition is changed and user confirms test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Number Condition", NewResult2PassConditionNumberTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition is updated with the new condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Number Condition", DefaultResult2PassConditionNumberTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_False')]
    procedure PromptUpdateTestsFromResult_UpdateNumberCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Do not update test result conditions when result default number condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with decimal type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Decimal");
        QltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        // [WHEN] The result default number condition is changed and user declines test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Number Condition", NewResult2PassConditionNumberTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition remains unchanged with the default condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default number condition.');

        QltyInspectionResult.Validate("Default Number Condition", DefaultResult2PassConditionNumberTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_True')]
    procedure PromptUpdateTestsFromResult_UpdateTextCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Update test result conditions when result default text condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with text type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Text");
        QltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        // [WHEN] The result default text condition is changed and user confirms test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Text Condition", NewResult2PassConditionTextTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition is updated with the new text condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Text Condition", DefaultResult2PassConditionTextTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_False')]
    procedure PromptUpdateTestsFromResult_UpdateTextCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Do not update test result conditions when result default text condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with text type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Text");
        QltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        // [WHEN] The result default text condition is changed and user declines test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Text Condition", NewResult2PassConditionTextTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition remains unchanged with the default text condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionTextTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        QltyInspectionResult.Validate("Default Text Condition", DefaultResult2PassConditionTextTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_True')]
    procedure PromptUpdateTestsFromResult_UpdateBooleanCondition_ShouldUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Update test result conditions when result default boolean condition changes and user confirms the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with boolean type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Boolean");
        QltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default boolean condition.');

        // [WHEN] The result default boolean condition is changed and user confirms test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Boolean Condition", NewResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition is updated with the new boolean condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        QltyInspectionResult.Validate("Default Boolean Condition", DefaultResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    [HandlerFunctions('PromptUpdateTestsFromResultConfirmHandler_False')]
    procedure PromptUpdateTestsFromResult_UpdateBooleanCondition_ShouldNotUpdate()
    var
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Do not update test result conditions when result default boolean condition changes and user declines the update

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with boolean type is created and result conditions are copied from default
        Clear(QltyTest);
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Validate("Test Value Type", QltyTest."Test Value Type"::"Value Type Boolean");
        QltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(QltyTest.Code);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default boolean condition.');

        // [WHEN] The result default boolean condition is changed and user declines test update
        QltyInspectionResult.Get(DefaultResult2PassCodeTok);
        QltyInspectionResult.Validate("Default Boolean Condition", NewResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify(true);

        // [THEN] The test result condition remains unchanged with the default boolean condition
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, QltyTest.Code, 0, 0, QltyTest.Code, DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(DefaultResult2PassConditionBooleanTok, ToLoadQltyIResultConditConf.Condition, 'Result condition config should have default text condition.');

        QltyInspectionResult.Validate("Default Boolean Condition", DefaultResult2PassConditionBooleanTok);
        QltyInspectionResult.Modify();
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToTemplateLine()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadSecondQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Copy result conditions from one template line to another template line and verify conditions are copied correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A first quality inspection template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [GIVEN] A quality test with decimal type is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [GIVEN] A template line is created in the first template with custom result condition
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf.Condition := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A second quality inspection template is created with a template line using default result condition
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'The template line result condition should match the new condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadSecondQltyIResultConditConf.Condition, 'The template line result condition should match the default condition.');

        // [WHEN] Result conditions are copied from the first template line to the second template line
        QltyInspectionUtility.CopyResultConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line now has the same result condition as the first template line
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, ToLoadSecondQltyIResultConditConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToTemplateLine_NoExistingConfigLine()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ConfigurationToLoadSecondQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadSecondQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
    begin
        // [SCENARIO] Copy result conditions from one template line to another template line when the destination has no existing config line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A first quality inspection template is created with a custom result condition
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf.Condition := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A second quality inspection template is created without ensuring results
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadSecondQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Init();
        ConfigurationToLoadSecondQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadSecondQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadSecondQltyInspectionTemplateLine.Insert();

        LibraryAssert.AreEqual(InitialConditionTok, ToLoadQltyIResultConditConf.Condition, 'The template line result condition should match the new condition.');

        // [WHEN] Result conditions are copied from the first template line to the second template line
        QltyInspectionUtility.CopyResultConditionsFromTemplateLineToTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, ConfigurationToLoadSecondQltyInspectionTemplateLine);

        // [THEN] The second template line receives the result condition configuration from the first template line
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadSecondQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadSecondQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, ToLoadSecondQltyIResultConditConf.Condition, 'The condition should match the copied template line.');
    end;

    [Test]
    procedure CopyResultConditionsFromDefaultToAllTemplates_WithNewTestConfiguredToCopy()
    var
        ConditionalQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        TestCode: Text;
        BeforeNewResultCountConditions: Integer;
    begin
        // [SCENARIO] Supports issue 5503, allows a scenario of adding a new grade with 'automatically copy' configured after existing grades are and adds those conditions.

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A first quality inspection template is created with a custom grade condition
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf.Condition := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // This is not testing the scenario, this is just validating the preconditions.
        ConditionalQltyInspectionResult.SetRange("Copy Behavior", ConditionalQltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        LibraryAssert.IsTrue(ConditionalQltyInspectionResult.Count() > 0, 'Validating preconditions. There must be n>0 grades that copy for this test to be valid.');
        ToLoadQltyIResultConditConf.SetRecFilter();
        ToLoadQltyIResultConditConf.SetRange("Result Code");
        BeforeNewResultCountConditions := ConditionalQltyInspectionResult.Count();
        LibraryAssert.AreEqual(BeforeNewResultCountConditions, ToLoadQltyIResultConditConf.Count(), 'Validating preconditions. Grade.Count(where copy is on) should equal the grade count for a given template line.');

        // [GIVEN] Another net new grade with a copy behavior.
        ConditionalQltyInspectionResult.Init();
        ConditionalQltyInspectionResult.Code := 'AUTOMATEDTEST';
        ConditionalQltyInspectionResult.Description := 'Automated test.';
        ConditionalQltyInspectionResult."Copy Behavior" := ConditionalQltyInspectionResult."Copy Behavior"::"Automatically copy the result";
        ConditionalQltyInspectionResult.Insert(true);

        // [WHEN] We ask the system to copy the new grades to all templates
        QltyInspectionUtility.CopyGradeConditionsFromDefaultToAllTemplates();

        // [THEN] The grade condition count should now be one higher.
        ConditionalQltyInspectionResult.SetRange("Copy Behavior", ConditionalQltyInspectionResult."Copy Behavior"::"Automatically copy the result");
        LibraryAssert.AreEqual(BeforeNewResultCountConditions + 1, ToLoadQltyIResultConditConf.Count(), 'The grade conditions should have increased by one.');

        // clean up the artifacts
        ToLoadQltyIResultConditConf.Reset();
        ToLoadQltyIResultConditConf.SetRange("Result Code", ConditionalQltyInspectionResult.Code);
        ToLoadQltyIResultConditConf.DeleteAll(false);
        ConditionalQltyInspectionResult.Delete(); // remove the grade.
    end;

    [Test]
    procedure CopyResultConditionsFromTemplateLineToInspection_NoExistingConfigLine()
    var
        Location: Record Location;
        Item: Record Item;
        ToLoadQltyTest: Record "Qlty. Test";
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
        RecordRef: RecordRef;
        UnusedVariant: Code[10];
        TestCode: Text;
    begin
        // [SCENARIO] Copy result conditions from a template line to an inspection when the inspection has no existing config line

        Initialize();

        // [GIVEN] A quality inspection template with a prioritized rule for purchase lines is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [GIVEN] A quality test with decimal type and default result conditions is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();
        QltyInspectionUtility.CopyResultConditionsFromDefaultToTest(ToLoadQltyTest.Code);

        // [GIVEN] A template with a template line is created for the test
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [GIVEN] A purchase order is created and a quality inspection is created from it
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionUtility.CreateInspectionWithPreventDisplaying(RecordRef, true, false, QltyInspectionHeader);

        // [WHEN] Result conditions are copied from the template line to the inspection
        QltyInspectionUtility.CopyResultConditionsFromTemplateToInspection(ConfigurationToLoadQltyInspectionTemplateLine, QltyInspectionLine);

        // [THEN] The inspection receives the result condition configuration with the default value
        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Inspection, QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, ToLoadQltyIResultConditConf.Condition, 'The condition should match the default value.');
    end;

    [Test]
    procedure GetPromotedResultsForTest()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyTest: Record "Qlty. Test";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        TestCode: Text;
    begin
        // [SCENARIO] Get promoted results for a test with custom result condition and verify the result information is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with decimal type and custom result condition is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();
        ToLoadQltyTest.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyTest.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, ToLoadQltyTest.Code, 0, 0, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [WHEN] Promoted results for the test are retrieved
        QltyInspectionUtility.GetPromotedResultsForTest(ToLoadQltyTest, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information matches the test result condition
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf.Condition, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(ToLoadQltyIResultConditConf."Condition Description", MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(ToLoadQltyIResultConditConf."Result Code");
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForTest_Default()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyTest: Record "Qlty. Test";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        TestCode: Text;
    begin
        // [SCENARIO] Get promoted results for a test without custom result condition and verify default result information is returned

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with decimal type and no custom result condition is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [WHEN] Promoted results for the test are retrieved
        QltyInspectionUtility.GetPromotedResultsForTest(ToLoadQltyTest, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
        ToLoadQltyTest: Record "Qlty. Test";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        TestCode: Text;
    begin
        // [SCENARIO] Get promoted results for a template line and verify the result information from the template is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality test with decimal type and custom result condition is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();
        ToLoadQltyTest.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyTest.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, ToLoadQltyTest.Code, 0, 0, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A quality inspection template is created with a template line and results are ensured
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Template, ConfigurationToLoadQltyInspectionTemplateHdr.Code, 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

        // [WHEN] Promoted results for the template line are retrieved
        QltyInspectionUtility.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
        ToLoadQltyTest: Record "Qlty. Test";
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        TestCode: Text;
    begin
        // [SCENARIO] Get default promoted results for a template line when no custom conditions exist

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A decimal type quality test without custom result conditions is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [GIVEN] A quality inspection template with a template line is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted results for the template line are retrieved
        QltyInspectionUtility.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        // [THEN] The returned result information matches the default result condition
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionCellData[1], 'Returned condition should match result condition.');
        LibraryAssert.AreEqual(DefaultResult2PassConditionNumberTok, MatrixConditionDescriptionCellData[1], 'Returned condition should match result condition description.');
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Description, MatrixCaptionSet[1], 'Returned description should match result description');
        LibraryAssert.IsTrue(MatrixVisible[1], 'Each returned record should be visible.');
    end;

    [Test]
    procedure GetPromotedResultsForTemplateLine_NoTest()
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
        // [SCENARIO] Get promoted results for a template line that has no associated test

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template with a template line without a test is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();

        // [WHEN] Promoted results for the template line are retrieved
        QltyInspectionUtility.GetPromotedResultsForTemplateLine(ConfigurationToLoadQltyInspectionTemplateLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
        ToLoadQltyTest: Record "Qlty. Test";
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
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        TestCode: Text;
    begin
        // [SCENARIO] Get promoted results for an inspection line and verify the result information from the inspection is returned correctly

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A decimal type quality test with custom result condition is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();
        ToLoadQltyTest.SetResultCondition(DefaultResult2PassCodeTok, InitialConditionTok, true);
        ToLoadQltyTest.Modify();

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Test, ToLoadQltyTest.Code, 0, 0, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);
        ToLoadQltyIResultConditConf."Condition Description" := InitialConditionTok;
        ToLoadQltyIResultConditConf.Modify();

        // [GIVEN] A quality inspection template with a template line and ensured results is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);

        // [WHEN] Promoted results for the inspection line are retrieved
        QltyInspectionUtility.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

        ToLoadQltyIResultConditConf.Get(ToLoadQltyIResultConditConf."Condition Type"::Inspection, QltyInspectionHeader."No.", 0, 10000, ToLoadQltyTest.Code, DefaultResult2PassCodeTok);

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
        ToLoadQltyTest: Record "Qlty. Test";
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
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        TestCode: Text;
    begin
        // [SCENARIO] Get default promoted results for an inspection line when no custom conditions exist at inspection level

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A decimal type quality test without custom result conditions is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [GIVEN] A quality inspection template with a template line and ensured results is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line");
        ConfigurationToLoadQltyInspectionTemplateLine.Init();
        ConfigurationToLoadQltyInspectionTemplateLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ConfigurationToLoadQltyInspectionTemplateLine.InitLineNoIfNeeded();
        ConfigurationToLoadQltyInspectionTemplateLine.Validate("Test Code", ToLoadQltyTest.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.Insert();
        ConfigurationToLoadQltyInspectionTemplateLine.EnsureResultsExist(false);

        // [GIVEN] A purchase order with item and vendor is created and a quality inspection is created from the purchase line
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        UnusedVariant := '';
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, UnusedVariant, PurOrderPurchaseHeader, PurOrdPurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);

        // [WHEN] Promoted results for the inspection line are retrieved
        QltyInspectionUtility.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        PurOrdPurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        RecID: RecordId;
        RecordRef: RecordRef;
        MatrixSourceRecordId: array[10] of RecordId;
        MatrixConditionCellData: array[10] of Text;
        MatrixConditionDescriptionCellData: array[10] of Text;
        MatrixCaptionSet: array[10] of Text;
        MatrixVisible: array[10] of Boolean;
        UnusedVariant: Code[10];
        TestCode: Text;
    begin
        // [SCENARIO] Get promoted results for an inspection line that has no associated template line

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A decimal type quality test is created
        Clear(ToLoadQltyTest);
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

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
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Test Code" := ToLoadQltyTest.Code;
        QltyInspectionLine.Insert();

        // [WHEN] Promoted results for the inspection line are retrieved
        QltyInspectionUtility.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixConditionCellData, MatrixConditionDescriptionCellData, MatrixCaptionSet, MatrixVisible);

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
    procedure PromptUpdateTemplatesFromTestConfirmHandler_True(Question: Text; var Reply: Boolean)
    begin
        LibraryAssert.AreEqual(StrSubstNo(UpdateTemplatesQst, 1, QltyTest.Code), Question, 'Question should match test and number of template lines.');
        Reply := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateTemplatesFromTestConfirmHandler_False(Question: Text; var Reply: Boolean)
    begin
        LibraryAssert.AreEqual(StrSubstNo(UpdateTemplatesQst, 1, QltyTest.Code), Question, 'Question should match test and number of template lines.');
        Reply := false;
    end;

    [ConfirmHandler]
    procedure PromptUpdateTestsFromResultConfirmHandler_True(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure PromptUpdateTestsFromResultConfirmHandler_False(Question: Text; var Reply: Boolean)
    var
    begin
        Reply := false;
    end;
}
