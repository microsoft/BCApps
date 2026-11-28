// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#if not CLEAN30
using Microsoft.Foundation.Navigate;
using Microsoft.Upgrade;
using System.Environment.Configuration;
using System.Upgrade;
#endif

codeunit 12106 "Business Activity Feature IT"
#if not CLEAN30
    implements "Feature Data Update"
#endif
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure IsEnabled(): Boolean
    begin
#if not CLEAN30
        exit(FeatureManagementFacade.IsEnabled(GetFeatureKey(), false));
#else
        exit(true);
#endif
    end;

#if not CLEAN30
    procedure GetFeatureKey(): Text[50]
    begin
        exit(BusinessActivityCodeITTok);
    end;

    procedure IsDataUpdateRequired(): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        exit(not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBusinessActivityCodeUpgradeTag()));
    end;

    procedure ReviewData()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        UpgradeBaseApp.GetBusinessActivityUpgradeOverview(TempDocumentEntry);
        Commit();
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        UpgradeBaseApp.UpgradeBusinessActivityCodes();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, GetTaskDescription(), StartDateTime);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DataUpdateDescriptionTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", OnAfterFeatureDisableConfirmed, '', false, false)]
    local procedure PreventDisablingAfterMigration(FeatureKey: Record "Feature Key")
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if FeatureKey.ID <> GetFeatureKey() then
            exit;
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetBusinessActivityCodeUpgradeTag()) then
            Error(CannotDisableErr);
    end;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        BusinessActivityCodeITTok: Label 'BusinessActivityCodeIT', Locked = true, MaxLength = 50;
        DataUpdateDescriptionTxt: Label 'Copy Italian activity codes, setup, documents, and posted entries to the Business Activity Code fields. After the update, the company will use Business Activity Code and cannot return to the legacy activity codes.';
        CannotDisableErr: Label 'You cannot disable Business Activity Code after the Italian activity code data has been migrated.';
#endif
}
