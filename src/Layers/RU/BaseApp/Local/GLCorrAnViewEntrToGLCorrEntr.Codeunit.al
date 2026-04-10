#pragma warning disable AA0247
codeunit 14941 GLCorrAnViewEntrToGLCorrEntr
{

    trigger OnRun()
    begin
    end;

    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLSetup: Record "General Ledger Setup";
        UpdateGLCorrAnalysisView: Codeunit "Update G/L Corr. Analysis View";

    [Scope('OnPrem')]
    procedure GetGLCorrEntries(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; var TempGLCorrEntry: Record "G/L Correspondence Entry")
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
        AccountingPeriod: Record "Accounting Period";
        GlobalDimValue: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        GLCorrAnalysisView.Get(GLCorrAnalysisViewEntry."G/L Corr. Analysis View Code");

        GLSetup.Get();

        StartDate := GLCorrAnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        if StartDate < GLCorrAnalysisView."Starting Date" then
            StartDate := 0D
        else
            if (GLCorrAnalysisViewEntry."Posting Date" = NormalDate(GLCorrAnalysisViewEntry."Posting Date")) and
               not (GLCorrAnalysisView."Date Compression" in [GLCorrAnalysisView."Date Compression"::None, GLCorrAnalysisView."Date Compression"::Day])
            then
                case GLCorrAnalysisView."Date Compression" of
                    GLCorrAnalysisView."Date Compression"::Week:
                        EndDate := CalcDate('<-CW+6D>', StartDate);
                    GLCorrAnalysisView."Date Compression"::Month:
                        EndDate := CalcDate('<+1M-1D>', StartDate);
                    GLCorrAnalysisView."Date Compression"::Quarter:
                        EndDate := CalcDate('<+3M-1D>', StartDate);
                    GLCorrAnalysisView."Date Compression"::Year:
                        EndDate := CalcDate('<+1Y-1D>', StartDate);
                    GLCorrAnalysisView."Date Compression"::Period:
                        begin
                            AccountingPeriod."Starting Date" := StartDate;
                            if AccountingPeriod.Next() <> 0 then
                                EndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date")
                            else
                                EndDate := 99991231D
                        end;
                end;

        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.", "Posting Date");
        GLCorrEntry.SetRange("Debit Account No.", GLCorrAnalysisViewEntry."Debit Account No.");
        GLCorrEntry.SetRange("Credit Account No.", GLCorrAnalysisViewEntry."Credit Account No.");
        GLCorrEntry.SetRange("Posting Date", StartDate, EndDate);
        GLCorrEntry.SetRange("Entry No.", 0, GLCorrAnalysisView."Last Entry No.");

        if GetDebitGlobalDimValue(GLSetup."Global Dimension 1 Code", GLCorrAnalysisViewEntry, GlobalDimValue) then
            GLCorrEntry.SetRange("Debit Global Dimension 1 Code", GlobalDimValue)
        else
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisViewEntry."G/L Corr. Analysis View Code", 0, GLSetup."Global Dimension 1 Code")
            then
                GLCorrEntry.SetFilter("Debit Global Dimension 1 Code", GLCorrAnalysisViewFilter."Dimension Value Filter");

        if GetDebitGlobalDimValue(GLSetup."Global Dimension 2 Code", GLCorrAnalysisViewEntry, GlobalDimValue) then
            GLCorrEntry.SetRange("Debit Global Dimension 2 Code", GlobalDimValue)
        else
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisViewEntry."G/L Corr. Analysis View Code", 0, GLSetup."Global Dimension 2 Code")
            then
                GLCorrEntry.SetFilter("Debit Global Dimension 2 Code", GLCorrAnalysisViewFilter."Dimension Value Filter");

        if GetCreditGlobalDimValue(GLSetup."Global Dimension 1 Code", GLCorrAnalysisViewEntry, GlobalDimValue) then
            GLCorrEntry.SetRange("Credit Global Dimension 1 Code", GlobalDimValue)
        else
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisViewEntry."G/L Corr. Analysis View Code", 1, GLSetup."Global Dimension 1 Code")
            then
                GLCorrEntry.SetFilter("Credit Global Dimension 1 Code", GLCorrAnalysisViewFilter."Dimension Value Filter");

        if GetCreditGlobalDimValue(GLSetup."Global Dimension 2 Code", GLCorrAnalysisViewEntry, GlobalDimValue) then
            GLCorrEntry.SetRange("Credit Global Dimension 2 Code", GlobalDimValue)
        else
            if GLCorrAnalysisViewFilter.Get(GLCorrAnalysisViewEntry."G/L Corr. Analysis View Code", 1, GLSetup."Global Dimension 2 Code")
            then
                GLCorrEntry.SetFilter("Credit Global Dimension 2 Code", GLCorrAnalysisViewFilter."Dimension Value Filter");

        if GLCorrEntry.FindSet() then
            repeat
                if DimEntryOK(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 1 Code",
                     GLCorrAnalysisViewEntry."Debit Dimension 1 Value Code") and
                   DimEntryOK(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 2 Code",
                     GLCorrAnalysisViewEntry."Debit Dimension 2 Value Code") and
                   DimEntryOK(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView."Debit Dimension 3 Code",
                     GLCorrAnalysisViewEntry."Debit Dimension 3 Value Code") and
                   DimEntryOK(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 1 Code",
                     GLCorrAnalysisViewEntry."Credit Dimension 1 Value Code") and
                   DimEntryOK(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 2 Code",
                     GLCorrAnalysisViewEntry."Credit Dimension 2 Value Code") and
                   DimEntryOK(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView."Credit Dimension 3 Code",
                     GLCorrAnalysisViewEntry."Credit Dimension 3 Value Code") and
                   UpdateGLCorrAnalysisView.DimSetIDInFilter(GLCorrEntry."Debit Dimension Set ID", GLCorrAnalysisView) and
                   UpdateGLCorrAnalysisView.DimSetIDInFilter(GLCorrEntry."Credit Dimension Set ID", GLCorrAnalysisView)
                then begin
                    TempGLCorrEntry := GLCorrEntry;
                    if TempGLCorrEntry.Insert() then;
                end;
            until GLCorrEntry.Next() = 0;
    end;

    local procedure DimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]): Boolean
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if Dim = '' then
            exit(true);

        if DimSetEntry.Get(DimSetID, Dim) then
            exit(DimSetEntry."Dimension Value Code" = DimValue);

        exit(DimValue = '');
    end;

    local procedure GetDebitGlobalDimValue(GlobalDim: Code[20]; var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            GLCorrAnalysisView."Debit Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Debit Dimension 1 Value Code";
                end;
            GLCorrAnalysisView."Debit Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Debit Dimension 2 Value Code";
                end;
            GLCorrAnalysisView."Debit Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Debit Dimension 3 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;

    local procedure GetCreditGlobalDimValue(GlobalDim: Code[20]; var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            GLCorrAnalysisView."Credit Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Credit Dimension 1 Value Code";
                end;
            GLCorrAnalysisView."Credit Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Credit Dimension 2 Value Code";
                end;
            GLCorrAnalysisView."Credit Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := GLCorrAnalysisViewEntry."Credit Dimension 3 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;
}

