// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.EServices.EDocument;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Projects.Project.Archive;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.Archive;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using System.Automation;
using System.DataAdministration;
using System.Diagnostics;
using System.Environment.Configuration;
using System.IO;
using System.Threading;
using System.Utilities;

codeunit 3995 "Base Application Logs Delete"
{
    Access = Internal;
    Permissions =
                tabledata "Activity Log" = rd,
                tabledata "Change Log Entry" = rd,
                tabledata "Data Exch." = rd,
                tabledata "Dataverse Entity Change" = rd,
                tabledata "Error Message" = rd,
                tabledata "Error Message Register" = rd,
                tabledata "Integration Synch. Job" = rd,
                tabledata "Integration Synch. Job Errors" = rd,
                tabledata "Job Queue Log Entry" = rd,
                tabledata "Posted Invt. Pick Header" = rd,
                tabledata "Posted Invt. Put-away Header" = rd,
                tabledata "Posted Whse. Receipt Header" = rd,
                tabledata "Posted Whse. Shipment Header" = rd,
                tabledata "Purchase Header Archive" = rd,
                tabledata "Registered Whse. Activity Hdr." = rd,
                tabledata "Registered Invt. Movement Hdr." = rd,
                tabledata "Report Inbox" = rd,
                tabledata "Sales Header Archive" = rd,
                tabledata "Workflow Step Instance Archive" = rd,
                tabledata "Job Archive" = rd,
                tabledata "Sent Notification Entry" = rd;

    var
        NoFiltersErr: Label 'No filters were set on table %1, %2. Please contact your Microsoft Partner for assistance.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyIndirectPermissionRequired', '', true, true)]
    local procedure DeleteRecordsWithIndirectPermissionsOnApplyRetentionPolicyIndirectPermissionRequired(var RecRef: RecordRef; var Handled: Boolean)
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        // if someone else took it, exit
        if Handled then
            exit;

        // check if we can handle the table
        if not (RecRef.Number in [Database::"Change Log Entry",
            Database::"Job Queue Log Entry",
            Database::"Workflow Step Instance Archive",
            Database::"Integration Synch. Job",
            Database::"Integration Synch. Job Errors",
            Database::"Report Inbox",
            Database::"Sales Header Archive",
            Database::"Job Archive",
            Database::"Purchase Header Archive",
            Database::"Dataverse Entity Change",
            Database::"Sent Notification Entry",
            Database::"Posted Invt. Pick Header",
            Database::"Posted Invt. Put-away Header",
            Database::"Posted Whse. Receipt Header",
            Database::"Posted Whse. Shipment Header",
            Database::"Registered Whse. Activity Hdr.",
            Database::"Registered Invt. Movement Hdr.",
            Database::"Data Exch.",
            Database::"Activity Log",
            Database::"Error Message",
            Database::"Error Message Register"])
        then
            exit;

        // if no filters have been set, something is wrong.
        if (RecRef.GetFilters() = '') or (not RecRef.MarkedOnly()) then
            RetentionPolicyLog.LogError(LogCategory(), StrSubstNo(NoFiltersErr, RecRef.Number, RecRef.Name));

        // delete all remaining records
        RecRef.DeleteAll(true);

        // set handled
        Handled := true;
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;
}