// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

entitlement "D365 Business Central Infrastructure BaseApp"
{
    Type = Application;
    Id = '996def3d-b36c-4153-8607-a6fd3c01b89f';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 DIM CORRECTION",
                         "D365 FULL ACCESS",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Security - Baseapp";
}
