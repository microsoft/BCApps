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
        table "No. Series" = X,
        table "No. Series Line" = X,
#if not CLEAN24
#pragma warning disable AL0432
        table "No. Series Line Sales" = X,
        table "No. Series Line Purchase" = X,
#pragma warning restore AL0432
#endif
        table "No. Series Relationship" = X,
        table "No. Series Tenant" = X,
#if not CLEAN24
#pragma warning disable AL0432
        report "No. Series" = X,
        report "No. Series Check" = X,
        codeunit NoSeriesManagement = X,
#pragma warning restore AL0432
#endif
        page "No. Series" = X,
        page "No. Series Lines" = X,
        page "No. Series Relationships" = X;
}