// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 300 "No. Series - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
        page "No. Series" = X,
        page "No. Series Lines" = X,
        page "No. Series Lines Part" = X,
        page "No. Series Relationships" = X,
        page "No. Series Relationships Part" = X,
        Codeunit "No. Series - Setup" = X;
}