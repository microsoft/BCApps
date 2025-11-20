// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using System.Threading;

codeunit 2583 "Dim Correction Validate"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        DimensionCorrection.Get(Rec."Record ID to Process");

        if DimensionCorrection.Completed then
            ValidateUndoCorrection(DimensionCorrection)
        else
            ValidateDraftCorrection(DimensionCorrection);
    end;

    procedure ValidateDraftCorrection(var DimensionCorrection: Record "Dimension Correction")
    var
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        ErrorCount: Integer;
    begin
        Session.LogMessage('0000EL9', StrSubstNo(StartingValidateDimensionCorrectionJobLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrectionMgt.VerifyCanValidateDimensionCorrection(DimensionCorrection);
        DimensionCorrectionMgt.ValidateBlockedNotUsed(DimensionCorrection);
        DimensionCorrectionMgt.SetValidatingStatusInProgress(DimensionCorrection);
        Commit();

        DimensionCorrectionMgt.GenerateSupportingTables(DimensionCorrection, TempDimCorrectionSetBuffer);
        DimensionCorrectionMgt.ValidateDimensionSets(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);
        DimensionCorrectionMgt.ValidateDimensionChanges(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);

        DimensionCorrection.Status := DimensionCorrection.Status::Draft;
        DimensionCorrection.Modify();
        Commit();

        DimensionCorrectionMgt.UpdateValidationStatusAndThrowErrorIfFailed(DimensionCorrection, ErrorCount);

        Session.LogMessage('0000ELA', StrSubstNo(CompletedValidateDimensionCorrectionJobLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    procedure ValidateUndoCorrection(var DimensionCorrection: Record "Dimension Correction")
    var
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        ErrorCount: Integer;
    begin
        Session.LogMessage('0000ELB', StrSubstNo(StartingValidateUndoDimensionCorrectionJobLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrectionMgt.VerifyCanValidateDimensionCorrection(DimensionCorrection);
        DimensionCorrectionMgt.VerifyCanUndoDimensionCorrection(DimensionCorrection);
        DimensionCorrectionMgt.ValidateBlockedNotUsed(DimensionCorrection);
        DimensionCorrectionMgt.SetValidatingStatusInProgress(DimensionCorrection);
        Commit();

        GetUndoDimensionCorrectionChanges(DimensionCorrection, TempDimCorrectionSetBuffer);
        DimensionCorrectionMgt.ValidateDimensionSets(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);
        DimensionCorrectionMgt.ValidateDimensionChanges(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);

        DimensionCorrection.Status := DimensionCorrection.Status::Completed;
        DimensionCorrection.Modify();
        Commit();

        DimensionCorrectionMgt.UpdateValidationStatusAndThrowErrorIfFailed(DimensionCorrection, ErrorCount);

        Session.LogMessage('0000ELC', StrSubstNo(CompletedValidateUndoDimensionCorrectionJobLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure GetUndoDimensionCorrectionChanges(DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
    begin
        DimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionSetBuffer.FindSet();
        repeat
            TempDimCorrectionSetBuffer.TransferFields(DimCorrectionSetBuffer, true);
            TempDimCorrectionSetBuffer."Target Set ID" := DimCorrectionSetBuffer."Dimension Set ID";
            TempDimCorrectionSetBuffer."Dimension Set ID" := DimCorrectionSetBuffer."Target Set ID";
            TempDimCorrectionSetBuffer.Insert();
        until DimCorrectionSetBuffer.Next() = 0;
    end;

    var
        StartingValidateDimensionCorrectionJobLbl: Label 'Starting Validate Dimension Correction Job, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedValidateDimensionCorrectionJobLbl: Label 'Completed Validate Dimension Correction Job, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        StartingValidateUndoDimensionCorrectionJobLbl: Label 'Starting Validate Undo Dimension Correction Job, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedValidateUndoDimensionCorrectionJobLbl: Label 'Completed Validate Undo Dimension Correction Job, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;
}
