#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Apps;
using System.Utilities;

codeunit 10821 "Sales FR Feature Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "NAV App Installed App" = r;
    ObsoleteReason = 'Feature Sales FR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        SalesFRFeatureKeyIdTok: Label 'SalesFR', Locked = true;
        SalesFRAppIdTok: Label '8df591a3-d767-4475-8bff-44b8b5527477', Locked = true;
        InstallSalesFRAppQst: Label 'The Sales FR feature is provided by the Sales FR app, which is not installed. The feature has no effect until the app is installed.\\Do you want to install the app now?';
        SalesFRAppNotInstalledErr: Label 'The Sales FR feature cannot be enabled because the Sales FR app is not installed. Install the app on the Extension Management page, and then enable the feature.';
        SalesFRAppNotPublishedErr: Label 'The Sales FR feature cannot be enabled because the Sales FR app is not available in this environment. Contact your system administrator.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure VerifySalesFRAppOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        if FeatureKey.ID <> SalesFRFeatureKeyIdTok then
            exit;

        // Without read permission the installation state cannot be verified, so the user is not blocked.
        if not NAVAppInstalledApp.ReadPermission() then
            exit;

        if NAVAppInstalledApp.Get(GetSalesFRAppId()) then
            exit;

        if GuiAllowed() then
            InstallSalesFRApp();

        if not NAVAppInstalledApp.Get(GetSalesFRAppId()) then
            Error(SalesFRAppNotInstalledErr);
    end;

    local procedure InstallSalesFRApp()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ExtensionManagement: Codeunit "Extension Management";
        PackageId: Guid;
    begin
        if not ConfirmManagement.GetResponseOrDefault(InstallSalesFRAppQst, false) then
            exit;

        PackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(GetSalesFRAppId());
        if IsNullGuid(PackageId) then
            Error(SalesFRAppNotPublishedErr);

        // The feature key validation runs inside a write transaction, which the installer cannot run in.
        Commit();
        ExtensionManagement.InstallExtension(PackageId, GlobalLanguage(), true);
    end;

    local procedure GetSalesFRAppId(): Guid
    begin
        exit(SalesFRAppIdTok);
    end;
}
#endif
