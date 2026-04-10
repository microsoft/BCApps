// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Dynamics 365 Administrator BaseApp"
{
    Type = Role;
    RoleType = Local;
    Id = '44367163-eba1-44c3-98af-f5787879f96a';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
