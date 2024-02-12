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
#if not CLEAN24
#pragma warning disable AL0432
        report "No. Series" = X,
        report "No. Series Check" = X,
#pragma warning restore AL0432
#endif
        page "No. Series" = X,
        page "No. Series Lines" = X,
        page "No. Series Lines Part" = X,
#if not CLEAN24
#pragma warning disable AL0432
        page "No. Series Lines Purchase" = X,
        page "No. Series Lines Sales" = X,
#pragma warning restore AL0432
#endif
        page "No. Series Relationships" = X,
        page "No. Series Relationships Part" = X,
        Codeunit "No. Series - Setup" = X;
}
