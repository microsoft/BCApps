// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Permissions;

using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.API;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Installation;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Integration.Foundation.Attachment;
using Microsoft.QualityManagement.Integration.Foundation.Navigate;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Utilities;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Setup.SetupGuide;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Workflow;

/// <summary>
/// Used for data entry only.
/// </summary>
permissionset 20404 QltyEntryInspector
{
    Caption = 'Quality Inspection - Data Entry';
    Assignable = true;
    IncludedPermissionSets = "QltyMngmnt - Objects";
    Permissions =
        // codeunits
        codeunit "Qlty. - Warehouse Integration" = X,
        codeunit "Qlty. Application Area Mgmt." = X,
        codeunit "Qlty. Auto Configure" = X,
        codeunit "Qlty. Inspection - Create" = X,
        codeunit "Qlty. Disp. Change Tracking" = X,
        codeunit "Qlty. Disp. Internal Put-away" = X,
        codeunit "Qlty. Disp. Move Auto Choose" = X,
        codeunit "Qlty. Disp. Neg. Adjust Inv." = X,
        codeunit "Qlty. Disp. Purchase Return" = X,
        codeunit "Qlty. Disp. Transfer" = X,
        codeunit "Qlty. Expression Mgmt." = X,
        codeunit "Qlty. Filter Helpers" = X,
        codeunit "Qlty. Inspec. Gen. Rule Mgmt." = X,
        codeunit "Qlty. Result Condition Mgmt." = X,
        codeunit "Qlty. Result Evaluation" = X,
        codeunit "Qlty. Install" = X,
        codeunit "Qlty. Inventory Availability" = X,
        codeunit "Qlty. Item Tracking Mgmt." = X,
        codeunit "Qlty. Job Queue Management" = X,
        codeunit "Qlty. Item Journal Management" = X,
        codeunit "Qlty. Transfer Integration" = X,
        codeunit "Qlty. Attachment Integration" = X,
        codeunit "Qlty. Utilities Integration" = X,
        codeunit "Qlty. Navigate Integration" = X,
        codeunit "Qlty. Tracking Integration" = X,
        codeunit "Qlty. Misc Helpers" = X,
        codeunit "Qlty. Notification Mgmt." = X,
        codeunit "Qlty. Permission Mgmt." = X,
        codeunit "Qlty. Manufactur. Integration" = X,
        codeunit "Qlty. Assembly Integration" = X,
        codeunit "Qlty. Receiving Integration" = X,
        codeunit "Qlty. Report Mgmt." = X,
        codeunit "Qlty. Session Helper" = X,
        codeunit "Qlty. Start Workflow" = X,
        codeunit "Qlty. Item Tracking" = X,
        codeunit "Qlty. Traversal" = X,
        codeunit "Qlty. Workflow Setup" = X,
        // pages
        page "Qlty. Lookup Field Choose" = X,
        page "Qlty. Edit Large Text" = X,
        page "Qlty. Choose Existing Tests" = X,
        page "Qlty. Manager RC" = X,
        page "Qlty. Test Card Part" = X,
        page "Qlty. Test Card" = X,
        page "Qlty. Test Lookup" = X,
        page "Qlty. Test Number Card Part" = X,
        page "Qlty. Test Wizard" = X,
        page "Qlty. Tests" = X,
        page "Qlty. Inspection Gen. Rules" = X,
        page "Qlty. Inspection Result List" = X,
        page "Qlty. Inspection Template" = X,
        page "Qlty. Inspection Template Edit" = X,
        page "Qlty. Inspection Template List" = X,
        page "Qlty. Inspection Template Subf" = X,
        page "Qlty. Lookup Code List" = X,
        page "Qlty. Lookup Code Part" = X,
        page "Qlty. Manager Role Center" = X,
        page "Qlty. Management Setup Guide" = X,
        page "Qlty. Management Setup" = X,
        page "Qlty. Most Recent Picture" = X,
        page "Qlty. Prod. Gen. Rule Wizard" = X,
        page "Qlty. Asm. Gen. Rule Wizard" = X,
        page "Qlty. Rec. Gen. Rule Wizard" = X,
        page "Qlty. Related Transfer Orders" = X,
        page "Qlty. Report Selection - QM" = X,
        page "Qlty. Routing Line Lookup" = X,
        page "Qlty. Inspect. Source Config." = X,
        page "Qlty. Source Config Line Part" = X,
        page "Qlty. Ins. Source Config. List" = X,
        page "Qlty. Inspection Subform" = X,
        page "Qlty. Inspection Lines" = X,
        page "Qlty. Inspection Activities" = X,
        page "Qlty. Inspection List" = X,
        page "Qlty. Whse. Gen. Rule Wizard" = X,
        page "Qlty. Inspection" = X,
        // queries
        query "Qlty. Inspection Values" = X,
        query "Qlty. Item Ledger By Location" = X,
        // reports
        report "Qlty. Certificate of Analysis" = X,
        report "Qlty. Change Item Tracking" = X,
        report "Qlty. Create Internal Put-away" = X,
        report "Qlty. Create Negative Adjmt." = X,
        report "Qlty. Create Purchase Return" = X,
        report "Qlty. Create Inspection" = X,
        report "Qlty. Create Transfer Order" = X,
        report "Qlty. General Purpose Inspect." = X,
        report "Qlty. Move Inventory" = X,
        report "Qlty. Non-Conformance" = X,
        // tables
        table "Qlty. Express Config. Value" = X,
        table "Qlty. Test" = X,
        table "Qlty. Inspection Gen. Rule" = X,
        table "Qlty. I. Result Condit. Conf." = X,
        table "Qlty. Inspection Result" = X,
        table "Qlty. Inspection Template Hdr." = X,
        table "Qlty. Inspection Template Line" = X,
        table "Qlty. Lookup Code" = X,
        table "Qlty. Management Setup" = X,
        table "Qlty. Related Transfers Buffer" = X,
        table "Qlty. Mgmt. Role Center Cue" = X,
        table "Qlty. Inspect. Src. Fld. Conf." = X,
        table "Qlty. Inspect. Source Config." = X,
        table "Qlty. Inspection Line" = X,
        table "Qlty. Inspection Header" = X,
        // table data
        tabledata "Qlty. Express Config. Value" = RIMD,
        tabledata "Qlty. Test" = RIMd,
        tabledata "Qlty. Inspection Gen. Rule" = RIMd,
        tabledata "Qlty. I. Result Condit. Conf." = RIMd,
        tabledata "Qlty. Inspection Result" = RIMd,
        tabledata "Qlty. Inspection Template Hdr." = RIMd,
        tabledata "Qlty. Inspection Template Line" = RIMd,
        tabledata "Qlty. Lookup Code" = RIMd,
        tabledata "Qlty. Management Setup" = RIMd,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMd,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = RIMd,
        tabledata "Qlty. Inspect. Source Config." = RIMd,
        tabledata "Qlty. Inspection Line" = RIMd,
        tabledata "Qlty. Inspection Header" = RIMd;
}

