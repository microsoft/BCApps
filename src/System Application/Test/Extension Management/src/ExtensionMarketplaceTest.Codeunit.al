// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Apps;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133102 "Extension Marketplace Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        ExtensionManagement: Codeunit "Extension Management";
        PermissionsMock: Codeunit "Permissions Mock";
        FailingAppId: Guid;
        DetailedInstallFailureMsg: Label 'The test extension installation failed with a detailed error.';
        MicrosoftPublisherTxt: Label 'Microsoft', Locked = true;
        FixtureNotPublishedErr: Label 'The extension test fixture %1 must be published and tenant-visible before running this test.', Comment = '%1 = app ID';
        FixtureInstalledErr: Label 'The extension test fixture must not be installed before running this test.';
        WrongMessageErr: Label 'The installation message was not the expected message. Actual message: %1', Comment = '%1 = actual message';
        ExtensionInstalledErr: Label 'The extension should not be installed.';
        PendingSetupNotClearedErr: Label 'The failed installation should clear pending extension setup for the current user.';

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallMarketplaceExtensionPageHandler,InstallationMessageHandler')]
    procedure FailedFirstPartyInstallShowsOriginalError()
    begin
        Initialize();
        AssertFirstPartyFixturePublished();

        ExtensionManagement.InstallMarketplaceExtension(FailingAppId);

        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(FailingAppId), ExtensionInstalledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallMarketplaceExtensionPageHandler,InstallationMessageHandler')]
    procedure FailedFirstPartyInstallClearsPendingSetup()
    var
        ExtensionPendingSetup: Record "Extension Pending Setup";
    begin
        Initialize();
        AssertFirstPartyFixturePublished();
        InsertPendingSetup(ExtensionPendingSetup);

        ExtensionManagement.InstallMarketplaceExtension(FailingAppId);

        ExtensionPendingSetup.SetRange("User Id", UserSecurityId());
        Assert.IsTrue(ExtensionPendingSetup.IsEmpty(), PendingSetupNotClearedErr);
    end;

    local procedure Initialize()
    var
        ExtensionPendingSetup: Record "Extension Pending Setup";
    begin
        PermissionsMock.Set('Exten. Mgt. - Admin');
        FailingAppId := '858fafc0-9ef8-4430-88a3-869469587eea';

        ExtensionPendingSetup.SetRange("User Id", UserSecurityId());
        ExtensionPendingSetup.DeleteAll();

        Assert.IsFalse(ExtensionManagement.IsInstalledByAppId(FailingAppId), FixtureInstalledErr);
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

    local procedure InsertPendingSetup(var ExtensionPendingSetup: Record "Extension Pending Setup")
    begin
        ExtensionPendingSetup."User Id" := UserSecurityId();
        ExtensionPendingSetup."App Id" := FailingAppId;
        ExtensionPendingSetup."Created On" := CurrentDateTime();
        ExtensionPendingSetup.Insert();
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
        Assert.IsTrue(StrPos(Message, DetailedInstallFailureMsg) > 0, StrSubstNo(WrongMessageErr, Message));
    end;
}
