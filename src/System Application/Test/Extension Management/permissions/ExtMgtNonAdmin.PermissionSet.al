// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Security.AccessControl;

permissionset 133100 "Ext. Mgt. Nonadmin"
{
    Assignable = true;

    Permissions = tabledata "Access Control" = R;
}