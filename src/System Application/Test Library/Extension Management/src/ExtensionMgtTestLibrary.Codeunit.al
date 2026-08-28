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

    procedure CanManageExtensions(): Boolean
    begin
        exit(ExtensionInstallationImpl.CanManageExtensions());
    end;

    procedure CanManageExtensions(UserSecurityId: Guid): Boolean
    begin
        exit(ExtensionInstallationImpl.CanManageExtensions(UserSecurityId));
    end;

    procedure CheckPermissions(UserSecurityId: Guid)
    begin
        ExtensionInstallationImpl.CheckPermissions(UserSecurityId);
    end;

    procedure RunExtensionSetup(AppId: Guid)
    begin
        ExtensionInstallationImpl.RunExtensionSetup(AppId);
    end;

    procedure SetAppId(Id: Guid; var MarketplaceExtnDeployment: Page "Marketplace Extn Deployment")
    begin
        MarketplaceExtnDeployment.SetAppID(Id);
    end;
}