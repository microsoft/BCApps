// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

permissionset 6014 "API Codeunits - Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'API Codeunits - Read';

    Permissions =
        codeunit "Environment API" = X,
        codeunit "Time Zone API" = X;
}
