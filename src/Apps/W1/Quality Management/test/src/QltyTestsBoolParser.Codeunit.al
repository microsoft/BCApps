// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using System.TestLibraries.Utilities;

codeunit 139978 "Qlty. Tests - Bool. Parser"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    [Test]
    procedure GetBooleanFor()
    var
        QltyBooleanParser: Codeunit "Qlty. Boolean Parser";
    begin
        // [SCENARIO] Convert various text values to boolean
        Initialize();

        // [GIVEN] Various text values representing true or false

        // [WHEN] GetBooleanFor is called with positive values (true, 1, yes, ok, pass, etc.)
        // [THEN] The function returns true for all positive boolean representations
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('true'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('TRUE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('1'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('Yes'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('Y'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('T'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('OK'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('GOOD'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('PASS'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.GetBooleanFor('V'), 'document intelligence/form recognizer selected check.');

        // [WHEN] GetBooleanFor is called with negative values (false, no, fail, etc.)
        // [THEN] The function returns false for all negative boolean representations
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('false'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('FALSE'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('N'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('No'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('F'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('Fail'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('Failed'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('BAD'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('disabled'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor('unacceptable'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.GetBooleanFor(':UNSELECTED:'), 'document intelligence/form recognizer scenario');
    end;

    [Test]
    procedure IsTextValueNegativeBoolean()
    var
        QltyBooleanParser: Codeunit "Qlty. Boolean Parser";
    begin
        // [SCENARIO] Identify negative boolean text values

        Initialize();

        // [GIVEN] Various text values representing positive and negative boolean states
        // [WHEN] IsTextValueNegativeBoolean is called with each value
        // [THEN] The function returns false for positive values, true for negative values
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('true'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('TRUE'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('1'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('Yes'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('Y'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('T'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('OK'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('GOOD'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('PASS'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('V'), 'document intelligence/form recognizer selected check.');

        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('false'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('FALSE'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('N'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('No'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('F'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('Fail'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('Failed'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('BAD'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('disabled'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean('unacceptable'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValueNegativeBoolean(':UNSELECTED:'), 'document intelligence/form recognizer scenario');

        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('not a hot dog'), 'not a hot dog');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('Canada'), 'a sovereign country');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValueNegativeBoolean('1234'), 'a number');
    end;

    [Test]
    procedure IsTextValuePositiveBoolean()
    var
        QltyBooleanParser: Codeunit "Qlty. Boolean Parser";
    begin
        // [SCENARIO] Identify positive boolean text values

        Initialize();

        // [GIVEN] Various text values representing positive and negative boolean states
        // [WHEN] IsTextValuePositiveBoolean is called with each value
        // [THEN] The function returns true for positive values, false for negative values
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('true'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('TRUE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('1'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('Yes'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('Y'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('T'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('OK'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('GOOD'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('PASS'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyBooleanParser.IsTextValuePositiveBoolean('V'), 'document intelligence/form recognizer selected check.');

        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('false'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('FALSE'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('N'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('No'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('F'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('Fail'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('Failed'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('BAD'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('disabled'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('unacceptable'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean(':UNSELECTED:'), 'document intelligence/form recognizer scenario');

        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('not a hot dog'), 'not a hot dog');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('Canada'), 'a sovereign country');
        LibraryAssert.IsFalse(QltyBooleanParser.IsTextValuePositiveBoolean('1234'), 'a number');
    end;
}
