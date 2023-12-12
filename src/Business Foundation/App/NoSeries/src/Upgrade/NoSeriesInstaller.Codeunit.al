// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 329 "No. Series Installer"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        NoSeriesUpgrade: Codeunit "No. Series Upgrade";
    begin
        NoSeriesUpgrade.SetupNoSeriesImplementation();
    end;
}
