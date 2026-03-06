// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 139963 "Qlty. Tests - Result Eval."
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
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        TestValue: Text;
    begin
        // [SCENARIO] Validate decimal value testing with various conditions including blank values, ranges, exact matches, and comparison operators

        // [GIVEN] A result evaluation codeunit instance
        // [WHEN] Testing blank and zero values with different allowable ranges
        // [THEN] Blank values pass with blank allowable ranges but fail with numerical ranges, and zero passes within its valid range
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal('', ''), 'blank string with blank allowable');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal('', '0..1'), 'blank string with numerical range.');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal('0', '0..1'), 'zero numerical range.');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal('0', '-100..100'), 'zero numerical range-extended.');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal('', '-100..100'), 'blank numerical range-extended.');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal('0', ''), 'zero with blank range.');

        // [WHEN] Testing decimal value '3' with various conditions
        TestValue := '3';
        // [THEN] Value passes exact match, range, and comparison validations correctly
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, ''), 'Decimal basic no condition');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '3'), 'Decimal basic exact');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '000000000000000'), 'Decimal basic exact lots of precision');

        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '2' + GetRegionalDecimalSeparator() + '99999'), 'Decimal basic almost 3 under');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '00001'), 'Decimal basic almost 3 over');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '2'), 'Decimal basic not 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '<>0'), 'Decimal basic not zero');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '<>'''''), 'Decimal basic not zero, demo person special');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '>0'), 'Decimal basic more than zero');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '<=3'), 'Decimal basic lteq 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '>=3'), 'Decimal basic gteq 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '<4'), 'Decimal basic lt 4');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '>2' + GetRegionalDecimalSeparator() + '9999'), 'Decimal basic gt 2');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '2..4'), 'Decimal basic range');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '3..3'), 'Decimal basic range');

        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '-100..2' + GetRegionalDecimalSeparator() + '9'), 'Decimal basic range less');

        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '3' + GetRegionalDecimalSeparator() + '0001..100'), 'Decimal basic range more');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '1|2|3|4'), 'Decimal basic range list');

        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDecimal(TestValue, '1|2|4'), 'Decimal basic range list');
    end;

    [Test]
    procedure ValueInteger()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        TestValue: Text;
    begin
        // [SCENARIO] Validate integer value testing with various conditions including exact matches, ranges, comparisons, and lists

        // [GIVEN] An integer test value of '3'
        TestValue := '3';

        // [WHEN] Testing the integer value against various conditions
        // [THEN] The value passes validation for exact matches, ranges, comparisons, and list inclusions
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, ''), 'Integer basic no condition');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger('', ''), 'Integer basic blank.');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '3'), 'Integer basic exact');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '2'), 'Integer basic not 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '<>0'), 'Integer basic not zero');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '>0'), 'Integer basic more than zero');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '<=3'), 'Integer basic lteq 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '>=3'), 'Integer basic gteq 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '<4'), 'Integer basic lt 4');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '>2'), 'Integer basic gt 2');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '2..4'), 'Integer basic range');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '3..3'), 'Integer basic range');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '-100..2'), 'Integer basic range less');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '4..100'), 'Integer basic range more');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '1|2|3|4'), 'Integer list');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsInteger(TestValue, '1|2|4'), 'Integer list missing');
    end;

    [Test]
    procedure ValueString()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
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
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString(TestValue, ''), 'String basic no condition');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString(TestValue, '3'), 'String basic exact');
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsString(TestValue, '2'), 'String basic not 3');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString(TestValue, '<>0'), 'String basic not zero');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString(TestValue, '<>'''''), 'String basic not blank');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('abcdefg', '*b*'), 'String basic wildcard 1');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('abcdefg', '*g'), 'String basic wildcard 2');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'caseSensitive'), 'String case sensitive 1');
        if DatabaseIsCaseSensitive then begin
            LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive'), 'String case sensitive 2');
            LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'CaseSensitive'), 'String case sensitive 3');
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive', CaseOption::Insensitive), 'String case sensitive 4');
            LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive', CaseOption::Sensitive), 'String case sensitive 5');
        end else begin
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive'), 'String case sensitive 2');
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'CaseSensitive'), 'String case sensitive 3');
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive', CaseOption::Insensitive), 'String case sensitive 4');
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('caseSensitive', 'casesensitive', CaseOption::Sensitive), 'String case sensitive 5');
        end;
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('wildCardSearch', '*ard*'), 'String wildcard 1');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsString('wildCardSearch', 'wild*'), 'String wildcard 2');
    end;

    [TryFunction]
    procedure Try_TestValueDateIntentionallyBad()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        TestValue: Text[250];
    begin
        TestValue := 'not a date';
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '', false), 'Date basic not a date 1');
    end;

    [TryFunction]
    procedure Try_TestValueDateTimeIntentionallyBad()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        TestValue: Text[250];
    begin
        TestValue := 'not a datetime';
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, '', false), 'Datetime basic not a date time 1');
    end;

    [Test]
    procedure ValueDate()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
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

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '', false),
            'Date basic no condition 2');
        if IsDayMonthYearLocal() then
            LibraryAssert.AreNotEqual(TestValue, format(Date, 0, '<Day,2>' + GetDateSeparator() + '<Month,2>' + GetDateSeparator() + '<Year>'), 'Back and forth date - no change')
        else
            LibraryAssert.AreNotEqual(TestValue, format(Date, 0, '<Month,2>' + GetDateSeparator() + '<Day,2>' + GetDateSeparator() + '<Year>'), 'Back and forth date - no change');

        TestValue := OriginalTestValue;
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '', true), 'Date basic no condition 1');
        LibraryAssert.AreEqual(TestValue, format(Date, 0, '<Year4>-<Month,2>-<Day,2>'), 'Back and forth date - should change');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '1' + GetDateSeparator() + '1..2' + GetDateSeparator() + '2', false), 'Date basic date range 1');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, StrSubstNo('1' + GetDateSeparator() + '1' + GetDateSeparator() + '%1..2' + GetDateSeparator() + '2' + GetDateSeparator() + '%1', YearAsString), false), 'Date basic date range 2');
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, StrSubstNo('>1' + GetDateSeparator() + '1' + GetDateSeparator() + '%1', YearAsString), false), 'Date basic date range 3');

        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, StrSubstNo('<=%1', format(Date)), false), 'Date basic date range 4');
        if IsDayMonthYearLocal() then begin
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '28' + GetDateSeparator() + '1', false),
                'Date basic NO CONVERT');
            LibraryAssert.AreNotEqual('28-1' + YearAsString, TestValue, 'date basic NO CONVERT');

            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '28-1', true), 'Date basic convert');
        end else begin
            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '1' + GetDateSeparator() + '28', false), 'Date basic NO CONVERT');
            LibraryAssert.AreNotEqual('1/28/' + YearAsString, TestValue, 'date basic NO CONVERT');

            LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '1/28', true), 'Date basic convert');
        end;

        LibraryAssert.AreEqual(YearAsString + '-01-28', TestValue, 'date basic convert 1');

        TestValue := '2023-12-31';
        Date := DMY2Date(31, 12, 2023);
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '', true), 'Date universal date value');

        TestValue := format(PredictableDate, 0, 9);
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDate(TestValue, TestValue, true), 'expected value matches expected date.');

        TestValue := format(PredictableDate, 0, 9);
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDate(TestValue, '<>' + TestValue, true), 'expected value matches anything but the expected date.');

        TestValue := '';
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDate(TestValue, format(PredictableDate, 0, 9), true), 'blank input date with valid acceptable date');
    end;

    [Test]
    procedure ValueDateTime()
    var
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
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
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, '', false), 'Datetime basic do not adjust' + DateFailureSuffixDetails);
        LibraryAssert.AreEqual(OriginalTestValue, TestValue, 'test value should not have changed for datetime ' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime with timezone adjustment
        TestValue := OriginalTestValue;
        // [THEN] Datetime passes validation and converts correctly
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, '', true), 'Date basic with adjustment of datetime' + DateFailureSuffixDetails);
        LibraryAssert.AreEqual(TestValue, format(Date, 0, 9), 'back and forth datetime.' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime within valid date range without adjustment
        // [THEN] Datetime within range passes validation
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 1, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 1, 2004), 235900T)), false),
                'Datetime basic date range jan to feb no adjustment ' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime outside valid date range
        // [THEN] Datetime outside range fails validation
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 2, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 3, 2004), 235900T)), false),
                'Datetime outside of date range basic date range jan to feb' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime within valid date range with adjustment
        // [THEN] Datetime passes validation with timezone adjustment
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, StrSubstNo('%1..%2', CreateDateTime(DMY2Date(28, 1, 2004), 000000T),
                CreateDateTime(DMY2Date(28, 1, 2004), 235900T)), true),
                'Datetime basic date range jan to feb with adjustment ' + DateFailureSuffixDetails);

        // [WHEN] Testing exact datetime match
        TestValue := format(Date, 0, 9);
        // [THEN] Exact match passes validation
        LibraryAssert.IsTrue(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, TestValue, true), 'expected value matches expected date.' + DateFailureSuffixDetails);

        // [WHEN] Testing datetime with not-equal condition
        TestValue := format(Date, 0, 9);
        // [THEN] Not-equal condition fails when values match
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, '<>' + TestValue, true), 'expected value matches anything but the expected date.' + DateFailureSuffixDetails);

        // [WHEN] Testing blank datetime against valid acceptable date
        TestValue := '';
        // [THEN] Blank datetime fails validation
        LibraryAssert.IsFalse(QltyInspectionUtility.CheckIfValueIsDateTime(TestValue, format(Date, 0, 9), true), 'blank input date with valid acceptable date' + DateFailureSuffixDetails);
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Decimal()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for decimal field with optional inspection line-specific result conditions overriding template conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Field-level result condition is set to 4..5 for PASS result
        NumericalMeasureQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '4..5', true);

        // [GIVEN] Template-level result condition is modified to 6..7 for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] FAIL result condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", NumericalMeasureQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual(
            'INPROGRESS',
            QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '', NumericalMeasureQltyTest."Case Sensitive"),
            'blank value');

        // [THEN] Value at minimum of range (6) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '6', NumericalMeasureQltyTest."Case Sensitive"),
            'min value inspection line result');
        // [THEN] Value slightly exceeding maximum (7.0001) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '7.0001', NumericalMeasureQltyTest."Case Sensitive"),
            'slightly exceeding max inspection line result');
        // [THEN] Value slightly below minimum (5.999999) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '5.999999', NumericalMeasureQltyTest."Case Sensitive"),
            'slightly before min inspection line result');

        // [THEN] Value slightly below maximum (6.999999) evaluates to PASS
        LibraryAssert.AreEqual(
           'PASS',
           QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '6.999999', NumericalMeasureQltyTest."Case Sensitive"),
           'slightly before min inspection line result');

        // [THEN] Blank value is not treated as zero and evaluates to INPROGRESS
        LibraryAssert.AreEqual(
            'INPROGRESS',
            QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '', NumericalMeasureQltyTest."Case Sensitive"),
            'ensure that blank is not treated as a zero - decimal.');

        // [THEN] Zero value is not treated as blank and evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '0.0', NumericalMeasureQltyTest."Case Sensitive"),
            'ensure that zero is not treated as a blank - decimal');
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_DateTime()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateTimeQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for datetime field with optional inspection line-specific result conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a datetime field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, DateTimeQltyTest."Test Value Type"::"Value Type DateTime", DateTimeQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Field-level result condition is set to '2001-02-03 01:02:03' for PASS result
        DateTimeQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '2001-02-03 01:02:03', true);

        // [GIVEN] Template-level result condition is modified to '2004-05-06 01:02:03' for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '2004-05-06 01:02:03');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", DateTimeQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateTimeQltyTest."Test Value Type", '', DateTimeQltyTest."Case Sensitive"), 'blank value');

        // [THEN] Exact datetime match evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateTimeQltyTest."Test Value Type", '2004-05-06 01:02:03', DateTimeQltyTest."Case Sensitive"), 'exact value pass');
        // [THEN] Datetime one second past expected evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateTimeQltyTest."Test Value Type", '2004-05-06 01:02:04', DateTimeQltyTest."Case Sensitive"), 'slightly exceeding max inspection line result');
        // [THEN] Field-level condition datetime is ignored (FAIL not PASS)
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateTimeQltyTest."Test Value Type", '2001-02-03 01:02:03', DateTimeQltyTest."Case Sensitive"), 'should have ignored the default field pass condition.');
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Date()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for date field with optional inspection line-specific result conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a date field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, DateQltyTest."Test Value Type"::"Value Type Date", DateQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Field-level result condition is set to '2001-02-03' for PASS result
        DateQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '2001-02-03', true);
        // [GIVEN] Template-level result condition is modified to '2004-05-06' for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '2004-05-06');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", DateQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateQltyTest."Test Value Type", '', DateQltyTest."Case Sensitive"), 'blank value');

        // [THEN] Exact date match evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateQltyTest."Test Value Type", '2004-05-06', DateQltyTest."Case Sensitive"), 'exact value pass');
        // [THEN] Date one day past expected evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateQltyTest."Test Value Type", '2004-05-07', DateQltyTest."Case Sensitive"), 'slightly exceeding max inspection line result');
        // [THEN] Field-level condition date is ignored (FAIL not PASS)
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, DateQltyTest."Test Value Type", '2001-02-03', DateQltyTest."Case Sensitive"), 'should have ignored the default field pass condition.');
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Boolean()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        BooleanQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for boolean field with template-level condition requiring 'Yes' value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a boolean field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyTest."Test Value Type"::"Value Type Boolean", BooleanQltyTest, QltyInspectionTemplateLine);
        // [GIVEN] Template-level result condition is set to 'Yes' for PASS result
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, 'Yes');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", BooleanQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", '', BooleanQltyTest."Case Sensitive"), 'blank value');
        // [THEN] Value 'Yes' evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", 'Yes', BooleanQltyTest."Case Sensitive"), 'exact value pass');
        // [THEN] Value 'On' (alternative true value) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", 'On', BooleanQltyTest."Case Sensitive"), 'different kind of yes');
        // [THEN] Value 'No' evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", 'No', BooleanQltyTest."Case Sensitive"), 'Direct No.');
        // [THEN] Value 'False' (alternative false value) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", 'False', BooleanQltyTest."Case Sensitive"), 'different kind of no.');
        // [THEN] Invalid boolean value evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, BooleanQltyTest."Test Value Type", 'this is not a boolean', BooleanQltyTest."Case Sensitive"), 'not a boolean');
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Label()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        LabelQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for label field type which should always return blank result regardless of value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a label field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, LabelQltyTest."Test Value Type"::"Value Type Label", LabelQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Inspection generation rules are cleared and prioritized rule is created
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LabelQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Blank value returns blank result (labels are not resultd)
        LibraryAssert.AreEqual('', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, LabelQltyTest."Test Value Type", '', LabelQltyTest."Case Sensitive"), 'blank value should result in a blank result for labels.');

        // [THEN] Any value returns blank result (labels are not resultd)
        LibraryAssert.AreEqual('', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, LabelQltyTest."Test Value Type", 'anything at all is ignored.', LabelQltyTest."Case Sensitive"), 'with a label, it is always a blank result.');
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Integer()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result for integer field with template-level result conditions overriding field-level conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyTest."Test Value Type"::"Value Type Integer", NumericalMeasureQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Field-level result condition is set to 4..5 for PASS result
        NumericalMeasureQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '4..5', true);

        // [GIVEN] Template-level result condition is modified to 6..7 for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] FAIL result condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", NumericalMeasureQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '', NumericalMeasureQltyTest."Case Sensitive"), 'blank value');
        // [THEN] Value 6 (minimum of range) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '6', NumericalMeasureQltyTest."Case Sensitive"), 'min value inspection line result');
        // [THEN] Value 7 (maximum of range) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '7', NumericalMeasureQltyTest."Case Sensitive"), 'max value inspection line result');
        // [THEN] Value 8 (exceeding maximum) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '8', NumericalMeasureQltyTest."Case Sensitive"), 'slightly exceeding max inspection line result');
        // [THEN] Value 5 (below minimum) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '5', NumericalMeasureQltyTest."Case Sensitive"), 'slightly before min inspection line result');
        // [THEN] Value 6 (re-inspection pass value) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '6', NumericalMeasureQltyTest."Case Sensitive"), 'pass value.');
        // [THEN] Blank value is not treated as zero and evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '', NumericalMeasureQltyTest."Case Sensitive"), 'ensure that blank is not treated as a zero - integer.');
        // [THEN] Zero value is not treated as blank and evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '0', NumericalMeasureQltyTest."Case Sensitive"), 'ensure that zero is not treated as a blank - Integer');

        // [THEN] Non-integer value (7.0001) causes an error
        ClearLastError();
        asserterror LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, NumericalMeasureQltyTest."Test Value Type", '7.0001', NumericalMeasureQltyTest."Case Sensitive"), 'should error, value is not an integer.');
        LibraryAssert.ExpectedError(Expected1Err);
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_Text()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        SanityCheckQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        DatabaseIsCaseSensitive: Boolean;
    begin
        // [SCENARIO] Evaluate result for text field with template-level conditions overriding field-level, testing case sensitivity and blank result validation

        // [GIVEN] No blank results exist in the system initially
        DatabaseIsCaseSensitive := IsDatabaseCaseSensitive();
        SanityCheckQltyInspectionResult.Reset();
        SanityCheckQltyInspectionResult.SetFilter(Code, '=''''');
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - a');
        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured and no blank results created
        QltyInspectionUtility.EnsureBasicSetupExists(false);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - b');
        // [GIVEN] An inspection template with a text field is created and no blank results created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyTest."Test Value Type"::"Value Type Text", TextQltyTest, QltyInspectionTemplateLine);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - c');
        // [GIVEN] Field-level result condition is set to 'A|B|C' for PASS result
        TextQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), 'A|B|C', true);

        // [GIVEN] Template-level result condition is modified to 'D|E' for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, 'D|E');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        // [GIVEN] Prioritized rule is created and no blank results created
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - d');

        // [GIVEN] A production order is generated
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        // [GIVEN] Production order is retrieved and Inspection is created with no blank results
        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - e');
        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line and test-level result conditions are retrieved with no blank results
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", TextQltyTest.Code);
        QltyInspectionLine.FindFirst();
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - f');
        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] Result is evaluated with blank value
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - g');
        // [THEN] Result is INPROGRESS for blank value and no blank results created
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", '', TextQltyTest."Case Sensitive"), 'blank value');
        LibraryAssert.AreEqual(0, SanityCheckQltyInspectionResult.Count(), 'should be no blank results - gb');

        // [THEN] Value 'D' (in template condition) evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'D', TextQltyTest."Case Sensitive"), 'first text-method1');
        // [THEN] Value 'D' evaluates to PASS using alternative evaluation method (no line parameter)
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyIResultConditConf, TextQltyTest."Test Value Type", 'D', TextQltyTest."Case Sensitive"), 'first text method2 test with no line.');
        // [THEN] Value 'e' (lowercase) with insensitive comparison evaluates to PASS
        LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'e', TextQltyTest."Case Sensitive"::Insensitive), 'second text lowercase insensitive ');
        if DatabaseIsCaseSensitive then
            // [THEN] Value 'e' (lowercase) with sensitive comparison evaluates to FAIL
            LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'e', TextQltyTest."Case Sensitive"::Sensitive), 'second text lowercase sensitive')
        else
            // [THEN] Value 'e' (lowercase) with sensitive comparison evaluates to PASS
            LibraryAssert.AreEqual('PASS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'e', TextQltyTest."Case Sensitive"::Sensitive), 'second text lowercase sensitive');
        // [THEN] Value 'A' (in field-level condition) evaluates to FAIL (template override works)
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'A', TextQltyTest."Case Sensitive"), 'original field pass, which should be overwritten by the template.');
        // [THEN] Value 'c' (lowercase field-level condition) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'c', TextQltyTest."Case Sensitive"), 'original field lowercase');
        // [THEN] Value 'C' (field-level condition) evaluates to FAIL (template override works)
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'C', TextQltyTest."Case Sensitive"), 'original field');
        // [THEN] Value 'Monkey' (not in any condition) evaluates to FAIL
        LibraryAssert.AreEqual('FAIL', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", 'Monkey', TextQltyTest."Case Sensitive"), 'A value not in any condition.');
        // [THEN] Blank value re-inspectioned evaluates to INPROGRESS
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionUtility.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, TextQltyTest."Test Value Type", '', TextQltyTest."Case Sensitive"), 'ensure that blank is not treated as a zero - integer.');
    end;

    [Test]
    procedure EvaluateResult_BasicExpressions_Replacement_Decimal()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        UsesReferenceQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyTest: Record "Qlty. Test";
        UsesReferenceInPassConditionQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        UsesReferenceQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Evaluate result using expression with field reference replacement for dynamic decimal range validation

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with two decimal fields is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureReferenceQltyTest, OriginalQltyInspectionTemplateLine);

        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, UsesReferenceInPassConditionQltyTest."Test Value Type"::"Value Type Decimal", UsesReferenceInPassConditionQltyTest, UsesReferenceQltyInspectionTemplateLine);

        // [GIVEN] First field has template-level result condition set to 6..7 for PASS
        OriginalQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", OriginalQltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Second field has dynamic condition '1..[TestCode]' that references first field's value
        Clear(QltyIResultConditConf);
        UsesReferenceQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", UsesReferenceQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", UsesReferenceQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", UsesReferenceQltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, StrSubstno('1..[%1]', NumericalMeasureReferenceQltyTest.Code));
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line for second field (uses reference) is retrieved
        UsesReferenceQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        UsesReferenceQltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        UsesReferenceQltyInspectionLine.SetRange("Test Code", UsesReferenceInPassConditionQltyTest.Code);
        UsesReferenceQltyInspectionLine.FindFirst();

        // [GIVEN] Inspection-level result conditions are retrieved
        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", UsesReferenceQltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", UsesReferenceQltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", UsesReferenceQltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", UsesReferenceQltyInspectionLine."Test Code");

        // [GIVEN] Reference field value is set to 6
        QltyInspectionHeader.SetTestValue(NumericalMeasureReferenceQltyTest."Code", '6');

        // [WHEN] Result is evaluated with value 6 (at max of dynamic range 1..6)
        // [THEN] Result evaluates to PASS
        LibraryAssert.AreEqual(
            'PASS',
            QltyInspectionUtility.EvaluateResult(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            QltyIResultConditConf,
             UsesReferenceInPassConditionQltyTest."Test Value Type",
             '6',
             UsesReferenceInPassConditionQltyTest."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 1 (at min of dynamic range) evaluates to PASS
        LibraryAssert.AreEqual(
            'PASS',
            QltyInspectionUtility.EvaluateResult(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            QltyIResultConditConf,
             UsesReferenceInPassConditionQltyTest."Test Value Type",
             '1',
             UsesReferenceInPassConditionQltyTest."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 7 (exceeding dynamic range max) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyInspectionUtility.EvaluateResult(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            QltyIResultConditConf,
            UsesReferenceInPassConditionQltyTest."Test Value Type",
            '7',
            UsesReferenceInPassConditionQltyTest."Case Sensitive"
            ),
            'should be using a condition of 1..6');
        // [THEN] Value 0.9 (below dynamic range min) evaluates to FAIL
        LibraryAssert.AreEqual(
            'FAIL',
            QltyInspectionUtility.EvaluateResult(
            QltyInspectionHeader,
            UsesReferenceQltyInspectionLine,
            QltyIResultConditConf,
            UsesReferenceInPassConditionQltyTest."Test Value Type",
            '0.9',
            UsesReferenceInPassConditionQltyTest."Case Sensitive"
            ),
            'should be using a condition of 1..6');
    end;

    [Test]
    procedure GetTestLineConfigFilters()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        UsesReferenceQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyTest: Record "Qlty. Test";
        UsesReferenceInPassConditionQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        UsesReferenceQltyInspectionLine: Record "Qlty. Inspection Line";
        ExpectedQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ActualQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Verify GetInspectionLineConfigFilters returns correct filters for inspection line-specific result conditions with expression replacement

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureReferenceQltyTest, OriginalQltyInspectionTemplateLine);

        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, UsesReferenceInPassConditionQltyTest."Test Value Type"::"Value Type Decimal", UsesReferenceInPassConditionQltyTest, UsesReferenceQltyInspectionTemplateLine);
        OriginalQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", OriginalQltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        Clear(ToLoadToLoadToUseAsATemplateQltyIResultConditConf);
        UsesReferenceQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", UsesReferenceQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", UsesReferenceQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", UsesReferenceQltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, StrSubstno('1..{2+[%1]}', NumericalMeasureReferenceQltyTest.Code));
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line for second field is retrieved with expression '1..{2+[TestCode]}'
        UsesReferenceQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        UsesReferenceQltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        UsesReferenceQltyInspectionLine.SetRange("Test Code", UsesReferenceInPassConditionQltyTest.Code);
        UsesReferenceQltyInspectionLine.FindFirst();

        // [GIVEN] Expected filters are manually configured for inspection line-specific result conditions
        ExpectedQltyIResultConditConf.Reset();
        ExpectedQltyIResultConditConf.SetRange("Condition Type", ExpectedQltyIResultConditConf."Condition Type"::Inspection);
        ExpectedQltyIResultConditConf.SetRange("Target Code", UsesReferenceQltyInspectionLine."Inspection No.");
        ExpectedQltyIResultConditConf.SetRange("Target Re-inspection No.", UsesReferenceQltyInspectionLine."Re-inspection No.");
        ExpectedQltyIResultConditConf.SetRange("Target Line No.", UsesReferenceQltyInspectionLine."Line No.");
        ExpectedQltyIResultConditConf.SetRange("Test Code", UsesReferenceQltyInspectionLine."Test Code");

        // [WHEN] GetInspectionLineConfigFilters is called to retrieve actual filters
        QltyInspectionUtility.GetInspectionLineConfigFilters(UsesReferenceQltyInspectionLine, ActualQltyIResultConditConf);
        // [THEN] Actual filters match expected filters for inspection line result conditions
        LibraryAssert.AreEqual(ExpectedQltyIResultConditConf.GetView(), ActualQltyIResultConditConf.GetView(), 'result condition filters should match.');
    end;

    [Test]
    procedure GetTemplateLineConfigFilters()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyTest: Record "Qlty. Test";
        ExpectedQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ActualQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Verify GetTemplateLineConfigFilters returns correct filters for template line-specific result conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureReferenceQltyTest, OriginalQltyInspectionTemplateLine);
        // [GIVEN] Template-level result condition is set to 6..7 for PASS result
        OriginalQltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", OriginalQltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Expected filters are manually configured for template line-specific result conditions
        ExpectedQltyIResultConditConf.Reset();
        ExpectedQltyIResultConditConf.SetRange("Condition Type", ExpectedQltyIResultConditConf."Condition Type"::Template);
        ExpectedQltyIResultConditConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Template Code");
        ExpectedQltyIResultConditConf.SetRange("Target Line No.", OriginalQltyInspectionTemplateLine."Line No.");
        ExpectedQltyIResultConditConf.SetRange("Test Code", OriginalQltyInspectionTemplateLine."Test Code");

        // [WHEN] GetTemplateLineConfigFilters is called to retrieve actual filters
        GetTemplateLineConfigFilters(OriginalQltyInspectionTemplateLine, ActualQltyIResultConditConf);
        // [THEN] Actual filters match expected filters for template line result conditions
        LibraryAssert.AreEqual(ExpectedQltyIResultConditConf.GetView(), ActualQltyIResultConditConf.GetView(), 'result condition filters should match for template line..');
    end;

    [Test]
    procedure GetFieldConfigFilters()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureReferenceQltyTest: Record "Qlty. Test";
        ExpectedQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ActualQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Verify GetFieldConfigFilters returns correct filters for field-specific result conditions

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureReferenceQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureReferenceQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Expected filters are set for field-level result conditions
        ExpectedQltyIResultConditConf.Reset();
        ExpectedQltyIResultConditConf.SetRange("Condition Type", ExpectedQltyIResultConditConf."Condition Type"::Test);
        ExpectedQltyIResultConditConf.SetRange("Target Code", OriginalQltyInspectionTemplateLine."Test Code");
        ExpectedQltyIResultConditConf.SetRange("Test Code", OriginalQltyInspectionTemplateLine."Test Code");

        // [WHEN] GetFieldConfigFilters is called to retrieve actual filters
        GetFieldConfigFilters(NumericalMeasureReferenceQltyTest, ActualQltyIResultConditConf);
        // [THEN] Actual filters match expected filters for field-level result conditions
        LibraryAssert.AreEqual(ExpectedQltyIResultConditConf.GetView(), ActualQltyIResultConditConf.GetView(), 'result condition filters should match for field');
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Decimal()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DecimalQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that decimal field default values must fall within allowable values range (1..3)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a decimal field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, DecimalQltyTest."Test Value Type"::"Value Type Decimal", DecimalQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for decimal field are set to range 1..3
        DecimalQltyTest."Allowable Values" := '1..3';
        DecimalQltyTest.Modify();

        // [WHEN] Default value is set to 3 (maximum of range)
        DecimalQltyTest."Default Value" := '3';
        // [THEN] Validation passes
        QltyInspectionUtility.ValidateAllowableValuesOnTest(DecimalQltyTest);
        // [THEN] Default value 4 (exceeding maximum) causes error
        ClearLastError();
        DecimalQltyTest."Default Value" := '4';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DecimalQltyTest);
        // [THEN] Default value 0.9999 (below minimum) causes error
        ClearLastError();
        DecimalQltyTest."Default Value" := '0.9999';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DecimalQltyTest);
        // [THEN] Default value 1 (minimum of range) passes validation
        ClearLastError();
        DecimalQltyTest."Default Value" := '1';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(DecimalQltyTest);

        // [THEN] Non-numeric default value causes error
        ClearLastError();
        DecimalQltyTest."Default Value" := 'this is not a number';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DecimalQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Option()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        OptionListQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that option field default values must be one of the allowable comma-delimited options (A,B,C,D)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with an option field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, OptionListQltyTest."Test Value Type"::"Value Type Option", OptionListQltyTest, OriginalQltyInspectionTemplateLine);
        // [GIVEN] Allowable values for option field are set to 'A,B,C,D'
        OptionListQltyTest.Description := '';
        OptionListQltyTest."Allowable Values" := 'A,B,C,D';
        OptionListQltyTest.Modify();

        // [THEN] Default value 'AA' (not in list) causes error
        ClearLastError();
        OptionListQltyTest."Default Value" := 'AA';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);

        // [THEN] Default value 'E' (not in list) causes error
        ClearLastError();
        OptionListQltyTest."Default Value" := 'E';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);

        // [THEN] Default value 'AB' (not in list) causes error
        ClearLastError();
        OptionListQltyTest."Default Value" := 'AB';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);

        // [THEN] Default value 'A' (in list) passes validation
        ClearLastError();
        OptionListQltyTest."Default Value" := 'A';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);
        // [THEN] Default value 'B' (in list) passes validation
        OptionListQltyTest."Default Value" := 'B';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);
        // [THEN] Default value 'D' (in list) passes validation
        OptionListQltyTest."Default Value" := 'D';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(OptionListQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Integer()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        IntegerQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that integer field default values must fall within allowable values range (1..3)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, IntegerQltyTest."Test Value Type"::"Value Type Integer", IntegerQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for integer field are set to range 1..3
        IntegerQltyTest."Allowable Values" := '1..3';
        IntegerQltyTest.Modify();

        // [WHEN] Default value is set to 3 (maximum of range)
        IntegerQltyTest."Default Value" := '3';
        // [THEN] Validation passes
        QltyInspectionUtility.ValidateAllowableValuesOnTest(IntegerQltyTest);
        // [THEN] Default value 4 (exceeding maximum) causes error
        ClearLastError();
        IntegerQltyTest."Default Value" := '4';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(IntegerQltyTest);
        // [THEN] Default value 0 (below minimum) causes error
        ClearLastError();
        IntegerQltyTest."Default Value" := '0';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(IntegerQltyTest);
        // [THEN] Default value 1 (minimum of range) passes validation
        ClearLastError();
        IntegerQltyTest."Default Value" := '1';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(IntegerQltyTest);
        // [THEN] Non-integer default value causes error
        ClearLastError();
        IntegerQltyTest."Default Value" := 'this is not an integer';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(IntegerQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Text()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TextQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that text field default values must be one of the allowable pipe-delimited options (A|B|C)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a text field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyTest."Test Value Type"::"Value Type Text", TextQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for text field are set to 'A|B|C'
        TextQltyTest."Allowable Values" := 'A|B|C';
        TextQltyTest.Modify();

        // [WHEN] Default value is set to 'A' (in list)
        TextQltyTest."Default Value" := 'A';
        // [THEN] Validation passes
        QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest);
        // [THEN] Default value 'D' (not in list) causes error
        ClearLastError();
        TextQltyTest."Default Value" := 'D';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest);
        // [THEN] Default value '0' (not in list) causes error
        ClearLastError();
        TextQltyTest."Default Value" := '0';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest);
        // [THEN] Default value 'B' (in list) passes validation
        ClearLastError();
        TextQltyTest."Default Value" := 'B';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Date()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that date field default values must match the exact allowable date value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a date field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, DateQltyTest."Test Value Type"::"Value Type Date", DateQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for date field is set to '2001-02-03'
        DateQltyTest."Allowable Values" := '2001-02-03';
        DateQltyTest.Modify();

        // [WHEN] Default value is set to '2001-02-03' (exact match)
        DateQltyTest."Default Value" := '2001-02-03';
        // [THEN] Validation passes
        QltyInspectionUtility.ValidateAllowableValuesOnTest(DateQltyTest);
        // [THEN] Default value '2001-02-04' (different date) causes error
        ClearLastError();
        DateQltyTest."Default Value" := '2001-02-04';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateQltyTest);
        // [THEN] Default value '2001-01-01' (different date) causes error
        ClearLastError();
        DateQltyTest."Default Value" := '2001-01-01';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateQltyTest);
        // [THEN] Non-date default value causes error
        ClearLastError();
        DateQltyTest."Default Value" := 'this is not a date';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_DateTime()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DateTimeQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that datetime field default values must match the exact allowable datetime value

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a datetime field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, DateTimeQltyTest."Test Value Type"::"Value Type DateTime", DateTimeQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for datetime field is set to '2001-02-03 04:05:06'
        DateTimeQltyTest."Allowable Values" := '2001-02-03 04:05:06';
        DateTimeQltyTest.Modify();

        // [WHEN] Default value is set to '2001-02-03 04:05:06' (exact match)
        DateTimeQltyTest."Default Value" := '2001-02-03 04:05:06';
        // [THEN] Validation passes
        QltyInspectionUtility.ValidateAllowableValuesOnTest(DateTimeQltyTest);
        // [THEN] Default value '2001-02-03 04:05:07' (one second later) causes error
        ClearLastError();
        DateTimeQltyTest."Default Value" := '2001-02-03 04:05:07';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateTimeQltyTest);
        // [THEN] Default value '2001-02-03 04:05:00' (different time) causes error
        ClearLastError();
        DateTimeQltyTest."Default Value" := '2001-02-03 04:05:00';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateTimeQltyTest);
        // [THEN] Non-datetime default value causes error
        ClearLastError();
        DateTimeQltyTest."Default Value" := 'this is not a date time.';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(DateTimeQltyTest);
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_Boolean()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        BooleanQltyTest: Record "Qlty. Test";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Validate that boolean field default values must match the allowable boolean value and accept equivalent representations

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a boolean field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyTest."Test Value Type"::"Value Type Boolean", BooleanQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable value for boolean field is set to 'Yes'
        BooleanQltyTest."Allowable Values" := 'Yes';
        BooleanQltyTest.Modify();

        // [WHEN] Default value is set to 'Yes' and equivalent true representations
        BooleanQltyTest."Default Value" := 'Yes';
        // [THEN] 'Yes' passes validation
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] 'True' (equivalent to Yes) passes validation
        BooleanQltyTest."Default Value" := 'True';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] '1' (equivalent to Yes) passes validation
        BooleanQltyTest."Default Value" := '1';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] 'On' (equivalent to Yes) passes validation
        BooleanQltyTest."Default Value" := 'On';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] 'No' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyTest."Default Value" := 'No';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] 'False' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyTest."Default Value" := 'False';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] '0' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyTest."Default Value" := '0';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] 'Off' (not matching Yes) causes error
        ClearLastError();
        BooleanQltyTest."Default Value" := 'Off';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] Non-boolean value causes error
        ClearLastError();
        BooleanQltyTest."Default Value" := 'this is not a boolean';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);

        // [GIVEN] A new boolean field with blank allowable values (accepts any boolean value)
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, BooleanQltyTest."Test Value Type"::"Value Type Boolean", BooleanQltyTest, OriginalQltyInspectionTemplateLine);

        BooleanQltyTest."Allowable Values" := '';
        BooleanQltyTest.Modify();
        // [THEN] Blank default value passes validation
        BooleanQltyTest."Default Value" := '';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] All true representations pass validation when allowable values are blank
        BooleanQltyTest."Default Value" := 'Yes';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := 'True';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := '1';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := 'On';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] All false representations pass validation when allowable values are blank
        BooleanQltyTest."Default Value" := 'No';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := 'False';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := '0';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        BooleanQltyTest."Default Value" := 'Off';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        // [THEN] Non-boolean value is converted to 'No'
        BooleanQltyTest."Default Value" := 'this is not a boolean';
        QltyInspectionUtility.ValidateAllowableValuesOnTest(BooleanQltyTest);
        LibraryAssert.AreEqual('No', BooleanQltyTest."Default Value", 'Not-yes should have been converted to No');
    end;

    [Test]
    procedure ValidateAllowableValuesOnField_WithInspectionContext()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OriginalQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TextQltyTest: Record "Qlty. Test";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate that field default values are validated with Inspection context, accepting valid values and rejecting invalid ones

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a text field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, TextQltyTest."Test Value Type"::"Value Type Text", TextQltyTest, OriginalQltyInspectionTemplateLine);

        // [GIVEN] Allowable values for text field are set to 'A|B|C'
        TextQltyTest."Allowable Values" := 'A|B|C';
        TextQltyTest.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved for test context validation
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", TextQltyTest.Code);
        QltyInspectionLine.FindFirst();

        // [WHEN] Default value is set to 'A' (in allowable values)
        TextQltyTest."Default Value" := 'A';
        // [THEN] Validation passes with inspection header context
        QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest, QltyInspectionHeader, QltyInspectionLine);
        // [THEN] Validation passes with inspection header and inspection line context
        QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest, QltyInspectionHeader, QltyInspectionLine);

        // [THEN] Default value 'D' (not in allowable values) causes error with inspection header context
        ClearLastError();
        TextQltyTest."Default Value" := 'D';
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest, QltyInspectionHeader, QltyInspectionLine);
        // [THEN] Default value 'D' causes error with inspection header and inspection line context
        asserterror QltyInspectionUtility.ValidateAllowableValuesOnTest(TextQltyTest, QltyInspectionHeader, QltyInspectionLine);
        ClearLastError();
    end;

    [Test]
    procedure EvaluateResult_WithOptionalInspectionLine_OnRun()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Test OnRun method of result evaluation codeunit with integer field values and error handling

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with an integer field is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyTest."Test Value Type"::"Value Type Integer", NumericalMeasureQltyTest, QltyInspectionTemplateLine);

        // [GIVEN] Field-level result condition is set to 4..5 for PASS result
        NumericalMeasureQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '4..5', true);

        // [GIVEN] Template-level result condition is modified to 6..7 for PASS result
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] FAIL result condition is set to >=0
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", 'FAIL');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '>=0');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();

        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved and result conditions are set up
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", NumericalMeasureQltyTest.Code);
        QltyInspectionLine.FindFirst();

        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        // [WHEN] OnRun is called with blank test value
        QltyInspectionLine."Test Value" := '';
        QltyInspectionLine.Modify(false);
        Commit();
        // [THEN] OnRun returns true and result is INPROGRESS
        LibraryAssert.AreEqual(true, QltyInspectionUtility.RunResultEvaluation(QltyInspectionLine), 'OnRun should have returned true for validation. blank.');
        LibraryAssert.AreEqual('INPROGRESS', QltyInspectionLine."Result Code", 'blank value via onrun.');

        // [THEN] OnRun with value 6 (minimum) returns true and result is PASS
        QltyInspectionLine."Test Value" := '6';
        LibraryAssert.AreEqual(true, QltyInspectionUtility.RunResultEvaluation(QltyInspectionLine), 'OnRun should have returned true for validation. min');
        LibraryAssert.AreEqual('PASS', QltyInspectionLine."Result Code", 'min value via onrun.');

        // [THEN] OnRun with invalid value 'not a number' returns false
        QltyInspectionLine."Test Value" := 'not a number';
        LibraryAssert.AreEqual(false, QltyInspectionUtility.RunResultEvaluation(QltyInspectionLine), 'should not have evaluated to a number.');

        // [THEN] OnRun with value 8 (exceeding max) returns true and result is FAIL
        QltyInspectionLine."Test Value" := '8';
        LibraryAssert.AreEqual(true, QltyInspectionUtility.RunResultEvaluation(QltyInspectionLine), 'OnRun should have returned true for validation. Fail');
        LibraryAssert.AreEqual('FAIL', QltyInspectionLine."Result Code", 'exceeded value..');

        // [THEN] OnRun with decimal value '7.0001' returns false with expected error
        ClearLastError();
        QltyInspectionLine."Test Value" := '7.0001';
        LibraryAssert.AreEqual(false, QltyInspectionUtility.RunResultEvaluation(QltyInspectionLine), 'should not have evaluated to an integer.');
        LibraryAssert.AreEqual(StrSubstNo(Expected2Err, NumericalMeasureQltyTest.Description), GetLastErrorText(), 'error text from failed run.');
    end;

    [Test]
    procedure ValidateInspectionLine()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        NumericalMeasureQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        NumericMeasureQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate inspection line values against allowable values range for decimal field with result evaluation

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with a decimal field and allowable values range 0..12345 is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, NumericalMeasureQltyTest."Test Value Type"::"Value Type Decimal", NumericalMeasureQltyTest, QltyInspectionTemplateLine);
        NumericalMeasureQltyTest.Validate("Allowable Values", '0..12345');
        NumericalMeasureQltyTest.Modify(false);

        // [GIVEN] Field-level result condition is set to 4..5 for PASS result
        NumericalMeasureQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), '4..5', true);
        // [GIVEN] Template-level result condition is modified to 6..7 for PASS result
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, '6..7');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        // [GIVEN] Prioritized rule is created for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] Inspection line is retrieved for validation
        NumericMeasureQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        NumericMeasureQltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        NumericMeasureQltyInspectionLine.SetRange("Test Code", NumericalMeasureQltyTest.Code);
        NumericMeasureQltyInspectionLine.FindFirst();

        // [WHEN] ValidateQltyInspectionLine is called with blank value
        NumericMeasureQltyInspectionLine."Test Value" := '';
        NumericMeasureQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', NumericMeasureQltyInspectionLine."Result Code", 'blank value');

        // [THEN] ValidateInspectionLineWithAllowableValues also returns INPROGRESS for blank value
        NumericMeasureQltyInspectionLine."Test Value" := '';
        NumericMeasureQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateInspectionLineWithAllowableValues(NumericMeasureQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('INPROGRESS', NumericMeasureQltyInspectionLine."Result Code", 'blank value with testing allowable values.');

        // [THEN] Value 6 (minimum of result range) evaluates to PASS
        NumericMeasureQltyInspectionLine."Test Value" := '6';
        NumericMeasureQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', NumericMeasureQltyInspectionLine."Result Code", 'min value inspection line result');

        // [THEN] Value 7.0001 (exceeding maximum) evaluates to FAIL
        NumericMeasureQltyInspectionLine."Test Value" := '7.0001';
        NumericMeasureQltyInspectionLine.Modify();

        QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Result Code", 'slightly exceeding max inspection line result');
        QltyInspectionUtility.ValidateInspectionLineWithAllowableValues(NumericMeasureQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Result Code", 'slightly exceeding max inspection line result');

        // [THEN] Value 5.999999 (below minimum) evaluates to FAIL
        NumericMeasureQltyInspectionLine."Test Value" := '5.999999';
        NumericMeasureQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', NumericMeasureQltyInspectionLine."Result Code", 'slightly before min inspection line result');
        // [THEN] Value 6.999999 (near maximum) evaluates to PASS
        NumericMeasureQltyInspectionLine."Test Value" := '6.999999';
        NumericMeasureQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);

        LibraryAssert.AreEqual('PASS', NumericMeasureQltyInspectionLine."Result Code", 'slightly before min inspection line result');

        // [THEN] Value -1 (outside allowable values range) causes an error
        NumericMeasureQltyInspectionLine."Test Value" := '-1';
        NumericMeasureQltyInspectionLine.Modify(false);

        ClearLastError();
        asserterror QltyInspectionUtility.ValidateQltyInspectionLine(NumericMeasureQltyInspectionLine);

        LibraryAssert.ExpectedError(StrSubstNo(Expected3Err, NumericMeasureQltyInspectionLine."Description"));
    end;

    [Test]
    procedure ValidateInspectionLine_OptionList()
    var
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        OptionListMeasureQltyTest: Record "Qlty. Test";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        OptionListQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Validate inspection line values for option field with allowable values (A,B,C,D,E) and template-level result conditions (C|D for PASS)

        // [GIVEN] Quality management setup is initialized with basic configuration
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Basic quality setup is ensured
        QltyInspectionUtility.EnsureBasicSetupExists(false);

        // [GIVEN] An inspection template with an option field is created with allowable values 'A,B,C,D,E'
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(QltyInspectionTemplateHdr, OptionListMeasureQltyTest."Test Value Type"::"Value Type Option", OptionListMeasureQltyTest, QltyInspectionTemplateLine);
        OptionListMeasureQltyTest.Description := '';
        OptionListMeasureQltyTest.Validate("Allowable Values", 'A,B,C,D,E');
        OptionListMeasureQltyTest.Modify(false);
        QltyInspectionTemplateLine.Description := '';
        QltyInspectionTemplateLine.Modify(false);

        // [GIVEN] Field-level result condition is set to 'A|B' for PASS result
        OptionListMeasureQltyTest.SetResultCondition(QltyInspectionUtility.GetDefaultPassResult(), 'A|B', true);
        // [GIVEN] Template-level result condition is modified to 'C|D' for PASS result (overrides field-level)
        QltyInspectionTemplateLine.EnsureResultsExist(false);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Condition Type", ToLoadToLoadToUseAsATemplateQltyIResultConditConf."Condition Type"::Template);
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.SetRange("Result Code", QltyInspectionUtility.GetDefaultPassResult());
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.FindFirst();
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Validate(Condition, 'C|D');
        ToLoadToLoadToUseAsATemplateQltyIResultConditConf.Modify();
        // [GIVEN] Inspection generation rules are cleared and prioritized rule is created
        QltyInspectionGenRule.DeleteAll(false);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order is generated and Inspection is created with specific template
        QltyProdOrderGenerator.GenerateItemSourceProdOrders(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);

        QltyInspectionHeader.Reset();
        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariantAndTemplate(ProdOrderRoutingLine, false, QltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] Inspection line for option field is retrieved
        OptionListQltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        OptionListQltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        OptionListQltyInspectionLine.SetRange("Test Code", OptionListMeasureQltyTest.Code);
        OptionListQltyInspectionLine.FindFirst();

        // [WHEN] ValidateQltyInspectionLine is called with blank value
        OptionListQltyInspectionLine."Test Value" := '';
        OptionListQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(OptionListQltyInspectionLine);
        // [THEN] Result is INPROGRESS for blank value
        LibraryAssert.AreEqual('INPROGRESS', OptionListQltyInspectionLine."Result Code", 'blank value');

        // [THEN] ValidateInspectionLineWithAllowableValues also returns INPROGRESS for blank value
        OptionListQltyInspectionLine."Test Value" := '';
        OptionListQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateInspectionLineWithAllowableValues(OptionListQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.AreEqual('INPROGRESS', OptionListQltyInspectionLine."Result Code", 'blank value with testing allowable values.');

        // [THEN] Value 'C' (first PASS option in template condition) evaluates to PASS
        OptionListQltyInspectionLine."Test Value" := 'C';
        OptionListQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', OptionListQltyInspectionLine."Result Code", 'one of 2 options');

        // [THEN] Value 'D' (second PASS option in template condition) evaluates to PASS
        OptionListQltyInspectionLine."Test Value" := 'D';
        OptionListQltyInspectionLine.Modify();
        QltyInspectionUtility.ValidateQltyInspectionLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('PASS', OptionListQltyInspectionLine."Result Code", 'two of two options.');

        // [THEN] Value 'A' (in allowable values but not in template PASS condition) evaluates to FAIL
        OptionListQltyInspectionLine."Test Value" := 'A';
        OptionListQltyInspectionLine.Modify();

        QltyInspectionUtility.ValidateQltyInspectionLine(OptionListQltyInspectionLine);
        LibraryAssert.AreEqual('FAIL', OptionListQltyInspectionLine."Result Code", 'allowed but failing.');

        // [THEN] Value 'F' (not in allowable values) causes an error
        ClearLastError();
        OptionListQltyInspectionLine."Test Value" := 'F';
        asserterror QltyInspectionUtility.ValidateInspectionLineWithAllowableValues(OptionListQltyInspectionLine, QltyInspectionHeader, true, true);
        LibraryAssert.ExpectedError(StrSubstNo(Expected4Err, OptionListQltyInspectionLine."Test Code"));
    end;

    local procedure GetTemplateLineConfigFilters(var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; var OutTemplateLineQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    begin
        OutTemplateLineQltyIResultConditConf.SetRange("Condition Type", OutTemplateLineQltyIResultConditConf."Condition Type"::Template);
        OutTemplateLineQltyIResultConditConf.SetRange("Target Code", QltyInspectionTemplateLine."Template Code");
        OutTemplateLineQltyIResultConditConf.SetRange("Target Re-inspection No.");
        OutTemplateLineQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionTemplateLine."Line No.");
        OutTemplateLineQltyIResultConditConf.SetRange("Test Code", QltyInspectionTemplateLine."Test Code");
    end;

    local procedure GetFieldConfigFilters(var QltyTest: Record "Qlty. Test"; var OutTemplateLineQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    begin
        OutTemplateLineQltyIResultConditConf.SetRange("Condition Type", OutTemplateLineQltyIResultConditConf."Condition Type"::Test);
        OutTemplateLineQltyIResultConditConf.SetRange("Target Code", QltyTest.Code);
        OutTemplateLineQltyIResultConditConf.SetRange("Target Re-inspection No.");
        OutTemplateLineQltyIResultConditConf.SetRange("Target Line No.");
        OutTemplateLineQltyIResultConditConf.SetRange("Test Code", QltyTest.Code);
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
