// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

using System.Environment.Configuration;

permissionset 7404 "REGISTRATION MIGRATE"
{
    Assignable = true;
    Caption = 'Review Registration No. Migration';
    IncludedPermissionSets = "Feature Mgt. - Admin";

    Permissions = tabledata "Registration No. Migration" = RIMD,
                  table "Registration No. Migration" = X,
                  page "Registration No. Migration" = X,
                  codeunit "Registration No. Feature" = X,
                  codeunit "Registration No. Mgt." = X;
}
