// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using Microsoft.Foundation;

entitlement "Delegated BC Admin agent - Partner"
{
    Type = Role;
    RoleType = Delegated;
    Id = '00000000-0000-0000-0000-000000000010';

    ObjectEntitlements = "Bus. Found. - Admin";
}
