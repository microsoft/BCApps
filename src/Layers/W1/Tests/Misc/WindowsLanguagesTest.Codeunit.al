// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 132930 "Windows Languages Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Windows Languages]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ExpectedLanguageCount: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TestWindowsLanguagesTableCount()
    var
        WindowsLanguage: Record "Windows Language";
    begin
        // [FEATURE] [Windows Language]
        // [SCENARIO] Windows Language table should have exactly 247 languages

        LibraryLowerPermissions.SetO365Basic();
        ExpectedLanguageCount := 247;

        // [GIVEN] Windows Language table

        // [WHEN] We count all the records in the table
        // [THEN] The count should be exactly 247
        Assert.AreEqual(ExpectedLanguageCount, WindowsLanguage.Count(), 'The Windows Language table should have exactly 247 languages.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWindowsLanguagesPageCount()
    var
        WindowsLanguages: TestPage "Windows Languages";
        LanguageCount: Integer;
    begin
        // [FEATURE] [Windows Languages]
        // [SCENARIO] Windows Languages page should display exactly 247 languages

        LibraryLowerPermissions.SetO365Basic();
        ExpectedLanguageCount := 247;
        LanguageCount := 0;

        // [GIVEN] Windows Languages page is opened
        WindowsLanguages.OpenView();

        // [WHEN] We count all the records on the page
        if WindowsLanguages.First() then
            repeat
                LanguageCount += 1;
            until not WindowsLanguages.Next();

        // [THEN] The count should be exactly 247
        Assert.AreEqual(ExpectedLanguageCount, LanguageCount, 'The Windows Languages page should display exactly 247 languages.');

        WindowsLanguages.Close();
    end;
}
