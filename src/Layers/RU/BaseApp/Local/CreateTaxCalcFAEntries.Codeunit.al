#pragma warning disable AA0247
codeunit 17307 "Create Tax Calc. FA Entries"
{
    TableNo = "Tax Calc. FA Entry";

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

    [Scope('OnPrem')]
    procedure "Code"(StartDate: Date; EndDate: Date; TaxCalcSectionCode: Code[10])
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TempTaxCalcFAEntry: Record "Tax Calc. FA Entry" temporary;
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        Window: Dialog;
        Total: Integer;
        Procesing: Integer;
        BaseAmountDepreciation: Decimal;
        TaxAmountDepreciation: Decimal;
        Disposed: Boolean;
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Tax Depreciation Book");

        TaxCalcMgt.ValidateAbsenceFAEntriesDate(StartDate, EndDate, TaxCalcSectionCode);

        if not TaxCalcFAEntry.FindLast() then
            TaxCalcFAEntry."Entry No." := 0;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        FixedAsset.SetFilter("FA Type", '%1|%2',
          FixedAsset."FA Type"::"Fixed Assets", FixedAsset."FA Type"::"Intangible Asset");
        DepreciationBook.SetFilter("Posting Book Type", '%1|%2',
          DepreciationBook."Posting Book Type"::Accounting, DepreciationBook."Posting Book Type"::"Tax Accounting");
        Total := FixedAsset.Count * DepreciationBook.Count();
        Procesing := 0;
        if FixedAsset.FindSet() then
            repeat
                Disposed := DepreciationBook.FindSet();
                if Disposed then begin
                    Procesing += 1;
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));
                    TaxAmountDepreciation := 0;
                    BaseAmountDepreciation := 0;
                    TempTaxCalcFAEntry."Entry No." := 0;
                    TempTaxCalcFAEntry.DeleteAll();
                    repeat
                        if FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code) then begin
                            FADepreciationBook.CalcFields("Book Value");
                            Disposed := Disposed and
                              ((FADepreciationBook."Disposal Date" > 0D) and
                               (FADepreciationBook."Disposal Date" <= EndDate) and
                               (FADepreciationBook."Book Value" = 0));
                            FADepreciationBook.SetRange("FA Posting Date Filter", StartDate, EndDate);
                            FADepreciationBook.CalcFields(Depreciation);
                            FADepreciationBook.SetRange("FA Posting Date Filter");
                            TempTaxCalcFAEntry.Init();
                            TempTaxCalcFAEntry."Section Code" := TaxCalcSectionCode;
                            TempTaxCalcFAEntry."Starting Date" := StartDate;
                            TempTaxCalcFAEntry."Ending Date" := EndDate;
                            TempTaxCalcFAEntry."FA No." := FixedAsset."No.";
                            TempTaxCalcFAEntry."Depreciation Group" := FixedAsset."Depreciation Group";
                            TempTaxCalcFAEntry."Belonging to Manufacturing" := FixedAsset."Belonging to Manufacturing";
                            TempTaxCalcFAEntry."FA Type" := FixedAsset."FA Type";
                            if DepreciationBook."Posting Book Type" = DepreciationBook."Posting Book Type"::Accounting then begin
                                TempTaxCalcFAEntry."Depreciation Book Code (Base)" := DepreciationBook.Code;
                                BaseAmountDepreciation += FADepreciationBook.Depreciation;
                            end else begin
                                TempTaxCalcFAEntry."Depreciation Book Code (Tax)" := DepreciationBook.Code;
                                TaxAmountDepreciation += FADepreciationBook.Depreciation;
                            end;
                            TempTaxCalcFAEntry."Entry No." += 1;
                            TempTaxCalcFAEntry.Insert();
                        end;
                    until DepreciationBook.Next() = 0;
                    if Disposed or (BaseAmountDepreciation <> TaxAmountDepreciation) then
                        case TempTaxCalcFAEntry.Count of
                            2:
                                begin
                                    TempTaxCalcFAEntry.Find('-');
                                    TaxCalcFAEntry.TransferFields(TempTaxCalcFAEntry, false);
                                    TaxCalcFAEntry.Disposed := Disposed;
                                    TempTaxCalcFAEntry.Next();
                                    if TaxCalcFAEntry."Depreciation Book Code (Base)" <> '' then
                                        TaxCalcFAEntry."Depreciation Book Code (Tax)" :=
                                          TempTaxCalcFAEntry."Depreciation Book Code (Tax)"
                                    else
                                        TaxCalcFAEntry."Depreciation Book Code (Base)" :=
                                          TempTaxCalcFAEntry."Depreciation Book Code (Base)";
                                    TaxCalcFAEntry."Entry No." += 1;
                                    TaxCalcFAEntry.Insert();
                                end;
                            else begin
                                TempTaxCalcFAEntry.FindSet();
                                repeat
                                    TaxCalcFAEntry.TransferFields(TempTaxCalcFAEntry, false);
                                    TaxCalcFAEntry.Disposed := Disposed;
                                    TaxCalcFAEntry."Entry No." += 1;
                                    TaxCalcFAEntry.Insert();
                                until TempTaxCalcFAEntry.Next() = 0;
                            end;
                        end;
                end;
            until FixedAsset.Next() = 0;

        CreateTaxCalcAccumulationation(StartDate, EndDate, TaxCalcSectionCode);
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcAccumulationation(DateBegin: Date; DateEnd: Date; TaxCalcSectionCode: Code[10])
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcAccumulation2: Record "Tax Calc. Accumulation";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TaxCalcFAEntry0: Record "Tax Calc. FA Entry";
        TempTaxCalcLine: Record "Tax Calc. Line" temporary;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        AddValue: Decimal;
    begin
        TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. FA Entry");
        if not TaxCalcHeader.FindFirst() then
            exit;

        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        repeat
            TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
            if TaxCalcLine.FindSet() then
                repeat
                    TempTaxCalcLine := TaxCalcLine;
                    TempTaxCalcLine.Value := 0;
                    TempTaxCalcLine.Insert();
                until TaxCalcLine.Next() = 0;
        until TaxCalcHeader.Next() = 0;

        TaxCalcFAEntry0.SetRange("Date Filter", DateBegin, DateEnd);

        TaxCalcFAEntry.SetCurrentKey("Section Code", "Ending Date");
        TaxCalcFAEntry.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcFAEntry.SetRange("Ending Date", DateEnd);
        if TaxCalcFAEntry.FindSet() then
            repeat
                TempTaxCalcLine.SetFilter("Depreciation Group", '%1|%2', '', TaxCalcFAEntry."Depreciation Group");
                TempTaxCalcLine.SetFilter("Belonging to Manufacturing", '%1|%2',
                  TempTaxCalcLine."Belonging to Manufacturing"::" ", TaxCalcFAEntry."Belonging to Manufacturing");
                TempTaxCalcLine.SetFilter("FA Type", '%1|%2',
                  TempTaxCalcLine."FA Type"::" ", TaxCalcFAEntry."FA Type" + 1);
                if TempTaxCalcLine.FindSet() then begin
                    TaxCalcFAEntry0 := TaxCalcFAEntry;
                    TaxCalcFAEntry0.CalcFields(
                      "Total Depr. Amount (Base)", "Total Depr. Amount (Tax)",
                      "Depreciation Amount (Base)", "Depreciation Amount (Tax)",
                      "Depr. Group Elimination");
                    repeat
                        AddValue := 0;
                        case TempTaxCalcLine."Sum Field No." of
                            TaxCalcFAEntry.FieldNo("Total Depr. Amount (Base)"):
                                if TaxCalcFAEntry.Disposed then
                                    AddValue := TaxCalcFAEntry0."Total Depr. Amount (Base)";
                            TaxCalcFAEntry.FieldNo("Total Depr. Amount (Tax)"):
                                if TaxCalcFAEntry.Disposed then
                                    AddValue := TaxCalcFAEntry0."Total Depr. Amount (Tax)";
                            TaxCalcFAEntry.FieldNo("Depreciation Amount (Base)"):
                                AddValue := TaxCalcFAEntry0."Depreciation Amount (Base)";
                            TaxCalcFAEntry.FieldNo("Depreciation Amount (Tax)"):
                                AddValue := TaxCalcFAEntry0."Depreciation Amount (Tax)";
                            TaxCalcFAEntry.FieldNo("Depr. Group Elimination"):
                                if TempTaxCalcLine."Tax Diff. Amount (Tax)" then
                                    AddValue := TaxCalcFAEntry0."Depr. Group Elimination";
                        end;
                        if AddValue <> 0 then begin
                            TempTaxCalcLine.Value += AddValue;
                            TempTaxCalcLine.Modify();
                        end;
                    until TempTaxCalcLine.Next() = 0;
                end;
            until TaxCalcFAEntry.Next() = 0;

        TaxCalcAccumulation.Reset();
        if not TaxCalcAccumulation.FindLast() then
            TaxCalcAccumulation."Entry No." := 0;

        TaxCalcAccumulation.Init();
        TaxCalcAccumulation."Section Code" := TaxCalcSectionCode;
        TaxCalcAccumulation."Starting Date" := DateBegin;
        TaxCalcAccumulation."Ending Date" := DateEnd;

        TempTaxCalcLine.Reset();
        if TempTaxCalcLine.FindSet() then
            repeat
                TaxCalcAccumulation."Template Line Code" := TempTaxCalcLine."Line Code";
                TaxCalcAccumulation."Register No." := TempTaxCalcLine.Code;
                TaxCalcAccumulation.Indentation := TempTaxCalcLine.Indentation;
                TaxCalcAccumulation.Bold := TempTaxCalcLine.Bold;
                TaxCalcAccumulation.Description := TempTaxCalcLine.Description;
                TaxCalcAccumulation."Amount Period" := TempTaxCalcLine.Value;
                TaxCalcAccumulation."Template Line No." := TempTaxCalcLine."Line No.";
                TaxCalcAccumulation."Tax Diff. Amount (Base)" := TempTaxCalcLine."Tax Diff. Amount (Base)";
                TaxCalcAccumulation."Tax Diff. Amount (Tax)" := TempTaxCalcLine."Tax Diff. Amount (Tax)";
                TaxCalcAccumulation.Disposed := TempTaxCalcLine.Disposed;
                TaxCalcAccumulation."Amount Date Filter" :=
                  TaxRegTermMgt.CalcIntervalDate(
                    TaxCalcAccumulation."Starting Date",
                    TaxCalcAccumulation."Ending Date",
                    TempTaxCalcLine.Period);
                TaxCalcAccumulation.Amount := TaxCalcAccumulation."Amount Period";
                TaxCalcAccumulation."Entry No." += 1;
                TaxCalcAccumulation.Insert();
                if TempTaxCalcLine.Period <> '' then begin
                    TaxCalcAccumulation2 := TaxCalcAccumulation;
                    TaxCalcAccumulation2.Reset();
                    TaxCalcAccumulation2.SetCurrentKey("Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
                    TaxCalcAccumulation2.SetRange("Section Code", TaxCalcSectionCode);
                    TaxCalcAccumulation2.SetRange("Register No.", TaxCalcAccumulation."Register No.");
                    TaxCalcAccumulation2.SetRange("Template Line No.", TaxCalcAccumulation."Template Line No.");
                    TaxCalcAccumulation2.SetFilter("Starting Date", TaxCalcAccumulation."Amount Date Filter");
                    TaxCalcAccumulation2.SetFilter("Ending Date", TaxCalcAccumulation."Amount Date Filter");
                    TaxCalcAccumulation2.CalcSums("Amount Period");
                    TaxCalcAccumulation.Amount := TaxCalcAccumulation2."Amount Period";
                    TaxCalcAccumulation.Modify();
                end;
            until TempTaxCalcLine.Next() = 0;
    end;
}

