#pragma warning disable AA0247
codeunit 17202 "Tax Dimension Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Change cannot be completed because %1 has records with %2=%3, %4=%5, %6=%7, %8=%9.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label 'Deletion cannot be completed because %1 has records with %2=%3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1003: Label 'Deletion cannot be completed because %1 has records with %2=%3, %4=%5.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegSection: Record "Tax Register Section";
        TempDimBuf1: Record "Dimension Buffer" temporary;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1004: Label 'Entry %1 %2\Debit %3 Credit %4';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1005: Label '\\Skip?';
#pragma warning restore AA0074
        TempDimBuf2: Record "Dimension Buffer" temporary;
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
        Text1009: Label '\Dimension %1 not found.\Filter %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1010: Label 'LineNo = %1 TaxRegDimComb."Line No." = %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLLine(TaxRegTemplate: Record "Tax Register Template"; var TaxRegGLEntry: Record "Tax Register G/L Entry")
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        TaxRegDimFilter.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", TaxRegTemplate."Line No.");
        TaxRegDimFilter.SetFilter("Dimension Value Filter", '<>%1', '');
        if TaxRegDimFilter.FindSet() then begin
            if TaxRegSection.Code <> TaxRegTemplate."Section Code" then
                TaxRegSection.Get(TaxRegTemplate."Section Code");
            repeat
                if TaxRegSection."Dimension 1 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegGLEntry.SetFilter("Dimension 1 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 2 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegGLEntry.SetFilter("Dimension 2 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 3 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegGLEntry.SetFilter("Dimension 3 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 4 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegGLEntry.SetFilter("Dimension 4 Value Code", TaxRegDimFilter."Dimension Value Filter");
            until TaxRegDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxItemLine(TaxRegTemplate: Record "Tax Register Template"; var TaxRegItemEntry: Record "Tax Register Item Entry")
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        TaxRegDimFilter.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", TaxRegTemplate."Line No.");
        TaxRegDimFilter.SetFilter("Dimension Value Filter", '<>%1', '');
        if TaxRegDimFilter.FindSet() then begin
            if TaxRegSection.Code <> TaxRegTemplate."Section Code" then
                TaxRegSection.Get(TaxRegTemplate."Section Code");
            repeat
                if TaxRegSection."Dimension 1 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegItemEntry.SetFilter("Dimension 1 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 2 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegItemEntry.SetFilter("Dimension 2 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 3 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegItemEntry.SetFilter("Dimension 3 Value Code", TaxRegDimFilter."Dimension Value Filter");
                if TaxRegSection."Dimension 4 Code" = TaxRegDimFilter."Dimension Code" then
                    TaxRegItemEntry.SetFilter("Dimension 4 Value Code", TaxRegDimFilter."Dimension Value Filter");
            until TaxRegDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateTemplateDimFilters(TaxRegTemplate: Record "Tax Register Template"): Boolean
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        DimensionValue: Record "Dimension Value";
    begin
        TempDimBuf1.Reset();

        TaxRegDimFilter.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", TaxRegTemplate."Line No.");
        if TaxRegDimFilter.FindSet() then
            repeat
                if not TempDimBuf1.Get(0, 0, TaxRegDimFilter."Dimension Code") then begin
                    if not (TaxRegDimFilter."Dimension Value Filter" in ['', '''''']) then
                        exit(false);
                end else begin
                    DimensionValue.SetRange("Dimension Code", TaxRegDimFilter."Dimension Code");
                    DimensionValue.SetFilter(Code, TaxRegDimFilter."Dimension Value Filter");
                    DimensionValue."Dimension Code" := TaxRegDimFilter."Dimension Code";
                    DimensionValue.Code := TempDimBuf1."Dimension Value Code";
                    if not DimensionValue.Find() then
                        exit(false);
                end;
            until TaxRegDimFilter.Next(1) = 0;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetTaxEntryDim(TaxRegSectionCode: Code[10]; Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; Dimension3ValueCode: Code[20]; Dimension4ValueCode: Code[20])
    begin
        if TaxRegSection.Code <> TaxRegSectionCode then
            TaxRegSection.Get(TaxRegSectionCode);
        TempDimBuf1.Reset();
        TempDimBuf1.DeleteAll();

        if (Dimension1ValueCode <> '') and (TaxRegSection."Dimension 1 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxRegSection."Dimension 1 Code";
            TempDimBuf1."Dimension Value Code" := Dimension1ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension2ValueCode <> '') and (TaxRegSection."Dimension 2 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxRegSection."Dimension 2 Code";
            TempDimBuf1."Dimension Value Code" := Dimension2ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension3ValueCode <> '') and (TaxRegSection."Dimension 3 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxRegSection."Dimension 3 Code";
            TempDimBuf1."Dimension Value Code" := Dimension3ValueCode;
            TempDimBuf1.Insert();
        end;

        if (Dimension4ValueCode <> '') and (TaxRegSection."Dimension 4 Code" <> '') then begin
            TempDimBuf1."Dimension Code" := TaxRegSection."Dimension 4 Code";
            TempDimBuf1."Dimension Value Code" := Dimension4ValueCode;
            TempDimBuf1.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure WhereUsedByDimensions(TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry"; var TaxRegIDTotaling: Code[250]; var Dimension1ValueCode: Code[20]; var Dimension2ValueCode: Code[20]; var Dimension3ValueCode: Code[20]; var Dimension4ValueCode: Code[20]): Boolean
    var
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxReg: Record "Tax Register";
        MessageText: Text[250];
    begin
        Dimension1ValueCode := '';
        Dimension2ValueCode := '';
        Dimension3ValueCode := '';
        Dimension4ValueCode := '';
        if (TaxRegGLCorrEntry."Debit Account No." <> '') and (TaxRegGLCorrEntry."Credit Account No." <> '') then
            MessageText :=
              StrSubstNo(Text1004,
                TaxReg.TableCaption(), TaxRegDimFilter."Tax Register No.",
                TaxRegGLCorrEntry."Debit Account No.", TaxRegGLCorrEntry."Credit Account No.")
        else
            if TaxRegGLCorrEntry."Debit Account No." <> '' then
                MessageText :=
                  StrSubstNo(Text1006,
                    TaxReg.TableCaption(), TaxRegDimFilter."Tax Register No.",
                    TaxRegGLCorrEntry."Debit Account No.")
            else
                MessageText :=
                  StrSubstNo(Text1007,
                    TaxReg.TableCaption(), TaxRegDimFilter."Tax Register No.",
                    TaxRegGLCorrEntry."Credit Account No.");

        TaxRegDimCorrFilter.SetRange("Section Code", TaxRegGLCorrEntry."Section Code");
        TaxRegDimCorrFilter.SetRange("G/L Corr. Entry No.", TaxRegGLCorrEntry."Entry No.");
        TaxRegDimCorrFilter.SetRange("Connection Type", TaxRegDimCorrFilter."Connection Type"::Combinations);
        if not CheckDimRestrictions(TaxRegDimCorrFilter) then
            exit(false);
        TaxRegDimCorrFilter.SetRange("Connection Type", TaxRegDimCorrFilter."Connection Type"::Filters);
        TaxRegIDTotaling := TaxRegGLCorrEntry."Tax Register ID Totaling";
        if TaxRegDimCorrFilter.FindSet() then
            repeat
                TaxRegDimFilter.SetCurrentKey("Section Code", "Entry No.");
                TaxRegDimFilter.SetRange("Section Code", TaxRegGLCorrEntry."Section Code");
                TaxRegDimFilter.SetRange("Entry No.", TaxRegDimCorrFilter."Connection Entry No.");
                if not CheckSetupDimFilters(TaxRegDimFilter, MessageText) then
                    exit(false);
                if TaxRegDimFilter.FindSet() then
                    repeat
                        TaxReg.Get(TaxRegDimFilter."Section Code", TaxRegDimFilter."Tax Register No.");
                        if TaxRegIDTotaling = '' then
                            TaxRegIDTotaling := '~';
                        if StrPos(TaxRegIDTotaling, '~' + TaxReg."Register ID" + '~') = 0 then
                            TaxRegIDTotaling :=
                              StrSubstNo('%1%2~', TaxRegIDTotaling, TaxReg."Register ID");
                    until TaxRegDimFilter.Next(1) = 0;
            until TaxRegDimCorrFilter.Next(1) = 0;
        TempDimBuf2.Reset();
        if TempDimBuf2.FindSet() then
            repeat
                case TempDimBuf2."Dimension Code" of
                    TaxRegSection."Dimension 1 Code":
                        Dimension1ValueCode := TempDimBuf2."Dimension Value Code";
                    TaxRegSection."Dimension 2 Code":
                        Dimension2ValueCode := TempDimBuf2."Dimension Value Code";
                    TaxRegSection."Dimension 3 Code":
                        Dimension3ValueCode := TempDimBuf2."Dimension Value Code";
                    TaxRegSection."Dimension 4 Code":
                        Dimension4ValueCode := TempDimBuf2."Dimension Value Code";
                end;
            until TempDimBuf2.Next(1) = 0;
        exit(true);
    end;

    local procedure CheckSetupDimFilters(var TaxRegDimFilter: Record "Tax Register Dim. Filter"; MessageText: Text[250]): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        TempDimBuf1.Reset();
        if TempDimBuf1.FindSet() then
            repeat
                TaxRegDimFilter.SetRange("Dimension Code", TempDimBuf1."Dimension Code");
                if TaxRegDimFilter.FindSet() then begin
                    DimensionValue."Dimension Code" := TempDimBuf1."Dimension Code";
                    DimensionValue.Code := TempDimBuf1."Dimension Value Code";
                    DimensionValue.SetRange("Dimension Code", TempDimBuf1."Dimension Code");
                    repeat
                        DimensionValue.SetFilter(Code, TaxRegDimFilter."Dimension Value Filter");
                        if not DimensionValue.Find() then
                            exit(false);
                    until TaxRegDimFilter.Next(1) = 0;
                end;
            until TempDimBuf1.Next() = 0;

        TaxRegDimFilter.SetRange("Dimension Code");
        if TaxRegDimFilter.FindSet() then
            repeat
                if TaxRegDimFilter."If No Value" <> TaxRegDimFilter."If No Value"::Ignore then begin
                    TempDimBuf1.SetRange("Dimension Code", TaxRegDimFilter."Dimension Code");
                    if not TempDimBuf1.FindFirst() then
                        case TaxRegDimFilter."If No Value" of
                            TaxRegDimFilter."If No Value"::Skip:
                                exit(false);
                            TaxRegDimFilter."If No Value"::Confirm:
                                begin
                                    if Confirm(MessageText + Text1009 + Text1005,
                                         false,
                                         TaxRegDimFilter."Dimension Code",
                                         TaxRegDimFilter."Dimension Value Filter")
                                    then
                                        exit(false);
                                    Error('');
                                end;
                            TaxRegDimFilter."If No Value"::Error:
                                Error(MessageText + Text1009,
                                  TaxRegDimFilter."Dimension Code",
                                  TaxRegDimFilter."Dimension Value Filter");
                        end;
                end;
            until TaxRegDimFilter.Next(1) = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateSetupDimFilters(TaxRegEntrySetup: Record "Tax Register Line Setup"): Boolean
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxReg: Record "Tax Register";
        MessageText: Text[250];
    begin
        MessageText :=
          StrSubstNo(Text1008,
            TaxReg.TableCaption(), TaxRegEntrySetup."Tax Register No.", TaxRegEntrySetup."Line No.");
        TaxRegDimFilter.SetRange("Section Code", TaxRegEntrySetup."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegEntrySetup."Tax Register No.");
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::"Entry Setup");
        TaxRegDimFilter.SetRange("Line No.", TaxRegEntrySetup."Line No.");
        exit(CheckSetupDimFilters(TaxRegDimFilter, MessageText))
    end;

    [Scope('OnPrem')]
    procedure SetLedgEntryDim(TaxRegSectionCode: Code[10]; DimSetID: Integer)
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        if TaxRegSection.Code <> TaxRegSectionCode then
            TaxRegSection.Get(TaxRegSectionCode);
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
    procedure CheckDimComb(DimComb: Record "Dimension Combination"; TaxRegSectionCode: Code[10])
    var
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
    begin
        TaxRegDimComb.SetRange("Section Code", TaxRegSectionCode);
        TaxRegDimComb.SetRange("Dimension 1 Code", DimComb."Dimension 1 Code");
        TaxRegDimComb.SetRange("Dimension 2 Code", DimComb."Dimension 2 Code");
        if TaxRegDimComb.FindSet() then
            repeat
                if TaxRegDimComb."Combination Restriction" = TaxRegDimComb."Combination Restriction"::Limited then begin
                    TaxRegDimValueComb.SetRange("Section Code", TaxRegDimComb."Section Code");
                    TaxRegDimValueComb.SetRange("Tax Register No.", TaxRegDimComb."Tax Register No.");
                    TaxRegDimValueComb.SetRange("Line No.", TaxRegDimComb."Line No.");
                    TaxRegDimValueComb.SetRange("Dimension 1 Code", TaxRegDimComb."Dimension 1 Code");
                    TaxRegDimValueComb.SetRange("Dimension 2 Code", TaxRegDimComb."Dimension 2 Code");
                    if TaxRegDimValueComb.FindSet() then
                        repeat
                            if TaxRegDimValueComb."Type Limit" = TaxRegDimValueComb."Type Limit"::Blocked then begin
                                TaxRegDimDefValue.SetRange("Section Code", TaxRegDimValueComb."Section Code");
                                TaxRegDimDefValue.SetRange("Tax Register No.", TaxRegDimValueComb."Tax Register No.");
                                TaxRegDimDefValue.SetRange("Line No.", TaxRegDimValueComb."Line No.");
                                TaxRegDimDefValue.SetRange("Dimension 1 Code", TaxRegDimValueComb."Dimension 1 Code");
                                TaxRegDimDefValue.SetRange("Dimension 1 Value Code", TaxRegDimValueComb."Dimension 1 Value Code");
                                TaxRegDimDefValue.SetRange("Dimension 2 Code", TaxRegDimValueComb."Dimension 2 Code");
                                TaxRegDimDefValue.SetRange("Dimension 2 Value Code", TaxRegDimValueComb."Dimension 2 Value Code");
                                if TaxRegDimDefValue.FindFirst() then
                                    if DimComb."Combination Restriction" = DimComb."Combination Restriction"::Blocked then
                                        Error(Text1001,
                                          TaxRegDimDefValue.TableCaption(),
                                          TaxRegDimDefValue.FieldCaption("Dimension 1 Code"), TaxRegDimDefValue."Dimension 1 Code",
                                          TaxRegDimDefValue.FieldCaption("Dimension 2 Code"), TaxRegDimDefValue."Dimension 2 Code",
                                          TaxRegDimDefValue.FieldCaption("Dimension Code"), TaxRegDimDefValue."Dimension Code",
                                          TaxRegDimDefValue.FieldCaption("Dimension Value"), TaxRegDimDefValue."Dimension Value");
                            end;
                        until TaxRegDimValueComb.Next(1) = 0;
                end;
            until TaxRegDimComb.Next(1) = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDimCode(Dim: Record Dimension; TaxRegSectionCode: Code[10])
    var
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
    begin
        if TaxRegSectionCode <> '' then
            TaxRegDimComb.SetRange("Section Code", TaxRegSectionCode);
        TaxRegDimComb.SetRange("Dimension 1 Code", Dim.Code);
        if TaxRegDimComb.FindFirst() then
            Error(Text1002,
              TaxRegDimComb.TableCaption(),
              TaxRegDimComb.FieldCaption("Dimension 1 Code"), TaxRegDimComb."Dimension 1 Code");

        TaxRegDimComb.Reset();
        if TaxRegSectionCode <> '' then
            TaxRegDimComb.SetRange("Section Code", TaxRegSectionCode);
        TaxRegDimComb.SetRange("Dimension 2 Code", Dim.Code);
        if TaxRegDimComb.FindFirst() then
            Error(Text1002,
              TaxRegDimComb.TableCaption(),
              TaxRegDimComb.FieldCaption("Dimension 2 Code"), TaxRegDimComb."Dimension 2 Code");

        if TaxRegSectionCode <> '' then
            TaxRegDimDefValue.SetRange("Section Code", TaxRegSectionCode);
        TaxRegDimDefValue.SetRange("Dimension Code", Dim.Code);
        if TaxRegDimDefValue.FindFirst() then
            Error(Text1002,
              TaxRegDimDefValue.TableCaption(),
              TaxRegDimDefValue.FieldCaption("Dimension Code"), TaxRegDimDefValue."Dimension Code");
    end;

    [Scope('OnPrem')]
    procedure CheckDimValue(DimValue: Record "Dimension Value"; TaxRegSectionCode: Code[10])
    var
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
        TaxRegDimDefValue: Record "Tax Register Dim. Def. Value";
    begin
        TaxRegDimValueComb.SetRange("Section Code", TaxRegSectionCode);
        if TaxRegSectionCode <> '' then
            TaxRegDimValueComb.SetRange("Dimension 1 Code", DimValue."Dimension Code");
        TaxRegDimValueComb.SetRange("Dimension 1 Value Code", DimValue.Code);
        if TaxRegDimValueComb.FindFirst() then
            Error(Text1003,
              TaxRegDimValueComb.TableCaption(),
              TaxRegDimValueComb.FieldCaption("Dimension 1 Code"), TaxRegDimValueComb."Dimension 1 Code",
              TaxRegDimValueComb.FieldCaption("Dimension 1 Value Code"), TaxRegDimValueComb."Dimension 1 Value Code");

        TaxRegDimValueComb.Reset();
        if TaxRegSectionCode <> '' then
            TaxRegDimValueComb.SetRange("Section Code", TaxRegSectionCode);
        TaxRegDimValueComb.SetRange("Dimension 2 Code", DimValue."Dimension Code");
        TaxRegDimValueComb.SetRange("Dimension 2 Value Code", DimValue.Code);
        if TaxRegDimValueComb.FindFirst() then
            Error(Text1003,
              TaxRegDimValueComb.TableCaption(),
              TaxRegDimValueComb.FieldCaption("Dimension 2 Code"), TaxRegDimValueComb."Dimension 2 Code",
              TaxRegDimValueComb.FieldCaption("Dimension 2 Value Code"), TaxRegDimValueComb."Dimension 2 Value Code");

        TaxRegDimDefValue.SetRange("Section Code", TaxRegSectionCode);
        if TaxRegSectionCode <> '' then
            TaxRegDimDefValue.SetRange("Dimension Code", DimValue."Dimension Code");
        TaxRegDimDefValue.SetRange("Dimension Value", DimValue.Code);
        if TaxRegDimDefValue.FindFirst() then
            Error(Text1003,
              TaxRegDimDefValue.TableCaption(),
              TaxRegDimDefValue.FieldCaption("Dimension Code"), TaxRegDimDefValue."Dimension Code",
              TaxRegDimDefValue.FieldCaption("Dimension Value"), TaxRegDimDefValue."Dimension Value");
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxGLRecordRef(TaxRegTemplate: Record "Tax Register Template"; var TaxRegRecordRef: RecordRef)
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegFieldRef: FieldRef;
    begin
        TaxRegDimFilter.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", TaxRegTemplate."Line No.");
        TaxRegDimFilter.SetFilter("Dimension Value Filter", '<>%1', '');
        if TaxRegDimFilter.FindSet() then begin
            if TaxRegSection.Code <> TaxRegTemplate."Section Code" then
                TaxRegSection.Get(TaxRegTemplate."Section Code");
            repeat
                if TaxRegSection."Dimension 1 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegGLEntry.FieldNo("Dimension 1 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 2 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegGLEntry.FieldNo("Dimension 2 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 3 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegGLEntry.FieldNo("Dimension 3 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 4 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegGLEntry.FieldNo("Dimension 4 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
            until TaxRegDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2TaxItemRecordRef(TaxRegTemplate: Record "Tax Register Template"; var TaxRegRecordRef: RecordRef)
    var
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegFieldRef: FieldRef;
    begin
        TaxRegDimFilter.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
        TaxRegDimFilter.SetRange("Line No.", TaxRegTemplate."Line No.");
        TaxRegDimFilter.SetFilter("Dimension Value Filter", '<>%1', '');
        if TaxRegDimFilter.FindSet() then begin
            if TaxRegSection.Code <> TaxRegTemplate."Section Code" then
                TaxRegSection.Get(TaxRegTemplate."Section Code");
            repeat
                if TaxRegSection."Dimension 1 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegItemEntry.FieldNo("Dimension 1 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 2 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegItemEntry.FieldNo("Dimension 2 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 3 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegItemEntry.FieldNo("Dimension 3 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
                if TaxRegSection."Dimension 4 Code" = TaxRegDimFilter."Dimension Code" then begin
                    TaxRegFieldRef := TaxRegRecordRef.Field(TaxRegItemEntry.FieldNo("Dimension 4 Value Code"));
                    TaxRegFieldRef.SetFilter(TaxRegDimFilter."Dimension Value Filter");
                end;
            until TaxRegDimFilter.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckDimRestrictions(var TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter"): Boolean
    var
        TempDimBuf0: Record "Dimension Buffer" temporary;
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TempTaxRegDimComb: Record "Tax Register Dim. Comb." temporary;
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
        TaxRegDimDefaultValue: Record "Tax Register Dim. Def. Value";
        SectionCode: Code[10];
        RegisterNo: Code[10];
        LineNo: Integer;
        CurrentDimCode: Code[20];
        CurrentDimValCode: Code[20];
        NextRecord: Boolean;
    begin
        TempDimBuf2.DeleteAll();

        TempDimBuf1.Reset();
        if not TempDimBuf1.FindFirst() then
            exit(true);

        if not TaxRegDimCorrFilter.FindFirst() then begin
            repeat
                TempDimBuf2 := TempDimBuf1;
                TempDimBuf2.Insert();
            until TempDimBuf1.Next(1) = 0;
            exit(true);
        end;

        TaxRegDimComb.SetCurrentKey("Section Code", "Entry No.");
        TaxRegDimComb.SetRange("Section Code", TaxRegDimCorrFilter."Section Code");

        LineNo := -1;
        repeat
            TaxRegDimComb.SetRange("Entry No.", TaxRegDimCorrFilter."Connection Entry No.");
            TaxRegDimComb.FindFirst();
            TempTaxRegDimComb := TaxRegDimComb;
            TempTaxRegDimComb.Insert();
            if LineNo <> -1 then
                if LineNo <> TaxRegDimComb."Line No." then begin
                    LineNo := LineNo;
                    Error(Text1010, LineNo, TaxRegDimComb."Line No.");
                end;
            LineNo := TaxRegDimComb."Line No.";
        until TaxRegDimCorrFilter.Next(1) = 0;

        SectionCode := TaxRegDimComb."Section Code";
        RegisterNo := TaxRegDimComb."Tax Register No.";
        LineNo := TaxRegDimComb."Line No.";

        TaxRegDimDefaultValue.SetRange("Section Code", SectionCode);
        TaxRegDimDefaultValue.SetRange("Tax Register No.", RegisterNo);
        TaxRegDimDefaultValue.SetRange("Line No.", LineNo);

        repeat
            TempDimBuf0 := TempDimBuf1;
            TempDimBuf0.Insert();
        until TempDimBuf1.Next(1) = 0;

        while TempDimBuf0.FindSet() do begin
            CurrentDimCode := TempDimBuf0."Dimension Code";
            CurrentDimValCode := TempDimBuf0."Dimension Value Code";
            TempDimBuf0.Delete();
            NextRecord := false;
            if TaxRegDimComb.Get(SectionCode, RegisterNo, LineNo, CurrentDimCode, '') then begin
                if TaxRegDimComb."Combination Restriction" = TaxRegDimComb."Combination Restriction"::Blocked then
                    exit(false);
                if TaxRegDimValueComb.Get(SectionCode, RegisterNo, LineNo, CurrentDimCode, CurrentDimValCode, '', '') then begin
                    if TaxRegDimValueComb."Type Limit" = TaxRegDimValueComb."Type Limit"::Blocked then
                        exit(false);
                    TaxRegDimDefaultValue.SetRange("Dimension 1 Code", CurrentDimCode);
                    TaxRegDimDefaultValue.SetRange("Dimension 1 Value Code", CurrentDimValCode);
                    TaxRegDimDefaultValue.SetFilter("Dimension 2 Code", '''''');
                    TaxRegDimDefaultValue.SetFilter("Dimension 2 Value Code", '''''');
                    if TaxRegDimDefaultValue.FindSet() then
                        repeat
                            TempDimBuf2."Dimension Code" := TaxRegDimDefaultValue."Dimension Code";
                            TempDimBuf2."Dimension Value Code" := TaxRegDimDefaultValue."Dimension Value";
                            TempDimBuf2.Insert();
                        until TaxRegDimDefaultValue.Next(1) = 0;
                    NextRecord := true;
                end;
            end else
                if TempDimBuf0.FindSet() then
                    repeat
                        if CurrentDimCode > TempDimBuf0."Dimension Code" then begin
                            if TaxRegDimComb.Get(SectionCode, RegisterNo, LineNo, TempDimBuf0."Dimension Code", CurrentDimCode) then begin
                                if TaxRegDimComb."Combination Restriction" = TaxRegDimComb."Combination Restriction"::Blocked then
                                    exit(false);
                                if TaxRegDimValueComb.Get(SectionCode, RegisterNo, LineNo, CurrentDimCode, CurrentDimValCode,
                                     TempDimBuf0."Dimension Code", TempDimBuf0."Dimension Value Code")
                                then begin
                                    if TaxRegDimValueComb."Type Limit" = TaxRegDimValueComb."Type Limit"::Blocked then
                                        exit(false);
                                    TaxRegDimDefaultValue.SetRange("Dimension 1 Code", CurrentDimCode);
                                    TaxRegDimDefaultValue.SetRange("Dimension 1 Value Code", CurrentDimValCode);
                                    TaxRegDimDefaultValue.SetRange("Dimension 2 Code", TempDimBuf0."Dimension Code");
                                    TaxRegDimDefaultValue.SetRange("Dimension 2 Value Code", TempDimBuf0."Dimension Value Code");
                                    if TaxRegDimDefaultValue.FindSet() then
                                        repeat
                                            TempDimBuf2."Dimension Code" := TaxRegDimDefaultValue."Dimension Code";
                                            TempDimBuf2."Dimension Value Code" := TaxRegDimDefaultValue."Dimension Value";
                                            TempDimBuf2.Insert();
                                        until TaxRegDimDefaultValue.Next(1) = 0;
                                    NextRecord := true;
                                end;
                            end;
                        end else
                            if TaxRegDimComb.Get(SectionCode, RegisterNo, LineNo, CurrentDimCode, TempDimBuf0."Dimension Code") then begin
                                if TaxRegDimComb."Combination Restriction" = TaxRegDimComb."Combination Restriction"::Blocked then
                                    exit(false);
                                if TaxRegDimValueComb.Get(SectionCode, RegisterNo, LineNo,
                                     TempDimBuf0."Dimension Code", TempDimBuf0."Dimension Value Code",
                                     CurrentDimCode, CurrentDimValCode)
                                then begin
                                    if TaxRegDimValueComb."Type Limit" = TaxRegDimValueComb."Type Limit"::Blocked then
                                        exit(false);
                                    TaxRegDimDefaultValue.SetRange("Dimension 1 Code", TempDimBuf0."Dimension Code");
                                    TaxRegDimDefaultValue.SetRange("Dimension 1 Value Code", TempDimBuf0."Dimension Value Code");
                                    TaxRegDimDefaultValue.SetRange("Dimension 2 Code", CurrentDimCode);
                                    TaxRegDimDefaultValue.SetRange("Dimension 2 Value Code", CurrentDimValCode);
                                    if TaxRegDimDefaultValue.FindSet() then
                                        repeat
                                            TempDimBuf2."Dimension Code" := TaxRegDimDefaultValue."Dimension Code";
                                            TempDimBuf2."Dimension Value Code" := TaxRegDimDefaultValue."Dimension Value";
                                            TempDimBuf2.Insert();
                                        until TaxRegDimDefaultValue.Next(1) = 0;
                                    NextRecord := true;
                                end;
                            end;
                    until NextRecord or (TempDimBuf0.Next() = 0);
            if not NextRecord then begin
                TempDimBuf2."Dimension Code" := CurrentDimCode;
                TempDimBuf2."Dimension Value Code" := CurrentDimValCode;
                TempDimBuf2.Insert();
            end;
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2GLCorrAnViewEntry(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; GLCorrAnalysisView: Record "G/L Corr. Analysis View"; TaxRegTemplate: Record "Tax Register Template"; TaxRegEntrySetup: Record "Tax Register Line Setup")
    begin
        GLCorrAnalysisViewEntry.FilterGroup(2);
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 1 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 1 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 2 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 2 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 3 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 3 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 1 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 1 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 2 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 2 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 3 Value Code",
          TaxRegTemplate.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 3 Code", 1));
        GLCorrAnalysisViewEntry.FilterGroup(4);
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 1 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 1 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 2 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 2 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Debit Dimension 3 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Debit Dimension 3 Code", 0));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 1 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 1 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 2 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 2 Code", 1));
        GLCorrAnalysisViewEntry.SetFilter(
          "Credit Dimension 3 Value Code",
          TaxRegEntrySetup.GetGLCorrDimFilter(GLCorrAnalysisView."Credit Dimension 3 Code", 1));
        GLCorrAnalysisViewEntry.FilterGroup(0);
    end;
}

