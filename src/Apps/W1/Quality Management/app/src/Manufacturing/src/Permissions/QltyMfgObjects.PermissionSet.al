// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.QualityManagement.Utilities;

permissionset 20470 "Qlty. Mfg. - Objects"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Quality Management Manufacturing - Objects';

    Permissions =
        codeunit "Qlty. Manufactur. Integration" = X,
        codeunit "Qlty. Filter Helpers - Mfg." = X,
        codeunit "Qlty. Session Helper - Mfg." = X,
        codeunit "Qlty. Traversal - Mfg." = X,
        page "Qlty. Prod. Gen. Rule Wizard" = X,
        page "Qlty. Routing Line Lookup" = X;
}
