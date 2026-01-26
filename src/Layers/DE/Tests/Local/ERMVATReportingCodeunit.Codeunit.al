codeunit 134055 "ERM VAT Reporting - Codeunit"
{
    // // [FEATURE] [VAT Report]

    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "VAT Entry" = i;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        VATReportMediator: Codeunit "VAT Report Mediator";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        StatusError: Label 'Status must be equal to ''Open''  in %1: %2=%3. Current value is ''Released''.', Comment = '%1=Table Caption;%2=Field Caption;%3=Field Value;';
        OriginalReportNoError: Label 'You must specify an original report for a report of type %1.', Comment = '%1=vat report type';
        VATReportConfigCodeError: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is '' ''.', Comment = '%1=Field Caption;%2=Field Value;%3=Table Caption;%4=Field Caption;%5=Field Value;';
        NoLinesError: Label 'You cannot release the %1 report because no lines exist.', Comment = '%1=Table Caption;';
        SubmittedError: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1=Table Caption;';
        EmptyError: Label '%1 must be empty.', Comment = '%1=Table Caption';
        VATReportErr: Label 'VAT Report Line does not have value.';

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesOrignalReportNo()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Original Report No. Error comes after doing GetLines when VAT Report Type is Corrective.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Set VAT Report Type to Corrective and run Suggest Lines.
        VATReportHeader."VAT Report Type" := VATReportHeader."VAT Report Type"::Corrective;
        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for Original Report No.
        Assert.ExpectedError(
          StrSubstNo(OriginalReportNoError, Format(VATReportHeader."VAT Report Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesStatus()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Status Error comes after doing GetLines when the status is released.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Set Status to Release and run Suggest Lines.
        VATReportHeader.Status := VATReportHeader.Status::Released;

        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for status.
        Assert.ExpectedError(
          StrSubstNo(StatusError, VATReportHeader.TableCaption(), VATReportHeader.FieldCaption("No."), VATReportHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesVATReportConfigCode()
    var
        VATReportHeader: Record "VAT Report Header";
        TempVATReportHeader: Record "VAT Report Header" temporary;
    begin
        // Check VAT Report Config. Code Error comes after doing GetLines when VAT Report Config. Code is not set to option 1.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);
        CreateVATReportHeader(TempVATReportHeader);
        TempVATReportHeader."VAT Report Config. Code" := 1;  // Assigning First Option Value in Temp Record as needed for Expected Error.

        // 2. Exercise: Set VAT Report Config. Code to blank and run Suggest Lines.
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::" ";
        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for VAT Report Config Code.
        Assert.ExpectedError(
          StrSubstNo(
            VATReportConfigCodeError, VATReportHeader.FieldCaption("VAT Report Config. Code"),
            TempVATReportHeader."VAT Report Config. Code", VATReportHeader.TableCaption(),
            VATReportHeader.FieldCaption("No."), VATReportHeader."No."));
    end;

    [Test]
    [HandlerFunctions('SuggestLinesReportHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLines()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Check VAT Report Suggest Lines report gets run after doing GetLines and no lines come on date less than workdate in VAT Report Lines.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update the start and end date to any date less than workdate and Run Suggest Lines.
        VATReportHeader."Start Date" := CalcDate('<-' + Format(LibraryRandom.RandInt(10) + 1) + 'Y>', WorkDate());
        VATReportHeader."End Date" := VATReportHeader."Start Date";
        VATReportHeader.Modify();
        Commit();

        VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: VAT Report Line is empty.
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        Assert.IsTrue(VATReportLine.IsEmpty, StrSubstNo(EmptyError, VATReportLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorReopenAfterSubmit()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Check Error comes for Not allowed to reopen after submit when the Modify Submitted Reports is False in VAT Report Setup.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update status to submitted and Reopen.
        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        asserterror VATReportMediator.Reopen(VATReportHeader);

        // 3. Verify: Error occurs for not allowed to reopen due to the VAT Report Setup.
        Assert.ExpectedError(StrSubstNo(SubmittedError, VATReportSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorReopenAfterRelease()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Status gets updated to open after reopen when the earlier status was released.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update status to Released and Reopen.
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportMediator.Reopen(VATReportHeader);

        // 3. Verify: Status gets updated to Open.
        VATReportHeader.Get(VATReportHeader."No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorRelease()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportErrorLog: TestPage "VAT Report Error Log";
    begin
        // Check Error comes for No VAT Report Lines when changing the status to release.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Run the Release function.
        VATReportErrorLog.Trap();
        asserterror VATReportMediator.Release(VATReportHeader);

        // 3. Verify: Error occurs for No VAT Report Lines.
        VATReportErrorLog."Error Message".AssertEquals(StrSubstNo(NoLinesError, CopyStr(VATReportHeader.TableCaption(), 1, 3)));
        VATReportErrorLog.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SuggestLinesReportHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportSuggestLines()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Check Error comes when click on Suggest Lines in VAT Report Header.

        // 1. Setup: Create VAT Report Header with Trade type.
        Initialize();
        CreateVATReportHeaderWithTradeType(VATReportHeader, VATReportHeader."Trade Type"::Both);

        // 2. Exercise: Run the VAT Report Suggest Lines.
        RunVATReportSuggestLines(VATReportHeader."No.");

        // 3. Verify: VAT Report Lines created successfully.
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        Assert.IsTrue(not VATReportLine.IsEmpty, VATReportErr);
    end;

    [Test]
    [HandlerFunctions('VATEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportBaseOnAssistButton()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
    begin
        // Check that VAT Report Header Status gets changed to released while export when status is open.
        Initialize();

        // 1. Setup: Create VAT Report Header.
        CreateVATReportHeaderWithData(VATReportHeader, VATReportHeader."Trade Type"::Sales);
        CreateVATReportLinesWithData(VATReportHeader."No.");

        // 2. Click OnAssist Button in VAT Report Line and look VAT Entries.
        VATReport.OpenEdit();
        VATReport.FILTER.SetFilter("No.", VATReportHeader."No.");
        VATReport.VATReportLines.Base.AssistEdit();
    end;

    [Test]
    [HandlerFunctions('SuggestLinesReportHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportSuggestLinesAfterCustBalPosting()
    var
        VATReportHeader: Record "VAT Report Header";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 121626] Verify VAT Report Line is created with Customer info
        Initialize();

        // [GIVEN] Customer with "Country/Region Code" = CountryCode, "VAT Registration No." = VATRegNo
        CreateCustomer(Customer);

        // [GIVEN] Create post sales journal with two lines: 1 - AcountNo = GLAccount, BalAccNo = ''; 2 - AccountNo = '', BalAccNo = CustomerNo
        CreatePostGenJnlLines(
          CreateGLAccount(GLAccount."Gen. Posting Type"::Sale), Customer."No.", GenJournalLine."Bal. Account Type"::Customer, -1);

        // [GIVEN] VAT Report Card
        CreateVATReportHeaderWithData(VATReportHeader, VATReportHeader."Trade Type"::Sales);

        // [WHEN] Run the VAT Report Suggest Lines.
        RunVATReportSuggestLines(VATReportHeader."No.");

        // [THEN] There is a VAT Report Line with "Country/Region Code" = CountryCode, "VAT Registration No." = VATRegNo
        VerifyVATReportCVInfo(VATReportHeader."No.", Customer."Country/Region Code", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SuggestLinesReportHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportSuggestLinesAfterVendBalPosting()
    var
        VATReportHeader: Record "VAT Report Header";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 121626] Verify VAT Report Line is created with Vendor info
        Initialize();

        // [GIVEN] Vendor with "Country/Region Code" = CountryCode, "VAT Registration No." = VATRegNo
        CreateVendor(Vendor);

        // [GIVEN] Create post purchase journal with two lines: 1 - AcountNo = GLAccount, BalAccNo = ''; 2 - AccountNo = '', BalAccNo = VendorNo
        CreatePostGenJnlLines(
          CreateGLAccount(GLAccount."Gen. Posting Type"::Purchase), Vendor."No.", GenJournalLine."Bal. Account Type"::Vendor, 1);

        // [GIVEN] VAT Report Card
        CreateVATReportHeaderWithData(VATReportHeader, VATReportHeader."Trade Type"::Purchases);

        // [WHEN] Run the VAT Report Suggest Lines.
        RunVATReportSuggestLines(VATReportHeader."No.");

        // [THEN] There is a VAT Report Line with "Country/Region Code" = CountryCode, "VAT Registration No." = VATRegNo
        VerifyVATReportCVInfo(VATReportHeader."No.", Vendor."Country/Region Code", Vendor."VAT Registration No.");
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        CreateVATReportSetup();
        Commit();
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert();
        VATReportSetup."No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        VATReportSetup.Modify();
    end;

    local procedure CreateVATReportHeaderWithTradeType(var VATReportHeader: Record "VAT Report Header"; TradeType: Option)
    begin
        CreateVATReportHeader(VATReportHeader);
        VATReportHeader.Validate("Trade Type", TradeType);
        VATReportHeader.Modify(true);
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.Init();
        VATReportHeader.Insert(true);
    end;

    local procedure CreateVATReportHeaderWithData(var VATReportHeader: Record "VAT Report Header"; TradeType: Option)
    begin
        CreateVATReportHeader(VATReportHeader);
        VATReportHeader."Trade Type" := TradeType;
        VATReportHeader."Report Period Type" := VATReportHeader."Report Period Type"::Month;
        VATReportHeader."Report Period No." := Date2DMY(WorkDate(), 2);
        VATReportHeader."Report Year" := Date2DMY(WorkDate(), 3);
        VATReportHeader."Start Date" := CalcDate('<-CM>', WorkDate());
        VATReportHeader."End Date" := CalcDate('<CM>', WorkDate());
        VATReportHeader.Modify();
    end;

    local procedure CreateVATReportLinesWithData(VATReportNo: Code[20])
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        VATReportLine: Record "VAT Report Line";
        i: Integer;
        NextVATEntryNo: Integer;
    begin
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportNo;
        VATReportLine."Line No." := 10000;
        VATReportLine.Insert();

        NextVATEntryNo := 10000;
        for i := 1 to 300 do begin
            VATEntry.Init();
            VATEntry."Entry No." := NextVATEntryNo;
            VATEntry."Posting Date" := WorkDate();
            VATEntry."Document No." := VATReportNo;
            VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
            VATEntry.Type := VATEntry.Type::Sale;
            VATEntry.Base := LibraryRandom.RandInt(1000);
            VATEntry.Insert();
            NextVATEntryNo := NextVATEntryNo + 1;

            VATReportLineRelation.Init();
            VATReportLineRelation."VAT Report No." := VATReportNo;
            VATReportLineRelation."VAT Report Line No." := 10000;
            VATReportLineRelation."Table No." := DATABASE::"VAT Entry";
            VATReportLineRelation."Entry No." := VATEntry."Entry No.";
            VATReportLineRelation.Insert();
        end;
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."EU Country/Region Code" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CreateCountryRegionCode();
        Customer."VAT Registration No." := LibraryUtility.GenerateGUID();
        Customer.Modify();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CreateCountryRegionCode();
        Vendor."VAT Registration No." := LibraryUtility.GenerateGUID();
        Vendor.Modify();
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType));
    end;

    local procedure CreatePostGenJnlLines(GLAccountNo: Code[20]; CVNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; SignFactor: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PayAmount: Decimal;
        DocumentNo: Code[20];
    begin
        PayAmount := LibraryRandom.RandDec(100, 2);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, PayAmount * SignFactor);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type", GenJournalLine."Account Type", '', BalAccountType, CVNo, PayAmount * SignFactor);
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunVATReportSuggestLines(VATReportHeaderNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Commit();
        VATReportHeader.SetRange("No.", VATReportHeaderNo);
        REPORT.Run(REPORT::"VAT Report Suggest Lines", true, false, VATReportHeader);
    end;

    local procedure VerifyVATReportCVInfo(VATReportNo: Code[20]; ExpectedCountryCode: Code[10]; ExpectedVATRegNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.SetRange("Country/Region Code", ExpectedCountryCode);
        VATReportLine.SetRange("VAT Registration No.", ExpectedVATRegNo);
        Assert.IsFalse(VATReportLine.IsEmpty, VATReportErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesReportHandler(var SuggestLinesRequestPage: TestRequestPage "VAT Report Suggest Lines")
    begin
        SuggestLinesRequestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATEntriesPageHandler(var VATEntries: TestPage "VAT Entries")
    begin
        VATEntries.First();
        VATEntries.OK().Invoke();
    end;
}
