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
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Workflow;

/// <summary>
/// Used for full read-only access to Quality Management.
/// </summary>
permissionset 20401 "QltyMngmnt - Read"
{
    Caption = 'Quality Management - Read access';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Objects";

    Permissions =
        tabledata "Qlty. Management Setup" = R,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMD,
        tabledata "Qlty. Workflow Config. Value" = R,
        tabledata "Qlty. Inspection Gen. Rule" = R,
        tabledata "Qlty. I. Result Condit. Conf." = R,
        tabledata "Qlty. Inspect. Source Config." = R,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = R,
        tabledata "Qlty. Test Lookup Value" = R,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Inspection Template Hdr." = R,
        tabledata "Qlty. Inspection Template Line" = R,
        tabledata "Qlty. Test" = R,
        tabledata "Qlty. Inspection Result" = R,
        tabledata "Qlty. Inspection Header" = R,
        tabledata "Qlty. Inspection Line" = R;
}
