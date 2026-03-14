// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Globalization;
using System.TestTools.TestRunner;

codeunit 149046 "AIT Test Suite Language"
{
    Access = Internal;

    /// <summary>
    /// Updates the eval suite languages by adding all available language versions from the test input groups.
    /// Languages that are no longer part of any dataset will be removed.
    /// </summary>
    /// <param name="TestSuiteCode">The eval suite code to update languages for.</param>
    /// <param name="TestInputGroupCode">The test input group code to get languages from.</param>
    procedure UpdateLanguagesFromDataset(TestSuiteCode: Code[100]; TestInputGroupCode: Code[100])
    var
        TestInputGroup: Record "Test Input Group";
        TestInputGroupLanguageVersions: Record "Test Input Group";
        SeenLanguages: Dictionary of [Integer, Boolean];
    begin
        if not TestInputGroup.Get(TestInputGroupCode) then
            exit;

        AddLanguage(TestSuiteCode, TestInputGroup."Language ID", SeenLanguages);

        if TestInputGroup.GetTestInputGroupLanguages(TestInputGroupCode, TestInputGroupLanguageVersions) then
            repeat
                AddLanguage(TestSuiteCode, TestInputGroupLanguageVersions."Language ID", SeenLanguages);
            until TestInputGroupLanguageVersions.Next() = 0;
    end;

    /// <summary>
    /// Gets the display name of a language by its ID.
    /// </summary>
    /// <param name="LanguageID">The language ID.</param>
    /// <returns>The display name of the language.</returns>
    procedure GetLanguageDisplayName(LanguageID: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
        NoneLbl: Label 'None';
    begin
        if WindowsLanguage.Get(LanguageID) then
            exit(WindowsLanguage.Name);

        exit(NoneLbl);
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
    /// Opens a lookup page to select and assign a language to the eval suite.
    /// </summary>
    /// <param name="AITTestSuite">The eval suite record to assign a language to.</param>
    procedure AssistEditTestSuiteLanguage(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
        TempAITTestSuiteLanguage: Record "AIT Test Suite Language" temporary;
        AITTestSuiteLanguages: Page "AIT Test Suite Language Lookup";
    begin
        TempAITTestSuiteLanguage."Test Suite Code" := AITTestSuite.Code;
        TempAITTestSuiteLanguage."Language ID" := 0;
        TempAITTestSuiteLanguage.Insert();

        AITTestSuiteLanguage.SetRange("Test Suite Code", AITTestSuite.Code);
        if AITTestSuiteLanguage.FindSet() then
            repeat
                TempAITTestSuiteLanguage.TransferFields(AITTestSuiteLanguage);
                TempAITTestSuiteLanguage.Insert();
            until AITTestSuiteLanguage.Next() = 0;

        AITTestSuiteLanguages.SetRecords(TempAITTestSuiteLanguage);
        AITTestSuiteLanguages.LookupMode := true;

        if AITTestSuiteLanguages.RunModal() = Action::LookupOK then begin
            AITTestSuiteLanguages.GetRecord(TempAITTestSuiteLanguage);
            AITTestSuite.Validate("Run Language ID", TempAITTestSuiteLanguage."Language ID");
            AITTestSuite.Modify(true);
        end;
    end;

    /// <summary>
    /// Gets the language-specific version of a dataset based on the test suite's language setting.
    /// </summary>
    /// <param name="InputDatasetCode">The base input dataset code.</param>
    /// <param name="LanguageID">The language ID from the test suite.</param>
    /// <returns>The language-specific dataset code.</returns>
    procedure GetLanguageDataset(InputDatasetCode: Code[100]; LanguageID: Integer): Code[100]
    var
        TestInputGroup: Record "Test Input Group";
        LanguageDatasetCode: Code[100];
        LanguageVersionNotFoundErr: Label 'No language version found for dataset %1 with language %2.', Comment = '%1 = Dataset Code, %2 = Language Name';
    begin
        if not TestInputGroup.Get(InputDatasetCode) then
            exit(InputDatasetCode);

        if TestInputGroup."Parent Group Code" <> '' then
            exit(InputDatasetCode);

        if LanguageID = 0 then
            if GetLanguageDatasetCode(TestInputGroup."Group Name", 1033, LanguageDatasetCode) then
                exit(LanguageDatasetCode)
            else
                exit(InputDatasetCode);

        if not GetLanguageDatasetCode(TestInputGroup."Group Name", LanguageID, LanguageDatasetCode) then
            Error(LanguageVersionNotFoundErr, InputDatasetCode, GetLanguageDisplayName(LanguageID));

        exit(LanguageDatasetCode);
    end;

    local procedure GetLanguageDatasetCode(GroupName: Text[250]; LanguageID: Integer; var LanguageDatasetCode: Code[100]): Boolean
    var
        LanguageVersionGroup: Record "Test Input Group";
    begin
        LanguageVersionGroup.SetRange("Group Name", GroupName);
        LanguageVersionGroup.SetRange("Language ID", LanguageID);
        if not LanguageVersionGroup.FindFirst() then
            exit(false);

        LanguageDatasetCode := LanguageVersionGroup.Code;
        exit(true);
    end;

    local procedure AddLanguage(TestSuiteCode: Code[100]; LanguageID: Integer; SeenLanguages: Dictionary of [Integer, Boolean])
    var
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
    begin
        if LanguageID = 0 then
            exit;

        if SeenLanguages.ContainsKey(LanguageID) then
            exit;

        SeenLanguages.Add(LanguageID, true);

        if AITTestSuiteLanguage.Get(TestSuiteCode, LanguageID) then
            exit;

        AITTestSuiteLanguage."Test Suite Code" := CopyStr(TestSuiteCode, 1, MaxStrLen(AITTestSuiteLanguage."Test Suite Code"));
        AITTestSuiteLanguage."Language ID" := LanguageID;
        AITTestSuiteLanguage.Insert(true);
    end;
}
