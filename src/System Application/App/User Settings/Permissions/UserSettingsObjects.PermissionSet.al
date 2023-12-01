// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

permissionset 9175 "User Settings - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "User Settings" = X,
                  page "Accessible Companies" = X,
                  page "User Personalization" = X,
                  page "User Settings FactBox" = X,
                  page "User Settings List" = X,
                  page "User Settings" = X,
                  page Roles = X;
}
