#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Navigate;
using System.Environment.Configuration;

codeunit 1080 "Feature - Fin. Report Default" implements "Feature Data Update"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Financial Report defaults feature will be always enabled in version 29.0';
    ObsoleteTag = '28.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        DescriptionTxt: Label 'If you enable Financial Report defaults, existing Negative Amount Format and Period Type fields will be migrated to the new fields with the newly added default option.';
        FinancialReportDefaultsTok: Label 'FinancialReportDefaults', Locked = true, MaxLength = 50;

    procedure IsDefaultsFeatureEnabled(): Boolean
    var
        FeatureMgtFacade: Codeunit "Feature Management Facade";
    begin
        exit(FeatureMgtFacade.IsEnabled(GetFinancialReportDefaultsFeatureKey()));
    end;

    procedure GetFinancialReportDefaultsFeatureKey(): Text[50]
    begin
        exit(FinancialReportDefaultsTok);
    end;

    procedure IsDataUpdateRequired(): Boolean
    var
        FinReportDefaultUpgrade: Codeunit "Fin. Report Default Upgrade";
    begin
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            FinReportDefaultUpgrade.SetUpgradeTag(false);
            exit(false);
        end else
            exit(true);
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FinancialReport: Record "Financial Report";
        FinReportDefaultUpgrade: Codeunit "Fin. Report Default Upgrade";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        FinReportDefaultUpgrade.UpdateData();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, FinancialReport.TableCaption(), StartDateTime);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    local procedure CountRecords()
    var
        FinancialReport: Record "Financial Report";
        FinancialReportUserFilters: Record "Financial Report User Filters";
    begin
        InsertDocumentEntry(Database::"Financial Report", FinancialReport.TableCaption(), FinancialReport.Count());
        InsertDocumentEntry(Database::"Financial Report User Filters", FinancialReportUserFilters.TableCaption(), FinancialReportUserFilters.Count());
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
}
#endif