// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Analysis;

table 2582 "Dimension Correction"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
            Editable = false;
        }

        field(2; "Status"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = Draft,"In Process","Validaton in Process",Failed,Completed,"Undo in Process","Undo Completed";
            OptionCaption = 'Draft,In Process,Validation in Process,Failed,Completed,Undo in Process,Undo Completed';
            Editable = false;
        }

        field(3; Description; Text[250])
        {
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(6; "Generated Set IDs"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(7; "Total Updated Ledger Entries"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(8; Invalidated; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Invalidated Dim Correction" where("Invalidated Entry No." = field("Entry No.")));
        }

        field(9; "Total Selected Ledger Entries"; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(10; "Undo Last Ledger Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(11; "Error Message"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message';
            Editable = false;
        }

        field(12; Completed; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Ran Once';
            Editable = false;
        }

        field(13; "Last Job Queue Entry ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }

        field(14; "Generated Selected Entries"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(15; "Validated Selected Entries"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(16; "Last Updated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(17; "Last Validated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(18; "Started Correction"; Boolean)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(19; "Validation Errors Register ID"; Guid)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(20; "Validated At"; DateTime)
        {
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(21; "Validation Message"; Blob)
        {
            DataClassification = CustomerContent;
        }

        field(30; "Update Analysis Views"; Boolean)
        {
            DataClassification = CustomerContent;
        }

        field(31; "Update Analysis Views Status"; Option)
        {
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = "Not Started","In Process",Failed,Completed;
        }

        field(32; "Update Analysis Views Error"; Blob)
        {
            DataClassification = CustomerContent;
        }

        field(33; "Analysis View Update Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = "Update on posting only","All";
        }

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

    procedure SetUpdateAnalysisViewErrorMessage(ErrorMessage: Text)
    var
        AnalysisViewErrorMessageOutStream: OutStream;
    begin
        Rec."Update Analysis Views Error".CreateOutStream(AnalysisViewErrorMessageOutStream);
        AnalysisViewErrorMessageOutStream.WriteText(ErrorMessage);
    end;

    procedure GetUpdateAnalysisViewErrorMessage(var ErrorMessage: Text)
    var
        AnalysisViewErrorMessageInStream: InStream;
    begin
        Rec.CalcFields("Update Analysis Views Error");
        Rec."Update Analysis Views Error".CreateInStream(AnalysisViewErrorMessageInStream);
        AnalysisViewErrorMessageInStream.ReadText(ErrorMessage)
    end;

    procedure SetValidateDimensionChangesText(StatusText: Text)
    var
        ValidateDimensionChangesOutStream: OutStream;
    begin
        Rec."Validation Message".CreateOutStream(ValidateDimensionChangesOutStream);
        ValidateDimensionChangesOutStream.WriteText(StatusText);
    end;

    procedure GetValidateDimensionChangesText(var StatusText: Text)
    var
        ValidateDimensionChangesInStream: InStream;
    begin
        Rec.CalcFields("Validation Message");
        Rec."Validation Message".CreateInStream(ValidateDimensionChangesInStream);
        ValidateDimensionChangesInStream.ReadText(StatusText)
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var DimensionCorrection: Record "Dimension Correction")
    begin
    end;
}
