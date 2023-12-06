// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Excel;

permissionset 1488 "Edit in Excel - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Edit in Excel" = X,
                  codeunit "Edit in Excel Workbook" = X,
                  page "Excel Centralized Depl. Wizard" = X;
}
