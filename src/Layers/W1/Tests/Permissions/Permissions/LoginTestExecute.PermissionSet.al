// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

permissionset 132913 "Login Test - Execute"
{
    Assignable = true;
    Permissions = codeunit Assert = X,
                  codeunit "Login Permissions Tests" = X;
}
