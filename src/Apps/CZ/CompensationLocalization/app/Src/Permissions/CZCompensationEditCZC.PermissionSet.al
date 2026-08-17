// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

permissionset 11771 "CZ Compensation - Edit CZC"
{
    Access = Internal;
    Assignable = false;
    Caption = 'CZ Compensation - Edit';

    IncludedPermissionSets = "CZ Compensation - Read CZC";

    Permissions = tabledata "Compensation Header CZC" = IMD,
#if not CLEAN29
#pragma warning disable AL0432
                  tabledata "Compens. Report Selections CZC" = IMD,
#pragma warning restore AL0432
#endif
                  tabledata "Compensation Line CZC" = IMD,
                  tabledata "Compensations Setup CZC" = IMD,
                  tabledata "Posted Compensation Header CZC" = IMD,
                  tabledata "Posted Compensation Line CZC" = IMD;
}
