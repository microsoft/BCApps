codeunit 130100 "Library - Payment Export"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    procedure GetRandomCreditorNo(): Code[20]
    begin
        exit(LibraryUtility.GenerateGUID() + Format(LibraryRandom.RandIntInRange(111111111, 999999999)));
    end;

    procedure GetRandomPaymentReference(): Code[50]
    var
        RandomValue: Code[10];
    begin
        RandomValue := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        exit(LibraryUtility.GenerateGUID() + RandomValue + RandomValue);
    end;

    procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
    end;

    procedure VerifyGenJnlLineErr(GenJnlLine: Record "Gen. Journal Line"; ExpectedError: Text[250])
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Document No.", GenJnlLine."Document No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJnlLine."Line No.");
        PaymentJnlExportErrorText.SetRange("Error Text", ExpectedError);
        Assert.IsFalse(PaymentJnlExportErrorText.IsEmpty, 'Expected Error message cannot be found.');
    end;

    procedure CreateSimpleDataExchDefWithMapping(var DataExchMapping: Record "Data Exch. Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CreateSimpleDataExchDefWithMapping2(DataExchDef, DataExchMapping, DataExchFieldMapping, TableID, FieldID);
    end;

    procedure CreateSimpleDataExchDefWithMapping2(var DataExchDef: Record "Data Exch. Def"; var DataExchMapping: Record "Data Exch. Mapping"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColDef: Record "Data Exch. Column Def";
        DataExchDefCode: Code[20];
        DataExchLineDefCode: Code[20];
    begin
        DataExchDefCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef.Init();
        DataExchDef.Code := DataExchDefCode;
        DataExchDef.Name := DataExchDef.Code;
        DataExchDef.Type := DataExchDef.Type::"Payment Export";
        DataExchDef.Insert();

        DataExchLineDefCode := LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Init();
        DataExchLineDef.Code := DataExchLineDefCode;
        DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchLineDef.Insert();

        DataExchColDef.Init();
        DataExchColDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchColDef."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchColDef."Column No." := 1;
        DataExchColDef.Insert();

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchMapping."Table ID" := TableID;
        DataExchMapping.Insert();

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Column No." := 1;
        DataExchFieldMapping."Field ID" := FieldID;
        DataExchFieldMapping.Insert();
    end;

    procedure SelectPaymentJournalTemplate(): Code[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Payments);
        GenJnlTemplate.SetRange(Recurring, false);

        if not GenJnlTemplate.FindFirst() then begin
            GenJnlTemplate.Init();
            GenJnlTemplate.Name := LibraryUtility.GenerateRandomCode(GenJnlTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
            GenJnlTemplate.Type := GenJnlTemplate.Type::Payments;
            GenJnlTemplate.Recurring := false;
            GenJnlTemplate.Insert();
        end;

        exit(GenJnlTemplate.Name);
    end;

    procedure SetPmtToDomestic(var BankAccount: Record "Bank Account"; var VendorBankAccount: Record "Vendor Bank Account")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        BankAccount."Country/Region Code" := CompanyInformation."Country/Region Code";
        BankAccount.Modify(true);
        VendorBankAccount."Country/Region Code" := BankAccount."Country/Region Code";
        VendorBankAccount.Modify(true);
    end;

    procedure SetPmtToInternational(var BankAccount: Record "Bank Account"; var VendorBankAccount: Record "Vendor Bank Account")
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        BankAccount."Country/Region Code" := CompanyInformation."Country/Region Code";
        BankAccount.Modify(true);
        CountryRegion.SetFilter(Code, '<>%1', BankAccount."Country/Region Code");
        CountryRegion.FindFirst();
        VendorBankAccount."Country/Region Code" := CountryRegion.Code;
        VendorBankAccount.Modify(true);
    end;

    procedure SetRefundToDomestic(var BankAccount: Record "Bank Account"; var CustomerBankAccount: Record "Customer Bank Account")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        BankAccount."Country/Region Code" := CompanyInformation."Country/Region Code";
        BankAccount.Modify(true);
        CustomerBankAccount."Country/Region Code" := BankAccount."Country/Region Code";
        CustomerBankAccount.Modify(true);
    end;

    procedure SetRefundToInternational(var BankAccount: Record "Bank Account"; var CustomerBankAccount: Record "Customer Bank Account")
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        BankAccount."Country/Region Code" := CompanyInformation."Country/Region Code";
        BankAccount.Modify(true);
        CountryRegion.SetFilter(Code, '<>%1', BankAccount."Country/Region Code");
        CountryRegion.FindFirst();
        CustomerBankAccount."Country/Region Code" := CountryRegion.Code;
        CustomerBankAccount.Modify(true);
    end;

    procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        PaymentMethod: Record "Payment Method";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);

        VendorBankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(111111, 999999));
        VendorBankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        VendorBankAccount.Modify();
    end;

    procedure CreatePaymentExportBatch(var GenJournalBatch: Record "Gen. Journal Batch"; DataExchDefCode: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        CreateBankAccount(BankAccount);
        CreateBankExportImportSetup(BankExportImportSetup, DataExchDefCode);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Modify();
        CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", BankAccount."No.", true);
    end;

    procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(111111, 999999));
        BankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        BankAccount.Modify();
    end;

    procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; DataExchDefCode: Code[20])
    begin
        if BankExportImportSetup.Get(DataExchDefCode) then
            BankExportImportSetup.Delete();
        BankExportImportSetup.Reset();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();
    end;

    procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AllowPaymentExport: Boolean)
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Validate("Allow Payment Export", AllowPaymentExport);
        GenJournalBatch.Modify(true);
    end;

    procedure CreateVendorPmtJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, LibraryRandom.RandDec(1000, 2));
    end;
}

