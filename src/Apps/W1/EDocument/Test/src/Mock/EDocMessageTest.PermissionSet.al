// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using System.TestLibraries.Utilities;

permissionset 139898 "E-Doc. Message Test"
{
    Assignable = false;

    Permissions =
        codeunit Assert = X,
        codeunit "E-Doc. Impl. State" = X,
        codeunit "E-Doc. Integration Mock V2" = X;
}
