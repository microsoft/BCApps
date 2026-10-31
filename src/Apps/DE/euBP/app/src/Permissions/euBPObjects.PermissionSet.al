// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

permissionset 6549 "euBP - Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = table "euBP Setup" = X,
                  page "euBP Setup" = X,
                  codeunit "euBP Data Handling" = X,
                  codeunit "euBP Data Check" = X,
                  codeunit "euBP XML Mgt." = X,
                  codeunit "euBP - Initialize" = X;
}
