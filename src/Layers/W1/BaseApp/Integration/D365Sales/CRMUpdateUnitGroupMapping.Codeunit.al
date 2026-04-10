// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using System.Threading;

codeunit 5367 "CRM Update Unit Group Mapping"
{
    TableNo = "Job Queue Entry";
    Permissions = TableData Item = r,
                  TableData Resource = r,
                  TableData "Unit Group" = rimd;

    trigger OnRun()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Session.LogMessage('0000HZ8', StartingToUpdateUnitGroupMappingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        CRMIntegrationManagement.UpdateItemUnitGroup();
        CRMIntegrationManagement.UpdateResourceUnitGroup();
        Session.LogMessage('0000HZ9', FinishedUpdatingUnitGroupMappingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    var
        TelemetryCategoryTok: Label 'AL CRM Integration';
        StartingToUpdateUnitGroupMappingLbl: Label 'Starting to update unit group mapping.', Locked = true;
        FinishedUpdatingUnitGroupMappingLbl: Label 'Finished updating unit group mapping.', Locked = true;
}
