codeunit 144009 "IT - VAT Reporting - Service"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        isInitialized: Boolean;
        YouMustSpecifyValueErr: Label 'You must specify a value for the %1 field';
        ConfirmTextContractTemplateQst: Label 'Do you want to create the contract using a contract template?';

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIncl()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvExcl()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvExcl2()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvInclWVAT()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvExclWVAT()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvExcl2WVAT()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocInclInVATTransRep(ServiceHeader."Document Type"::Invoice, true, false, true);
    end;

    local procedure VerifyServDocInclInVATTransRep(DocumentType: Enum "Service Document Type"; InclVAT: Boolean; InclInVATSetup: Boolean; InclInVATTransRep: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(InclInVATSetup);

        // Create Service Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreateServiceDocument(ServiceHeader, ServiceLine, DocumentType, CreateCustomer(false, ServiceHeader.Resident::Resident, true, InclVAT), LineAmount);

        // Verify Service Line.
        ServiceLine.TestField("Include in VAT Transac. Rep.", InclInVATSetup); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvFromContractIncl()
    begin
        // Create Service Invoice from Service Contract.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvFromContract(false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvFromContractExcl()
    begin
        // Create Service Invoice from Service Contract.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvFromContract(false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvFromContractInclWVAT()
    begin
        // Create Service Invoice from Service Contract.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvFromContract(true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvFromContractExclWVAT()
    begin
        // Create Service Invoice from Service Contract.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvFromContract(true, false);
    end;

    local procedure VerifyServInvFromContract(InclVAT: Boolean; InclInVATSetup: Boolean)
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceLine: Record "Service Line";
        ContractAmount: Decimal;
        ServiceInvoiceNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(InclInVATSetup);

        // Create Service Contract.
        ContractAmount := CalculateAmount(WorkDate(), InclVAT, true);
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false, Customer.Resident::Resident, true, InclVAT), ContractAmount);

        // Sign Contract and Create Service Invoice.
        ServiceInvoiceNo := SignServiceContract(ServiceContractHeader);

        // Find Service Line.
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Invoice, ServiceInvoiceNo, true);

        // Verify Sevice Line.
        ServiceLine.TestField("Include in VAT Transac. Rep.", InclInVATSetup);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvLnkContractIncl()
    begin
        // Create Service Invoice and link to Service Contract.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvLnkContract(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvLnkContractInclWVAT()
    begin
        // Create Service Invoice and link to Service Contract.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServInvLnkContract(true);
    end;

    local procedure VerifyServInvLnkContract(InclVAT: Boolean)
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ContractAmount: Decimal;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Service Contract.
        ContractAmount := CalculateAmount(WorkDate(), InclVAT, true);
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false, Customer.Resident::Resident, true, InclVAT), ContractAmount);

        // Create Service Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, false);
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Customer No.", LineAmount);

        // Assign Service Contract.
        ServiceLine.Validate("Contract No.", ServiceContractHeader."Contract No.");
        ServiceLine.Modify(true);

        // Verify Service Line.
        ServiceLine.TestField("Include in VAT Transac. Rep.", true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServOrdLnkContractIncl()
    begin
        // Create Service Order and link to Service Contract.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServOrdLnkContract(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServOrdLnkContractInclWVAT()
    begin
        // Create Service Order and link to Service Contract.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Contract Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServOrdLnkContract(true);
    end;

    local procedure VerifyServOrdLnkContract(InclVAT: Boolean)
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ContractAmount: Decimal;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Service Contract.
        ContractAmount := CalculateAmount(WorkDate(), InclVAT, true);
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false, Customer.Resident::Resident, true, InclVAT), ContractAmount);

        // Sign Service Contract.
        SignServiceContract(ServiceContractHeader);

        // Create Service Order.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, false);
        CreateServiceOrder(ServiceHeader, ServiceLine, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract No.", LineAmount);

        // Verify Service Line.
        ServiceLine.TestField("Include in VAT Transac. Rep.", true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryServInv()
    begin
        VerifyCountryServInv(CreateCountry()); // EU Country.
    end;

    local procedure VerifyCountryServInv(CountryRegionCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Customer.
        Customer.Get(CreateCustomer(false, ServiceHeader.Resident::"Non-Resident", true, false));
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Modify(true);

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.", LineAmount);

        // Verify Sales Line.
        ServiceLine.TestField("Include in VAT Transac. Rep.", false);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServDocManualInclude()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceTestPage: TestPage "Service Invoice";
        ServiceCreditMemoTestPage: TestPage "Service Credit Memo";
    begin
        // Verify EDITABLE is TRUE through pages because property is not available through record.

        // Service Invoice.
        LibraryService.CreateServiceHeader(ServiceHeader, "Service Document Type"::Invoice, '');
        ServiceInvoiceTestPage.OpenNew();
        ServiceInvoiceTestPage.GotoRecord(ServiceHeader);
        Assert.IsTrue(
            ServiceInvoiceTestPage.ServLines."Include in VAT Transac. Rep.".Editable(),
            'EDITABLE should be TRUE for the field ' + ServiceInvoiceTestPage.ServLines."Include in VAT Transac. Rep.".Caption);
        ServiceInvoiceTestPage.Close();

        // Service Credit Memo.
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, "Service Document Type"::"Credit Memo", '');
        ServiceCreditMemoTestPage.OpenNew();
        ServiceCreditMemoTestPage.GoToRecord(ServiceHeader);
        Assert.IsTrue(
            ServiceCreditMemoTestPage.ServLines."Include in VAT Transac. Rep.".Editable(),
            'EDITABLE should be TRUE for the field ' + ServiceCreditMemoTestPage.ServLines."Include in VAT Transac. Rep.".Caption());
        ServiceCreditMemoTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvPostIncl()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServDocPostIncl(ServiceHeader."Document Type"::Invoice, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvPostExcl()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocPostIncl(ServiceHeader."Document Type"::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvPostInclWVAT()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifyServDocPostIncl(ServiceHeader."Document Type"::Invoice, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvPostExclWVAT()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyServDocPostIncl(ServiceHeader."Document Type"::Invoice, true, false);
    end;

    local procedure VerifyServDocPostIncl(DocumentType: Enum "Service Document Type"; InclVAT: Boolean; InclInVATTransRep: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Service Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreateServiceDocument(ServiceHeader, ServiceLine, DocumentType, CreateCustomer(false, ServiceHeader.Resident::Resident, true, InclVAT), LineAmount);
        DocumentNo := PostServiceHeader(ServiceHeader);

        // Verify Service Line.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Service Header", DocumentType.AsInteger()), DocumentNo, true); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServInvWithContractPost()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Invoice linked to Service Contract.
        // Expected result: Contract No. copied to VAT Entry.
        VerifyServDocWithContractPost(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServOrdWithContractPost()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Order linked to Service Contract.
        // Expected result: Contract No. copied to VAT Entry.
        VerifyServDocWithContractPost(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerServiceContract')]
    [Scope('OnPrem')]
    procedure ServCMWithContractPost()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service CM linked to Service Contract.
        // Expected result: Contract No. copied to VAT Entry.
        VerifyServDocWithContractPost(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure VerifyServDocWithContractPost(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ContractAmount: Decimal;
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();
        // Setup.

        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Service Contract.
        ContractAmount := CalculateAmount(WorkDate(), false, true);
        CreateServiceContract(ServiceContractHeader, CreateCustomer(false, Customer.Resident::Resident, true, false), ContractAmount);

        // Sign Service Contract.
        SignServiceContract(ServiceContractHeader);

        // Create Service Document.
        LineAmount := CalculateAmount(WorkDate(), false, false);
        case DocumentType of
            ServiceHeader."Document Type"::Order:
                // Create Service Order linked to Contract.
                CreateServiceOrder(ServiceHeader, ServiceLine, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract No.", LineAmount);
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo":
                begin
                    // Create Service Invoice.
                    CreateServiceDocument(ServiceHeader, ServiceLine, DocumentType, ServiceContractHeader."Customer No.", LineAmount);
                    // Assign Service Contract.
                    ServiceLine.Validate("Contract No.", ServiceContractHeader."Contract No.");
                    ServiceLine.Modify(true);
                end;
        end;

        // Post.
        DocumentNo := PostServiceHeader(ServiceHeader);

        // Verify VAT Entry.
        if DocumentType = ServiceHeader."Document Type"::"Credit Memo" then
            VerifyContractNo(ServiceHeader."Document Type", DocumentNo, ServiceLine."Line Amount", ServiceContractHeader."Contract No.")
        else
            VerifyContractNo(ServiceHeader."Document Type"::Invoice, DocumentNo, -ServiceLine."Line Amount", ServiceContractHeader."Contract No.");

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMRefToBlank()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: No error meessage that [Refers to Period] field is blank.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::" ", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMRefToCurrent()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::Current, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMRefToCrYear()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::"Current Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMRefToPrevious()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::"Previous Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMLineRefToCurrent()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::Current, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMLineRefToCrYear()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::"Current Calendar Year", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCMLineRefToPrevious()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifyServDocRefTo(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Refers to Period"::"Current Calendar Year", true);
    end;

    local procedure VerifyServDocRefTo(DocumentType: Enum "Service Document Type"; RefersToPeriod: Option; UpdateLine: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [Prices Including VAT] = No.
        // Line Amount > [Threshold Amount Excl. VAT.].
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Service Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer(false, ServiceHeader.Resident::Resident, true, false));

        // Update Refers To Period.
        ServiceHeader.Validate("Refers to Period", RefersToPeriod);
        ServiceHeader.Modify(true);

        // Create Service Line.
        CreateServiceLine(ServiceHeader, ServiceLine, '', LineAmount);

        // Update Refers To Period.
        if UpdateLine then begin
            ServiceLine.Validate("Refers to Period", RefersToPeriod);
            ServiceLine.Modify(true);
        end;

        // Post Service Document.
        DocumentNo := PostServiceHeader(ServiceHeader);

        // Verify Posted Service Cr. Memo.
        if UpdateLine then
            VerifyRefersToPeriod(DATABASE::"Service Cr.Memo Line", DocumentNo, RefersToPeriod)
        else
            VerifyRefersToPeriod(DATABASE::"Service Cr.Memo Header", DocumentNo, RefersToPeriod);

        // Verify VAT Entry.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Service Header", DocumentType.AsInteger()), DocumentNo, true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustServTaxRepContact()
    var
        Customer: Record Customer;
    begin
        CustServTaxRep(Customer."Tax Representative Type"::Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustServTaxRepCust()
    var
        Customer: Record Customer;
    begin
        CustServTaxRep(Customer."Tax Representative Type"::Customer);
    end;

    local procedure CustServTaxRep(TaxRepType: Option)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        TaxRepNo: Code[20];
        ExpectedTaxRepType: Option;
    begin
        Initialize();

        // Create Customer.
        Customer.Get(CreateCustomer(false, Customer.Resident::"Non-Resident", false, false));

        // Set Tax Representative Type & No.
        case TaxRepType of
            Customer."Tax Representative Type"::Contact:
                begin
                    TaxRepNo := CreateContact();
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Contact;
                end;
            Customer."Tax Representative Type"::Customer:
                begin
                    TaxRepNo := CreateCustomer(false, Customer.Resident::Resident, true, true);
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Customer;
                end;
        end;
        Customer.Validate("Tax Representative Type", TaxRepType);
        Customer.Validate("Tax Representative No.", TaxRepNo);
        Customer.Modify(true);

        // Create Service Document.
        Amount := LibraryRandom.RandDec(10000, 2);
        CreateServiceDocument(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.", Amount);
        DocumentNo := PostServiceHeader(ServiceHeader);

        // Verify VAT Entry.
        VerifyTaxRep(GetDocumentTypeVATEntry(DATABASE::"Service Header", ServiceHeader."Document Type".AsInteger()), DocumentNo, ExpectedTaxRepType, TaxRepNo);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustResFiscalCode()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [Fiscal Code].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::Resident, Customer.FieldNo("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResCtryRegion()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [Country/Region Code].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResFirstName()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [First Name].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("First Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResLastName()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [Last Name].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Last Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResDteOfBirth()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [Date of Birth].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Date of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResPlOfBirth()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [Place of Birth].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Place of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvKnCustResVATRegNo()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that error message is generated when posting Service Invoice without [VAT Registration No.].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyServDocReqFields(ServiceHeader."Document Type"::Invoice, false, Customer.Resident::Resident, Customer.FieldNo("VAT Registration No."));
    end;

    local procedure VerifyServDocReqFields(DocumentType: Enum "Service Document Type"; IndividualPerson: Boolean; Resident: Option; FieldId: Integer)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Customer (Excl. VAT).
        Customer.Get(CreateCustomer(IndividualPerson, Resident, true, false));

        // Remove Value from Field under test.
        RecordRef.GetTable(Customer);
        FieldRef := RecordRef.Field(FieldId);
        ClearField(RecordRef, FieldRef);

        // Create Service Document.
        CreateServiceDocument(ServiceHeader, ServiceLine, DocumentType, Customer."No.", LineAmount);

        // Try to Post Service Document and verify Error Message.
        asserterror PostServiceHeader(ServiceHeader);
        Assert.ExpectedError(StrSubstNo(YouMustSpecifyValueErr, FieldRef.Caption));

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustResExclVATRep()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that no error message is generated when posting Service Invoice without [Fiscal Code].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyServDocReqFieldsExcl(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvIndCustNonResExclVATRep()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that no error message is generated when posting Service Invoice without [Country/Region Code].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is completed successfully.
        VerifyServDocReqFieldsExcl(ServiceHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvKnCustResExclVATRep()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Verify that no error message is generated when posting Service Invoice without [VAT Registration No.].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyServDocReqFieldsExcl(ServiceHeader."Document Type"::Invoice, false, Customer.Resident::Resident);
    end;

    local procedure VerifyServDocReqFieldsExcl(DocumentType: Enum "Service Document Type"; IndividualPerson: Boolean; Resident: Option)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(false);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Service Document.
        CreateServiceDocument(ServiceHeader, ServiceLine, DocumentType, CreateCustomer(IndividualPerson, Resident, false, false), LineAmount);

        // Post Service Document (no error message).
        PostServiceHeader(ServiceHeader);

        // Tear Down.
        TearDown();
    end;

    local procedure Initialize()
    begin
        TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        CreateVATReportSetup();
        Commit();

        TearDown(); // Cleanup for the first test.
    end;

    local procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        Delta: Decimal;
    begin
        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta := LibraryRandom.RandDec(GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false), 2);

        if not InclInVATTransRep then
            Delta := -Delta;

        Amount := GetThresholdAmount(StartingDate, InclVAT) + Delta;
    end;

    local procedure ClearField(RecordRef: RecordRef; FieldRef: FieldRef)
    var
        FieldRef2: FieldRef;
        RecordRef2: RecordRef;
    begin
        RecordRef2.Open(RecordRef.Number, true); // Open temp table.
        FieldRef2 := RecordRef2.Field(FieldRef.Number);

        FieldRef.Validate(FieldRef2.Value); // Clear field value.
        RecordRef.Modify(true);
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("VAT Registration No.", LibraryUtility.GenerateRandomCode(Contact.FieldNo("VAT Registration No."), DATABASE::Contact));
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateCountry(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code); // Fill with Country Code as value is not important for test.
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Individual Person", IndividualPerson);
        Customer.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Customer.Resident::"Non-Resident" then
                Customer.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Customer.Validate("VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer))
            else
                case Resident of
                    Customer.Resident::Resident:
                        Customer."Fiscal Code" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer); // Validation of Fiscal Code is not important.
                    Customer.Resident::"Non-Resident":
                        begin
                            Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
                            Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
                            Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Customer.Validate("Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer));
                        end;
                end;
        end;

        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Always use Normal for G/L Accounts.
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);

        // Gen. Posting Type, Gen. Bus. and VAT Bus. Posting Groups are required for General Journal.
        if GenPostingType <> GLAccount."Gen. Posting Type"::" " then begin
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
            GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        end;
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateServiceContractAccGroup(): Code[10]
    var
        GLAccount: Record "G/L Account";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // Create G/L Account with VAT Posting Setup.
        GLAccount.Get(CreateGLAccount(GLAccount."Gen. Posting Type"::Sale));

        // Create Service Contract Account Group.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        ServiceContractAccountGroup.Validate("Non-Prepaid Contract Acc.", GLAccount."No.");
        ServiceContractAccountGroup.Validate("Prepaid Contract Acc.", GLAccount."No.");
        ServiceContractAccountGroup.Modify(true);
        exit(ServiceContractAccountGroup.Code);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20]; LineValue: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Create Service Contract Header.
        LibraryVariableStorage.Enqueue(ConfirmTextContractTemplateQst); // Passing expected message to Confirm Handler.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", CreateServiceContractAccGroup());
        ServiceContractHeader.Modify(true);

        // Create Service Item.
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");

        // Create Service Contract Line.
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Validate("Next Planned Service Date", ServiceContractHeader."Starting Date");
        ServiceContractLine.Validate("Line Value", LineValue);
        ServiceContractLine.Modify(true);

        // Update Annual Amount on Service Contract Header.
        ServiceContractHeader.Validate("Annual Amount", LineValue);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        // Create Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);

        if DocumentType = ServiceHeader."Document Type"::"Credit Memo" then begin
            ServiceHeader.Validate("Refers to Period", ServiceHeader."Refers to Period"::"Current Calendar Year");
            ServiceHeader.Modify(true);
        end;
        // Create Service Line.
        CreateServiceLine(ServiceHeader, ServiceLine, '', LineAmount);
    end;

    local procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceItemNo: Code[10]; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Service Line.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccount(GLAccount."Gen. Posting Type"::" "));
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LineAmount / ServiceLine.Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; ContractNo: Code[20]; LineAmount: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Service Order.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, GetServiceItemNo(CustomerNo));
        ServiceItemLine.Validate("Contract No.", ContractNo);
        ServiceItemLine.Modify(true);

        // Create Service Line.
        CreateServiceLine(ServiceHeader, ServiceLine, ServiceItemLine."Service Item No.", LineAmount);
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert(true);
        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATTransReportAmount(var VATTransRepAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransRepAmount.Init();
        VATTransRepAmount.Validate("Starting Date", StartingDate);
        VATTransRepAmount.Insert(true);
    end;

    local procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure GetDocumentTypeVATEntry(TableNo: Option; DocumentType: Option) DocumentTypeVATEntry: Enum "Gen. Journal Document Type"
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        VATEntry: Record "VAT Entry";
    begin
        case TableNo of
            DATABASE::"Gen. Journal Line":
                DocumentTypeVATEntry := "Gen. Journal Document Type".FromInteger(DocumentType);
            DATABASE::"Sales Header":
                case DocumentType of
                    SalesHeader."Document Type"::Invoice.AsInteger(),
                    SalesHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    SalesHeader."Document Type"::"Credit Memo".AsInteger(),
                    SalesHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Service Header":
                case DocumentType of
                    ServiceHeader."Document Type"::Invoice.AsInteger(),
                    ServiceHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    ServiceHeader."Document Type"::"Credit Memo".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Purchase Header":
                case DocumentType of
                    PurchHeader."Document Type"::Invoice.AsInteger(),
                    PurchHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    PurchHeader."Document Type"::"Credit Memo".AsInteger(),
                    PurchHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
        end;
    end;

    local procedure GetServiceDocumentNo(ServiceHeader: Record "Service Header") DocumentNo: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        DocumentNo := NoSeries.PeekNextNo(ServiceHeader."Posting No. Series");
    end;

    local procedure GetServiceItemNo(CustomerNo: Code[20]): Code[20]
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.SetFilter("Customer No.", CustomerNo);
        ServiceItem.FindFirst();
        exit(ServiceItem."No.");
    end;

    local procedure GetThresholdAmount(StartingDate: Date; InclVAT: Boolean) Amount: Decimal
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATTransactionReportAmount.SetFilter("Starting Date", '<=%1', StartingDate);
        VATTransactionReportAmount.FindLast();

        if InclVAT then
            Amount := VATTransactionReportAmount."Threshold Amount Incl. VAT"
        else
            Amount := VATTransactionReportAmount."Threshold Amount Excl. VAT";
    end;

    local procedure FindServiceDocumentRegister(var ServiceDocumentRegister: Record "Service Document Register"; SourceDocumentType: Enum "Service Source Document Type"; SourceDocumentNo: Code[20]; DestinationDocumentType: Enum "Service Destination Document Type")
    begin
        ServiceDocumentRegister.SetRange("Source Document Type", SourceDocumentType);
        ServiceDocumentRegister.SetRange("Source Document No.", SourceDocumentNo);
        ServiceDocumentRegister.SetRange("Destination Document Type", DestinationDocumentType);
        ServiceDocumentRegister.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; SkipEmptyLine: Boolean)
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetFilter("Document No.", DocumentNo);
        if SkipEmptyLine then
            ServiceLine.SetFilter("No.", '<>%1', ''); // Skip empty line.
        ServiceLine.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure PostServiceHeader(var ServiceHeader: Record "Service Header") DocumentNo: Code[20]
    begin
        DocumentNo := GetServiceDocumentNo(ServiceHeader);
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order:
                LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo":
                LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        end;
    end;

    local procedure SetupThresholdAmount(StartingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransRepAmount, StartingDate);
        VATRate := LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ThresholdAmount := 1000 * LibraryRandom.RandInt(10);
        VATTransRepAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransRepAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);

        VATTransRepAmount.Modify(true);
    end;

    local procedure SignServiceContract(var ServiceContractHeader: Record "Service Contract Header"): Code[20]
    var
        ServiceDocumentRegister: Record "Service Document Register";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Sign Contract and Create Service Invoice.
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Find Service Invoice.
        FindServiceDocumentRegister(ServiceDocumentRegister, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceDocumentRegister."Destination Document Type"::Invoice);

        exit(ServiceDocumentRegister."Destination Document No.");
    end;

    local procedure VerifyContractNo(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Base: Decimal; ContractNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Base, Base);
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Contract No.", ContractNo);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyIncludeVAT(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; InclInVATTransRep: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Include in VAT Transac. Rep.", InclInVATTransRep);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyRefersToPeriod(TableID: Option; DocumentNo: Code[20]; RefersToPeriod: Option)
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATEntry: Record "VAT Entry";
    begin
        case TableID of
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(DocumentNo);
                    SalesCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoHeader.Get(DocumentNo);
                    PurchCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Sales Cr.Memo Line":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    SalesCrMemoLine.FindFirst();
                    SalesCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Line":
                begin
                    PurchCrMemoLine.SetRange("Document No.", DocumentNo);
                    PurchCrMemoLine.FindFirst();
                    PurchCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
        end;

        FindVATEntry(VATEntry, VATEntry."Document Type"::"Credit Memo", DocumentNo);
        repeat
            VATEntry.TestField("Refers To Period", RefersToPeriod);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyTaxRep(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TaxRepType: Option; TaxRepNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Tax Representative Type", TaxRepType);
            VATEntry.TestField("Tax Representative No.", TaxRepNo);
        until VATEntry.Next() = 0;
    end;

    local procedure TearDown()
    var
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.ModifyAll("Sales Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Purch. Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", false, true);

        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ", true);

        VATTransRepAmount.DeleteAll(true);
        EnableUnrealizedVAT(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerServiceContract(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question = ConfirmTextContractTemplateQst then
            Reply := false;
    end;
}

