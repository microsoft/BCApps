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
        codeunit "No. Series Copilot Impl." = X,
        codeunit "No. Series Text Match Impl." = X;
}