// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

permissionset 774 "Azure AD Plan - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = page "Custom Permission Set In Plan" = X,
#if not CLEAN22
#pragma warning disable AL0432
#endif
                  page "Default Permission Set In Plan" = X,
#if not CLEAN22
#pragma warning restore AL0432
#endif
                  page "Plan Configuration Card" = X,
                  page "Plan Configuration List" = X,
                  page "Plan Configurations Part" = X,
                  page "User Plan Members FactBox" = X,
                  page "User Plan Members" = X,
                  page "User Plans FactBox" = X;
}
