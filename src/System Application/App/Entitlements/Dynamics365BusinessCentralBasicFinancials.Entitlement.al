// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Azure.Identity;

entitlement "Dynamics 365 Business Central Basic Financials"
{
    Type = PerUserServicePlan;
    Id = '2ec8b6ca-ab13-4753-a479-8c2ffe4c323b';

#pragma warning disable AL0684
    ObjectEntitlements = "Application Objects - Exec",
                         "Azure AD Plan - Admin",
                         "Security Groups - Admin",
                         "System Application - Admin";
#pragma warning restore
}
