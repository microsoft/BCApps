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
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Foundation.Attachment;
using Microsoft.QualityManagement.Integration.Foundation.Navigate;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Utilities;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Workflow;

/// <summary>
/// Used for supervising.
/// </summary>
permissionset 20403 QltyGeneral
{
    Caption = 'Quality Inspection - Supervisor';
    Assignable = true;
    Permissions =
        // codeunits
        codeunit "Qlty. - Warehouse Integration" = X,
        codeunit "Qlty. Application Area Mgmt." = X,
        codeunit "Qlty. Auto Configure" = X,
        codeunit "Qlty. Inspection Test - Create" = X,
        codeunit "Qlty. Disp. Change Tracking" = X,
        codeunit "Qlty. Disp. Internal Put-away" = X,
        codeunit "Qlty. Disp. Move Auto Choose" = X,
        codeunit "Qlty. Disp. Neg. Adjust Inv." = X,
        codeunit "Qlty. Disp. Purchase Return" = X,
        codeunit "Qlty. Disp. Transfer" = X,
        codeunit "Qlty. Expression Mgmt." = X,
        codeunit "Qlty. Filter Helpers" = X,
        codeunit "Qlty. Generation Rule Mgmt." = X,
        codeunit "Qlty. Grade Condition Mgmt." = X,
        codeunit "Qlty. Grade Evaluation" = X,
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
        page "Qlty. Choose Existing Fields" = X,
        page "Qlty. Manager RC" = X,
        page "Qlty. Field Card Part" = X,
        page "Qlty. Field Card" = X,
        page "Qlty. Field Expr. Card Part" = X,
        page "Qlty. Field Lookup" = X,
        page "Qlty. Field Number Card Part" = X,
        page "Qlty. Field Wizard" = X,
        page "Qlty. Fields" = X,
        page "Qlty. In. Test Generat. Rules" = X,
        page "Qlty. Inspection Grade List" = X,
        page "Qlty. Inspection Template" = X,
        page "Qlty. Inspection Template Edit" = X,
        page "Qlty. Inspection Template List" = X,
        page "Qlty. Inspection Template Subf" = X,
        page "Qlty. Lookup Code List" = X,
        page "Qlty. Lookup Code Part" = X,
        page "Qlty. Manager Role Center" = X,
        page "Qlty. Management Setup" = X,
        page "Qlty. Most Recent Picture" = X,
        page "Qlty. Rec. Gen. Rule Wizard" = X,
        page "Qlty. Related Transfer Orders" = X,
        page "Qlty. Report Selection" = X,
        page "Qlty. Inspection Test Subform" = X,
        page "Qlty. Inspection Test Lines" = X,
        page "Qlty. Inspection Activities" = X,
        page "Qlty. Inspection Test List" = X,
        page "Qlty. Whse. Gen. Rule Wizard" = X,
        page "Qlty. Inspection Test" = X,
        // queries
        query "Qlty. Inspection Test Values" = X,
        query "Qlty. Item Ledger By Location" = X,
        // reports
        report "Qlty. Certificate of Analysis" = X,
        report "Qlty. Change Item Tracking" = X,
        report "Qlty. Create Internal Put-away" = X,
        report "Qlty. Create Negative Adjmt." = X,
        report "Qlty. Create Purchase Return" = X,
        report "Qlty. Create Inspection Test" = X,
        report "Qlty. Create Transfer Order" = X,
        report "Qlty. General Purpose Inspect." = X,
        report "Qlty. Move Inventory" = X,
        report "Qlty. Non-Conformance" = X,
        // tables
        table "Qlty. Express Config. Value" = X,
        table "Qlty. Field" = X,
        table "Qlty. In. Test Generation Rule" = X,
        table "Qlty. I. Grade Condition Conf." = X,
        table "Qlty. Inspection Grade" = X,
        table "Qlty. Inspection Template Hdr." = X,
        table "Qlty. Inspection Template Line" = X,
        table "Qlty. Lookup Code" = X,
        table "Qlty. Management Setup" = X,
        table "Qlty. Related Transfers Buffer" = X,
        table "Qlty. Mgmt. Role Center Cue" = X,
        table "Qlty. Inspect. Src. Fld. Conf." = X,
        table "Qlty. Inspect. Source Config." = X,
        table "Qlty. Inspection Test Line" = X,
        table "Qlty. Inspection Test Header" = X,
        // table data
        tabledata "Qlty. Express Config. Value" = RIMD,
        tabledata "Qlty. In. Test Generation Rule" = RIMD,
        tabledata "Qlty. I. Grade Condition Conf." = RIMD,
        tabledata "Qlty. Inspection Grade" = RIMD,
        tabledata "Qlty. Inspection Template Hdr." = RIMD,
        tabledata "Qlty. Inspection Template Line" = RIMD,
        tabledata "Qlty. Lookup Code" = RIMD,
        tabledata "Qlty. Management Setup" = RIMD,
        tabledata "Qlty. Related Transfers Buffer" = RIMD,
        tabledata "Qlty. Mgmt. Role Center Cue" = RIMD,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = RIMD,
        tabledata "Qlty. Inspect. Source Config." = RIMD,
        tabledata "Qlty. Inspection Test Line" = RIMD,
        tabledata "Qlty. Inspection Test Header" = RIMD,
        tabledata "Qlty. Field" = RIMD;
}

