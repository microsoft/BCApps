codeunit 143305 "Library - 340 347 Declaration"
{

    trigger OnRun()
    begin
    end;

    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        IncorrectVATSetupErr: Label 'Incorrect use of setup function: VATCashRegime can only be TRUE if UnrealizedVAT is TRUE.';

    [Scope('OnPrem')]
    procedure CreateAndPostPaymentForPI(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();

        if GenJournalLine.FindLast() then
            GenJournalLine.Init();
        GenJournalLine."Line No." += 1;

        GenJournalLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Posting Date", PostingDate);

        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");

        case DocumentType of
            GenJournalLine."Applies-to Doc. Type"::Invoice:
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine."Applies-to Doc. Type"::"Credit Memo":
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Refund);
        end;
        if GenJournalBatch."No. Series" <> '' then
            GenJournalLine."Document No." := NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series", PostingDate)
        else
            GenJournalLine."Document No." := 'PMT' + PadStr(DocumentNo, 17);

        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", VendorNo);
        GenJournalLine.Validate("Applies-to Doc. Type", DocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);

        GenJournalLine.Validate(Amount, Amount);

        GenJournalLine.Insert(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(GenJournalLine."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPaymentForSI(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();

        if GenJournalLine.FindLast() then
            GenJournalLine.Init();
        GenJournalLine."Line No." += 1;

        GenJournalLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Posting Date", PostingDate);

        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");

        case DocumentType of
            GenJournalLine."Applies-to Doc. Type"::Invoice:
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine."Applies-to Doc. Type"::"Credit Memo":
                GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Refund);
        end;
        if GenJournalBatch."No. Series" <> '' then
            GenJournalLine."Document No." := NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series", PostingDate)
        else
            GenJournalLine."Document No." := 'PMT' + PadStr(DocumentNo, 17);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustomerNo);

        GenJournalLine.Validate("Applies-to Doc. Type", DocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);

        GenJournalLine.Validate(Amount, -Amount);
        GenJournalLine.Insert(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseCrMemo(VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; PostingDate: Date; var Amount: Decimal; var ExtCrMemoNo: Code[35]; ApplyToInvNo: Code[20]) CrMemoNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        InvVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", 'EXT.' + PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader."Corrected Invoice No." := 'X';
        PurchaseHeader.Modify(true);
        ExtCrMemoNo := PurchaseHeader."Vendor Cr. Memo No.";

        CreatePurchaseLine(VATPostingSetup, PurchaseHeader, Amount);

        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        if ApplyToInvNo <> '' then begin
            VendLedgEntry.FindLast();
            VendLedgEntry.CalcFields("Remaining Amount");
            LibraryERM.SetApplyVendorEntry(VendLedgEntry, VendLedgEntry."Remaining Amount");
            InvVendLedgEntry.SetRange("Document No.", ApplyToInvNo);
            InvVendLedgEntry.FindLast();
            LibraryERM.SetAppliestoIdVendor(InvVendLedgEntry);
            LibraryERM.PostVendLedgerApplication(VendLedgEntry);
        end;

        exit(CrMemoNo);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; PostingDate: Date; var Amount: Decimal; var ExtDocumentNo: Code[35]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Invoice No.", 'EXT.' + PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        ExtDocumentNo := PurchaseHeader."Vendor Invoice No.";

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Random - Quantity.
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        Amount := PurchaseLine."Line Amount";

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostServiceInvoice(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PostingDate: Date; var Amount: Decimal): Code[20]
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo, PostingDate);

        Amount := CreateServiceLine(ServiceHeader, VATPostingSetup);

        Ship := true;
        Invoice := true;
        ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);

        exit(ServiceHeader."Last Posting No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostServiceCrMemo(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PostingDate: Date; var Amount: Decimal): Code[20]
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate);

        Amount := CreateServiceLine(ServiceHeader, VATPostingSetup);

        Ship := true;
        Invoice := true;
        ServicePost.PostWithLines(ServiceHeader, TempServiceLine, Ship, Consume, Invoice);

        exit(ServiceHeader."Last Posting No.");
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesCrMemo(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PostingDate: Date; var Amount: Decimal; ApplyToInvNo: Code[20]) CrMemoNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        InvCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate, PostingDate);
        SalesHeader."Corrected Invoice No." := ApplyToInvNo;
        if ApplyToInvNo = '' then
            SalesHeader."Corrected Invoice No." := 'X';
        Amount := CreateSalesLine(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", Amount);
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        if ApplyToInvNo <> '' then begin
            CustLedgEntry.FindLast();
            CustLedgEntry.CalcFields("Remaining Amount");
            LibraryERM.SetApplyCustomerEntry(CustLedgEntry, CustLedgEntry."Remaining Amount");
            InvCustLedgEntry.SetRange("Document No.", ApplyToInvNo);
            InvCustLedgEntry.FindLast();
            LibraryERM.SetAppliestoIdCustomer(InvCustLedgEntry);
            LibraryERM.PostCustLedgerApplication(CustLedgEntry);
        end;

        exit(CrMemoNo);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoice(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PostingDate: Date; var Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, PostingDate);
        Amount := CreateSalesLine(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer; VATBusinessPostingGroupCode: Code[20])
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."VAT Bus. Posting Group" := VATBusinessPostingGroupCode;
        Customer."Country/Region Code" := 'ES';
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."VAT Registration No." :=
          CopyStr(LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code), 2, 9);
        Customer.Address := 'Frydenlunds Alle 6';
        Customer."Post Code" := 'DK-8000';
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor; VATBusinessPostingGroupCode: Code[20])
    var
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."VAT Bus. Posting Group" := VATBusinessPostingGroupCode;
        Vendor.Validate("Country/Region Code", 'ES');
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor."VAT Registration No." :=
          CopyStr(LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code), 2, 9);
        Vendor."Post Code" := PostCode.Code;
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItem(var Item: Record Item; VATProdPostingGroupCode: Code[20]) ItemCode: Code[20]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
        ItemCode := LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PurchaseGLAccount: Record "G/L Account";
        ReverseChrgGLAccount: Record "G/L Account";
    begin
        if VATBusinessPostingGroupCode = '' then begin
            LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            VATBusinessPostingGroupCode := VATBusinessPostingGroup.Code;
        end;
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);

        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryERM.CreateGLAccount(PurchaseGLAccount);
        LibraryERM.CreateGLAccount(ReverseChrgGLAccount);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseGLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", ReverseChrgGLAccount."No.");
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandIntInRange(3, 5));
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLine(var VATPostingSetup: Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header"; var Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Random - Quantity.
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        if Amount = 0 then
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(500, 1000))
        else
            PurchaseLine.Validate("Direct Unit Cost", Amount / PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        Amount := PurchaseLine."Line Amount";
    end;

    [Scope('OnPrem')]
    procedure CreateServiceLine(var ServiceHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader,
          ServiceLine.Type::Item,
          CreateItem(Item, VATPostingSetup."VAT Prod. Posting Group"));

        ServiceLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(2, 5));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        ServiceLine.Modify(true);

        exit(ServiceLine."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; VATProdPostingGrCode: Code[20]; Amount: Decimal): Decimal
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(Item, VATProdPostingGrCode), LibraryRandom.RandIntInRange(2, 5));
        if Amount = 0 then
            SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(500, 1000))
        else
            SalesLine.Validate("Unit Price", Amount / SalesLine.Quantity);
        SalesLine.Modify(true);
        exit(SalesLine."Line Amount");
    end;

    [Scope('OnPrem')]
    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date; DocumentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
    begin
        if UseUnrealizedVAT then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.Validate("Unrealized VAT", true);
            GeneralLedgerSetup.Modify(true);
        end;

        if UseVATCashRegime then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.Validate("VAT Cash Regime", true);
            GeneralLedgerSetup.Modify(true);
        end;

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate(
          "VAT Identifier", LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", 5);
        if UseUnrealizedVAT then begin
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
            VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
            VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        end;
        if UseVATCashRegime then
            VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure RunMake340DeclarationReportWithGLAcc(PostingDate: Date; NewGLAccount: Text[20]) ExportFileName: Text[1024]
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        ExportFileName := TemporaryPath + 'ES340.txt';
        if Exists(ExportFileName) then
            Erase(ExportFileName);

        Clear(Make340Declaration);
        Make340Declaration.UseRequestPage(true);
        Make340Declaration.InitializeRequest(
          Format(Date2DMY(PostingDate, 3)),
          Date2DMY(PostingDate, 2),
          'ElCODE',
          GenerateRandomNumericalText(9),
          GenerateRandomNumericalText(4),
          GenerateRandomNumericalText(16),
          0,
          false,
          '',
          ExportFileName,
          NewGLAccount,
          0.0);
        Make340Declaration.RunModal();
        Make340Declaration.GetServerFileName(ExportFileName);
    end;

    [Scope('OnPrem')]
    procedure RunMake340DeclarationReport(PostingDate: Date): Text[1024]
    begin
        exit(RunMake340DeclarationReportWithGLAcc(PostingDate, ''));
    end;

    [Scope('OnPrem')]
    procedure GetLine340Amount(Line: Text; StartingPosition: Integer; IsTotal: Boolean) Result: Decimal
    var
        Length: Integer;
    begin
        if IsTotal then
            Length := 17
        else
            Length := 13;

        Evaluate(Result, CopyStr(Line, StartingPosition + 1, Length));
        Result /= 100;

        if CopyStr(Line, StartingPosition, 1) = 'N' then
            Result := -Result;
    end;

    [Scope('OnPrem')]
    procedure SetupVATType(UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if UseVATCashRegime and not UseUnrealizedVAT then
            Error(IncorrectVATSetupErr);

        VATPostingSetup.FindSet();
        repeat
            // The order matters
            if UseUnrealizedVAT then begin
                VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
                VATPostingSetup.Validate("VAT Cash Regime", UseVATCashRegime)
            end else begin
                VATPostingSetup.Validate("VAT Cash Regime", UseVATCashRegime);
                VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
            end;
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;

        GeneralLedgerSetup.Get();

        // The order matters
        if UseVATCashRegime then begin
            GeneralLedgerSetup.Validate("Unrealized VAT", UseUnrealizedVAT);
            GeneralLedgerSetup.Validate("VAT Cash Regime", UseVATCashRegime)
        end else begin
            GeneralLedgerSetup.Validate("VAT Cash Regime", UseVATCashRegime);
            GeneralLedgerSetup.Validate("Unrealized VAT", UseUnrealizedVAT);
        end;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GenerateRandomNumericalText(NumberOfDigit: Integer) ElectronicCode: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            ElectronicCode := InsStr(ElectronicCode, Format(LibraryRandom.RandInt(9)), Counter);  // Random value of 1 digit required.
    end;
}

