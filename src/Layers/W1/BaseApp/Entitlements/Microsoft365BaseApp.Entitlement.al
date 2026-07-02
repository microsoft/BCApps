// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "Microsoft 365 BaseApp"
{
    Type = PerUserServicePlan;
    Id = '57ff2da0-773e-42df-b2af-ffb7a2317929';
    ObjectEntitlements = "D365 READ",
                         "Security - Baseapp",
                         "Local Read";
}
