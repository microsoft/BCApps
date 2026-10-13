// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Apps;
using System.Environment.Configuration;
using System.Media;
using System.TestLibraries.Apps;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133100 "Extension Management Test"
{

    // For the purpose of this test, two sample extensions are pre-published.
    // The condition for the tests to pass is that one of the extensions is holding a dependency on the other one, and they are both 1st Party Extensions, version 1.0.
    // The appIds' of the two extensions are set in the SetNavAppIds procedure.
    // The two extensions are pre-build outside the testing extension , and it is only the resulting .app files that are moved to a "testArtifacts" folder within the test library of this extension.
    // The tests script will therefore publish the two extensions separately so the tests in this codeunit can execute and complete succesfully.

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        ExtensionManagement: Codeunit "Extension Management";
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        MainAppId: Guid;
        DependingAppId: Guid;
        NotInstalledSuccErr: Label 'Extension was not installed succesfully';
        NotUninstalledSuccErr: Label 'Extension has not been uninstalled succesfully';
        MainExtNotInstalledSuccErr: Label 'The extension the current extension is depending on was not installed succesfully';
        DependingExtNotInstalledSuccErr: Label 'The extension depending on the current extension was not uninstalled succesfully';
        ExtensionInstalleddErr: Label 'Extension should not be installed';
        ExtensionNotInstalledErr: Label 'Extension should be installed.';
        PackageIdExistsErr: Label 'The returned extension pakage does not exist';
        NullPackageIdErr: Label 'There should not be an extension corresponding to the returned package ID';
        PackageIdExtensionVersionErr: Label 'The package Id does not poin to the correct extension version';

    local procedure SetNavAppIds()
    begin
        MainAppId := '9d939f81-be24-481f-9352-830c0346c171';
        DependingAppId := 'c4123d81-a537-4062-bdd4-7b9882bcc319';
    end;

    local procedure InitializeExtensions()
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        if NAVAppInstalledApp.Get(MainAppId) then
            ExtensionManagement.UninstallExtension(NAVAppInstalledApp."Package ID", false);
        if NAVAppInstalledApp.Get(DependingAppId) then
            ExtensionManagement.UninstallExtension(NAVAppInstalledApp."Package ID", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstallUninstallExtension()
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
        MainAppPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        MainAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
        ExtensionManagement.InstallExtension(MainAppPackageId, GlobalLanguage(), false);
        Assert.IsTrue(NAVAppInstalledApp.Get(MainAppId), NotInstalledSuccErr);

        ExtensionManagement.UninstallExtension(MainAppPackageId, false);
        Assert.IsFalse(NAVAppInstalledApp.Get(MainAppId), NotUninstalledSuccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstallExtensionDependencies()
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
        MainPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        MainPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);

        ExtensionManagement.InstallExtension(MainPackageId, GlobalLanguage(), false);
        Assert.IsTrue(NAVAppInstalledApp.Get(MainAppId), MainExtNotInstalledSuccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UninstallExtensionDependents()
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
        MainAppPackageId: Guid;
        DependingAppPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        MainAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
        DependingAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(DependingAppId);

        ExtensionManagement.InstallExtension(MainAppPackageId, GlobalLanguage(), false);
        ExtensionManagement.InstallExtension(DependingAppPackageId, GlobalLanguage(), false);
        ExtensionManagement.UninstallExtension(MainAppPackageId, false);

        Assert.IsFalse(NAVAppInstalledApp.Get(DependingAppId), DependingExtNotInstalledSuccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsExtensionInstalledByPackageId()
    var
        MainAppPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        MainAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);

        ExtensionManagement.InstallExtension(MainAppPackageId, GlobalLanguage(), false);
        Assert.IsTrue(ExtensionManagement.IsInstalledByPackageId(MainAppPackageId), ExtensionNotInstalledErr);

        ExtensionManagement.UninstallExtension(MainAppPackageId, false);

        Assert.IsFalse(ExtensionManagement.IsInstalledByPackageId(MainAppPackageId), ExtensionInstalleddErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsExtensionInstalledByAppId()
    var
        MainAppPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        MainAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);

        ExtensionManagement.InstallExtension(MainAppPackageId, GlobalLanguage(), false);
        Assert.IsTrue(ExtensionManagement.IsInstalledByAppId(MainAppId), ExtensionNotInstalledErr);

        ExtensionManagement.UninstallExtension(MainAppPackageId, false);

        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(MainAppId), ExtensionInstalleddErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLatestVersionPackageIdByAppId()
    var
        PublishedApplication: Record "Published Application";
        PackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();

        PackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
        PublishedApplication.SetRange("Package ID", PackageId);
        PublishedApplication.SetRange("Tenant Visible", true);

        Assert.IsTrue(PublishedApplication.FindFirst(), PackageIdExistsErr);
        Assert.AreEqual(PublishedApplication."Version Major", 1, PackageIdExtensionVersionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCurrentlyInstalledVersionPackageIdByAppId()
    var
        PublishedApplication: Record "Published Application";
        PackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();
        InitializeExtensions();

        PackageId := ExtensionManagement.GetCurrentlyInstalledVersionPackageIdByAppId(MainAppId);
        Assert.IsTrue(IsNullGuid(PackageId), NullPackageIdErr);

        PackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
        ExtensionManagement.InstallExtension(PackageId, GlobalLanguage(), false);
        PackageId := ExtensionManagement.GetCurrentlyInstalledVersionPackageIdByAppId(MainAppId);
        PublishedApplication.SetRange("Package ID", PackageId);
        PublishedApplication.SetRange("Tenant Visible", true);

        Assert.IsTrue(PublishedApplication.FindFirst(), PackageIdExistsErr);
        Assert.AreEqual(PublishedApplication."Version Major", 1, PackageIdExtensionVersionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSpecificVersionPackageIdByAppId()
    var
        PublishedApplication: Record "Published Application";
        PackageId: Guid;
        NullGuid: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        SetNavAppIds();

        PackageId := ExtensionManagement.GetSpecificVersionPackageIdByAppId(NullGuid, '', 0, 0, 0, 0);
        Assert.IsTrue(ISNULLGUID(PackageId), NullPackageIdErr);

        PackageId := ExtensionManagement.GetSpecificVersionPackageIdByAppId(MainAppId, '', 0, 0, 0, 0);
        PublishedApplication.SetRange("Package ID", PackageId);
        PublishedApplication.SetRange("Tenant Visible", true);

        Assert.IsFalse(PublishedApplication.IsEmpty(), PackageIdExistsErr);

        PackageId := ExtensionManagement.GetSpecificVersionPackageIdByAppId(MainAppId, '', 1, 0, 0, 0);
        PublishedApplication.SetRange("Package ID", PackageId);
        PublishedApplication.SetRange("Tenant Visible", true);

        Assert.IsTrue(PublishedApplication.FindFirst(), PackageIdExistsErr);
        Assert.AreEqual(PublishedApplication."Version Major", 1, PackageIdExtensionVersionErr);

        PackageId := ExtensionManagement.GetSpecificVersionPackageIdByAppId(MainAppId, '', 1, 0, 0, 0);
        PublishedApplication.SetRange("Package ID", PackageId);
        PublishedApplication.SetRange("Tenant Visible", true);

        Assert.IsTrue(PublishedApplication.FindFirst(), PackageIdExistsErr);
        Assert.AreEqual(PublishedApplication."Version Major", 1, PackageIdExtensionVersionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure MessageShownOnInvokingSetupThisAppWhenNoSetupDefinedForExtension()
    var
        MainAppPackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] 2 extensions published but not installed
        SetNavAppIds();
        InitializeExtensions();

        // [GIVEN] Install an extension
        MainAppPackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
        ExtensionManagement.InstallExtension(MainAppPackageId, GlobalLanguage(), false);

        // [WHEN] RunExtensionSetup is invoked
        // [THEN] Message is shown
        ExtensionMgtTestLibrary.RunExtensionSetup(MainAppId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownOnInvokingSetupThisAppWhenSelectedExtensionIsNotInstalled()
    var
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] 2 extensions published but not installed
        SetNavAppIds();
        InitializeExtensions();

        // [WHEN] RunExtensionSetup is invoked
        // [THEN] Error is thrown saying that the extension is not installed
        asserterror ExtensionMgtTestLibrary.RunExtensionSetup(MainAppId);
        Assert.ExpectedError('is not installed');
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler')]
    [Scope('OnPrem')]
    procedure SetupPageIsRunOnInvokingSetupThisAppWhenOnlyOneSetupExistsAndNoPrimarySetupDefinedForAnExtension()
    var
        GuidedExperience: Codeunit "Guided Experience";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] RunExtensionSetup is invoked
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);

        // [THEN] Modal handler handles the opened setup page
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler')]
    [Scope('OnPrem')]
    procedure SetupIsRunOnInvokingSetupWhenObjectIsNonPageType()
    var
        GuidedExperience: Codeunit "Guided Experience";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Codeunit, Codeunit::"Sample Setup For Test", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] RunExtensionSetup is invoked
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);

        // [THEN] Modal handler handles the opened setup page
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler')]
    [Scope('OnPrem')]
    procedure SetupPageIsRunOnInvokingSetupThisAppWhenOnlyOneSetupExistsAndOnePrimarySetupDefinedForAnExtension()
    var
        GuidedExperience: Codeunit "Guided Experience";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);

        // [WHEN] RunExtensionSetup is invoked
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);

        // [THEN] Modal handler handles the opened setup page
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetupPageIsRunOnInvokingSetupThisAppWhenOnlyTwoSetupExistsAndOnePrimarySetupDefinedForAnExtension()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AppSetupList: TestPage "App Setup List";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Details");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Details", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] RunExtensionSetup is invoked
        AppSetupList.Trap();
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);

        // [THEN] Modal handler handles the opened setup page
    end;

    [Test]
    //[HandlerFunctions('ExtensionSettingsModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetupListIsShownOnInvokingSetupThisAppWhenOnlyTwoSetupExistsAndNoPrimarySetupDefinedForAnExtension()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AppSetupList: TestPage "App Setup List";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Details");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Details", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] RunExtensionSetup is invoked
        AppSetupList.Trap();
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);

        // [THEN] Modal handler handles the opened setup page and then AppSetupList handles the resulting setup list
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhenDefiningMoreThanOneAsPrimarySetupForAnExtensionTheLastOneWins()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AppSetupList: TestPage "App Setup List";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Details");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");

        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Details", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);
        // [WHEN] A second setup page is marked as primary
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);

        // [THEN] The last setup wins
        AppSetupList.Trap();
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);
    end;

    [Test]
    [HandlerFunctions('ExtensionSettingsModalHandler')]
    [Scope('OnPrem')]
    procedure ExistingSetupCanBeMarkedAsPrimary()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AppSetupList: TestPage "App Setup List";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Details");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");
        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] Call Insert again with IsPrimary = true
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);

        // [THEN] Setup is marked as Primary and runs
        AppSetupList.Trap();
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupCanBeUnmarkedAsPrimary()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AppSetupList: TestPage "App Setup List";
        ModuleInformation: ModuleInfo;
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
    begin
        // Initialize
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Settings");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Extension Details");
        GuidedExperience.Remove("Guided Experience Type"::"Assisted Setup", ObjectType::Codeunit, Codeunit::"Sample Setup For Test");
        PermissionsMock.Set('Exten. Mgt. - Admin');

        // [GIVEN] A Assisted Setup for the current extension
        Title := CopyStr(MainAppId, 1, MaxStrLen(Title));
        ShortTitle := CopyStr(MainAppId, 1, MaxStrLen(ShortTitle));
        Description := CopyStr(DependingAppId, 1, MaxStrLen(Description));
        NavApp.GetCurrentModuleInfo(ModuleInformation);

        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', true);
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Details", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');

        // [WHEN] Unmark the setup as primary
        GuidedExperience.InsertAssistedSetup(Title, ShortTitle, Description, 0, ObjectType::Page, Page::"Extension Settings", "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '', false);

        // [THEN] PrimaryGuidedExperienceItem has been deleted
        AppSetupList.Trap();
        ExtensionMgtTestLibrary.RunExtensionSetup(ModuleInformation.Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionSettingsDoesNotAllowNew()
    var
        ExtensionSettings: TestPage "Extension Settings";
    begin
        PrepareSettingsExtension(false);
        OpenExtensionSettings(ExtensionSettings);

        asserterror ExtensionSettings.New();
        Assert.ExpectedError('Insert is not allowed. Page = Extension Settings, Id = 2511.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionSettingsAllowsEditingHttpClientRequests()
    var
        NAVAppSetting: Record "NAV App Setting";
        ExtensionSettings: TestPage "Extension Settings";
        AllowHttpClientRequests: Boolean;
    begin
        PrepareSettingsExtension(false);
        OpenExtensionSettings(ExtensionSettings);
        ExtensionSettings.Edit().Invoke();
        Assert.IsTrue(ExtensionSettings.AllowHttpClientRequests.Editable(), 'HTTP client settings should remain editable.');

        AllowHttpClientRequests := not ExtensionSettings.AllowHttpClientRequests.AsBoolean();
        ExtensionSettings.AllowHttpClientRequests.SetValue(AllowHttpClientRequests);
        ExtensionSettings.Close();

        NAVAppSetting.Get(MainAppId);
        Assert.AreEqual(AllowHttpClientRequests, NAVAppSetting."Allow HttpClient Requests", 'The edited setting should be saved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionSettingsDisablesUninstallWhenNotInstalled()
    var
        ExtensionSettings: TestPage "Extension Settings";
    begin
        PrepareSettingsExtension(false);
        OpenExtensionSettings(ExtensionSettings);

        Assert.IsFalse(ExtensionSettings.Uninstall.Enabled(), 'Uninstall should be disabled for an uninstalled app.');
        Assert.IsFalse(ExtensionSettings.SetupApp.Enabled(), 'Set up should be disabled for an uninstalled app.');
        Assert.IsTrue(ExtensionSettings.Install.Enabled(), 'Install should be enabled for an uninstalled app.');
        ExtensionSettings.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure ExtensionSettingsUninstallsSelectedExtension()
    var
        ExtensionSettings: TestPage "Extension Settings";
        ExtensionDetails: TestPage "Extension Details";
    begin
        PrepareSettingsExtension(true);
        OpenExtensionSettings(ExtensionSettings);

        Assert.IsTrue(ExtensionSettings.Uninstall.Enabled(), 'Uninstall should be enabled for an installed app.');
        Assert.IsTrue(ExtensionSettings.SetupApp.Enabled(), 'Set up should be enabled for an installed app.');
        Assert.IsFalse(ExtensionSettings.Install.Enabled(), 'Install should be disabled for an installed app.');
        Assert.IsFalse(ExtensionSettings.Unpublish.Enabled(), 'Unpublish should be disabled for an installed app.');

        ExtensionDetails.Trap();
        ExtensionSettings.Uninstall.Invoke();
        ExtensionDetails.Un_Id.AssertEquals(LowerCase(DelChr(Format(MainAppId), '=', '{}')));
        Assert.IsTrue(ExtensionDetails.Uninstall.Visible(), 'The existing uninstall experience should open.');
        ExtensionDetails.Uninstall.Invoke();

        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(MainAppId), 'The selected extension should be uninstalled.');
        Assert.IsFalse(ExtensionSettings.Uninstall.Enabled(), 'Uninstall should be disabled after returning to the card.');
        Assert.IsTrue(ExtensionSettings.Install.Enabled(), 'Install should be enabled after returning to the card.');
        ExtensionSettings.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstalledMarketplaceRequestDoesNotReopenWizard()
    begin
        PrepareSettingsExtension(true);

        // No page handlers: reopening the installation or setup UI fails this test.
        ExtensionManagement.InstallMarketplaceExtension(MainAppId);
        ExtensionManagement.InstallMarketplaceExtension(MainAppId);

        Assert.IsTrue(ExtensionManagement.IsInstalledByAppId(MainAppId), 'The existing installation should be unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstalledAppsourceRequestDoesNotReopenWizard()
    begin
        PrepareSettingsExtension(true);

        ExtensionMgtTestLibrary.InstallAppsourceExtensionWithRefreshSession('PAPPID.' + Format(MainAppId));

        Assert.IsTrue(ExtensionManagement.IsInstalledByAppId(MainAppId), 'The existing installation should be unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenedInstallationPageSkipsInstalledApp()
    begin
        PrepareSettingsExtension(true);

        // Simulate restoring the installation page from its filters in the refreshed session.
        ExtensionMgtTestLibrary.RunExtensionInstallationPage(MainAppId, '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MarketplaceDeploymentModalHandler,DeclineInstallFailureStatusConfirmHandler')]
    procedure UninstalledMarketplaceRequestStillOpensWizard()
    begin
        PrepareSettingsExtension(false);

        ExtensionManagement.InstallMarketplaceExtension(MainAppId);

        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(MainAppId), 'Closing the wizard should not install the app.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MarketplacePreviewDeploymentModalHandler')]
    procedure InstalledAppPreviewRequestStillOpensWizard()
    begin
        PrepareSettingsExtension(true);

        ExtensionMgtTestLibrary.RunExtensionInstallationPage(MainAppId, 'test-preview-key');
    end;

    local procedure PrepareSettingsExtension(Install: Boolean)
    var
        PackageId: Guid;
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');
        SetNavAppIds();
        InitializeExtensions();
        if Install then begin
            PackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(MainAppId);
            ExtensionManagement.InstallExtension(PackageId, GlobalLanguage(), false);
            Assert.IsTrue(ExtensionManagement.IsInstalledByAppId(MainAppId), NotInstalledSuccErr);
        end;
    end;

    local procedure OpenExtensionSettings(var ExtensionSettings: TestPage "Extension Settings")
    var
        NAVAppSetting: Record "NAV App Setting";
        ExtensionSettingsPage: Page "Extension Settings";
    begin
        NAVAppSetting.SetRange("App ID", MainAppId);
        ExtensionSettingsPage.SetTableView(NAVAppSetting);
        ExtensionSettings.Trap();
        ExtensionSettingsPage.Run();
    end;

    [ModalPageHandler]
    procedure MarketplaceDeploymentModalHandler(var MarketplaceExtnDeployment: TestPage "Marketplace Extn Deployment")
    begin
        Assert.IsTrue(MarketplaceExtnDeployment.Continue.Visible(), 'The installation wizard should open at the disclaimer.');
        MarketplaceExtnDeployment.Continue.Invoke();
        Assert.IsTrue(MarketplaceExtnDeployment.Install.Visible(), 'The installation step should remain available.');
        MarketplaceExtnDeployment.Close();
    end;

    [ModalPageHandler]
    procedure MarketplacePreviewDeploymentModalHandler(var MarketplaceExtnDeployment: TestPage "Marketplace Extn Deployment")
    begin
        MarketplaceExtnDeployment.Continue.Invoke();
        Assert.IsTrue(MarketplaceExtnDeployment.PreviewInfo.Visible(), 'Preview requests should retain the preview installation flow.');
        MarketplaceExtnDeployment.Close();
    end;

    [ConfirmHandler]
    procedure DeclineInstallFailureStatusConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure ExtensionSettingsModalHandler(var ExtensionSettings: TestPage "Extension Settings")
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
