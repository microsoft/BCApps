codeunit 144010 "IT - VAT Reporting - Get Lines"
{
    // // [FEATURE] [VAT Report] [VAT Report Suggest Lines]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        isInitialized: Boolean;
        ErrorUnexpectedValue: Label 'Unexpected value in %1 field of %2 table.';
        ErrorUnexpectedNumberOfLines: Label 'Unexpected number of lines.';
        ConfirmApply: Label 'Do you want to post the application';
        ApplicationSuccessfullyPosted: Label 'The application was successfully posted.';
        ErrorYouCannotRename: Label 'You cannot rename the report because it has been assigned a report number.';
        ErrorThisIsNotAllowed: Label 'This is not allowed because of the setup in the VAT Report Setup window.';
        ErrorEditingIsNotAllowed: Label 'Editing is not allowed because the report is marked as Released.';
        ErrorShouldNotBeEmpty: Label 'Value should not be empty.';
        ErrorYouCannotSpecifyAnOriginalReport: Label 'You cannot specify an original report for a report of type Standard.';
        ErrorYouCannotSpecifyTheSameReport: Label 'You cannot specify the same report as the reference report.';
        ErrorYouMustSpecifyAnOriginalReportNo: Label 'You must specify an original report for a report of type Cancellation';
        GJLResidentIndErr: Label 'The Account Type or Bal. Account Type field must be Customer or Vendor when the Resident field';

    [Test]
    [Scope('OnPrem')]
    procedure VATReportDeleteBeforeRelease()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportDelete(VATReportHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportDeleteAfterRelease()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportDelete(VATReportHeader.Status::Released);
    end;

    local procedure VerifyVATReportDelete(Status: Option)
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        // Delete VAT Report.
        if Status = VATReportHeader.Status::Open then
            VATReportHeader.Delete(true)
        else begin
            // Release VAT Report.
            ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);
            // Delete VAT Report.
            asserterror VATReportHeader.Delete(true);
            Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption(Status), Format(VATReportHeader.Status::Open));
        end;

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportRename()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();

        // Create VAt Report Header.
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          VATReportHeader."VAT Report Type"::Standard, WorkDate(), WorkDate());

        // Rename VAT Report.
        asserterror VATReportHeader.Rename(IncStr(VATReportHeader."No."));
        Assert.ExpectedError(ErrorYouCannotRename);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenReleased()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Released, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenOpen()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Open, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenSubmitted()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Submitted, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenReleasedAllowed()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Released, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenOpenAllowed()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Open, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportReopenSubmittedAllowed()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VerifyVATReportReopen(VATReportHeader.Status::Submitted, true);
    end;

    local procedure VerifyVATReportReopen(Status: Option; AllowModifySubmitted: Boolean)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        if AllowModifySubmitted then begin
            VATReportSetup.Get();
            VATReportSetup.Validate("Modify Submitted Reports", true);
            VATReportSetup.Modify(true);
        end;

        // Reopen and Verify.
        case Status of
            VATReportHeader.Status::Open:
                begin
                    ChangeStatus(VATReportHeader, VATReportHeader.Status::Open); // Reopen VAT Report.
                    VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
                end;
            VATReportHeader.Status::Released:
                begin
                    ChangeStatus(VATReportHeader, VATReportHeader.Status::Released); // Release VAT Report.
                    ChangeStatus(VATReportHeader, VATReportHeader.Status::Open); // Reopen VAT Report.
                    VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
                end;
            VATReportHeader.Status::Submitted:
                begin
                    ChangeStatus(VATReportHeader, VATReportHeader.Status::Released); // Release VAT Report.
                    VATReportHeader.Validate("Tax Auth. Receipt No.", Format(LibraryRandom.RandInt(100)));
                    VATReportHeader.Validate("Tax Auth. Document No.", Format(LibraryRandom.RandInt(100)));
                    ChangeStatus(VATReportHeader, VATReportHeader.Status::Submitted); // Submit VAT Report.
                    if not AllowModifySubmitted then begin
                        asserterror ChangeStatus(VATReportHeader, VATReportHeader.Status::Open); // Reopen VAT Report.
                        Assert.ExpectedError(ErrorThisIsNotAllowed)
                    end else begin
                        ChangeStatus(VATReportHeader, VATReportHeader.Status::Open);
                        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
                    end;
                end;
        end;

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportModifyReleased()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        // Release VAT Report.
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);

        // Modify VAT Report and Verify Error Message.
        asserterror VATReportHeader.Validate("End Date", VATReportHeader."End Date");
        Assert.ExpectedError(ErrorEditingIsNotAllowed);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportLineModifyReleased()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        // Release VAT Report.
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);

        // Modify VAT Report line and verify error
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();
        VATReportLine.Validate("Incl. in Report", false);
        asserterror VATReportLine.Modify(true);
        Assert.ExpectedError(ErrorEditingIsNotAllowed);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [HandlerFunctions('NoSeriesListHandler')]
    [Scope('OnPrem')]
    procedure NoAssistEdit()
    var
        VATReport: TestPage "VAT Report";
    begin
        Initialize();

        // Create VAT Report.
        VATReport.OpenNew();
        VATReport."No.".AssistEdit();
        Assert.AreNotEqual('', VATReport."No.".Value, ErrorShouldNotBeEmpty);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoManual()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        No: Code[20];
    begin
        Initialize();

        // Create VAT Report.
        No := LibraryUtility.GenerateGUID();
        VATReport.OpenNew();
        VATReport."No.".SetValue(No);
        VATReport.OK().Invoke();
        VATReportHeader.Get(No);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [HandlerFunctions('VATReportListHandler')]
    [Scope('OnPrem')]
    procedure OriginalReportNoLookup()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportHeader2: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        // Release VAT Report.
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);

        // Submit VAT Report.
        VATReportHeader.Validate("Tax Auth. Receipt No.", Format(LibraryRandom.RandInt(100)));
        VATReportHeader.Validate("Tax Auth. Document No.", Format(LibraryRandom.RandInt(100)));
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Submitted);
        LibraryVariableStorage.Enqueue(VATReportHeader."No.");

        // Create VAT Report.
        VATReport.OpenNew();
        VATReport."VAT Report Config. Code".Activate();
        VATReport."VAT Report Type".SetValue(VATReportHeader."VAT Report Type"::"Cancellation ");
        VATReport."Original Report No.".Lookup();

        // Verify Original Report No. is filled.
        VATReport."Original Report No.".AssertEquals(VATReportHeader."No.");
        VATReportHeader2.Get(VATReport."No.".Value); // Important to get record before closing page.
        VATReport.OK().Invoke();
        VATReportHeader2.Find(); // Refresh record.
        VATReportHeader2.TestField("Original Report No.", VATReportHeader."No.");

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OriginalReportNoValidateStandard()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportHeader2: Record "VAT Report Header";
    begin
        Initialize();

        // Setup.
        GenerateDummyVATReport(VATReportHeader);

        // Release VAT Report.
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);

        // Submit VAT Report.
        VATReportHeader.Validate("Tax Auth. Receipt No.", Format(LibraryRandom.RandInt(100)));
        VATReportHeader.Validate("Tax Auth. Document No.", Format(LibraryRandom.RandInt(100)));
        ChangeStatus(VATReportHeader, VATReportHeader.Status::Submitted);

        // Create 2-nd VAT Report.
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader2, VATReportHeader2."VAT Report Config. Code"::"VAT Transactions Report",
          VATReportHeader."VAT Report Type"::Standard, WorkDate(), WorkDate());
        asserterror VATReportHeader2.Validate("Original Report No.", VATReportHeader."No.");
        Assert.ExpectedError(ErrorYouCannotSpecifyAnOriginalReport);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OriginalReportNoValidateSame()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();

        // Create VAT Report.
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          VATReportHeader."VAT Report Type"::"Cancellation ", WorkDate(), WorkDate());
        asserterror VATReportHeader.Validate("Original Report No.", VATReportHeader."No.");
        Assert.ExpectedError(ErrorYouCannotSpecifyTheSameReport);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OriginalReportNoEmptyRelease()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();

        // Create Cancellation VAT Report.
        LibraryVATUtils.CreateVATReportHeader(
          VATReportHeader, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          VATReportHeader."VAT Report Type"::"Cancellation ", WorkDate(), WorkDate());

        // Release and verify error message.
        asserterror ChangeStatus(VATReportHeader, VATReportHeader.Status::Released);
        Assert.ExpectedError(ErrorYouMustSpecifyAnOriginalReportNo);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompCustNonResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGetLine(
                GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE

        Assert.ExpectedErrorCannotFind(Database::"VAT Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndCustNonResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResRefGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);  // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndCustResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::Resident, false);  // Individual= FALSE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnCompVendNonResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGetLine(
                GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, false, GenJournalLine.Resident::"Non-Resident", false);  // Individual= FALSE, UsingFiscalCode = FALSE

        Assert.ExpectedErrorCannotFind(Database::"VAT Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
                GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
              GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KnIndVendNonResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::"Non-Resident", false); // Individual= TRUE, UsingFiscalCode = FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
                GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
                GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResRefGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
                GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true);
        // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnIndVendResCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGetLine(
              GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, true, GenJournalLine.Resident::Resident, true); // Individual= TRUE, UsingFiscalCode = TRUE
    end;

    local procedure VerifyGetLine(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UsingFiscalCode: Boolean)
    begin
        Initialize();

        // Setup + Verify
        LibraryVATUtils.VerifyGetLn(AccountType, DocumentType, GenPostingType, IndividualPerson, Resident, true, UsingFiscalCode);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractInvGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractInvGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractCMGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractCMGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractInvGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractInvGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractCMGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::"Credit Memo", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractCMGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::"Credit Memo", false);
    end;

    local procedure VerifyContractGetLn(VATReportLineType: Enum "General Posting Type"; DocumentType: Enum "Gen. Journal Document Type"; UseThreshold: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        OrderAmount: Decimal;
        LineAmount: Decimal;
        ExpectedLineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), UseThreshold);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, false); // Below threshold.

        case VATReportLineType of
            VATReportLine.Type::Sale:
                begin
                    // Create Sales Order Linked to Blanket Order.
                    CreateSalesOrderLinkedBlOrd(
                      SalesHeader, LibraryVATUtils.CreateCustomer(false, SalesHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount,
                      DocumentType);
                    // Post Sales Order.
                    LibrarySales.PostSalesDocument(SalesHeader, true, true);
                end;
            VATReportLine.Type::Purchase:
                begin
                    // Create Purchase Order Linked to Blanket Order.
                    CreatePurchOrderLinkedBlOrd(
                      PurchHeader, LibraryVATUtils.CreateVendor(false, PurchHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount,
                      DocumentType);
                    // Post Purchase Order.
                    LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
                end;
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        if UseThreshold then
            ExpectedLineAmount := 0
        else
            ExpectedLineAmount := LineAmount;

        Assert.AreEqual(
          ExpectedLineAmount, Abs(VATReportLine.Base),
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Base), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractInvBelowThresholdGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractBelowThresholdGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::Order.AsInteger());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractInvBelowThresholdGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractBelowThresholdGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::Order.AsInteger());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractCMBelowThresholdGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        SalesHeader: Record "Sales Header";
    begin
        VerifyContractBelowThresholdGetLn(VATReportLine.Type::Sale, SalesHeader."Document Type"::"Credit Memo".AsInteger());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractCMBelowThresholdGetLn()
    var
        VATReportLine: Record "VAT Report Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        VerifyContractBelowThresholdGetLn(VATReportLine.Type::Purchase, PurchaseHeader."Document Type"::"Credit Memo".AsInteger());
    end;

    local procedure VerifyContractBelowThresholdGetLn(VATReportLineType: Enum "General Posting Type"; DocumentType: Option)
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        OrderAmount: Decimal;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, false); // Below threshold.
        LineAmount := OrderAmount / 2; // Below threshold.

        case VATReportLineType of
            VATReportLine.Type::Sale:
                begin
                    // Create Sales Order Linked to Blanket Order.
                    CreateSalesOrderLinkedBlOrd(
                      SalesHeader, LibraryVATUtils.CreateCustomer(false, SalesHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount,
                      "Sales Document Type".FromInteger(DocumentType));
                    // Post Sales Order.
                    LibrarySales.PostSalesDocument(SalesHeader, true, true);
                end;
            VATReportLine.Type::Purchase:
                begin
                    // Create Purchase Order Linked to Blanket Order.
                    CreatePurchOrderLinkedBlOrd(
                      PurchHeader, LibraryVATUtils.CreateVendor(false, PurchHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount,
                      "Purchase Document Type".FromInteger(DocumentType));
                    // Post Purchase Order.
                    LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
                end;
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        Assert.IsTrue(VATReportLine.IsEmpty, ErrorUnexpectedNumberOfLines); // No lines expected.

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractApplyGetLn()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyContractApplyGetLn(VATReportLine.Type::Sale, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractApplyGetLn()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyContractApplyGetLn(VATReportLine.Type::Purchase, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesContractApplyGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyContractApplyGetLn(VATReportLine.Type::Sale, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchContractApplyGetLnNoThreshold()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyContractApplyGetLn(VATReportLine.Type::Purchase, false);
    end;

    local procedure VerifyContractApplyGetLn(VATReportLineType: Enum "General Posting Type"; UseThreshold: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        OrderAmount: Decimal;
        LineAmount: Decimal;
        ActualLineCount: Integer;
        ExpectedLineCount: Integer;
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), UseThreshold);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, false); // Below threshold.

        case VATReportLineType of
            VATReportLine.Type::Sale:
                // Create Sales Invoice and Credit Memo Linked to Blanket Order. Apply.
                CreateSalesInvCMLinkedBlOrd(
                  SalesHeader, LibraryVATUtils.CreateCustomer(false, SalesHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount);
            VATReportLine.Type::Purchase:
                // Create Purchase Invoice and Credit Memo Linked to Blanket Order. Apply.
                CreatePurchInvCMLinkedBlOrd(
                  PurchHeader, LibraryVATUtils.CreateVendor(false, PurchHeader.Resident::Resident, true, false, false), OrderAmount, LineAmount);
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.

        ActualLineCount := VATReportLine.Count();
        if UseThreshold then
            ExpectedLineCount := 0
        else
            ExpectedLineCount := 2;
        Assert.AreEqual(ExpectedLineCount, ActualLineCount, ErrorUnexpectedNumberOfLines);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::" ", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::"Credit Memo", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBlwGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::" ", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBlwAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::"Credit Memo", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::" ", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::"Credit Memo", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoBlwGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::" ", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoBlwAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::"Credit Memo", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoUnrealizedVATGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::" ", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppCMURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, true, GenJournalLine."Document Type"::"Credit Memo", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppInvURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, true, GenJournalLine."Document Type"::Invoice, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBlwAppCMURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, true, GenJournalLine."Document Type"::"Credit Memo", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBlwAppInvURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, true, GenJournalLine."Document Type"::Invoice, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoBlwAppURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::"Credit Memo", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAppCMURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unrealized VAT = TRUE
        // Applying Entry = Credit Memo
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::"Credit Memo", true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAppInvURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unrealized VAT = TRUE
        // Applying Entry = Invoice
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::Invoice, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAppInvBlwURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unrealized VAT = TRUE
        // Applying Entry = Invoice
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::Invoice, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAllBelowGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::" ", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppAllBelowGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, false, GenJournalLine."Document Type"::"Credit Memo", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAllBelowGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::" ", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAppAllBelowGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, false, GenJournalLine."Document Type"::"Credit Memo", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoAllBelowUnrealizedVATGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Vendor, true, GenJournalLine."Document Type"::" ", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAppInvURVAllBelowGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // TFS 323503 - Invoice and Credit Memo both below the threshold
        VerifyCMGetLn(GenJournalLine."Account Type"::Customer, true, GenJournalLine."Document Type"::Invoice, false, false);
    end;

    local procedure VerifyCMGetLn(AccountType: Enum "Gen. Journal Account Type"; UnrealizedVAT: Boolean; ApplyingEntry: Enum "Gen. Journal Document Type"; InvoiceAboveThreshold: Boolean; CreditMemoAboveThreshold: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
        StartDate: Date;
    begin
        Initialize();

        if (not InvoiceAboveThreshold) and CreditMemoAboveThreshold then
            Assert.Fail('You cannot apply a credit memo to a smaller invoice');

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);
        if UnrealizedVAT then
            LibraryVATUtils.SetupUnrealizedVAT();

        // Calculate Amounts.
        if InvoiceAboveThreshold then
            InvoiceAmount := LibraryVATUtils.GetAmountBiggerThanThreshold(WorkDate(), true)
        else
            InvoiceAmount := LibraryVATUtils.GetAmountLessThanThreshold(WorkDate(), false);

        if CreditMemoAboveThreshold then
            CrMemoAmount := LibraryRandom.RandDecInDecimalRange(LibraryVATUtils.GetThresholdAmount(WorkDate(), true), InvoiceAmount, 1)
        else
            CrMemoAmount := LibraryRandom.RandDecInDecimalRange(0, InvoiceAmount, 1);

        // Create and Post Invoice.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostInvoiceJnlLine(GenJournalLine, AccountType, InvoiceAmount);

        // Create and Post Credit Memo.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostCMJnlLine(GenJournalLine2, AccountType, GenJournalLine."Account No.", CrMemoAmount, '');

        // Apply Entries.
        case ApplyingEntry of
            GenJournalLine."Document Type"::"Credit Memo":
                ApplyLedgerEntries(AccountType, GenJournalLine2."Document Type", GenJournalLine2."Document No.",
                  GenJournalLine."Document Type", GenJournalLine."Document No.", CrMemoAmount);
            GenJournalLine."Document Type"::Invoice:
                ApplyLedgerEntries(AccountType, GenJournalLine."Document Type", GenJournalLine."Document No.",
                  GenJournalLine2."Document Type", GenJournalLine2."Document No.", CrMemoAmount);
        end;

        // Create VAT Report.
        StartDate := GenJournalLine."Posting Date";

        // FIXME: remove this. Invoice is not included into reporting period when Credit Memo refers to Previous Calendar Year.
        // IF RefersToPeriod = GenJournalLine."Refers to Period"::"Previous Calendar Year" THEN
        // StartDate := GenJournalLine2."Posting Date";
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          StartDate, GenJournalLine2."Posting Date");

        // Verify VAT Report Lines.
        VerifyVATReportLineCrMemo(VATReportLine, GenJournalLine, GenJournalLine2, InvoiceAboveThreshold, CreditMemoAboveThreshold);

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayAppPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayAppInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayAppPayUnGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayAppInvUnGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayAppPayGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayAppInvGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayAppPayUnGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayAppInvUnGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayGetLn(GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice, true);
    end;

    local procedure VerifyInvPayGetLn(AccountType: Enum "Gen. Journal Account Type"; ApplyingEntry: Enum "Gen. Journal Document Type"; Unapply: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        Initialize();

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);
        LibraryVATUtils.SetupUnrealizedVAT();

        // Calculate Amounts.
        InvoiceAmount := LibraryVATUtils.CalculateAmount(WorkDate(), true, true); // Invoice Amount is above threshold.
        PaymentAmount := LibraryRandom.RandDecInRange(0, 1, 1) * LibraryVATUtils.GetThresholdAmount(WorkDate(), true); // Payment Amount is below threshold.

        // Create and Post Invoice.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostInvoiceJnlLine(GenJournalLine, AccountType, InvoiceAmount);

        // Create and Post Payment.
        CreatePostPaymentJnlLine(GenJournalLine2, AccountType, GenJournalLine."Account No.", PaymentAmount, '');

        // Apply & Unapply Entries.
        case ApplyingEntry of
            GenJournalLine."Document Type"::Payment:
                begin
                    ApplyLedgerEntries(AccountType, GenJournalLine2."Document Type", GenJournalLine2."Document No.",
                      GenJournalLine."Document Type", GenJournalLine."Document No.", PaymentAmount);
                    if Unapply then
                        UnapplyEntry(AccountType, GenJournalLine2."Document Type", GenJournalLine2."Document No.");
                end;
            GenJournalLine."Document Type"::Invoice:
                begin
                    ApplyLedgerEntries(AccountType, GenJournalLine."Document Type", GenJournalLine."Document No.",
                      GenJournalLine2."Document Type", GenJournalLine2."Document No.", PaymentAmount);
                    if Unapply then
                        UnapplyEntry(AccountType, GenJournalLine."Document Type", GenJournalLine."Document No.");
                end;
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          GenJournalLine."Posting Date", GenJournalLine2."Posting Date");

        // Verify VAT Report Lines.
        Assert.AreEqual(1, VATReportLine.Count, ErrorUnexpectedNumberOfLines); // 1 line for Invoice.
        VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::Invoice, -GenJournalLine.Amount); // Initial Invoice Amount.

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Customer, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayCMGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Vendor, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayCMUnapplyGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Customer, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayCMUnapplyGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Vendor, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayCMURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Customer, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayCMURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Vendor, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPayCMUnapplyURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Customer, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvPayCMUnapplyURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvPayCMGetLn(GenJournalLine."Account Type"::Vendor, true, true);
    end;

    local procedure VerifyInvPayCMGetLn(AccountType: Enum "Gen. Journal Account Type"; Unapply: Boolean; UnrealizedVAT: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CreditMemoAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);
        if UnrealizedVAT then
            LibraryVATUtils.SetupUnrealizedVAT();

        // Calculate Amounts so that all 3 (Invoice, Payment, Credit Memo) are above the threshold.
        PaymentAmount := LibraryVATUtils.CalculateAmount(WorkDate(), true, true);
        InvoiceAmount := 2 * PaymentAmount + 0.5 * LibraryVATUtils.GetThresholdAmount(WorkDate(), true);
        CreditMemoAmount := InvoiceAmount - PaymentAmount;

        // Create and Post Invoice.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostInvoiceJnlLine(GenJournalLine, AccountType, InvoiceAmount);

        // Create and Post Payment.
        CreatePostPaymentJnlLine(GenJournalLine2, AccountType, GenJournalLine."Account No.", PaymentAmount, GenJournalLine."Document No.");
        PaymentDocNo := GenJournalLine2."Document No.";

        // Create and Post Credit Memo.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostCMJnlLine(GenJournalLine2, AccountType, GenJournalLine."Account No.", CreditMemoAmount, GenJournalLine."Document No.");

        if Unapply then begin
            UnapplyEntry(AccountType, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine2."Document No."); // Unapply Credit Memo.
            UnapplyEntry(AccountType, GenJournalLine."Document Type"::Payment, PaymentDocNo); // Unapply Payment.
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          GenJournalLine."Posting Date", GenJournalLine2."Posting Date");

        // Verify VAT Report Lines.
        Assert.AreEqual(2, VATReportLine.Count, ErrorUnexpectedNumberOfLines); // 2 lines - line for Invoice and line for Credit Memo.
        VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::Invoice, -GenJournalLine.Amount); // Initial Invoice Amount.
        VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::"Credit Memo", -GenJournalLine2.Amount); // Initial Credit Memo Amount.

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvCMPartUnapplyGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvCMPartGetLn(GenJournalLine."Account Type"::Customer, true, false, GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvCMPartUnapplyURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvCMPartGetLn(GenJournalLine."Account Type"::Customer, true, true, GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvCMPartUnapplyGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvCMPartGetLn(GenJournalLine."Account Type"::Vendor, true, false, GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvCMPartUnapplyURVGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyInvCMPartGetLn(GenJournalLine."Account Type"::Vendor, true, true, GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure VerifyInvCMPartGetLn(AccountType: Enum "Gen. Journal Account Type"; Unapply: Boolean; UnrealizedVAT: Boolean; ApplyingEntry: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        Initialize();

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);
        if UnrealizedVAT then
            LibraryVATUtils.SetupUnrealizedVAT();

        // Calculate Amounts.
        CrMemoAmount := LibraryVATUtils.GetThresholdAmount(WorkDate(), true) / 2; // Credit Memo Amount is below threshold.
        InvoiceAmount := 2.25 * LibraryVATUtils.GetThresholdAmount(WorkDate(), true); // Invoice Amount is above threshold.

        // Create and Post Invoice.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostInvoiceJnlLine(GenJournalLine, AccountType, InvoiceAmount);

        // Create and Post Credit Memo.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreatePostCMJnlLine(GenJournalLine2, AccountType, GenJournalLine."Account No.", CrMemoAmount, '');

        // Post Partial Application.
        if ApplyingEntry = GenJournalLine."Document Type"::"Credit Memo" then
            ApplyLedgerEntries(AccountType, GenJournalLine."Document Type", GenJournalLine."Document No.",
              GenJournalLine2."Document Type", GenJournalLine2."Document No.", CrMemoAmount / 2)
        else
            ApplyLedgerEntries(AccountType, GenJournalLine2."Document Type", GenJournalLine2."Document No.",
              GenJournalLine."Document Type", GenJournalLine."Document No.", CrMemoAmount / 2);

        if Unapply then
            UnapplyEntry(AccountType, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No."); // Unapply Invoice.

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          GenJournalLine."Posting Date", GenJournalLine2."Posting Date");

        // Verify VAT Report Lines.
        Assert.AreEqual(1, VATReportLine.Count, ErrorUnexpectedNumberOfLines); // 1 line for the Invoice. The Credit Memo is not reported as it is below the threshold.
        VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::Invoice, -GenJournalLine.Amount); // Initial Invoice Amount.

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMMultiAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMMultiAppGetLn(GenJournalLine."Account Type"::Customer, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMMultiAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMMultiAppGetLn(GenJournalLine."Account Type"::Vendor, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMMultiURVAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMMultiAppGetLn(GenJournalLine."Account Type"::Customer, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMMultiURVAppGetLn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCMMultiAppGetLn(GenJournalLine."Account Type"::Vendor, true);
    end;

    local procedure VerifyCMMultiAppGetLn(AccountType: Enum "Gen. Journal Account Type"; UnrealizedVAT: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        LineAmount: Decimal;
        GenPostingType: Enum "General Posting Type";
        EndDate: Date;
    begin
        Initialize();

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);
        if UnrealizedVAT then
            LibraryVATUtils.SetupUnrealizedVAT();

        // Calculate Amounts.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), true, true); // Above threshold.

        // Create and Post Invoice.
        GenPostingType := GetGenPostingType(AccountType);
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        LibraryVATUtils.CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenPostingType, AccountType,
          CreateDefaultAccount(GenPostingType, AccountType), 3 * LineAmount);
        LibraryVATUtils.UpdateReqFldsGenJnlLine(GenJournalLine, true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create and Post Credit Memo.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        CreateApplyCM(GenJournalLine2, GenJournalLine, GenPostingType, LineAmount);

        // Create and Post Credit Memo.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        EndDate := CreateApplyCM(GenJournalLine2, GenJournalLine, GenPostingType, LineAmount);

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          GenJournalLine."Posting Date", EndDate);

        // Verify VAT Report Lines.
        Assert.AreEqual(3, VATReportLine.Count, ErrorUnexpectedNumberOfLines);
        repeat
            if VATReportLine."Document Type" = VATReportLine."Document Type"::Invoice then
                Assert.AreNearlyEqual(3 * LineAmount, Abs(VATReportLine."Amount Incl. VAT"), LibraryERM.GetAmountRoundingPrecision(),
                  StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption("Amount Incl. VAT"), VATReportLine.TableCaption()))
            else
                Assert.AreNearlyEqual(LineAmount, Abs(VATReportLine."Amount Incl. VAT"), LibraryERM.GetAmountRoundingPrecision(),
                  StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption("Amount Incl. VAT"), VATReportLine.TableCaption()));
        until VATReportLine.Next() = 0;

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResCustPayGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResCustInvGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonResCustInvGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResCustRefGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResCustCMGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResVendPayGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResVendInvGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonVendPayGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::"Non-Resident");
        Assert.ExpectedError(GJLResidentIndErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonResVendInvGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::"Non-Resident");
        Assert.ExpectedError(GJLResidentIndErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResVendRefGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResVendCMGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonResVendRefGrouping()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        asserterror VerifyGenJnlGroupingGetLn(GenJournalLine."Document Type"::Refund, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine.Resident::"Non-Resident");
        Assert.ExpectedError(GJLResidentIndErr);
    end;

    local procedure VerifyGenJnlGroupingGetLn(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; Resident: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        AccountNo: Code[20];
        LineAmount: Decimal;
        AmountInclVAT: Decimal;
        UseIndividual: Boolean;
    begin
        Initialize();

        // Setup.
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), true, true); // Above threshold.

        // Create Gen. Journal Line.
        WorkDate(LibraryVATUtils.GetPostingDate()); // Changing to new WORKDATE to have a single entry posted for specific date.
        AccountNo := LibraryVATUtils.CreateGLAccount(GenPostingType);
        LibraryVATUtils.CreateGenJnlLine(
          GenJournalLine, DocumentType, GenPostingType, GenJournalLine."Account Type"::"G/L Account", AccountNo, LineAmount);

        // Update Individual Person, Resident.
        UseIndividual := (GenPostingType <> GenJournalLine."Gen. Posting Type"::Purchase);
        UpdateIndResGenJnlLine(GenJournalLine, UseIndividual, Resident, LibraryVATUtils.GetCountryCode());

        // Enter VAT Registration No.
        LibraryVATUtils.UpdateReqFldsGenJnlLine(GenJournalLine, true);

        // Create 2-nd Gen. Journal Line with same Document No.
        CopyGenJournal(GenJournalLine);

        // Create 3-rd Gen. Journal Line with same Document No.
        CopyGenJournal(GenJournalLine);
        GenJournalLine.Validate(Amount, GenJournalLine.Amount / 2); // Below Threshold.
        GenJournalLine.Modify(true);

        // Post General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Turn off [Include] flag from the VAT Entry where Line Amount is below Threshold. This is required to verify grouping.
        UpdateVATEntry(GenJournalLine."Document No.", Abs(GenJournalLine.Amount), true);

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report",
          GenJournalLine."Posting Date", GenJournalLine."Posting Date");

        // Verify VAT Report Lines.
        AmountInclVAT := Round(2 * LineAmount);
        Assert.AreEqual(
          AmountInclVAT, Abs(VATReportLine."Amount Incl. VAT"),
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption("Amount Incl. VAT"), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCustResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Sale, false, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCustNonResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Sale, false, VATEntry.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndCustResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Sale, true, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndCustNonResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Sale, true, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompVenResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Purchase, false, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompVenNonResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Purchase, false, VATEntry.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndVenResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Purchase, true, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndVenNonResGrouping()
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VerifyDocGroupingGetLn(VATReportLine.Type::Purchase, true, VATEntry.Resident::Resident);
    end;

    local procedure VerifyDocGroupingGetLn(VATReportLineType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        LineAmount: Decimal;
        OrderAmount: Decimal;
        AccountNo: Code[20];
        DocumentNo: Code[20];
        VATEntry: Record "VAT Entry";
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amount.
        OrderAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, false); // Below threshold.

        case VATReportLineType of
            VATReportLine.Type::Sale:
                begin
                    if IndividualPerson and (Resident = VATEntry.Resident::Resident) then
                        AccountNo := LibraryVATUtils.CreateCustomer(IndividualPerson, Resident, true, false, true) // Resident and Individual must use fiscal code.
                    else
                        AccountNo := LibraryVATUtils.CreateCustomer(IndividualPerson, Resident, true, false, false);
                    // Create Sales Order with multiple lines.
                    CreateSalesOrderLinkedBlOrd(SalesHeader, AccountNo, OrderAmount, LineAmount, SalesHeader."Document Type"::Order); // With Contract No.
                    CreateSalesLine(SalesHeader, SalesLine, OrderAmount); // Above threshold.
                    CreateSalesLine(SalesHeader, SalesLine, OrderAmount); // Above threshold.
                    CreateSalesLine(SalesHeader, SalesLine, LineAmount); // Below threshold.
                                                                         // Post Sales Order.
                    DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
                end;
            VATReportLine.Type::Purchase:
                begin
                    AccountNo := LibraryVATUtils.CreateVendor(false, Resident, true, false, false);
                    // Create Purchase Order with multiple lines.
                    CreatePurchOrderLinkedBlOrd(PurchHeader, AccountNo, OrderAmount, LineAmount, PurchHeader."Document Type"::Order);
                    CreatePurchLine(PurchHeader, PurchLine, OrderAmount); // Above threshold.
                    CreatePurchLine(PurchHeader, PurchLine, OrderAmount); // Above threshold.
                    CreatePurchLine(PurchHeader, PurchLine, LineAmount); // Below threshold.
                    DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
                end;
        end;

        // Turn off [Include] flag from the VAT Entry where Line Amount is below Threshold. This is required to verify grouping.
        UpdateVATEntry(DocumentNo, Abs(LineAmount), false);

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        repeat
            Assert.AreEqual(
              2 * OrderAmount, Abs(VATReportLine.Base),
              StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Base), VATReportLine.TableCaption()))
        until VATReportLine.Next() = 0;

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompCustResCMGrouping()
    var
        VATEntry: Record "VAT Entry";
    begin
        VerifyCMGroupingGetLn(VATEntry.Type::Sale, false, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndCustResCMGrouping()
    var
        VATEntry: Record "VAT Entry";
    begin
        VerifyCMGroupingGetLn(VATEntry.Type::Sale, true, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompVenResCMGrouping()
    var
        VATEntry: Record "VAT Entry";
    begin
        VerifyCMGroupingGetLn(VATEntry.Type::Purchase, false, VATEntry.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndVenResCMGrouping()
    var
        VATEntry: Record "VAT Entry";
    begin
        VerifyCMGroupingGetLn(VATEntry.Type::Purchase, true, VATEntry.Resident::Resident);
    end;

    local procedure VerifyCMGroupingGetLn(VATReportLineType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        LineAmount: Decimal;
        VATEntry: Record "VAT Entry";
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amount.
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.

        // Create Credit Memo with multiple lines.
        case VATReportLineType of
            VATReportLine.Type::Sale:
                begin
                    // Create Sales Header.
                    if IndividualPerson and (Resident = VATEntry.Resident::Resident) then    // Resident and Individual must use fiscal code.
                        LibrarySales.CreateSalesHeader(
                          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
                          LibraryVATUtils.CreateCustomer(IndividualPerson, Resident, true, false, true))
                    else
                        LibrarySales.CreateSalesHeader(
                          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
                          LibraryVATUtils.CreateCustomer(IndividualPerson, Resident, true, false, false));

                    // Update Refers To Period.
                    SalesHeader.Validate("Refers to Period", SalesHeader."Refers to Period"::"Current Calendar Year");
                    SalesHeader.Modify(true);

                    // Create Sales Line.
                    CreateSalesLine(SalesHeader, SalesLine, LineAmount);
                    CreateSalesLine(SalesHeader, SalesLine, LineAmount / 2);
                    LibrarySales.PostSalesDocument(SalesHeader, true, true);
                end;
            VATReportLine.Type::Purchase:
                begin
                    CreatePurchHeader(
                      PurchHeader, PurchHeader."Document Type"::"Credit Memo",
                      LibraryVATUtils.CreateVendor(
                        IndividualPerson, Resident, true, false, (IndividualPerson and (Resident = VATEntry.Resident::Resident))));
                    // Update Refers To Period.
                    PurchHeader.Validate("Refers to Period", SalesHeader."Refers to Period"::"Current Calendar Year");
                    PurchHeader.Modify(true);

                    // Create Purchase Line.
                    CreatePurchLine(PurchHeader, PurchLine, LineAmount);
                    CreatePurchLine(PurchHeader, PurchLine, LineAmount / 2);
                    UpdateCheckTotal(PurchHeader, 1.5 * LineAmount);
                    LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
                end;
        end;

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        Assert.AreEqual(
          Round(1.5 * LineAmount), Abs(VATReportLine.Base),
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Base), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvLineDiscount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        CustNo := LibraryVATUtils.CreateCustomer(false, GenJnlLine.Resident::Resident, true, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);
        CreateSalesLine(SalesHeader, SalesLine, LineAmount / 2);
        SalesLine.Validate("Line Discount %", 15);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        Assert.AreNearlyEqual(
          Round(0.5 * LineAmount * 0.85 + LineAmount), Abs(VATReportLine."Amount Incl. VAT"), 1,
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Base), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvLineDiscount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendorNo: Code[20];
        LineAmount: Decimal;
        DiscountPct: Decimal;
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        DiscountPct := 15;
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        VendorNo := LibraryVATUtils.CreateVendor(false, GenJnlLine.Resident::Resident, true, true, true);
        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);
        CreatePurchLine(PurchHeader, PurchLine, LineAmount / 2);
        PurchLine.Validate("Line Discount %", DiscountPct);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Exercise
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        Assert.AreNearlyEqual(
          Round((LineAmount / 2 * (100 - DiscountPct) / 100) + LineAmount), Abs(VATReportLine."Amount Incl. VAT"), 1,
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Base), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffVATPosGroup()
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustNo: Code[20];
        LineAmount: Decimal;
        VATProdPostingGroup: array[2] of Code[20];
    begin
        Initialize();

        // Setup.
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Ensure that all VAT posting groups are included
        VATPostingSetup.SetFilter("VAT %", '<>0');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", true);
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.FindFirst();
        VATProdPostingGroup[1] := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup[1]);
        VATPostingSetup.FindFirst();
        VATProdPostingGroup[2] := VATPostingSetup."VAT Prod. Posting Group";

        // Create a sales invoice with two lines, each with different VAT posting group
        LineAmount := LibraryVATUtils.CalculateAmount(WorkDate(), false, true); // Above threshold.
        CustNo := LibraryVATUtils.CreateCustomer(false, GenJnlLine.Resident::Resident, true, false, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup[1]);
        SalesLine.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup[2]);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Lines.
        Assert.AreEqual(
          Round(LineAmount * 0.3), Abs(VATReportLine.Amount),
          StrSubstNo(ErrorUnexpectedValue, VATReportLine.FieldCaption(Amount), VATReportLine.TableCaption()));

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithoutVATRegIncInVATReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Sales] [VAT Report Suggest Lines]
        // [SCENARIO 376088] Sales Credit Memo posted without VAT Registration No. and Fiscal Code should be included into VAT Report

        Initialize();
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // [GIVEN] Sales Credit Memo with blank "Fiscal Code" and "VAT Registration No", "Incl. in VAT Report" = TRUE and VAT Amount = 18
        CreatePostGenJnlLineWithoutFiscCodeAndVATRegNo(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Gen. Posting Type"::Sale);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // [THEN] VAT Report Line generated for Credit Memo and Amount = 18
        VerifyVATReportLine(
          VATReportHeader."No.", GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithoutVATRegIncInVATReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [VAT Report Suggest Lines]
        // [SCENARIO 376088] Purchase Credit Memo posted without VAT Registration No. and Fiscal Code should be included into VAT Report

        Initialize();
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // [GIVEN] Purchase Credit Memo with blank "Fiscal Code" and "VAT Registration No", "Incl. in VAT Report" = TRUE and VAT Amount = 18
        CreatePostGenJnlLineWithoutFiscCodeAndVATRegNo(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Gen. Posting Type"::Purchase);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // [THEN] VAT Report Line generated for Credit Memo and Amount = 18
        VerifyVATReportLine(
          VATReportHeader."No.", GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. VAT Amount");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DocNoInVATReportLineCorrespondsToVendorInvoiceNoInPurchInvoice_Datifattura()
    var
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 227272] "Vendor Invoice No." in Purchase Invoice must be used as "Document No." in VAT Report Line
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Vendor Invoice No." = "TEST001"
        CreatePostPurchaseDocumentInNextPeriod(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] "Document No." in VAT Report Line = "TEST001"
        VATReportLine.TestField("Document No.", PurchaseHeader."Vendor Invoice No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DocNoInVATReportLineCorrespondsToVendorCrMemoNoInPurchCrMemo_Datifattura()
    var
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 227272] "Vendor Cr. Memo No." in Purchase Credit Memo must be used as "Document No." in VAT Report Line
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with "Vendor Cr. Memo No." = "TEST001"
        CreatePostPurchaseDocumentInNextPeriod(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] "Document No." in VAT Report Line = "TEST001"
        VATReportLine.TestField("Document No.", PurchaseHeader."Vendor Cr. Memo No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcludeReverseChangeSalesVATEntryFromVATReportAfterPostingPurchInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 227270] Reverse charge Sales VAT Entry created after posting Puschase Invoice must be excluded from the VAT Report
        Initialize();

        // [GIVEN] "VAT Posting Setup" with "VAT Calculation Type" = "Reverse Charge VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Posted Purchase Invoice with "VAT Calculateion Type" = "Reverse Charge VAT" for Vendor "A"
        CreatePostPurchaseDocumentInNextPeriodWithVATSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] Two VAT Entries for for vendor "A"
        // [THEN] The first "VAT Entry" With Type = Purchase
        // [THEN] The second "VAT Entry" With Type = Sale
        // [THEN] VAT report consists of one line with "Document Type" = Invoice, Type = Purchase
        VerifyVATEntryAndVATReportLineForScenarioWithExcludingReverseChangeSalesVATEntry(
          PurchaseHeader, VATReportLine."Document Type"::Invoice, VATReportHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcludeReverseChangeSalesVATEntryFromVATReportAfterPostingPurchCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Reverse Charge VAT]
        // [SCENARIO 227270] Reverse charge Sales VAT Entry created after posting Puschase Credit Memo must be excluded from the VAT Report
        Initialize();

        // [GIVEN] "VAT Posting Setup" with "VAT Calculation Type" = "Reverse Charge VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Posted Purchase Credit Memo with "VAT Calculateion Type" = "Reverse Charge VAT" for Vendor "A"
        CreatePostPurchaseDocumentInNextPeriodWithVATSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] Two VAT Entries for for vendor "A"
        // [THEN] The first "VAT Entry" With Type = Purchase
        // [THEN] The second "VAT Entry" With Type = Sale
        // [THEN] VAT report consists of one line with "Document Type" = "Credit Memo", Type = Purchase
        VerifyVATEntryAndVATReportLineForScenarioWithExcludingReverseChangeSalesVATEntry(
          PurchaseHeader, VATReportLine."Document Type"::"Credit Memo", VATReportHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithNonDeductibleAmount_Datifattura()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT]
        // [SCENARIO 227263] Non-deductible VAT Amount in Purchase Invoice must be included in amounts in VAT Report Line when "Deductible %" = 50
        Initialize();

        // [GIVEN] "VAT Posting Setup" with "Deductible %" = 50, "VAT %" = 20
        CreateVATPostingSetupWithAccountsAndDeductible(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandInt(50), LibraryRandom.RandInt(50));

        // [GIVEN] Posted Purchase Invoice with Amount = 2000, "Amount Including VAT" = 2400, "VAT Posting Setup" having "Deductible %" = 50
        CreatePostPurchaseDocumentInNextPeriodWithVATSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] VAT report consists of one line having Base = 2000, Amount = 400
        VerifyVATReportLineAmounts(PurchaseHeader, VATReportHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithoutDeductibleAmount_Datifattura()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT]
        // [SCENARIO 227263] Non-deductible VAT Amount in Purchase Invoice must be included in amounts in VAT Report Line when "Deductible %" = 0
        Initialize();

        // [GIVEN] "VAT Posting Setup" with "Deductible %" = 0, "VAT %" = 20
        CreateVATPostingSetupWithAccountsAndDeductible(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandInt(50), 0);

        // [GIVEN] Posted Purchase Invoice with Amount = 2000, "Amount Including VAT" = 2400, "VAT Posting Setup" having "Deductible %" = 0
        CreatePostPurchaseDocumentInNextPeriodWithVATSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura,
          PurchaseHeader."Posting Date", PurchaseHeader."Posting Date");

        // [THEN] VAT report consists of one line having Base = 2000, Amount = 400
        VerifyVATReportLineAmounts(PurchaseHeader, VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocumentTypeCopiesToVATReportLineForSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 394014] "Fattura Document Type" specified in sales document copies to Dattifatura VAT report line

        Initialize();
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), false);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // [GIVEN] Posted sales invoice with "Fattura Document Type" = "TD26"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Fattura Document Type", LibraryITLocalization.GetRandomFatturaDocType(''));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Create VAT Report
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, WorkDate(), WorkDate());

        // [THEN] VAT Report Line has "Fattura Document Type" = "TD26"
        VATReportLine.TestField("Fattura Document Type", SalesHeader."Fattura Document Type");

        // Tear Down.
        LibraryVATUtils.TearDown();
    end;

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

    local procedure AdjustAmountToApplyCLE(CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal): Decimal
    var
        Sign: Integer;
    begin
        CustLedgerEntry.CalcFields("Remaining Amount");
        Sign := CustLedgerEntry."Remaining Amount" / Abs(CustLedgerEntry."Remaining Amount");
        exit(Abs(AmountToApply) * Sign);
    end;

    local procedure AdjustAmountToApplyVLE(VendLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal): Decimal
    var
        Sign: Integer;
    begin
        VendLedgerEntry.CalcFields("Remaining Amount");
        Sign := VendLedgerEntry."Remaining Amount" / Abs(VendLedgerEntry."Remaining Amount");
        exit(Abs(AmountToApply) * Sign);
    end;

    local procedure ApplyLedgerEntries(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo2: Code[20]; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Enqueue(ConfirmApply);
        LibraryVariableStorage.Enqueue(ApplicationSuccessfullyPosted);

        case AccountType of
            GenJournalLine."Account Type"::Customer:
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
                    LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AdjustAmountToApplyCLE(CustLedgerEntry, AmountToApply));
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
                    CustLedgerEntry2.Validate("Amount to Apply", AdjustAmountToApplyCLE(CustLedgerEntry2, AmountToApply));
                    CustLedgerEntry2.Modify(true);
                    LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
                    LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
                    LibraryERM.SetApplyVendorEntry(VendLedgerEntry, AdjustAmountToApplyVLE(VendLedgerEntry, AmountToApply));
                    LibraryERM.FindVendorLedgerEntry(VendLedgerEntry2, DocumentType2, DocumentNo2);
                    VendLedgerEntry2.Validate("Amount to Apply", AdjustAmountToApplyVLE(VendLedgerEntry2, AmountToApply));
                    VendLedgerEntry2.Modify(true);
                    LibraryERM.SetAppliestoIdVendor(VendLedgerEntry2);
                    LibraryERM.PostVendLedgerApplication(VendLedgerEntry);
                end;
        end;
    end;

    local procedure ChangeStatus(var VATReportHeader: Record "VAT Report Header"; Status: Option)
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        case Status of
            VATReportHeader.Status::Open:
                VATReportMediator.Reopen(VATReportHeader);
            VATReportHeader.Status::Released:
                VATReportMediator.Release(VATReportHeader);
            VATReportHeader.Status::Submitted:
                VATReportMediator.Submit(VATReportHeader);
        end;
        VATReportHeader.Find(); // Refresh record.
    end;

    local procedure CopyGenJournal(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Copy(GenJournalLine);
        GenJournalLine."Line No." += 10000;
        GenJournalLine.Insert(true);
    end;

    local procedure CreateDefaultAccount(GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type") AccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AccountNo := LibraryVATUtils.CreateAccount(GenPostingType, AccountType, false, GenJournalLine.Resident::Resident, false, false); // This is Default Option.
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        // Create Purch. Header.
        CreatePurchHeader(PurchHeader, DocumentType, VendorNo);

        // Create Purch. Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount);

        // Fill Total.
        UpdateCheckTotal(PurchHeader, LineAmount);
    end;

    local procedure CreatePurchDocumentWithVATSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; LineAmount: Decimal)
    begin
        CreatePurchHeader(
          PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LineAmount / PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        UpdateCheckTotal(PurchaseHeader, LineAmount);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        // Create Purch. Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        if (DocumentType = PurchHeader."Document Type"::"Credit Memo") or
           (DocumentType = PurchHeader."Document Type"::"Return Order")
        then begin
            PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
            PurchHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Purch. Line.
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "),
          LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LineAmount / PurchLine.Quantity);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchLineLinkedBlOrd(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PurchLine2: Record "Purchase Line"; LineAmount: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", PurchLine2."No.", PurchLine2.Quantity / 2);  // At least 2 documents can be linked to a Blanket Order.
        PurchLine.Validate("Blanket Order No.", PurchLine2."Document No.");
        PurchLine.Validate("Blanket Order Line No.", PurchLine2."Line No.");
        PurchLine.Validate("Direct Unit Cost", LineAmount / PurchLine.Quantity);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchInvCMLinkedBlOrd(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20]; OrderAmount: Decimal; LineAmount: Decimal)
    var
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
        CrMemoAmount: Decimal;
    begin
        DocumentNo := CreatePurchOrderLinkedBlOrd(PurchHeader, VendorNo, OrderAmount, LineAmount, PurchHeader."Document Type"::Invoice);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type"::"Blanket Order");
        PurchLine.SetFilter("Document No.", DocumentNo);
        PurchLine.FindFirst();

        // Post Purch Order.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Create Purch CM Header.
        CreatePurchHeader(PurchHeader2, PurchHeader2."Document Type"::"Credit Memo", PurchLine."Buy-from Vendor No.");

        // Update Refers To Period.
        PurchHeader2.Validate("Refers to Period", PurchHeader2."Refers to Period"::"Current Calendar Year");
        PurchHeader2.Modify(true);

        // Create Purch Line and Assign Contract No.
        CrMemoAmount := LineAmount / 2;
        CreatePurchLineLinkedBlOrd(PurchHeader2, PurchLine2, PurchLine, CrMemoAmount);

        // Post Purch CM.
        PostedDocNo2 := LibraryPurchase.PostPurchaseDocument(PurchHeader2, true, true);

        ApplyLedgerEntries(
          GenJnlLine."Account Type"::Vendor, PurchHeader2."Document Type", PostedDocNo2, PurchHeader."Document Type", PostedDocNo,
          CrMemoAmount);
    end;

    local procedure CreatePurchOrderLinkedBlOrd(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20]; OrderAmount: Decimal; LineAmount: Decimal; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
    begin
        // Create and Release Blanket Order.
        CreatePurchDocument(PurchHeader2, PurchLine2, PurchHeader."Document Type"::"Blanket Order", VendorNo, OrderAmount);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader2);

        // If Credit Memo then Purchase Order first to have Qty balance
        if DocumentType = PurchHeader."Document Type"::"Credit Memo" then begin
            LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, PurchHeader2."Buy-from Vendor No.");
            CreatePurchLineLinkedBlOrd(PurchHeader, PurchLine, PurchLine2, LineAmount);
            LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        end;

        // Create Purchase Order Header.
        CreatePurchHeader(PurchHeader, DocumentType, PurchHeader2."Buy-from Vendor No.");

        // Update Refers To Period.
        if DocumentType = PurchHeader."Document Type"::"Credit Memo" then begin
            PurchHeader.Validate("Refers to Period", PurchHeader."Refers to Period"::"Current Calendar Year");
            PurchHeader.Modify(true);
        end;

        // Create Sales Line and Assign Contract No.
        CreatePurchLineLinkedBlOrd(PurchHeader, PurchLine, PurchLine2, LineAmount);
        exit(PurchHeader2."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        // Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Sales Line.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "),
          LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LineAmount / SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineLinkedBlOrd(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", SalesLine2."No.", SalesLine2.Quantity / 2); // At least 2 documents can be linked to a Blanket Order.
        SalesLine.Validate("Blanket Order No.", SalesLine2."Document No.");
        SalesLine.Validate("Blanket Order Line No.", SalesLine2."Line No.");
        SalesLine.Validate("Unit Price", LineAmount / SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvCMLinkedBlOrd(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; OrderAmount: Decimal; LineAmount: Decimal)
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        CrMemoAmount: Decimal;
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        DocumentNo := CreateSalesOrderLinkedBlOrd(SalesHeader, CustomerNo, OrderAmount, LineAmount, SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesLine.SetFilter("Document No.", DocumentNo);
        SalesLine.FindFirst();

        // Post Sales Order.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales CM Header.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");

        // Update Refers To Period.
        SalesHeader2.Validate("Refers to Period", SalesHeader2."Refers to Period"::"Current Calendar Year");
        SalesHeader2.Modify(true);

        // Create Sales Line and Assign Contract No.
        CrMemoAmount := LineAmount / 2;
        CreateSalesLineLinkedBlOrd(SalesHeader2, SalesLine2, SalesLine, CrMemoAmount);

        // Post Sales CM.
        PostedDocNo2 := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        ApplyLedgerEntries(
          GenJnlLine."Account Type"::Customer, SalesHeader2."Document Type", PostedDocNo2, SalesHeader."Document Type", PostedDocNo,
          CrMemoAmount);
    end;

    local procedure CreateSalesOrderLinkedBlOrd(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; OrderAmount: Decimal; LineAmount: Decimal; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create and Release Blanket Order.
        CreateSalesDocument(SalesHeader2, SalesLine2, SalesHeader2."Document Type"::"Blanket Order", CustomerNo, OrderAmount);
        LibrarySales.ReleaseSalesDocument(SalesHeader2);

        // If Credit Memo then Sales Order first to have Qty balance
        if DocumentType = SalesHeader."Document Type"::"Credit Memo" then begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesLine2."Sell-to Customer No.");
            CreateSalesLineLinkedBlOrd(SalesHeader, SalesLine, SalesLine2, LineAmount);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        // Create Sales Order Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SalesLine2."Sell-to Customer No.");

        // Update Refers To Period.
        if DocumentType = SalesHeader."Document Type"::"Credit Memo" then begin
            SalesHeader.Validate("Refers to Period", SalesHeader."Refers to Period"::"Current Calendar Year");
            SalesHeader.Modify(true);
        end;

        // Create Sales Line and Assign Contract No.
        CreateSalesLineLinkedBlOrd(SalesHeader, SalesLine, SalesLine2, LineAmount);
        exit(SalesLine2."Document No.");
    end;

    local procedure CreatePostCMJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    begin
        LibraryVATUtils.CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GetGenPostingType(AccountType), AccountType, AccountNo, Amount);
        LibraryVATUtils.UpdateReqFldsGenJnlLine(GenJournalLine, true);
        SetAppliesTo(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostInvoiceJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        GenPostingType: Enum "General Posting Type";
    begin
        GenPostingType := GetGenPostingType(AccountType);
        LibraryVATUtils.CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenPostingType, AccountType,
          CreateDefaultAccount(GenPostingType, AccountType), Amount);
        LibraryVATUtils.UpdateReqFldsGenJnlLine(GenJournalLine, true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        Amount :=
          LibraryVATUtils.AdjustAmountSign(Amount, GenJournalLine."Document Type"::Payment, AccountType, GetGenPostingType(AccountType));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryVATUtils.FindBankAccount());
        SetAppliesTo(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPurchaseDocumentInNextPeriod(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchDocument(PurchaseHeader, PurchaseLine, DocumentType, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(1000, 2));
        UpdatePostingDateInPurchaseDocument(PurchaseHeader, CalcDate('<CM+1Y>', GetLastVATEntryOpOccrDate()));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostPurchaseDocumentInNextPeriodWithVATSetup(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchDocumentWithVATSetup(PurchaseHeader, PurchaseLine, VATPostingSetup, DocumentType, LibraryRandom.RandDec(1000, 2));
        UpdatePostingDateInPurchaseDocument(PurchaseHeader, CalcDate('<CM+1Y>', GetLastVATEntryOpOccrDate()));
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateApplyCM(var GenJnlLine: Record "Gen. Journal Line"; GenJnlLine2: Record "Gen. Journal Line"; GenPostingType: Enum "General Posting Type"; Amount: Decimal) PostingDate: Date
    begin
        // Create Credit Memo.
        LibraryVATUtils.CreateGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::"Credit Memo", GenPostingType, GenJnlLine2."Account Type", GenJnlLine2."Account No.",
          Amount);
        LibraryVATUtils.UpdateReqFldsGenJnlLine(GenJnlLine, true);

        // Set Applies-To.
        SetAppliesTo(GenJnlLine, GenJnlLine2."Document Type", GenJnlLine2."Document No.");

        // Post General Journal.
        PostingDate := GenJnlLine."Posting Date";
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreatePostGenJnlLineWithoutFiscCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type")
    begin
        LibraryVATUtils.CreateGenJnlLineWithFiscalCodeAndVATRegNo(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AccountType, GenPostingType, true, GenJournalLine.Resident::Resident, false);
        GenJournalLine."Fiscal Code" := '';
        GenJournalLine."VAT Registration No." := '';
        GenJournalLine."Include in VAT Transac. Rep." := false;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateIncInVATRepOnVATEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");
    end;

    local procedure CreateVATPostingSetupWithAccountsAndDeductible(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal; Deductible: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType, VATRate);
        VATPostingSetup.Validate("Deductible %", Deductible);
        VATPostingSetup.Modify(true);
    end;

    local procedure GenerateDummyVATReport(var VATReportHeader: Record "VAT Report Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportLine: Record "VAT Report Line";
    begin
        WorkDate(LibraryVATUtils.GetPostingDate());
        LibraryVATUtils.SetupThresholdAmount(WorkDate(), true);
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create and Post Gen. Journal Line.
        LibraryVATUtils.CreatePostGenJnlLine(
              GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, GenJournalLine."Gen. Posting Type"::Sale, true, GenJournalLine.Resident::Resident, true);

        // Create VAT Report.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());
    end;

    local procedure GetGenPostingType(AccountType: Enum "Gen. Journal Account Type") GenPostingType: Enum "General Posting Type"
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                GenPostingType := GenJournalLine."Gen. Posting Type"::Sale;
            GenJournalLine."Account Type"::Vendor:
                GenPostingType := GenJournalLine."Gen. Posting Type"::Purchase;
        end;
    end;

    local procedure GetLastVATEntryOpOccrDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Operation Occurred Date", Type, "Document Type", "Document No.", "Contract No.");
        VATEntry.FindLast();
        exit(VATEntry."Operation Occurred Date");
    end;

    local procedure SetAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", DocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateCheckTotal(var PurchHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchHeader.Validate("Check Total", CheckTotal);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateIndResGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; IndividualPerson: Boolean; Resident: Option; CountryRegionCode: Code[10])
    begin
        GenJournalLine.Validate("Individual Person", IndividualPerson);
        GenJournalLine.Validate(Resident, Resident);
        GenJournalLine.Validate("Country/Region Code", CountryRegionCode);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateIncInVATRepOnVATEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindLast();
        VATEntry."Include in VAT Transac. Rep." := true;
        VATEntry.Modify(true);
    end;

    local procedure UpdatePostingDateInPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date");
        PurchaseHeader.Validate("Operation Occurred Date");
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyVATReportLine(VATReportNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.SetRange("Document Type", DocType);
        VATReportLine.SetRange("Document No.", DocNo);
        VATReportLine.FindFirst();
        VATReportLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyVATReportLine2(var VATReportLine: Record "VAT Report Line"; DocumentType: Enum "Gen. Journal Document Type"; AmountInclVAT: Decimal)
    begin
        VATReportLine.SetRange("Document Type", DocumentType);
        VATReportLine.FindFirst();
        VATReportLine.TestField("Amount Incl. VAT", AmountInclVAT);
    end;

    local procedure VerifyVATReportLineCrMemo(var VATReportLine: Record "VAT Report Line"; GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line"; InvoiceAboveThreshold: Boolean; CreditMemoAboveThreshold: Boolean)
    var
        VatReportLineCounterExpected: Integer;
        VatReportLineCounterActual: Integer;
    begin
        VatReportLineCounterActual := VATReportLine.Count();

        if InvoiceAboveThreshold then begin
            VatReportLineCounterExpected += 1;
            VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::Invoice, -GenJournalLine.Amount); // Adjusted Invoice Amount.
        end;
        if CreditMemoAboveThreshold then begin
            VatReportLineCounterExpected += 1;
            VerifyVATReportLine2(VATReportLine, VATReportLine."Document Type"::"Credit Memo", -GenJournalLine2.Amount);
        end;

        Assert.AreEqual(VatReportLineCounterExpected, VatReportLineCounterActual, ErrorUnexpectedNumberOfLines);
    end;

    local procedure VerifyVATEntryAndVATReportLineForScenarioWithExcludingReverseChangeSalesVATEntry(PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Gen. Journal Document Type"; VATReportNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
    begin
        VATEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        VATEntry.SetRange("Bill-to/Pay-to No.", PurchaseHeader."Pay-to Vendor No.");
        Assert.RecordCount(VATEntry, 2);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        Assert.RecordCount(VATEntry, 1);

        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        Assert.RecordCount(VATReportLine, 1);
        VATReportLine.FindFirst();
        VATReportLine.TestField("Document Type", DocumentType);
        VATReportLine.TestField(Type, VATReportLine.Type::Purchase);
    end;

    local procedure VerifyVATReportLineAmounts(PurchaseHeader: Record "Purchase Header"; VATReportNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.FindFirst();
        Assert.RecordCount(VATReportLine, 1);
        VATReportLine.TestField(Base, PurchaseHeader.Amount);
        VATReportLine.TestField(Amount, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount);
    end;

    local procedure UnapplyEntry(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
                    LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
                    LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
                end;
        end;
    end;

    local procedure UpdateVATEntry(DocumentNo: Code[20]; Amount: Decimal; InclVAT: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            if InclVAT then begin
                if Abs(VATEntry.Base + VATEntry.Amount) = Amount then begin
                    VATEntry."Include in VAT Transac. Rep." := false;
                    VATEntry.Modify(true);
                end;
            end else
                if Abs(VATEntry.Base) = Amount then begin
                    VATEntry."Include in VAT Transac. Rep." := false;
                    VATEntry.Modify(true);
                end;
        until VATEntry.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListHandler(var NoSeriesList: Page "No. Series"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReportListHandler(var VATReportList: TestPage "VAT Report List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VATReportList.GotoKey(No);
        VATReportList.OK().Invoke();
    end;
}

