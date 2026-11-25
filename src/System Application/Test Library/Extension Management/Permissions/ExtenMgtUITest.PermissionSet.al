// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

using System.Environment.Configuration;

permissionset 135108 "Exten. Mgt. UI Test"
{
    Access = Internal;
    Assignable = true;

    Permissions = tabledata "User Personalization" = R;
}
