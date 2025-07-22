// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 290 "No. Series Copilot Install"
{
    Subtype = Install;
    Access = Internal;

    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnInstallAppPerDatabase()
    var
        NoSeriesCopilotRegister: Codeunit "No. Series Copilot Register";
    begin
        NoSeriesCopilotRegister.RegisterCapability();
    end;
}