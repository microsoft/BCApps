// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Analysis;
using System.Threading;

codeunit 2584 "Dim Corr Analysis View"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        DimensionCorrection.Get(Rec."Record ID to Process");
        DimensionCorrection."Update Analysis View Job ID" := Rec.ID;
        DimensionCorrection.Modify();
        UpdateAnalysisViews(DimensionCorrection);
    end;

    procedure UpdateAnalysisViews(var DimensionCorrection: Record "Dimension Correction")
    begin
        Session.LogMessage('0000EK8', StrSubstNo(StartingUpdateAnalysisViewsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::"In Process";
        Clear(DimensionCorrection."Update Analysis Views Error");
        DimensionCorrection.Modify();
        Commit();

        UpdateSelectedAnalysisViews(DimensionCorrection);

        DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Completed;
        DimensionCorrection.Modify();
        Commit();

        Session.LogMessage('0000EK9', StrSubstNo(CompletedUpdateAnalysisViewsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure ShouldUpdateAnalysisView(var AnalysisView: Record "Analysis View"; var DimensionCorrection: Record "Dimension Correction") Result: Boolean
    var
        TempDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        if not DimensionCorrectionMgt.GetDimCorrectionChanges(DimensionCorrection."Entry No.", TempDimCorrectionChange) then
            exit(false);

        if not TempDimCorrectionChange.FindSet() then
            exit(false);

        repeat
            if AnalysisView.CheckDimensionIsTracked(TempDimCorrectionChange."Dimension Code") then
                exit(true);
        until TempDimCorrectionChange.Next() = 0;

        OnAfterShouldUpdateAnalysisView(AnalysisView, DimensionCorrection, Result);
    end;

    local procedure UpdateSelectedAnalysisViews(var DimensionCorrection: Record "Dimension Correction")
    var
        AnalysisView: Record "Analysis View";
        UpdatedAnalysisView: Record "Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        AnalysisView.SetRange(Blocked, false);
        AnalysisView.SetRange("Account Source", AnalysisView."Account Source"::"G/L Account");
        OnUpdateSelectedAnalysisViewsOnAfterSetFilter(AnalysisView);
        if AnalysisView.IsEmpty() then
            exit;

        AnalysisView.FindSet();
        repeat
            if ShouldUpdateAnalysisView(AnalysisView, DimensionCorrection) then begin
                AnalysisView."Reset Needed" := true;
                AnalysisView.Modify();
            end;
        until AnalysisView.Next() = 0;
        Commit();

        AnalysisView.SetRange("Reset Needed", true);
        if AnalysisView.IsEmpty() then
            exit;

        AnalysisView.FindSet();
        repeat
            if AnalysisView."Update on Posting" or (DimensionCorrection."Analysis View Update Type" = DimensionCorrection."Analysis View Update Type"::All) then begin
                UpdatedAnalysisView.Get(AnalysisView.RecordId);
                UpdatedAnalysisView.AnalysisViewReset();
                UpdateAnalysisView.Update(UpdatedAnalysisView, 2, false);
                Commit();
            end;
        until AnalysisView.Next() = 0;
    end;

    var
        StartingUpdateAnalysisViewsLbl: Label 'Starting Update Analysis Views, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        CompletedUpdateAnalysisViewsLbl: Label 'Completed Update Analysis Views, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldUpdateAnalysisView(var AnalysisView: Record "Analysis View"; var DimensionCorrection: Record "Dimension Correction"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSelectedAnalysisViewsOnAfterSetFilter(var AnalysisView: Record "Analysis View");
    begin
    end;
}
