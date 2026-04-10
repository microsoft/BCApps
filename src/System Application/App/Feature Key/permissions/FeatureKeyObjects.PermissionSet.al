// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

permissionset 2609 "Feature Key - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Feature Management Facade" = X,
                  page "Feature Management" = X,
                  page "Schedule Feature Data Update" = X,
                  table "Feature Data Update Status" = X;
}