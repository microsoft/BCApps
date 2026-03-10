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
/// Used for administering Quality Management and supervising Quality Inspections.
/// </summary>
permissionset 20405 "QltyMngmnt - Edit"
{
    Caption = 'Quality Management - Full edit access';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Objects";

    Permissions =
        tabledata "Qlty. Management Setup" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMD,
        tabledata "Qlty. Workflow Config. Value" = RIMD,
        tabledata "Qlty. Inspection Gen. Rule" = RIMD,
        tabledata "Qlty. I. Result Condit. Conf." = RIMD,
        tabledata "Qlty. Inspect. Source Config." = RIMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = RIMD,
        tabledata "Qlty. Test Lookup Value" = RIMD,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Inspection Template Hdr." = RIMD,
        tabledata "Qlty. Inspection Template Line" = RIMD,
        tabledata "Qlty. Test" = RIMD,
        tabledata "Qlty. Inspection Result" = RIMD,
        tabledata "Qlty. Inspection Header" = RIMD,
        tabledata "Qlty. Inspection Line" = RIMD;
}
