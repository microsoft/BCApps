codeunit 144068 "UT - Export Payment File"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export again?';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT - Export Payment File");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT - Export Payment File");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT - Export Payment File");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineAlreadyExportedForDTA()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        Initialize();

        // Setup.
        SetupPaymentJournal(GenJournalLine);

        // Exercise.
        PaymentJournal.OpenView();
        PaymentJournal."Generate &DTA File".Invoke(); // Generate DTA

        // Verify: In confirm handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineAlreadyExportedForEZAG()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        Initialize();

        // Setup.
        SetupPaymentJournal(GenJournalLine);

        // Exercise.
        PaymentJournal.OpenView();
        PaymentJournal."Generate EZAG File".Invoke(); // Generate EZAG

        // Verify: In confirm handler.
    end;

    local procedure SetupPaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        SelectPaymentJnlBatch(GenJournalBatch);
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
            if i mod 2 = 1 then begin
                GenJournalLine."Exported to Payment File" := true;
                GenJournalLine.Modify();
            end;
        end;
    end;

    local procedure SelectPaymentJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange("Page ID", PAGE::"Payment Journal");
        GenJournalTemplate.FindFirst();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        if not GenJournalBatch.FindFirst() then
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(Format(ExportAgainQst), Message, 'Unexpected dialog.');
        Reply := false;
    end;
}

