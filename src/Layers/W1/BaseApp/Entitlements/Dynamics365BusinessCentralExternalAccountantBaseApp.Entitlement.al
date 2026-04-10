// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central External Accountant BaseApp"
{
    Type = PerUserServicePlan;
    Id = '170991d7-b98e-41c5-83d4-db2052e1795f';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS PREMIUM",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
