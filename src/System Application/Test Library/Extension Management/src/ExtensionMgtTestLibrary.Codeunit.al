// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

using System.Apps;

codeunit 135109 "Extension Mgt. Test Library"
{
    var
        ExtensionManagement: Codeunit "Extension Management";
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";

    procedure RunExtensionSetup(AppId: Guid)
    begin
        ExtensionInstallationImpl.RunExtensionSetup(AppId);
    end;

    procedure SetAppId(Id: Guid; var MarketplaceExtnDeployment: Page "Marketplace Extn Deployment")
    begin
        MarketplaceExtnDeployment.SetAppID(Id);
    end;

    procedure CreatePendingExtensionSetup(AppId: Guid)
    var
        ExtensionPendingSetup: Record "Extension Pending Setup";
    begin
        ClearPendingExtensionSetup();
        ExtensionPendingSetup."User Id" := UserSecurityId();
        ExtensionPendingSetup."App Id" := AppId;
        ExtensionPendingSetup."Created On" := CurrentDateTime();
        ExtensionPendingSetup.Insert();
    end;

    procedure ClearPendingExtensionSetup()
    var
        ExtensionPendingSetup: Record "Extension Pending Setup";
    begin
        ExtensionPendingSetup.SetRange("User Id", UserSecurityId());
        ExtensionPendingSetup.DeleteAll();
    end;

    procedure IsPendingExtensionSetupEmpty(): Boolean
    var
        ExtensionPendingSetup: Record "Extension Pending Setup";
    begin
        ExtensionPendingSetup.SetRange("User Id", UserSecurityId());
        exit(ExtensionPendingSetup.IsEmpty());
    end;

    procedure UninstallExtensionIfInstalled(AppId: Guid)
    var
        PackageId: Guid;
    begin
        if not ExtensionManagement.IsInstalledByAppId(AppId) then
            exit;

        PackageId := ExtensionManagement.GetCurrentlyInstalledVersionPackageIdByAppId(AppId);
        ExtensionManagement.UninstallExtension(PackageId, false);
    end;

    procedure InstallMarketplaceExtension(MarketplaceApplicationId: Text)
    var
        ExtensionMarketplace: Codeunit "Extension Marketplace";
    begin
        ExtensionMarketplace.InstallAppsourceExtensionWithRefreshSession(MarketplaceApplicationId, '');
    end;
}
