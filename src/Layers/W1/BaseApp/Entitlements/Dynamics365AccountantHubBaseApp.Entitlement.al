// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Dynamics 365 - Accountant Hub BaseApp"
{
    Type = PerUserServicePlan;
    Id = '5d60ea51-0053-458f-80a8-b6f426a1a0c1';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 ACCOUNTANTS",
                         "D365 BASIC",
                         "D365 DIM CORRECTION",
                         "D365 JOBS, EDIT",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Security - Baseapp";
}
