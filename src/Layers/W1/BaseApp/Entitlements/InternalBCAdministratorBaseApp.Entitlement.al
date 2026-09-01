// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Internal BC Administrator BaseApp"
{
    Type = Role;
    RoleType = Local;
    Id = '963797fb-eb3b-4cde-8ce3-5878b3f32a3f';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
