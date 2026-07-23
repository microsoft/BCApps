#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Foundation.Navigate;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 13468 "Dep Diff FI Feature Data Update" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = tabledata "Feature Data Update Status" = rm;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature Depreciation Differences FI will be enabled by default in version 32.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        DescriptionTxt: Label 'Existing records in FI BaseApp fields will be copied to Depreciation Differences FI app fields.';

    procedure IsDataUpdateRequired(): Boolean
    begin
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;
        exit(true);
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");
        SetUpgradeTag(true);
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        StartDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Depreciation Differences FI', StartDateTime);
        TransferFields(Database::"FA Posting Group", 13462, 13400);
        TransferFields(Database::"FA Posting Group", 13463, 13401);
        TransferFields(Database::"FA Ledger Entry", 13464, 13400);
        TransferFields(Database::"Source Code Setup", 13465, 13400);
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Depreciation Differences FI', EndDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords()
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();
        InsertDocumentEntry(Database::"FA Posting Group", 'FA Posting Group', CountWithNonDefaultField(Database::"FA Posting Group", 13400, false) + CountWithNonDefaultField(Database::"FA Posting Group", 13401, false));
        InsertDocumentEntry(Database::"FA Ledger Entry", 'FA Ledger Entry', CountWithNonDefaultField(Database::"FA Ledger Entry", 13400, true));
        InsertDocumentEntry(Database::"Source Code Setup", 'Source Code Setup', CountWithNonDefaultField(Database::"Source Code Setup", 13400, false));
    end;

    local procedure CountWithNonDefaultField(TableId: Integer; SourceFieldNo: Integer; BooleanField: Boolean): Integer
    var
        RecRef: RecordRef;
        SourceFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        if BooleanField then
            SourceFieldRef.SetFilter('%1', true)
        else
            SourceFieldRef.SetFilter('<>%1', '');
        exit(RecRef.Count());
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;
        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure TransferFields(TableId: Integer; TargetFieldNo: Integer; SourceFieldNo: Integer)
    var
        RecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        if RecRef.FindSet() then
            repeat
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                TargetFieldRef.Value := SourceFieldRef.Value;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        DepreciationDifferencesFIUpgradeTag: Codeunit "Dep Diff FI Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(DepreciationDifferencesFIUpgradeTag.GetUpgradeTag()) then
            exit;
        UpgradeTag.SetUpgradeTag(DepreciationDifferencesFIUpgradeTag.GetUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(DepreciationDifferencesFIUpgradeTag.GetUpgradeTag(), true);
    end;
}
#endif
