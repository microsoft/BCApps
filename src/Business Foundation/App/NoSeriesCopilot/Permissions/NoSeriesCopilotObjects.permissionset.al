// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 330 "No. Series Copilot - Objects"
{
    Access = Internal;
    Assignable = false;
    Permissions =
        // start of <todo>
        // TODO: Uncomment this line when the semantic codeunit is ready
        tabledata "No. Series Copilot Setup" = RIMD,
        table "No. Series Copilot Setup" = X,
        page "No. Series Copilot Setup" = X,
        // end of <todo>
        codeunit "No. Series Copilot Impl." = X,
        codeunit "No. Series Cop. Semantic Impl." = X,
        codeunit "No. Series Text Match Impl." = X;
}