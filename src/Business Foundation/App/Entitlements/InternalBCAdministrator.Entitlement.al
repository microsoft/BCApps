// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using Microsoft.Foundation;

entitlement "Internal BC Administrator"
{
    Type = Role;
    RoleType = Local;
    Id = '963797fb-eb3b-4cde-8ce3-5878b3f32a3f';

    ObjectEntitlements = "Bus. Found. - Admin";
}
