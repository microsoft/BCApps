codeunit 134225 "ERM CreateAndTestGLAccount"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Indentation]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateGLAccount()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
        GLAccountIndent: Codeunit "G/L Account-Indent";
        Assert: Codeunit Assert;
        DeltaAssert: Codeunit "Delta Assert";
        PreviousIndentation: Integer;
        Amount: Decimal;
    begin
        // Test Covers TFS_TS_ID: 111509: Test suite: Create new G/L Account.
        // 1. Create a new GL Account.
        // 2. Indent the newly created GL Account.
        // 3. Create General Journal Line for the newly created GL Account.
        // 4. Post the General Journal Line.
        // 5. Verify the Balance Amount in GL Account using DeltaAssert. Verify the Indentation Value for GL Account.

        // Setup: Create a new GL Account.
        PreviousIndentation := CreateGLAccount(GLAccount);

        // Exercise: Indent the GL Account. Create and Post the General Journal Lines using the newly created GL Account.
        GLAccountIndent.Indent();

        Amount := LibraryRandom.RandInt(100);  // Store Random Amount in a variable and use it in DeltaAssert.
        DeltaAssert.Init();
        DeltaAssert.AddWatch(DATABASE::"G/L Account", GLAccount.GetPosition(), GLAccount.FieldNo(Balance), Amount);

        CreateGnlJnlLines(GenJournalLine, GLAccount."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify the Balance Amount in GL Account using DeltaAssert. Verify the Indentation Value for GL Account.
        DeltaAssert.Assert();

        GLAccount.Get(GLAccount."No.");
        Assert.AreEqual(PreviousIndentation + 1, GLAccount.Indentation, 'Account was not indented correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountIndentOverwriteTotalingValue()
    var
        GLAccount: Array[3] of Record "G/L Account";
        GLAccountType: Enum "G/L Account Type";
        GLAccountIndent: Codeunit "G/L Account-Indent";
    begin
        // [SCENARIO 409314] G/L Account Indentation should overwrite exisiting Totaling value

        // [GIVEN] 3 G/L Accounts GL1, GL2, GL3 with types "Begin-Total", "Posting", "End-Total"
        GLAccount[1].GET(CreateGLAccountNo(GLAccountType::"Begin-Total"));
        GLAccount[2].GET(CreateGLAccountNo(GLAccountType::Posting));
        GLAccount[3].GET(CreateGLAccountNo(GLAccountType::"End-Total"));

        // [WHEN] G/L Account Indentation is invoked
        GLAccountIndent.Indent();
        GLAccount[3].Find();

        // [THEN] GL3 Totaling = 'GL1..GL3'
        Assert.AreEqual(GLAccount[1]."No." + '..' + GLAccount[3]."No.", GLAccount[3].Totaling, '');

        // [GIVEN] GL3 Totaling manually changed to "I"
        GLAccount[3].Totaling := 'I';
        GLAccount[3].Modify();

        // [WHEN] G/L Account Indentation is invoked
        GLAccountIndent.Indent();
        GLAccount[3].Find();

        // [THEN] GL3 Totaling = 'GL1..GL3'
        Assert.AreEqual(GLAccount[1]."No." + '..' + GLAccount[3]."No.", GLAccount[3].Totaling, '');
    end;

    [Normal]
    local procedure CreateGLAccount(var GLAccount2: Record "G/L Account"): Integer
    var
        GLAccount: Record "G/L Account";
        GLAccountNo1: Decimal;
        GLAccountNo2: Decimal;
    begin
        GLAccount.SetFilter(Totaling, '<>''''');
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::"End-Total");  // required for BE
        GLAccount.FindFirst();

        GLAccount2.SetFilter("No.", GLAccount.Totaling);
        GLAccount2.FindFirst();
        Evaluate(GLAccountNo1, GLAccount2."No.");

        GLAccount2.Next();
        Evaluate(GLAccountNo2, GLAccount2."No.");

        // Create a new GL Account. Find the Account No. by dividing sum of Begin-Total Account and next Account by two.
        GLAccount2.Init();
        GLAccount2.Validate("No.", Format((GLAccountNo1 + GLAccountNo2) / 2, 20, 1));
        // Using 20 for Length of No. field, 1 for seperator.
        GLAccount2.Insert(true);
        GLAccount2.Validate(Name, GLAccount2."No.");
        GLAccount2.Validate("Income/Balance", GLAccount."Income/Balance");
        GLAccount2.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount2.Modify(true);
        exit(GLAccount.Indentation);  // Return the indentation value.
    end;

    [Normal]
    local procedure CreateGnlJnlLines(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Create General Journal Lines using newly created GL Account.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;

    local procedure CreateGLAccountNo(GLAccountType: Enum "G/L Account Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccountType;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;
}

