codeunit 144014 "Purchase Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Journal]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalLastNoUsedOnNoSeries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Code[20];
    begin
        // Verify Last Number Used field of Number Series, Post Purchase Journal.

        // Setup: Create Number Series, and Purchase Journal.
        LibraryLowerPermissions.SetJournalsEdit();
        LibraryLowerPermissions.AddO365Setup();
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch);
        LastNoUsed := GenJournalLine."Document No.";

        // Exercise: Post Purchase Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Last No. Used field of Number Series, Updated after posting Purchase Journal.
        NoSeriesLine.SetRange("Series Code", GenJournalBatch."No. Series");
        NoSeriesLine.FindFirst();
        NoSeriesLine.TestField("Last No. Used", LastNoUsed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalWithNextNoOnNoSeries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        // Verify Document Number on Purchase Journal after Posting Purchase Journal.

        // Setup: Create Number Series. Create and Post Purchase Journal.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindGeneralJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name", GenJournalBatch."Bal. Account No.");
        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");

        // Exercise: Create Purchase Journal.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(10, 2));  // Random value for Amount.

        // Verify: Verify Document Number on Purchase Journal with Number Series Next Number.
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    var
        NoSeriesLine: Record "No. Series Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateNoSeries(NoSeriesLine);
        CreateGeneralJournalBatch(GenJournalBatch, NoSeriesLine."Series Code");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(10, 2));  // Random value for Amount.
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateNoSeries(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);  // Use True for Default Numbers, Manual Numbers and False for Order Date.
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, NoSeries.Code + '000', NoSeries.Code + '999');  // Adding 000 for Starting Number and 999 for Ending Number.
        NoSeriesLine."Increment-by No." := LibraryRandom.RandInt(10);
        NoSeriesLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeries: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Purchases);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", NoSeries);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure FindGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10]; BalAccountNo: Code[20])
    begin
        GenJournalBatch.SetRange("Bal. Account No.", BalAccountNo);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, JournalTemplateName);
    end;
}

