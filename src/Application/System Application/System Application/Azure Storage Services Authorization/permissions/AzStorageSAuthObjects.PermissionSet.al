// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage;

using System.Security.Encryption;

permissionset 9065 "Az. Storage S. Auth. - Objects"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Cryptography Mgt. - Objects";

    Permissions = Codeunit "Storage Service Authorization" = X;
}
