codeunit 144043 "Test ESR Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectESRSetupItem(var ESRSetupListItems: TestPage "ESR Setup List")
    var
        ESRSetup: Record "ESR Setup";
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        Assert.IsTrue(ESRSetup.Get(BankCode), 'ESR setup not found');
        ESRSetupListItems.GotoRecord(ESRSetup);
        ESRSetupListItems.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ESRImportFileRecordNumber: Variant;
        HandleMessage: Variant;
        ShouldHandleMessage: Boolean;
    begin
        // The message should contain that ESRImportFileRecordNumber records were imported.
        LibraryVariableStorage.Dequeue(HandleMessage);
        ShouldHandleMessage := HandleMessage;
        if ShouldHandleMessage then begin
            LibraryVariableStorage.Dequeue(ESRImportFileRecordNumber);
            Assert.IsTrue(StrPos(Message, ESRImportFileRecordNumber) > 0, 'Unexpected dialog.');
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LSVConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVSuggestCollectionReqPageHandler(var LSVSuggestCollection: TestRequestPage "LSV Suggest Collection")
    begin
        LSVSuggestCollection.FromDueDate.SetValue(WorkDate());
        LSVSuggestCollection.ToDueDate.SetValue(WorkDate());
        LSVSuggestCollection.Customer.SetFilter("No.", RetrieveLSVCustomerForCollection());
        LSVSuggestCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCloseCollectionReqPageHandler(var LSVCloseCollection: TestRequestPage "LSV Close Collection")
    begin
        LSVCloseCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVFileReqPageHandler(var WriteLSVFile: TestRequestPage "Write LSV File")
    begin
        WriteLSVFile.TestSending.SetValue(false);
        WriteLSVFile.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerESRJournalReportRequestPageHandler(var RequestPage: TestRequestPage "Customer ESR Journal")
    var
        "Layout": Variant;
    begin
        LibraryVariableStorage.Dequeue(Layout);

        RequestPage.Layout.SetValue(Layout);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;
}

