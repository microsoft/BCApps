// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Analysis;

/// <summary>
/// Stores dimension correction definitions with status tracking and validation results.
/// Manages correction jobs for updating dimension values in posted general ledger entries.
/// </summary>
table 2582 "Dimension Correction"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the dimension correction record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
            Editable = false;
        }

        /// <summary>
        /// Current processing status of the dimension correction.
        /// </summary>
        field(2; "Status"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = Draft,"In Process","Validaton in Process",Failed,Completed,"Undo in Process","Undo Completed";
            OptionCaption = 'Draft,In Process,Validation in Process,Failed,Completed,Undo in Process,Undo Completed';
            Editable = false;
        }

        /// <summary>
        /// User-defined description for the dimension correction.
        /// </summary>
        field(3; Description; Text[250])
        {
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        /// <summary>
        /// Indicates whether target dimension set IDs have been generated for the correction.
        /// </summary>
        field(6; "Generated Set IDs"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Total number of general ledger entries updated by this dimension correction.
        /// </summary>
        field(7; "Total Updated Ledger Entries"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Indicates whether the dimension correction has been invalidated due to subsequent changes.
        /// </summary>
        field(8; Invalidated; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Invalidated Dim Correction" where("Invalidated Entry No." = field("Entry No.")));
        }

        /// <summary>
        /// Total number of ledger entries selected for dimension correction processing.
        /// </summary>
        field(9; "Total Selected Ledger Entries"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Last entry number processed during undo operation for tracking progress.
        /// </summary>
        field(10; "Undo Last Ledger Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Error message from the last failed dimension correction operation.
        /// </summary>
        field(11; "Error Message"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message';
            Editable = false;
        }

        /// <summary>
        /// Indicates whether the dimension correction has been completed at least once.
        /// </summary>
        field(12; Completed; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Ran Once';
            Editable = false;
        }

        /// <summary>
        /// GUID of the last job queue entry used for processing this dimension correction.
        /// </summary>
        field(13; "Last Job Queue Entry ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }

        /// <summary>
        /// Indicates whether selected ledger entries have been generated for the correction.
        /// </summary>
        field(14; "Generated Selected Entries"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Indicates whether selected entries have been validated for dimension correction.
        /// </summary>
        field(15; "Validated Selected Entries"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Entry number of the last updated general ledger entry during processing.
        /// </summary>
        field(16; "Last Updated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Entry number of the last validated general ledger entry during validation process.
        /// </summary>
        field(17; "Last Validated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Indicates whether the dimension correction processing has been started.
        /// </summary>
        field(18; "Started Correction"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// GUID for tracking validation errors in the error register system.
        /// </summary>
        field(19; "Validation Errors Register ID"; Guid)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// Date and time when the dimension correction validation was completed.
        /// </summary>
        field(20; "Validated At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>
        /// BLOB field containing validation messages and status information.
        /// </summary>
        field(21; "Validation Message"; Blob)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Indicates whether analysis views should be updated after dimension correction.
        /// </summary>
        field(30; "Update Analysis Views"; Boolean)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Current status of analysis views update process for this dimension correction.
        /// </summary>
        field(31; "Update Analysis Views Status"; Option)
        {
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = "Not Started","In Process",Failed,Completed;
        }

        /// <summary>
        /// BLOB field containing error messages from failed analysis views update operations.
        /// </summary>
        field(32; "Update Analysis Views Error"; Blob)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Specifies the type of analysis view update to perform after dimension correction.
        /// </summary>
        field(33; "Analysis View Update Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = "Update on posting only","All";
        }

        /// <summary>
        /// GUID of the job queue entry responsible for updating analysis views.
        /// </summary>
        field(34; "Update Analysis View Job ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }

        key(Key2; Status)
        {
        }
    }

    trigger OnInsert()
    var
        DimensionCorrection: Record "Dimension Correction";
        AnalysisView: Record "Analysis View";
    begin
        if not DimensionCorrection.FindLast() then
            Rec."Entry No." := 1
        else
            Rec."Entry No." := DimensionCorrection."Entry No." + 1;

        if Rec.Description = '' then
            Rec.Description := StrSubstNo(DimensionCorrectionLbl, Rec."Entry No.");

        AnalysisView.SetRange(Blocked, false);
        AnalysisView.SetRange("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.SetRange("Update on Posting", true);
        Rec."Update Analysis Views" := not AnalysisView.IsEmpty();
        OnAfterOnInsert(Rec);
    end;

    trigger OnDelete()
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimCorrectionChange: Record "Dim Correction Change";
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Entry No." = 0 then
            exit;

        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectSelectionCriteria.DeleteAll(true);

        DimCorrectionChange.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectionChange.DeleteAll(true);

        DimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectionSetBuffer.DeleteAll(true);

        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectionEntryLog.DeleteAll(true);
    end;

    /// <summary>
    /// Sets error message for analysis views update operation.
    /// </summary>
    /// <param name="ErrorMessage">Error message text to store</param>
    procedure SetUpdateAnalysisViewErrorMessage(ErrorMessage: Text)
    var
        AnalysisViewErrorMessageOutStream: OutStream;
    begin
        Rec."Update Analysis Views Error".CreateOutStream(AnalysisViewErrorMessageOutStream);
        AnalysisViewErrorMessageOutStream.WriteText(ErrorMessage);
    end;

    /// <summary>
    /// Retrieves error message from analysis views update operation.
    /// </summary>
    /// <param name="ErrorMessage">Variable to store retrieved error message</param>
    procedure GetUpdateAnalysisViewErrorMessage(var ErrorMessage: Text)
    var
        AnalysisViewErrorMessageInStream: InStream;
    begin
        Rec.CalcFields("Update Analysis Views Error");
        Rec."Update Analysis Views Error".CreateInStream(AnalysisViewErrorMessageInStream);
        AnalysisViewErrorMessageInStream.ReadText(ErrorMessage)
    end;

    /// <summary>
    /// Sets validation status text message in the validation message BLOB field.
    /// </summary>
    /// <param name="StatusText">Status text to store in validation message</param>
    procedure SetValidateDimensionChangesText(StatusText: Text)
    var
        ValidateDimensionChangesOutStream: OutStream;
    begin
        Rec."Validation Message".CreateOutStream(ValidateDimensionChangesOutStream);
        ValidateDimensionChangesOutStream.WriteText(StatusText);
    end;

    /// <summary>
    /// Retrieves validation status text from the validation message BLOB field.
    /// </summary>
    /// <param name="StatusText">Variable to store retrieved validation status text</param>
    procedure GetValidateDimensionChangesText(var StatusText: Text)
    var
        ValidateDimensionChangesInStream: InStream;
    begin
        Rec.CalcFields("Validation Message");
        Rec."Validation Message".CreateInStream(ValidateDimensionChangesInStream);
        ValidateDimensionChangesInStream.ReadText(StatusText)
    end;

    /// <summary>
    /// Reopens a dimension correction by resetting it to draft status and clearing processing data.
    /// </summary>
    procedure ReopenDraftDimensionCorrection()
    var
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        Rec.TestField(Completed, false);
        Rec.TestField("Last Updated Entry No.", 0);

        if Rec.Status = Rec.Status::"In Process" then
            Error(CannotChangeDimensionCorrectionErr, Rec.Status::"In Process");

        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", "Entry No.");
        DimCorrectionEntryLog.DeleteAll(true);

        DimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectionSetBuffer.DeleteAll(true);

        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", Rec."Entry No.");
        DimCorrectSelectionCriteria.ModifyAll("Last Entry No.", 0);

        DimensionCorrectionMgt.DeleteValidationErrors(Rec);

        Clear(Rec."Last Updated Entry No.");
        Clear(Rec."Generated Set IDs");
        Clear(Rec."Generated Selected Entries");
        Clear(Rec."Validated At");
        Clear(Rec."Validated Selected Entries");
        Clear(Rec."Last Validated Entry No.");
        Clear(Rec."Total Updated Ledger Entries");
        Clear(Rec."Total Selected Ledger Entries");
        Clear(Rec."Started Correction");
        Clear(Rec."Validation Message");
    end;

    var
        CannotChangeDimensionCorrectionErr: Label 'You cannot change a dimension correction while it is in %1 state.', Comment = '%1 Name of the state';
        DimensionCorrectionLbl: Label 'Dimension Correction %1', Comment = '%1 Entry No of the dimension correction';

    /// <summary>
    /// Integration event raised after inserting a new dimension correction record.
    /// </summary>
    /// <param name="DimensionCorrection">Dimension correction record that was inserted</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var DimensionCorrection: Record "Dimension Correction")
    begin
    end;
}
