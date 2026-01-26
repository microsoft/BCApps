codeunit 144350 "CH DTA/EZAG File Reports"
{
    // // [FEATURE] [DTA File] [EZAG File]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryDTA: Codeunit "Library - DTA";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWriteTestFile()
    var
        DTASetup: Record "DTA Setup";
        DTASetupPage: TestPage "DTA Setup";
        File: Text;
    begin
        Initialize();

        LibraryDTA.CreateDTASetup(DTASetup, '', false);
        DTASetup.Validate("DTA File Folder", TemporaryPath);
        DTASetup.Modify(true);

        Commit();

        DTASetupPage.OpenEdit();
        DTASetupPage.GotoRecord(DTASetup);
        DTASetupPage."&Write Testfile".Invoke();

        File := DTASetup."DTA File Folder" + DTASetup."DTA Filename";

        Assert.IsTrue(Exists(File), 'No test file generated in ' + File);
        Erase(File);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if not isInitialized then begin
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibraryERMCountryData.UpdatePurchasesPayablesSetup();
            LibraryERMCountryData.UpdateGenJournalTemplate();
            LibraryERMCountryData.UpdateGeneralLedgerSetup();
            isInitialized := true;
            Commit();
            exit;
        end;

        // Delete all Journal Lines
        GenJournalLine.Init();
        GenJournalLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure FindLineContainingValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        File: File;
        InStr: InStream;
        FieldValue: Text[1024];
    begin
        File.TextMode(true);
        File.Open(FileName, TEXTENCODING::Windows);
        File.Read(Line);
        File.CreateInStream(InStr);
        while (not InStr.EOS) and (StrPos(FieldValue, Value) = 0) do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if StrPos(FieldValue, Value) = 0 then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTASuggestVendorPaymentsRequestPageHandler(var DTASuggestVendorPayments: TestRequestPage "DTA Suggest Vendor Payments")
    var
        VarPostingDate: Variant;
        VarDueDateFrom: Variant;
        VarDueDateTo: Variant;
        DebitToBank: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarPostingDate);
        LibraryVariableStorage.Dequeue(VarDueDateFrom);
        LibraryVariableStorage.Dequeue(VarDueDateTo);
        LibraryVariableStorage.Dequeue(DebitToBank);
        LibraryVariableStorage.Dequeue(VendorNo);

        DTASuggestVendorPayments."Posting Date".SetValue(VarPostingDate); // Posting Date
        DTASuggestVendorPayments."Due Date from".SetValue(VarDueDateFrom); // Due Date From
        DTASuggestVendorPayments."Due Date to".SetValue(VarDueDateTo); // Due Date To

        if Format(DebitToBank) <> '' then
            DTASuggestVendorPayments."ReqFormDebitBank.""Bank Code""".SetValue(DebitToBank);
        DTASuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);

        DTASuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTAFileRequestPageHandler(var DTAFile: TestRequestPage "DTA File")
    var
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        DTAFile."FileBank.""Bank Code""".SetValue(BankCode);
        DTAFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EZAGFileRequestPageHandler(var EZAGFile: TestRequestPage "EZAG File")
    var
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        EZAGFile."DtaSetup.""Bank Code""".SetValue(BankCode);
        EZAGFile.OK().Invoke();
    end;
}

