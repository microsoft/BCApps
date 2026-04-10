// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Basic Financials BaseApp"
{
    Type = PerUserServicePlan;
    Id = '2ec8b6ca-ab13-4753-a479-8c2ffe4c323b';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BASIC ISV",
                         "D365 DIM CORRECTION",
                         "D365 DIM CHANGE GLO",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
