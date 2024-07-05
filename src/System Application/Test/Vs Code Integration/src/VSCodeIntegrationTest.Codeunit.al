// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration;

using System.Apps;
using System.Integration;
using System.Tooling;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 138133 "VS Code Integration Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TempNavInstalledApp: Record "NAV App Installed App" temporary;
        TempPublishedApplication: Record "Published Application" temporary;
        TempPageInfoAndFields: Record "Page Info And Fields" temporary;
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        HyperlinkStorage: Codeunit "Library - Variable Storage";
        VSCodeIntegration: Codeunit "VS Code Integration";

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure GetUrlToNavigateInVSCodeForPage()
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to navigate to the page

        Initialize();
        HyperlinkStorage.Enqueue('vscode://ms-dynamics-smb.al/navigateTo?type=page&id=22&name=Customer%20List');

        // [GIVEN] a page's infomation
        TempPageInfoAndFields.Init();
        TempPageInfoAndFields."Page ID" := 22;
        TempPageInfoAndFields."Page Name" := 'Customer List';

        // [WHEN] we generate the URL to send a request to VS Code to navigate to the page source 
        VSCodeIntegration.NavigateToPageDefinitionInVSCode(TempPageInfoAndFields, TempNavInstalledApp);

        // [THEN] URL has the expected format
        // Asserted in handler
        AssertCleanedUp();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure GetUrlToNavigateInVSCodeForTableField()
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to navigate to a table field

        Initialize();
        HyperlinkStorage.Enqueue('vscode://ms-dynamics-smb.al/navigateTo?type=table&id=11&name=Customer&appid=&fieldName=No.');

        // [GIVEN] a table field's infomation
        TempPageInfoAndFields.Init();
        TempPageInfoAndFields."Source Table No." := 11;
        TempPageInfoAndFields."Source Table Name" := 'Customer';
        TempPageInfoAndFields."Field Name" := 'No.';

        // [WHEN] we generate the URL to send a request to VS Code to navigate to the table field's definition in source code
        VSCodeIntegration.NavigateFieldDefinitionInVSCode(TempPageInfoAndFields, TempNavInstalledApp);

        // [THEN] URL has the expected format
        // Asserted in handler
        AssertCleanedUp();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure FormatDependencies()
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to navigate to the page with dependencies

        Initialize();
        HyperlinkStorage.Enqueue('&dependencies=A15FD72B-6430-4BB6-DFBC-1A948B7B15B4%2CMyApp2%2CPublisher2%2C23.0.0.0%3BF15FD82B-8050-4BB6-BFBC-1A948B7B17C3%2CMyApp1%2CPublisher1%2C1.2.3.4%3B');

        // [GIVEN] a page's dependencies
        TempNavInstalledApp.Init();
        TempNavInstalledApp."App ID" := 'f15fd82b-8050-4bb6-bfbc-1a948b7b17c3';
        TempNavInstalledApp."Name" := 'MyApp1';
        TempNavInstalledApp."Publisher" := 'Publisher1';
        TempNavInstalledApp."Version Major" := 1;
        TempNavInstalledApp."Version Minor" := 2;
        TempNavInstalledApp."Version Build" := 3;
        TempNavInstalledApp."Version Revision" := 4;
        TempNavInstalledApp.Insert();

        TempNavInstalledApp."App ID" := 'a15fd72b-6430-4bb6-dfbc-1a948b7b15b4';
        TempNavInstalledApp."Name" := 'MyApp2';
        TempNavInstalledApp."Publisher" := 'Publisher2';
        TempNavInstalledApp."Version Major" := 23;
        TempNavInstalledApp."Version Minor" := 0;
        TempNavInstalledApp."Version Build" := 0;
        TempNavInstalledApp."Version Revision" := 0;
        TempNavInstalledApp.Insert();

        // [WHEN] we generate the URL to send a request to VS Code to navigate to the page source 
        VSCodeIntegration.NavigateToPageDefinitionInVSCode(TempPageInfoAndFields, TempNavInstalledApp);

        // [THEN] Dependencies in URL has the expected format
        // Asserted in handler
        AssertCleanedUp();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure GetUrlToOpenExtensionSource()
    begin
        // [SCENARIO] Constructing URL to send a request to VS Code to get an extension's source code from a source evrsion control

        Initialize();
        HyperlinkStorage.Enqueue('vscode://ms-dynamics-smb.al/sourceSync?repoUrl=https%3A%2F%2Fgithub.com%2Fmicrosoft%2FBCApps&commitId=d00e148c0513b02b4818a6f8fd399ad6e9543080&appid=F15FD82B-8050-4BB6-BFBC-1A948B7B17C3');

        // [GIVEN] a the source control information
        TempPublishedApplication.Init();
        TempPublishedApplication."Source Repository Url" := 'https://github.com/microsoft/BCApps';
        TempPublishedApplication."Source Commit ID" := 'd00e148c0513b02b4818a6f8fd399ad6e9543080';
        TempPublishedApplication.ID := 'f15fd82b-8050-4bb6-bfbc-1a948b7b17c3';
        TempPublishedApplication.Insert();

        // [WHEN] we generate the URL to send a request to VS Code to get an extension's source code
        VSCodeIntegration.OpenExtensionSourceInVSCode(TempPublishedApplication);

        // [THEN] URL has the expected format
        // Asserted in handler
        AssertCleanedUp();
    end;

    [HyperlinkHandler]
    procedure HyperlinkHandler(URL: Text[1024])
    begin
        Assert.IsTrue(URL.Contains(HyperlinkStorage.DequeueText()), 'Unexpected URL.');
    end;

    internal procedure Initialize()
    begin
        PermissionsMock.Set('VSC Intgr. - Admin');

        TempNavInstalledApp.DeleteAll();
        TempPageInfoAndFields.DeleteAll();
        TempPublishedApplication.DeleteAll();
        HyperlinkStorage.Clear();
    end;

    internal procedure AssertCleanedUp()
    begin
        HyperlinkStorage.AssertEmpty();
    end;
}