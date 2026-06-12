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
using Microsoft.QualityManagement.Setup;

/// <summary>
/// Grants the minimum permissions required to initiate quality inspections from
/// automatic procedures triggered by other operations (for example, production order
/// completion, purchase receipts, warehouse activities, and similar background
/// scenarios). Setup and configuration data is exposed as read-only, while inspection
/// records can be created and updated, so that Quality Management data is only
/// modified through Quality Management code paths and not by direct user interaction.
/// </summary>
permissionset 20407 "QltyMgmt - Initiate"
{
    Caption = 'Quality Inspection - Initiate';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMgmt - Objects";

    Permissions =
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Result" = r,
        tabledata "Qlty. Test" = r,
        tabledata "Qlty. Test Lookup Value" = r,
        tabledata "Qlty. Inspection Template Hdr." = r,
        tabledata "Qlty. Inspection Template Line" = r,
        tabledata "Qlty. Inspect. Source Config." = r,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = r,
        tabledata "Qlty. Inspection Header" = rim,
        tabledata "Qlty. Inspection Line" = rim,
        tabledata "Qlty. I. Result Condit. Conf." = rim;
}
