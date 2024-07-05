// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Utilities;

codeunit 139194 "Format Validation Tests"
{
    Subtype = Test;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;
        PhoneNoErr: Label '%1 must not contain letters in Format Validation Test Table %2=''%3''.', Comment = '%1 = Field caption "Phone No.", %2 = Field caption "No.", %3 = "No."', Locked = true;

    [Test]
    procedure CreateFormatValidationDataWithValidPhoneNo_ValidatePhoneNo_ExpectIsValidResult()
    var
        FormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect return value false when validating a phone on. which does not contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomNumericText(MaxStrLen(FormatValidationTestTable."Phone No.")), FormatValidationTestTable);

        LibraryAssert.IsFalse(FormatValidation.ValidateIfPhoneNoContainsCharacters(FormatValidationTestTable."Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithInvalidPhoneNo_ValidatePhoneNo_ExpectNotValidResult()
    var
        FormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect return value true when validating a phone on. which does contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(FormatValidationTestTable."Phone No."), 1), FormatValidationTestTable);

        LibraryAssert.IsTrue(FormatValidation.ValidateIfPhoneNoContainsCharacters(FormatValidationTestTable."Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithValidPhoneNo_ValidatePhoneNo_ExpectNoError()
    var
        FormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect no error message when validating a phone on. which does not contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomNumericText(MaxStrLen(FormatValidationTestTable."Phone No.")), FormatValidationTestTable);

        FormatValidation.ThrowErrorIfPhoneNoContainsCharacters(FormatValidationTestTable."Phone No.", Database::"Format Validation Test Table", FormatValidationTestTable.FieldNo("Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithInvalidPhoneNo_ValidatePhoneNo_ExpectError()
    var
        FormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect error message when validating a phone on. which does contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(FormatValidationTestTable."Phone No."), 1), FormatValidationTestTable);

        asserterror FormatValidation.ThrowErrorIfPhoneNoContainsCharacters(FormatValidationTestTable."Phone No.", Database::"Format Validation Test Table", FormatValidationTestTable.FieldNo("Phone No."));

        LibraryAssert.ExpectedError(StrSubstNo(PhoneNoErr, FormatValidationTestTable.FieldCaption("Phone No."), FormatValidationTestTable.FieldCaption("No."), FormatValidationTestTable."No."));
    end;

    local procedure Initialize();
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Format Validation");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Format Validation");

        IsInitialized := true;

        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Format Validation");
    end;

    local procedure CreateFormatValidationTestData(PhoneNo: Text[30]; var FormatValidationTestTable: Record "Format Validation Test Table");
    begin
        FormatValidationTestTable."Phone No." := PhoneNo;
        FormatValidationTestTable.Insert(false);
    end;
}