// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Test;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Peppol;
using System.Globalization;

codeunit 139237 "PEPPOL VAT Helper Tests"
{
    Subtype = Test;
    TestType = UnitTest;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    procedure GetVATClauseInfoReturnsVATEXCodeAndDescription()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        PEPPOLVATHelper: Codeunit "PEPPOL VAT Helper";
        VATEXCode: Text;
        VATClauseDescription: Text;
    begin
        // [SCENARIO] GetVATClauseInfo returns VATEX Code and Description when VAT Posting Setup and VAT Clause exist
        // [GIVEN] A VAT Posting Setup with a VAT Clause that has a VATEX Code
        CreateVATPostingSetupWithVATClause(VATPostingSetup, VATClause);

        // [WHEN] GetVATClauseInfo is called
        PEPPOLVATHelper.GetVATClauseInfo(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', VATEXCode, VATClauseDescription);

        // [THEN] VATEX Code and Description are returned
        Assert.AreEqual(VATClause."VATEX Code", VATEXCode, 'VATEX Code mismatch');
        Assert.AreEqual(VATClause.Description, VATClauseDescription, 'VAT Clause Description mismatch');
    end;

    [Test]
    procedure GetVATClauseInfoReturnsEmptyWhenVATClauseCodeIsBlank()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLVATHelper: Codeunit "PEPPOL VAT Helper";
        VATEXCode: Text;
        VATClauseDescription: Text;
    begin
        // [SCENARIO] GetVATClauseInfo returns empty when VAT Posting Setup exists but VAT Clause Code is blank
        // [GIVEN] A VAT Posting Setup with no VAT Clause Code
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, Enum::"Tax Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));

        // [WHEN] GetVATClauseInfo is called
        PEPPOLVATHelper.GetVATClauseInfo(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', VATEXCode, VATClauseDescription);

        // [THEN] Both values are empty
        Assert.AreEqual('', VATEXCode, 'VATEX Code should be empty');
        Assert.AreEqual('', VATClauseDescription, 'VAT Clause Description should be empty');
    end;

    [Test]
    procedure GetVATClauseInfoReturnsEmptyWhenVATClauseNotFound()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PEPPOLVATHelper: Codeunit "PEPPOL VAT Helper";
        VATEXCode: Text;
        VATClauseDescription: Text;
    begin
        // [SCENARIO] GetVATClauseInfo returns empty when VAT Clause record does not exist
        // [GIVEN] A VAT Posting Setup with a non-existing VAT Clause Code
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, Enum::"Tax Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        VATPostingSetup."VAT Clause Code" := CopyStr(LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Clause Code"), Database::"VAT Posting Setup"), 1, MaxStrLen(VATPostingSetup."VAT Clause Code"));
        VATPostingSetup.Modify();

        // [WHEN] GetVATClauseInfo is called
        PEPPOLVATHelper.GetVATClauseInfo(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', VATEXCode, VATClauseDescription);

        // [THEN] Both values are empty
        Assert.AreEqual('', VATEXCode, 'VATEX Code should be empty');
        Assert.AreEqual('', VATClauseDescription, 'VAT Clause Description should be empty');
    end;

    [Test]
    procedure GetVATClauseInfoReturnsTranslatedDescription()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        VATClauseTranslation: Record "VAT Clause Translation";
        Language: Record Language;
        PEPPOLVATHelper: Codeunit "PEPPOL VAT Helper";
        VATEXCode: Text;
        VATClauseDescription: Text;
        TranslatedDescription: Text[250];
    begin
        // [SCENARIO] GetVATClauseInfo returns translated description when a translation exists for the given language
        // [GIVEN] A VAT Posting Setup with a VAT Clause that has a translation
        CreateVATPostingSetupWithVATClause(VATPostingSetup, VATClause);
        Language.Init();
        Language.Code := CopyStr(LibraryUtility.GenerateRandomCode(Language.FieldNo(Code), Database::Language), 1, MaxStrLen(Language.Code));
        Language.Name := Language.Code;
        Language.Insert();
        TranslatedDescription := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(50, 0), 1, MaxStrLen(TranslatedDescription));
        VATClauseTranslation.Init();
        VATClauseTranslation."VAT Clause Code" := VATClause.Code;
        VATClauseTranslation."Language Code" := Language.Code;
        VATClauseTranslation.Description := TranslatedDescription;
        VATClauseTranslation.Insert();

        // [WHEN] GetVATClauseInfo is called with the translation language
        PEPPOLVATHelper.GetVATClauseInfo(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", Language.Code, VATEXCode, VATClauseDescription);

        // [THEN] Translated description is returned
        Assert.AreEqual(VATClause."VATEX Code", VATEXCode, 'VATEX Code mismatch');
        Assert.AreEqual(TranslatedDescription, VATClauseDescription, 'Should return translated description');
    end;

    local procedure CreateVATPostingSetupWithVATClause(var VATPostingSetup: Record "VAT Posting Setup"; var VATClause: Record "VAT Clause")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, Enum::"Tax Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        VATClause.Init();
        VATClause.Code := CopyStr(LibraryUtility.GenerateRandomCode20(VATClause.FieldNo(Code), Database::"VAT Clause"), 1, MaxStrLen(VATClause.Code));
        VATClause.Description := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(50, 0), 1, MaxStrLen(VATClause.Description));
        VATClause."VATEX Code" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 0), 1, MaxStrLen(VATClause."VATEX Code"));
        VATClause.Insert();
        VATPostingSetup."VAT Clause Code" := VATClause.Code;
        VATPostingSetup.Modify();
    end;
}
