// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration;

using System.Apps;
using System.Integration;
using System.TestLibraries.Utilities;
using System.Reflection;

codeunit 138133 "VS Code Request Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TempNavInstalledApp: Record "NAV App Installed App" temporary;
        AllObjWithCaption: Record AllObjWithCaption;
        Assert: Codeunit "Library Assert";
        VSCodeRequestManagement: Codeunit "VS Code Request Management";

    [Test]
    procedure TestFormatDependencies()
    var
        Dependencies: Text;
    begin
        // [SCENARIO] Formatting apps from a table into query url parameter format

        // [GIVEN] a table with the installed apps
        TempNavInstalledApp.DeleteAll();

        TempNavInstalledApp.Init();
        TempNavInstalledApp."App ID" := 'f15fd82b-8050-4bb6-bfbc-1a948b7b17c3';
        TempNavInstalledApp."Name" := 'MyApp1';
        TempNavInstalledApp."Publisher" := 'Publisher1';
        TempNavInstalledApp."Version Major" := 1;
        TempNavInstalledApp."Version Minor" := 2;
        TempNavInstalledApp."Version Build" := 3;
        TempNavInstalledApp."Version Revision" := 4;
        TempNavInstalledApp.Insert();

        TempNavInstalledApp.Init();
        TempNavInstalledApp."App ID" := 'a15fd72b-6430-4bb6-dfbc-1a948b7b15b4';
        TempNavInstalledApp."Name" := 'MyApp2';
        TempNavInstalledApp."Publisher" := 'Publisher2';
        TempNavInstalledApp."Version Major" := 23;
        TempNavInstalledApp."Version Minor" := 0;
        TempNavInstalledApp."Version Build" := 0;
        TempNavInstalledApp."Version Revision" := 0;
        TempNavInstalledApp.Insert();

        // [WHEN] we format these into query url parameter format
        Dependencies := VSCodeRequestManagement.GetFormattedDependencies(TempNavInstalledApp);

        // [THEN] String has the expected format
        Assert.AreEqual('A15FD72B-6430-4BB6-DFBC-1A948B7B15B4,MyApp2,Publisher2,23.0.0.0;F15FD82B-8050-4BB6-BFBC-1A948B7B17C3,MyApp1,Publisher1,1.2.3.4;', Dependencies, 'The format is incorrect.');
    end;

    [Test]
    procedure GetUrlToNavigateInVSCodeForPage()
    var
        URL: text;
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to navigate to the page

        // [GIVEN] a page's infomation
        // [WHEN] we generate the URL to send a request to VS Code to navigate to the page source 
        URL := VSCodeRequestManagement.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Page, 2515, 'AppSource Product List', '', '');

        // [THEN] URL has the expected format
        Assert.IsTrue(URL.StartsWith('vscode://ms-dynamics-smb.al/navigateTo?type=page&id=2515&name=AppSource%20Product%20List'), 'Unexpected URL.');
    end;

    [Test]
    procedure GetUrlToNavigateInVSCodeForTableField()
    var
        URL: text;
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to navigate to a table field

        // [GIVEN] a table field's infomation
        // [WHEN] we generate the URL to send a request to VS Code to navigate to the table field's definition in source code
        URL := VSCodeRequestManagement.GetUrlToNavigateInVSCode(AllObjWithCaption."Object Type"::Table, 2515, 'AppSource Product', 'DisplayName', '');

        // [THEN] URL has the expected format
        Assert.IsTrue(Url.StartsWith('vscode://ms-dynamics-smb.al/navigateTo?type=table&id=2515&name=AppSource%20Product&fieldName=DisplayName'), 'Unexpected URL.');
    end;

    [Test]
    procedure GetUrlToOpenExtensionSource()
    var
        URL: text;
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to get an extension's source code from a source evrsion control

        // [GIVEN] a the source control information
        // [WHEN] we generate the URL to send a request to VS Code to get an extension's source code
        URL := VSCodeRequestManagement.GetUrlToOpenExtensionSource('https://github.com/microsoft/BCApps', 'd00e148c0513b02b4818a6f8fd399ad6e9543080');

        // [THEN] URL has the expected format
        Assert.AreEqual('vscode://ms-dynamics-smb.al/sourceSync?repoUrl=https%3A%2F%2Fgithub.com%2Fmicrosoft%2FBCApps&commitId=d00e148c0513b02b4818a6f8fd399ad6e9543080', URL, 'Unexpected URL.');
    end;
}