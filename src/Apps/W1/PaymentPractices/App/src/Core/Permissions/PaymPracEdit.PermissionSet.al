// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

permissionset 687 "Paym. Prac. Edit"
{
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Paym. Prac. Read";

    Permissions =
#if NOT CLEAN29
#pragma warning disable AL0432
        tabledata "Payment Period" = IMD,
#pragma warning restore AL0432
#endif
        tabledata "Payment Period Header" = IMD,
        tabledata "Payment Period Line" = IMD,
        tabledata "Payment Practice Data" = IMD,
        tabledata "Payment Practice Line" = IMD,
        tabledata "Payment Practice Header" = IMD,
        tabledata "Paym. Prac. Dispute Ret. Data" = IMD;

}
