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

permissionset 20405 "QltyMngmnt - Edit"
{
    Caption = 'Quality Management - Edit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "QltyMngmnt - Read";

    Permissions =
        tabledata "Qlty. In. Test Generation Rule" = IMD,
        tabledata "Qlty. I. Grade Condition Conf." = IMD,
        tabledata "Qlty. Inspection Grade" = IMD,
        tabledata "Qlty. Lookup Code" = IMD,
        tabledata "Qlty. Management Setup" = IMD,
        tabledata "Qlty. Related Transfers Buffer" = IMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = IMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = IMD,
        tabledata "Qlty. Inspect. Source Config." = IMD,
        tabledata "Qlty. Inspection Template Line" = IMD,
        tabledata "Qlty. Inspection Template Hdr." = IMD,
        tabledata "Qlty. Inspection Test Line" = IMD,
        tabledata "Qlty. Inspection Test Header" = IMD,
        tabledata "Qlty. Field" = IMD;
}
