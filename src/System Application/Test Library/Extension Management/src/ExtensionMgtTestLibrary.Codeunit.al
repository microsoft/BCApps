// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

using System.Apps;

codeunit 135109 "Extension Mgt. Test Library"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Installation Impl", OnCanManageExtensions, '', false, false)]
    local procedure AuthorizeTestSession(var Result: Boolean)
    begin
        Result := true;
    end;

    var
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";

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

    /// <summary>
    /// Shows the installation failure prompt that opens Extension Installation Status.
    /// </summary>
    procedure ShowInstallFailureStatus()
    begin
        ExtensionOperationImpl.ShowInstallFailureStatus();
    end;
}
