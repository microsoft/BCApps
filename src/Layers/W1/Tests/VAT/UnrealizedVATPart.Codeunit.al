codeunit 132516 "Unrealized VAT Part"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [UT]
        isInitialized := false;
    end;

    var
        TestMethodName: Text[30];
        TestCodeunitID: Integer;
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Failed: Label '%1 Failed';
        LibraryERM: Codeunit "Library - ERM";
        VATBus: Code[20];
        VATProd: Code[20];
        isInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        TestCodeunitID := 132516;
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERMCountryData.CreateVATData();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATBus := VATPostingSetup."VAT Bus. Posting Group";
        VATProd := VATPostingSetup."VAT Prod. Posting Group";
        isInitialized := true;

        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentageFull()
    begin
        Initialize();
        TestMethodName := 'Percentagefull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Percentage);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(50, 50, 50, 0, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentageLow()
    begin
        Initialize();
        TestMethodName := 'PercentageLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Percentage);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(25, 25, 50, 0, 0) <> 0.5 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Percentage2Low()
    begin
        Initialize();
        TestMethodName := 'Percentage2Low';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Percentage);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(15, 40, 50, 0, 0) <> 0.6 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Percentage2Full()
    begin
        Initialize();
        TestMethodName := 'Percentage2Full';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Percentage);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(25, 50, 50, 0, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstLow()
    begin
        Initialize();
        TestMethodName := 'FirstLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(5, 5, 50, -10, 0) <> 0.5 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Firstfull()
    begin
        Initialize();
        TestMethodName := 'FirstFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(10, 10, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure First2PayLow()
    begin
        Initialize();
        TestMethodName := 'First2PayLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(2, 7, 50, -10, 0) <> 0.2 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure First2PayFull()
    begin
        Initialize();
        TestMethodName := 'First2PayFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(5, 10, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure First2PayOver()
    begin
        Initialize();
        TestMethodName := 'First2Payover';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(0, 0);
        if GetUnRealizedVATPart(2, 20, 20, 0, 0) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstReverseChargeLow()
    begin
        Initialize();
        TestMethodName := 'FirstRevergeChargeLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::First);

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(5, 5, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstFullyFull()
    begin
        Initialize();
        TestMethodName := 'FirstFullyFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(10, 10, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Firstfullylow()
    begin
        Initialize();
        TestMethodName := 'FirstFullyLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(5, 5, 50, -10, 0) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstFully2PayLow()
    begin
        Initialize();
        TestMethodName := 'FirstFully2PayLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(5, 7, 50, -10, 0) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstFully2PayFull()
    begin
        Initialize();
        TestMethodName := 'FirstFully2PayFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(5, 10, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirstFullyReverseChargeLow()
    begin
        Initialize();
        TestMethodName := 'FirstFullyReverseChargeLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(5, 5, 50, -10, 0) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastFull()
    begin
        Initialize();
        TestMethodName := 'LastFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(50, 50, 50, 0, -10) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastUnder()
    begin
        Initialize();
        TestMethodName := 'LastUnder';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(40, 40, 50, 0, -10) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastLow()
    begin
        Initialize();
        TestMethodName := 'LastLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(45, 45, 50, 0, -10) <> 0.5 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Last2PayLow()
    begin
        Initialize();
        TestMethodName := 'Last2PayLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(-2, 47, 50, 0, 5) <> 0.4 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Last2PayFull()
    begin
        Initialize();
        TestMethodName := 'Last2PayFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(20, 5);
        if GetUnRealizedVATPart(5, 50, 50, 0, -10) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastReverseChargeLow()
    begin
        Initialize();
        TestMethodName := 'LastReverseChargeLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(45, 45, 50, 0, -10) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastReverseChargeFull()
    begin
        Initialize();
        TestMethodName := 'LastFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::Last);

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(50, 50, 50, 0, -10) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastFullyFull()
    begin
        Initialize();
        TestMethodName := 'LastFullyFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(50, 50, 50, 0, -10) <> 1 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastFullyunder()
    begin
        Initialize();
        TestMethodName := 'LastFullyUnder';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(40, 40, 50, 0, -10) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastfullyLow()
    begin
        Initialize();
        TestMethodName := 'LastFullyLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");

        GenerateVATEntry(40, 10);
        if GetUnRealizedVATPart(45, 45, 50, 0, -10) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastFullyReverseChargeLow()
    begin
        Initialize();
        TestMethodName := 'LastFullyLow';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(45, 45, 50, 0, -10) <> 0 then
            Error(Failed, TestMethodName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastFullyReverseChargeFull()
    begin
        Initialize();
        TestMethodName := 'LastFullyFull';
        SetUnrealizedVATType(VATBus, VATProd, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");

        GenerateVATEntry(40, 10);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        if GetUnRealizedVATPart(50, 50, 50, 0, -10) <> 1 then
            Error(Failed, TestMethodName);
    end;

    local procedure SetUnrealizedVATType(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; UnRealizedVATType: Integer)
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("Unrealized VAT Type", UnRealizedVATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure GenerateVATEntry(UnrealizedBase: Decimal; UnrealizedAmount: Decimal)
    begin
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry.Amount := 0;
        VATEntry.Base := 0;
        VATEntry."VAT Bus. Posting Group" := VATBus;
        VATEntry."VAT Prod. Posting Group" := VATProd;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry."Remaining Unrealized Amount" := UnrealizedBase;
        VATEntry."Remaining Unrealized Base" := UnrealizedAmount;
    end;

    local procedure GetUnRealizedVATPart(SettledAmount: Decimal; Paid: Decimal; Full: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal): Decimal
    begin
        exit(VATEntry.GetUnrealizedVATPart(SettledAmount, Paid, Full, TotalUnrealVATAmountFirst, TotalUnrealVATAmountLast));
    end;
}

