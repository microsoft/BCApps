codeunit 144019 "IT - VAT Rep - Export Unittest"
{
    // // [FEATURE] [VAT Report] [Export]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
        VATReportLineRec: Record "VAT Report Line";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        TransmissionFiles: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        isInitialized: Boolean;
        ConstType: Option FE,FE1,FE2,FR,FR1,FR2,NE,NR,DF,FN,SE,TA,FA,SA,BL,BL1,BL2;
        LineNoCounter: Integer;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN;
        RecordNotFoundErr: Label 'VAT Report Line %1 was not found in the file as a %2 record with the specified identifier: <%3>=<%4>.', Comment = 'VAT Report Line <Line No.> was not found in the file as a <Record Identifier> record with the specified identifier: <BlockKey>=<Value>.';
        BlockValueNotFoundErr: Label 'Block with key %1 did not match the expected value.';
        InvalidRecordIdentifierErr: Label 'No line verification key/value set found for identifier %1.';
        CustomerTotalErr: Label 'The total amount for customer %1 did not match';
        ExpectedErrorFailedErr: Label 'Assert.ExpectedError failed. Expected: %1. Actual: %2.';
        IncorrectEncodingErr: Label 'The encoded value did not match the expected.';
        FormatNumErr: Label 'Value %1 formatted incorrectly.';
        TaxRepresentativeTxt: Label 'Tax Representative';
        QueueUnderflowForNewFileNameErr: Label 'Assert.IsTrue failed. Queue underflow.';
        WrongMaxRecCountErr: Label 'Wrong max record count calculated.';

    local procedure Initialize()
    begin
        TransmissionFiles.Clear();

        if isInitialized then
            exit;

        CreateVATReportSetup(false);
        SetupCompany(false);
        GeneralSetup();
        isInitialized := true;
        Commit();
    end;

    local procedure TearDown()
    begin
        asserterror Error('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FEInvoiceIssued()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify issued invoice is printed correctly
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedMustBePositive()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify issued invoice is printed correctly
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        VATReportLine.Amount := -100;
        VATReportLine.Base := -400;
        VATReportLine.Modify(true);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, -VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedNonDeductAVAT()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, true);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedZeroValue()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify issued invoice is printed correctly
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        VATReportLine.Amount := 0;
        VATReportLine.Modify(false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FRInvoiceReceived()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify received invoice is printed correctly
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FRInvoiceReceivedGrouping()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLineA: Record "VAT Report Line";
        VATReportLineB: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        VendorA: Code[20];
        VendorB: Code[20];
        TextFile: BigText;
    begin
        // Verify received invoice is printed correctly
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        VendorA := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        VendorB := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLineA, VATReportHeader, ConstType::FR, VendorA, false);
        AddVATReportLine(VATReportLineB, VATReportHeader, ConstType::FR, VendorB, false);
        VATReportLineB."Document No." := VATReportLineA."Document No.";
        VATReportLineB.Modify(true);
        VATEntry.Get(VATReportLineB."VAT Entry No.");
        VATEntry."Document No." := VATReportLineA."Document No.";
        VATEntry.Modify(true);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLineA.Type::Purchase, VendorA, -VATReportLineA.Amount);
        VerifyCustomerTotal(TextFile, VATReportLineA.Type::Purchase, VendorB, -VATReportLineB.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedGrouping()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLineA: Record "VAT Report Line";
        VATReportLineB: Record "VAT Report Line";
        VATReportLineC: Record "VAT Report Line";
        VATReportLineD: Record "VAT Report Line";
        VATReportLineE: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        CustA: Code[20];
        VendorB: Code[20];
        TextFile: BigText;
    begin
        // Verify received invoice is printed correctly
        Initialize();
        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustA := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        VendorB := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLineA, VATReportHeader, ConstType::FE, CustA, false);
        AddVATReportLine(VATReportLineB, VATReportHeader, ConstType::FE, CustA, false);
        AddVATReportLine(VATReportLineC, VATReportHeader, ConstType::FE, CustA, false);
        AddVATReportLine(VATReportLineD, VATReportHeader, ConstType::NE, CustA, false);
        AddVATReportLine(VATReportLineE, VATReportHeader, ConstType::FR, VendorB, false);
        VATReportLineB."Document No." := VATReportLineA."Document No.";
        VATReportLineB.Modify(true);
        VATEntry.Get(VATReportLineB."VAT Entry No.");
        VATEntry."Document No." := VATReportLineA."Document No.";
        VATEntry.Modify(true);
        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);
        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLineA.Type::Sale, CustA, VATReportLineA.Amount + VATReportLineB.Amount +
          VATReportLineC.Amount - VATReportLineD.Amount);
        VerifyCustomerTotal(TextFile, VATReportLineA.Type::Purchase, VendorB, -VATReportLineE.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NECreditMemoIssued()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, -VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure NRCreditMemoReceived()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NR, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, CustNo, -VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FNNonResidentInvoices()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::"Non-Resident", true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure SEServicePurchase()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendorNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        VendorNo := LibrarySpesometro.CreateVendor(false, VendorRec.Resident::"Non-Resident", true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendorNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, VendorNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        VATReportLine3: Record "VAT Report Line";
        CustNo: Code[20];
        CustNo2: Code[20];
        TextFile: BigText;
    begin
        // Tests the aggregated export with two customers which should be seperated properly. The order of the VAT Report Line is "scrampled" so the sorting is tested
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        CustNo2 := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::Resident, false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine3, VATReportHeader, ConstType::FE, CustNo2, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount + VATReportLine2.Amount);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo2, VATReportLine3.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FE_NEAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        VATReportLine3: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine3, VATReportHeader, ConstType::NE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(
          TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount + VATReportLine2.Amount - VATReportLine3.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleFAAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        VATReportLine3: Record "VAT Report Line";
        VendorNoA: Code[20];
        VendorNoB: Code[20];
        TextFile: BigText;
    begin
        Initialize();
        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        VendorNoA := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        VendorNoB := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendorNoA, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FR, VendorNoB, false);
        AddVATReportLine(VATReportLine3, VATReportHeader, ConstType::FR, VendorNoB, false);
        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);
        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, VendorNoA, -VATReportLine.Amount);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, VendorNoB, -VATReportLine2.Amount - VATReportLine3.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixedDetailAggregatedCompare()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        VATReportLine3: Record "VAT Report Line";
        VATReportLine4: Record "VAT Report Line";
        CustNo: Code[20];
        CustNo2: Code[20];
        TextFileAgg: BigText;
        TextFileDetailed: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine3, VATReportHeader, ConstType::NE, CustNo, false);
        CustNo2 := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine4, VATReportHeader, ConstType::FE, CustNo2, false);
        AddVATReportLine(VATReportLine4, VATReportHeader, ConstType::FE, CustNo2, false);
        AddVATReportLine(VATReportLine4, VATReportHeader, ConstType::NE, CustNo2, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFileAgg);
        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Modify();
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFileDetailed);

        // Verify
        VerifyStructure(TextFileAgg, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyValue(TextFileAgg, '1', 2, 128, 1, ConstFormat::CB);
        VerifyCustomerTotal(
          TextFileAgg, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount + VATReportLine2.Amount - VATReportLine3.Amount);
        VerifyStructure(TextFileDetailed, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyValue(TextFileDetailed, '1', 2, 129, 1, ConstFormat::CB);
        VerifyCustomerTotal(
          TextFileDetailed, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount + VATReportLine2.Amount - VATReportLine3.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FEInvoiceIssuedIndividual()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::Resident, false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FNNonResidentInvoicesIndividual()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure SEServicePurchaseIndividual()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::"Non-Resident", false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Purchase, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FNNonResidentInvoicesAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure FNSEMixedNonResidentInvoicesAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        CustNo2: Code[20];
        CustNo3: Code[20];
        TextFile: BigText;
        TotalVAT: Decimal;
        TotalVAT2: Decimal;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        CustNo2 := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::"Non-Resident", false, true);
        CustNo3 := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::"Non-Resident", true, false);

        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);
        TotalVAT += VATReportLine.Amount;
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, CustNo2, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);
        TotalVAT += VATReportLine.Amount;
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo3, false);
        TotalVAT2 += VATReportLine.Amount;
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);
        TotalVAT += VATReportLine.Amount;

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, TotalVAT);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo3, TotalVAT2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure MultipleTransmissionFiles()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine, VATReportLine2 : Record "VAT Report Line";
        CustNo: Code[20];
        TextFile1: BigText;
        TextFile2: BigText;
        Index: Integer;
        MaxRecordCount: Integer;
    begin
        Initialize();

        // [GIVEN] VAT Report for a Customer
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);

        MaxRecordCount := GetMaxRecordCount();
        for Index := 1 to MaxRecordCount + 1 do
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // [WHEN] Export VAT Report to flat file
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile1);
        LoadNextFile(TextFile2);

        // [THEN] Verify generated file
        VerifyStructure(TextFile1, VATReportHeader, 1, 2);
        VerifyStructure(TextFile2, VATReportHeader, 2, 2);
        VATReportLine2.Get(VATReportLine."VAT Report No.", MaxRecordCount);
        VerifyExists(TextFile1, VATReportLine2);
        VerifyExists(TextFile2, VATReportLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure MultipleTransmissionFilesMixed()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        FlatFileManagement: Codeunit "Flat File Management";
        CustNo: Code[20];
        CustNo2: Code[20];
        CustNo3: Code[20];
        TextFile1: BigText;
        TextFile2: BigText;
        TextFile3: BigText;
        Index: Integer;
        MaxRecordCount: Integer;
    begin
        Initialize();

        // [GIVEN] VAT Report for 3 Customers
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        CustNo2 := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::"Non-Resident", false, true);
        CustNo3 := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);

        FlatFileManagement.Initialize();

        // [GIVEN] 4 lines in header and footer of VAT Report (A, B, E and Z records)
        FlatFileManagement.SetHeaderFooterRecordCountPerFile(4);

        // [GIVEN] Max number of records, which may be added to report not exceeding 5 MB (MaxRecordCount)
        MaxRecordCount := FlatFileManagement.GetMaxRecordsPerFile();

        // [GIVEN] MaxRecordCount + 1 1st Customer's entries added to report to make it to generate 2 files (1st file is of max size)
        for Index := 1 to MaxRecordCount + 1 do
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // [GIVEN] MaxRecordCount / 2 1st Customer's entries added to report to be added in the 2nd file
        for Index := 1 to (MaxRecordCount div 2) do
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, CustNo, false);

        // [GIVEN] MaxRecordCount / 2 2nd Customer's entries added to report to be added to the 2nd file
        for Index := 1 to (MaxRecordCount div 2) do
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, CustNo2, false);

        // [GIVEN] 3 3rd Customer's entries added to report to finalize the second file and create the 3rd one, while being exported
        for Index := 1 to 3 do
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, CustNo3, false);

        // [WHEN] Export VAT Report to flat file
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile1);
        LoadNextFile(TextFile2);
        LoadNextFile(TextFile3);

        // [THEN] Verify structure of 3 generated files
        VerifyStructure(TextFile1, VATReportHeader, 1, 3);
        VerifyStructure(TextFile2, VATReportHeader, 2, 3);
        VerifyStructure(TextFile3, VATReportHeader, 3, 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure MultipleTransmissionFilesAggregated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
        Index: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::Resident, false, true);
        for Index := 1 to 1600 do begin
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
            TotalAmount += VATReportLine.Amount;
        end;

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, TotalAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure UnicodeCompInfo()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Customer: Record Customer;
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify export is able to handle special characters and convert them accordingly.
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        Customer.Get(CustNo);
        Customer.Validate("Last Name", '!ABC éñÑé¼íéÔ¼¥¢ !"#%&/');
        Customer.Modify(true);
        Assert.AreEqual(LibrarySpesometro.EncodeString(Customer."Last Name"), 'ABC  ', IncorrectEncodingErr);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure PhoneNumberCleaning()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CompanyInfo: Record "Company Information";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify a phone number is "cleaned" correctly, i.e. removing all non-numering characters
        Initialize();

        // Setup
        CompanyInfo.Get();
        CompanyInfo.Validate("Phone No.", '+49 461-123456');
        CompanyInfo.Modify(true);

        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFileAndLoadNextFile(VATReportHeader, true, TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEIdentVatRegNo()
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales invoice for customer (Individual) with VAT Reg. No. is identified by FE001001
        FEIdentVatRegNoHelper(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEIdentVatRegNoNonInd()
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales invoice for customer (non-Individual) with VAT Reg. No. is identified by FE001001

        FEIdentVatRegNoHelper(false);
    end;

    [Scope('OnPrem')]
    procedure FEIdentVatRegNoHelper(Individual: Boolean)
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales invoice for customer (Non-Individual/Individual) with VAT Reg. No. is identified by FE001001
        Initialize();

        // [GIVEN] An individual/non-individual resident customer with VAT Registration No.
        Customer.Get(LibrarySpesometro.CreateCustomer(Individual, Customer.Resident::Resident, true, false));

        // [GIVEN] A VAT Report with a sales invoice (FE) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, Customer."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The VAT Reg. No is exported to FE001001
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FE001001',
          LibrarySpesometro.FormatPadding(ConstFormat::PI, Customer."VAT Registration No.", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEIdentFiscalCode()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales invoice for customer with Fiscal code is identified by FE001002
        Initialize();

        // [GIVEN] An non-individual resident customer without VAT Reg. No. but fiscal code
        Customer.Get(LibrarySpesometro.CreateCustomer(false, Customer.Resident::Resident, false, true));

        // [GIVEN] A VAT Report with a sales invoice (FE) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, Customer."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The Fiscal Code is exported to FE001002
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FE001002',
          LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."Fiscal Code", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FEIdentSummaryDocument()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales invoice for customer without Fiscal code and VAT Reg. No is a summary document
        Initialize();

        // [GIVEN] An non-individual resident customer without VAT Reg. No. but fiscal code
        Customer.Get(LibrarySpesometro.CreateCustomer(false, Customer.Resident::Resident, false, false));

        // [GIVEN] A VAT Report with a sales invoice (FE) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, Customer."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The document is a summary document indicated by FE001003
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FE001003',
          LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FRIdentVatRegNo()
    var
        Vendor: Record Vendor;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Purchase invoice for vendor with VAT Reg. No. is identified by FR001001
        Initialize();

        // [GIVEN] An individual resident vendor with VAT Registration No.
        Vendor.Get(LibrarySpesometro.CreateVendor(true, Vendor.Resident::Resident, true, false));

        // [GIVEN] A VAT Report with a purchase invoice (FR) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, Vendor."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The VAT Reg. No is exported to FR001001
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FR001001',
          LibrarySpesometro.FormatPadding(ConstFormat::PI, Vendor."VAT Registration No.", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FRIdentFiscalCodeOnly()
    var
        Vendor: Record Vendor;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Purchase invoice for vendor without VAT Reg. No. but fiscal which is considered a summary document
        Initialize();

        // [GIVEN] An individual resident vendor with VAT Registration No.
        Vendor.Get(LibrarySpesometro.CreateVendor(true, Vendor.Resident::Resident, false, true));

        // [GIVEN] A VAT Report with a purchase invoice (FR) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, Vendor."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The document is set as a summary document with FR001002
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FR001002',
          LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NEIdentVATRegNo()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales credit-memo for customer with VAT Reg. No is identified by NE001001
        Initialize();

        // [GIVEN] An non-individual resident customer with VAT Reg. No. and Fiscal Code
        Customer.Get(LibrarySpesometro.CreateCustomer(false, Customer.Resident::Resident, true, true));

        // [GIVEN] A VAT Report with a sales credit-memo (NE) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, Customer."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The VAT Reg. No. is exported to NE001001
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'NE001001',
          LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."VAT Registration No.", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NEIdentFiscalCode()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Sales credit-memo for customer without VAT Reg. No. but Fiscal Code is identified by NE001002
        Initialize();

        // [GIVEN] An non-individual resident customer without VAT Reg. No. and with Fiscal Code
        Customer.Get(LibrarySpesometro.CreateCustomer(false, Customer.Resident::Resident, false, true));

        // [GIVEN] A VAT Report with a sales credit-memo (NE) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, Customer."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The Fiscal Code is exported to NE001002
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'NE001002',
          LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."Fiscal Code", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NRIdentVatRegNo()
    var
        Vendor: Record Vendor;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Purchase credit-memo for vendor with VAT Reg. No is identified by NR001001
        Initialize();

        // [GIVEN] An non-individual resident vendor with VAT Reg. No. and Fiscal Code
        Vendor.Get(LibrarySpesometro.CreateVendor(false, Vendor.Resident::Resident, true, true));

        // [GIVEN] A VAT Report with a purchase credit-memo (NR) line
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NR, Vendor."No.", false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The VAT Reg. No. is exported to NR001001
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'NR001001',
          LibrarySpesometro.FormatPadding(ConstFormat::CF, Vendor."VAT Registration No.", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompExtendedVATregNo()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CompanyInfo: Record "Company Information";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        Initialize();

        // Setup
        CompanyInfo.Get();
        CompanyInfo.Validate("VAT Registration No.", 'IT12345678901');
        CompanyInfo.Modify(true);

        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmtpyReport()
    var
        VATReportHeader: Record "VAT Report Header";
        TextFile: BigText;
    begin
        // Verify an empty report is not exportable
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LargeIdentValue()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Test that a block value can exceed 16 characters
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        Customer.Get(CustNo);
        Customer."Last Name" := 'ALong LastNameWithout-Meaning';
        Customer.Modify(true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntermediaryTransaction()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Test that intermediary information is exported correct
        Initialize();
        CreateVATReportSetup(true);

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveReport()
    var
        VATReportHeader: Record "VAT Report Header";
        OrgVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Test that a corrective VAT report can be generated
        Initialize();

        // Setup
        CreateVATReportHeader(OrgVATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        OrgVATReportHeader.Validate("Tax Auth. Receipt No.", '12345');
        OrgVATReportHeader.Validate("Tax Auth. Document No.", '678901');
        OrgVATReportHeader.Modify(true);
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Corrective);
        VATReportHeader."Original Report No." := OrgVATReportHeader."No.";
        VATReportHeader.Modify(true);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectiveReportValidateError()
    var
        VATReportHeader: Record "VAT Report Header";
        OrgVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
    begin
        // Test that a corrective VAT report can be generated
        Initialize();

        // Setup
        CreateVATReportHeader(OrgVATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Corrective);
        VATReportHeader."Original Report No." := OrgVATReportHeader."No.";
        VATReportHeader.Modify(true);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        asserterror ExportToFile(VATReportHeader, true);

        // Verify
        if GetLastErrorText <> '' then
            Error(ExpectedErrorFailedErr, '', GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveReportOriginalReportNo()
    var
        VATReportHeader: Record "VAT Report Header";
        OrgVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Test that a corrective VAT report can be generated
        Initialize();

        // Setup
        CreateVATReportHeader(OrgVATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        OrgVATReportHeader."Tax Auth. Receipt No." := '12345';
        OrgVATReportHeader."Tax Auth. Document No." := '678901';
        OrgVATReportHeader.Modify(true);
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Corrective);
        VATReportHeader."Original Report No." := OrgVATReportHeader."No.";
        VATReportHeader.Modify(true);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellationReport()
    var
        VATReportHeader: Record "VAT Report Header";
        OrgVATReportHeader: Record "VAT Report Header";
        TextFile: BigText;
    begin
        // Test that a cancellation VAT report can be generated
        Initialize();

        // Setup
        CreateVATReportHeader(OrgVATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        OrgVATReportHeader.Validate("Tax Auth. Receipt No.", '12345');
        OrgVATReportHeader."Tax Auth. Document No." := '678901';
        OrgVATReportHeader.Modify(true);

        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::"Cancellation ");
        VATReportHeader."Original Report No." := OrgVATReportHeader."No.";
        VATReportHeader.Modify();

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure SelectiveReport()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine1: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        VATReportLine3: Record "VAT Report Line";
        VATReportLine4: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify only selected lines are exported
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine1, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine3, VATReportHeader, ConstType::FE, CustNo, false);
        AddVATReportLine(VATReportLine4, VATReportHeader, ConstType::FE, CustNo, false);
        VATReportLine2."Incl. in Report" := false;
        VATReportLine2.Modify(true);
        VATReportLine4."Incl. in Report" := false;
        VATReportLine4.Modify(true);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine1);
        VerifyExists(TextFile, VATReportLine3);
        VerifyCustomerTotal(TextFile, VATReportLine1.Type::Sale, CustNo, VATReportLine1.Amount + VATReportLine3.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllCombinationsValidate()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        CustNonInd: Code[20];
        CustInd: Code[20];
        CustNonRes: Code[20];
        CustNonResInd: Code[20];
        VendNonInd: Code[20];
        VendInd: Code[20];
        VendNonRes: Code[20];
        VendNonResInd: Code[20];
        TextFile: BigText;
        Country: Code[10];
    begin
        // Generate a report with all modules and their combinations for the validator tool
        Initialize();
        CompanyInfo.Get();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNonInd := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        Customer.Get(CustNonInd);
        Customer."VAT Registration No." := '02313610129';
        Customer.Modify();

        CustInd := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::Resident, false, true);
        Customer.Get(CustInd);
        Customer."Fiscal Code" := 'VNNLSN74L03L682U';
        Customer.Modify();

        CustNonRes := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::"Non-Resident", true, false);
        CustNonResInd := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);

        VendNonInd := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        Vendor.Get(VendNonInd);
        Vendor."VAT Registration No." := '02313610129';
        Vendor.Modify();

        VendInd := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::Resident, false, true);
        Vendor.Get(VendInd);
        Vendor."Fiscal Code" := 'VNNLSN74L03L682U';
        Vendor.Modify();

        VendNonRes := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::"Non-Resident", false, true);
        VendNonResInd := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::"Non-Resident", false, true);

        // Use a valid country code for all the above
        Country := LibrarySpesometro.GetCountryCode();
        CountryRegion.Get(Country);
        CountryRegion."Foreign Country/Region Code" := '271';
        CountryRegion.Modify();

        // FE invoices
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNonInd, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustInd, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustInd, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNonInd, false);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        VATEntry."VAT Registration No." := CompanyInfo."VAT Registration No.";
        VATEntry.Modify();

        // FR invoices
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendNonInd, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendNonInd, false);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        VATEntry."VAT Registration No." := CompanyInfo."VAT Registration No.";
        VATEntry.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendNonInd, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendNonInd, false);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        VATEntry.Modify();

        // NE credit memos
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, CustNonInd, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NE, CustInd, false);

        // NR credit memos
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NR, VendNonInd, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::NR, VendNonInd, false);

        // FN Invoices
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNonRes, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNonResInd, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustNonRes, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();

        // SE invoices
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendNonRes, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendNonResInd, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendNonRes, false);
        VATReportLine.Base := LibrarySpesometro.GetThresholdAmount() + 1;
        VATReportLine.Amount := VATReportLine.Base * 0.2;
        VATReportLine.Modify();

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify (Lazy, real is done with the validator tool)
        // ftp://ftpentratel2.finanze.it/pub/repos/entratel518_all.exe
        // http://www.agenziaentrate.gov.it/wps/content/Nsilib/Nsi/Home/CosaDeviFare/ComunicareDati/
        // operazioni+rilevanti+fini+Iva/Compilazione+e+invio/Procedura+spesometro/
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SanMarinoValidate()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        VendSanMarino: Code[20];
        VendSanMarinoInd: Code[20];
        TextFile: BigText;
    begin
        // Generate a report with all modules and their combinations for the validator tool
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        if not CountryRegion.Get('SM') then begin
            CountryRegion.Init();
            CountryRegion.Validate(Code, 'SM');
            CountryRegion.Validate("Foreign Country/Region Code", '037');
            CountryRegion.Insert();
        end;

        VendSanMarino := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::"Non-Resident", true, false);
        Vendor.Get(VendSanMarino);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor.Modify();

        VendSanMarinoInd := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::"Non-Resident", false, true);
        Vendor.Get(VendSanMarinoInd);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor."VAT Registration No." := '02860040126';
        Vendor.Modify();

        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendSanMarino, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendSanMarinoInd, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify (Lazy, real is done with the validator tool)
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelfBilled()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // Verify self billed is checked
        Initialize();
        CompanyInfo.Get();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        Customer.Get(CustNo);
        Customer."VAT Registration No." := CompanyInfo."VAT Registration No.";
        Customer.Modify();
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        VerifyCustomerTotal(TextFile, VATReportLine.Type::Sale, CustNo, VATReportLine.Amount);
        Assert.AreEqual(LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16),
          LibrarySpesometro.ReadBlockValue(TextFile, 3, 'FE001006'), StrSubstNo(BlockValueNotFoundErr, 'FE001006'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtInsertNewEntry()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Entry can be inserted into Appointment management if all required fields are filled out
        Initialize();

        // [GIVEN] VAT Report Setup page is opened on Appointment fasttab

        // [WHEN] User tries to insert a new line
        // [WHEN] The line contains App. code, Type, No., Date from and Date to
        // [WHEN] Date From <= Date To
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false),
          CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false),
          CalcDate('<-CM>', WorkDate()), 0D);

        // [THEN] The line is inserted correctly

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtInsertNewEntryMissingData()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Entry cannot be inserted into Appointment management if a required field is not filled out
        Initialize();

        // [GIVEN] VAT Report Setup page is opened on Appointment fasttab

        // [WHEN] User tries to insert a new line
        // [WHEN] The line contains Type, No., Date from and Date to but not App. code
        asserterror LibrarySpesometro.InsertSpesometroAppointment(
            SpesometroAppointment, '', LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false),
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        Assert.ExpectedError(SpesometroAppointment.FieldCaption("Appointment Code"));
        asserterror LibrarySpesometro.InsertSpesometroAppointment(
            SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(), '', CalcDate('<-CM>', WorkDate()),
            CalcDate('<CM>', WorkDate()));
        Assert.ExpectedError(SpesometroAppointment.FieldCaption("Vendor No."));
        asserterror LibrarySpesometro.InsertSpesometroAppointment(
            SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
            LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), 0D, CalcDate('<CM>', WorkDate()));
        Assert.ExpectedError(SpesometroAppointment.FieldCaption("Starting Date"));

        // [WHEN] Date From <= Date To
        asserterror LibrarySpesometro.InsertSpesometroAppointment(
            SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
            LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), CalcDate('<CM>', WorkDate()),
            CalcDate('<-CM>', WorkDate()));

        // [THEN] An error is generated stating App. Code is required

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtDateToFrom()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Date From has to be before or equal to the Date To in Appointment Management
        Initialize();

        // [GIVEN] A valid entry in "Spesometro Appointment" exists
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false),
          CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [WHEN] The Date To is changed to a value before Date From
        asserterror SpesometroAppointment.Validate("Ending Date", CalcDate('<-1D>', SpesometroAppointment."Starting Date"));

        // [THEN] An error is thrown that the Date To has to be equal or greater than Date From

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtFetchVendorInfoResident()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        FieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Vendor information is fetched through "Spesometro Appointment" table
        Initialize();

        // [GIVEN] A "Spesometro Appointment" record with Type = Vendor and No. = "Some vendor"
        VendorNo := LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true);
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(), VendorNo, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [WHEN] The function GetAppointmentData(key) is called on the record
        // [WHEN] Key is in the valid range (e.g. VAT Registration No., Fiscal code, First name etc).
        Vendor.Get(VendorNo);
        Assert.AreEqual(Vendor."First Name", SpesometroAppointment.GetValueOf(FieldName::"First Name"), '');
        Assert.AreEqual(Vendor."Last Name", SpesometroAppointment.GetValueOf(FieldName::"Last Name"), '');
        if Vendor.Gender = Vendor.Gender::Male then
            Assert.AreEqual('M', SpesometroAppointment.GetValueOf(FieldName::Gender), '')
        else
            Assert.AreEqual('F', SpesometroAppointment.GetValueOf(FieldName::Gender), '');
        Assert.AreEqual(
          LibrarySpesometro.FormatDate(Vendor."Date of Birth", ConstFormat::DT),
          SpesometroAppointment.GetValueOf(FieldName::"Date of Birth"), '');
        Assert.AreEqual(Vendor."Birth City", SpesometroAppointment.GetValueOf(FieldName::Municipality), '');
        Assert.AreEqual(Vendor."Birth County", SpesometroAppointment.GetValueOf(FieldName::Province), '');
        Assert.AreEqual(Vendor."Fiscal Code", SpesometroAppointment.GetValueOf(FieldName::"Fiscal Code"), '');

        // [THEN] The returned data is fetched from the Vendor table for the given vendor

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtFetchVendorInfoNonResident()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        VendorNo: Code[20];
        FieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Vendor information is fetched through "Spesometro Appointment" table
        Initialize();

        // [GIVEN] A "Spesometro Appointment" record with Type = Vendor and No. = "Some vendor"
        VendorNo := LibrarySpesometro.CreateVendor(true, VendorRec.Resident::"Non-Resident", false, true);
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(), VendorNo,
          CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [WHEN] The function GetAppointmentData(key) is called on the record
        // [WHEN] Key is in the valid range (e.g. VAT Registration No., Fiscal code, First name etc).

        // [THEN] The returned data is fetched from the Vendor table for the given vendor
        Vendor.Get(VendorNo);
        CountryRegion.Get(Vendor."Birth Country/Region Code");
        Assert.AreEqual(Vendor."First Name", SpesometroAppointment.GetValueOf(FieldName::"First Name"), '');
        Assert.AreEqual(Vendor."Last Name", SpesometroAppointment.GetValueOf(FieldName::"Last Name"), '');
        if Vendor.Gender = Vendor.Gender::Male then
            Assert.AreEqual('M', SpesometroAppointment.GetValueOf(FieldName::Gender), '')
        else
            Assert.AreEqual('F', SpesometroAppointment.GetValueOf(FieldName::Gender), '');
        Assert.AreEqual(
          LibrarySpesometro.FormatDate(Vendor."Date of Birth", ConstFormat::DT),
          SpesometroAppointment.GetValueOf(FieldName::"Date of Birth"), '');
        Assert.AreEqual(CountryRegion."Foreign Country/Region Code", SpesometroAppointment.GetValueOf(FieldName::Municipality), '');
        Assert.AreEqual('EE', SpesometroAppointment.GetValueOf(FieldName::Province), '');
        Assert.AreEqual(Vendor."Fiscal Code", SpesometroAppointment.GetValueOf(FieldName::"Fiscal Code"), '');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointMgtDeleteEntry()
    var
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] The user is able to delete an "Spesometro Appointment" record
        Initialize();

        // [GIVEN] VAT Report Setup page is opened on Appointment fasttab
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false),
          CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [WHEN] User deletes a record
        SpesometroAppointment.Delete();

        // [THEN] The record is deleted

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpNoInRange()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment: Record "Spesometro Appointment";
        TextFile: BigText;
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; No appointment in the date range
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<-CM-1M>', WorkDate());
        DateSpec1End := CalcDate('<CM-1M>', WorkDate());
        DateSpec2Start := CalcDate('<-CM+1M>', WorkDate());
        DateSpec2End := CalcDate('<CM+1M>', WorkDate());

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B < X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec2Start, DateSpec2End);

        // [GIVEN] Company does NOT use Tax Representative

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-B50 are blank / null
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::CF, '', 16), 2, 394, 16, ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::NUp, '0', 2), 2, 410, 2, ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 420, 8, ConstFormat::DT); // B44 Ending Date

        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 24), 2, 428, 24, ConstFormat::AN); // B45 First Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 20), 2, 452, 20, ConstFormat::AN); // B46 Last Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 1), 2, 472, 1, ConstFormat::AN); // B47 Gender
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 473, 8, ConstFormat::DT); // B48 Date of Birth
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 40), 2, 481, 40, ConstFormat::AN); // B49 Municipality
        LibrarySpesometro.VerifyValue(TextFile, '  ', 2, 521, 2, ConstFormat::PN); // B50 Province

        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 60), 2, 523, 60, ConstFormat::AN); // B51 Designation

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpTaxRepreFallbackInd()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment: Record "Spesometro Appointment";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        TextFile: BigText;
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; No appointment in the date range, with Ind. Tax Representative
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<-CM-1M>', WorkDate());
        DateSpec1End := CalcDate('<CM-1M>', WorkDate());
        DateSpec2Start := CalcDate('<-CM+1M>', WorkDate());
        DateSpec2End := CalcDate('<CM+1M>', WorkDate());

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B < X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec2Start, DateSpec2End);

        // [GIVEN] Company does use Individual Tax Representative
        Vendor.Get(LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true));

        CompanyInformation.Get();
        CompanyInformation."Tax Representative No." := Vendor."No.";
        CompanyInformation.Modify();

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-B44 are filled with information about the Tax Representative
        // [THEN] B42 uses a code that represent Tax Representative
        // [THEN] B43-44 are filled with the date range of the report
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, Vendor."Fiscal Code", 16), 2, 394, 16, ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::NUp, '06', 2), 2, 410, 2, ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatDate(VATReportHeader."Start Date", ConstFormat::DT), 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 420, 8, ConstFormat::DT); // B44 Ending Date

        // [THEN] B45-50 are filled with data from the Tax Representative Vendor card
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, Vendor."First Name", 24), 2, 428, 24, ConstFormat::AN); // B45 First Name
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, Vendor."Last Name", 20), 2, 452, 20, ConstFormat::AN); // B46 Last Name
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, 'M', 1), 2, 472, 1, ConstFormat::AN); // B47 Gender
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatDate(Vendor."Date of Birth", ConstFormat::DT), 2, 473, 8, ConstFormat::DT); // B48 Date of Birth
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, Vendor."Birth City", 40), 2, 481, 40, ConstFormat::AN); // B49 Municipality
        LibrarySpesometro.VerifyValue(TextFile, Vendor."Birth County", 2, 521, 2, ConstFormat::PN); // B50 Province

        // [THEN] 51 is blank because the Vendor is an individual
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 60), 2, 523, 60, ConstFormat::AN); // B51 Designation

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpTaxRepreFallbackNonInd()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment: Record "Spesometro Appointment";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        TextFile: BigText;
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; No appointment in the date range, with Non-ind. Tax Representative
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<-CM-1M>', WorkDate());
        DateSpec1End := CalcDate('<CM-1M>', WorkDate());
        DateSpec2Start := CalcDate('<-CM+1M>', WorkDate());
        DateSpec2End := CalcDate('<CM+1M>', WorkDate());

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B < X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec2Start, DateSpec2End);

        // [GIVEN] Company does use Non-individual Tax Representative
        Vendor.Get(LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false));
        Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor);
        Vendor.Modify();

        CompanyInformation.Get();
        CompanyInformation."Tax Representative No." := Vendor."No.";
        CompanyInformation.Modify();

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-B44 are filled with information about the Tax Representative
        // [THEN] B42 uses a code that represent Tax Representative
        // [THEN] B43-44 are filled with the date range of the report
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::CF, Vendor."Fiscal Code", 16), 2, 394, 16, ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::NUp, '06', 2), 2, 410, 2, ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatDate(VATReportHeader."Start Date", ConstFormat::DT), 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 420, 8, ConstFormat::DT); // B44 Ending Date

        // [THEN] B45-50 are blank
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 24), 2, 428, 24, ConstFormat::AN); // B45 First Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 20), 2, 452, 20, ConstFormat::AN); // B46 Last Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 1), 2, 472, 1, ConstFormat::AN); // B47 Gender
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 473, 8, ConstFormat::DT); // B48 Date of Birth
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 40), 2, 481, 40, ConstFormat::AN); // B49 Municipality
        LibrarySpesometro.VerifyValue(TextFile, '  ', 2, 521, 2, ConstFormat::PN); // B50 Province

        // [THEN] 51 is needed because the Vendor is a non-individual
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, TaxRepresentativeTxt, 60), 2, 523, 60, ConstFormat::AN); // B51 Designation

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpOneInRangeInd()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment1: Record "Spesometro Appointment";
        SpesometroAppointment2: Record "Spesometro Appointment";
        TextFile: BigText;
        AppointmentFieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; One Appointment in range, individual
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<-1D>', DateVATStart);
        DateSpec1End := CalcDate('<+1D>', DateVATStart);
        DateSpec2Start := CalcDate('<+1D>', DateVATEnd);
        DateSpec2End := 0D;

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B > X and A < X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment1, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true), DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment2, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true), DateSpec2Start, DateSpec2End);

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-50 is filled with information from "Spesometro Appointment" for record (A-B)
        LibrarySpesometro.VerifyValue(
          TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"Fiscal Code"), 16), 2,
          394, 16,
          ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::NUp, SpesometroAppointment1."Appointment Code", 2), 2, 410, 2,
          ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatDate(SpesometroAppointment1."Starting Date", ConstFormat::DT), 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatDate(SpesometroAppointment1."Ending Date", ConstFormat::DT), 2, 420, 8, ConstFormat::DT); // B44 Ending Date
        LibrarySpesometro.VerifyValue(
          TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"First Name"), 24), 2,
          428, 24,
          ConstFormat::AN); // B45 First Name
        LibrarySpesometro.VerifyValue(
          TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::AN, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"Last Name"), 20), 2,
          452, 20,
          ConstFormat::AN); // B46 Last Name
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, SpesometroAppointment1.GetValueOf(AppointmentFieldName::Gender), 1),
          2, 472, 1,
          ConstFormat::AN); // B47 Gender
        LibrarySpesometro.VerifyValue(
          TextFile, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"Date of Birth"), 2, 473, 8, ConstFormat::DT); // B48 Date of Birth
        LibrarySpesometro.VerifyValue(
          TextFile, SpesometroAppointment1.GetValueOf(AppointmentFieldName::Municipality), 2, 481, 40, ConstFormat::AN); // B49 Municipality
        LibrarySpesometro.VerifyValue(
          TextFile, SpesometroAppointment1.GetValueOf(AppointmentFieldName::Province), 2, 521, 2, ConstFormat::PN); // B50 Province

        // [THEN] 51 is blank because the Vendor is an individual
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 60), 2, 523, 60, ConstFormat::AN); // B51 Designation

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpOneInRangeNonInd()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment1: Record "Spesometro Appointment";
        SpesometroAppointment2: Record "Spesometro Appointment";
        Vendor: Record Vendor;
        TextFile: BigText;
        AppointmentFieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; One Appointment in range, Non-individual
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<+1D>', DateVATStart);
        DateSpec1End := CalcDate('<+1D>', DateVATStart);
        DateSpec2Start := CalcDate('<+1D>', DateVATEnd);
        DateSpec2End := 0D;

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        Vendor.Get(LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false));
        Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor);
        Vendor.Modify();

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B > X and A > X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment1, LibrarySpesometro.CreateAppointmentCode(), Vendor."No.", DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment2, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(false, VendorRec.Resident::Resident, true, false), DateSpec2Start,
          DateSpec2End);

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-44 is filled with information from "Spesometro Appointment" for record (A-B)
        LibrarySpesometro.VerifyValue(
          TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"Fiscal Code"), 16), 2,
          394, 16,
          ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::NUp, SpesometroAppointment1."Appointment Code", 2), 2, 410, 2,
          ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatDate(SpesometroAppointment1."Starting Date", ConstFormat::DT), 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatDate(SpesometroAppointment1."Ending Date", ConstFormat::DT), 2, 420, 8, ConstFormat::DT); // B44 Ending Date

        // [THEN] Fields B45-50 are blank
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 24), 2, 428, 24, ConstFormat::AN); // B45 First Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 20), 2, 452, 20, ConstFormat::AN); // B46 Last Name
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 1), 2, 472, 1, ConstFormat::AN); // B47 Gender
        LibrarySpesometro.VerifyValue(TextFile, '00000000', 2, 473, 8, ConstFormat::DT); // B48 Date of Birth
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, '', 40), 2, 481, 40, ConstFormat::AN); // B49 Municipality
        LibrarySpesometro.VerifyValue(TextFile, '  ', 2, 521, 2, ConstFormat::PN); // B50 Province

        // [THEN] 51 is needed because the Vendor is a non-individual
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::AN, SpesometroAppointment1.Designation, 60), 2, 523, 60, ConstFormat::AN); // B51 Designation

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointExpMultipleInRange()
    var
        VATReportHeader: Record "VAT Report Header";
        SpesometroAppointment1: Record "Spesometro Appointment";
        SpesometroAppointment2: Record "Spesometro Appointment";
        TextFile: BigText;
        AppointmentFieldName: Option "First Name","Last Name",Gender,"Date of Birth",Municipality,Province,"Fiscal Code";
        DateVATStart: Date;
        DateVATEnd: Date;
        DateSpec1Start: Date;
        DateSpec1End: Date;
        DateSpec2Start: Date;
        DateSpec2End: Date;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Appointment data can be fetched during export; Multiple Appointment records in range
        Initialize();

        DateVATStart := CalcDate('<-CM>', WorkDate());
        DateVATEnd := CalcDate('<CM>', WorkDate());
        DateSpec1Start := CalcDate('<-1D>', DateVATStart);
        DateSpec1End := CalcDate('<+1D>', DateVATStart);
        DateSpec2Start := CalcDate('<-1D>', DateVATEnd);
        DateSpec2End := CalcDate('<+1D>', DateVATEnd);

        // [GIVEN] A VAT Report ready to be exported for date range X-Y
        CreateVATReport(VATReportHeader, DateVATStart, DateVATEnd);

        // [GIVEN] A "Spesometro Appointment" record in the range A-B, where B > X and A <= X
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment1, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true), DateSpec1Start, DateSpec1End);

        // [GIVEN] A "Spesometro Appointment" record in the range C-D, where C < Y and D > Y
        LibrarySpesometro.InsertSpesometroAppointment(
          SpesometroAppointment2, LibrarySpesometro.CreateAppointmentCode(),
          LibrarySpesometro.CreateVendor(true, VendorRec.Resident::Resident, false, true), DateSpec2Start, DateSpec2End);

        // [WHEN] The file is exported
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] Fields B41-44 is filled with information from "Spesometro Appointment" for record (A-B) (The first it found)
        LibrarySpesometro.VerifyValue(
          TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, SpesometroAppointment1.GetValueOf(AppointmentFieldName::"Fiscal Code"), 16), 2,
          394, 16,
          ConstFormat::CF); // B41 Fiscal Code
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::NUp, SpesometroAppointment1."Appointment Code", 2), 2, 410, 2, ConstFormat::NU); // B42 Appointment Code
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatDate(SpesometroAppointment1."Starting Date", ConstFormat::DT), 2, 412, 8, ConstFormat::DT); // B43 Starting Date
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatDate(SpesometroAppointment1."Ending Date", ConstFormat::DT), 2, 420, 8, ConstFormat::DT); // B44 Ending Date

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntermediaryNonEmptyVATRegNo()
    var
        VATReportHeader: Record "VAT Report Header";
        CompanyInformation: Record "Company Information";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] A non-empty "VAT Report Setup"."Intermediary VAT Registration No." results in a intermediary submission
        Initialize();

        // [GIVEN] "VAT Report Setup"."Intermediary VAT Registration No." is not empty
        VATReportSetup."Intermediary VAT Reg. No." :=
          LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Intermediary VAT Reg. No."), DATABASE::"VAT Report Setup");
        VATReportSetup.Modify();

        // [WHEN] A VAT Report is exported
        CreateVATReport(VATReportHeader, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The file is generated
        // [THEN] Field A4 is 10 and A5 contains the value from "VAT Report Setup"."Intermediary VAT Registration No."
        LibrarySpesometro.VerifyValue(TextFile, '10', 1, 21, 2, ConstFormat::NU); // A4 Type of Declarer
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, VATReportSetup."Intermediary VAT Reg. No.", 16), 1, 23, 16, ConstFormat::CF); // A5 Declarer's fiscal code

        // [THEN] Field B52 contains the value from "VAT Report Setup"."Intermediary VAT Registration No."
        LibrarySpesometro.VerifyValue(TextFile,
          LibrarySpesometro.FormatPadding(ConstFormat::CF, VATReportSetup."Intermediary VAT Reg. No.", 16), 2, 583, 16, ConstFormat::CF); // B52 Declarer's fiscal code

        // [THEN] Field B2, C2, E2 contains company's "Fiscal Code"
        // [THEN] Field D2 contains company's "VAT Registration No."
        CompanyInformation.Get();
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::CF, GetCompanyRegNo(), 16), 2, 2, 16, ConstFormat::CF); // B2
        // "C" record is not exported
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::CF, CompanyInformation.GetTaxCode(), 16), 3, 2, 16, ConstFormat::CF); // D2
        LibrarySpesometro.VerifyValue(
          TextFile, LibrarySpesometro.FormatPadding(ConstFormat::CF, GetCompanyRegNo(), 16), 4, 2, 16, ConstFormat::CF); // E2

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntermediaryOptionalCAFRegNoDate()
    var
        VATReportHeader: Record "VAT Report Header";
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] Intermediary CAF Reg. No. is optional
        Initialize();

        // [GIVEN] "VAT Report Setup"."Intermediary VAT Registration No." is not empty
        VATReportSetup."Intermediary VAT Reg. No." :=
          LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Intermediary VAT Reg. No."), DATABASE::"VAT Report Setup");

        // [GIVEN] "VAT Report Setup"."Intermediary CAF Reg No." is empty
        VATReportSetup."Intermediary CAF Reg. No." := '';
        VATReportSetup.Modify();

        // [WHEN] A VAT Report is exported
        CreateVATReport(VATReportHeader, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] No error is thrown
        // [THEN] The file is generated with field B53 blank
        LibrarySpesometro.VerifyValue(TextFile, LibrarySpesometro.FormatPadding(ConstFormat::NUp, '', 5), 2, 599, 5, ConstFormat::NU); // B53

        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SummaryDocumentRecordE()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLineA: Record "VAT Report Line";
        VATReportLineB: Record "VAT Report Line";
        VendorNo: Code[20];
        VendorNo2: Code[20];
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] BUG101089: Differentiate between purchase invoices received and summary documents declared
        Initialize();

        // [GIVEN] A VAT Report
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);

        // [GIVEN] A Purchase VAT entry without VAT Registration No.
        VendorNo := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, false, false);
        AddVATReportLine(VATReportLineA, VATReportHeader, ConstType::FR, VendorNo, false);

        // [GIVEN] A Purchase VAT entry with VAT registration No.
        VendorNo2 := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLineB, VATReportHeader, ConstType::FR, VendorNo2, false);

        // [WHEN] The report is exported in detailed mode
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // [THEN] The file is valid
        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        // [THEN] Number of summary purchase document (TA005002) is 1
        LibrarySpesometro.VerifyBlockValue(TextFile, 5, 'TA005002', LibrarySpesometro.FormatPadding(ConstFormat::NP, '1', 16), false, true);

        // [THEN] Number of non-summary purchase documents (TA005001) is 1
        LibrarySpesometro.VerifyBlockValue(TextFile, 5, 'TA005001', LibrarySpesometro.FormatPadding(ConstFormat::NP, '1', 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndividualVendorFiscalCode()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] BUG101094: An individual vendors VAT reg. no exported to FA001001
        Initialize();

        // [GIVEN] A VAT Report
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);

        // [GIVEN] A Purchase VAT entry for an resident, individual vendor with VAT Reg. No and Fiscal Code
        VendorNo := LibrarySpesometro.CreateVendor(true, CustomerRec.Resident::Resident, true, true);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, VendorNo, false);
        Vendor.Get(VendorNo);

        // [WHEN] The report is exported in aggregated mode
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // [THEN] The file is valid
        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        // [THEN] TA001001 is filled with VAT Reg. No.
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FA001001',
          LibrarySpesometro.FormatPadding(ConstFormat::PI, Vendor."VAT Registration No.", 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SummaryDocumentAggregateCount()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile: BigText;
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] BUG101095: Aggregate count should work even with summary documents
        Initialize();

        // [GIVEN] A VAT Report
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);

        // [GIVEN] A Purchase VAT entry (not summary)
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // [WHEN] The report is exported in aggregated mode
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // [THEN] The file is valid
        VerifyStructure(TextFile, VATReportHeader, 1, 1);

        // [THEN] TA001001 is 1 as no summary documents are present
        LibrarySpesometro.VerifyBlockValue(TextFile, 4, 'TA001001', LibrarySpesometro.FormatPadding(ConstFormat::NP, '1', 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpesometroTypeMapVATReport()
    var
        SpesometroExport: Codeunit "Spesometro Export";
    begin
        // [FEATURE] Appointment / Intermediary / Spesometro unification
        // [SCENARIO] VAT Report communication type is mapped to Spesometro file format

        // [GIVEN] An unknown VAT Report report type
        // [WHEN] The VAT Report spesometro mapping function is called
        asserterror SpesometroExport.MapVATReportType(5);

        // [THEN] An error is thrown
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNum()
    var
        ExportVATTransactions: Report "Export VAT Transactions";
        FormattedValue: Text;
        Values: array[2] of Decimal;
        Options: array[2] of Option;
        ValueIndex: Integer;
        OptionIndex: Integer;
        ExpectedValue: Text;
    begin
        Values[1] := LibraryRandom.RandDec(99, 2) / 200; // less than 0.5
        Values[2] := -LibraryRandom.RandDec(99, 2) / 200; // greater than -0.5
        Options[1] := ConstFormat::NP;
        Options[2] := ConstFormat::NU;

        for ValueIndex := 1 to ArrayLen(Values) do
            for OptionIndex := 1 to ArrayLen(Options) do begin
                FormattedValue := ExportVATTransactions.FormatNum(Values[ValueIndex], Options[OptionIndex]);
                ExpectedValue := '1';
                if (Options[OptionIndex] = ConstFormat::NU) and (Values[ValueIndex] < 0) then
                    ExpectedValue := '-1';
                Assert.AreEqual(ExpectedValue, FormattedValue, StrSubstNo(FormatNumErr, Values[ValueIndex]));
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBase()
    begin
        Initialize();

        RunCheckBaseScenario(ConstType::FE, 'FE001012', true);
        RunCheckBaseScenario(ConstType::FR, 'FR001010', false);
        RunCheckBaseScenario(ConstType::NE, 'NE001008', true);
        RunCheckBaseScenario(ConstType::NR, 'NR001006', false);
        RunCheckBaseScenario(ConstType::FN, 'FN001017', true);
        RunCheckBaseScenario(ConstType::SE, 'SE001017', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonResidentCustomerBlankVATId()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        CustomerNo: Code[20];
        TextFile: BigText;
    begin
        // Verify self billed is checked
        Initialize();
        CompanyInfo.Get();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustomerNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);
        Customer.Get(CustomerNo);
        CountryRegion.Get(Customer."Country/Region Code");
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FN, CustomerNo, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        Assert.AreEqual(LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
          LibrarySpesometro.ReadBlockValue(TextFile, 3, 'BL001006'), StrSubstNo(BlockValueNotFoundErr, 'BL001006'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonResidentVendorBlankVATId()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        VendorNo: Code[20];
        TextFile: BigText;
    begin
        // Verify self billed is checked
        Initialize();
        CompanyInfo.Get();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        VendorNo := LibrarySpesometro.CreateVendor(true, VendorRec.Resident::"Non-Resident", false, true);
        Vendor.Get(VendorNo);
        CountryRegion.Get(Vendor."Country/Region Code");
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::SE, VendorNo, false);

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        Assert.AreEqual(LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
          LibrarySpesometro.ReadBlockValue(TextFile, 3, 'BL001006'), StrSubstNo(BlockValueNotFoundErr, 'BL001006'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcccountPurchaseVATEntryExportDetailed()
    begin
        GLAcccountVATEntryExportDetailed(ConstType::FR, 'FR001002');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcccountSalesVATEntryExportDetailed()
    begin
        GLAcccountVATEntryExportDetailed(ConstType::FE, 'FE001003');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAcccountVATEntriesExportAggregate()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
        Index: Integer;
    begin
        // Verify self billed is checked
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);

        AddGLAccountVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, LibraryUtility.GenerateGUID());
        Index := LibraryRandom.RandIntInRange(5, 10);
        while Index > 0 do begin
            AddGLAccountVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, '');
            Index -= 1;
        end;

        AddGLAccountVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, LibraryUtility.GenerateGUID());
        Index := LibraryRandom.RandIntInRange(5, 10);
        while Index > 0 do begin
            AddGLAccountVATReportLine(VATReportLine, VATReportHeader, ConstType::FR, '');
            Index -= 1;
        end;

        // Exercise
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, 'FA001003',
          LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AggregatedVATReportDetailedForNonResidentCustomers()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine1: Record "VAT Report Line";
        VATReportLine2: Record "VAT Report Line";
        CustNo1: Code[20];
        CustNo2: Code[20];
        TextFile: BigText;
    begin
        // [FEATURE] [SALES]
        // [SCENARIO 363440] Aggregated VAT Report for non-resident Customers creates detailed lines for each customers
        Initialize();

        // [GIVEN] 2 Non-resident customers with empty VAT Registration No. and Fiscal Code
        CustNo1 := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, false);
        CustNo2 := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, false);

        // [GIVEN] VAT Report Document with 2 lines for 2 non-resident Customers
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddVATReportLine(VATReportLine1, VATReportHeader, ConstType::FN, CustNo1, false);
        AddVATReportLine(VATReportLine2, VATReportHeader, ConstType::FN, CustNo2, false);

        // [WHEN] Export aggregated VAT Report
        ExportToFile(VATReportHeader, false);
        LoadNextFile(TextFile);

        // [THEN] VAT Report has detailed lines for each customer
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyCustomerTotal(TextFile, VATReportLine1.Type::Sale, CustNo1, VATReportLine1.Amount);
        VerifyCustomerTotal(TextFile, VATReportLine2.Type::Sale, CustNo2, VATReportLine2.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransmissionFileOfMaxSize()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
        TextFile1: BigText;
        TextFile2: BigText;
        Index: Integer;
        MaxRecordCount: Integer;
    begin
        // [SCENARIO 378693] VAT Report containing maximum number of lines calculated by Flat File Management should be exported to 1 file
        Initialize();

        // [GIVEN] VAT Report for a Customer
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::"Non-Resident", false, true);

        // [GIVEN] Created max number of Report lines (calculated according to the limit of 5MB and fixed line size of 1900 symbols. Is 2759 in this case.)
        MaxRecordCount := GetMaxRecordCount();
        for Index := 1 to MaxRecordCount do // MaxRecordCount
            AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);

        // [WHEN] Export VAT Report to flat file
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile1);

        // [THEN] Only one file is generated (only one file was added to export queue)
        asserterror LoadNextFile(TextFile2);
        Assert.ExpectedError(QueueUnderflowForNewFileNameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxRecordsPerFile()
    var
        FlatFileManagement: Codeunit "Flat File Management";
        HeaderAndFooterSize: Integer;
        MaxRecordCount: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378693] The maximum of 2759 lines of 1900 symbols should be allowed for VAT Report without header and footer to not exceed 5 MB

        FlatFileManagement.Initialize();
        HeaderAndFooterSize := LibraryRandom.RandInt(2760) - 1;
        FlatFileManagement.SetHeaderFooterRecordCountPerFile(HeaderAndFooterSize);
        MaxRecordCount := FlatFileManagement.GetMaxRecordsPerFile();
        Assert.AreEqual(2759 - HeaderAndFooterSize, MaxRecordCount, WrongMaxRecCountErr);
    end;

    local procedure VerifyStructure(var TextFile: BigText; VATReportHeader: Record "VAT Report Header"; TransNo: Integer; TotalTransNo: Integer)
    var
        SpesometroExport: Codeunit "Spesometro Export";
        VATReportType: Option;
    begin
        VATReportType := SpesometroExport.MapVATReportType(VATReportHeader."VAT Report Type");
        LibrarySpesometro.VerifyStructure(TextFile, VATReportType, TransNo, TotalTransNo,
          VATReportHeader."Original Report No.", VATReportHeader."Start Date", VATReportHeader."End Date");
    end;

    local procedure CreateVATReportSetup(UseIntermediary: Boolean)
    begin
        if not VATReportSetup.Get() then
            VATReportSetup.Insert(true);

        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());

        if UseIntermediary then begin
            VATReportSetup.Validate("Intermediary VAT Reg. No.", Format(LibraryRandom.RandInt(100)));
            VATReportSetup.Validate("Intermediary CAF Reg. No.", '');
            VATReportSetup.Validate("Intermediary Date", CalcDate('<-3M>', Today));
        end else begin
            VATReportSetup.Validate("Intermediary VAT Reg. No.", '');
            VATReportSetup.Validate("Intermediary CAF Reg. No.", Format(LibraryRandom.RandInt(100)));
            VATReportSetup.Validate("Intermediary Date", 0D);
        end;
        VATReportSetup.Validate("Modify Submitted Reports", false);
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATReport(var VATReportHeader: Record "VAT Report Header"; StartDate: Date; EndDate: Date)
    var
        VATReportLine: Record "VAT Report Line";
        CustNo: Code[20];
    begin
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        CustNo := LibrarySpesometro.CreateCustomer(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, ConstType::FE, CustNo, false);
        VATReportHeader.Validate("Start Date", StartDate);
        VATReportHeader.Validate("End Date", EndDate);
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; ReportType: Option)
    begin
        VATReportHeader.Init();
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report");
        VATReportHeader.Validate("VAT Report Type", ReportType);
        VATReportHeader.Modify(true);
        LineNoCounter := 0;
    end;

    local procedure AddVATReportLine(var VATReportLine: Record "VAT Report Line"; var VATReportHeader: Record "VAT Report Header"; LineType: Option; CustNo: Code[20]; NonDeductableVAT: Boolean)
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
        NewEntryNo: Integer;
    begin
        VATEntry.FindLast();
        NewEntryNo := VATEntry."Entry No." + 1;

        VATEntry.Init();
        VATEntry."Entry No." := NewEntryNo;
        VATEntry."Posting Date" := CalcDate('<-2D>', Today);
        VATEntry."Document Date" := VATEntry."Posting Date";
        if LineType in [ConstType::FE, ConstType::NE, ConstType::FN] then
            VATEntry.Type := VATEntry.Type::Sale
        else
            VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Document No." := Format(LibraryRandom.RandInt(999999));
        VATEntry."Bill-to/Pay-to No." := CustNo;
        if VATEntry.Type = VATEntry.Type::Sale then begin
            Customer.Get(CustNo);
            VATEntry."VAT Registration No." := Customer."VAT Registration No.";
            VATEntry."Country/Region Code" := Customer."Country/Region Code";
            VATEntry."First Name" := Customer."First Name";
            VATEntry."Last Name" := Customer."Last Name";
            VATEntry."Date of Birth" := Customer."Date of Birth";
            VATEntry."Individual Person" := Customer."Individual Person";
            VATEntry.Resident := Customer.Resident;
            VATEntry."Fiscal Code" := Customer."Fiscal Code";
            VATEntry."Place of Birth" := Customer."Place of Birth";
        end else begin
            Vendor.Get(CustNo);
            VATEntry."VAT Registration No." := Vendor."VAT Registration No.";
            VATEntry."Country/Region Code" := Vendor."Country/Region Code";
            VATEntry."First Name" := Vendor."First Name";
            VATEntry."Last Name" := Vendor."Last Name";
            VATEntry."Date of Birth" := Vendor."Date of Birth";
            VATEntry."Individual Person" := Vendor."Individual Person";
            VATEntry.Resident := Vendor.Resident;
            VATEntry."Fiscal Code" := Vendor."Fiscal Code";
            VATEntry."Place of Birth" := Vendor."Birth City";
        end;
        if NonDeductableVAT then
            VATEntry."Deductible %" := 0
        else
            VATEntry."Deductible %" := 100;
        VATEntry.Base := LibraryRandom.RandDec(LibrarySpesometro.GetThresholdAmount(), 2);
        VATEntry.Amount := (VATEntry.Base / 100 * LibraryRandom.RandIntInRange(1, 21)) / 100 * VATEntry."Deductible %";
        VATEntry.Insert(false);

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeader."No.";
        VATReportLine."Posting Date" := VATEntry."Posting Date";
        VATReportLine."Document No." := VATEntry."Document No.";
        VATReportLine."Line No." := GetNextLineNo();
        VATReportLine.Type := VATEntry.Type;
        VATReportLine.Base := VATEntry.Base;
        VATReportLine.Amount := VATEntry.Amount;
        VATReportLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
        VATReportLine."Country/Region Code" := VATEntry."Country/Region Code";
        VATReportLine."VAT Registration No." := VATEntry."VAT Registration No.";
        ConstType := LineType;
        VATReportLine."Record Identifier" := Format(ConstType);
        VATReportLine."Operation Occurred Date" := VATEntry."Operation Occurred Date";
        VATReportLine."Amount Incl. VAT" := VATReportLine.Base + VATReportLine.Amount;
        VATReportLine."VAT Entry No." := VATEntry."Entry No.";
        VATReportLine."VAT Group Identifier" := VATEntry."VAT Registration No.";
        if VATReportLine."VAT Group Identifier" = '' then
            VATReportLine."VAT Group Identifier" := VATEntry."Fiscal Code";
        VATReportLine."Incl. in Report" := true;
        VATReportLine.Insert(false);
    end;

    local procedure AddGLAccountVATReportLine(var VATReportLine: Record "VAT Report Line"; var VATReportHeader: Record "VAT Report Header"; LineType: Option; VATRegNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        NewEntryNo: Integer;
    begin
        VATEntry.FindLast();
        NewEntryNo := VATEntry."Entry No." + 1;

        VATEntry.Init();
        VATEntry."Entry No." := NewEntryNo;
        VATEntry."Posting Date" := CalcDate('<-2D>', Today);
        VATEntry."Document Date" := VATEntry."Posting Date";
        VATEntry."Operation Occurred Date" := VATEntry."Document Date";
        if LineType in [ConstType::FE, ConstType::NE, ConstType::FN] then
            VATEntry.Type := VATEntry.Type::Sale
        else
            VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Document No." := Format(LibraryRandom.RandInt(999999));
        VATEntry.Resident := VATEntry.Resident::Resident;
        VATEntry."Include in VAT Transac. Rep." := true;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry."Individual Person" := false;
        VATEntry."VAT %" := LibraryRandom.RandIntInRange(1, 21);
        VATEntry."Deductible %" := 100;
        VATEntry."VAT Registration No." := VATRegNo;

        VATEntry.Base := LibraryRandom.RandDec(LibrarySpesometro.GetThresholdAmount(), 2);
        VATEntry.Amount := VATEntry.Base * VATEntry."VAT %" / 100;
        VATEntry.Insert(false);

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeader."No.";
        VATReportLine."Posting Date" := VATEntry."Posting Date";
        VATReportLine."Document No." := VATEntry."Document No.";
        VATReportLine."Line No." := GetNextLineNo();
        VATReportLine.Type := VATEntry.Type;
        VATReportLine.Base := VATEntry.Base;
        VATReportLine.Amount := VATEntry.Amount;
        VATReportLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
        VATReportLine."Country/Region Code" := VATEntry."Country/Region Code";
        VATReportLine."VAT Registration No." := VATEntry."VAT Registration No.";
        ConstType := LineType;
        VATReportLine."Record Identifier" := Format(ConstType);
        VATReportLine."Operation Occurred Date" := VATEntry."Operation Occurred Date";
        VATReportLine."Amount Incl. VAT" := VATReportLine.Base + VATReportLine.Amount;
        VATReportLine."VAT Entry No." := VATEntry."Entry No.";
        VATReportLine."VAT Group Identifier" := VATEntry."VAT Registration No.";
        if VATReportLine."VAT Group Identifier" = '' then
            VATReportLine."VAT Group Identifier" := VATEntry."Fiscal Code";
        VATReportLine."Incl. in Report" := VATEntry."Include in VAT Transac. Rep.";
        VATReportLine.Insert(false);
    end;

    local procedure GLAcccountVATEntryExportDetailed(RecordType: Option; CheckFieldName: Text)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
    begin
        // Verify self billed is checked
        Initialize();

        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        AddGLAccountVATReportLine(VATReportLine, VATReportHeader, RecordType, '');

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        Assert.AreEqual(
          LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16),
          LibrarySpesometro.ReadBlockValue(TextFile, 3, CheckFieldName),
          StrSubstNo(BlockValueNotFoundErr, CheckFieldName));
    end;

    local procedure SetupCompany(UseTaxRepresentative: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Fiscal Code", '19988771002');
        CompanyInformation.Validate("VAT Registration No.", '02327910580');
        CompanyInformation.Validate(Name, 'CRONUS Italia S.p.A.');
        CompanyInformation.Validate(City, 'Rome');
        CompanyInformation.Validate(County, 'AG');
        CompanyInformation.Validate("Phone No.", '123456789123');
        CompanyInformation.Validate("Fax No.", '456789012345');
        CompanyInformation.Validate("Industrial Classification", '35.11.00');
        CompanyInformation.Validate("E-Mail", 'hello@microsoft.com');

        if UseTaxRepresentative then
            CompanyInformation.Validate("Tax Representative No.", LibraryPurchase.CreateVendorNo())
        else
            CompanyInformation.Validate("Tax Representative No.", '');
        CompanyInformation.Modify(true);
    end;

    local procedure GeneralSetup()
    var
        CountryRegion: Record "Country/Region";
        ForeignCountry: Code[10];
    begin
        CountryRegion.FindSet();
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        ForeignCountry := CountryRegion.Code;

        CountryRegion.FindFirst();
        CountryRegion."Foreign Country/Region Code" := ForeignCountry;
        CountryRegion.Modify(true);
    end;

    local procedure GetNextLineNo(): Integer
    begin
        LineNoCounter += 1;
        exit(LineNoCounter);
    end;

    local procedure GetCompanyRegNo(): Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Fiscal Code" <> '' then
            exit(CompanyInformation."Fiscal Code");
        exit(CompanyInformation."VAT Registration No.");
    end;

    local procedure GetMaxRecordCount(): Integer
    var
        FlatFileManagement: Codeunit "Flat File Management";
    begin
        FlatFileManagement.Initialize();
        FlatFileManagement.SetHeaderFooterRecordCountPerFile(4); // A, B, E and Z records
        exit(FlatFileManagement.GetMaxRecordsPerFile());
    end;

    local procedure ExportToFile(var VATReportHeader: Record "VAT Report Header"; DetailedExport: Boolean)
    var
        ExportVATTransactions: Report "Export VAT Transactions";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        FileName: Text;
        FileNameBase: Text;
        Index: Integer;
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
        VATReportHeader.SetFilter("No.", VATReportHeader."No.");
        ExportVATTransactions.SetTableView(VATReportHeader);
        ExportVATTransactions.UseRequestPage(false);
        FileNameBase := TemporaryPath + LibraryUtility.GenerateGUID();
        FileName := FileNameBase + '.ccf';
        ExportVATTransactions.InitializeRequest(FileName, DetailedExport);
        ExportVATTransactions.RunModal();
        if ExportVATTransactions.GetNoFiles() > 1 then
            for Index := 1 to ExportVATTransactions.GetNoFiles() do
                TransmissionFiles.Enqueue(FileNameBase + Format(Index) + '.ccf')
        else
            TransmissionFiles.Enqueue(FileName);
    end;

    local procedure LoadFile(var TextFile: BigText; FileName: Text[250])
    var
        File: File;
        InStr: InStream;
    begin
        File.Open(FileName);
        File.CreateInStream(InStr);
        TextFile.Read(InStr);
    end;

    local procedure LoadNextFile(var TextFile: BigText)
    var
        FileName: Variant;
    begin
        TransmissionFiles.Dequeue(FileName);
        LoadFile(TextFile, FileName);
    end;

    local procedure ExportToFileAndLoadNextFile(var VATReportHeader: Record "VAT Report Header"; DetailedExport: Boolean; var TextFile: BigText)
    begin
        ExportToFile(VATReportHeader, DetailedExport);
        LoadNextFile(TextFile);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandler(var ErrorPage: Page "VAT Report Error Log")
    begin
    end;

    local procedure RunCheckBaseScenario(LineType: Option; "Key": Text; IsCustomer: Boolean)
    begin
        CheckBaseScenario(LineType, 999999 + LibraryRandom.RandInt(999999), Key, '1', IsCustomer);
        CheckBaseScenario(LineType, -(999999 + LibraryRandom.RandInt(999999)), Key, '1', IsCustomer);
        CheckBaseScenario(LineType, LibraryRandom.RandInt(999999), Key, '0', IsCustomer);
        CheckBaseScenario(LineType, -LibraryRandom.RandInt(999999), Key, '0', IsCustomer);
    end;

    local procedure CheckBaseScenario(LineType: Option; Base: Decimal; "Key": Text; ExpectedValue: Text; IsCustomer: Boolean)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
        CustomerVendorNo: Code[20];
    begin
        // Setup
        CreateVATReportHeader(VATReportHeader, VATReportHeader."VAT Report Type"::Standard);
        if IsCustomer then
            CustomerVendorNo := LibrarySpesometro.CreateCustomer(true, CustomerRec.Resident::Resident, false, true)
        else
            CustomerVendorNo := LibrarySpesometro.CreateVendor(false, CustomerRec.Resident::Resident, true, false);
        AddVATReportLine(VATReportLine, VATReportHeader, LineType, CustomerVendorNo, false);
        UpdateBaseAmountVATReportLine(VATReportLine, Base);

        // Exercise
        ExportToFile(VATReportHeader, true);
        LoadNextFile(TextFile);

        // Verify
        VerifyStructure(TextFile, VATReportHeader, 1, 1);
        VerifyExists(TextFile, VATReportLine);
        LibrarySpesometro.VerifyBlockValue(TextFile, 3, Key, LibrarySpesometro.FormatPadding(ConstFormat::CB, ExpectedValue, 16), false, true);
    end;

    local procedure UpdateBaseAmountVATReportLine(var VATReportLine: Record "VAT Report Line"; NewBase: Decimal)
    begin
        VATReportLine.Base := NewBase;
        VATReportLine.Amount := VATReportLine.Base * LibraryRandom.RandIntInRange(1, 21) / 100;
        VATReportLine.Modify();
    end;

    local procedure VerifyExists(var TextFile: BigText; var VATReportLine: Record "VAT Report Line")
    var
        Index: Integer;
        BlockKey: Text;
        Value: Text;
        BlockKey2: Text;
        Value2: Text;
        RoundOption: Text;
    begin
        RoundOption := '=';
        if (VATReportLine.Base > -1) and (VATReportLine.Base < 1) then
            RoundOption := '>';

        BlockKey := '';
        BlockKey2 := '';
        case VATReportLine."Record Identifier" of
            'FE':
                begin
                    BlockKey := 'FE001009';
                    Value := VATReportLine."Document No.";
                end;
            'FR':
                begin
                    BlockKey := 'FR001008';
                    Value :=
                      LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(Abs(VATReportLine.Base), 1, RoundOption), 0, '<integer>'), 16);
                    BlockKey2 := 'FR001001';
                    Value2 := LibrarySpesometro.FormatPadding(ConstFormat::PI, VATReportLine."VAT Registration No.", 16);
                end;
            'NE':
                begin
                    BlockKey := 'NE001005';
                    Value := VATReportLine."Document No.";
                end;
            'NR':
                begin
                    BlockKey := 'NR001004';
                    Value :=
                      LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(Abs(VATReportLine.Base), 1, RoundOption), 0, '<integer>'), 16);
                    BlockKey2 := 'NR001001';
                    Value2 := LibrarySpesometro.FormatPadding(ConstFormat::PI, VATReportLine."VAT Registration No.", 16);
                end;
            'FN':
                begin
                    BlockKey := 'FN001013';
                    Value := VATReportLine."Document No.";
                end;
            'SE':
                begin
                    BlockKey := 'SE001014';
                    Value := VATReportLine."Document No.";
                end;
            else
                Error(InvalidRecordIdentifierErr, VATReportLine."Record Identifier");
        end;

        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do
            if LibrarySpesometro.ReadValue(TextFile, Index, 1, 1) = 'D' then
                if LibrarySpesometro.VerifyBlockValue(TextFile, Index, BlockKey, Value, true, false) then
                    if BlockKey2 <> '' then begin
                        if LibrarySpesometro.VerifyBlockValue(TextFile, Index, BlockKey2, Value2, true, true) then
                            exit;
                    end else
                        exit;

        Assert.Fail(StrSubstNo(RecordNotFoundErr, VATReportLine."Line No.", VATReportLine."Record Identifier", BlockKey, Value));
    end;

    local procedure VerifyCustomerTotal(var TextFile: BigText; CustType: Enum "General Posting Type"; CustNo: Code[20]; Total: Decimal): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        LineNo: Integer;
        SumTotal: Decimal;
        BlockKey: Text;
        Value: Text;
        AmountBlockKey: Text;
        RecordType: Text;
        UseLine: Boolean;
        LastName: Text;
        FirstName: Text;
        DOB: Date;
        Name: Text;
        City: Text;
    begin
        if Customer.Get(CustNo) then;
        if Vendor.Get(CustNo) then;

        for LineNo := 1 to Round(TextFile.Length / 1900, 1, '>') do
            if LibrarySpesometro.ReadValue(TextFile, LineNo, 1, 1) in ['C', 'D'] then begin
                RecordType := LibrarySpesometro.ReadValue(TextFile, LineNo, 90, 2); // Assumption: Each record only have one customer/"VAT report line" per line in the file
                BlockKey := '';
                case RecordType of
                    Format(ConstType::FE):
                        begin
                            AmountBlockKey := 'FE001011';
                            if Customer."Individual Person" then begin
                                BlockKey := 'FE001002';
                                Value := LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."Fiscal Code", 16)
                            end else begin
                                BlockKey := 'FE001001';
                                Value := LibrarySpesometro.FormatPadding(ConstFormat::PI, Customer."VAT Registration No.", 16);
                            end;

                            if LibrarySpesometro.ReadBlockValue(TextFile, LineNo, BlockKey) = Value then
                                SumTotal += SumBlockValue(TextFile, LineNo, AmountBlockKey);
                        end;
                    Format(ConstType::FA):
                        begin
                            if CustType = VATReportLineRec.Type::Sale then
                                if Customer."Individual Person" then begin
                                    BlockKey := 'FA001002';
                                    Value := LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."Fiscal Code", 16)
                                end else begin
                                    BlockKey := 'FA001001';
                                    Value := LibrarySpesometro.FormatPadding(ConstFormat::PI, Customer."VAT Registration No.", 16);
                                end;
                            if CustType = VATReportLineRec.Type::Purchase then
                                if Vendor."Individual Person" then begin
                                    BlockKey := 'FA001002';
                                    Value := LibrarySpesometro.FormatPadding(ConstFormat::CF, Vendor."Fiscal Code", 16)
                                end else begin
                                    BlockKey := 'FA001001';
                                    Value := LibrarySpesometro.FormatPadding(ConstFormat::PI, Vendor."VAT Registration No.", 16);
                                end;

                            if LibrarySpesometro.ReadBlockValue(TextFile, LineNo, BlockKey) = Value then begin
                                SumTotal += SumBlockValue(TextFile, LineNo, 'FA001008');
                                SumTotal += SumBlockValue(TextFile, LineNo, 'FA001011');
                                SumTotal -= SumBlockValue(TextFile, LineNo, 'FA001013');
                                SumTotal -= SumBlockValue(TextFile, LineNo, 'FA001016');
                            end;
                        end;
                    Format(ConstType::FR):
                        if LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FR001001') =
                           LibrarySpesometro.FormatPadding(ConstFormat::PI, Vendor."VAT Registration No.", 16)
                        then
                            SumTotal += SumBlockValue(TextFile, LineNo, 'FR001009');
                    Format(ConstType::NE):
                        begin
                            AmountBlockKey := 'NE001007';
                            if Customer."Individual Person" then begin
                                BlockKey := 'NE001002';
                                Value := LibrarySpesometro.FormatPadding(ConstFormat::CF, Customer."Fiscal Code", 16)
                            end else begin
                                BlockKey := 'NE001001';
                                Value := LibrarySpesometro.FormatPadding(ConstFormat::PI, Customer."VAT Registration No.", 16);
                            end;

                            if LibrarySpesometro.ReadBlockValue(TextFile, LineNo, BlockKey) = Value then
                                SumTotal -= SumBlockValue(TextFile, LineNo, AmountBlockKey);
                        end;
                    Format(ConstType::NR):
                        if LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'NR001001') =
                           LibrarySpesometro.FormatPadding(ConstFormat::PI, Vendor."VAT Registration No.", 16)
                        then
                            SumTotal -= SumBlockValue(TextFile, LineNo, 'NR001005');
                    Format(ConstType::FN):
                        begin
                            BlockKey := '';
                            if Customer."Individual Person" then begin
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FN001001'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Customer."Last Name"), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FN001002'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Customer."First Name"), '>', ' ')) and
                                   (LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FN001003') =
                                    LibrarySpesometro.FormatPadding(
                                      ConstFormat::DT, LibrarySpesometro.FormatDate(Customer."Date of Birth", ConstFormat::DT), 16))
                                then
                                    BlockKey := 'FN001016';
                            end else
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FN001007'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Customer.Name), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'FN001008'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Customer.City), '>', ' '))
                                then
                                    BlockKey := 'FN001016';
                            if BlockKey <> '' then
                                SumTotal += SumBlockValue(TextFile, LineNo, BlockKey);
                        end;
                    Format(ConstType::SE):
                        begin
                            BlockKey := '';
                            if Vendor."Individual Person" then begin
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'SE001001'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Vendor."Last Name"), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'SE001002'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Vendor."First Name"), '>', ' ')) and
                                   (LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'SE001003') =
                                    LibrarySpesometro.FormatPadding(
                                      ConstFormat::DT, LibrarySpesometro.FormatDate(Vendor."Date of Birth", ConstFormat::DT), 16))
                                then
                                    BlockKey := 'SE001016'
                            end else
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'SE001007'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Vendor.Name), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'SE001008'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Vendor.City), '>', ' '))
                                then
                                    BlockKey := 'SE001016';
                            if BlockKey <> '' then
                                SumTotal += SumBlockValue(TextFile, LineNo, BlockKey);
                        end;
                    Format(ConstType::BL):
                        begin
                            UseLine := false;
                            if CustType = VATReportLineRec.Type::Sale then begin
                                LastName := Customer."Last Name";
                                FirstName := Customer."First Name";
                                DOB := Customer."Date of Birth";
                                Name := Customer.Name;
                                City := Customer.City;
                            end;
                            if CustType = VATReportLineRec.Type::Purchase then begin
                                LastName := Vendor."Last Name";
                                FirstName := Vendor."First Name";
                                DOB := Vendor."Date of Birth";
                                Name := Vendor.Name;
                                City := Vendor.City;
                            end;

                            if Customer."Individual Person" then begin
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'BL001001'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(LastName), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'BL001002'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(FirstName), '>', ' ')) and
                                   (LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'BL001003') =
                                    LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(DOB, ConstFormat::DT), 16))
                                then
                                    UseLine := true;
                            end else
                                if (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'BL001007'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(Name), '>', ' ')) and
                                   (DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, 'BL001008'), '>', ' ') =
                                    DelChr(LibrarySpesometro.EncodeString(City), '>', ' '))
                                then
                                    UseLine := true;

                            if UseLine then begin
                                SumTotal += SumBlockValue(TextFile, LineNo, 'BL003002');
                                SumTotal -= SumBlockValue(TextFile, LineNo, 'BL006002');
                            end;
                        end;
                    else
                        Error(InvalidRecordIdentifierErr, RecordType);
                end;
            end;
        Assert.AreNearlyEqual(Total, SumTotal, 1, StrSubstNo(CustomerTotalErr, Customer."No."));
    end;

    local procedure SumBlockValue(var TextFile: BigText; LineNo: Integer; BlockKey: Text): Decimal
    var
        Tmp: Text;
        Amount: Decimal;
    begin
        Tmp := DelChr(LibrarySpesometro.ReadBlockValue(TextFile, LineNo, BlockKey), '=', ' ');
        if Tmp <> '' then begin
            Evaluate(Amount, Tmp);
            exit(Amount);
        end;
        exit(0);
    end;
}

