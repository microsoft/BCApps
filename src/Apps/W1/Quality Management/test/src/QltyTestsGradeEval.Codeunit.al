// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 139963 "Qlty. Tests - Grade Eval."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = UnitTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        InfoForDateFailureSuffixLbl: Label ' LocaleId=%1, LanguageId=%2, TimeZone=%3, TimeZoneOffset=%4', Comment = '%1=LocaleId, %2=LanguageId, %3=TimeZone, %4=Offset';
        Expected1Err: Label 'The value "7.0001" can''t be evaluated into type Integer';
        Expected2Err: Label 'The value "7.0001" is not allowed for %1, it is not a Integer.', Comment = '%1=the field code.';
        Expected3Err: Label 'The value "-1" is not allowed for %1, it must be in the range of "0..12345"', Comment = '%1=the identifier.';
        Expected4Err: Label 'The value "F" is not allowed for %1, it must be in the range of "A,B,C,D,E".', Comment = '%1=the identifier.';

    procedure GetRegionalDecimalSeparator(): Text
    begin
        exit(Format(1.1) [2]);
    end;

    procedure GetRegionalThousandsSeparator(): Text
    begin
        exit(Format(1234) [2]);
    end;

    procedure GetDateSeparator(): Text
    var
        Date: Text;
    begin
        Date := Format(DMY2Date(11, 11, 2024), 0, 1);
        exit(Date[3]);
    end;

    procedure IsDayMonthYearLocal(): Boolean
    begin
        exit(CopyStr(Format(DMY2Date(11, 10, 2024), 0, 1), 1, 2) = '11');
    end;

    [Test]
    procedure ValueDecimal()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text;
    begin
        // [SCENARIO] Validate decimal value testing with various conditions including blank values, ranges, exact matches, and comparison operators

        // [GIVEN] A grade evaluation codeunit instance
        // [WHEN] Testing blank and zero values with different allowable ranges
        // [THEN] Blank values pass with blank allowable ranges but fail with numerical ranges, and zero passes within its valid range
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal('', ''), 'blank string with blank allowable');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal('', '0..1'), 'blank string with numerical range.');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal('0', '0..1'), 'zero numerical range.');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal('0', '-100..100'), 'zero numerical range-extended.');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal('', '-100..100'), 'blank numerical range-extended.');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal('0', ''), 'zero with blank range.');

        // [WHEN] Testing decimal value '3' with various conditions
        TestValue := '3';
        // [THEN] Value passes exact match, range, and comparison validations correctly
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, ''), 'Decimal basic no condition');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '3'), 'Decimal basic exact');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '000000000000000'), 'Decimal basic exact lots of precision');

        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '2' + GetRegionalDecimalSeparator() + '99999'), 'Decimal basic almost 3 under');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '00001'), 'Decimal basic almost 3 over');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '2'), 'Decimal basic not 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '<>0'), 'Decimal basic not zero');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '<>'''''), 'Decimal basic not zero, demo person special');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '>0'), 'Decimal basic more than zero');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '<=3'), 'Decimal basic lteq 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '>=3'), 'Decimal basic gteq 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '<4'), 'Decimal basic lt 4');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '>2' + GetRegionalDecimalSeparator() + '9999'), 'Decimal basic gt 2');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '2..4'), 'Decimal basic range');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '3..3'), 'Decimal basic range');

        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '-100..2' + GetRegionalDecimalSeparator() + '9'), 'Decimal basic range less');

        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '0001..100'), 'Decimal basic range more');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDecimal(TestValue, '1|2|3|4'), 'Decimal basic range list');

        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDecimal(TestValue, '1|2|4'), 'Decimal basic range list');
    end;

    [Test]
    procedure ValueInteger()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text;
    begin
        // [SCENARIO] Validate integer value testing with various conditions including exact matches, ranges, comparisons, and lists

        // [GIVEN] An integer test value of '3'
        TestValue := '3';

        // [WHEN] Testing the integer value against various conditions
        // [THEN] The value passes validation for exact matches, ranges, comparisons, and list inclusions
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, ''), 'Integer basic no condition');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger('', ''), 'Integer basic blank.');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '3'), 'Integer basic exact');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueInteger(TestValue, '2'), 'Integer basic not 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '<>0'), 'Integer basic not zero');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '>0'), 'Integer basic more than zero');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '<=3'), 'Integer basic lteq 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '>=3'), 'Integer basic gteq 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '<4'), 'Integer basic lt 4');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '>2'), 'Integer basic gt 2');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '2..4'), 'Integer basic range');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '3..3'), 'Integer basic range');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueInteger(TestValue, '-100..2'), 'Integer basic range less');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueInteger(TestValue, '4..100'), 'Integer basic range more');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueInteger(TestValue, '1|2|3|4'), 'Integer list');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueInteger(TestValue, '1|2|4'), 'Integer list missing');
    end;

    [Test]
    procedure ValueString()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text;
        CaseOption: Enum "Qlty. Case Sensitivity";
        DatabaseIsCaseSensitive: Boolean;
    begin
        // [SCENARIO] Validate string value testing with exact matches, wildcards, and case sensitivity options

        // [GIVEN] A string test value
        TestValue := '3';

        // [WHEN] Testing string values with various conditions including wildcards and case sensitivity
        // [THEN] Values pass validation for exact matches, wildcard patterns, and respect case sensitivity settings
        DatabaseIsCaseSensitive := IsDatabaseCaseSensitive();
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString(TestValue, ''), 'String basic no condition');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString(TestValue, '3'), 'String basic exact');
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueString(TestValue, '2'), 'String basic not 3');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString(TestValue, '<>0'), 'String basic not zero');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString(TestValue, '<>'''''), 'String basic not blank');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('abcdefg', '*b*'), 'String basic wildcard 1');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('abcdefg', '*g'), 'String basic wildcard 2');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'caseSensitive'), 'String case sensitive 1');
        if DatabaseIsCaseSensitive then begin
            LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive'), 'String case sensitive 2');
            LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueString('caseSensitive', 'CaseSensitive'), 'String case sensitive 3');
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive', CaseOption::Insensitive), 'String case sensitive 4');
            LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive', CaseOption::Sensitive), 'String case sensitive 5');
        end else begin
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive'), 'String case sensitive 2');
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'CaseSensitive'), 'String case sensitive 3');
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive', CaseOption::Insensitive), 'String case sensitive 4');
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('caseSensitive', 'casesensitive', CaseOption::Sensitive), 'String case sensitive 5');
        end;
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('wildCardSearch', '*ard*'), 'String wildcard 1');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueString('wildCardSearch', 'wild*'), 'String wildcard 2');
    end;

    [TryFunction]
    procedure Try_TestValueDateIntentionallyBad()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text[250];
    begin
        TestValue := 'not a date';
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDate(TestValue, '', false), 'Date basic not a date 1');
    end;

    [TryFunction]
    procedure Try_TestValueDateTimeIntentionallyBad()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text[250];
    begin
        TestValue := 'not a datetime';
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDateTime(TestValue, '', false), 'Datetime basic not a date time 1');
    end;

    [Test]
    procedure ValueDate()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TestValue: Text[250];
        Date: Date;
        PredictableDate: Date;
        Year: Integer;
        YearAsString: Text;
        OriginalTestValue: Text[250];
    begin
        // [SCENARIO] Validate date value testing with various formats, date ranges, comparisons, and regional settings

        // [GIVEN] Current year and a predictable date for testing
        Year := Date2DMY(WorkDate(), 3);
        YearAsString := format(Year, 0, 9);
        PredictableDate := DMY2Date(28, 2, 2004);

        // [WHEN] Testing invalid date strings
        // [THEN] Invalid date strings fail validation
        LibraryAssert.IsFalse(Try_TestValueDateIntentionallyBad(), 'should have failed with not a date');

        if IsDayMonthYearLocal() then
            TestValue := '28' + GetDateSeparator() + '1' + GetDateSeparator() + YearAsString
        else
            TestValue := '1' + GetDateSeparator() + '28' + GetDateSeparator() + YearAsString;
        Date := DMY2Date(28, 1, Year);
        OriginalTestValue := TestValue;

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '', false),
            'Date basic no condition 2');
        if IsDayMonthYearLocal() then
            LibraryAssert.AreNotEqual(TestValue, format(Date, 0, '<Day,2>' + GetDateSeparator() + '<Month,2>' + GetDateSeparator() + '<Year>'), 'Back and forth date - no change')
        else
            LibraryAssert.AreNotEqual(TestValue, format(Date, 0, '<Month,2>' + GetDateSeparator() + '<Day,2>' + GetDateSeparator() + '<Year>'), 'Back and forth date - no change');

        TestValue := OriginalTestValue;
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '', true), 'Date basic no condition 1');
        LibraryAssert.AreEqual(TestValue, format(Date, 0, '<Year4>-<Month,2>-<Day,2>'), 'Back and forth date - should change');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '1' + GetDateSeparator() + '1..2' + GetDateSeparator() + '2', false), 'Date basic date range 1');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, StrSubstNo('1' + GetDateSeparator() + '1' + GetDateSeparator() + '%1..2' + GetDateSeparator() + '2' + GetDateSeparator() + '%1', YearAsString), false), 'Date basic date range 2');
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, StrSubstNo('>1' + GetDateSeparator() + '1' + GetDateSeparator() + '%1', YearAsString), false), 'Date basic date range 3');

        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, StrSubstNo('<=%1', format(Date)), false), 'Date basic date range 4');
        if IsDayMonthYearLocal() then begin
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '28' + GetDateSeparator() + '1', false),
                'Date basic NO CONVERT');
            LibraryAssert.AreNotEqual('28-1' + YearAsString, TestValue, 'date basic NO CONVERT');

            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '28-1', true), 'Date basic convert');
        end else begin
            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '1' + GetDateSeparator() + '28', false), 'Date basic NO CONVERT');
            LibraryAssert.AreNotEqual('1/28/' + YearAsString, TestValue, 'date basic NO CONVERT');

            LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '1/28', true), 'Date basic convert');
        end;

        LibraryAssert.AreEqual(YearAsString + '-01-28', TestValue, 'date basic convert 1');

        TestValue := '2023-12-31';
        Date := DMY2Date(31, 12, 2023);
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, '', true), 'Date universal date value');

        TestValue := format(PredictableDate, 0, 9);
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDate(TestValue, TestValue, true), 'expected value matches expected date.');

        TestValue := format(PredictableDate, 0, 9);
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDate(TestValue, '<>' + TestValue, true), 'expected value matches anything but the expected date.');

        TestValue := '';
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDate(TestValue, format(PredictableDate, 0, 9), true), 'blank input date with valid acceptable date');
    end;

    [Test]
    procedure ValueDateTime()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
        TestValue: Text[250];
        Date: DateTime;
        OriginalTestValue: Text[250];
        LocaleFinder: SessionSettings;
        DateFailureSuffixDetails: Text;
    begin
        // [SCENARIO] Validate datetime value testing with timezone adjustments, date ranges, comparisons, and exact matches

        // [GIVEN] Timezone information and regional settings are retrieved for diagnostic purposes
        TypeHelper.GetUserTimezoneOffset(TimezoneOffset);
        DateFailureSuffixDetails := StrSubstNo(InfoForDateFailureSuffixLbl, LocaleFinder.LocaleId, LocaleFinder.LanguageId, LocaleFinder.TimeZone, TimezoneOffset);

        // [GIVEN] A datetime value is created for January 28, 2004 at 01:02:03
        // [WHEN] Testing invalid datetime format
        // [THEN] Invalid datetime fails validation
        LibraryAssert.IsFalse(Try_TestValueDateTimeIntentionallyBad(), 'should have failed with not a date' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime without timezone adjustment
        Date := CreateDateTime(DMY2Date(28, 1, 2004), 010203T);
        TestValue := format(Date, 0, 9);
        OriginalTestValue := TestValue;
        // [THEN] Datetime passes validation and value remains unchanged
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDateTime(TestValue, '', false), 'Datetime basic do not adjust' + DateFailureSuffixDetails);
        LibraryAssert.AreEqual(OriginalTestValue, TestValue, 'test value should not have changed for datetime ' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime with timezone adjustment
        TestValue := OriginalTestValue;
        // [THEN] Datetime passes validation and converts correctly
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDateTime(TestValue, '', true), 'Date basic with adjustment of datetime' + DateFailureSuffixDetails);
        LibraryAssert.AreEqual(TestValue, format(Date, 0, 9), 'back and forth datetime.' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime within valid date range without adjustment
        // [THEN] Datetime within range passes validation
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 1, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 1, 2004), 235900T)), false),
                'Datetime basic date range jan to feb no adjustment ' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime outside valid date range
        // [THEN] Datetime outside range fails validation
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 2, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 3, 2004), 235900T)), false),
                'Datetime outside of date range basic date range jan to feb' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime within valid date range with adjustment
        // [THEN] Datetime passes validation with timezone adjustment
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 1, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 1, 2004), 235900T)), true),
                'Datetime basic date range jan to feb with adjustment ' + DateFailureSuffixDetails);

        // [WHEN] Testing exact datetime match
        TestValue := format(Date, 0, 9);
        // [THEN] Exact match passes validation
        LibraryAssert.IsTrue(QltyGradeEvaluation.TestValueDateTime(TestValue, TestValue, true), 'expected value matches expected date.' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime with not-equal condition
        TestValue := format(Date, 0, 9);
        // [THEN] Not-equal condition fails when values match
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDateTime(TestValue, '<>' + TestValue, true), 'expected value matches anything but the expected date.' + DateFailureSuffixDetails);

        // [WHEN] Testing blank datetime against valid acceptable date
        TestValue := '';
        // [THEN] Blank datetime fails validation
        LibraryAssert.IsFalse(QltyGradeEvaluation.TestValueDateTime(TestValue, format(Date, 0, 9), true), 'blank input date with valid acceptable date' + DateFailureSuffixDetails);
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Decimal()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for decimal field with optional inspection line-specific grade conditions overriding template conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyField."Field Type"::"Field Type Decimal", NumericalMeasureQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Field-level grade condition is set to 4..5 for PASS grade
        NumericalMeasureQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '4..5', true);

        // [GIVEN] Template-level grade condition is modified to 6..7 for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] FAIL grade condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", NumericalMeasureQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual(
            'INPROGRESS',
            QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '', NumericalMeasureQltyField."Case Sensitive"),
            'blank value');

        // [THEN] Value at minimum of range (6) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '6', NumericalMeasureQltyField."Case Sensitive"),
            'min value inspection line grade');
        // [THEN] Value slightly exceeding maximum (7.0001) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '7.0001', NumericalMeasureQltyField."Case Sensitive"),
            'slightly exceeding max inspection line grade');
        // [THEN] Value slightly below minimum (5.999999) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '5.999999', NumericalMeasureQltyField."Case Sensitive"),
            'slightly before min inspection line grade');

        // [THEN] Value slightly below maximum (6.999999) evaluates to PASS
        LibraryAssert.AreEqual(
           'PASS',
           QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '6.999999', NumericalMeasureQltyField."Case Sensitive"),
           'slightly before min inspection line grade');

        // [THEN] Blank value is not treated as zero and evaluates to INPROGRESS
        LibraryAssert.AreEqual(
            'INPROGRESS',
            QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '', NumericalMeasureQltyField."Case Sensitive"),
            'ensure that blank is not treated as a zero - decimal.');

        // [THEN] Zero value is not treated as blank and evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '0.0', NumericalMeasureQltyField."Case Sensitive"),
            'ensure that zero is not treated as a blank - decimal');
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_DateTime()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateTimeQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for datetime field with optional inspection line-specific grade conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a datetime field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, DateTimeQltyField."Field Type"::"Field Type DateTime", DateTimeQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Field-level grade condition is set to '2001-02-03 01:02:03' for PASS grade
        DateTimeQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '2001-02-03 01:02:03', true);

        // [GIVEN] Template-level grade condition is modified to '2004-05-06 01:02:03' for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '2004-05-06 01:02:03');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", DateTimeQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateTimeQltyField."Field Type", '', DateTimeQltyField."Case Sensitive"), 'blank value');

        // [THEN] Exact datetime match evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateTimeQltyField."Field Type", '2004-05-06 01:02:03', DateTimeQltyField."Case Sensitive"), 'exact value pass');
        // [THEN] Datetime one second past expected evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateTimeQltyField."Field Type", '2004-05-06 01:02:04', DateTimeQltyField."Case Sensitive"), 'slightly exceeding max inspection line grade');
        // [THEN] Field-level condition datetime is ignored (FAIL not PASS)
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateTimeQltyField."Field Type", '2001-02-03 01:02:03', DateTimeQltyField."Case Sensitive"), 'should have ignored the default field pass condition.');
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Date()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for date field with optional inspection line-specific grade conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a date field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, DateQltyField."Field Type"::"Field Type Date", DateQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Field-level grade condition is set to '2001-02-03' for PASS grade
        DateQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '2001-02-03', true);
        // [GIVEN] Template-level grade condition is modified to '2004-05-06' for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '2004-05-06');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", DateQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateQltyField."Field Type", '', DateQltyField."Case Sensitive"), 'blank value');

        // [THEN] Exact date match evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateQltyField."Field Type", '2004-05-06', DateQltyField."Case Sensitive"), 'exact value pass');
        // [THEN] Date one day past expected evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateQltyField."Field Type", '2004-05-07', DateQltyField."Case Sensitive"), 'slightly exceeding max inspection line grade');
        // [THEN] Field-level condition date is ignored (FAIL not PASS)
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, DateQltyField."Field Type", '2001-02-03', DateQltyField."Case Sensitive"), 'should have ignored the default field pass condition.');
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Boolean()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        BooleanQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for boolean field with template-level condition requiring 'Yes' value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a boolean field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyField."Field Type"::"Field Type Boolean", BooleanQltyField, QltyInspectionTemplateLine);
        // [GIVEN] Template-level grade condition is set to 'Yes' for PASS grade
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, 'Yes');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", BooleanQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", '', BooleanQltyField."Case Sensitive"), 'blank value');
        // [THEN] Value 'Yes' evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", 'Yes', BooleanQltyField."Case Sensitive"), 'exact value pass');
        // [THEN] Value 'On' (alternative true value) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", 'On', BooleanQltyField."Case Sensitive"), 'different kind of yes');
        // [THEN] Value 'No' evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", 'No', BooleanQltyField."Case Sensitive"), 'Direct No.');
        // [THEN] Value 'False' (alternative false value) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", 'False', BooleanQltyField."Case Sensitive"), 'different kind of no.');
        // [THEN] Invalid boolean value evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, BooleanQltyField."Field Type", 'this is not a boolean', BooleanQltyField."Case Sensitive"), 'not a boolean');
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Label()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        LabelQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for label field type which should always return blank grade regardless of value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a label field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, LabelQltyField."Field Type"::"Field Type Label", LabelQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Inspection generation rules are cleared and prioritized rule is created
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", LabelQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Blank value returns blank grade (labels are not graded)
        LibraryAssert.AreEqual('', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, LabelQltyField."Field Type", '', LabelQltyField."Case Sensitive"), 'blank value should result in a blank grade for labels.');

        // [THEN] Any value returns blank grade (labels are not graded)
        LibraryAssert.AreEqual('', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, LabelQltyField."Field Type", 'anything at all is ignored.', LabelQltyField."Case Sensitive"), 'with a label, it is always a blank grade.');
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Integer()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade for integer field with template-level grade conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyField."Field Type"::"Field Type Integer", NumericalMeasureQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Field-level grade condition is set to 4..5 for PASS grade
        NumericalMeasureQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '4..5', true);

        // [GIVEN] Template-level grade condition is modified to 6..7 for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] FAIL grade condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", NumericalMeasureQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '', NumericalMeasureQltyField."Case Sensitive"), 'blank value');
        // [THEN] Value 6 (minimum of range) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '6', NumericalMeasureQltyField."Case Sensitive"), 'min value inspection line grade');
        // [THEN] Value 7 (maximum of range) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '7', NumericalMeasureQltyField."Case Sensitive"), 'max value inspection line grade');
        // [THEN] Value 8 (exceeding maximum) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '8', NumericalMeasureQltyField."Case Sensitive"), 'slightly exceeding max inspection line grade');
        // [THEN] Value 5 (below minimum) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '5', NumericalMeasureQltyField."Case Sensitive"), 'slightly before min inspection line grade');
        // [THEN] Value 6 (reinspection pass value) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '6', NumericalMeasureQltyField."Case Sensitive"), 'pass value.');
        // [THEN] Blank value is not treated as zero and evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '', NumericalMeasureQltyField."Case Sensitive"), 'ensure that blank is not treated as a zero - integer.');
        // [THEN] Zero value is not treated as blank and evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '0', NumericalMeasureQltyField."Case Sensitive"), 'ensure that zero is not treated as a blank - Integer');

        // [THEN] Non-integer value (7.0001) causes an error
        ClearLastError();
        asserterror LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, NumericalMeasureQltyField."Field Type", '7.0001', NumericalMeasureQltyField."Case Sensitive"), 'should error, value is not an integer.');
        LibraryAssert.ExpectedError(Expected1Err);
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_Text()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        SanityCheckQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        DatabaseIsCaseSensitive: Boolean;
    begin
        // [SCENARIO] Evaluate grade for text field with template-level conditions overriding field-level, testing case sensitivity and blank grade validation

        // [GIVEN] No blank grades exist in the system initially
        DatabaseIsCaseSensitive := IsDatabaseCaseSensitive();
        SanityCheckQltyInspectionGrade.Reset();
        SanityCheckQltyInspectionGrade.SetFilter(Code, '=''''');
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - a');
        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured and no blank grades created
        QltyAutoConfigure.EnsureBasicSetup(false);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - b');
        // [GIVEN] An inspection template with a text field is created and no blank grades created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyField."Field Type"::"Field Type Text", TextQltyField, QltyInspectionTemplateLine);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - c');
        // [GIVEN] Field-level grade condition is set to 'A|B|C' for PASS grade
        TextQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), 'A|B|C', true);

        // [GIVEN] Template-level grade condition is modified to 'D|E' for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, 'D|E');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        // [GIVEN] Prioritized rule is created and no blank grades created
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - d');

        // [GIVEN] A production order is generated
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        // [GIVEN] Production order is retrieved and Inspection is created with no blank grades
        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - e');
        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level grade conditions are retrieved with no blank grades
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", TextQltyField.Code);
        QltyInspectionLine.FindFirst();
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - f');
        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] Grade is evaluated with blank value
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - g');
        // [THEN] Grade is INPROGRESS for blank value and no blank grades created
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", '', TextQltyField."Case Sensitive"), 'blank value');
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionGrade.Count(), 'should be no blank grades - gb');

        // [THEN] Value 'D' (in template condition) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'D', TextQltyField."Case Sensitive"), 'first text-method1');
        // [THEN] Value 'D' evaluates to PASS using alternative evaluation method (no line parameter)
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'D', TextQltyField."Case Sensitive"), 'first text method2 test with no line.');
        // [THEN] Value 'e' (lowercase) with insensitive comparison evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'e', TextQltyField."Case Sensitive"::Insensitive), 'second text lowercase insensitive ');
        if DatabaseIsCaseSensitive then
            // [THEN] Value 'e' (lowercase) with sensitive comparison evaluates to FAIL
            LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'e', TextQltyField."Case Sensitive"::Sensitive), 'second text lowercase sensitive')
        else
            // [THEN] Value 'e' (lowercase) with sensitive comparison evaluates to PASS
            LibraryAssert.AreEqual('PASS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'e', TextQltyField."Case Sensitive"::Sensitive), 'second text lowercase sensitive');
        // [THEN] Value 'A' (in field-level condition) evaluates to FAIL (template override works)
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'A', TextQltyField."Case Sensitive"), 'original field pass, which should be overwritten by the template.');
        // [THEN] Value 'c' (lowercase field-level condition) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'c', TextQltyField."Case Sensitive"), 'original field lowercase');
        // [THEN] Value 'C' (field-level condition) evaluates to FAIL (template override works)
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'C', TextQltyField."Case Sensitive"), 'original field');
        // [THEN] Value 'Monkey' (not in any condition) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", 'Monkey', TextQltyField."Case Sensitive"), 'A value not in any condition.');
        // [THEN] Blank value reinspectioned evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyGradeEvaluation.EvaluateGrade(QltyInspectionHeader, QltyInspectionLine, TestQltyIGradeConditionConf, TextQltyField."Field Type", '', TextQltyField."Case Sensitive"), 'ensure that blank is not treated as a zero - integer.');
    end;

    [Test]
    procedure EvaluateGrade_BasicExpressions_Replacement_Decimal()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        UsesReferenceQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyField: Record "Qlty. Field";
        UsesReferenceInPassConditionQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        UsesReferenceQltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate grade using expression with field reference replacement for dynamic decimal range validation

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with two decimal fields is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyField."Field Type"::"Field Type Decimal", NumericalMeasureReferenceQltyField, OriginalQltyInspectionTemplateLine);

        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, UsesReferenceInPassConditionQltyField."Field Type"::"Field Type Decimal", UsesReferenceInPassConditionQltyField, UsesReferenceQltyInspectionTemplateLine);

        // [GIVEN] First field has template-level grade condition set to 6..7 for PASS
        OriginalQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", OriginalQltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Second field has dynamic condition '1..[FieldCode]' that references first field's value
        Clear(TestQltyIGradeConditionConf);
        UsesReferenceQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", UsesReferenceQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", UsesReferenceQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", UsesReferenceQltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, StrSubstno('1..[%1]', NumericalMeasureReferenceQltyField.Code));
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line for second field (uses reference) is retrieved
        UsesReferenceQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        UsesReferenceQltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        UsesReferenceQltyInspectionLine.SetRange("Field Code", UsesReferenceInPassConditionQltyField.Code);
        UsesReferenceQltyInspectionLine.FindFirst();

        // [GIVEN] Test-level grade conditions are retrieved
        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", UsesReferenceQltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", UsesReferenceQltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", UsesReferenceQltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", UsesReferenceQltyInspectionLine."Field Code");

        // [GIVEN] Reference field value is set to 6
        QltyInspectionHeader.SetTestValue(NumericalMeasureReferenceQltyField."Code", '6');

        // [WHEN] Grade is evaluated with value 6 (at max of dynamic range 1..6)
        // [THEN] Grade evaluates to PASS
        LibraryAssert.AreEqual(
            'PASS',
            QltyGradeEvaluation.EvaluateGrade(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            TestQltyIGradeConditionConf,
             UsesReferenceInPassConditionQltyField."Field Type",
             '6',
             UsesReferenceInPassConditionQltyField."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 1 (at min of dynamic range) evaluates to PASS
        LibraryAssert.AreEqual(
            'PASS',
            QltyGradeEvaluation.EvaluateGrade(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            TestQltyIGradeConditionConf,
             UsesReferenceInPassConditionQltyField."Field Type",
             '1',
             UsesReferenceInPassConditionQltyField."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 7 (exceeding dynamic range max) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyGradeEvaluation.EvaluateGrade(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            TestQltyIGradeConditionConf,
            UsesReferenceInPassConditionQltyField."Field Type",
            '7',
            UsesReferenceInPassConditionQltyField."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 0.9 (below dynamic range min) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyGradeEvaluation.EvaluateGrade(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            TestQltyIGradeConditionConf,
            UsesReferenceInPassConditionQltyField."Field Type",
            '0.9',
            UsesReferenceInPassConditionQltyField."Case Sensitive"
            ),
            'should be using a condition of 1..6');
    end;

    [Test]
    procedure GetTestLineConfigFilters()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        UsesReferenceQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyField: Record "Qlty. Field";
        UsesReferenceInPassConditionQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        UsesReferenceQltyInspectionLine: Record "Qlty. Inspection Line";
        ExpectedQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ActualQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Verify GetTestLineConfigFilters returns correct filters for inspection line-specific grade conditions with expression replacement

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyField."Field Type"::"Field Type Decimal", NumericalMeasureReferenceQltyField, OriginalQltyInspectionTemplateLine);

        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, UsesReferenceInPassConditionQltyField."Field Type"::"Field Type Decimal", UsesReferenceInPassConditionQltyField, UsesReferenceQltyInspectionTemplateLine);
        OriginalQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", OriginalQltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        Clear(ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf);
        UsesReferenceQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", UsesReferenceQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", UsesReferenceQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", UsesReferenceQltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, StrSubstno('1..{2+[%1]}', NumericalMeasureReferenceQltyField.Code));
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line for second field is retrieved with expression '1..{2+[FieldCode]}'
        UsesReferenceQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        UsesReferenceQltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        UsesReferenceQltyInspectionLine.SetRange("Field Code", UsesReferenceInPassConditionQltyField.Code);
        UsesReferenceQltyInspectionLine.FindFirst();

        // [GIVEN] Expected filters are manually configured for inspection line-specific grade conditions
        ExpectedQltyIGradeConditionConf.Reset();
        ExpectedQltyIGradeConditionConf.SetRange("Condition Type", ExpectedQltyIGradeConditionConf."Condition Type"::Inspection);
        ExpectedQltyIGradeConditionConf.SetRange("Target Code", UsesReferenceQltyInspectionLine."Inspection No.");
        ExpectedQltyIGradeConditionConf.SetRange("Target Reinspection No.", UsesReferenceQltyInspectionLine."Reinspection No.");
        ExpectedQltyIGradeConditionConf.SetRange("Target Line No.", UsesReferenceQltyInspectionLine."Line No.");
        ExpectedQltyIGradeConditionConf.SetRange("Field Code", UsesReferenceQltyInspectionLine."Field Code");

        // [WHEN] GetTestLineConfigFilters is called to retrieve actual filters
        QltyGradeEvaluation.GetTestLineConfigFilters(UsesReferenceQltyInspectionLine, ActualQltyIGradeConditionConf);
        // [THEN] Actual filters match expected filters for inspection line grade conditions
        LibraryAssert.AreEqual(ExpectedQltyIGradeConditionConf.GetView(), ActualQltyIGradeConditionConf.GetView(), 'grade condition filters should match.');
    end;

    [Test]
    procedure GetTemplateLineConfigFilters()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyField: Record "Qlty. Field";
        ExpectedQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ActualQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Verify GetTemplateLineConfigFilters returns correct filters for template line-specific grade conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyField."Field Type"::"Field Type Decimal", NumericalMeasureReferenceQltyField, OriginalQltyInspectionTemplateLine);
        // [GIVEN] Template-level grade condition is set to 6..7 for PASS grade
        OriginalQltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", OriginalQltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Expected filters are manually configured for template line-specific grade conditions
        ExpectedQltyIGradeConditionConf.Reset();
        ExpectedQltyIGradeConditionConf.SetRange("Condition Type", ExpectedQltyIGradeConditionConf."Condition Type"::Template);
        ExpectedQltyIGradeConditionConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ExpectedQltyIGradeConditionConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ExpectedQltyIGradeConditionConf.SetRange("Field Code", OriginalQltyInspectionTemplateLine."Field Code");

        // [WHEN] GetTemplateLineConfigFilters is called to retrieve actual filters
        GetTemplateLineConfigFilters(OriginalQltyInspectionTemplateLine, ActualQltyIGradeConditionConf);
        // [THEN] Actual filters match expected filters for template line grade conditions
        LibraryAssert.AreEqual(ExpectedQltyIGradeConditionConf.GetView(), ActualQltyIGradeConditionConf.GetView(), 'grade condition filters should match for template line..');
    end;

    [Test]
    procedure GetFieldConfigFilters()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyField: Record "Qlty. Field";
        ExpectedQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ActualQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Verify GetFieldConfigFilters returns correct filters for field-specific grade conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyField."Field Type"::"Field Type Decimal", NumericalMeasureReferenceQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Expected filters are set for field-level grade conditions
        ExpectedQltyIGradeConditionConf.Reset();
        ExpectedQltyIGradeConditionConf.SetRange("Condition Type", ExpectedQltyIGradeConditionConf."Condition Type"::Field);
        ExpectedQltyIGradeConditionConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Field Code");
        ExpectedQltyIGradeConditionConf.SetRange("Field Code", OriginalQltyInspectionTemplateLine."Field Code");

        // [WHEN] GetFieldConfigFilters is called to retrieve actual filters
        GetFieldConfigFilters(NumericalMeasureReferenceQltyField, ActualQltyIGradeConditionConf);
        // [THEN] Actual filters match expected filters for field-level grade conditions
        LibraryAssert.AreEqual(ExpectedQltyIGradeConditionConf.GetView(), ActualQltyIGradeConditionConf.GetView(), 'grade condition filters should match for field');
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Decimal()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DecimalQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that decimal field default values must fall within allowable values range (1..3)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, DecimalQltyField."Field Type"::"Field Type Decimal", DecimalQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for decimal field are set to range 1..3
        DecimalQltyField."Allowable Values" := '1..3';
        DecimalQltyField.Modify();

        // [WHEN] Default value is set to 3 (maximum of range)
        DecimalQltyField."Default Value" := '3';
        // [THEN] Validation passes
        QltyGradeEvaluation.ValidateAllowableValuesOnField(DecimalQltyField);
        // [THEN] Default value 4 (exceeding maximum) causes error
        ClearLastError();
        DecimalQltyField."Default Value" := '4';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DecimalQltyField);
        // [THEN] Default value 0.9999 (below minimum) causes error
        ClearLastError();
        DecimalQltyField."Default Value" := '0.9999';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DecimalQltyField);
        // [THEN] Default value 1 (minimum of range) passes validation
        ClearLastError();
        DecimalQltyField."Default Value" := '1';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(DecimalQltyField);

        // [THEN] Non-numeric default value causes error
        ClearLastError();
        DecimalQltyField."Default Value" := 'this is not a number';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DecimalQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Option()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        OptionListQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that option field default values must be one of the allowable comma-delimited options (A,B,C,D)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with an option field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, OptionListQltyField."Field Type"::"Field Type Option", OptionListQltyField, OriginalQltyInspectionTemplateLine);
        // [GIVEN] Allowable values for option field are set to 'A,B,C,D'
        OptionListQltyField.Description := '';
        OptionListQltyField."Allowable Values" := 'A,B,C,D';
        OptionListQltyField.Modify();

        // [THEN] Default value 'AA' (not in list) causes error
        ClearLastError();
        OptionListQltyField."Default Value" := 'AA';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);

        // [THEN] Default value 'E' (not in list) causes error
        ClearLastError();
        OptionListQltyField."Default Value" := 'E';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);

        // [THEN] Default value 'AB' (not in list) causes error
        ClearLastError();
        OptionListQltyField."Default Value" := 'AB';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);

        // [THEN] Default value 'A' (in list) passes validation
        ClearLastError();
        OptionListQltyField."Default Value" := 'A';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);
        // [THEN] Default value 'B' (in list) passes validation
        OptionListQltyField."Default Value" := 'B';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);
        // [THEN] Default value 'D' (in list) passes validation
        OptionListQltyField."Default Value" := 'D';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(OptionListQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Integer()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        IntegerQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that integer field default values must fall within allowable values range (1..3)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, IntegerQltyField."Field Type"::"Field Type Integer", IntegerQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for integer field are set to range 1..3
        IntegerQltyField."Allowable Values" := '1..3';
        IntegerQltyField.Modify();

        // [WHEN] Default value is set to 3 (maximum of range)
        IntegerQltyField."Default Value" := '3';
        // [THEN] Validation passes
        QltyGradeEvaluation.ValidateAllowableValuesOnField(IntegerQltyField);
        // [THEN] Default value 4 (exceeding maximum) causes error
        ClearLastError();
        IntegerQltyField."Default Value" := '4';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(IntegerQltyField);
        // [THEN] Default value 0 (below minimum) causes error
        ClearLastError();
        IntegerQltyField."Default Value" := '0';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(IntegerQltyField);
        // [THEN] Default value 1 (minimum of range) passes validation
        ClearLastError();
        IntegerQltyField."Default Value" := '1';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(IntegerQltyField);
        // [THEN] Non-integer default value causes error
        ClearLastError();
        IntegerQltyField."Default Value" := 'this is not an integer';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(IntegerQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Text()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that text field default values must be one of the allowable pipe-delimited options (A|B|C)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a text field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyField."Field Type"::"Field Type Text", TextQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for text field are set to 'A|B|C'
        TextQltyField."Allowable Values" := 'A|B|C';
        TextQltyField.Modify();

        // [WHEN] Default value is set to 'A' (in list)
        TextQltyField."Default Value" := 'A';
        // [THEN] Validation passes
        QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField);
        // [THEN] Default value 'D' (not in list) causes error
        ClearLastError();
        TextQltyField."Default Value" := 'D';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField);
        // [THEN] Default value '0' (not in list) causes error
        ClearLastError();
        TextQltyField."Default Value" := '0';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField);
        // [THEN] Default value 'B' (in list) passes validation
        ClearLastError();
        TextQltyField."Default Value" := 'B';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Date()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that date field default values must match the exact allowable date value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a date field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, DateQltyField."Field Type"::"Field Type Date", DateQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for date field is set to '2001-02-03'
        DateQltyField."Allowable Values" := '2001-02-03';
        DateQltyField.Modify();

        // [WHEN] Default value is set to '2001-02-03' (exact match)
        DateQltyField."Default Value" := '2001-02-03';
        // [THEN] Validation passes
        QltyGradeEvaluation.ValidateAllowableValuesOnField(DateQltyField);
        // [THEN] Default value '2001-02-04' (different date) causes error
        ClearLastError();
        DateQltyField."Default Value" := '2001-02-04';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateQltyField);
        // [THEN] Default value '2001-01-01' (different date) causes error
        ClearLastError();
        DateQltyField."Default Value" := '2001-01-01';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateQltyField);
        // [THEN] Non-date default value causes error
        ClearLastError();
        DateQltyField."Default Value" := 'this is not a date';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_DateTime()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateTimeQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that datetime field default values must match the exact allowable datetime value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a datetime field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, DateTimeQltyField."Field Type"::"Field Type DateTime", DateTimeQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for datetime field is set to '2001-02-03 04:05:06'
        DateTimeQltyField."Allowable Values" := '2001-02-03 04:05:06';
        DateTimeQltyField.Modify();

        // [WHEN] Default value is set to '2001-02-03 04:05:06' (exact match)
        DateTimeQltyField."Default Value" := '2001-02-03 04:05:06';
        // [THEN] Validation passes
        QltyGradeEvaluation.ValidateAllowableValuesOnField(DateTimeQltyField);
        // [THEN] Default value '2001-02-03 04:05:07' (one second later) causes error
        ClearLastError();
        DateTimeQltyField."Default Value" := '2001-02-03 04:05:07';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateTimeQltyField);
        // [THEN] Default value '2001-02-03 04:05:00' (different time) causes error
        ClearLastError();
        DateTimeQltyField."Default Value" := '2001-02-03 04:05:00';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateTimeQltyField);
        // [THEN] Non-datetime default value causes error
        ClearLastError();
        DateTimeQltyField."Default Value" := 'this is not a date time.';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(DateTimeQltyField);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Boolean()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        BooleanQltyField: Record "Qlty. Field";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        // [SCENARIO] Validate that boolean field default values must match the allowable boolean value and accept equivalent representations

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a boolean field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyField."Field Type"::"Field Type Boolean", BooleanQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for boolean field is set to 'Yes'
        BooleanQltyField."Allowable Values" := 'Yes';
        BooleanQltyField.Modify();

        // [WHEN] Default value is set to 'Yes' and equivalent true representations
        BooleanQltyField."Default Value" := 'Yes';
        // [THEN] 'Yes' passes validation
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] 'True' (equivalent to Yes) passes validation
        BooleanQltyField."Default Value" := 'True';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] '1' (equivalent to Yes) passes validation
        BooleanQltyField."Default Value" := '1';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] 'On' (equivalent to Yes) passes validation
        BooleanQltyField."Default Value" := 'On';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] 'No' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyField."Default Value" := 'No';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] 'False' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyField."Default Value" := 'False';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] '0' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyField."Default Value" := '0';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] 'Off' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyField."Default Value" := 'Off';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] Non-boolean value causes error
        ClearLastError();
        BooleanQltyField."Default Value" := 'this is not a boolean';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);

        // [GIVEN] A new boolean field with blank allowable values (accepts any boolean value)
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyField."Field Type"::"Field Type Boolean", BooleanQltyField, OriginalQltyInspectionTemplateLine);

        BooleanQltyField."Allowable Values" := '';
        BooleanQltyField.Modify();
        // [THEN] Blank default value passes validation
        BooleanQltyField."Default Value" := '';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] All true representations pass validation when allowable values are blank
        BooleanQltyField."Default Value" := 'Yes';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := 'True';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := '1';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := 'On';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] All false representations pass validation when allowable values are blank
        BooleanQltyField."Default Value" := 'No';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := 'False';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := '0';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        BooleanQltyField."Default Value" := 'Off';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        // [THEN] Non-boolean value is converted to 'No'
        BooleanQltyField."Default Value" := 'this is not a boolean';
        QltyGradeEvaluation.ValidateAllowableValuesOnField(BooleanQltyField);
        LibraryAssert.AreEqual('No', BooleanQltyField."Default Value", 'Not-yes should have been converted to No');
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_WithTestContext()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TextQltyField: Record "Qlty. Field";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate that field default values are validated with test context, accepting valid values and rejecting invalid ones

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a text field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyField."Field Type"::"Field Type Text", TextQltyField, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for text field are set to 'A|B|C'
        TextQltyField."Allowable Values" := 'A|B|C';
        TextQltyField.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved for test context validation
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", TextQltyField.Code);
        QltyInspectionLine.FindFirst();

        // [WHEN] Default value is set to 'A' (in allowable values)
        TextQltyField."Default Value" := 'A';
        // [THEN] Validation passes with inspection header context
        QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField, QltyInspectionHeader);
        // [THEN] Validation passes with inspection header and inspection line context
        QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField, QltyInspectionHeader, QltyInspectionLine);

        // [THEN] Default value 'D' (not in allowable values) causes error with inspection header context
        ClearLastError();
        TextQltyField."Default Value" := 'D';
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField, QltyInspectionHeader);
        // [THEN] Default value 'D' causes error with inspection header and inspection line context
        asserterror QltyGradeEvaluation.ValidateAllowableValuesOnField(TextQltyField, QltyInspectionHeader, QltyInspectionLine);
        ClearLastError();
    end;

    [Test]
    procedure EvaluateGrade_WithOptionalTestLine_OnRun()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Test OnRun method of grade evaluation codeunit with integer field values and error handling

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyField."Field Type"::"Field Type Integer", NumericalMeasureQltyField, QltyInspectionTemplateLine);

        // [GIVEN] Field-level grade condition is set to 4..5 for PASS grade
        NumericalMeasureQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '4..5', true);

        // [GIVEN] Template-level grade condition is modified to 6..7 for PASS grade
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] FAIL grade condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved and grade conditions are set up
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.SetRange("Field Code", NumericalMeasureQltyField.Code);
        QltyInspectionLine.FindFirst();

        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Inspection);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        // [WHEN] OnRun is called with blank test value
        QltyInspectionLine."Test Value" := '';
        QltyInspectionLine.Modify(false);
        Commit();
        // [THEN] OnRun returns true and grade is INPROGRESS
        LibraryAssert.AreEqual(true, QltyGradeEvaluation.Run(QltyInspectionLine), 'OnRun should have returned true for validation. blank.');
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionLine."Grade Code", 'blank value via onrun.');

        // [THEN] OnRun with value 6 (minimum) returns true and grade is PASS
        QltyInspectionLine."Test Value" := '6';
        LibraryAssert.AreEqual(true, QltyGradeEvaluation.Run(QltyInspectionLine), 'OnRun should have returned true for validation. min');
        LibraryAssert.AreEqual('PASS', QltyInspectionLine."Grade Code", 'min value via onrun.');

        // [THEN] OnRun with invalid value 'not a number' returns false
        QltyInspectionLine."Test Value" := 'not a number';
        LibraryAssert.AreEqual(false, QltyGradeEvaluation.Run(QltyInspectionLine), 'should not have evaluated to a number.');

        // [THEN] OnRun with value 8 (exceeding max) returns true and grade is FAIL
        QltyInspectionLine."Test Value" := '8';
        LibraryAssert.AreEqual(true, QltyGradeEvaluation.Run(QltyInspectionLine), 'OnRun should have returned true for validation. Fail');
        LibraryAssert.AreEqual('FAIL', QltyInspectionLine."Grade Code", 'exceeded value..');

        // [THEN] OnRun with decimal value '7.0001' returns false with expected error
        ClearLastError();
        QltyInspectionLine."Test Value" := '7.0001';
        LibraryAssert.AreEqual(false, QltyGradeEvaluation.Run(QltyInspectionLine), 'should not have evaluated to an integer.');
        LibraryAssert.AreEqual(StrSubstNo(Expected2Err, NumericalMeasureQltyField.Description), GetLastErrorText(), 'error text from failed run.');
    end;

    [Test]
    procedure ValidateTestLine()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        NumericMeasureQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate inspection line values against allowable values range for decimal field with grade evaluation

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with a decimal field and allowable values range 0..12345 is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyField."Field Type"::"Field Type Decimal", NumericalMeasureQltyField, QltyInspectionTemplateLine);
        NumericalMeasureQltyField.Validate("Allowable Values", '0..12345');
        NumericalMeasureQltyField.Modify(false);

        // [GIVEN] Field-level grade condition is set to 4..5 for PASS grade
        NumericalMeasureQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), '4..5', true);
        // [GIVEN] Template-level grade condition is modified to 6..7 for PASS grade
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved for validation
        NumericMeasureQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        NumericMeasureQltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        NumericMeasureQltyInspectionLine.SetRange("Field Code", NumericalMeasureQltyField.Code);
        NumericMeasureQltyInspectionLine.FindFirst();

        // [WHEN] ValidateTestLine is called with blank value
        NumericMeasureQltyInspectionLine."Test Value" := '';
        NumericMeasureQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', NumericMeasureQltyInspectionLine."Grade Code", 'blank value');

        // [THEN] ValidateTestLineWithAllowableValues also returns INPROGRESS for blank value
        NumericMeasureQltyInspectionLine."Test Value" := '';
        NumericMeasureQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLineWithAllowableValues(NumericMeasureQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('INPROGRESS', NumericMeasureQltyInspectionLine."Grade Code", 'blank value with testing allowable values.');

        // [THEN] Value 6 (minimum of grade range) evaluates to PASS
        NumericMeasureQltyInspectionLine."Test Value" := '6';
        NumericMeasureQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', NumericMeasureQltyInspectionLine."Grade Code", 'min value inspection line grade');

        // [THEN] Value 7.0001 (exceeding maximum) evaluates to FAIL
        NumericMeasureQltyInspectionLine."Test Value" := '7.0001';
        NumericMeasureQltyInspectionLine.Modify();

        QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Grade Code", 'slightly exceeding max inspection line grade');
        QltyGradeEvaluation.ValidateTestLineWithAllowableValues(NumericMeasureQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Grade Code", 'slightly exceeding max inspection line grade');

        // [THEN] Value 5.999999 (below minimum) evaluates to FAIL
        NumericMeasureQltyInspectionLine."Test Value" := '5.999999';
        NumericMeasureQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Grade Code", 'slightly before min inspection line grade');
        // [THEN] Value 6.999999 (near maximum) evaluates to PASS
        NumericMeasureQltyInspectionLine."Test Value" := '6.999999';
        NumericMeasureQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);

        LibraryAssert.AreEqual('PASS', NumericMeasureQltyInspectionLine."Grade Code", 'slightly before min inspection line grade');

        // [THEN] Value -1 (outside allowable values range) causes an error
        NumericMeasureQltyInspectionLine."Test Value" := '-1';
        NumericMeasureQltyInspectionLine.Modify(false);

        ClearLastError();
        asserterror QltyGradeEvaluation.ValidateTestLine(NumericMeasureQltyInspectionLine);

        LibraryAssert.ExpectedError(StrSubstNo(Expected3Err, NumericMeasureQltyInspectionLine."Description"));
    end;

    [Test]
    procedure ValidateTestLine_OptionList()
    var
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        OptionListMeasureQltyField: Record "Qlty. Field";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        OptionListQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate inspection line values for option field with allowable values (A,B,C,D,E) and template-level grade conditions (C|D for PASS)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyAutoConfigure.EnsureBasicSetup(false);

        // [GIVEN] An inspection template with an option field is created with allowable values 'A,B,C,D,E'
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateFieldAndAddToTemplate(QltyInspectionTemplateHdr, OptionListMeasureQltyField."Field Type"::"Field Type Option", OptionListMeasureQltyField, QltyInspectionTemplateLine);
        OptionListMeasureQltyField.Description := '';
        OptionListMeasureQltyField.Validate("Allowable Values", 'A,B,C,D,E');
        OptionListMeasureQltyField.Modify(false);
        QltyInspectionTemplateLine.Description := '';
        QltyInspectionTemplateLine.Modify(false);

        // [GIVEN] Field-level grade condition is set to 'A|B' for PASS grade
        OptionListMeasureQltyField.SetGradeCondition(QltyAutoConfigure.GetDefaultPassGrade(), 'A|B', true);
        // [GIVEN] Template-level grade condition is modified to 'C|D' for PASS grade (overrides field-level)
        QltyInspectionTemplateLine.EnsureGrades(false);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.SetRange("Grade Code", QltyAutoConfigure.GetDefaultPassGrade());
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Validate(Condition, 'C|D');
        ToLoadToLoadToUseAsATemplateQltyIGradeConditionConf.Modify();
        // [GIVEN] Inspection generation rules are cleared and prioritized rule is created
        QltyInspectionGenRule.DeleteAll(false);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created with specific template
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionCreate.CreateInspectionWithVariantAndTemplate(ProdOrderRoutingLine, true, QltyInspectionTemplateHdr.Code);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Inspection line for option field is retrieved
        OptionListQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        OptionListQltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        OptionListQltyInspectionLine.SetRange("Field Code", OptionListMeasureQltyField.Code);
        OptionListQltyInspectionLine.FindFirst();

        // [WHEN] ValidateTestLine is called with blank value
        OptionListQltyInspectionLine."Test Value" := '';
        OptionListQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(OptionListQltyInspectionLine);
        // [THEN] Grade is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', OptionListQltyInspectionLine."Grade Code", 'blank value');

        // [THEN] ValidateTestLineWithAllowableValues also returns INPROGRESS for blank value
        OptionListQltyInspectionLine."Test Value" := '';
        OptionListQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLineWithAllowableValues(OptionListQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('INPROGRESS', OptionListQltyInspectionLine."Grade Code", 'blank value with testing allowable values.');

        // [THEN] Value 'C' (first PASS option in template condition) evaluates to PASS
        OptionListQltyInspectionLine."Test Value" := 'C';
        OptionListQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', OptionListQltyInspectionLine."Grade Code", 'one of 2 options');

        // [THEN] Value 'D' (second PASS option in template condition) evaluates to PASS
        OptionListQltyInspectionLine."Test Value" := 'D';
        OptionListQltyInspectionLine.Modify();
        QltyGradeEvaluation.ValidateTestLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', OptionListQltyInspectionLine."Grade Code", 'two of two options.');

        // [THEN] Value 'A' (in allowable values but not in template PASS condition) evaluates to FAIL
        OptionListQltyInspectionLine."Test Value" := 'A';
        OptionListQltyInspectionLine.Modify();

        QltyGradeEvaluation.ValidateTestLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', OptionListQltyInspectionLine."Grade Code", 'allowed but failing.');

        // [THEN] Value 'F' (not in allowable values) causes an error
        ClearLastError();
        OptionListQltyInspectionLine."Test Value" := 'F';
        asserterror QltyGradeEvaluation.ValidateTestLineWithAllowableValues(OptionListQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.ExpectedError(StrSubstNo(Expected4Err, OptionListQltyInspectionLine."Field Code"));
    end;

    local procedure GetTemplateLineConfigFilters(var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; var OutTemplateLineQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        OutTemplateLineQltyIGradeConditionConf.SetRange("Condition Type", OutTemplateLineQltyIGradeConditionConf."Condition Type"::Template);
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Reinspection No.");
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        OutTemplateLineQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
    end;

    local procedure GetFieldConfigFilters(var QltyField: Record "Qlty. Field"; var OutTemplateLineQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        OutTemplateLineQltyIGradeConditionConf.SetRange("Condition Type", OutTemplateLineQltyIGradeConditionConf."Condition Type"::Field);
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Code", QltyField.Code);
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Reinspection No.");
        OutTemplateLineQltyIGradeConditionConf.SetRange("Target Line No.");
        OutTemplateLineQltyIGradeConditionConf.SetRange("Field Code", QltyField.Code);
    end;

    local procedure IsDatabaseCaseSensitive(): Boolean
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        TempQltyInspectionHeader.Init();
        TempQltyInspectionHeader."No." := 'A';
        TempQltyInspectionHeader.Description := 'CASESENSITIVE';
        TempQltyInspectionHeader.Insert();

        Clear(TempQltyInspectionHeader);
        TempQltyInspectionHeader.SetFilter(Description, 'casesensitive');
        exit(TempQltyInspectionHeader.IsEmpty());
    end;
}
