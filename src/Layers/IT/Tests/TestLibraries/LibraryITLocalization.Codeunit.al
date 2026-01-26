codeunit 143000 "Library - IT Localization"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        VATPeriodTxt: Label '%1/%2', Comment = '%1=Field Value,%2=Field Value';

    [Scope('OnPrem')]
    procedure CreateAppointmentCode(var AppointmentCode: Record "Appointment Code")
    begin
        AppointmentCode.Init();
        AppointmentCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(AppointmentCode.FieldNo(Code), DATABASE::"Appointment Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Appointment Code", AppointmentCode.FieldNo(Code))));
        AppointmentCode.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBill(var Bill: Record Bill)
    begin
        Bill.Init();
        Bill.Validate(Code, LibraryUtility.GenerateRandomCode(Bill.FieldNo(Code), DATABASE::Bill));
        Bill.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBillPostingGroup(var BillPostingGroup: Record "Bill Posting Group"; No: Code[20]; PaymentMethod: Code[10])
    begin
        BillPostingGroup.Init();
        BillPostingGroup.Validate("No.", No);
        BillPostingGroup.Validate("Payment Method", PaymentMethod);
        BillPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCompanyType(var CompanyTypes: Record "Company Types")
    begin
        CompanyTypes.Init();
        CompanyTypes.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(CompanyTypes.FieldNo(Code), DATABASE::"Company Types"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Company Types", CompanyTypes.FieldNo(Code))));
        CompanyTypes.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContributionCode(var ContributionCode: Record "Contribution Code"; ContributionType: Option)
    begin
        ContributionCode.Init();
        ContributionCode.Validate(Code, LibraryUtility.GenerateRandomCode(ContributionCode.FieldNo(Code), DATABASE::"Contribution Code"));
        ContributionCode.Validate("Contribution Type", ContributionType);
        ContributionCode.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContributionCodeLine(var ContributionCodeLine: Record "Contribution Code Line"; "Code": Code[20]; StartingDate: Date; ContributionType: Option)
    begin
        ContributionCodeLine.Init();
        ContributionCodeLine.Validate(Code, Code);
        ContributionCodeLine.Validate("Starting Date", StartingDate);
        ContributionCodeLine.Validate("Contribution Type", ContributionType);
        ContributionCodeLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContributionBracket(var ContributionBracket: Record "Contribution Bracket"; ContributionType: Option)
    begin
        ContributionBracket.Init();
        ContributionBracket.Validate(
          Code, LibraryUtility.GenerateRandomCode(ContributionBracket.FieldNo(Code), DATABASE::"Contribution Bracket"));
        ContributionBracket.Validate("Contribution Type", ContributionType);
        ContributionBracket.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateContributionBracketLine(var ContributionBracketLine: Record "Contribution Bracket Line"; "Code": Code[20]; Amount: Decimal; ContributionType: Option)
    begin
        ContributionBracketLine.Init();
        ContributionBracketLine.Validate(Code, Code);
        ContributionBracketLine.Validate(Amount, Amount);
        ContributionBracketLine.Validate("Contribution Type", ContributionType);
        ContributionBracketLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomsAuthorityVendor(var CustomsAuthorityVendor: Record "Customs Authority Vendor"; VendorNo: Code[20])
    begin
        CustomsAuthorityVendor.Init();
        CustomsAuthorityVendor.Validate("Vendor No.", VendorNo);
        CustomsAuthorityVendor.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateInterestOnArrears(var InterestOnArrears: Record "Interest on Arrears"; "Code": Code[10]; StartingDate: Date)
    begin
        InterestOnArrears.Init();
        InterestOnArrears.Validate(Code, Code);
        InterestOnArrears.Validate("Starting Date", StartingDate);
        InterestOnArrears.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemCostingSetup(var ItemCostingSetup: Record "Item Costing Setup")
    begin
        if not ItemCostingSetup.Get() then
            ItemCostingSetup.Insert(true);
    end;

#if not CLEAN27
    [Scope('OnPrem')]
    procedure CreatePeriodicVATSettlementEntry(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.Init();
        PeriodicSettlementVATEntry.Validate(
          "VAT Period", StrSubstNo(VATPeriodTxt, Date2DMY(PeriodDate, 3), ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0')));
        PeriodicSettlementVATEntry.Insert(true);
    end;
#else
    [Scope('OnPrem')]
    procedure CreatePeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.Init();
        PeriodicSettlementVATEntry.Validate(
          "VAT Period", StrSubstNo(VATPeriodTxt, Date2DMY(PeriodDate, 3), ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0')));
        PeriodicSettlementVATEntry.Insert(true);
    end;
#endif
    [Scope('OnPrem')]
    procedure CreateServiceTariffNumber(var ServiceTariffNumber: Record "Service Tariff Number")
    begin
        ServiceTariffNumber.Init();
        ServiceTariffNumber.Validate(
          "No.", LibraryUtility.GenerateRandomCode(ServiceTariffNumber.FieldNo("No."), DATABASE::"Service Tariff Number"));
        ServiceTariffNumber.Insert(true);
    end;

#if not CLEAN27
#pragma warning disable AL0801
    [Obsolete('Preparation for replacement by Subcontracting app', '27.0')]
    [Scope('OnPrem')]
    procedure CreateSubContractingPrice(var SubcontractorPrices: Record "Subcontractor Prices"; WorkCenterNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; StandardTaskCode: Code[10]; VariantCode: Code[10]; StartDate: Date; UnitOfMeasureCode: Code[10]; MinimumQuantity: Decimal; CurrencyCode: Code[10])
    begin
        SubcontractorPrices.Init();
        SubcontractorPrices.Validate("Work Center No.", WorkCenterNo);
        SubcontractorPrices.Validate("Vendor No.", VendorNo);
        SubcontractorPrices.Validate("Item No.", ItemNo);
        SubcontractorPrices.Validate("Standard Task Code", StandardTaskCode);
        SubcontractorPrices.Validate("Variant Code", VariantCode);
        SubcontractorPrices.Validate("Start Date", StartDate);
        SubcontractorPrices.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SubcontractorPrices.Validate("Minimum Quantity", MinimumQuantity);
        SubcontractorPrices.Validate("Currency Code", CurrencyCode);
        SubcontractorPrices.Insert(true);
    end;
#pragma warning restore AL0801
#endif

    [Scope('OnPrem')]
    procedure CreateTransportMethod(var TransportMethod: Record "Transport Method")
    begin
        TransportMethod.Init();
        TransportMethod.Validate(Code, LibraryUtility.GenerateRandomCode(TransportMethod.FieldNo(Code), DATABASE::"Transport Method"));
        TransportMethod.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATRegister(var VATRegister: Record "VAT Register"; VATRegisterType: Option)
    begin
        VATRegister.Init();
        VATRegister.Validate(Code, LibraryUtility.GenerateGUID());
        VATRegister.Validate(Type, VATRegisterType);
        VATRegister.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup, 0);
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine.Validate(
            "Row No.",
            CopyStr(LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line"),
                1, LibraryUtility.GetFieldLength(DATABASE::"VAT Statement Line", VATStatementLine.FieldNo("Row No."))));
        VATStatementLine.Validate(Description, VATStatementLine."Row No.");
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::"Blacklist Amount");
        VATStatementLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATTransactionReportAmount(var VATTransactionReportAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransactionReportAmount.Init();
        VATTransactionReportAmount.Validate("Starting Date", StartingDate);
        VATTransactionReportAmount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerBillHeader(var CustomerBillHeader: Record "Customer Bill Header")
    begin
        CustomerBillHeader.Init();
        CustomerBillHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        VendorBillHeader.Init();
        VendorBillHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWithholdCode(var WithholdCode: Record "Withhold Code")
    begin
        WithholdCode.Init();
        WithholdCode.Validate(Code, LibraryUtility.GenerateRandomCode(WithholdCode.FieldNo(Code), DATABASE::"Withhold Code"));
        WithholdCode.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWithholdCodeLine(var WithholdCodeLine: Record "Withhold Code Line"; WithholdCode: Code[20]; StartingDate: Date)
    begin
        WithholdCodeLine.Init();
        WithholdCodeLine.Validate("Withhold Code", WithholdCode);
        WithholdCodeLine.Validate("Starting Date", StartingDate);
        WithholdCodeLine.Insert(true);
    end;

    procedure CreateFatturaPaymentMethodCode(): Code[10]
    var
        FatturaCode: Record "Fattura Code";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Fattura PA Payment Method", GetRandomFatturaCode(FatturaCode.Type::"Payment Method"));
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    procedure CreateFatturaPaymentTermsCode(): Code[10]
    var
        FatturaCode: Record "Fattura Code";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Fattura Payment Terms Code", GetRandomFatturaCode(FatturaCode.Type::"Payment Terms"));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        // Public Company Customer
        exit(
          CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    procedure CreateFatturaCustomerNo(PACode: Code[7]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerNo());
        Customer.Validate("PA Code", PACode);
        LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer);
        Customer.Validate("Country/Region Code", 'IT');
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", CopyStr(LibraryUtility.GenerateRandomNumericText(5), 1, MaxStrLen(Customer."Post Code")));
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo('IT'));
        Customer.Validate("Fiscal Code", '02876990587');
        Customer.Validate(County, 'IT');
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Validate("PEC E-Mail Address", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    procedure CreateFatturaProjectCode(): Code[15]
    var
        FatturaProjectInfo: Record "Fattura Project Info";
    begin
        exit(CreateFatturaProjectInfo(FatturaProjectInfo.Type::Project));
    end;

    procedure CreateFatturaTenderCode(): Code[15]
    var
        FatturaProjectInfo: Record "Fattura Project Info";
    begin
        exit(CreateFatturaProjectInfo(FatturaProjectInfo.Type::Tender));
    end;

    local procedure CreateFatturaProjectInfo(Type: Option): Code[15]
    var
        FatturaProjectInfo: Record "Fattura Project Info";
    begin
        FatturaProjectInfo.Init();
        FatturaProjectInfo.Type := Type;
        FatturaProjectInfo.Code :=
          LibraryUtility.GenerateRandomCodeWithLength(FatturaProjectInfo.FieldNo(Code),
            DATABASE::"Fattura Project Info", MaxStrLen(FatturaProjectInfo.Code));
        FatturaProjectInfo.Insert();
        exit(FatturaProjectInfo.Code);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Integer)
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", VATPercentage);
        VATPostingSetup.FindFirst();
    end;

    procedure FilterFatturaDocumentTypeNoDefaultValues(var FatturaDocumentType: Record "Fattura Document Type")
    begin
        FatturaDocumentType.SetRange(Invoice, false);
        FatturaDocumentType.SetRange("Credit Memo", false);
        FatturaDocumentType.SetRange("Self-Billing", false);
        FatturaDocumentType.SetRange(Prepayment, false);
    end;

    [Scope('OnPrem')]
    procedure GetVATCode(): Code[20]
    begin
        exit('12345670124');
    end;

    [Scope('OnPrem')]
    procedure GetFiscalCode(): Code[20]
    begin
        // Fiscal code of a fictitious Matteo Moretti (male), born in Milan on 9 April 1925
        exit('MRTMTT25D09F205Z');
    end;

    procedure GetRandomFatturaCode(TypeValue: Enum "Fattura Code Type"): Code[4]
    var
        FatturaCode: Record "Fattura Code";
    begin
        FatturaCode.SetRange(Type, TypeValue);
        FatturaCode.Next(LibraryRandom.RandIntInRange(1, FatturaCode.Count));
        exit(FatturaCode.Code);
    end;

    procedure GetRandomCompanyType(): Code[2]
    var
        CompanyTypes: Record "Company Types";
    begin
        CompanyTypes.Next(LibraryRandom.RandInt(CompanyTypes.Count));
        exit(CompanyTypes.Code);
    end;

    procedure GetRandomFatturaDocType(ExcludeFatturaDocType: Code[20]): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        FatturaDocHelper.InsertFatturaDocumentTypeList();
        FilterFatturaDocumentTypeNoDefaultValues(FatturaDocumentType);
        FatturaDocumentType.SetFilter("No.", '<>%1', ExcludeFatturaDocType);
        FatturaDocumentType.FindSet();
        FatturaDocumentType.Next(LibraryRandom.RandIntInRange(1, FatturaDocumentType.Count - 1));
        exit(FatturaDocumentType."No.");
    end;

    [Scope('OnPrem')]
    procedure SetValidateLocVATRegNo(ValidateLocVATRegNo: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Validate loc.VAT Reg. No.", ValidateLocVATRegNo);
        GeneralLedgerSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure IssueVendorBill(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Vend. Bill List-Change Status", VendorBillHeader);
    end;

    [Scope('OnPrem')]
    procedure PostIssuedVendorBill(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Vendor Bill List - Post", VendorBillHeader);
    end;

    procedure InsertFatturaElectronicFormats(FormatCode: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo".AsInteger());
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Service Invoice".AsInteger());
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo".AsInteger());
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"FatturaPA Sales Validation", 0, ElectronicDocumentFormat.Usage::"Sales Validation".AsInteger());
        ElectronicDocumentFormat.InsertElectronicFormat(
          FormatCode, '', CODEUNIT::"FatturaPA Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation".AsInteger());
    end;

    procedure SetValidateDocumentOnPostingSales(Validate: Boolean; FormatCode: Code[20])
    begin
        LibrarySales.SetFatturaPAElectronicFormat(FormatCode);
        LibrarySales.SetValidateDocumentOnPosting(Validate);
    end;

    procedure SetValidateDocumentOnPostingService(Validate: Boolean; FormatCode: Code[20])
    begin
        LibrarySales.SetFatturaPAElectronicFormat(FormatCode);
        LibraryService.SetValidateDocumentOnPosting(Validate);
    end;

    procedure SetupFatturaPA()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        UpdateFatturaCompanyInformation();
        ClearAllXMLFilesInTempFolder();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Fattura PA Nos." := InsertFatturaNoSeries();

        InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);
        SetupFatturaDocumentSendingProfile();
    end;

    local procedure SetupFatturaDocumentSendingProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.DeleteAll();
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Validate(Disk, DocumentSendingProfile.Disk::"Electronic Document");
        DocumentSendingProfile.Validate("Disk Format", FatturaPA_ElectronicFormatTxt);
        DocumentSendingProfile.Validate(Default, true);
        DocumentSendingProfile.Insert();
    end;

    procedure UpdateFatturaCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(IBAN, 'IT60X0542811101000000123456');
        // valid IBAN needed
        CompanyInformation.Validate("Fiscal Code", 'VNTRTR89B16Z154M');
        // valid Fiscal Code needed
        CompanyInformation.Validate("Country/Region Code", 'IT');
        CompanyInformation.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code"));
        CompanyInformation.Validate("REA No.", LibraryUtility.GenerateRandomText(10));
        CompanyInformation.Validate("Registry Office Province", LibraryUtility.GenerateRandomAlphabeticText(2, 0));
        CompanyInformation.Validate("Company Type", GetRandomCompanyType());
        CompanyInformation.Validate(Address, LibraryUtility.GenerateRandomText(10));
        CompanyInformation.Validate("Post Code", CopyStr(LibraryUtility.GenerateRandomNumericText(5), 1, MaxStrLen(CompanyInformation."Post Code")));
        CompanyInformation.Validate(County, LibraryUtility.GenerateRandomAlphabeticText(2, 0));
        CompanyInformation.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        CompanyInformation.Modify(true);
    end;

    procedure UpdatePaidInCapitalInCompanyInformation(PaidInCapital: Decimal)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Paid-In Capital", PaidInCapital);
        CompanyInformation.Modify(true);
    end;

    local procedure InsertFatturaNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.FindFirst();
        NoSeriesLine.Validate("Starting No.", '1001');
        NoSeriesLine.Validate("Ending No.", '1999');
        NoSeriesLine.Validate("Last No. Used", '1995');
        NoSeriesLine.Modify(true);
        exit(NoSeries.Code);
    end;

    [Scope('OnPrem')]
    procedure ClearAllXMLFilesInTempFolder()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        ServerFileName: Text[250];
    begin
        ServerFileName := CopyStr(FileManagement.ServerTempFileName('xml'), 1, MaxStrLen(ServerFileName));
        FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, FileManagement.GetDirectoryName(ServerFileName));
        TempNameValueBuffer.SetFilter(Name, '*.xml');
        if TempNameValueBuffer.FindSet() then
            repeat
                FileManagement.DeleteServerFile(TempNameValueBuffer.Name);
            until TempNameValueBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure LoadTempXMLBufferFromTempBlob(var TempXMLBuffer: Record "XML Buffer" temporary; TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
    end;
}

