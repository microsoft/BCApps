codeunit 143002 "Library - VAT Utils"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        FEInvoicesIssuedTxt: Label 'FE';
        FRInvoicesReceivedTxt: Label 'FR';
        NECreditMemosIssuedTxt: Label 'NE';
        NRCreditMemosReceivedTxt: Label 'NR';
        FNNonResidentsSalesTxt: Label 'FN';
        SENonResidentsPurchasesTxt: Label 'SE';

    [Scope('OnPrem')]
    procedure AdjustAmountSign(Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if ((DocumentType = GenJournalLine."Document Type"::Invoice) and (AccountType = GenJournalLine."Account Type"::Vendor)) or
           ((DocumentType = GenJournalLine."Document Type"::Refund) and (AccountType = GenJournalLine."Account Type"::Vendor)) or
           ((DocumentType = GenJournalLine."Document Type"::Payment) and (AccountType = GenJournalLine."Account Type"::Customer)) or
           ((DocumentType = GenJournalLine."Document Type"::"Credit Memo") and
            (AccountType = GenJournalLine."Account Type"::Customer)) or
           ((DocumentType = GenJournalLine."Document Type"::Invoice) and
            (AccountType = GenJournalLine."Account Type"::"G/L Account") and
            (GenPostingType = GenJournalLine."Gen. Posting Type"::Sale)) or
           ((DocumentType = GenJournalLine."Document Type"::"Credit Memo") and
            (AccountType = GenJournalLine."Account Type"::"G/L Account") and
            (GenPostingType = GenJournalLine."Gen. Posting Type"::Purchase))
        then
            Amount := -Abs(Amount);
        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        Delta: Decimal;
        ThresholdDiff: Decimal;
    begin
        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta := LibraryRandom.RandDec(GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false), 2);

        if not InclInVATTransRep then
            Delta := -Delta;

        // The threshold of 3.000 Euro (Vat excluded) for the invoices is removed, testing for threshold value of 0 and amount under 3000
        ThresholdDiff := GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false);
        if ThresholdDiff = 0 then
            Delta := LibraryRandom.RandDec(3000, 2);    // When threshold is set to 0

        Amount := GetThresholdAmount(StartingDate, InclVAT) + Delta;
    end;

    [Scope('OnPrem')]
    procedure CreateAccount(GenPostingType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; IndividualPerson: Boolean; Resident: Option; InclVAT: Boolean; UsingFiscalCode: Boolean) AccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                AccountNo := CreateGLAccount(GenPostingType);
            GenJournalLine."Account Type"::Customer:
                AccountNo := CreateCustomer(IndividualPerson, Resident, true, InclVAT, UsingFiscalCode);
            GenJournalLine."Account Type"::Vendor:
                AccountNo := CreateVendor(IndividualPerson, Resident, true, InclVAT, UsingFiscalCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean; UsingFiscalCode: Boolean): Code[20]
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
            if UsingFiscalCode then
                Customer."Fiscal Code" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer);
            if Resident = Customer.Resident::"Non-Resident" then
                Customer.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Customer.Validate(
                  "VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer))
            else
                if Resident = Customer.Resident::"Non-Resident" then begin
                    Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
                    Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
                    Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                    Customer.Validate(
                      "Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer));
                end;
        end;

        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLineWithFiscalCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UsingFiscalCode: Boolean)
    var
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        // Set the amount
        Amount := CalculateAmount(WorkDate(), true, true);

        // Create Account.
        AccountNo := CreateAccount(GenPostingType, AccountType, IndividualPerson, Resident, false, UsingFiscalCode);

        // Create Gen. Journal Line.
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, AccountNo, Amount);

        // Update Individual Person, Resident.
        if AccountType = GenJournalLine."Account Type"::"G/L Account" then begin
            GenJournalLine.Validate("Individual Person", IndividualPerson);
            GenJournalLine.Validate(Resident, Resident);
            GenJournalLine.Modify(true);
        end;

        // Update Required Fields like VAT Registration No., Fiscal Code.
        UpdateReqFldsGenJnlLine(GenJournalLine, UsingFiscalCode);
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BalAccountType: Enum "Gen. Journal Account Type";
        BalAccountNo: Code[20];
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"Bank Account";
                    BalAccountNo := FindBankAccount();
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
        end;
        Amount := AdjustAmountSign(Amount, DocumentType, AccountType, GenPostingType);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccount(GenPostingType: enum "General Posting Type"): Code[20]
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

    [Scope('OnPrem')]
    procedure CreatePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UsingFiscalCode: Boolean)
    begin
        CreateGenJnlLineWithFiscalCodeAndVATRegNo(
          GenJournalLine, DocumentType, AccountType, GenPostingType, IndividualPerson, Resident, UsingFiscalCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure CreateVATReport(var VATReportHeader: Record "VAT Report Header"; var VATReportLine: Record "VAT Report Line"; VATReportConfigCode: Option; StartDate: Date; EndDate: Date)
    begin
        CreateVATReportHeader(VATReportHeader, VATReportConfigCode, VATReportHeader."VAT Report Type"::Standard, StartDate, EndDate);
        CreateVATReportLines(VATReportHeader, VATReportLine);
    end;

    [Scope('OnPrem')]
    procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; VATReportConfigCode: Option; VATReportType: Option; StartDate: Date; EndDate: Date)
    begin
        VATReportHeader.Init();
        VATReportHeader."No." := LibraryUtility.GenerateGUID();
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("VAT Report Config. Code", VATReportConfigCode);
        VATReportHeader.Validate("VAT Report Type", VATReportType);
        VATReportHeader.Validate("Start Date", StartDate);
        VATReportHeader.Validate("End Date", EndDate);
        VATReportHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATReportLines(var VATReportHeader: Record "VAT Report Header"; var VATReportLine: Record "VAT Report Line")
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        // Get VAT Report Lines.
        VATReportMediator.GetLines(VATReportHeader);

        // Find VAT Report Lines.
        VATReportLine.SetFilter("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.FindFirst() then; // No lines is expected result for certain Credit Memo scenarios.
    end;

    [Scope('OnPrem')]
    procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert(true);
        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Validate(
          "Intermediary VAT Reg. No.", Format(LibraryRandom.RandIntInRange(10000, 99999)) +
          Format(LibraryRandom.RandIntInRange(100000, 999999)));
        VATReportSetup.Modify(true);

        SetupCompanyInformation();
    end;

    [Scope('OnPrem')]
    procedure CreateVATTransReportAmount(var VATTransactionReportAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransactionReportAmount.Init();
        VATTransactionReportAmount.Validate("Starting Date", StartingDate);
        VATTransactionReportAmount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean; UsingFiscalCode: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Individual Person", IndividualPerson);
        Vendor.Validate(Resident, Resident);

        if ReqFlds then begin
            if UsingFiscalCode then
                Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor);
            if Resident = Vendor.Resident::"Non-Resident" then
                Vendor.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Vendor.Validate(
                  "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor))
            else
                if Resident = Vendor.Resident::"Non-Resident" then begin
                    Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
                    Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
                    Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                    Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
                end;
        end;

        Vendor.Validate("Prices Including VAT", PricesInclVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure FindMaxVATRate(VATCalculationType: Enum "Tax Calculation Type") VATRate: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.SetFilter("VAT %", '>0');
        VATPostingSetup.SetRange("Deductible %", 100);
        if VATPostingSetup.FindSet() then begin
            repeat
                if VATPostingSetup."VAT %" > VATRate then
                    VATRate := VATPostingSetup."VAT %"
            until VATPostingSetup.Next() = 0;
            VATPostingSetup.SetRange("VAT %", VATRate);
            VATPostingSetup.FindFirst();
        end;
    end;

    [Scope('OnPrem')]
    procedure FindGLAccount(VATProdGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.SetFilter("Gen. Bus. Posting Group", '');
        GLAccount.SetFilter("Gen. Prod. Posting Group", '');
        GLAccount.SetFilter("VAT Bus. Posting Group", '');
        GLAccount.SetFilter("VAT Prod. Posting Group", VATProdGroup);
        GLAccount.FindFirst();
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure GenerateVATRegistrationNumber(): Text[20]
    begin
        exit(Format(LibraryRandom.RandIntInRange(10000, 99999)) + Format(LibraryRandom.RandIntInRange(100000, 999999)));
    end;

    [Scope('OnPrem')]
    procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetRange("Intrastat Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure GetPostingDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Operation Occurred Date");
        VATEntry.FindLast();
        if VATEntry."Posting Date" > WorkDate() then
            exit(CalcDate('<1D>', VATEntry."Posting Date"));
        exit(CalcDate('<1D>', WorkDate()));
    end;

    [Scope('OnPrem')]
    procedure GetThresholdAmount(StartingDate: Date; InclVAT: Boolean) Amount: Decimal
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

    [Scope('OnPrem')]
    procedure GetAmountBiggerThanThreshold(StartingDate: Date; InclVAT: Boolean): Decimal
    begin
        exit(GetThresholdAmount(StartingDate, InclVAT) + LibraryRandom.RandIntInRange(1, 1000));
    end;

    [Scope('OnPrem')]
    procedure GetAmountLessThanThreshold(StartingDate: Date; InclVAT: Boolean): Decimal
    var
        Amount: Decimal;
    begin
        Amount := GetThresholdAmount(StartingDate, InclVAT);
        exit(Amount - LibraryRandom.RandIntInRange(0, Amount - 1));
    end;

    [Scope('OnPrem')]
    procedure IsCreditMemo(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              ((VATEntry.Type = VATEntry.Type::Sale) and (TotalVATEntryBase(VATEntry) > 0)) or
              ((VATEntry.Type = VATEntry.Type::Purchase) and (TotalVATEntryBase(VATEntry) < 0)));
    end;

    [Scope('OnPrem')]
    procedure IsInvoice(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              ((VATEntry.Type = VATEntry.Type::Sale) and (TotalVATEntryBase(VATEntry) < 0)) or
              ((VATEntry.Type = VATEntry.Type::Purchase) and (TotalVATEntryBase(VATEntry) > 0)));
    end;

    [Scope('OnPrem')]
    procedure SetupCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Fiscal Code" := LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Fiscal Code"), DATABASE::"Company Information");
        CompanyInformation."VAT Registration No." := Format(LibraryRandom.RandIntInRange(10000, 99999)) +
          Format(LibraryRandom.RandIntInRange(100000, 999999));
        CompanyInformation.Validate(County, LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo(County), DATABASE::"Company Information"));
        CompanyInformation.Validate("Industrial Classification", '35.11.00');
        CompanyInformation.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupThresholdAmount(StartingDate: Date; UseThreshold: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransactionReportAmount, StartingDate);
        VATRate := FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        if UseThreshold then
            ThresholdAmount := 1000 * LibraryRandom.RandInt(10)
        else
            ThresholdAmount := 0;
        VATTransactionReportAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransactionReportAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);
        VATTransactionReportAmount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure SetupUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        EnableUnrealizedVAT(true);

        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.FindFirst();
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", FindGLAccount(''));
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", FindGLAccount(''));
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure TotalVATEntryBase(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Base + VATEntry."Nondeductible Base" + VATEntry."Unrealized Base");
    end;

    [Scope('OnPrem')]
    procedure TotalVATEntryAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Amount + VATEntry."Nondeductible Amount" + VATEntry."Unrealized Amount");
    end;

    [Scope('OnPrem')]
    procedure UpdateReqFldsGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; UsingFiscalCode: Boolean)
    begin
        // Update fields required for posting when Incl. in VAT Transac. Report is TRUE.
        if GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident" then
            GenJournalLine.Validate("Country/Region Code", GetCountryCode());

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then begin
            GenJournalLine.Validate("First Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("First Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Last Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Last Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            GenJournalLine.Validate("Place of Birth", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Place of Birth"), DATABASE::"Gen. Journal Line"));
        end;

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) and UsingFiscalCode then
            GenJournalLine."Fiscal Code" := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Fiscal Code"), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        if not GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) then
            GenJournalLine."VAT Registration No." := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("VAT Registration No."), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        GenJournalLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateVATPostingSetup(InclInVATTransRep: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.FindFirst();

        VATPostingSetup.Validate("Include in VAT Transac. Rep.", InclInVATTransRep);
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyGetLn(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option; UseThreshold: Boolean; UsingFiscalCode: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Setup.
        WorkDate(GetPostingDate());

        SetupThresholdAmount(WorkDate(), UseThreshold);

        UpdateVATPostingSetup(true);

        // Create and Post Gen. Journal Line.
        CreatePostGenJnlLine(GenJournalLine, DocumentType, AccountType, GenPostingType, IndividualPerson, Resident, UsingFiscalCode);

        // Create VAT Report.
        CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report", WorkDate(), WorkDate());

        // Verify VAT Report Line.
        VerifyVATReportLine(VATReportLine);
    end;

    [Scope('OnPrem')]
    procedure VerifyVATReportLine(VATReportLine: Record "VAT Report Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        // Find VAT Entry.
        VATEntry.Get(VATReportLine."VAT Entry No.");
        // Verify VAT Report Line using VAT Entry (W1 fields).
        VATReportLine.TestField("Posting Date", VATEntry."Posting Date");
        VATReportLine.TestField("Document No.", VATEntry."Document No.");
        VATReportLine.TestField("Document Type", VATEntry."Document Type");
        VATReportLine.TestField(Type, VATEntry.Type);
        VATReportLine.TestField(Base, TotalVATEntryBase(VATEntry));
        VATReportLine.TestField(Amount, TotalVATEntryAmount(VATEntry));
        VATReportLine.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type");
        VATReportLine.TestField("Bill-to/Pay-to No.", VATEntry."Bill-to/Pay-to No.");
        VATReportLine.TestField("EU 3-Party Trade", VATEntry."EU 3-Party Trade");
        VATReportLine.TestField("Source Code", VATEntry."Source Code");
        VATReportLine.TestField("Reason Code", VATEntry."Reason Code");
        VATReportLine.TestField("Country/Region Code", VATEntry."Country/Region Code");
        VATReportLine.TestField("Internal Ref. No.", VATEntry."Internal Ref. No.");
        VATReportLine.TestField("Unrealized Amount", 0);
        VATReportLine.TestField("Unrealized Base", 0);
        VATReportLine.TestField("External Document No.", VATEntry."External Document No.");
        VATReportLine.TestField("VAT Registration No.", VATEntry."VAT Registration No.");
        // Verify VAT Report Line using VAT Entry (IT fields).
        VATReportLine.TestField("Operation Occurred Date", VATEntry."Operation Occurred Date");
        VATReportLine.TestField("Amount Incl. VAT", TotalVATEntryBase(VATEntry) + TotalVATEntryAmount(VATEntry));

        VerifyVatReportLineRecordId(VATEntry, VATReportLine);
    end;

    local procedure VerifyVatReportLineRecordId(VATEntry: Record "VAT Entry"; VATReportLine: Record "VAT Report Line")
    begin
        // Verify Record Identifier.
        if VATEntry.Resident = VATEntry.Resident::Resident then begin
            if IsInvoice(VATEntry) then begin
                if VATEntry.Type = VATEntry.Type::Sale then
                    VATReportLine.TestField("Record Identifier", FEInvoicesIssuedTxt)
                else
                    if VATEntry.Type = VATEntry.Type::Purchase then
                        VATReportLine.TestField("Record Identifier", FRInvoicesReceivedTxt);
            end else
                if IsCreditMemo(VATEntry) then
                    if VATEntry.Type = VATEntry.Type::Sale then
                        VATReportLine.TestField("Record Identifier", NECreditMemosIssuedTxt)
                    else
                        if VATEntry.Type = VATEntry.Type::Purchase then
                            VATReportLine.TestField("Record Identifier", NRCreditMemosReceivedTxt);
        end else
            // TODO: check that the country is Non-EU
            if VATEntry.Type = VATEntry.Type::Sale then
                VATReportLine.TestField("Record Identifier", FNNonResidentsSalesTxt)
            else
                if VATEntry.Type = VATEntry.Type::Purchase then
                    VATReportLine.TestField("Record Identifier", SENonResidentsPurchasesTxt);
    end;

    [Scope('OnPrem')]
    procedure TearDown()
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
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

        VATTransactionReportAmount.DeleteAll(true);
        EnableUnrealizedVAT(false);
    end;
}

