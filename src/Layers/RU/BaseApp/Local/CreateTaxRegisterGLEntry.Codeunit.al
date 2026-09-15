#pragma warning disable AA0247
codeunit 17203 "Create Tax Register GL Entry"
{
    TableNo = "Tax Register G/L Entry";

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegSetup: Record "Tax Register Setup";
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
#pragma warning disable AA0074
        Text21000901: Label 'Illegal filter setting.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000902: Label 'Entry %1 %2 Line %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TempTaxRegTemplate: Record "Tax Register Template" temporary;
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
    begin
        TaxRegMgt.ValidateAbsenceGLEntriesDate(StartDate, EndDate, SectionCode);

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        Clear(TaxDimMgt);
        TaxRegSetup.Get();

        TaxRegAccumulation.Reset();
        if not TaxRegAccumulation.FindLast() then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Reset();
        TaxRegAccumulation.Init();
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register G/L Entry");
        if TaxReg.FindSet() then
            repeat
                if TaxReg."G/L Corr. Analysis View Code" <> '' then
                    GLCorrAnalysisView.Get(TaxReg."G/L Corr. Analysis View Code");
                TaxRegTemplate.SetRange("Section Code", TaxReg."Section Code");
                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                if TaxRegTemplate.FindSet() then
                    repeat
                        TempTaxRegTemplate := TaxRegTemplate;

                        if TaxRegTemplate.Expression <> '' then begin
                            TaxRegLineSetup.Reset();
                            TaxRegLineSetup.SetRange("Section Code", TaxReg."Section Code");
                            TaxRegLineSetup.SetRange("Tax Register No.", TaxReg."No.");
                            if TaxRegTemplate."Term Line Code" <> '' then
                                TaxRegLineSetup.SetRange("Line Code", TaxRegTemplate."Term Line Code");
                            if TaxRegLineSetup.FindSet() then
                                repeat
                                    if TaxReg."G/L Corr. Analysis View Code" <> '' then begin
                                        GLCorrAnalysisViewEntry.Reset();
                                        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", TaxReg."G/L Corr. Analysis View Code");
                                        GLCorrAnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);
                                        TaxDimMgt.SetDimFilters2GLCorrAnViewEntry(
                                          GLCorrAnalysisViewEntry, GLCorrAnalysisView, TaxRegTemplate, TaxRegLineSetup);
                                        case TaxRegLineSetup."Account Type" of
                                            TaxRegLineSetup."Account Type"::Correspondence:
                                                begin
                                                    if TaxRegLineSetup."Account No." <> '' then
                                                        GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                    if TaxRegLineSetup."Bal. Account No." <> '' then
                                                        GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Bal. Account No.");
                                                    GLCorrAnalysisViewEntry.CalcSums(Amount);
                                                    TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrAnalysisViewEntry.Amount;
                                                    FillAuxTabFromGLCorrAnViewEntry(
                                                      GLCorrAnalysisViewEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                end;
                                            TaxRegLineSetup."Account Type"::"G/L Account":
                                                case TaxRegLineSetup."Amount Type" of
                                                    TaxRegLineSetup."Amount Type"::Debit:
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrAnalysisViewEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrAnalysisViewEntry.Amount;
                                                            FillAuxTabFromGLCorrAnViewEntry(
                                                              GLCorrAnalysisViewEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                    TaxRegLineSetup."Amount Type"::Credit:
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrAnalysisViewEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrAnalysisViewEntry.Amount;
                                                            FillAuxTabFromGLCorrAnViewEntry(
                                                              GLCorrAnalysisViewEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                    TaxRegLineSetup."Amount Type"::"Net Change":
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrAnalysisViewEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrAnalysisViewEntry.Amount;
                                                            FillAuxTabFromGLCorrAnViewEntry(
                                                              GLCorrAnalysisViewEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                            GLCorrAnalysisViewEntry.SetRange("Debit Account No.");

                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrAnalysisViewEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value - GLCorrAnalysisViewEntry.Amount;
                                                            FillAuxTabFromGLCorrAnViewEntry(
                                                              GLCorrAnalysisViewEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                end;
                                        end;
                                    end else begin
                                        GLCorrEntry.Reset();
                                        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
                                        GLCorrEntry.SetRange("Posting Date", StartDate, EndDate);
                                        case TaxRegLineSetup."Account Type" of
                                            TaxRegLineSetup."Account Type"::Correspondence:
                                                begin
                                                    if TaxRegLineSetup."Account No." <> '' then
                                                        GLCorrEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                    if TaxRegLineSetup."Bal. Account No." <> '' then
                                                        GLCorrEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Bal. Account No.");
                                                    GLCorrEntry.CalcSums(Amount);
                                                    TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrEntry.Amount;
                                                    FillAuxTableFromGLCorrEntry(
                                                      GLCorrEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                end;
                                            TaxRegLineSetup."Account Type"::"G/L Account":
                                                case TaxRegLineSetup."Amount Type" of
                                                    TaxRegLineSetup."Amount Type"::Debit:
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrEntry.Amount;
                                                            FillAuxTableFromGLCorrEntry(
                                                              GLCorrEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                    TaxRegLineSetup."Amount Type"::Credit:
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrEntry.Amount;
                                                            FillAuxTableFromGLCorrEntry(
                                                              GLCorrEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                    TaxRegLineSetup."Amount Type"::"Net Change":
                                                        begin
                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value + GLCorrEntry.Amount;
                                                            FillAuxTableFromGLCorrEntry(
                                                              GLCorrEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                            GLCorrEntry.SetRange("Debit Account No.");

                                                            if TaxRegLineSetup."Account No." <> '' then
                                                                GLCorrEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                                            GLCorrEntry.CalcSums(Amount);
                                                            TempTaxRegTemplate.Value := TempTaxRegTemplate.Value - GLCorrEntry.Amount;
                                                            FillAuxTableFromGLCorrEntry(
                                                              GLCorrEntry, SectionCode, TaxReg."Register ID", StartDate, EndDate);
                                                        end;
                                                end;
                                        end;
                                    end;
                                until TaxRegLineSetup.Next() = 0;
                        end;

                        TempTaxRegTemplate.Insert();
                    until TaxRegTemplate.Next() = 0;

                if TempTaxRegTemplate.FindSet() then
                    repeat
                        TaxRegAccumulation."Report Line Code" := TempTaxRegTemplate."Report Line Code";
                        TaxRegAccumulation."Template Line Code" := TempTaxRegTemplate."Line Code";
                        TaxRegAccumulation."Section Code" := TempTaxRegTemplate."Section Code";
                        TaxRegAccumulation."Tax Register No." := TempTaxRegTemplate.Code;
                        TaxRegAccumulation.Indentation := TempTaxRegTemplate.Indentation;
                        TaxRegAccumulation.Bold := TempTaxRegTemplate.Bold;
                        TaxRegAccumulation.Description := TempTaxRegTemplate.Description;
                        TaxRegAccumulation.Amount := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Amount Period" := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Template Line No." := TempTaxRegTemplate."Line No.";
                        TaxRegAccumulation."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxRegAccumulation."Starting Date",
                            TaxRegAccumulation."Ending Date",
                            TempTaxRegTemplate.Period);
                        TaxRegAccumulation.Amount := TaxRegAccumulation."Amount Period";
                        TaxRegAccumulation."Entry No." += 1;
                        TaxRegAccumulation.Insert();
                        if TempTaxRegTemplate.Period <> '' then begin
                            TaxRegAccumulation2 := TaxRegAccumulation;
                            TaxRegAccumulation2.Reset();
                            TaxRegAccumulation2.SetCurrentKey(
                              "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxRegAccumulation2.SetRange("Section Code", TaxRegAccumulation."Section Code");
                            TaxRegAccumulation2.SetRange("Tax Register No.", TaxRegAccumulation."Tax Register No.");
                            TaxRegAccumulation2.SetRange("Template Line No.", TaxRegAccumulation."Template Line No.");
                            TaxRegAccumulation2.SetFilter("Starting Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.SetFilter("Ending Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.CalcSums("Amount Period");
                            TaxRegAccumulation.Amount := TaxRegAccumulation2."Amount Period";
                            TaxRegAccumulation.Modify();
                        end;
                    until TempTaxRegTemplate.Next() = 0;

                TempTaxRegTemplate.DeleteAll();
            until TaxReg.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure BuildTaxRegGLCorresp(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        GLCorrespondEntry: Record "G/L Correspondence Entry";
        TaxRegGLCorresp: Record "Tax Register G/L Corr. Entry";
        TaxReg: Record "Tax Register";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TmpTaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter" temporary;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        Total: Integer;
        Procesing: Integer;
    begin
        TaxRegMgt.ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxReg.Reset();
        TaxReg.SetRange("Section Code", SectionCode);
        if not TaxReg.Find('-') then
            exit;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);
        Window.Update(4, GLCorrespondEntry.TableCaption());

        TaxRegLineSetup.Reset();
        TaxRegLineSetup.SetRange("Section Code", SectionCode);
        Total := TaxRegLineSetup.Count();
        TaxRegGLCorresp."Section Code" := SectionCode;

        DebitGLAcc.SetRange("Account Type", DebitGLAcc."Account Type"::Posting);
        CreditGLAcc.SetRange("Account Type", CreditGLAcc."Account Type"::Posting);

        repeat
            TaxRegGLCorresp."Tax Register ID Totaling" := TaxReg."Register ID";
            TaxRegGLCorresp."Register Type" := TaxRegGLCorresp."Register Type"::" ";
            TaxRegLineSetup.SetRange("Tax Register No.", TaxReg."No.");
            TaxRegLineSetup.SetRange("Check Exist Entry", TaxRegLineSetup."Check Exist Entry"::Item);
            TaxRegLineSetup.SetRange("Account Type", TaxRegLineSetup."Account Type"::"G/L Account");
            if TaxRegLineSetup.FindSet() then
                repeat
                    Procesing += 1;
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));
                    CopyDimValuefilter(TaxRegLineSetup, TmpTaxRegDimCorrFilter);
                    CreditGLAcc.SetFilter("No.", '%1', '');
                    DebitGLAcc.SetFilter("No.", '%1', '');
                    case TaxRegLineSetup."Amount Type" of
                        TaxRegLineSetup."Amount Type"::Debit:
                            DebitGLAcc.SetFilter("No.", TaxRegLineSetup."Account No.");
                        TaxRegLineSetup."Amount Type"::Credit:
                            CreditGLAcc.SetFilter("No.", TaxRegLineSetup."Account No.");
                        TaxRegLineSetup."Amount Type"::"Net Change":
                            begin
                                DebitGLAcc.SetFilter("No.", TaxRegLineSetup."Account No.");
                                CreditGLAcc.SetFilter("No.", TaxRegLineSetup."Account No.");
                            end;
                    end;
                    TaxRegGLCorresp."Register Type" := TaxRegGLCorresp."Register Type"::Item;
                    TaxRegGLCorresp."Credit Account No." := '';
                    if DebitGLAcc.FindSet() then
                        repeat
                            TaxRegGLCorresp."Debit Account No." := DebitGLAcc."No.";
                            InsertTaxRegGLCorrespondLine(
                              TaxRegGLCorresp, TmpTaxRegDimCorrFilter, TaxRegLineSetup."Tax Register No.", TaxRegLineSetup."Line No.");
                        until DebitGLAcc.Next() = 0;
                    TaxRegGLCorresp."Debit Account No." := '';
                    if CreditGLAcc.FindSet() then
                        repeat
                            TaxRegGLCorresp."Credit Account No." := CreditGLAcc."No.";
                            InsertTaxRegGLCorrespondLine(
                              TaxRegGLCorresp, TmpTaxRegDimCorrFilter, TaxRegLineSetup."Tax Register No.", TaxRegLineSetup."Line No.");
                        until CreditGLAcc.Next() = 0;
                until TaxRegLineSetup.Next() = 0;
        until TaxReg.Next() = 0;
        Window.Close();
    end;

    local procedure InsertTaxRegGLCorrespondLine(var TaxRegGLCorrespond: Record "Tax Register G/L Corr. Entry"; var TmpTaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter" temporary; TaxRegNo: Code[10]; TaxEntrySetupLineNo: Integer)
    var
        TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry";
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        TaxRegiName: Record "Tax Register";
    begin
        TaxRegGLCorrEntry := TaxRegGLCorrespond;
        TmpTaxRegDimCorrFilter.Reset();
        TaxRegGLCorrespond.SetRange("Section Code", TaxRegGLCorrespond."Section Code");
        TaxRegGLCorrespond.SetRange("Debit Account No.", TaxRegGLCorrespond."Debit Account No.");
        TaxRegGLCorrespond.SetRange("Credit Account No.", TaxRegGLCorrespond."Credit Account No.");
        TaxRegGLCorrespond.SetRange("Register Type", TaxRegGLCorrespond."Register Type");
        if not TaxRegGLCorrespond.FindLast() then begin
            TaxRegGLCorrespond."Tax Register ID Totaling" := '';
            TaxRegGLCorrespond."Where Used Register IDs" := '~';
            TaxRegGLCorrespond.Insert(true);
        end;

        if StrPos(TaxRegGLCorrespond."Where Used Register IDs", '~' + TaxRegGLCorrEntry."Tax Register ID Totaling" + '~') = 0 then
            TaxRegGLCorrespond."Where Used Register IDs" :=
              StrSubstNo('%1%2~', TaxRegGLCorrespond."Where Used Register IDs", TaxRegGLCorrEntry."Tax Register ID Totaling")
        else begin
            if TaxRegGLCorrEntry."Starting Date" < TaxRegGLCorrespond."Starting Date" then
                TaxRegGLCorrespond."Starting Date" := TaxRegGLCorrEntry."Starting Date";
            if TaxRegGLCorrespond."Ending Date" < TaxRegGLCorrEntry."Ending Date" then
                TaxRegGLCorrespond."Ending Date" := TaxRegGLCorrEntry."Ending Date";
        end;
        TmpTaxRegDimCorrFilter.SetRange("Connection Type", TmpTaxRegDimCorrFilter."Connection Type"::Filters);
        if TmpTaxRegDimCorrFilter.FindFirst() then begin
            if StrPos(TaxRegGLCorrespond."Tax Register ID Totaling", '~' + TaxRegGLCorrEntry."Tax Register ID Totaling" + '~') <> 0 then
                Error(Text21000901);
            case CheckDimValueFilter(TmpTaxRegDimCorrFilter, TaxRegGLCorrespond."Entry No.", TaxRegNo, TaxEntrySetupLineNo) of
                -1:
                    Error(Text21000902, TaxRegiName.TableCaption(), TaxRegNo, TaxEntrySetupLineNo);
                1:
                    repeat
                        TaxRegDimCorrFilter := TmpTaxRegDimCorrFilter;
                        TaxRegDimCorrFilter."G/L Corr. Entry No." := TaxRegGLCorrespond."Entry No.";
                        TaxRegDimCorrFilter.Insert();
                    until TmpTaxRegDimCorrFilter.Next(1) = 0;
            end;
        end else begin
            if TaxRegGLCorrespond."Tax Register ID Totaling" = '' then
                TaxRegGLCorrespond."Tax Register ID Totaling" := '~';
            if StrPos(TaxRegGLCorrespond."Tax Register ID Totaling", '~' + TaxRegGLCorrEntry."Tax Register ID Totaling" + '~') = 0 then
                TaxRegGLCorrespond."Tax Register ID Totaling" :=
                  StrSubstNo('%1%2~', TaxRegGLCorrespond."Tax Register ID Totaling", TaxRegGLCorrEntry."Tax Register ID Totaling");
        end;
        TmpTaxRegDimCorrFilter.SetRange("Connection Type", TmpTaxRegDimCorrFilter."Connection Type"::Combinations);
        if TmpTaxRegDimCorrFilter.FindSet() then
            repeat
                TaxRegDimCorrFilter := TmpTaxRegDimCorrFilter;
                TaxRegDimCorrFilter."G/L Corr. Entry No." := TaxRegGLCorrespond."Entry No.";
                if TaxRegDimCorrFilter.Insert() then;
            until TmpTaxRegDimCorrFilter.Next(1) = 0;
        TmpTaxRegDimCorrFilter.SetRange("Connection Type");
        TaxRegGLCorrespond.Modify();
        TaxRegGLCorrespond := TaxRegGLCorrEntry;
    end;

    local procedure CopyDimValuefilter(TaxRegLineSetup: Record "Tax Register Line Setup"; var TempTaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter" temporary)
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
    begin
        TempTaxRegDimCorrFilter.DeleteAll();

        TempTaxRegDimCorrFilter."Section Code" := TaxRegLineSetup."Section Code";
        TempTaxRegDimCorrFilter."G/L Corr. Entry No." := 0;

        TaxRegDimFilter.SetRange("Section Code", TaxRegLineSetup."Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", TaxRegLineSetup."Tax Register No.");
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::"Entry Setup");
        TaxRegDimFilter.SetRange("Line No.", TaxRegLineSetup."Line No.");
        TempTaxRegDimCorrFilter."Connection Type" := TempTaxRegDimCorrFilter."Connection Type"::Filters;
        if TaxRegDimFilter.FindSet() then
            repeat
                TempTaxRegDimCorrFilter."Connection Entry No." := TaxRegDimFilter."Entry No.";
                TempTaxRegDimCorrFilter.Insert();
            until TaxRegDimFilter.Next(1) = 0;

        TempTaxRegDimCorrFilter."Connection Type" := TempTaxRegDimCorrFilter."Connection Type"::Combinations;
        TaxRegDimComb.SetRange("Section Code", TaxRegLineSetup."Section Code");
        TaxRegDimComb.SetRange("Tax Register No.", TaxRegLineSetup."Tax Register No.");
        TaxRegDimComb.SetRange("Line No.", TaxRegLineSetup."Line No.");
        if TaxRegDimComb.FindSet() then
            repeat
                TempTaxRegDimCorrFilter."Connection Entry No." := TaxRegDimComb."Entry No.";
                TempTaxRegDimCorrFilter.Insert();
            until TaxRegDimComb.Next(1) = 0;
    end;

    local procedure CheckDimValueFilter(var TempTaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter" temporary; TaxRegGLCorrEntryNo: Integer; TaxRegNo: Code[10]; TaxEntrySetupNo: Integer): Integer
    var
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        OldTaxRegDimFilter: Record "Tax Register Dim. Filter";
        NewTaxRegDimFilter: Record "Tax Register Dim. Filter";
        OldExist: Boolean;
        NewExist: Boolean;
    begin
        TaxRegDimCorrFilter.SetRange("Section Code", TempTaxRegDimCorrFilter."Section Code");
        TaxRegDimCorrFilter.SetRange("G/L Corr. Entry No.", TaxRegGLCorrEntryNo);
        TaxRegDimCorrFilter.SetRange("Connection Type", TaxRegDimCorrFilter."Connection Type"::Filters);
        if TaxRegDimCorrFilter.Find('-') then begin
            NewTaxRegDimFilter.SetCurrentKey("Section Code", "Entry No.");
            NewTaxRegDimFilter.SetRange("Section Code", TempTaxRegDimCorrFilter."Section Code");
            NewTaxRegDimFilter.SetRange("Tax Register No.", TaxRegNo);
            NewTaxRegDimFilter.SetRange(Define, NewTaxRegDimFilter.Define::"Entry Setup");
            NewTaxRegDimFilter.SetRange("Line No.", TaxEntrySetupNo);
            NewExist := NewTaxRegDimFilter.Find('-');
            OldTaxRegDimFilter.SetCurrentKey("Section Code", "Entry No.");
            OldTaxRegDimFilter.SetRange("Section Code", TempTaxRegDimCorrFilter."Section Code");
            OldTaxRegDimFilter.SetRange("Entry No.", TaxRegDimCorrFilter."Connection Entry No.");
            OldExist := OldTaxRegDimFilter.FindFirst();
            while OldExist and NewExist do
                if (OldTaxRegDimFilter."Dimension Code" <> NewTaxRegDimFilter."Dimension Code") or
                   (OldTaxRegDimFilter."Dimension Value Filter" <> NewTaxRegDimFilter."Dimension Value Filter")
                then
                    NewExist := not OldExist
                else begin
                    NewExist := NewTaxRegDimFilter.Next(1) <> 0;
                    OldExist := TaxRegDimCorrFilter.Next(1) <> 0;
                    if OldExist then begin
                        OldTaxRegDimFilter.SetRange("Entry No.", TaxRegDimCorrFilter."Connection Entry No.");
                        OldExist := OldTaxRegDimFilter.FindFirst();
                    end;
                end;
            if OldExist <> NewExist then
                exit(-1);
            exit(0);
        end;
        exit(1);
    end;

    local procedure FillAuxTableFromGLCorrEntry(var GLCorrEntry: Record "G/L Correspondence Entry"; SectionCode: Code[10]; TaxRegID: Code[10]; StartDate: Date; EndDate: Date)
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        EntryNo: Integer;
        WhereUsedRegisterID: Code[20];
    begin
        if not TaxRegSetup."Create Data for Printing Forms" then
            exit;

        if TaxRegGLEntry.FindLast() then
            EntryNo := TaxRegGLEntry."Entry No." + 1
        else
            EntryNo := 0;

        if GLCorrEntry.FindSet() then
            repeat
                WhereUsedRegisterID := '~' + TaxRegID + '~';
                if CheckTaxRegGLEntryPresence(WhereUsedRegisterID, GLCorrEntry."Debit Entry No.") then begin
                    TaxRegGLEntry.Init();
                    TaxRegGLEntry."Entry No." := EntryNo;
                    TaxRegGLEntry."Section Code" := SectionCode;
                    TaxRegGLEntry."Starting Date" := StartDate;
                    TaxRegGLEntry."Ending Date" := EndDate;
                    TaxRegGLEntry."Where Used Register IDs" := '~' + TaxRegID + '~';
                    TaxRegGLEntry."Entry Type" := TaxRegGLEntry."Entry Type"::Incoming;
                    TaxRegGLEntry.CopyFromGLCorrEntry(GLCorrEntry);
                    TaxRegGLEntry."Debit Dimension 1 Value Code" := GLCorrEntry."Debit Global Dimension 1 Code";
                    TaxRegGLEntry."Debit Dimension 2 Value Code" := GLCorrEntry."Debit Global Dimension 2 Code";
                    TaxRegGLEntry."Credit Dimension 1 Value Code" := GLCorrEntry."Credit Global Dimension 1 Code";
                    TaxRegGLEntry."Credit Dimension 2 Value Code" := GLCorrEntry."Credit Global Dimension 2 Code";
                    TaxRegGLEntry.Insert();
                    EntryNo += 1;
                end;
            until GLCorrEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FillAuxTabFromGLCorrAnViewEntry(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; SectionCode: Code[10]; TaxRegID: Code[10]; StartDate: Date; EndDate: Date)
    var
        TempGLCorrEntry: Record "G/L Correspondence Entry" temporary;
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        GLCorrAnViewEntrToGLCorrEntr: Codeunit GLCorrAnViewEntrToGLCorrEntr;
        EntryNo: Integer;
        WhereUsedRegisterID: Code[20];
    begin
        if not TaxRegSetup."Create Data for Printing Forms" then
            exit;

        if TaxRegGLEntry.FindLast() then
            EntryNo := TaxRegGLEntry."Entry No." + 1
        else
            EntryNo := 0;

        if GLCorrAnalysisViewEntry.FindSet() then
            repeat
                TempGLCorrEntry.Reset();
                TempGLCorrEntry.DeleteAll();
                GLCorrAnViewEntrToGLCorrEntr.GetGLCorrEntries(GLCorrAnalysisViewEntry, TempGLCorrEntry);
                if TempGLCorrEntry.FindSet() then
                    repeat
                        WhereUsedRegisterID := '~' + TaxRegID + '~';
                        if CheckTaxRegGLEntryPresence(WhereUsedRegisterID, TempGLCorrEntry."Debit Entry No.") then begin
                            TaxRegGLEntry.Init();
                            TaxRegGLEntry."Entry No." := EntryNo;
                            TaxRegGLEntry."Section Code" := SectionCode;
                            TaxRegGLEntry."Starting Date" := StartDate;
                            TaxRegGLEntry."Ending Date" := EndDate;
                            TaxRegGLEntry."Where Used Register IDs" := WhereUsedRegisterID;
                            TaxRegGLEntry."Entry Type" := TaxRegGLEntry."Entry Type"::Incoming;

                            TaxRegGLEntry.CopyFromGLCorrEntry(TempGLCorrEntry);

                            TaxRegGLEntry."Debit Dimension 1 Value Code" := GLCorrAnalysisViewEntry."Debit Dimension 1 Value Code";
                            TaxRegGLEntry."Debit Dimension 2 Value Code" := GLCorrAnalysisViewEntry."Debit Dimension 2 Value Code";
                            TaxRegGLEntry."Debit Dimension 3 Value Code" := GLCorrAnalysisViewEntry."Debit Dimension 3 Value Code";
                            TaxRegGLEntry."Credit Dimension 1 Value Code" := GLCorrAnalysisViewEntry."Credit Dimension 1 Value Code";
                            TaxRegGLEntry."Credit Dimension 2 Value Code" := GLCorrAnalysisViewEntry."Credit Dimension 2 Value Code";
                            TaxRegGLEntry."Credit Dimension 3 Value Code" := GLCorrAnalysisViewEntry."Credit Dimension 3 Value Code";
                            TaxRegGLEntry.Insert();

                            EntryNo += 1;
                        end;
                    until TempGLCorrEntry.Next() = 0;
            until GLCorrAnalysisViewEntry.Next() = 0;
    end;

    local procedure CheckTaxRegGLEntryPresence(TaxRegID: Code[20]; LedgerEntryNo: Integer): Boolean
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
    begin
        TaxRegGLEntry.SetCurrentKey("Where Used Register IDs", "Ledger Entry No.");
        TaxRegGLEntry.SetRange("Where Used Register IDs", TaxRegID);
        TaxRegGLEntry.SetRange("Ledger Entry No.", LedgerEntryNo);
        exit(TaxRegGLEntry.IsEmpty);
    end;
}

