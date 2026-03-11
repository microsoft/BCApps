// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

permissionset 230 "Audit Codes - Objects"
{
    Assignable = false;
    Access = Internal;

    Permissions = table "Reason Code" = X,
                table "Return Reason" = X,
                table "Source Code" = X,
                table "Source Code Setup" = X,
                page "Reason Codes" = X,
                page "Source Codes" = X,
                page "Source Code Setup" = X,
                page "Return Reasons" = X;
}