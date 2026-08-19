#pragma warning disable AA0247
codeunit 17305 "Create Tax Calc. Entries"
{
    TableNo = "Tax Calc. G/L Entry";

    trigger OnRun()
    begin
        Code(Rec."Starting Date", Rec."Ending Date", Rec."Section Code");
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxCalcDimMgt: Codeunit "Tax Calc. Dim. Mgt.";
#pragma warning disable AA0074
        Text21000901: Label 'Illegal filter setting.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000902: Label 'Entry %1 %2 Line %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";

    [Scope('OnPrem')]
    procedure "Code"(DateBegin: Date; DateEnd: Date; TaxDifSectionCode: Code[10])
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TempTaxCalcLine: Record "Tax Calc. Line" temporary;
        TaxCalcAccumul: Record "Tax Calc. Accumulation";
        TaxCalcAccumul0: Record "Tax Calc. Accumulation";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        Wnd: Dialog;
    begin
        TaxCalcMgt.ValidateAbsenceGLEntriesDate(DateBegin, DateEnd, TaxDifSectionCode);

        Wnd.Open(Text21000900);
        Wnd.Update(1, DateBegin);
        Wnd.Update(2, DateEnd);

        Clear(TaxCalcDimMgt);

        TaxCalcAccumul.Reset();
        if not TaxCalcAccumul.FindLast() then
            TaxCalcAccumul."Entry No." := 0;

        TaxCalcAccumul.Reset();
        TaxCalcAccumul.Init();
        TaxCalcAccumul."Section Code" := TaxDifSectionCode;
        TaxCalcAccumul."Starting Date" := DateBegin;
        TaxCalcAccumul."Ending Date" := DateEnd;

        TaxCalcHeader.SetRange("Section Code", TaxDifSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. G/L Entry");
        if TaxCalcHeader.FindSet() then
            repeat
                if TaxCalcHeader."G/L Corr. Analysis View Code" <> '' then
                    GLCorrAnalysisView.Get(TaxCalcHeader."G/L Corr. Analysis View Code");
                TaxCalcLine.SetRange("Section Code", TaxCalcHeader."Section Code");
                TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
                if TaxCalcLine.FindSet() then
                    repeat
                        TempTaxCalcLine := TaxCalcLine;
                        if TaxCalcLine."Expression Type" = TaxCalcLine."Expression Type"::SumField then begin
                            TaxCalcSelectionSetup.Reset();
                            TaxCalcSelectionSetup.SetRange("Section Code", TaxCalcHeader."Section Code");
                            TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeader."No.");
                            if TaxCalcLine."Selection Line Code" <> '' then
                                TaxCalcSelectionSetup.SetRange("Line Code", TaxCalcLine."Selection Line Code");
                            if TaxCalcSelectionSetup.FindSet() then
                                repeat
                                    if TaxCalcHeader."G/L Corr. Analysis View Code" <> '' then begin
                                        GLCorrAnalysisViewEntry.Reset();
                                        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", TaxCalcHeader."G/L Corr. Analysis View Code");
                                        GLCorrAnalysisViewEntry.SetRange("Posting Date", DateBegin, DateEnd);
                                        TaxCalcDimMgt.SetDimFilters2GLCorrAnViewEntr(
                                          GLCorrAnalysisViewEntry,
                                          GLCorrAnalysisView,
                                          TaxCalcSelectionSetup,
                                          TaxCalcLine);
                                        if TaxCalcSelectionSetup."Account No." <> '' then
                                            GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.");
                                        if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                                            GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.");
                                        GLCorrAnalysisViewEntry.CalcSums(Amount);
                                        TempTaxCalcLine.Value := TempTaxCalcLine.Value + GLCorrAnalysisViewEntry.Amount;
                                    end else begin
                                        GLCorrEntry.Reset();
                                        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
                                        GLCorrEntry.SetRange("Posting Date", DateBegin, DateEnd);
                                        if TaxCalcSelectionSetup."Account No." <> '' then
                                            GLCorrEntry.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.");
                                        if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                                            GLCorrEntry.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.");
                                        GLCorrEntry.CalcSums(Amount);
                                        TempTaxCalcLine.Value := TempTaxCalcLine.Value + GLCorrEntry.Amount;
                                    end;
                                until TaxCalcSelectionSetup.Next() = 0;
                        end;

                        TempTaxCalcLine.Insert();
                    until TaxCalcLine.Next() = 0;

                if TempTaxCalcLine.FindSet() then
                    repeat
                        TaxCalcAccumul."Template Line Code" := TempTaxCalcLine."Line Code";
                        TaxCalcAccumul."Section Code" := TempTaxCalcLine."Section Code";
                        TaxCalcAccumul."Register No." := TempTaxCalcLine.Code;
                        TaxCalcAccumul.Indentation := TempTaxCalcLine.Indentation;
                        TaxCalcAccumul.Bold := TempTaxCalcLine.Bold;
                        TaxCalcAccumul.Description := TempTaxCalcLine.Description;
                        TaxCalcAccumul.Amount := TempTaxCalcLine.Value;
                        TaxCalcAccumul."Amount Period" := TempTaxCalcLine.Value;
                        TaxCalcAccumul."Template Line No." := TempTaxCalcLine."Line No.";
                        TaxCalcAccumul."Tax Diff. Amount (Base)" := TempTaxCalcLine."Tax Diff. Amount (Base)";
                        TaxCalcAccumul."Tax Diff. Amount (Tax)" := TempTaxCalcLine."Tax Diff. Amount (Tax)";
                        TaxCalcAccumul."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxCalcAccumul."Starting Date",
                            TaxCalcAccumul."Ending Date",
                            TempTaxCalcLine.Period);
                        TaxCalcAccumul.Amount := TaxCalcAccumul."Amount Period";
                        TaxCalcAccumul."Entry No." += 1;
                        TaxCalcAccumul.Insert();
                        if TempTaxCalcLine.Period <> '' then begin
                            TaxCalcAccumul0 := TaxCalcAccumul;
                            TaxCalcAccumul0.Reset();
                            TaxCalcAccumul0.SetCurrentKey(
                              "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxCalcAccumul0.SetRange("Section Code", TaxCalcAccumul."Section Code");
                            TaxCalcAccumul0.SetRange("Register No.", TaxCalcAccumul."Register No.");
                            TaxCalcAccumul0.SetRange("Template Line No.", TaxCalcAccumul."Template Line No.");
                            TaxCalcAccumul0.SetFilter("Starting Date", TaxCalcAccumul."Amount Date Filter");
                            TaxCalcAccumul0.SetFilter("Ending Date", TaxCalcAccumul."Amount Date Filter");
                            TaxCalcAccumul0.CalcSums("Amount Period");
                            TaxCalcAccumul.Amount := TaxCalcAccumul0."Amount Period";
                            TaxCalcAccumul.Modify();
                        end;
                    until TempTaxCalcLine.Next() = 0;

                TempTaxCalcLine.DeleteAll();
            until TaxCalcHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure BuildTaxCalcCorresp(DateBegin: Date; DateEnd: Date; SectionCode: Code[10])
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        GLCorrespondEntry: Record "G/L Correspondence Entry";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TempTaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter" temporary;
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        Wnd: Dialog;
        Total: Integer;
        Procesing: Integer;
    begin
        TaxCalcMgt.ValidateDateBeginDateEnd(DateBegin, DateEnd, SectionCode);

        TaxCalcHeader.Reset();
        TaxCalcHeader.SetRange("Section Code", SectionCode);
        if not TaxCalcHeader.FindFirst() then
            exit;

        Wnd.Open(Text21000900);
        Wnd.Update(1, DateBegin);
        Wnd.Update(2, DateEnd);
        Wnd.Update(4, GLCorrespondEntry.TableCaption());

        TaxCalcSelectionSetup.Reset();
        TaxCalcSelectionSetup.SetRange("Section Code", SectionCode);
        Total := TaxCalcSelectionSetup.Count();
        TaxCalcCorrespEntry."Section Code" := SectionCode;

        DebitGLAcc.SetRange("Account Type", DebitGLAcc."Account Type"::Posting);
        CreditGLAcc.SetRange("Account Type", CreditGLAcc."Account Type"::Posting);
        repeat
            TaxCalcCorrespEntry."Tax Register ID Totaling" := TaxCalcHeader."Register ID";
            TaxCalcCorrespEntry."Register Type" := TaxCalcCorrespEntry."Register Type"::" ";
            TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeader."No.");

            TaxCalcCorrespEntry."Register Type" := TaxCalcCorrespEntry."Register Type"::Item;
            TaxCalcSelectionSetup.SetRange("Register Type", TaxCalcSelectionSetup."Register Type"::Item);
            if TaxCalcSelectionSetup.FindSet() then
                repeat
                    Procesing += 1;
                    Wnd.Update(3, Round((Procesing / Total) * 10000, 1));
                    if (TaxCalcSelectionSetup."Account No." <> '') or (TaxCalcSelectionSetup."Bal. Account No." <> '') then
                        if (TaxCalcSelectionSetup."Account No." = '') or
                           (TaxCalcSelectionSetup."Bal. Account No." = '')
                        then begin
                            CopyDimValuefilter(TaxCalcSelectionSetup, TempTaxCalcDimFilter);
                            CreditGLAcc.SetFilter("No.", '%1', '');
                            DebitGLAcc.SetFilter("No.", '%1', '');
                            case true of
                                TaxCalcSelectionSetup."Bal. Account No." = '':
                                    DebitGLAcc.SetFilter("No.", TaxCalcSelectionSetup."Account No.");
                                TaxCalcSelectionSetup."Account No." = '':
                                    CreditGLAcc.SetFilter("No.", TaxCalcSelectionSetup."Bal. Account No.");
                            end;
                            TaxCalcCorrespEntry."Credit Account No." := '';
                            if DebitGLAcc.FindSet() then
                                repeat
                                    TaxCalcCorrespEntry."Debit Account No." := DebitGLAcc."No.";
                                    InsertTaxCalcCorrespondLine(
                                      TaxCalcCorrespEntry, TempTaxCalcDimFilter, TaxCalcSelectionSetup."Register No.", TaxCalcSelectionSetup."Line No.");
                                until DebitGLAcc.Next() = 0;
                            TaxCalcCorrespEntry."Debit Account No." := '';
                            if CreditGLAcc.FindSet() then
                                repeat
                                    TaxCalcCorrespEntry."Credit Account No." := CreditGLAcc."No.";
                                    InsertTaxCalcCorrespondLine(
                                      TaxCalcCorrespEntry, TempTaxCalcDimFilter, TaxCalcSelectionSetup."Register No.", TaxCalcSelectionSetup."Line No.");
                                until CreditGLAcc.Next() = 0;
                        end;
                until TaxCalcSelectionSetup.Next() = 0;

        until TaxCalcHeader.Next() = 0;
        Wnd.Close();
    end;

    [Scope('OnPrem')]
    procedure InsertTaxCalcCorrespondLine(var TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry"; var TmpTaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter" temporary; TaxCalcNo: Code[10]; TaxCalcSelectionSetupLineNo: Integer)
    var
        TaxCalcCorrEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter";
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        TaxCalcCorrEntry := TaxCalcCorrespEntry;
        TmpTaxCalcDimFilter.Reset();
        TaxCalcCorrespEntry.SetRange("Section Code", TaxCalcCorrespEntry."Section Code");
        TaxCalcCorrespEntry.SetRange("Debit Account No.", TaxCalcCorrespEntry."Debit Account No.");
        TaxCalcCorrespEntry.SetRange("Credit Account No.", TaxCalcCorrespEntry."Credit Account No.");
        if not TaxCalcCorrespEntry.FindLast() then begin
            TaxCalcCorrespEntry."Tax Register ID Totaling" := '';
            TaxCalcCorrespEntry."Where Used Register IDs" := '~';
            TaxCalcCorrespEntry.Insert(true);
        end;

        if StrPos(TaxCalcCorrespEntry."Where Used Register IDs", '~' + TaxCalcCorrEntry."Tax Register ID Totaling" + '~') = 0 then
            TaxCalcCorrespEntry."Where Used Register IDs" :=
              StrSubstNo('%1%2~', TaxCalcCorrespEntry."Where Used Register IDs", TaxCalcCorrEntry."Tax Register ID Totaling")
        else begin
            if TaxCalcCorrEntry."Starting Date" < TaxCalcCorrespEntry."Starting Date" then
                TaxCalcCorrespEntry."Starting Date" := TaxCalcCorrEntry."Starting Date";
            if TaxCalcCorrespEntry."Ending Date" < TaxCalcCorrEntry."Ending Date" then
                TaxCalcCorrespEntry."Ending Date" := TaxCalcCorrEntry."Ending Date";
        end;
        if TmpTaxCalcDimFilter.FindSet() then begin
            if StrPos(TaxCalcCorrespEntry."Tax Register ID Totaling", '~' + TaxCalcCorrEntry."Tax Register ID Totaling" + '~') <> 0 then
                Error(Text21000901);
            case CheckDimValueFilter(TmpTaxCalcDimFilter, TaxCalcCorrespEntry."Entry No.", TaxCalcNo, TaxCalcSelectionSetupLineNo) of
                -1:
                    Error(Text21000902, TaxCalcHeader.TableCaption(), TaxCalcNo, TaxCalcSelectionSetupLineNo);
                1:
                    repeat
                        TaxCalcDimFilter := TmpTaxCalcDimFilter;
                        TaxCalcDimFilter."Corresp. Entry No." := TaxCalcCorrespEntry."Entry No.";
                        TaxCalcDimFilter.Insert();
                    until TmpTaxCalcDimFilter.Next() = 0;
            end;
        end else begin
            if TaxCalcCorrespEntry."Tax Register ID Totaling" = '' then
                TaxCalcCorrespEntry."Tax Register ID Totaling" := '~';
            if StrPos(TaxCalcCorrespEntry."Tax Register ID Totaling", '~' + TaxCalcCorrEntry."Tax Register ID Totaling" + '~') = 0 then
                TaxCalcCorrespEntry."Tax Register ID Totaling" :=
                  StrSubstNo('%1%2~', TaxCalcCorrespEntry."Tax Register ID Totaling", TaxCalcCorrEntry."Tax Register ID Totaling");
        end;
        TaxCalcCorrespEntry.Modify();
        TaxCalcCorrespEntry := TaxCalcCorrEntry;
    end;

    [Scope('OnPrem')]
    procedure CopyDimValuefilter(TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup"; var TmpTaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter")
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        TmpTaxCalcDimFilter.DeleteAll();

        TmpTaxCalcDimFilter."Section Code" := TaxCalcSelectionSetup."Section Code";
        TmpTaxCalcDimFilter."Corresp. Entry No." := 0;

        TaxCalcDimFilter.SetRange("Section Code", TaxCalcSelectionSetup."Section Code");
        TaxCalcDimFilter.SetRange("Register No.", TaxCalcSelectionSetup."Register No.");
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::"Entry Setup");
        TaxCalcDimFilter.SetRange("Line No.", TaxCalcSelectionSetup."Line No.");
        if TaxCalcDimFilter.FindSet() then
            repeat
                TmpTaxCalcDimFilter."Connection Entry No." := TaxCalcDimFilter."Entry No.";
                TmpTaxCalcDimFilter.Insert();
            until TaxCalcDimFilter.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDimValueFilter(var TmpTaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter" temporary; TaxCalcCorrespEntryNo: Integer; TaxCalcNo: Code[10]; TaxCalcSelectionSetupNo: Integer): Integer
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Corr. Filter";
        OldTaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        NewTaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        OldExist: Boolean;
        NewExist: Boolean;
    begin
        TaxCalcDimFilter.SetRange("Section Code", TmpTaxCalcDimFilter."Section Code");
        TaxCalcDimFilter.SetRange("Corresp. Entry No.", TaxCalcCorrespEntryNo);
        if TaxCalcDimFilter.Find('-') then begin
            NewTaxCalcDimFilter.SetCurrentKey("Section Code", "Entry No.");
            NewTaxCalcDimFilter.SetRange("Section Code", TmpTaxCalcDimFilter."Section Code");
            NewTaxCalcDimFilter.SetRange("Register No.", TaxCalcNo);
            NewTaxCalcDimFilter.SetRange(Define, NewTaxCalcDimFilter.Define::"Entry Setup");
            NewTaxCalcDimFilter.SetRange("Line No.", TaxCalcSelectionSetupNo);
            NewExist := NewTaxCalcDimFilter.FindSet();
            OldTaxCalcDimFilter.SetCurrentKey("Section Code", "Entry No.");
            OldTaxCalcDimFilter.SetRange("Section Code", TmpTaxCalcDimFilter."Section Code");
            OldTaxCalcDimFilter.SetRange("Entry No.", TaxCalcDimFilter."Connection Entry No.");
            OldExist := OldTaxCalcDimFilter.FindSet();
            while OldExist and NewExist do
                if (OldTaxCalcDimFilter."Dimension Code" <> NewTaxCalcDimFilter."Dimension Code") or
                   (OldTaxCalcDimFilter."Dimension Value Filter" <> NewTaxCalcDimFilter."Dimension Value Filter")
                then
                    NewExist := not OldExist
                else begin
                    NewExist := NewTaxCalcDimFilter.Next() <> 0;
                    OldExist := TaxCalcDimFilter.Next() <> 0;
                    if OldExist then begin
                        OldTaxCalcDimFilter.SetRange("Entry No.", TaxCalcDimFilter."Connection Entry No.");
                        OldExist := OldTaxCalcDimFilter.FindFirst();
                    end;
                end;
            if OldExist <> NewExist then
                exit(-1);
            exit(0);
        end;
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure CalcFieldsTaxCalcEntry(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcLine0: Record "Tax Calc. Line";
        TaxCalcEntry: Record "Tax Calc. G/L Entry";
        TaxCalcBufferEntry: Record "Tax Calc. Buffer Entry";
        TaxCalcAccumul: Record "Tax Calc. Accumulation";
        TaxCalcAccumul0: Record "Tax Calc. Accumulation";
        TaxRegValueBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TempTaxCalcLine: Record "Tax Calc. Line" temporary;
        TempGLCorrespondEntry: Record "G/L Correspondence Entry" temporary;
        TaxCalcRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
        RoundingAmount: Decimal;
    begin
        TaxCalcHeader.SetRange("Section Code", SectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. G/L Entry");
        if not TaxCalcHeader.FindFirst() then
            exit;

        TaxCalcLine.SetRange("Section Code", SectionCode);
        TaxCalcLine0.SetRange("Section Code", SectionCode);
        TaxCalcLine0.SetRange("Date Filter", StartDate, EndDate);
        TaxCalcEntry.SetRange("Section Code", SectionCode);
        TaxCalcEntry.SetRange("Ending Date", EndDate);

        LinkAccumulateRecordRef.Open(DATABASE::"Tax Calc. Accumulation");
        TaxCalcAccumul.SetCurrentKey("Section Code", "Register No.", "Template Line No.");
        TaxCalcAccumul.SetRange("Section Code", SectionCode);
        TaxCalcAccumul.SetRange("Ending Date", EndDate);
        LinkAccumulateRecordRef.SetView(TaxCalcAccumul.GetView(false));

        TaxCalcSelectionSetup.Reset();
        TaxCalcSelectionSetup.SetRange("Section Code", SectionCode);

        TempGLCorrespondEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
        TempGLCorrespondEntry.Insert();

        Clear(TaxCalcDimMgt);

        repeat
            TaxRegValueBuffer."Order No." := TaxCalcHeader."No.";
            TaxCalcLine0.SetRange(Code, TaxCalcHeader."No.");
            TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
            TaxCalcLine.SetRange("Line Type", TaxCalcLine."Line Type"::CalcField);
            TaxCalcLine.SetRange("Sum Field No.", 0);
            if TaxCalcLine.FindFirst() then begin
                TaxCalcAccumul.SetRange("Register No.", TaxCalcHeader."No.");
                TaxCalcLine0.SetRange("Line Type", TaxCalcLine0."Line Type"::" ");
                TaxCalcLine0.SetFilter("Line Code", '<>''''');
                if TaxCalcLine0.FindSet() then
                    repeat
                        TaxCalcAccumul.SetRange("Template Line No.", TaxCalcLine0."Line No.");
                        TaxCalcAccumul.FindFirst();
                        TaxRegValueBuffer.Quantity := TaxCalcAccumul.Amount;
                        TaxRegValueBuffer."Order Line No." := TaxCalcLine0."Line No.";
                        TaxRegValueBuffer.Insert();
                    until TaxCalcLine0.Next() = 0;
                TaxCalcLine0.SetRange("Line Type");
                TaxCalcLine0.SetRange("Line Code");
                TaxCalcRecordRef.GetTable(TaxCalcLine);
                TaxCalcRecordRef.SetView(TaxCalcLine0.GetView(false));
                TaxRegTermMgt.CalculateTemplateEntry(
                  TaxCalcRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef, TaxRegValueBuffer);
                repeat
                    EntryNoAmountBuffer.Get('', TaxCalcLine."Line No.");
                    TaxCalcAccumul.SetRange("Template Line No.", TaxCalcLine."Line No.");
                    TaxCalcAccumul.FindFirst();
                    TaxCalcAccumul.Amount := EntryNoAmountBuffer.Amount;
                    TaxCalcAccumul.Modify();
                until TaxCalcLine.Next() = 0;
                TaxRegValueBuffer.Reset();
                TaxRegValueBuffer.DeleteAll();
                EntryNoAmountBuffer.Reset();
                EntryNoAmountBuffer.DeleteAll();
            end;
            TaxCalcLine.SetFilter("Sum Field No.", '<>0');
            if TaxCalcLine.FindFirst() then begin
                TaxCalcLine.SetRange("Sum Field No.");
                TempTaxCalcLine.Reset();
                TempTaxCalcLine.DeleteAll();
                if TaxCalcLine0.FindSet() then
                    repeat
                        if TaxCalcLine0."Line Type" = TempTaxCalcLine."Line Type"::" " then
                            if TaxCalcLine0."Sum Field No." in
                               [TaxCalcEntry.FieldNo("Tax Amount")]
                            then begin
                                TempTaxCalcLine := TaxCalcLine0;
                                TempTaxCalcLine.Value := 0;
                                TempTaxCalcLine.Insert();
                            end;
                    until TaxCalcLine0.Next() = 0;
                TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeader."No.");
                TaxCalcEntry.SetFilter("Where Used Register IDs", '*~' + TaxCalcHeader."Register ID" + '~*');
                if TaxCalcEntry.Find('-') then begin
                    TaxCalcAccumul.SetRange("Register No.", TaxCalcHeader."No.");
                    TaxCalcLine.SetRange("Line Type", TaxCalcLine."Line Type"::" ");
                    TaxCalcLine.SetFilter("Line Code", '<>%1', '');
                    if TaxCalcLine.FindSet() then
                        repeat
                            TaxCalcAccumul.SetRange("Template Line No.", TaxCalcLine."Line No.");
                            TaxCalcAccumul.FindFirst();
                            TaxRegValueBuffer.Quantity := TaxCalcAccumul.Amount;
                            TaxRegValueBuffer."Order Line No." := TaxCalcLine."Line No.";
                            TaxRegValueBuffer.Insert();
                        until TaxCalcLine.Next() = 0;
                    RoundingAmount := 0;
                    TaxCalcBufferEntry.Init();
                    TaxCalcBufferEntry.Code := TaxCalcHeader."No.";
                    repeat
                        TaxCalcLine.SetRange("Line Type", TaxCalcLine."Line Type"::LineField);
                        TaxCalcLine.SetFilter("Line Code", '<>%1', '');
                        if TaxCalcLine.FindSet() then
                            repeat
                                case TaxCalcLine."Sum Field No." of
                                    TaxCalcEntry.FieldNo(Amount):
                                        TaxRegValueBuffer.Quantity := TaxCalcEntry.Amount;
                                    else
                                        TaxRegValueBuffer.Quantity := 0;
                                end;
                                TaxRegValueBuffer."Order Line No." := TaxCalcLine."Line No.";
                                if not TaxRegValueBuffer.Insert() then
                                    TaxRegValueBuffer.Modify();
                            until TaxCalcLine.Next() = 0;
                        TaxCalcRecordRef.GetTable(TaxCalcLine);
                        TaxCalcRecordRef.SetView(TaxCalcLine0.GetView(false));
                        TaxRegTermMgt.CalculateTemplateEntry(
                          TaxCalcRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef, TaxRegValueBuffer);
                        TaxCalcLine.SetRange("Line Type", TaxCalcLine."Line Type"::CalcField);
                        TaxCalcLine.SetRange("Line Code");
                        TaxCalcLine.FindSet();
                        TaxCalcBufferEntry."Entry No." := TaxCalcEntry."Entry No.";
                        repeat
                            EntryNoAmountBuffer.Get('', TaxCalcLine."Line No.");
                            case TaxCalcLine."Sum Field No." of
                                TaxCalcEntry.FieldNo("Tax Amount"):
                                    begin
                                        TaxCalcBufferEntry."Tax Amount" := Round(EntryNoAmountBuffer.Amount + RoundingAmount);
                                        RoundingAmount :=
                                          EntryNoAmountBuffer.Amount + RoundingAmount - TaxCalcBufferEntry."Tax Amount";
                                    end;
                                TaxCalcEntry.FieldNo("Tax Factor"):
                                    TaxCalcBufferEntry."Tax Factor" := EntryNoAmountBuffer.Amount;
                            end;
                        until TaxCalcLine.Next() = 0;
                        TaxCalcBufferEntry.Insert();
                        EntryNoAmountBuffer.DeleteAll();

                        TempTaxCalcLine.Reset();
                        if TempTaxCalcLine.FindFirst() and TaxCalcSelectionSetup.Find('-') then begin
                            TaxCalcDimMgt.SetTaxCalcEntryDim(SectionCode,
                              TaxCalcEntry."Dimension 1 Value Code", TaxCalcEntry."Dimension 2 Value Code",
                              TaxCalcEntry."Dimension 3 Value Code", TaxCalcEntry."Dimension 4 Value Code");
                            TempGLCorrespondEntry."Debit Account No." := TaxCalcEntry."Debit Account No.";
                            TempGLCorrespondEntry."Credit Account No." := TaxCalcEntry."Credit Account No.";
                            TempGLCorrespondEntry.Modify();
                            repeat
                                if (TaxCalcSelectionSetup."Account No." <> '') or
                                   (TaxCalcSelectionSetup."Bal. Account No." <> '')
                                then begin
                                    if TaxCalcSelectionSetup."Account No." <> '' then
                                        TempGLCorrespondEntry.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.")
                                    else
                                        TempGLCorrespondEntry.SetRange("Debit Account No.");
                                    if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                                        TempGLCorrespondEntry.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.")
                                    else
                                        TempGLCorrespondEntry.SetRange("Credit Account No.");
                                    if TempGLCorrespondEntry.Find() then begin
                                        TempTaxCalcLine.SetFilter("Selection Line Code", '%1|%2', '', TaxCalcSelectionSetup."Line Code");
                                        if TempTaxCalcLine.FindSet() then
                                            repeat
                                                if TaxCalcDimMgt.ValidateTaxCalcDimFilters(TempTaxCalcLine) then begin
                                                    case TempTaxCalcLine."Sum Field No." of
                                                        TaxCalcEntry.FieldNo("Tax Amount"):
                                                            TempTaxCalcLine.Value += TaxCalcBufferEntry."Tax Amount";
                                                    end;
                                                    TempTaxCalcLine.Modify();
                                                end;
                                            until TempTaxCalcLine.Next() = 0;
                                    end;
                                end;
                            until TaxCalcSelectionSetup.Next() = 0;
                        end;
                    until TaxCalcEntry.Next() = 0;
                end;

                TempTaxCalcLine.Reset();
                TaxCalcAccumul0.SetRange("Section Code", TempTaxCalcLine."Section Code");
                TaxCalcAccumul0.SetRange("Register No.", TempTaxCalcLine.Code);
                if TempTaxCalcLine.FindSet() then
                    repeat
                        TaxCalcAccumul0.SetRange("Template Line No.", TempTaxCalcLine."Line No.");
                        TaxCalcAccumul0.FindFirst();
                        TaxCalcAccumul0.Amount := TempTaxCalcLine.Value;
                        TaxCalcAccumul0.Modify();
                    until TempTaxCalcLine.Next() = 0;
            end;
        until TaxCalcHeader.Next() = 0;
    end;
}

