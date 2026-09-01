// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Internal Administrator BaseApp"
{
    Type = Role;
    RoleType = Local;
    Id = '62e90394-69f5-4237-9190-012177145e10';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
