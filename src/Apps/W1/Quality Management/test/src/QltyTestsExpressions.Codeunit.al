// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139961 "Qlty. Tests - Expressions"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    var
        LibraryAssert: Codeunit "Library Assert";
        LookupExpressionTok: Label '[LOOKUP(Location;Code;Name=%1)]', Comment = '%1=the location name', Locked = true;
        LocationNameTok: Label 'Test Location';
        TemplateTok: Label '[template code]', Locked = true;
        TemplateCapitalizedTok: Label '[Template Code]', Locked = true;
        TemplateUppercaseTok: Label '[TEMPLATE CODE]', Locked = true;

    local procedure GetRegionalDecimalSeparator(): Text
    begin
        exit(Format(1.1) [2]);
    end;

    local procedure GetRegionalThousandsSeparator(): Text
    begin
        exit(Format(1234.56) [2]);
    end;

    [Test]
    procedure BasicTextExpressions()
    var
        TempIgnoredQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempIgnoredQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate basic text expression evaluation with field name substitution

        // [GIVEN] A temporary quality inspection test header is created with source custom, item, and quantity values
        TempIgnoredQltyInspectionTestHeader."Source Custom 1" := 'A';
        TempIgnoredQltyInspectionTestHeader."Source Item No." := 'B';
        TempIgnoredQltyInspectionTestHeader."Source Quantity (Base)" := 1234;

        // [WHEN] Text expression is evaluated with field name placeholders
        // [THEN] Field values are correctly substituted into the text expression
        LibraryAssert.AreEqual('Turkey A is 1234 B', QltyExpressionMgmt.EvaluateTextExpression('Turkey [Source Custom 1] is [Source Quantity (Base)] [Source Item No.]', TempIgnoredQltyInspectionTestHeader, TempIgnoredQltyInspectionTestLine), 'Basic text replacement with names');
        // [THEN] Non-existent field names in the expression are not replaced
        LibraryAssert.AreEqual('Turkey A is [Quantity (Base)] [Item No.]', QltyExpressionMgmt.EvaluateTextExpression('Turkey [Source Custom 1] is [Quantity (Base)] [Item No.]', TempIgnoredQltyInspectionTestHeader, TempIgnoredQltyInspectionTestLine), 'Basic text replacement from caption will not work.');
    end;

    [Test]
    procedure BasicItemLookup()
    var
        Item: Record Item;
        TempIgnoredQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        // [SCENARIO] Validate text expression evaluation with item record field lookup

        // [GIVEN] A temporary quality inspection test header is created with source custom and quantity values
        TempIgnoredQltyInspectionTestHeader."Source Custom 1" := '2';

        TempIgnoredQltyInspectionTestHeader."Source Quantity (Base)" := 1001;

        // [GIVEN] An item is created with unit cost and description values
        QltyProdOrderGenerator.CreateItem(Item);
        Item."Unit Cost" := 123.45;
        Item."Description 2" := 'turkey apple cheese';
        Item.Modify(false);

        // [GIVEN] The item number is set in the test header
        TempIgnoredQltyInspectionTestHeader."Source Item No." := Item."No.";

        // [WHEN] Text expression is evaluated with item field lookup syntax
        // [THEN] Item field values are correctly retrieved and substituted into the expression
        LibraryAssert.AreEqual('A turkey apple cheese is 123' + GetRegionalDecimalSeparator() + '45',
            QltyExpressionMgmt.EvaluateTextExpression('A [Item:Description 2] is [Item:Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
            'Basic item lookup a');
    end;

    [Test]
    procedure ItemFormatLookups()
    var
        Item: Record Item;
        TempIgnoredQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        // [SCENARIO] Validate text expression evaluation with different formatting options for item field lookups

        // [GIVEN] A temporary quality inspection test header is created with source values
        TempIgnoredQltyInspectionTestHeader."Source Custom 1" := '2';

        TempIgnoredQltyInspectionTestHeader."Source Quantity (Base)" := 1001;

        // [GIVEN] An item is created with a large unit cost value and description
        QltyProdOrderGenerator.CreateItem(Item);
        Item."Unit Cost" := 1234567890.12;
        Item."Description 2" := 'turkey apple cheese';
        Item.Modify(false);

        // [GIVEN] The item number is set in the test header
        TempIgnoredQltyInspectionTestHeader."Source Item No." := Item."No.";

        // [WHEN] Text expression is evaluated with F0 format (standard with thousands separator)
        // [THEN] The value is formatted with thousands separators and decimal separator
        LibraryAssert.AreEqual('F0 A turkey apple cheese is 1' + GetRegionalThousandsSeparator() + '234' + GetRegionalThousandsSeparator() + '567' + GetRegionalThousandsSeparator() + '890' + GetRegionalDecimalSeparator() + '12',
            QltyExpressionMgmt.EvaluateTextExpression('F0 A [Item:Description 2] is [Item(F0):Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
                'Table(F0):field');
        // [WHEN] Text expression is evaluated with F1 format (no thousands separator)
        // [THEN] The value is formatted without thousands separators
        LibraryAssert.AreEqual('F1 A turkey apple cheese is 1234567890' + GetRegionalDecimalSeparator() + '12',
            QltyExpressionMgmt.EvaluateTextExpression('F1 A [Item:Description 2] is [Item(F1):Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
                'Table(F1):field');
        // [WHEN] Text expression is evaluated with F2 format (plain format)
        // [THEN] The value is formatted as a plain decimal number
        LibraryAssert.AreEqual('F2 A turkey apple cheese is 1234567890.12', QltyExpressionMgmt.EvaluateTextExpression('F2 A [Item:Description 2] is [Item(F2):Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
                'Table(F2):field');
        // [WHEN] Text expression is evaluated with F9 format (same as F2, plain format)
        // [THEN] The value is formatted as a plain decimal number
        LibraryAssert.AreEqual('F9 A turkey apple cheese is 1234567890.12', QltyExpressionMgmt.EvaluateTextExpression('F9 A [Item:Description 2] is [Item(F9):Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
                'Table(F9):field');
        // [WHEN] Text expression is evaluated with legacy format syntax (ItemF)
        // [THEN] The legacy syntax still works with standard formatting
        LibraryAssert.AreEqual('(legacy format syntax) A turkey apple cheese is 1' + GetRegionalThousandsSeparator() + '234' + GetRegionalThousandsSeparator() + '567' + GetRegionalThousandsSeparator() + '890' + GetRegionalDecimalSeparator() + '12',
            QltyExpressionMgmt.EvaluateTextExpression('(legacy format syntax) A [Item:Description 2] is [ItemF:Unit Cost]', TempIgnoredQltyInspectionTestHeader, true),
                'TableF:field');
    end;

    [Test]
    procedure FormatNumberFunction()
    var
        Item: Record Item;
        TempIgnoredQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        // [SCENARIO] Validate the FORMATNUM function for formatting numeric values in text expressions

        // [GIVEN] A temporary quality inspection test header is created with source values
        TempIgnoredQltyInspectionTestHeader."Source Custom 1" := '2';

        TempIgnoredQltyInspectionTestHeader."Source Quantity (Base)" := 1001;

        // [GIVEN] An item is created with a large unit cost value
        QltyProdOrderGenerator.CreateItem(Item);
        Item."Unit Cost" := 1234567890.12;
        Item."Description 2" := 'turkey apple cheese';
        Item.Modify(false);

        // [GIVEN] The item number is set in the test header
        TempIgnoredQltyInspectionTestHeader."Source Item No." := Item."No.";

        // [WHEN] FORMATNUM function is used with format 0 (standard with thousands separator)
        // [THEN] The value is formatted with thousands separators
        LibraryAssert.AreEqual('F0 A turkey apple cheese is 1' + GetRegionalThousandsSeparator() + '234' + GetRegionalThousandsSeparator() + '567' + GetRegionalThousandsSeparator() + '890' + GetRegionalDecimalSeparator() + '12',
            QltyExpressionMgmt.EvaluateTextExpression('F0 A [Item:Description 2] is [FORMATNUM([Item:Unit Cost];0;)]', TempIgnoredQltyInspectionTestHeader, true),
                'FORMATNUM-0');
        // [WHEN] FORMATNUM function is used with format 1 (no thousands separator)
        // [THEN] The value is formatted without thousands separators
        LibraryAssert.AreEqual('F1 A turkey apple cheese is 1234567890' + GetRegionalDecimalSeparator() + '12',
            QltyExpressionMgmt.EvaluateTextExpression('F1 A [Item:Description 2] is [FORMATNUM([Item:Unit Cost];1;)]', TempIgnoredQltyInspectionTestHeader, true),
            'FORMATNUM-1');
        // [WHEN] FORMATNUM function is used with format 2 (plain format)
        // [THEN] The value is formatted as a plain decimal number
        LibraryAssert.AreEqual('F2 A turkey apple cheese is 1234567890.12', QltyExpressionMgmt.EvaluateTextExpression('F2 A [Item:Description 2] is [FORMATNUM([Item:Unit Cost];2; )]', TempIgnoredQltyInspectionTestHeader, true),
                'FORMATNUM-2');
        // [WHEN] FORMATNUM function is used with format 9 (same as format 2)
        // [THEN] The value is formatted as a plain decimal number
        LibraryAssert.AreEqual('F9 A turkey apple cheese is 1234567890.12', QltyExpressionMgmt.EvaluateTextExpression('F9 A [Item:Description 2] is [FORMATNUM([Item:Unit Cost];9; )]', TempIgnoredQltyInspectionTestHeader, true),
                'FORMATNUM-9');
    end;

    [Test]
    procedure LookupFieldValue()
    var
        Location: Record Location;
        TempIgnoredQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] Validate the LOOKUP function for retrieving field values based on another field's value

        // [GIVEN] A location is created with a specific name
        LibraryWarehouse.CreateLocation(Location);
        Location.Name := LocationNameTok;
        Location.Modify();

        // [WHEN] LOOKUP expression is evaluated to find location code by name
        // [THEN] The correct location code is returned
        LibraryAssert.AreEqual(Location.Code, QltyExpressionMgmt.EvaluateTextExpression(StrSubstNo(LookupExpressionTok, LocationNameTok), TempIgnoredQltyInspectionTestHeader, false), 'should return the location code');
    end;

    [Test]
    procedure EvaluateFirstStringOnlyFunctions_Replace()
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate the REPLACE function in text expressions

        // [WHEN] REPLACE function is evaluated to replace 'apple' with 'banana'
        // [THEN] The text is correctly replaced
        LibraryAssert.AreEqual('banana', QltyExpressionMgmt.TestEvaluateSpecialStringFunctions('[REPLACE(apple;apple;banana)]'), 'should return the replaced text');
    end;

    [Test]
    procedure EvaluateFirstStringOnlyFunctions_Copystr()
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate the COPYSTR function in text expressions

        // [WHEN] COPYSTR function is evaluated to extract substring from position 5, length 3
        // [THEN] The substring 'cat' is correctly extracted
        LibraryAssert.AreEqual('cat', QltyExpressionMgmt.TestEvaluateSpecialStringFunctions('[COPYSTR(copycat;5;3)]'), 'should return the replaced text');
    end;

    [Test]
    procedure EvaluateFirstStringOnlyFunctions_Classify_True()
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate the CLASSIFY function when condition matches

        // [WHEN] CLASSIFY function is evaluated with matching condition ('cat' equals 'cat')
        // [THEN] The true value is returned
        LibraryAssert.AreEqual('true', QltyExpressionMgmt.TestEvaluateSpecialStringFunctions('[CLASSIFY(cat;cat;true)]'), 'should return the classify value');
    end;

    [Test]
    procedure EvaluateFirstStringOnlyFunctions_Classify_False()
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate the CLASSIFY function when condition does not match

        // [WHEN] CLASSIFY function is evaluated with non-matching condition ('copycat' does not equal 'cat')
        // [THEN] An empty string is returned
        LibraryAssert.AreEqual('', QltyExpressionMgmt.TestEvaluateSpecialStringFunctions('[CLASSIFY(copycat;cat;true)]'), 'should return the classify value');
    end;

    [Test]
    procedure EvaluateExpressionForRecord_CaseInsensitive()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        // [SCENARIO] Validate that expression evaluation for records is case-insensitive

        // [GIVEN] Quality management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, QltyInspectionTemplateHdr);

        // [WHEN] Expression is evaluated with lowercase field name
        // [THEN] The template code is correctly retrieved
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Template Code", QltyExpressionMgmt.EvaluateExpressionForRecord(TemplateTok, QltyInspectionTestHeader, true), 'Should find template code');

        // [WHEN] Expression is evaluated with capitalized field name
        // [THEN] The template code is correctly retrieved (case-insensitive)
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Template Code", QltyExpressionMgmt.EvaluateExpressionForRecord(TemplateCapitalizedTok, QltyInspectionTestHeader, true), 'Should find template code');

        // [WHEN] Expression is evaluated with uppercase field name
        // [THEN] The template code is correctly retrieved (case-insensitive)
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Template Code", QltyExpressionMgmt.EvaluateExpressionForRecord(TemplateUppercaseTok, QltyInspectionTestHeader, true), 'Should find template code');

        QltyInTestGenerationRule.SetRange("Template Code", QltyInspectionTemplateHdr."Code");
        QltyInTestGenerationRule.DeleteAll();
    end;
}
