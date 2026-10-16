// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

using System.Apps;

codeunit 135109 "Extension Mgt. Test Library"
{
    var
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";

    procedure RunExtensionSetup(AppId: Guid)
    begin
        ExtensionInstallationImpl.RunExtensionSetup(AppId);
    end;

    procedure SetAppId(Id: Guid; var MarketplaceExtnDeployment: Page "Marketplace Extn Deployment")
    begin
        MarketplaceExtnDeployment.SetAppID(Id);
    end;

    /// <summary>
    /// Shows the installation failure prompt that opens Extension Installation Status.
    /// </summary>
    procedure ShowInstallFailureStatus()
    begin
        ExtensionOperationImpl.ShowInstallFailureStatus();
    end;

    /// <summary>
    /// Runs the AppSource installation flow, refreshing the session after a successful installation.
    /// </summary>
    /// <param name="MarketplaceApplicationId">The marketplace identifier containing a PAPPID token with the extension's app ID.</param>
    procedure InstallAppsourceExtensionWithRefreshSession(MarketplaceApplicationId: Text)
    var
        ExtensionMarketplace: Codeunit "Extension Marketplace";
    begin
        ExtensionMarketplace.InstallAppsourceExtensionWithRefreshSession(MarketplaceApplicationId, '');
    end;

    /// <summary>
    /// Opens the extension installation page using the app ID and preview key as page filters.
    /// </summary>
    /// <param name="AppId">The ID of the extension to install.</param>
    /// <param name="PreviewKey">The preview access key, or empty text for the public installation flow.</param>
    procedure RunExtensionInstallationPage(AppId: Guid; PreviewKey: Text)
    var
        TempExtensionInstallation: Record "Extension Installation";
    begin
        TempExtensionInstallation.SetRange(ID, AppId);
        if PreviewKey <> '' then
            TempExtensionInstallation.SetRange(PreviewKey, PreviewKey);

        Page.Run(Page::"Extension Installation", TempExtensionInstallation);
    end;
}
