// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

permissionset 686 "Paym. Prac. Read"
{
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Paym. Prac. Objects";

    Permissions =
#if NOT CLEAN29
#pragma warning disable AL0432
        tabledata "Payment Period" = R,
#pragma warning restore AL0432
#endif
        tabledata "Payment Period Header" = R,
        tabledata "Payment Period Line" = R,
        tabledata "Payment Practice Data" = R,
        tabledata "Payment Practice Line" = R,
        tabledata "Payment Practice Header" = R,
        tabledata "Paym. Prac. Dispute Ret. Data" = R;

}
