#pragma warning disable AA0247
codeunit 17304 "Tax Calc. Dim. Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TempDimBuf1: Record "Dimension Buffer" temporary;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1004: Label 'Entry %1 %2\Debit %3 Credit %4';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1005: Label '\\Skip?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1006: Label 'Entry %1 %2 Debit %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1007: Label 'Entry %1 %2 Credit %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1008: Label 'Entry %1 %2 Line %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1009: Label '\Dimension %1 not found.\Filter %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLLine(TaxCalcLine: Record "Tax Calc. Line"; var TaxCalcEntry: Record "Tax Calc. G/L Entry")
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        TaxCalcDimFilter.SetRange("Section Code", TaxCalcLine."Section Code");
        TaxCalcDimFilter.SetRange("Register No.", TaxCalcLine.Code);
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::Template);
        TaxCalcDimFilter.SetRange("Line No.", TaxCalcLine."Line No.");
        TaxCalcDimFilter.SetFilter("Dimension Value Filter", '<>''''');
        if TaxCalcDimFilter.FindSet() then begin
            if TaxCalcSection.Code <> TaxCalcLine."Section Code" then
                TaxCalcSection.Get(TaxCalcLine."Section Code");
            repeat
                if TaxCalcSection."Dimension 1 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 1 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 2 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 2 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 3 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 3 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 4 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 4 Value Code", TaxCalcDimFilter."Dimension Value Filter");
            until TaxCalcDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxCalcItemLine(TaxCalcLine: Record "Tax Calc. Line"; var TaxCalcEntry: Record "Tax Calc. Item Entry")
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        TaxCalcDimFilter.SetRange("Section Code", TaxCalcLine."Section Code");
        TaxCalcDimFilter.SetRange("Register No.", TaxCalcLine.Code);
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::Template);
        TaxCalcDimFilter.SetRange("Line No.", TaxCalcLine."Line No.");
        TaxCalcDimFilter.SetFilter("Dimension Value Filter", '<>''''');
        if TaxCalcDimFilter.FindSet() then begin
            if TaxCalcSection.Code <> TaxCalcLine."Section Code" then
                TaxCalcSection.Get(TaxCalcLine."Section Code");
            repeat
                if TaxCalcSection."Dimension 1 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 1 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 2 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 2 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 3 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 3 Value Code", TaxCalcDimFilter."Dimension Value Filter");
                if TaxCalcSection."Dimension 4 Code" = TaxCalcDimFilter."Dimension Code" then
                    TaxCalcEntry.SetFilter("Dimension 4 Value Code", TaxCalcDimFilter."Dimension Value Filter");
            until TaxCalcDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateTaxCalcDimFilters(TaxCalcLine: Record "Tax Calc. Line"): Boolean
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        DimensionValue: Record "Dimension Value";
    begin
        TempDimBuf1.Reset();

        TaxCalcDimFilter.SetRange("Section Code", TaxCalcLine."Section Code");
        TaxCalcDimFilter.SetRange("Register No.", TaxCalcLine.Code);
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::Template);
        TaxCalcDimFilter.SetRange("Line No.", TaxCalcLine."Line No.");
        if TaxCalcDimFilter.FindSet() then
            repeat
                if not TempDimBuf1.Get(0, 0, TaxCalcDimFilter."Dimension Code") then begin
                    if not (TaxCalcDimFilter."Dimension Value Filter" in ['', '''''']) then
                        exit(false);
                end else begin
                    DimensionValue.SetRange("Dimension Code", TaxCalcDimFilter."Dimension Code");
                    DimensionValue.SetFilter(Code, TaxCalcDimFilter."Dimension Value Filter");
                    DimensionValue."Dimension Code" := TaxCalcDimFilter."Dimension Code";
                    DimensionValue.Code := TempDimBuf1."Dimension Value Code";
                    if not DimensionValue.Find() then
                        exit(false);
                end;
            until TaxCalcDimFilter.Next(1) = 0;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetTaxCalcEntryDim(TaxCalcSectionCode: Code[10]; Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; Dimension3ValueCode: Code[20]; Dimension4ValueCode: Code[20])
    begin
        if TaxCalcSection.Code <> TaxCalcSectionCode then
            TaxCalcSection.Get(TaxCalcSectionCode);
        TempDimBuf1.Reset();
        TempDimBuf1.DeleteAll();

        if (Dimension1ValueCode <> '') and (TaxCalcSection."Dimension 1 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxCalcSection."Dimension 1 Code";
            TempDimBuf1."Dimension Value Code" := Dimension1ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension2ValueCode <> '') and (TaxCalcSection."Dimension 2 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxCalcSection."Dimension 2 Code";
            TempDimBuf1."Dimension Value Code" := Dimension2ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension3ValueCode <> '') and (TaxCalcSection."Dimension 3 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxCalcSection."Dimension 3 Code";
            TempDimBuf1."Dimension Value Code" := Dimension3ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension4ValueCode <> '') and (TaxCalcSection."Dimension 4 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxCalcSection."Dimension 4 Code";
            TempDimBuf1."Dimension Value Code" := Dimension4ValueCode;
            TempDimBuf1.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure WhereUsedByDimensions(TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry"; var TaxCalcIDTotaling: Code[250]; var Dimension1ValueCode: Code[20]; var Dimension2ValueCode: Code[20]; var Dimension3ValueCode: Code[20]; var Dimension4ValueCode: Code[20]): Boolean
    var
        TaxCalcDimCorFilter: Record "Tax Calc. Dim. Corr. Filter";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        TaxCalcHeader: Record "Tax Calc. Header";
        MessageText: Text[250];
    begin
        Dimension1ValueCode := '';
        Dimension2ValueCode := '';
        Dimension3ValueCode := '';
        Dimension4ValueCode := '';
        if (TaxCalcCorrespEntry."Debit Account No." <> '') and (TaxCalcCorrespEntry."Credit Account No." <> '') then
            MessageText :=
              StrSubstNo(Text1004,
                TaxCalcHeader.TableCaption(), TaxCalcDimFilter."Register No.",
                TaxCalcCorrespEntry."Debit Account No.", TaxCalcCorrespEntry."Credit Account No.")
        else
            if TaxCalcCorrespEntry."Debit Account No." <> '' then
                MessageText :=
                  StrSubstNo(Text1006,
                    TaxCalcHeader.TableCaption(), TaxCalcDimFilter."Register No.",
                    TaxCalcCorrespEntry."Debit Account No.")
            else
                MessageText :=
                  StrSubstNo(Text1007,
                    TaxCalcHeader.TableCaption(), TaxCalcDimFilter."Register No.",
                    TaxCalcCorrespEntry."Credit Account No.");

        TaxCalcDimCorFilter.SetRange("Section Code", TaxCalcCorrespEntry."Section Code");
        TaxCalcDimCorFilter.SetRange("Corresp. Entry No.", TaxCalcCorrespEntry."Entry No.");
        TaxCalcIDTotaling := TaxCalcCorrespEntry."Tax Register ID Totaling";
        if TaxCalcDimCorFilter.FindSet() then
            repeat
                TaxCalcDimFilter.SetCurrentKey("Section Code", "Entry No.");
                TaxCalcDimFilter.SetRange("Section Code", TaxCalcCorrespEntry."Section Code");
                TaxCalcDimFilter.SetRange("Entry No.", TaxCalcDimCorFilter."Connection Entry No.");
                if CheckSetupDimFilters(TaxCalcDimFilter, MessageText) then
                    if TaxCalcDimFilter.FindSet() then
                        repeat
                            TaxCalcHeader.Get(TaxCalcDimFilter."Section Code", TaxCalcDimFilter."Register No.");
                            if TaxCalcIDTotaling = '' then
                                TaxCalcIDTotaling := '~';
                            if StrPos(TaxCalcIDTotaling, '~' + TaxCalcHeader."Register ID" + '~') = 0 then
                                TaxCalcIDTotaling :=
                                  StrSubstNo('%1%2~', TaxCalcIDTotaling, TaxCalcHeader."Register ID");
                        until TaxCalcDimFilter.Next(1) = 0;
            until TaxCalcDimCorFilter.Next(1) = 0;
        TempDimBuf1.Reset();
        if TempDimBuf1.FindSet() then
            repeat
                case TempDimBuf1."Dimension Code" of
                    TaxCalcSection."Dimension 1 Code":
                        Dimension1ValueCode := TempDimBuf1."Dimension Value Code";
                    TaxCalcSection."Dimension 2 Code":
                        Dimension2ValueCode := TempDimBuf1."Dimension Value Code";
                    TaxCalcSection."Dimension 3 Code":
                        Dimension3ValueCode := TempDimBuf1."Dimension Value Code";
                    TaxCalcSection."Dimension 4 Code":
                        Dimension4ValueCode := TempDimBuf1."Dimension Value Code";
                end;
            until TempDimBuf1.Next(1) = 0;
        exit(TaxCalcIDTotaling <> '');
    end;

    local procedure CheckSetupDimFilters(var TaxCalcDimFilter: Record "Tax Calc. Dim. Filter"; MessageText: Text[250]): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        TempDimBuf1.Reset();
        if TempDimBuf1.FindSet() then
            repeat
                TaxCalcDimFilter.SetRange("Dimension Code", TempDimBuf1."Dimension Code");
                if TaxCalcDimFilter.FindSet() then begin
                    DimensionValue."Dimension Code" := TempDimBuf1."Dimension Code";
                    DimensionValue.Code := TempDimBuf1."Dimension Value Code";
                    DimensionValue.SetRange("Dimension Code", TempDimBuf1."Dimension Code");
                    repeat
                        DimensionValue.SetFilter(Code, TaxCalcDimFilter."Dimension Value Filter");
                        if not DimensionValue.Find() then
                            exit(false);
                    until TaxCalcDimFilter.Next(1) = 0;
                end;
            until TempDimBuf1.Next() = 0;

        TaxCalcDimFilter.SetRange("Dimension Code");
        if TaxCalcDimFilter.FindSet() then
            repeat
                if TaxCalcDimFilter."If No Value" <> TaxCalcDimFilter."If No Value"::Ignore then begin
                    TempDimBuf1.SetRange("Dimension Code", TaxCalcDimFilter."Dimension Code");
                    if not TempDimBuf1.FindFirst() then
                        case TaxCalcDimFilter."If No Value" of
                            TaxCalcDimFilter."If No Value"::Skip:
                                exit(false);
                            TaxCalcDimFilter."If No Value"::Confirm:
                                begin
                                    if Confirm(MessageText + Text1009 + Text1005,
                                         false,
                                         TaxCalcDimFilter."Dimension Code",
                                         TaxCalcDimFilter."Dimension Value Filter")
                                    then
                                        exit(false);
                                    Error('');
                                end;
                            TaxCalcDimFilter."If No Value"::Error:
                                Error(MessageText + Text1009,
                                  TaxCalcDimFilter."Dimension Code",
                                  TaxCalcDimFilter."Dimension Value Filter");
                        end;
                end;
            until TaxCalcDimFilter.Next(1) = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateSetupDimFilters(TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup"): Boolean
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        TaxCalcHeader: Record "Tax Calc. Header";
        MessageText: Text[250];
    begin
        MessageText :=
          StrSubstNo(Text1008,
            TaxCalcHeader.TableCaption(), TaxCalcSelectionSetup."Register No.", TaxCalcSelectionSetup."Line No.");
        TaxCalcDimFilter.SetRange("Section Code", TaxCalcSelectionSetup."Section Code");
        TaxCalcDimFilter.SetRange("Register No.", TaxCalcSelectionSetup."Register No.");
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::"Entry Setup");
        TaxCalcDimFilter.SetRange("Line No.", TaxCalcSelectionSetup."Line No.");
        exit(CheckSetupDimFilters(TaxCalcDimFilter, MessageText))
    end;

    [Scope('OnPrem')]
    procedure SetLedgEntryDim(TaxCalcSectionCode: Code[10]; DimSetID: Integer)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        if TaxCalcSection.Code <> TaxCalcSectionCode then
            TaxCalcSection.Get(TaxCalcSectionCode);
        TempDimBuf1.Reset();
        TempDimBuf1.DeleteAll();

        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        if TempDimSetEntry.FindSet() then
            repeat
                TempDimBuf1."Dimension Code" := TempDimSetEntry."Dimension Code";
                TempDimBuf1."Dimension Value Code" := TempDimSetEntry."Dimension Value Code";
                TempDimBuf1.Insert();
            until TempDimSetEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2GLCorrAnViewEntr(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; GLCorrAnalysisView: Record "G/L Corr. Analysis View"; TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup"; TaxCalcLine: Record "Tax Calc. Line")
    begin
        GLCorrAnalysisViewEntry.FilterGroup(2);
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 1 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 1 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 2 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 2 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 3 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 3 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 1 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 1 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 2 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 2 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 3 Value Code",
          TaxCalcLine.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 3 Code", 1));
        GLCorrAnalysisViewEntry.FilterGroup(4);
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 1 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 1 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 2 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 2 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 3 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 3 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 1 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 1 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 2 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 2 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 3 Value Code",
          TaxCalcSelectionSetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 3 Code", 1));
        GLCorrAnalysisViewEntry.FilterGroup(0);
    end;
}

