codeunit 144004 Domicilations
{
    // // [FEATURE] [Domicilations]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        DomFileNotExistsErr: Label 'Domiciliation file not created after exporting domiciliation journal line.';
        FileMgt: Codeunit "File Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPaymentJournalBE: Codeunit "Library - Payment Journal BE";
        DomiciliationJnlManagement: Codeunit DomiciliationJnlManagement;
        DimensionIsNotCorrectErr: Label '%1 is not correct for line %2.';
        DomLineDoesNotExistErr: Label '%1 does not exist.';

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler,FileDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure FileDomicilations_SaveFileForSimpleLine_FileCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        FileName: Text;
    begin
        CreateSimpleDomicilation(DomiciliationJournalLine, '');

        FileName := FileMgt.ServerTempFileName('');

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        Commit();
        DomiciliationJournalLine.FindFirst();
        DomiciliationJnlManagement.CreateDomiciliations(DomiciliationJournalLine);

        Assert.IsTrue(FileMgt.ServerFileExists(FileName + '.tmp'), DomFileNotExistsErr);
        FileMgt.DeleteServerFile(FileName + '.tmp');
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler,FileDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure DimensionsTransferedInGenJournalLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
        DimSetID: array[2] of Integer;
    begin
        CustomerNo := CreateCustomerWithNewDimension();
        CreatePostSalesInvoice(CustomerNo);
        CustomerNo2 := CreateCustomerWithNewDimension();
        CreatePostSalesInvoice(CustomerNo2);

        SuggestDomiciliationsSetDimension(DimSetID, StrSubstNo('%1|%2', CustomerNo, CustomerNo2));
        FileDomiciliations(GenJournalBatch);

        VerifyDimensionSetIDs(GenJournalBatch, DimSetID);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler,FileDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure SuggestFileDomiciliationWithoutDomiciliationNo()
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20];
    begin
        // Verify Domiciliation Journal Line is suggested, File Domiciliation runs without errors
        // File Domiciliation report shows correct values if Customer "Domiciliation No." field is empty
        CustomerNo := CreateSimpleCustomer(false);
        CreatePostSalesInvoice(CustomerNo);
        SuggestDomiciliations(DomiciliationJournalLine, CustomerNo);

        Assert.IsFalse(
          DomiciliationJournalLine.IsEmpty, StrSubstNo(DomLineDoesNotExistErr, DomiciliationJournalLine.TableCaption()));
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FileDomiciliations(GenJournalBatch);
        VerifyDomiciliationNo(0, 0);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure SuggestDomicilationForUnappliedCustomerInvoice()
    var
        DomiciliationJournalBatch: array[2] of Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: array[2] of Record "Domiciliation Journal Line";
    begin
        // [SCENARIO 378815] Domicilation journal line is suggested for an unapplied customer invoice
        CreateDomJnlTemplateWithTwoBatches(DomiciliationJournalBatch);

        // [GIVEN] Posted customer "C" domicilation journal line (DomJnlLine's "Template" = "A", "Batch" = "B1", "Status" = "Posted") for invoice "I"
        MockDomJnlLine(DomiciliationJournalLine[1], DomiciliationJournalBatch[1], DomiciliationJournalLine[1].Status::Posted);

        // [GIVEN] Unapply customer invoice "I"
        MockInvoiceCLE(DomiciliationJournalLine[1]."Customer No.", DomiciliationJournalLine[1]."Applies-to Doc. No.", true);

        // [WHEN] Suggest domicilation for new batch "B2"
        FilterDomJnlLine(DomiciliationJournalLine[2], DomiciliationJournalBatch[2]);
        RunSuggestDomicilations(DomiciliationJournalLine[2], DomiciliationJournalLine[1]."Customer No.");

        // [THEN] New domicilation line is created in batch "B2" with following values:
        // [THEN] "Template" = "A", "Batch" = "B2", "Customer No." = "C", "Applies-to Doc. Type" = Invoice, "Applies-to Doc. No." = "I", "Status" = ""
        Assert.RecordIsNotEmpty(DomiciliationJournalLine[2]);
        VerifyDomJnlLineValues(DomiciliationJournalLine[2], DomiciliationJournalLine[1], DomiciliationJournalLine[2].Status::" ");
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure SuggestDomicilationForAlreadyPostedCustomerInvoice()
    var
        DomiciliationJournalBatch: array[2] of Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // [SCENARIO 378815] Domicilation journal line is not suggested for already posted customer invoice
        CreateDomJnlTemplateWithTwoBatches(DomiciliationJournalBatch);

        // [GIVEN] Posted customer domicilation journal line (DomJnlLine's "Template" = "A", "Batch" = "B1", "Status" = "Posted") for invoice
        MockDomJnlLine(DomiciliationJournalLine, DomiciliationJournalBatch[1], DomiciliationJournalLine.Status::Posted);
        MockInvoiceCLE(DomiciliationJournalLine."Customer No.", DomiciliationJournalLine."Applies-to Doc. No.", false);

        // [WHEN] Suggest domicilation for new batch "B2"
        FilterDomJnlLine(DomiciliationJournalLine, DomiciliationJournalBatch[2]);
        RunSuggestDomicilations(DomiciliationJournalLine, DomiciliationJournalLine."Customer No.");

        // [THEN] No domicilation line is created in batch "B2"
        Assert.RecordIsEmpty(DomiciliationJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure SuggestDomicilationForAlreadySuggestedCustomerInvoice()
    var
        DomiciliationJournalBatch: array[2] of Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // [SCENARIO 378815] Domicilation journal line is not suggested for already suggested customer invoice
        CreateDomJnlTemplateWithTwoBatches(DomiciliationJournalBatch);

        // [GIVEN] Suggested customer domicilation journal line (DomJnlLine's "Template" = "A", "Batch" = "B1", "Status" = "") for invoice
        MockDomJnlLine(DomiciliationJournalLine, DomiciliationJournalBatch[1], DomiciliationJournalLine.Status::" ");
        MockInvoiceCLE(DomiciliationJournalLine."Customer No.", DomiciliationJournalLine."Applies-to Doc. No.", true);

        // [WHEN] Suggest domicilation for new batch "B2"
        FilterDomJnlLine(DomiciliationJournalLine, DomiciliationJournalBatch[2]);
        RunSuggestDomicilations(DomiciliationJournalLine, DomiciliationJournalLine."Customer No.");

        // [THEN] No domicilation line is created in batch "B2"
        Assert.RecordIsEmpty(DomiciliationJournalLine);
    end;

    [Test]
    [HandlerFunctions('DisabledRefundSuggestDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure RefundDisabledInSuggestDomiciliationRequestPage()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 201771] Stan can't select refunds when calls "Suggest Domiciliation" report on journal template pointing to processing codeunit that is not support domiciliation

        // [GIVEN] Bank account "B" where "SEPA Export Format" = "SEPA DD-Export File" (does not support domiciliation, i.e. Refunds)
        // [GIVEN] Domiciliation journal template with Bank Account = "B"
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        DomiciliationJournalTemplate."Bank Account No." := CreateBankAccountWithExportImportSetup(CODEUNIT::"SEPA DD-Export File");
        DomiciliationJournalTemplate.Modify();

        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        LibraryPaymentJournalBE.CreateDomLine(
          DomiciliationJournalLine, DomiciliationJournalTemplate.Name, DomiciliationJournalBatch.Name);

        // [WHEN] Stan calls "Suggest domiciliations"
        Commit();
        LibraryPaymentJournalBE.RunSuggestDomiciliations(DomiciliationJournalLine);

        // [THEN] The "Select Possible Refunds" option (Checkbox) is disabled and not checked
        // verification done in DisabledRefundSuggestDomiciliationsHandler
    end;

    [Test]
    [HandlerFunctions('EnabledRefundSuggestDomiciliationsHandler')]
    [Scope('OnPrem')]
    procedure RefundEnabledInSuggestDomiciliationRequestPage()
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 201771] Stan can select refunds when calls "Suggest Domiciliation" report on journal template pointing to processing codeunit that supports domiciliation

        // [GIVEN] Bank account "B" where "SEPA Export Format" = "File Domiciliation" (does not support domiciliation, i.e. Refunds)
        // [GIVEN] Domiciliation journal template with Bank Account = "B"
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        DomiciliationJournalTemplate."Bank Account No." := CreateBankAccountWithExportImportSetup(CODEUNIT::"File Domiciliations");
        DomiciliationJournalTemplate.Modify();

        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        LibraryPaymentJournalBE.CreateDomLine(
          DomiciliationJournalLine, DomiciliationJournalTemplate.Name, DomiciliationJournalBatch.Name);

        // [WHEN] Stan calls "Suggest domiciliations"
        Commit();
        LibraryPaymentJournalBE.RunSuggestDomiciliations(DomiciliationJournalLine);

        // [THEN] The "Select Possible Refunds" option (Checkbox) is enabled and not checked
        // verification done in EnabledRefundSuggestDomiciliationsHandler
    end;

    local procedure CreateSimpleDomicilation(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; CustomerNoFilter: Text)
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        JnlSelected: Boolean;
        CurrentJnlBatchName: Code[10];
    begin
        DomiciliationJnlManagement.TemplateSelection(DomiciliationJournalLine, JnlSelected);
        DomiciliationJnlManagement.OpenJournal(CurrentJnlBatchName, DomiciliationJournalLine);

        DomiciliationJournalTemplate.FindFirst();
        DomiciliationJournalLine."Journal Template Name" := DomiciliationJournalTemplate.Name;
        DomiciliationJournalLine."Journal Batch Name" := CurrentJnlBatchName;

        RunSuggestDomicilations(DomiciliationJournalLine, CustomerNoFilter);
    end;

    local procedure FindDomiciliationNo(): Text[12]
    var
        Customer: Record Customer;
    begin
        Customer.SetFilter("Domiciliation No.", '<>''''');
        Customer.FindFirst();
        exit(Customer."Domiciliation No.");
    end;

    local procedure CreateCustomerWithNewDimension() CustomerNo: Code[20]
    var
        GLSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        GLSetup.Get();
        CustomerNo := CreateSimpleCustomer(true);
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, GLSetup."Shortcut Dimension 1 Code", DimensionValue.Code);
    end;

    local procedure CreateSimpleCustomer(SetDomiciliationNo: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        if SetDomiciliationNo then begin
            Customer."Domiciliation No." := FindDomiciliationNo();
            Customer.Modify();
        end;
        exit(Customer."No.");
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateDomJnlTemplateWithTwoBatches(var DomiciliationJournalBatch: array[2] of Record "Domiciliation Journal Batch")
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
    begin
        LibraryPaymentJournalBE.CreateDomTemplate(DomiciliationJournalTemplate);
        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch[1]);
        LibraryPaymentJournalBE.CreateDomBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch[2]);
    end;

    local procedure CreateBankAccountWithExportImportSetup(ProcessingCodeunitID: Integer): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        BankAccount: Record "Bank Account";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitID;
        BankExportImportSetup.Insert();

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.Modify();

        exit(BankAccount."No.");
    end;

    local procedure MockDomJnlLine(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; NewStatus: Option)
    begin
        LibraryPaymentJournalBE.CreateDomLine(
          DomiciliationJournalLine,
          DomiciliationJournalBatch."Journal Template Name", DomiciliationJournalBatch.Name);
        DomiciliationJournalLine."Customer No." := LibrarySales.CreateCustomerNo();
        DomiciliationJournalLine."Applies-to Doc. Type" := DomiciliationJournalLine."Applies-to Doc. Type"::Invoice;
        DomiciliationJournalLine."Applies-to Doc. No." := LibraryUtility.GenerateGUID();
        DomiciliationJournalLine.Status := NewStatus;
        DomiciliationJournalLine.Modify();
    end;

    local procedure MockInvoiceCLE(CustomerNo: Code[20]; InvoiceNo: Code[20]; OpenStatus: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := InvoiceNo;
        CustLedgerEntry.Open := OpenStatus;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry.Insert();
    end;

    local procedure FilterDomJnlLine(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        DomiciliationJournalLine."Journal Template Name" := DomiciliationJournalBatch."Journal Template Name";
        DomiciliationJournalLine."Journal Batch Name" := DomiciliationJournalBatch.Name;
        DomiciliationJournalLine.SetRange("Journal Template Name", DomiciliationJournalLine."Journal Template Name");
        DomiciliationJournalLine.SetRange("Journal Batch Name", DomiciliationJournalLine."Journal Batch Name");
    end;

    local procedure SuggestDomiciliationsSetDimension(var DimSetID: array[2] of Integer; CustomerFilter: Text[100])
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
    begin
        SuggestDomiciliations(DomiciliationJournalLine, CustomerFilter);
        DomiciliationJournalLine.FindSet();
        DimSetID[1] := DomiciliationJournalLine."Dimension Set ID";
        DomiciliationJournalLine.Next();
        DimSetID[2] := DomiciliationJournalLine."Dimension Set ID";
    end;

    local procedure SuggestDomiciliations(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; CustomerFilter: Text[100])
    begin
        DomiciliationJournalLine.DeleteAll();
        CreateSimpleDomicilation(DomiciliationJournalLine, CustomerFilter);
    end;

    local procedure FileDomiciliations(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        FileName: Text;
    begin
        FileName := TemporaryPath + LibraryUtility.GenerateGUID();

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        Commit();
        DomiciliationJournalLine.FindFirst();
        DomiciliationJnlManagement.CreateDomiciliations(DomiciliationJournalLine);

        FileMgt.DeleteServerFile(FileName + '.tmp');
    end;

    local procedure RunSuggestDomicilations(DomiciliationJournalLine: Record "Domiciliation Journal Line"; CustomerNoFilter: Text)
    var
        Customer: Record Customer;
        SuggestDomicilations: Report "Suggest domicilations";
    begin
        Commit();
        Customer.SetFilter("No.", CustomerNoFilter);
        SuggestDomicilations.SetTableView(Customer);
        SuggestDomicilations.SetJournal(DomiciliationJournalLine);
        SuggestDomicilations.RunModal();
    end;

    local procedure VerifyDimensionSetIDs(var GenJournalBatch: Record "Gen. Journal Batch"; var DimSetID: array[2] of Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        Assert.AreEqual(
          DimSetID[1], GenJournalLine."Dimension Set ID",
          StrSubstNo(DimensionIsNotCorrectErr, GenJournalLine.FieldCaption("Dimension Set ID"), GenJournalLine."Line No."));
        GenJournalLine.Next();
        Assert.AreEqual(
          DimSetID[2], GenJournalLine."Dimension Set ID",
          StrSubstNo(DimensionIsNotCorrectErr, GenJournalLine.FieldCaption("Dimension Set ID"), GenJournalLine."Line No."));
    end;

    local procedure VerifyDomiciliationNo(DomiciliationNo1: Integer; DomiciliationNo2: Integer)
    begin
        LibraryReportValidation.OpenFile();
        // Check Domiciliation Total Domiciliation Nos. fields' values
        LibraryReportValidation.VerifyCellValue(15, 7, Format(DomiciliationNo1));
        LibraryReportValidation.VerifyCellValue(16, 7, Format(DomiciliationNo2));
    end;

    local procedure VerifyDomJnlLineValues(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; DomiciliationJournalLine2: Record "Domiciliation Journal Line"; ExpectedStatus: Option)
    begin
        DomiciliationJournalLine.FindFirst();
        Assert.AreEqual(DomiciliationJournalLine2."Customer No.", DomiciliationJournalLine."Customer No.", DomiciliationJournalLine.FieldCaption("Customer No."));
        Assert.AreEqual(DomiciliationJournalLine2."Applies-to Doc. Type", DomiciliationJournalLine."Applies-to Doc. Type", DomiciliationJournalLine.FieldCaption("Applies-to Doc. Type"));
        Assert.AreEqual(DomiciliationJournalLine2."Applies-to Doc. No.", DomiciliationJournalLine."Applies-to Doc. No.", DomiciliationJournalLine.FieldCaption("Applies-to Doc. No."));
        Assert.AreEqual(ExpectedStatus, DomiciliationJournalLine.Status, DomiciliationJournalLine.FieldCaption(Status));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileDomiciliationsHandler(var FileDomiciliations: TestRequestPage "File Domiciliations")
    var
        FileName: Variant;
        GenJournalBatchName: Variant;
    begin
        FileDomiciliations.Var1.SetValue(LibraryERM.SelectGenJnlTemplate());

        LibraryVariableStorage.Dequeue(FileName);
        FileDomiciliations.FileName.SetValue(Format(FileName) + '.tmp');

        LibraryVariableStorage.Dequeue(GenJournalBatchName);
        FileDomiciliations.Var2.SetValue(GenJournalBatchName);

        FileDomiciliations.SaveAsExcel(Format(LibraryReportValidation.GetFileName()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestDomiciliationsHandler(var Suggestdomicilations: TestRequestPage "Suggest domicilations")
    begin
        Suggestdomicilations.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DisabledRefundSuggestDomiciliationsHandler(var Suggestdomicilations: TestRequestPage "Suggest domicilations")
    begin
        Assert.IsFalse(Suggestdomicilations.SelectPossibleRefunds.Enabled(), 'Select Possible Refunds must be disabled');
        Suggestdomicilations.SelectPossibleRefunds.AssertEquals(false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EnabledRefundSuggestDomiciliationsHandler(var Suggestdomicilations: TestRequestPage "Suggest domicilations")
    begin
        Assert.IsTrue(Suggestdomicilations.SelectPossibleRefunds.Enabled(), 'Select Possible Refunds must be enabled');
        Suggestdomicilations.SelectPossibleRefunds.AssertEquals(false);
    end;
}

