// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

permissionset 8432 "Perf. Center Tables - View"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Performance Analysis" = R,
                  tabledata "Performance Analysis Line" = R;
}
