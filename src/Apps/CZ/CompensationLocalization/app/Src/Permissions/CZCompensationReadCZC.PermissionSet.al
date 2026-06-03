// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

permissionset 11770 "CZ Compensation - Read CZC"
{
    Access = Internal;
    Assignable = false;
    Caption = 'CZ Compensation - Read';

    IncludedPermissionSets = "CZ Compensation - Objects CZC";

    Permissions = tabledata "Compensation Header CZC" = R,
#if not CLEAN29
#pragma warning disable AL0432
                  tabledata "Compens. Report Selections CZC" = R,
#pragma warning restore AL0432
#endif
                  tabledata "Compensation Line CZC" = R,
                  tabledata "Compensations Setup CZC" = R,
                  tabledata "Posted Compensation Header CZC" = R,
                  tabledata "Posted Compensation Line CZC" = R;
}
