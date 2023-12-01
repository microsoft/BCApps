// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DataAdministration;

permissionset 8702 "Table Information - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Table Information Cache" = X,
                  page "Company Size Cache Part" = X,
                  page "Table Information Cache Part" = X,
                  page "Table Information" = X;
}
