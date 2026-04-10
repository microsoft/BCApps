// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.RoleCenters;

using System.Environment.Configuration;

profile "EMPLOYEE"
{
    Caption = 'Employee';
    ProfileDescription = 'An employee within the organization that does not have a specific role in Business Central, and typically only views data that others have shared with them.';
    RoleCenter = "Blank Role Center";
    Enabled = false;
}
