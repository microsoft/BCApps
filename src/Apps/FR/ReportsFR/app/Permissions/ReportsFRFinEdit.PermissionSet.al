// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

permissionset 10828 "Reports FR Fin. Edit"
{
    Assignable = true;
    Caption = 'French schedules - maintain';
    IncludedPermissionSets = "Reports FR Fin. Read";

    Permissions = tabledata "FR Financial Schedule Name" = RIMD,
                  tabledata "FR Financial Schedule Line" = RIMD;
}
