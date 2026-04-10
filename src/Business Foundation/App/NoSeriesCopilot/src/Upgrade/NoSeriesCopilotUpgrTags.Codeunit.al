// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 326 "No. Series Copilot Upgr. Tags"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetImplementationUpgradeTag(): Code[250]
    begin
        exit('MS-659-AddImplementationExtensibility-20240304'); //659 is the id of the issue https://github.com/microsoft/BCApps/issues/659
    end;
}
