#if INTERCOMPANY_IT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

permissionset 8561 "IC IT - Objects"
{
    Access = Internal;
    Assignable = false;
    Permissions = codeunit "IC Sales-Post IT" = X;
}
#endif
