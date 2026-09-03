// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Apps;
using System.TestLibraries.Apps;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133102 "Extension Marketplace Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        ExtensionManagement: Codeunit "Extension Management";
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PermissionsMock: Codeunit "Permissions Mock";
        FailingAppId: Guid;
        DetailedInstallFailureMsg: Label 'The test extension installation failed with a detailed error.';
        MarketplaceApplicationIdTxt: Label 'PAPPID.%1', Comment = '%1 = app ID', Locked = true;
        MicrosoftPublisherTxt: Label 'Microsoft', Locked = true;
        FixtureNotPublishedErr: Label 'The extension test fixture %1 must be published and tenant-visible before running this test.', Comment = '%1 = app ID';
        ExtensionInstalledErr: Label 'The extension should not be installed.';
        PendingSetupNotClearedErr: Label 'The failed installation should clear pending extension setup for the current user.';

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallMarketplaceExtensionPageHandler,InstallationMessageHandler')]
    procedure FailedFirstPartyInstallShowsOriginalError()
    begin
        // [GIVEN] A published first-party extension that raises an installation error
        Initialize();
        AssertFirstPartyFixturePublished();
        LibraryVariableStorage.Enqueue(DetailedInstallFailureMsg);

        // [WHEN] Installing the extension from AppSource
        ExtensionManagement.InstallMarketplaceExtension(FailingAppId);

        // [THEN] The original error is shown exactly once and the extension remains uninstalled
        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(FailingAppId), ExtensionInstalledErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallMarketplaceExtensionPageHandler,InstallationMessageHandler')]
    procedure FailedFirstPartyInstallByMarketplaceIdShowsOriginalError()
    begin
        // [GIVEN] A published first-party extension that raises an installation error
        Initialize();
        AssertFirstPartyFixturePublished();
        LibraryVariableStorage.Enqueue(DetailedInstallFailureMsg);

        // [WHEN] Installing the extension from an AppSource marketplace ID
        ExtensionMgtTestLibrary.InstallMarketplaceExtension(StrSubstNo(MarketplaceApplicationIdTxt, FailingAppId));

        // [THEN] The original error is shown exactly once and the extension remains uninstalled
        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(FailingAppId), ExtensionInstalledErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallMarketplaceExtensionPageHandler,InstallationMessageHandler')]
    procedure FailedFirstPartyInstallClearsPendingSetup()
    begin
        // [GIVEN] A published first-party extension that raises an installation error and pending setup exists
        Initialize();
        AssertFirstPartyFixturePublished();
        ExtensionMgtTestLibrary.CreatePendingExtensionSetup(FailingAppId);
        LibraryVariableStorage.Enqueue(DetailedInstallFailureMsg);

        // [WHEN] Installing the extension from AppSource
        ExtensionManagement.InstallMarketplaceExtension(FailingAppId);

        // [THEN] The original error is shown exactly once and pending setup is cleared
        Assert.IsTrue(ExtensionMgtTestLibrary.IsPendingExtensionSetupEmpty(), PendingSetupNotClearedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');
        FailingAppId := '858fafc0-9ef8-4430-88a3-869469587eea';
        LibraryVariableStorage.Clear();
        ExtensionMgtTestLibrary.ClearPendingExtensionSetup();
        ExtensionMgtTestLibrary.UninstallExtensionIfInstalled(FailingAppId);
    end;

    local procedure AssertFirstPartyFixturePublished()
    var
        PublishedApplication: Record "Published Application";
    begin
        PublishedApplication.SetRange(ID, FailingAppId);
        PublishedApplication.SetRange(Publisher, MicrosoftPublisherTxt);
        PublishedApplication.SetRange("Tenant Visible", true);
        Assert.IsFalse(PublishedApplication.IsEmpty(), StrSubstNo(FixtureNotPublishedErr, FailingAppId));
    end;

    [ModalPageHandler]
    procedure InstallMarketplaceExtensionPageHandler(var MarketplaceExtnDeployment: TestPage "Marketplace Extn Deployment")
    begin
        MarketplaceExtnDeployment.Continue.Invoke();
        MarketplaceExtnDeployment.Install.Invoke();
    end;

    [MessageHandler]
    procedure InstallationMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}
