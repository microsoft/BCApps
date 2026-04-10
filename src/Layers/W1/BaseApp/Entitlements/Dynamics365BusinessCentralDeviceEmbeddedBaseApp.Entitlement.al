// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Device - Embedded BaseApp"
{
    Type = ConcurrentUserServicePlan;
    GroupName = 'Dynamics 365 Business Central Device Users';
    Id = 'a98d0c4a-a52f-4771-a609-e20366102d2a';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS FULL ACCESS",
                         "D365 BUS PREMIUM",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
