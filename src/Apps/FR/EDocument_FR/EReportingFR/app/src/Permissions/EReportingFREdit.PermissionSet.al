// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

permissionset 10972 "E-Reporting FR - Edit"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "E-Reporting FR - Read";

    Permissions = tabledata "FR E-Invoice Lifecycle" = IM;
}