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
/// Used for working with Quality Inspections.
/// </summary>
permissionset 20404 QltyMngmntInspector
{
    Caption = 'Quality Management - Quality Inspector';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Objects";

    Permissions =
        tabledata "Qlty. Workflow Config. Value" = RIMD,
        tabledata "Qlty. Inspection Gen. Rule" = RIMd,
        tabledata "Qlty. I. Result Condit. Conf." = RIMd,
        tabledata "Qlty. Inspection Result" = RIMd,
        tabledata "Qlty. Inspection Template Hdr." = RIMd,
        tabledata "Qlty. Inspection Template Line" = RIMd,
        tabledata "Qlty. Test Lookup Value" = RIMd,
        tabledata "Qlty. Management Setup" = RIMd,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMd,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = RIMd,
        tabledata "Qlty. Inspect. Source Config." = RIMd,
        tabledata "Qlty. Inspection Line" = RIMd,
        tabledata "Qlty. Inspection Header" = RIMd,
        tabledata "Qlty. Test" = RIMd;
}

