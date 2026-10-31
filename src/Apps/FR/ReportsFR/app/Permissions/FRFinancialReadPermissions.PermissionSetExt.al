// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Security.AccessControl;

permissionsetextension 10826 "FR Financial Read Permissions" extends "LOCAL READ"
{
    IncludedPermissionSets = "Reports FR Fin. Read";
}
