// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

permissionset 9632 "Data Analysis - Edit"
{
    Access = Public;
    Assignable = true;
    Caption = 'Allow Adding Related Fields in Data Analysis Mode';

    Permissions = system "Add Fields in Analysis Mode" = X;
}
