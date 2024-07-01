// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Utilities;

codeunit 139194 "Check Phone No."
{
    Subtype = Test;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssert: Codeunit "Library Assert";
        ContactAltAddressPhoneNoErr: Label '%1 must not contain letters in %2 %3=''%4'',%5=''%6''.', Comment = '%1 = Field caption (mobile) phone no., %2 = Table caption, %3 = Field caption Contact No., %4 = Contact No., %5 Field caption Code, %6 = Code', Locked = true;
        ContactPhoneNoErr: Label '%1 must not contain letters in Contact %2=''%3''.', Comment = '%1 = Field caption (mobile) phone no., %2 = Field caption Contact No., %3 = Contact No.', Locked = true;

    [Test]
    procedure CreateContact_AddPhoneNoWithCharacters_ExpectError()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO] Expect error message in case a phone on. is applied which contains characters.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        asserterror Contact.Validate("Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Contact."Phone No."), 1));

        LibraryAssert.ExpectedError(StrSubstNo(ContactPhoneNoErr, Contact.FieldCaption("Phone No."), Contact.FieldCaption("No."), Contact."No."));
    end;

    [Test]
    procedure CreateContact_AddMobilePhoneNoWithCharacters_ExpectError()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO] Expect error message in case a mobile phone on. is applied which contains characters.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        asserterror Contact.Validate("Mobile Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Contact."Mobile Phone No."), 1));

        LibraryAssert.ExpectedError(StrSubstNo(ContactPhoneNoErr, Contact.FieldCaption("Mobile Phone No."), Contact.FieldCaption("No."), Contact."No."));
    end;

    [Test]
    procedure CreateContactAltAddress_AddPhoneNoWithCharacters_ExpectError()
    var
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        // [SCENARIO] Expect error message in case a phone on. is applied which contains characters.
        Initialize();
        LibraryMarketing.CreateContactAltAddress(ContactAltAddress, LibraryMarketing.CreateCompanyContactNo());

        asserterror ContactAltAddress.Validate("Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ContactAltAddress."Phone No."), 1));

        LibraryAssert.ExpectedError(StrSubstNo(ContactAltAddressPhoneNoErr, ContactAltAddress.FieldCaption("Phone No."), ContactAltAddress.TableCaption, ContactAltAddress.FieldCaption("Contact No."), ContactAltAddress."Contact No.", ContactAltAddress.FieldCaption(Code), ContactAltAddress.Code));
    end;

    [Test]
    procedure CreateContactAltAddress_AddMobilePhoneNoWithCharacters_ExpectError()
    var
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        // [SCENARIO] Expect error message in case a mobile phone on. is applied which contains characters.
        Initialize();
        LibraryMarketing.CreateContactAltAddress(ContactAltAddress, LibraryMarketing.CreateCompanyContactNo());

        asserterror ContactAltAddress.Validate("Mobile Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ContactAltAddress."Mobile Phone No."), 1));

        LibraryAssert.ExpectedError(StrSubstNo(ContactAltAddressPhoneNoErr, ContactAltAddress.FieldCaption("Mobile Phone No."), ContactAltAddress.TableCaption, ContactAltAddress.FieldCaption("Contact No."), ContactAltAddress."Contact No.", ContactAltAddress.FieldCaption(Code), ContactAltAddress.Code));
    end;

    local procedure Initialize();
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::CheckPhoneNo);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::CheckPhoneNo);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::CheckPhoneNo);
    end;
}