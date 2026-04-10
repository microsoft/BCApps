codeunit 144527 "ERM Create Tax Calc. FA"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        ObjectIsEmptyErr: Label '%1 is empty.';

    [Test]
    [HandlerFunctions('TaxCalcFAEntriesHandler,TaxFARegister21Handler,TaxFARegister41Handler,TaxFARegister44Handler,TaxFARegister423Handler')]
    [Scope('OnPrem')]
    procedure CalculateTaxFAEntries()
    var
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcCode: Code[10];
    begin
        TaxRegSection.FindFirst();
        LibraryTaxAcc.CreateTaxReg(TaxRegister, TaxRegSection.Code, DATABASE::"Tax Register Accumulation", 0);
        TaxCalcCode := CreateTaxCalculation(TaxRegister);
        TaxCalcFAEntry."Section Code" := TaxRegSection.Code;
        TaxCalcFAEntry."Starting Date" := TaxRegSection."Starting Date";
        TaxCalcFAEntry."Ending Date" := TaxRegSection."Ending Date";
        CODEUNIT.Run(CODEUNIT::"Create Tax Calc. FA Entries", TaxCalcFAEntry);

        // Verify
        TaxCalcAccumulation.SetRange("Register No.", TaxCalcCode);
        Assert.IsFalse(TaxCalcAccumulation.IsEmpty, StrSubstNo(ObjectIsEmptyErr, TaxCalcAccumulation.TableCaption()));
        VerifyTaxCalcFAEntriesPage(TaxRegSection.Code);
        VerifyTaxFARegister21(TaxRegSection.Code);
        VerifyTaxFARegister41(TaxRegSection.Code);
        VerifyTaxFARegister44(TaxRegSection.Code);
        VerifyTaxFARegister423(TaxRegSection.Code);
    end;

    local procedure CreateTaxCalculation(TaxRegister: Record "Tax Register"): Code[10]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
    begin
        LibraryTaxAcc.CreateTaxCalcHeader(TaxCalcHeader, TaxRegister."Section Code", DATABASE::"Tax Calc. FA Entry");
        LibraryTaxAcc.CreateTaxCalcLine(TaxCalcLine, 0, TaxCalcHeader."Section Code", TaxCalcHeader."No.");
        exit(TaxCalcHeader."No.");
    end;

    local procedure VerifyTaxCalcFAEntriesPage(SectionCode: Code[10])
    var
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TaxCalcFAEntriesPage: Page "Tax Calc. FA Entries";
    begin
        TaxCalcFAEntry.SetRange("Section Code", SectionCode);
        TaxCalcFAEntriesPage.SetTableView(TaxCalcFAEntry);
        TaxCalcFAEntriesPage.Run();
        Clear(TaxCalcFAEntriesPage);
    end;

    local procedure VerifyTaxFARegister21(SectionCode: Code[10])
    var
        TaxRegisterFAEntry: Record "Tax Register FA Entry";
        TaxRegister21FA: Page "Tax Register (2.1) FA";
    begin
        TaxRegisterFAEntry.SetRange("Section Code", SectionCode);
        TaxRegister21FA.SetTableView(TaxRegisterFAEntry);
        TaxRegister21FA.Run();
        Clear(TaxRegister21FA);
    end;

    local procedure VerifyTaxFARegister41(SectionCode: Code[10])
    var
        TaxRegisterFAEntry: Record "Tax Register FA Entry";
        TaxRegister41FA: Page "Tax Register (4.1) FA";
    begin
        TaxRegisterFAEntry.SetRange("Section Code", SectionCode);
        TaxRegister41FA.SetTableView(TaxRegisterFAEntry);
        TaxRegister41FA.Run();
        Clear(TaxRegister41FA);
    end;

    local procedure VerifyTaxFARegister44(SectionCode: Code[10])
    var
        TaxRegisterFAEntry: Record "Tax Register FA Entry";
        TaxRegister44FA: Page "Tax Register (4.4) FA";
    begin
        TaxRegisterFAEntry.SetRange("Section Code", SectionCode);
        TaxRegister44FA.SetTableView(TaxRegisterFAEntry);
        TaxRegister44FA.Run();
        Clear(TaxRegister44FA);
    end;

    local procedure VerifyTaxFARegister423(SectionCode: Code[10])
    var
        TaxRegisterFAEntry: Record "Tax Register FA Entry";
        TaxRegister423FA: Page "Tax Register (4.23) FA";
    begin
        TaxRegisterFAEntry.SetRange("Section Code", SectionCode);
        TaxRegister423FA.SetTableView(TaxRegisterFAEntry);
        TaxRegister423FA.Run();
        Clear(TaxRegister423FA);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxCalcFAEntriesHandler(var TaxCalcFAEntries: TestPage "Tax Calc. FA Entries")
    begin
        TaxCalcFAEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxFARegister21Handler(var TaxRegister21FA: TestPage "Tax Register (2.1) FA")
    begin
        TaxRegister21FA.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxFARegister41Handler(var TaxRegister41FA: TestPage "Tax Register (4.1) FA")
    begin
        TaxRegister41FA.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxFARegister44Handler(var TaxRegister44FA: TestPage "Tax Register (4.4) FA")
    begin
        TaxRegister44FA.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxFARegister423Handler(var TaxRegister423FA: TestPage "Tax Register (4.23) FA")
    begin
        TaxRegister423FA.OK().Invoke();
    end;
}

