// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Workflow;

/// <summary>
/// Used for working with Quality Inspections.
/// </summary>
permissionset 20404 "QltyMgmt - Inspector"
{
    Caption = 'Quality Inspector';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMgmt - Objects";

    Permissions =
        tabledata "Qlty. Workflow Config. Value" = Rim,
        tabledata "Qlty. Inspection Gen. Rule" = R,
        tabledata "Qlty. I. Result Condit. Conf." = RIMd,
        tabledata "Qlty. Inspection Result" = R,
        tabledata "Qlty. Inspection Template Hdr." = R,
        tabledata "Qlty. Inspection Template Line" = R,
        tabledata "Qlty. Test Lookup Value" = R,
        tabledata "Qlty. Management Setup" = R,
        tabledata "Qlty. Mgmt. Role Center Cue" = Ri,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = R,
        tabledata "Qlty. Inspect. Source Config." = R,
        tabledata "Qlty. Inspection Line" = RIMd,
        tabledata "Qlty. Inspection Header" = RIMd,
        tabledata "Qlty. Test" = R;
}
