#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 13466 "Feature Depr. Difference FI" implements "Feature Data Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Feature Data Update Status" = rm,
                  tabledata "FA Posting Group" = rimd,
                  tabledata "FA Ledger Entry" = rimd,
                  tabledata "Source Code Setup" = rimd;
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature Posting Depreciation Differences will be enabled by default in version 32.0.';
    ObsoleteTag = '29.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        DescriptionTxt: Label 'Existing records in FI BaseApp fields will be copied to Depreciation Differences FI app fields';

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
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Posting Depreciation Differences FI', StartDateTime);
        UpgradeDeprDifferenceFields();
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Posting Depreciation Differences FI', EndDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords()
    var
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::"FA Posting Group", FAPostingGroup.TableCaption(), FAPostingGroup.Count());
        InsertDocumentEntry(Database::"FA Ledger Entry", FALedgerEntry.TableCaption(), FALedgerEntry.Count());
        InsertDocumentEntry(Database::"Source Code Setup", SourceCodeSetup.TableCaption(), SourceCodeSetup.Count());
    end;

    local procedure InsertDocumentEntry(TableId: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableId;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure UpgradeDeprDifferenceFields()
    begin
        TransferFields(Database::"FA Posting Group", 13400, 13478);
        TransferFields(Database::"FA Posting Group", 13401, 13479);
        TransferFields(Database::"FA Ledger Entry", 13400, 13480);
        TransferFields(Database::"Source Code Setup", 13400, 13481);
    end;

    local procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        if RecRef.FindSet(true) then
            repeat
                SourceFieldRef := RecRef.Field(SourceFieldNo);
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                TargetFieldRef.Value := SourceFieldRef.Value;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagDeprDiffFI: Codeunit "Upg. Tag Depr. Diff. FI";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagDeprDiffFI.GetDeprDifferenceFIUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgTagDeprDiffFI.GetDeprDifferenceFIUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgTagDeprDiffFI.GetDeprDifferenceFIUpgradeTag(), true);
    end;
}
#endif
