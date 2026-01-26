codeunit 144051 TELEBANK
{
    // Validate report file format

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";

    [Test]
    [HandlerFunctions('FileInternationalPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInternationalExportFile()
    var
        ElectronicBankingSetup: Record "Electronic Banking Setup";
        UploadNoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        RequestNoSeries: Record "No. Series";
        NoSeries: Record "No. Series";
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentJournalTemplate: Record "Payment Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymJournalBatch: Record "Paym. Journal Batch";
        CustomerPaymentJournalLine: Record "Payment Journal Line";
        VendorPaymentJournalLine: Record "Payment Journal Line";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        FileInternationalPayments: Report "File International Payments";
        StringObject: DotNet String;
        FileObject: DotNet File;
        ServerFilename: Text;
    begin
        LibraryVariableStorage.Clear();
        // Create No Series for the Gen Journal Template
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'GJTTest0001', 'GJTTest9999');
        NoSeriesLine.Modify(true);

        // Create Template
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        PaymentJournalTemplate.Init();
        PaymentJournalTemplate.Name := GenJournalTemplate.Name;
        PaymentJournalTemplate.Insert();

        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);

        // Create Batch
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."No. Series" := NoSeries.Code;
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := GLAccount."No.";
        GenJournalBatch.Modify(true);

        PaymJournalBatch.Init();
        PaymJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        PaymJournalBatch.Name := GenJournalBatch.Name;
        PaymJournalBatch.Insert();

        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // Post
        LibraryVariableStorage.Enqueue(false);

        // Include dimentions
        LibraryVariableStorage.Enqueue(false);

        // Execution date
        LibraryVariableStorage.Enqueue(WorkDate());

        // Inscription No
        LibraryVariableStorage.Enqueue(1);

        // Filename
        ServerFilename := FileManagement.ServerTempFileName('txt');
        FileManagement.DeleteServerFile(ServerFilename);
        Assert.IsFalse(FileManagement.ServerFileExists(ServerFilename), 'Expected the Server file to be deleted');

        // Update the electronic banking setup
        LibraryUtility.CreateNoSeries(UploadNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, UploadNoSeries.Code, 'IBSUP0001', 'IBSUP9999');
        NoSeriesLine.Modify(true);

        LibraryUtility.CreateNoSeries(RequestNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, RequestNoSeries.Code, 'IBSREQ0001', 'IBSREQ9999');
        NoSeriesLine.Modify(true);

        ElectronicBankingSetup.Get();
        ElectronicBankingSetup."Summarize Gen. Jnl. Lines" := true;
        ElectronicBankingSetup.Modify(true);

        // Creat epayment journal lines
        // Clear all existing rows
        CustomerPaymentJournalLine.SetRange("Posting Date", WorkDate());
        CustomerPaymentJournalLine.DeleteAll();

        // Create customer and vendor
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        CustomerPaymentJournalLine.Reset();
        CustomerPaymentJournalLine.Init();
        CustomerPaymentJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        CustomerPaymentJournalLine."Journal Batch Name" := PaymJournalBatch.Name;
        CustomerPaymentJournalLine."Line No." := 1;
        CustomerPaymentJournalLine."Account Type" := CustomerPaymentJournalLine."Account Type"::Customer;
        CustomerPaymentJournalLine."Account No." := Customer."No.";
        CustomerPaymentJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        CustomerPaymentJournalLine."Beneficiary Bank Account" := CustomerBankAccount.Code;
        CustomerPaymentJournalLine."Posting Date" := WorkDate();
        CustomerPaymentJournalLine.Insert();

        VendorPaymentJournalLine.Reset();
        VendorPaymentJournalLine.Init();
        VendorPaymentJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        VendorPaymentJournalLine."Journal Batch Name" := PaymJournalBatch.Name;
        VendorPaymentJournalLine."Line No." := 2;
        VendorPaymentJournalLine."Account Type" := VendorPaymentJournalLine."Account Type"::Vendor;
        VendorPaymentJournalLine."Account No." := Vendor."No.";
        VendorPaymentJournalLine.Amount := LibraryRandom.RandDec(1000, 2);
        VendorPaymentJournalLine."Beneficiary Bank Account" := VendorBankAccount.Code;
        VendorPaymentJournalLine."Posting Date" := WorkDate();
        VendorPaymentJournalLine.Insert();

        // Exersice
        Commit();
        FileInternationalPayments.SetFileName(ServerFilename);
        FileInternationalPayments.UseRequestPage(true);
        FileInternationalPayments.Run();

        // Validate
        Assert.IsTrue(FileManagement.ServerFileExists(ServerFilename), 'Expected the report to generate a Server file');
        StringObject := FileObject.ReadAllText(ServerFilename);
        Assert.IsTrue(StringObject.Contains(Customer."No."), 'Expected exported file to contain customer no.');
        Assert.IsTrue(StringObject.Contains(Vendor."No."), 'Expected exported file to contain customer no.');
        Assert.AreEqual(1 + 8 + 8 + 1, FileObject.ReadAllLines(ServerFilename).Length,
          'Expected 1 header, two times 8 journal and 1 footer lines');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileInternationalPaymentsRequestPageHandler(var FileInternationalPayments: TestRequestPage "File International Payments")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.JournalTemplateName.SetValue(VariantValue);
        // Payment Journal Template;
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.JournalBatchName.SetValue(VariantValue);
        // Payment Journal Batch
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.AutomaticPosting.SetValue(VariantValue);
        // Post General Journal Lines
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.IncludeDimText.SetValue(VariantValue);
        // Include Dimensions
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.ExecutionDate.SetValue(VariantValue);
        // Execution Date
        LibraryVariableStorage.Dequeue(VariantValue);
        FileInternationalPayments.InscriptionNo.SetValue(VariantValue);
        // Inscription No.
        FileInternationalPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}