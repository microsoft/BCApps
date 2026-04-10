#pragma warning disable AA0247
codeunit 17205 "Create Tax Register FA Entry"
{
    TableNo = "Tax Register FA Entry";

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
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        FALedgEntry: Record "FA Ledger Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TempTaxRegTemplate: Record "Tax Register Template" temporary;
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
    begin
        TaxRegSetup.Get();
        TaxRegSetup.TestField("Tax Depreciation Book");

        TaxRegMgt.ValidateAbsenceFAEntriesDate(StartDate, EndDate, SectionCode);

        TaxRegAccumulation.Reset();
        if not TaxRegAccumulation.FindLast() then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Init();
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register FA Entry");
        if TaxReg.FindSet() then begin
            repeat
                TaxRegTemplate.SetRange("Section Code", TaxReg."Section Code");
                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                if TaxRegTemplate.FindSet() then
                    repeat
                        TempTaxRegTemplate := TaxRegTemplate;
                        if TaxRegTemplate.Expression <> '' then begin
                            SetFALedgerEntryFilters(FALedgEntry, TaxRegTemplate, StartDate, EndDate, 0);
                            case TaxRegTemplate."Sum Field No." of
                                TaxRegFAEntry.FieldNo("Acquisition Cost"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Valuation Changes"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Depreciation Amount"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Sales Gain/Loss"):
                                    case TaxRegTemplate."Result on Disposal" of
                                        TaxRegTemplate."Result on Disposal"::Gain:
                                            begin
                                                FALedgEntry.CalcSums("Sales Gain Amount");
                                                TempTaxRegTemplate.Value := FALedgEntry."Sales Gain Amount";
                                            end;
                                        TaxRegTemplate."Result on Disposal"::Loss:
                                            begin
                                                FALedgEntry.CalcSums("Sales Loss Amount");
                                                TempTaxRegTemplate.Value := FALedgEntry."Sales Loss Amount";
                                            end;
                                        else begin
                                            FALedgEntry.CalcSums(Amount);
                                            TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                        end;
                                    end;
                                TaxRegFAEntry.FieldNo("Sales Amount"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Depr. Group Elimination"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Depreciation Bonus Amount"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Depr. Bonus Recovery Amount"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := -FALedgEntry.Amount;
                                    end;
                                TaxRegFAEntry.FieldNo("Sold FA Qty"):
                                    TempTaxRegTemplate.Value := FALedgEntry.Count();
                                TaxRegFAEntry.FieldNo("Acquis. Cost for Released FA"):
                                    begin
                                        FALedgEntry.CalcSums(Amount);
                                        TempTaxRegTemplate.Value := FALedgEntry.Amount;
                                    end;
                            end;
                        end;

                        TempTaxRegTemplate.Insert();
                    until TaxRegTemplate.Next() = 0;

                TempTaxRegTemplate.Reset();
                if TempTaxRegTemplate.FindSet() then
                    repeat
                        TaxRegAccumulation."Report Line Code" := TempTaxRegTemplate."Report Line Code";
                        TaxRegAccumulation."Template Line Code" := TempTaxRegTemplate."Line Code";
                        TaxRegAccumulation."Tax Register No." := TempTaxRegTemplate.Code;
                        TaxRegAccumulation.Indentation := TempTaxRegTemplate.Indentation;
                        TaxRegAccumulation.Bold := TempTaxRegTemplate.Bold;
                        TaxRegAccumulation.Description := TempTaxRegTemplate.Description;
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
                            TaxRegAccumulation2.SetCurrentKey("Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxRegAccumulation2.SetRange("Section Code", SectionCode);
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

            FillInTaxRegFALedgerEntry(
              StartDate,
              EndDate,
              SectionCode);
            TempTaxRegTemplate.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFALedgerEntryFilters(var FALedgEntry: Record "FA Ledger Entry"; TaxRegTemplate: Record "Tax Register Template"; StartDate: Date; EndDate: Date; Mode: Option Calculate,Drilldown)
    var
        TaxRegFAEntry: Record "Tax Register FA Entry";
    begin
        if TaxRegTemplate.Expression <> '' then begin
            FALedgEntry.Reset();
            FALedgEntry.SetCurrentKey(
              "Depreciation Book Code", "FA Posting Date", "FA Posting Category", "FA Posting Type",
              "Belonging to Manufacturing", "FA Type", "Depreciation Group", "Depr. Bonus");
            FALedgEntry.SetFilter("Depreciation Book Code", TaxRegTemplate."Depr. Book Filter");
            FALedgEntry.SetRange("FA Posting Date", StartDate, EndDate);
            if TaxRegTemplate."Belonging to Manufacturing" <> TaxRegTemplate."Belonging to Manufacturing"::" " then
                FALedgEntry.SetRange("Belonging to Manufacturing", TaxRegTemplate."Belonging to Manufacturing");
            case TaxRegTemplate."FA Type" of
                TaxRegTemplate."FA Type"::"Fixed Assets":
                    FALedgEntry.SetRange("FA Type", FALedgEntry."FA Type"::"Fixed Assets");
                TaxRegTemplate."FA Type"::"Intangible Assets":
                    FALedgEntry.SetRange("FA Type", FALedgEntry."FA Type"::"Intangible Asset");
            end;
            if TaxRegTemplate."Depreciation Group" <> '' then
                FALedgEntry.SetRange("Depreciation Group", TaxRegTemplate."Depreciation Group");
            FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
            if TaxRegTemplate."Tax Difference Code Filter" <> '' then
                FALedgEntry.SetFilter("Tax Difference Code", TaxRegTemplate."Tax Difference Code Filter");

            case TaxRegTemplate."Sum Field No." of
                TaxRegFAEntry.FieldNo("Acquisition Cost"):
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                TaxRegFAEntry.FieldNo("Valuation Changes"):
                    FALedgEntry.SetRange("FA Posting Type",
                      FALedgEntry."FA Posting Type"::"Write-Down", FALedgEntry."FA Posting Type"::Appreciation);
                TaxRegFAEntry.FieldNo("Depreciation Amount"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
                        FALedgEntry.SetRange("Depr. Bonus", false);
                    end;
                TaxRegFAEntry.FieldNo("Sales Gain/Loss"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Gain/Loss");
                        FALedgEntry.SetRange("Depr. Group Elimination", false);
                        if Mode = Mode::Drilldown then
                            case TaxRegTemplate."Result on Disposal" of
                                TaxRegTemplate."Result on Disposal"::Gain:
                                    begin
                                        FALedgEntry.SetFilter("Sales Gain Amount", '>=%1', 0);
                                        FALedgEntry.SetRange("Sales Loss Amount", 0);
                                    end;
                                TaxRegTemplate."Result on Disposal"::Loss:
                                    FALedgEntry.SetFilter("Sales Loss Amount", '>%1', 0);
                            end;
                    end;
                TaxRegFAEntry.FieldNo("Sales Amount"):
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
                TaxRegFAEntry.FieldNo("Depr. Group Elimination"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Gain/Loss");
                        FALedgEntry.SetRange("Depr. Group Elimination", true);
                    end;
                TaxRegFAEntry.FieldNo("Depreciation Bonus Amount"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
                        FALedgEntry.SetRange("Depr. Bonus", true);
                        if TaxRegTemplate."Depr. Bonus % Filter" <> '' then
                            FALedgEntry.SetFilter("Depr. Bonus %", TaxRegTemplate."Depr. Bonus % Filter");
                    end;
                TaxRegFAEntry.FieldNo("Depr. Bonus Recovery Amount"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
                        FALedgEntry.SetRange("Depr. Bonus", true);
                        FALedgEntry.SetRange("FA Posting Date");
                        FALedgEntry.SetRange("Depr. Bonus Recovery Date", StartDate, EndDate);
                    end;
                TaxRegFAEntry.FieldNo("Sold FA Qty"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Gain/Loss");
                        FALedgEntry.SetRange("Result on Disposal", FALedgEntry."Result on Disposal"::Gain);
                        case TaxRegTemplate."Result on Disposal" of
                            TaxRegTemplate."Result on Disposal"::Gain:
                                begin
                                    FALedgEntry.SetFilter("Sales Gain Amount", '>=%1', 0);
                                    FALedgEntry.SetRange("Sales Loss Amount", 0);
                                end;
                            TaxRegTemplate."Result on Disposal"::Loss:
                                FALedgEntry.SetFilter("Sales Loss Amount", '>%1', 0);
                        end;
                    end;
                TaxRegFAEntry.FieldNo("Acquis. Cost for Released FA"):
                    begin
                        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                        FALedgEntry.SetRange("Reclassification Entry", true);
                        FALedgEntry.SetRange(Quantity, 1);
                    end;
            end;
        end;
    end;

    local procedure FillInTaxRegFALedgerEntry(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        EntryNo: Integer;
    begin
        if not TaxRegSetup."Create Data for Printing Forms" then
            exit;

        if TaxRegFAEntry.FindLast() then
            EntryNo := TaxRegFAEntry."Entry No." + 1
        else
            EntryNo := 0;

        FADepreciationBook.SetRange("Depreciation Book Code", TaxRegSetup."Tax Depreciation Book");
        if FADepreciationBook.FindSet() then
            repeat
                FALedgerEntry.SetRange("FA No.", FADepreciationBook."FA No.");
                FALedgerEntry.SetRange("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
                FALedgerEntry.SetRange("FA Posting Date", StartDate, EndDate);
                if FALedgerEntry.FindFirst() then begin
                    FixedAsset.Get(FALedgerEntry."FA No.");
                    TaxRegFAEntry.Init();
                    TaxRegFAEntry."Section Code" := SectionCode;
                    TaxRegFAEntry."Starting Date" := StartDate;
                    TaxRegFAEntry."Ending Date" := EndDate;
                    TaxRegFAEntry."FA No." := FALedgerEntry."FA No.";
                    TaxRegFAEntry."Depreciation Book Code" := FALedgerEntry."Depreciation Book Code";
                    TaxRegFAEntry."Belonging to Manufacturing" := FixedAsset."Belonging to Manufacturing";
                    TaxRegFAEntry."FA Type" := FixedAsset."FA Type";
                    TaxRegFAEntry."Depreciation Group" := FixedAsset."Depreciation Group";
                    TaxRegFAEntry."Entry No." := EntryNo;
                    TaxRegFAEntry.Insert();
                    EntryNo += 1;
                end;
            until FADepreciationBook.Next() = 0;
    end;
}

