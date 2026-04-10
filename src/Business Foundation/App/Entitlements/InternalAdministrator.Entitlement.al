// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using Microsoft.Foundation;

entitlement "Internal Administrator"
{
    Type = Role;
    RoleType = Local;
    Id = '62e90394-69f5-4237-9190-012177145e10';

    ObjectEntitlements = "Bus. Found. - Admin";
}
