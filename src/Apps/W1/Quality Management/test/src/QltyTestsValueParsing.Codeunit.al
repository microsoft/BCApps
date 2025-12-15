// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.QualityManagement.Utilities;
using System.TestLibraries.Utilities;

codeunit 139976 "Qlty. Tests - Value Parsing"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_IntegerSimple()
    var
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a simple integer range string into minimum and maximum values

        // [GIVEN] A range string "1..2"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the range string
        // [THEN] The function returns true and sets Min to 1 and Max to 2
        Initialize();
        LibraryAssert.AreEqual(true, QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax('1..2', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1, Min, 'simple integer min');
        LibraryAssert.AreEqual(2, Max, 'simple integer max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_IntegerNegativeValues()
    var
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a negative integer range string into minimum and maximum values

        // [GIVEN] A range string with negative values "-5..-1"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the negative range
        // [THEN] The function returns true and sets Min to -5 and Max to -1
        Initialize();
        LibraryAssert.AreEqual(true, QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax('-5..-1', Min, Max), 'negative');
        LibraryAssert.AreEqual(-5, Min, 'simple integer min');
        LibraryAssert.AreEqual(-1, Max, 'simple integer max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_DecimalSimple()
    var
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a decimal range string into minimum and maximum values

        // [GIVEN] A range string with decimal values "1.00000001..2.999999999999"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the decimal range
        // [THEN] The function returns true and sets Min to 1.00000001 and Max to 2.999999999999
        Initialize();
        LibraryAssert.AreEqual(true, QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax('1.00000001..2.999999999999', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1.00000001, Min, 'simple decimal min');
        LibraryAssert.AreEqual(2.999999999999, Max, 'simple decimal max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_DecimalThousands()
    var
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a decimal range string with thousands separator into minimum and maximum values

        // [GIVEN] A range string with decimal values and thousands separators "1.00000001..1,234,567,890.99"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the formatted range
        // [THEN] The function returns true and correctly parses Min and Max values
        Initialize();
        LibraryAssert.AreEqual(true, QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax('1.00000001..1,234,567,890.99', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1.00000001, Min, 'thousands separator decimal min');
        LibraryAssert.AreEqual(1234567890.99, Max, 'thousands separator decimal max');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;
}
