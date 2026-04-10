// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

permissionset 1752 "Data Classification - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Data Classification Mgt." = X,
                  page "Data Classification Wizard" = X,
                  page "Data Classification Worksheet" = X,
                  page "Field Data Classification" = X;
}
