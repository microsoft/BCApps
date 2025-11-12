// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

//using Microsoft.Manufacturing.Capacity;
//using Microsoft.Manufacturing.Document;
//using Microsoft.Manufacturing.Routing;
//using Microsoft.QualityManagement.Configuration.SourceConfiguration;
//using Microsoft.QualityManagement.Integration.Manufacturing.Document;
//using Microsoft.QualityManagement.Integration.Manufacturing.Journal;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
//using Microsoft.QualityManagement.RoleCenters;

permissionset 20470 "Qlty. Mfg. - Objects"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Quality Management Manufacturing - Objects';

    Permissions =
        codeunit "Qlty. Manufactur. Integration" = X,
        //codeunit "Qlty. Mfg. Filter Helpers" = X,
        //codeunit "Qlty. Mfg. Session Helper" = X,
        //codeunit "Qlty. Mfg. Traversal" = X,
        page "Qlty. Prod. Gen. Rule Wizard" = X,
        page "Qlty. Routing Line Lookup" = X;
}
