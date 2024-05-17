// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 332 "No. Series Upgrade Tags"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetImplementationUpgradeTag(): Code[250]
    begin
        exit('MS-471519-AddImplementationExtensibility-20231206 ');
    end;
}
