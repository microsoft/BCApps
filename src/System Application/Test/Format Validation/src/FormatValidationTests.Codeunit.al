// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Utilities;

codeunit 130449 "Format Validation Tests"
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
        TempFormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect return value false when validating a phone on. which does not contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomNumericText(MaxStrLen(TempFormatValidationTestTable."Phone No.")), TempFormatValidationTestTable);

        LibraryAssert.IsFalse(FormatValidation.ValidateIfPhoneNoContainsCharacters(TempFormatValidationTestTable."Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithInvalidPhoneNo_ValidatePhoneNo_ExpectNotValidResult()
    var
        TempFormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect return value true when validating a phone on. which does contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempFormatValidationTestTable."Phone No."), 1), TempFormatValidationTestTable);

        LibraryAssert.IsTrue(FormatValidation.ValidateIfPhoneNoContainsCharacters(TempFormatValidationTestTable."Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithValidPhoneNo_ValidatePhoneNo_ExpectNoError()
    var
        TempFormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect no error message when validating a phone on. which does not contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomNumericText(MaxStrLen(TempFormatValidationTestTable."Phone No.")), TempFormatValidationTestTable);

        FormatValidation.ThrowErrorIfPhoneNoContainsCharacters(TempFormatValidationTestTable."Phone No.", Database::"Format Validation Test Table", TempFormatValidationTestTable.FieldNo("Phone No."));
    end;

    [Test]
    procedure CreateFormatValidationDataWithInvalidPhoneNo_ValidatePhoneNo_ExpectError()
    var
        TempFormatValidationTestTable: Record "Format Validation Test Table";
        FormatValidation: Codeunit "Format Validation";
    begin
        // [SCENARIO] Expect error message when validating a phone on. which does contain characters.
        Initialize();
        CreateFormatValidationTestData(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempFormatValidationTestTable."Phone No."), 1), TempFormatValidationTestTable);

        asserterror FormatValidation.ThrowErrorIfPhoneNoContainsCharacters(TempFormatValidationTestTable."Phone No.", Database::"Format Validation Test Table", TempFormatValidationTestTable.FieldNo("Phone No."));

        LibraryAssert.ExpectedError(StrSubstNo(PhoneNoErr, TempFormatValidationTestTable.FieldCaption("Phone No."), TempFormatValidationTestTable.FieldCaption("No."), TempFormatValidationTestTable."No."));
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

    local procedure CreateFormatValidationTestData(PhoneNo: Text[30]; var TempFormatValidationTestTable: Record "Format Validation Test Table");
    begin
        TempFormatValidationTestTable."Phone No." := PhoneNo;
        TempFormatValidationTestTable.Insert(false);
    end;
}