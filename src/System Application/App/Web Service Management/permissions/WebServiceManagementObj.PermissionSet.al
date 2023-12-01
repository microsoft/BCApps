// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

permissionset 810 "Web Service Management - Obj."
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Web Service Management" = X,
                  table "Tenant Web Service Columns" = X,
                  table "Tenant Web Service Filter" = X,
                  table "Tenant Web Service OData" = X,
                  table "Web Service Aggregate" = X;
}
