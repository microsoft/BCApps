codeunit 132530 "VAT Rounding Test - Bug 30865"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [VAT Rounding Type] [VAT Difference]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        Initialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if Initialized then
            exit;

        LibraryERM.SetMaxVATDifferenceAllowed(1);
        LibraryERMCountryData.CreateVATData();
        Commit();
        Initialized := true
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRoundingUp()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('>');
        InitJnlLine(GenJnlLine);

        GenJnlLine.Validate(Amount, 25066.79);
        GenJnlLine.TestField("VAT Amount", 4002.27);
        GenJnlLine.TestField("Bal. VAT Amount", -4002.27);
        GenJnlLine.Validate("VAT Amount", 4002.28);
        GenJnlLine.TestField("VAT Difference", 0.01);
        GenJnlLine.Validate("Bal. VAT Amount", -4002.26);
        GenJnlLine.TestField("VAT Difference", 0.01);
        GenJnlLine.Validate("VAT Amount", 4002.27);
        GenJnlLine.TestField("VAT Difference", 0);
        GenJnlLine.Validate("VAT Amount", 4002.28);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRoundingNearest()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('=');
        InitJnlLine(GenJnlLine);

        GenJnlLine.Validate(Amount, 25066.79);
        GenJnlLine.TestField("VAT Amount", 4002.26);
        GenJnlLine.TestField("Bal. VAT Amount", -4002.26);
        GenJnlLine.Validate("VAT Amount", 4002.27);
        GenJnlLine.TestField("VAT Difference", 0.01);
        GenJnlLine.Validate("VAT Amount", 4002.26);
        GenJnlLine.TestField("VAT Difference", 0.0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRoundingDown()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        InitJnlLine(GenJnlLine);

        GenJnlLine.Validate(Amount, 25066.78);
        GenJnlLine.TestField("VAT Amount", 4002.25);
        GenJnlLine.TestField("Bal. VAT Amount", -4002.25);
        GenJnlLine.Validate("VAT Amount", 4002.27);
        GenJnlLine.TestField("VAT Difference", 0.02);
        GenJnlLine.Validate("VAT Amount", 4002.25);
        GenJnlLine.TestField("VAT Difference", 0.0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingUp()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('>');
        InitJnlLine(GenJnlLine);
        GenJnlLine.Validate(Amount, 25066.79);
        GenJnlLine.Validate("VAT Amount", 4002.28);
        GenJnlLine.TestField("VAT Difference", 0.01);
        GenJnlPost.Run(GenJnlLine);
        Commit();

        GLEntry.Find('+');
        GLEntry.TestField(Amount, -4002.27); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, -21064.52); // bal. amount excl. vat
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 4002.28); // vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 21064.51); // amount excl. vat

        VATEntry.Find('+');
        VATEntry.TestField(Amount, -4002.27); // bal. vat amount
        VATEntry.TestField(Base, -21064.52); // bal. base
        VATEntry.TestField("VAT Difference", 0);
        VATEntry.Next(-1);
        VATEntry.TestField(Amount, 4002.28); // vat amount
        VATEntry.TestField(Base, 21064.51); // base
        VATEntry.TestField("VAT Difference", 0.01);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingNearest()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('=');
        InitJnlLine(GenJnlLine);
        GenJnlLine.Validate(Amount, 25066.79);
        GenJnlLine.Validate("VAT Amount", 4002.27);
        GenJnlLine.TestField("VAT Difference", 0.01);
        GenJnlPost.Run(GenJnlLine);
        Commit();

        GLEntry.Find('+');
        GLEntry.TestField(Amount, -4002.26); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, -21064.53); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 4002.27); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 21064.52); // bal. vat amount

        VATEntry.Find('+');
        VATEntry.TestField(Amount, -4002.26); // bal. vat amount
        VATEntry.TestField(Base, -21064.53); // bal. base
        VATEntry.TestField("VAT Difference", 0);
        VATEntry.Next(-1);
        VATEntry.TestField(Amount, 4002.27); // vat amount
        VATEntry.TestField(Base, 21064.52); // base
        VATEntry.TestField("VAT Difference", 0.01);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDown()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post Line";
    begin
        Initialize();

        LibraryERM.SetVATRoundingType('<');
        InitJnlLine(GenJnlLine);
        GenJnlLine.Validate(Amount, 25066.78);
        GenJnlLine.Validate("VAT Amount", 4002.27);
        GenJnlLine.TestField("VAT Difference", 0.02);
        GenJnlPost.Run(GenJnlLine);
        Commit();

        GLEntry.Find('+');
        GLEntry.TestField(Amount, -4002.25); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, -21064.53); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 4002.27); // bal. vat amount
        GLEntry.Next(-1);
        GLEntry.TestField(Amount, 21064.51); // bal. vat amount

        VATEntry.Find('+');
        VATEntry.TestField(Amount, -4002.25); // bal. vat amount
        VATEntry.TestField(Base, -21064.53); // bal. base
        VATEntry.TestField("VAT Difference", 0);
        VATEntry.Next(-1);
        VATEntry.TestField(Amount, 4002.27); // vat amount
        VATEntry.TestField(Base, 21064.51); // base
        VATEntry.TestField("VAT Difference", 0.02);
    end;

    local procedure InitJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        AccountNo: Code[20];
    begin
        AccountNo := CreateGLAccount();
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, 0);  // Pass Zero for Amount.
        GenJournalLine.Validate("Bal. Account No.", AccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Used assignment operator to avoid confirmation message.
        GenJournalTemplate.Get(LibraryERM.SelectGenJnlTemplate());
        GenJournalTemplate."Allow VAT Difference" := true;
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Allow VAT Difference" := true;
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 19);  // Need to take hard coded value to ensure success of test cases.
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;
}

