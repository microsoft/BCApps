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

/// <summary>
/// Used for supervising quality inspections.
/// </summary>
permissionset 20403 QltyGeneral
{
    Caption = 'Quality Inspection - Supervisor';
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Objects";

    Permissions =
        // Table data
        tabledata "Qlty. Express Config. Value" = RIMD,
        tabledata "Qlty. Inspection Gen. Rule" = RIMD,
        tabledata "Qlty. I. Result Condit. Conf." = RIMD,
        tabledata "Qlty. Inspection Result" = RIMD,
        tabledata "Qlty. Inspection Template Hdr." = RIMD,
        tabledata "Qlty. Inspection Template Line" = RIMD,
        tabledata "Qlty. Lookup Code" = RIMD,
        tabledata "Qlty. Management Setup" = RIMD,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = RIMD,
        tabledata "Qlty. Inspect. Source Config." = RIMD,
        tabledata "Qlty. Inspection Line" = RIMD,
        tabledata "Qlty. Inspection Header" = RIMD,
        tabledata "Qlty. Test" = RIMD;
}

