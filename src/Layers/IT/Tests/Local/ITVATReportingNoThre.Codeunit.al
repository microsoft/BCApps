codeunit 144018 "IT - VAT Reporting - No Thre."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        NonResidentCrMemosNotReportedErr: Label 'The VAT Entry does not exist. Identification fields and values: Entry No.=';
        ResidentIndividualNonFiscalCodeErr: Label 'You must specify a value for the Fiscal Code field';

    local procedure Initialize()
    begin
        LibraryVATUtils.TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        LibraryVATUtils.CreateVATReportSetup();
        Commit();

        LibraryVATUtils.TearDown(); // Cleanup for the first test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusResIndFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusResIndNonFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGetLn(
                GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, false);  // Individual= TRUE, UsingFiscalCode = FALSE
        Assert.ExpectedError(ResidentIndividualNonFiscalCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusNonResIndFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::"Non-Resident", true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusNonResIndNonFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusResNonIndFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, true); // Individual= FALSE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusResNonIndNonFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusNonResNonIndFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::"Non-Resident", true);  // Individual= FALSE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCusNonResNonIndNonFiscalCodeGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustNonResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGetLn(
                GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE
        Assert.ExpectedError(NonResidentCrMemosNotReportedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustNonResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResRefGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendNonResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGetLn(
                GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE
        Assert.ExpectedError(NonResidentCrMemosNotReportedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendNonResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResRefGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLn(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::"Credit Memo",
              GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATCustNonResInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATCustNonResCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyUnrealizedVATTransactions(
                GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
        Assert.ExpectedError(NonResidentCrMemosNotReportedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATCustResInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATCustResCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATCustResRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false); // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATVendNonResInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATVendNonResCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyUnrealizedVATTransactions(
                GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
        Assert.ExpectedError(NonResidentCrMemosNotReportedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATVendResInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::
              Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATVendResCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATVendResPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyUnrealizedVATTransactions(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    local procedure VerifyGetLn(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UsingFiscalCode: Boolean)
    begin
        Initialize();

        // Setup + Verify
        LibraryVATUtils.VerifyGetLn(AccountType, DocumentType, GenPostingType, IndividualPerson, Resident, false, UsingFiscalCode);  // UseThreshold = FALSE

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    local procedure VerifyUnrealizedVATTransactions(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UsingFiscalCode: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();

        // Setup.

        // TODO> replace with LibraryVATUtils.VerifyGetLn after Roxana extracts it
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), false);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // TODO> Keep this line, when replacing with VATUtils call
        LibraryVATUtils.SetupUnrealizedVAT();

        // Create and Post Gen. Journal Line.
        LibraryVATUtils.CreatePostGenJnlLine(
          GenJournalLine, DocumentType, AccountType, GenPostingType, IndividualPerson, Resident, UsingFiscalCode);

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Line.
        LibraryVATUtils.VerifyVATReportLine(VATReportLine);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;
}

