codeunit 134044 "ERM VAT on Jnl"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Difference]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ErrorValidation: Label 'Error must be same.';
        VATAmountError: Label '%1 must be positive.';
        BalVATAmountError: Label '%1 must be negative.';
        AmountError: Label '%1 must be %2 in %3.';
        FieldValueError: Label 'The %1 must not be more than %2.';
        CanceledErr: Label 'Canceled.';

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtErrorOnGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error Raised when changing sign on VAT Amount field on General Journal Line.

        // Setup.
        Initialize();
        ModifyBatchAndCreateGenJnLine(GenJournalLine);
        GenJournalLine.Validate("VAT %", LibraryRandom.RandDec(10, 1));
        GenJournalLine.Modify(true);

        // Exercise: Validate General Journal Line for Negative Random VAT Amount.
        asserterror GenJournalLine.Validate("VAT Amount", -LibraryRandom.RandDec(10, 2));

        // Verify: Verify VAT Amount Error On Negative Value.
        Assert.AreEqual(StrSubstNo(VATAmountError, GenJournalLine.FieldCaption("VAT Amount")), GetLastErrorText, ErrorValidation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalVATAmtErrorOnGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error Raised when changing sign on Bal. VAT Amount field on General Journal Line.

        // Setup: Validate Bal. VAT Percent with Random Value on General Journal Line.
        Initialize();
        ModifyBatchAndCreateGenJnLine(GenJournalLine);
        GenJournalLine.Validate("Bal. VAT %", LibraryRandom.RandDec(10, 2));
        GenJournalLine.Modify(true);

        // Exercise: Validate Bal. VAT Amount for Positive Random Value.
        asserterror GenJournalLine.Validate("Bal. VAT Amount", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Bal. VAT Amount Error On Positive Value.
        Assert.AreEqual(StrSubstNo(BalVATAmountError, GenJournalLine.FieldCaption("Bal. VAT Amount")), GetLastErrorText, ErrorValidation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyVATSetupYesOnGenJnlLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VATAmount: Decimal;
    begin
        // Check All GL Account fields has been flow on General Journal Line when "Copy VAT Setup to Jnl. Lines" field of
        // General Journal Batch is Set to TRUE.

        // Setup: Crete General Template and Batch with "Copy VAT Setup to Jnl. Lines" field TRUE.
        Initialize();
        CreateGenTemplateAndBatch(GenJournalTemplate, GenJournalBatch, false, true);

        // Exercise: Create General Journal Line with Created General Journal Batch and Modify General Journal Line and
        // Calculate VAT Amount.
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment);
        VATAmount := ModifyGenJournalLine(GenJournalLine, GenJournalBatch.Name);

        // Verify: Verify General Journal Line for Different Set of fields with GL Account has been flow correctly when
        // "Copy VAT Setup to Jnl. Lines" field of General Journal Batch is Set to TRUE.
        GLAccount.Get(GenJournalLine."Account No.");
        GenJournalLine.TestField("Gen. Posting Type", GLAccount."Gen. Posting Type");
        GenJournalLine.TestField("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GenJournalLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenJournalLine.TestField("VAT Amount", VATAmount);

        // Tear Down: Delete Created General Journal Template and Batch.
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyVATSetupYesPostGenJnlLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATAmount: Decimal;
        Amount: Decimal;
    begin
        // Check GL Entry for VAT Amount and Amount fields After posting General Journal Line when
        // "Copy VAT Setup to Jnl. Lines" field of General Journal Batch is TRUE.

        // Setup: Crete General Template and Batch with "Copy VAT Setup to Jnl. Lines" field TRUE and General Journal Line and Calculate
        // VAT Amount and Amount.
        Initialize();
        CreateGenTemplateAndBatch(GenJournalTemplate, GenJournalBatch, false, true);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment);
        VATAmount := ModifyGenJournalLine(GenJournalLine, GenJournalBatch.Name);
        Amount := GenJournalLine.Amount - VATAmount;

        // Exercise: Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry for VAT Amount and Amount fields when General Journal Batch's field "Copy VAT Setup to Jnl. Lines"
        // is Set to TRUE.
        VerifyGLEntry(GenJournalLine."Document No.", VATAmount, Amount);

        // Tear Down: Delete Created General Journal Template and Batch.
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyVATSetupNoOnGenJnlLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATAmount: Decimal;
    begin
        // Check General Journal Line fields value for Blank when "Copy VAT Setup to Jnl. Lines" field of General Journal Batch is FALSE.

        // Setup: Crete General Template and Batch with "Copy VAT Setup to Jnl. Lines" field Set to FALSE.
        Initialize();
        CreateGenTemplateAndBatch(GenJournalTemplate, GenJournalBatch, false, false);

        // Exercise: Create General Journal Line with Created General Journal Batch and Modify General Journal Line and
        // Calculate VAT Amount.
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment);
        VATAmount := ModifyGenJournalLine(GenJournalLine, GenJournalBatch.Name);

        // Verify: Verify General Journal Line for Different Set of fields with Blank value when "Copy VAT Setup to Jnl. Lines"
        // field of General Journal Batch is Set to FALSE.
        GenJournalLine.TestField("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Amount", VATAmount);

        // Tear Down: Delete Created General Journal Template and Batch.
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyVATSetupNoPostGenJnlLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Check GL Entry for VAT Amount and Amount fields After posting General Journal Line when
        // "Copy VAT Setup to Jnl. Lines" field of General Journal Batch is FALSE.

        // Setup: Crete General Template and Batch with "Copy VAT Setup to Jnl. Lines" field FALSE and General Journal Line
        // and Calculate Amount.
        Initialize();
        CreateGenTemplateAndBatch(GenJournalTemplate, GenJournalBatch, false, false);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment);
        ModifyGenJournalLine(GenJournalLine, GenJournalBatch.Name);
        Amount := GenJournalLine.Amount;

        // Exercise: Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry for VAT Amount and Amount field after Posting General Journal Line When
        // "Copy VAT Setup to Jnl. Lines" field of General Journal Batch is Set to FALSE.
        VerifyGLEntry(GenJournalLine."Document No.", 0, Amount);

        // Tear Down: Delete Created General Journal Template and Batch.
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateJournalTemplateYesNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
    begin
        // [FEATURE] [General Journal Template] [Allow VAT Difference]
        // [SCENARIO] Allow VAT Difference = NO in General Journal Batches after setting Allow VAT Difference = NO in General Journal Template.
        Initialize();

        // [GIVEN] Create General Journal Template and two Journal Batches.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch[1], GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch[2], GenJournalTemplate.Name);

        // [GIVEN] Set Allow VAT Difference Field = YES for the General Journal Template.
        GenJournalTemplate.Validate("Allow VAT Difference", true);
        // [WHEN] Set Allow VAT Difference Field = NO for the General Journal Template.
        GenJournalTemplate.Validate("Allow VAT Difference", false);

        // [THEN] "Allow VAT Difference" Field in General Journal Batchs is NO.
        GenJournalBatch[1].Find();
        GenJournalBatch[1].TestField("Allow VAT Difference", false);
        GenJournalBatch[2].Find();
        GenJournalBatch[2].TestField("Allow VAT Difference", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateJournalTemplateYes()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
    begin
        // [FEATURE] [General Journal Template] [Allow VAT Difference]
        // [SCENARIO] Allow VAT Difference = YES in General Journal Batch after setting Allow VAT Difference = YES in General Journal Template.
        Initialize();

        // [GIVEN] Create General Journal Template and two Journal Batches.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch[1], GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch[2], GenJournalTemplate.Name);

        // [WHEN] Set Allow VAT Difference Field = YES for the General Journal Template.
        GenJournalTemplate.Validate("Allow VAT Difference", true);

        // [THEN] "Allow VAT Difference" Field in General Journal Batchs is YES.
        GenJournalBatch[1].Find();
        GenJournalBatch[1].TestField("Allow VAT Difference", true);
        GenJournalBatch[2].Find();
        GenJournalBatch[2].TestField("Allow VAT Difference", true);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeclineUpdateOnJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalTemplates: TestPage "General Journal Templates";
    begin
        // [FEATURE] [General Journal Template] [Allow VAT Difference] [UI]
        // [SCENARIO] Confirmation request should be shown while updating "Allow VAT Difference" on "General Journal Templates" page
        Initialize();

        // [GIVEN] Create General Journal Template and one Journal Batch, where "Allow VAT Difference" is YES.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate("Allow VAT Difference", true);
        GenJournalTemplate.Modify(true);
        Commit(); // due to expected error message

        // [GIVEN] Open page "General Journal Templates"
        GeneralJournalTemplates.OpenEdit();
        GeneralJournalTemplates.FILTER.SetFilter(Name, GenJournalTemplate.Name);
        GeneralJournalTemplates.First();
        // [WHEN] Set "Allow VAT Difference" = YES, but answer NO on the confirmation request
        asserterror GeneralJournalTemplates."Allow VAT Difference".SetValue(false);

        // [THEN] Error message "Cancelled"
        Assert.ExpectedError(CanceledErr);
        // [THEN] "Allow VAT Difference" is YES in General Journal Batch
        GenJournalBatch.Find();
        GenJournalBatch.TestField("Allow VAT Difference", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchWithAllowVATDiffYes()
    begin
        // Check Allow VAT Difference = Yes on General Journal Batch when Allow VAT Difference = Yes on General Journal Template.
        Initialize();
        GenJnlBatchWithAllowVATDiff(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchWithAllowVATDiffNo()
    begin
        // Check Allow VAT Difference = No on General Journal Batch when Allow VAT Difference = No on General Journal Template.
        Initialize();
        GenJnlBatchWithAllowVATDiff(false);
    end;

    local procedure GenJnlBatchWithAllowVATDiff(AllowVATDifference: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Setup: Find a General Journal Template. Update the Template.
        FindGeneralJournalTemplate(GenJournalTemplate);
        AllowVATDifferenceInTemplate(GenJournalTemplate.Name, AllowVATDifference);

        // Exercise: Create a new General Journal Batch for the General Journal Template.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.SetupNewBatch();

        // Verify: Verify that Allow VAT Difference = No in new General Journal Batch.
        GenJournalBatch.TestField("Allow VAT Difference", AllowVATDifference);

        // Tear Down: Roll Back update done in General Journal Template.
        GenJournalBatch.Delete(true);
        AllowVATDifferenceInTemplate(GenJournalTemplate.Name, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnBatchWithAllowVATDiffNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Check Error after updating General Journal Batch, when Allow VAT Difference = No on General Journal Template.

        // Setup: Find a General Journal Template with Allow VAT Difference = No.
        Initialize();
        FindGeneralJournalTemplate(GenJournalTemplate);

        // Exercise: Create a new General Journal Batch with Allow VAT Difference = Yes.
        asserterror CreateGeneralJournalBatch(GenJournalTemplate.Name, true);

        // Verify: Verify the error message.
        Assert.ExpectedTestFieldError(GenJournalTemplate.FieldCaption("Allow VAT Difference"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATDiffAllowedGenJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Error Raised when changing VAT Amount on General Journal Line and Allow VAT Difference = Yes.

        // Setup.
        Initialize();
        ModifyGeneralLedgerSetup(0);
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, true);

        // Exercise: Change VAT Amount on General Journal Line.
        asserterror GenJournalLine.Validate("VAT Amount", LibraryRandom.RandDec(100, 2));

        // Verify: Verify Error Message.
        Assert.AreEqual(
          StrSubstNo(FieldValueError, GenJournalLine.FieldCaption("VAT Difference"),
            Format(0.0, 0, '<Precision,2:2><Standard format,0>')), GetLastErrorText, ErrorValidation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVATWhenAllowVATDiffNo()
    begin
        // Check that Error Raised when changing VAT Amount on General Journal Line and Allow VAT Difference = No.
        Initialize();
        UpdateVATAmtOnGenJournalLine(false);
    end;

    local procedure UpdateVATAmtOnGenJournalLine(AllowVATDifference: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create General Journal Template, Batch and create General Journal Line for the Batch.
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, AllowVATDifference);

        // Exercise: Update Random VAT Amount on General Journal Line.
        asserterror GenJournalLine.Validate("VAT Amount", LibraryRandom.RandDec(100, 2));

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(GenJournalBatch.FieldCaption("Allow VAT Difference"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDiffTooBigOnGenJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATDifference: Decimal;
    begin
        // Check that Error Raised when changing VAT Amount on General Journal Line and Amount is bigger than Allowed VAT Difference.

        // Setup: Update General Ledger Setup. Create General Journal Template, Batch and General Journal Line.
        Initialize();
        VATDifference := LibraryRandom.RandDec(1, 2);  // Take random Amount for VAT Difference.
        ModifyGeneralLedgerSetup(VATDifference);
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, true);

        // Exercise: Change VAT Amount on General Journal Line with a Random Amount.
        asserterror GenJournalLine.Validate("VAT Amount", GenJournalLine."VAT Amount" + LibraryRandom.RandInt(10));

        // Verify: Verify Error Message.
        Assert.AreEqual(
          StrSubstNo(FieldValueError, GenJournalLine.FieldCaption("VAT Difference"), VATDifference), GetLastErrorText, ErrorValidation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeBalVATGenJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATDifference: Decimal;
    begin
        // Check error after updating Bal. Account No. and Balance VAT Amount on General Journal Line with Allow VAT Difference = Yes.

        // Setup: Update General Ledger Setup. Create General Journal Template, Batch and General Journal Line.
        Initialize();
        VATDifference := LibraryRandom.RandDec(1, 2);  // Take random Amount for VAT Difference.
        ModifyGeneralLedgerSetup(VATDifference);
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, true);
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccountWithVAT());
        GenJournalLine.Modify(true);

        // Exercise: Change Bal. VAT Amount for Negative Random Value greater than 100 to generate error message.
        asserterror GenJournalLine.Validate("Bal. VAT Amount", -LibraryRandom.RandDec(10, 2) - 100);

        // Verify: Verify Bal. VAT Difference Error.
        Assert.AreEqual(
          StrSubstNo(FieldValueError, GenJournalLine.FieldCaption("Bal. VAT Difference"), VATDifference),
          GetLastErrorText, ErrorValidation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalVATAmtInGenJournalLine()
    begin
        // Check that Error Raised after updating Bal. VAT Amount on General Journal Line.
        Initialize();
        BalanceVATAmtInGenJournalLine(LibraryRandom.RandDec(1, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegBalVATAmtInGenJournalLine()
    begin
        // Check that Error Raised when changing sign on Bal. VAT Amount field on General Journal Line.
        Initialize();
        BalanceVATAmtInGenJournalLine(-LibraryRandom.RandDec(1, 2));
    end;

    local procedure BalanceVATAmtInGenJournalLine(BalVATAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Journal Template, Batch and General Journal Line.
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, true);

        // Exercise: Update Bal. VAT Amount on General Journal Line.
        asserterror GenJournalLine.Validate("Bal. VAT Amount", BalVATAmount);

        // Verify: Verify Bal. VAT Amount Error.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Bal. VAT %"), '');
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineCopyVATSetupNo()
    begin
        // Verify Copy VAT Setup to Jnl. Lines in General Journal Template and General Journal Batch.

        // Setup: Create General Journal Template and General Journal Batch and set the value of
        // Copy VAT Setup to Jnl. Lines in General Journal Template, but decline confirmation
        Initialize();
        asserterror GenJnlLineCopyVATSetup(true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineCopyVATSetupYes()
    begin
        // Verify Copy VAT Setup to Jnl. Lines in General Journal Template and General Journal Batch.

        // Setup: Create General Journal Template and General Journal Batch and set the value of
        // Copy VAT Setup to Jnl. Lines in General Journal Template.
        Initialize();
        GenJnlLineCopyVATSetup(false);
    end;

    local procedure GenJnlLineCopyVATSetup(CopyVATSetuptoJnlLines: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify Copy VAT Setup to Jnl. Lines in General Journal Template and General Journal Batch.

        // General Journal Template and General Journal Batch.
        CreateGenTemplateAndBatch(GenJournalTemplate, GenJournalBatch, true, true);

        // Exercise: Modify Copy VAT Setup to Jnl. Lines in General Journal Templates page.
        UpdateCopyVATSetupToJnlLines(GenJournalTemplate.Name, false);

        // Verify: Verify Copy VAT Setup to Jnl. Lines in General Journal Batch.
        VerifyGeneralJournalBatch(GenJournalBatch."Journal Template Name", GenJournalBatch.Name, CopyVATSetuptoJnlLines);

        // Tear Down: Delete Created General Journal Template.
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATOnGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATDifference: Decimal;
        VATDifferenceOld: Decimal;
        VATBaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check VAT Base and VAT Difference on General Journal Line after changing VAT Amount. Allow VAT Difference = Yes.
        Initialize();
        VATDifference := LibraryRandom.RandDec(1, 2);
        VATBaseAmount := SetupAndCreatePmtJournalLine(GenJournalLine, VATDifferenceOld, VATAmount, VATDifference);

        // Verify: Verify VAT Base, VAT Difference on General Journal Line.
        Assert.AreEqual(
          VATBaseAmount, GenJournalLine."VAT Base Amount", StrSubstNo(AmountError, GenJournalLine.FieldCaption("VAT Base Amount"),
            VATBaseAmount, GenJournalLine.TableCaption()));
        Assert.AreEqual(
          -VATDifference, GenJournalLine."VAT Difference", StrSubstNo(AmountError, GenJournalLine.FieldCaption("VAT Difference"),
            -VATDifference, GenJournalLine.TableCaption()));

        // Tear Down: Roll back General Ledger Setup. Delete Journal Template.
        ModifyGeneralLedgerSetup(VATDifferenceOld);
        DeleteGenBatchAndTemplate(GenJournalLine."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATOnPostedGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATDifference: Decimal;
        VATDifferenceOld: Decimal;
        VATBaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check GL Entry, VAT Entry after posting General Journal Line and changing VAT Amount. Allow VAT Difference = Yes.
        Initialize();
        VATDifference := LibraryRandom.RandDec(1, 2);
        VATBaseAmount := SetupAndCreatePmtJournalLine(GenJournalLine, VATDifferenceOld, VATAmount, VATDifference);

        // Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry and VAT Entry.
        VerifyGLEntry(GenJournalLine."Document No.", VATAmount, GenJournalLine.Amount - VATAmount);
        VerifyVATEntry(GenJournalLine."Document No.", VATBaseAmount, VATAmount, -VATDifference);

        // Tear Down: Roll back General Ledger Setup and Delete General Journal Template.
        ModifyGeneralLedgerSetup(VATDifferenceOld);
        DeleteGenBatchAndTemplate(GenJournalLine."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaximumVATDifferenceAllowed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATProdPostingGroup: Code[20];
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATDifference: Decimal;
        OldVATDifference: Decimal;
    begin
        // Check Posted Entries after updating Maximum Manual VAT on a General Journal And Post them.

        // Setup: Create Template, G/L Accounts, and two General Journal Lines.
        Initialize();
        VATDifference := LibraryRandom.RandDec(1, 2);  // Take random Amount for VAT Difference.
        OldVATDifference := ModifyGeneralLedgerSetup(VATDifference);
        CreateJournalTemplateBatch(GenJournalBatch);
        AllowVATDifferenceInTemplate(GenJournalBatch."Journal Template Name", true);
        CreateAndUpdateGenJournalLine(GenJournalLine, GenJournalBatch, CreateGLAccountWithVAT(), '', VATDifference);
        VATProdPostingGroup := GenJournalLine."VAT Prod. Posting Group";
        VATAmount := ComputeVATAmount(GenJournalLine.Amount, GenJournalLine."VAT %") + VATDifference;
        CreateAndUpdateGenJournalLine(GenJournalLine, GenJournalBatch, CreateGLAccount(GenJournalLine."Account No."), '', VATDifference);
        VATAmount2 := ComputeVATAmount(GenJournalLine.Amount, GenJournalLine."VAT %") + VATDifference;

        // Exercise: Post General Journal Line after updating VAT Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify VAT Amount with different G/L Accounts.
        VerifyVATAmountInGLEntry(GenJournalLine."Document No.", VATProdPostingGroup, VATAmount);
        VerifyVATAmountInGLEntry(GenJournalLine."Document No.", GenJournalLine."VAT Prod. Posting Group", VATAmount2);

        // Tear Down: Roll back General Ledger Setup. Delete Journal Template.
        ModifyGeneralLedgerSetup(OldVATDifference);
        DeleteGenBatchAndTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalWithPositiveVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Post an entry in FCY with positive Manual VAT.
        Initialize();
        CreateGenJournalWithVAT(GenJournalLine);
        PostAndVerifyGLEntry(GenJournalLine, 1, GenJournalLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalWithNegativeVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Post an entry in FCY with negative Manual VAT.
        Initialize();
        CreateGenJournalWithVAT(GenJournalLine);
        PostAndVerifyGLEntry(GenJournalLine, -1, GenJournalLine."Bal. VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLink()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATEntry: Record "VAT Entry";
    begin
        // Check GL Entry VAT Entry Link for Posted General Journal Entry.

        // Setup.
        Initialize();

        // Exercise: Create and Post Entry for GL Account with Random Amount.
        SelectJournalBatchAndClearJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountWithVAT(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify that correct GL Entry VAT Entry Link exists for posted entry.
        FindGLEntry(GLEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        FindVATEntry(VATEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        GLEntryVATEntryLink.Get(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
    end;

    local procedure AllowVATDifferenceInTemplate(JournalTemplateName: Code[10]; AllowVATDifference: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalTemplate.Validate("Allow VAT Difference", AllowVATDifference);
        GenJournalTemplate.Modify(true);
    end;

    local procedure ComputeVATAmount(Amount: Decimal; VATPct: Decimal): Decimal
    begin
        exit(Round(Amount * VATPct / (100 + VATPct)));
    end;

    local procedure CreateAndUpdateCurrency(var Currency: Record Currency)
    var
        Currency2: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateCurrency(Currency2);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        LibraryERM.CreateRandomExchangeRate(Currency2.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Currency Code", Currency2.Code);
        CurrencyExchangeRate.Modify(true);
        Currency.Validate("Max. VAT Difference Allowed", LibraryRandom.RandDec(1, 2));  // Take random value for VAT Difference.
        Currency.Modify(true);
    end;

    local procedure CreateAndUpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; CurrencyCode: Code[10]; VATDifference: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccountWithVAT());
        GenJournalLine.Validate("VAT Amount", GenJournalLine."VAT Amount" + VATDifference);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBatchAndGenJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AllowVATDifference: Boolean)
    begin
        CreateJournalTemplateBatch(GenJournalBatch);
        AllowVATDifferenceInTemplate(GenJournalBatch."Journal Template Name", AllowVATDifference);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, DocumentType);
    end;

    local procedure CreateGenJournalWithVAT(var GenJournalLine: Record "Gen. Journal Line")
    var
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Setup : Create Currency, Journal Template, and General Journal Line.
        CreateAndUpdateCurrency(Currency);
        CreateJournalTemplateBatch(GenJournalBatch);
        AllowVATDifferenceInTemplate(GenJournalBatch."Journal Template Name", true);
        CreateAndUpdateGenJournalLine(
          GenJournalLine, GenJournalBatch, CreateGLAccountWithVAT(), Currency.Code, Currency."Max. VAT Difference Allowed");
        UpdateBalVATAmountOnGenJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalBatch(JournalTemplateName: Code[10]; AllowVATDifference: Boolean): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Allow VAT Difference", AllowVATDifference);
        GenJournalBatch.Modify(true);
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        // Taking Random value greater than 100 for Amount to avoid negative amount in General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountWithVAT(), 100 + LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenTemplateAndBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; CopyVATSetuptoJnlLinesForTempl: Boolean; CopyVATSetuptoJnlLines: Boolean)
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Copy VAT Setup to Jnl. Lines", CopyVATSetuptoJnlLinesForTempl);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", CopyVATSetuptoJnlLines);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGLAccount(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccountNo);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Next();
        exit(
          CreateAndUpdateGLAccount(
            GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group",
            VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateGLAccountWithVAT(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        exit(
          CreateAndUpdateGLAccount(
            GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateAndUpdateGLAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateJournalTemplateBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure DeleteGenBatchAndTemplate(JournalTemplateName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalTemplate.Delete(true);
    end;

    local procedure FindGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange("Allow VAT Difference", false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindExchRateAmount(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", GenJournalLine."Currency Code");
        CurrencyExchangeRate.FindFirst();
        Amount := LibraryERM.ConvertCurrency(Amount, CurrencyExchangeRate."Relational Currency Code", '', WorkDate());
        Amount := LibraryERM.ConvertCurrency(Amount, GenJournalLine."Currency Code", '', WorkDate());
        exit(Amount);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure ModifyBatchAndCreateGenJnLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Modify General Journal Batch and Create General Journal Line.
        SelectJournalBatchAndClearJournalLines(GenJournalBatch);
        AllowVATDifferenceInTemplate(GenJournalBatch."Journal Template Name", true);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment);
    end;

    local procedure ModifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]): Decimal
    begin
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Bal. Account No.", GenJournalLine."Account No.");
        GenJournalLine.Modify(true);
        exit(ComputeVATAmount(GenJournalLine.Amount, GenJournalLine."VAT %"));
    end;

    local procedure UpdateCopyVATSetupToJnlLines(Name: Code[10]; CopyVATSetuptoJnlLines: Boolean)
    var
        GeneralJournalTemplates: TestPage "General Journal Templates";
    begin
        GeneralJournalTemplates.OpenEdit();
        GeneralJournalTemplates.FILTER.SetFilter(Name, Name);
        GeneralJournalTemplates."Copy VAT Setup to Jnl. Lines".SetValue(CopyVATSetuptoJnlLines);
        GeneralJournalTemplates.OK().Invoke();
    end;

    local procedure ModifyGeneralLedgerSetup(MaxVATDifferenceAllowed: Decimal) MaxVATDiffAllowedOld: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        MaxVATDiffAllowedOld := GeneralLedgerSetup."Max. VAT Difference Allowed";
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostAndVerifyGLEntry(GenJournalLine: Record "Gen. Journal Line"; VATDifferenceAmount: Integer; Amount: Decimal)
    var
        AmountWithoutVAT: Decimal;
        VATAmount: Decimal;
    begin
        AmountWithoutVAT := GenJournalLine.Amount - VATDifferenceAmount * Amount;
        AmountWithoutVAT := FindExchRateAmount(GenJournalLine, AmountWithoutVAT);
        VATAmount := FindExchRateAmount(GenJournalLine, Amount);

        // Exercise: Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify that Amount and VAT Amount are posted correctly in G/L Entry.
        VerifyAmountAndVATInGLEntry(GenJournalLine, AmountWithoutVAT, VATDifferenceAmount * VATAmount);

        // Tear Down: Delete Journal Template.
        DeleteGenBatchAndTemplate(GenJournalLine."Journal Template Name");
    end;

    local procedure SelectJournalBatchAndClearJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetupAndCreatePmtJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var VATDifferenceOld: Decimal; var VATAmount: Decimal; VATDifference: Decimal) VATBaseAmount: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Setup: Update General Ledger Setup, Create Journal Template, Batch and General Journal Line.
        VATDifferenceOld := ModifyGeneralLedgerSetup(VATDifference);
        CreateBatchAndGenJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Payment, true);
        ModifyGenJournalLine(GenJournalLine, GenJournalBatch.Name);
        VATAmount := GenJournalLine."VAT Amount" - VATDifference;
        VATBaseAmount := GenJournalLine."VAT Base Amount" + VATDifference;

        // Exercise: Update VAT Amount on General Journal Line.
        GenJournalLine.Validate("VAT Amount", VATAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateBalVATAmountOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Bal. VAT Amount", -GenJournalLine."VAT Amount");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGeneralJournalBatch(JournalTemplateName: Code[10]; Name: Code[10]; CopyVATSetuptoJnlLines: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(JournalTemplateName, Name);
        GenJournalBatch.TestField("Copy VAT Setup to Jnl. Lines", CopyVATSetuptoJnlLines);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; VATAmount: Decimal; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, GLEntry."Document Type"::Payment, DocumentNo);
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal; VATDifference: Decimal)
    var
        VATEntry: Record "VAT Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindVATEntry(VATEntry, VATEntry."Document Type"::Payment, DocumentNo);
        Assert.AreNearlyEqual(
          Base, VATEntry.Base, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATDifference, VATEntry."VAT Difference", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.FieldCaption("VAT Difference"), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyAmountAndVATInGLEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; VATAmount: Decimal)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        Currency.Get(GenJournalLine."Currency Code");
        Amount := Round(Amount, Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
        VATAmount := Round(VATAmount, Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
        FindGLEntry(GLEntry, GLEntry."Document Type"::" ", GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountInGLEntry(DocumentNo: Code[20]; VATProdPostingGroup: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        GLEntry.FindFirst();
        GLEntry.TestField("VAT Amount", VATAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

