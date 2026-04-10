#pragma warning disable AA0247
codeunit 17207 "Create Tax Register FE Entry"
{
    TableNo = "Tax Register FE Entry";

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        Total: Integer;
        Procesing: Integer;
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Future Exp. Depreciation Book");

        TaxRegMgt.ValidateAbsenceFEEntriesDate(StartDate, EndDate, SectionCode);

        if not TaxRegFEEntry.FindLast() then
            TaxRegFEEntry."Entry No." := 0;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        Window.Update(4, FADepreciationBook.TableCaption);

        FADepreciationBook.Reset();
        FADepreciationBook.SetRange("Depreciation Book Code", TaxRegisterSetup."Future Exp. Depreciation Book");
        Total := FADepreciationBook.Count;
        Procesing := 0;

        FALedgEntry.SetRange("FA Posting Date", StartDate, EndDate);
        if FADepreciationBook.FindSet() then
            repeat
                Procesing += 1;
                if (Procesing mod 50) = 1 then
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));

                FALedgEntry.SetRange("FA No.", FADepreciationBook."FA No.");
                FALedgEntry.SetRange("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");

                if FALedgEntry.FindFirst() then begin
                    TaxRegFEEntry.Init();
                    TaxRegFEEntry."Section Code" := SectionCode;
                    TaxRegFEEntry."Starting Date" := StartDate;
                    TaxRegFEEntry."Ending Date" := EndDate;
                    TaxRegFEEntry."FE No." := FADepreciationBook."FA No.";
                    TaxRegFEEntry."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
                    TaxRegFEEntry."Entry No." += 1;
                    TaxRegFEEntry.Insert();

                    TaxRegFEEntry.CalcFields(
                      "Acquisition Cost", "Valuation Changes", "Depreciation Amount");
                end;
            until FADepreciationBook.Next() = 0;

        CreateTaxRegAccumulation(StartDate, EndDate, SectionCode);
    end;

    local procedure CreateTaxRegAccumulation(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegFEEntry: Record "Tax Register FE Entry";
        TaxRegFEEntry2: Record "Tax Register FE Entry";
        TempTaxRegTemplate: Record "Tax Register Template" temporary;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        AddValue: Decimal;
    begin
        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register FE Entry");
        if not TaxReg.Find('-') then
            exit;

        TaxRegTemplate.SetRange("Section Code", SectionCode);
        repeat
            TaxRegTemplate.SetRange(Code, TaxReg."No.");
            if TaxRegTemplate.FindSet() then
                repeat
                    TempTaxRegTemplate := TaxRegTemplate;
                    TempTaxRegTemplate.Value := 0;
                    TempTaxRegTemplate.Insert();
                until TaxRegTemplate.Next() = 0;
        until TaxReg.Next() = 0;

        TaxRegFEEntry.SetCurrentKey("Section Code", "Ending Date");
        TaxReg.SetRange("Section Code", SectionCode);
        TaxRegFEEntry.SetRange("Ending Date", EndDate);
        TaxRegFEEntry2.SetRange("Date Filter", StartDate, EndDate);
        if TaxRegFEEntry.FindSet() then
            repeat
                if TempTaxRegTemplate.FindSet() then begin
                    TaxRegFEEntry2 := TaxRegFEEntry;
                    TaxRegFEEntry2.CalcFields(
                      "Acquisition Cost", "Valuation Changes", "Depreciation Amount");
                    repeat
                        case TempTaxRegTemplate."Sum Field No." of
                            TaxRegFEEntry.FieldNo("Acquisition Cost"):
                                AddValue := TaxRegFEEntry2."Acquisition Cost";
                            TaxRegFEEntry.FieldNo("Valuation Changes"):
                                AddValue := TaxRegFEEntry2."Valuation Changes";
                            TaxRegFEEntry.FieldNo("Depreciation Amount"):
                                AddValue := TaxRegFEEntry2."Depreciation Amount";
                            else
                                AddValue := 0;
                        end;
                        if AddValue <> 0 then begin
                            TempTaxRegTemplate.Value += AddValue;
                            TempTaxRegTemplate.Modify();
                        end;
                    until TempTaxRegTemplate.Next() = 0;
                end;
            until TaxRegFEEntry.Next() = 0;

        TaxRegAccumulation.Reset();
        if not TaxRegAccumulation.FindLast() then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Init();
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

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
    end;
}

