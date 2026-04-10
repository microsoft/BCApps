// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

permissionset 134689 "Email View Perm"
{
    Assignable = true;
    IncludedPermissionSets = "Email - Admin";

    // Direct permissions needed for tests
    Permissions =
        tabledata "Email Outbox" = RIMD,
        tabledata "Email Recipient" = RIMD,
        tabledata "Sent Email" = RIMD,
        tabledata "Test Email Account" = RIMD,
        tabledata "Test Email Connector Setup" = RIMD;

}