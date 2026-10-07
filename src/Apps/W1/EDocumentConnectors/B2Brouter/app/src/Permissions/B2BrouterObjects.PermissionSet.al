// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.B2Brouter;

permissionset 6492 "B2Brouter Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = table "B2Brouter Setup" = X,
                  page "B2Brouter Setup" = X,
                  codeunit "B2Brouter Integration" = X,
                  codeunit "B2Brouter Api Management" = X;
}
