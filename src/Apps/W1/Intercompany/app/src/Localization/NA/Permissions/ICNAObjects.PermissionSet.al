#if INTERCOMPANY_NA
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

permissionset 8559 "IC NA - Objects"
{
    Access = Internal;
    Assignable = false;
    Permissions = codeunit "IC Payment Journal Test NA" = X,
                  codeunit "IC Register NA" = X;
}
#endif
