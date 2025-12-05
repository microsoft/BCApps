// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;
using System.Globalization;

codeunit 149046 "AIT Test Suite Language"
{
    Access = Internal;

    /// <summary>
    /// Updates the test method lines of the specified test suite to use the selected language version.
    /// </summary>
    /// <param name="AITTestSuite"></param>
    procedure UpdateLanguagesForTestSuite(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
        LanguageNotAvailableErr: Label 'Language ID %1 is not available for Test Suite %2.', Comment = '%1 - language ID, %2 - test suite code.';
    begin
        AddLanguagesFromTestSuite(AITTestSuite);

        if not AITTestSuiteLanguage.Get(AITTestSuite.Code, AITTestSuite."Language ID") then
            Error(LanguageNotAvailableErr, AITTestSuite."Language ID", AITTestSuite.Code);

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);

        if AITTestMethodLine.FindSet() then
            repeat
                UpdateLanguageForTestMethodLine(AITTestMethodLine, AITTestSuiteLanguage);
            until AITTestMethodLine.Next() = 0;
    end;

    /// <summary>
    /// Updates the input dataset of the test method line to the specified language version.
    /// </summary>
    /// <param name="AITTestMethodLine">The test method line record to update.</param>
    /// <param name="AITTestSuiteLanguage">The test suite language record specifying the language to update the input dataset to.</param>
    procedure UpdateLanguageForTestMethodLine(AITTestMethodLine: Record "AIT Test Method Line"; AITTestSuiteLanguage: Record "AIT Test Suite Language")
    var
        TestInputGroup: Record "Test Input Group";
        TestInputGroupLanguageVersion: Record "Test Input Group";
        InputDatasetNotFoundErr: Label 'Input Dataset %1 not found in Test Input Groups.', Comment = '%1 - input dataset.';
        NoLocalizedVersionErr: Label 'No localized version found for Input Dataset %1 in Language ID %2.', Comment = '%1 - input dataset, %2 - language ID.';
    begin
        if AITTestMethodLine."Input Dataset" = '' then
            exit;

        if not TestInputGroup.Get(AITTestMethodLine."Input Dataset") then
            Error(InputDatasetNotFoundErr, AITTestMethodLine."Input Dataset");

        TestInputGroupLanguageVersion.SetRange("Group Name", TestInputGroup."Group Name");
        TestInputGroupLanguageVersion.SetRange("Language ID", AITTestSuiteLanguage."Language ID");
        if not TestInputGroupLanguageVersion.FindFirst() then
            Error(NoLocalizedVersionErr, AITTestMethodLine."Input Dataset", AITTestSuiteLanguage."Language ID");

        AITTestMethodLine."Input Dataset" := TestInputGroupLanguageVersion.Code;
        AITTestMethodLine.Modify();
    end;


    /// <summary>
    /// Updates the test suite languages by adding all available language versions from the test input groups.
    /// </summary>
    /// <param name="AITTestSuite">The test suite record to update languages for.</param>
    /// <returns>True if languages were updated; otherwise, false.</returns>
    procedure AddLanguagesFromTestSuite(AITTestSuite: Record "AIT Test Suite"): Boolean
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        Updated: Boolean;
    begin
        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);

        if AITTestMethodLine.FindSet() then
            repeat
                if AddLanguagesFromTestMethodLine(AITTestMethodLine) then
                    Updated := true;
            until AITTestMethodLine.Next() = 0;

        exit(Updated);
    end;

    /// <summary>
    /// Updates the test suite languages by adding all available language versions from the test input groups.
    /// </summary>
    /// <param name="AITTestMethodLine">The test method line record to update language for.</param>
    /// <returns>True if languages were updated; otherwise, false.</returns>
    procedure AddLanguagesFromTestMethodLine(AITTestMethodLine: Record "AIT Test Method Line"): Boolean
    var
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
        TestInputGroup: Record "Test Input Group";
        TestInputGroupLanguageVersions: Record "Test Input Group";
        LanguageIDs: List of [Integer];
        Updated: Boolean;
    begin
        if not TestInputGroup.Get(AITTestMethodLine.GetTestInputCode()) then
            exit(false);

        if not TestInputGroup.GetTestInputGroupLanguages(TestInputGroupLanguageVersions) then
            exit(false);

        repeat
            if not LanguageIDs.Contains(TestInputGroupLanguageVersions."Language ID") then begin
                LanguageIDs.Add(TestInputGroupLanguageVersions."Language ID");

                if not AITTestSuiteLanguage.Get(AITTestMethodLine."Test Suite Code", TestInputGroupLanguageVersions."Language ID") then begin
                    AddLanguage(CopyStr(AITTestMethodLine."Test Suite Code", 1, StrLen(AITTestMethodLine."Test Suite Code")), TestInputGroupLanguageVersions."Language ID");
                    Updated := true;
                end;
            end;
        until TestInputGroupLanguageVersions.Next() = 0;

        exit(Updated);
    end;

    /// <summary>
    /// Gets the display name of a language by its ID.
    /// </summary>
    /// <param name="LanguageID">The language ID.</param>
    /// <returns>The display name of the language.</returns>
    procedure GetLanguageDisplayName(LanguageID: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if WindowsLanguage.Get(LanguageID) then
            exit(WindowsLanguage."Language Tag");

        exit('');
    end;

    /// <summary>
    /// Gets the language ID by its tag.
    /// </summary>
    /// <param name="LanguageTag">The language tag.</param>
    /// <returns>The language ID.</returns>
    procedure GetLanguageIDByTag(LanguageTag: Text): Integer
    var
        WindowsLanguage: Record "Windows Language";
        LanguageNotFoundErr: Label 'Language with tag %1 not found.', Comment = '%1 - language tag.';
    begin
        WindowsLanguage.SetRange("Language Tag", LanguageTag);
        if not WindowsLanguage.FindFirst() then
            Error(LanguageNotFoundErr, LanguageTag);

        exit(WindowsLanguage."Language ID");
    end;

    /// <summary>
    /// Opens a lookup page to select and assign a language to the test suite.
    /// </summary>
    /// <param name="AITTestSuite">The test suite record to assign a language to.</param>
    procedure AssistEditTestSuiteLanguage(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
        AITTestSuiteLanguages: Page "AIT Test Suite Languages";
    begin
        AITTestSuiteLanguage.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestSuiteLanguages.SetTableView(AITTestSuiteLanguage);
        AITTestSuiteLanguages.LookupMode := true;

        if AITTestSuiteLanguages.RunModal() = Action::LookupOK then begin
            AITTestSuiteLanguages.GetRecord(AITTestSuiteLanguage);
            AITTestSuite.Validate("Language ID", AITTestSuiteLanguage."Language ID");
            AITTestSuite.Modify(true);
        end;
    end;

    local procedure AddLanguage(TestSuiteCode: Code[10]; LanguageID: Integer)
    var
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
    begin
        AITTestSuiteLanguage."Test Suite Code" := TestSuiteCode;
        AITTestSuiteLanguage."Language ID" := LanguageID;
        AITTestSuiteLanguage.Insert(true);
    end;
}
