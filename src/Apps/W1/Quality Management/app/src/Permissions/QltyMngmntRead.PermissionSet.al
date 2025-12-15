// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup.Setup;

permissionset 20401 "QltyMngmnt - Read"
{
    Caption = 'Quality Management - Read';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Objects";

    Permissions =
        tabledata "Qlty. Inspection Gen. Rule" = R,
        tabledata "Qlty. I. Grade Condition Conf." = R,
        tabledata "Qlty. Inspection Grade" = R,
        tabledata "Qlty. Lookup Code" = R,
        tabledata "Qlty. Management Setup" = R,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = R,
        tabledata "Qlty. Inspect. Source Config." = R,
        tabledata "Qlty. Inspection Template Line" = R,
        tabledata "Qlty. Inspection Template Hdr." = R,
        tabledata "Qlty. Inspection Line" = R,
        tabledata "Qlty. Inspection Header" = R,
        tabledata "Qlty. Field" = R;
}
