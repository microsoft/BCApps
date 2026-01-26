codeunit 143000 "E-Invoice Sales Helper"
{

    trigger OnRun()
    begin
    end;

    var
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    local procedure BlankUNECECodes(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                UnitOfMeasure.Get(SalesLine."Unit of Measure");
                if UnitOfMeasure."International Standard Code" <> ''
                then begin
                    UnitOfMeasure."International Standard Code" := '';
                    UnitOfMeasure.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        exit(PostSalesOrder(SalesHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoiceNoUNECECode()
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        BlankUNECECodes(SalesHeader);
        PostSalesOrder(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoiceWithCustomerAndSalesPerson(var NewCustomer: Record Customer; SalesPersonCode: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        EInvoiceHelper.SetCustomer(NewCustomer);
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        EInvoiceHelper.ClearCustomer();
        SalesHeader."Salesperson Code" := SalesPersonCode;
        NewCustomer."No." := SalesHeader."Bill-to Customer No.";
        exit(PostSalesOrder(SalesHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesCrMemo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        exit(PostSalesOrder(SalesHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesCrMemoNoUNECECode()
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        BlankUNECECodes(SalesHeader);
        PostSalesOrder(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesCrMemoWithCustomerAndSalesPerson(var NewCustomer: Record Customer; SalesPersonCode: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        EInvoiceHelper.SetCustomer(NewCustomer);
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        EInvoiceHelper.ClearCustomer();
        SalesHeader."Salesperson Code" := SalesPersonCode;
        NewCustomer."No." := SalesHeader."Bill-to Customer No.";
        exit(PostSalesOrder(SalesHeader));
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        HowManyLinesToCreate: Integer;
        VATProdPostGroupCode: Code[20];
    begin
        CreateSalesHeader(SalesHeader, DocumentType);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATProdPostGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        HowManyLinesToCreate := 1 + LibraryRandom.RandInt(5);
        CreateSalesLines(SalesHeader, HowManyLinesToCreate, VATProdPostGroupCode);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocInForeignCurrency(DocType: Enum "Sales Document Type"): Code[20]
    var
        TempCustomer: Record Customer temporary;
        SalesHeader: Record "Sales Header";
    begin
        EInvoiceHelper.InitExpectedCustomerInfo(TempCustomer);
        TempCustomer.Validate("Currency Code", EInvoiceHelper.CreateExchangeRate(SalesHeader."Posting Date"));
        EInvoiceHelper.SetCustomer(TempCustomer);
        CreateSalesDoc(SalesHeader, DocType);
        EInvoiceHelper.ClearCustomer();
        exit(PostSalesOrder(SalesHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocWithVATGroups(var SalesHeader: Record "Sales Header"; VATRate: array[5] of Decimal): Code[20]
    var
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
        i: Integer;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type");

        for i := 1 to ArrayLen(VATRate) do
            if VATRate[i] >= 0 then begin
                NoOfLines := 2;
                VATProdPostingGroupCode := NewVATPostingSetup(VATRate[i], SalesHeader."VAT Bus. Posting Group", false);
                CreateSalesLines(SalesHeader, NoOfLines, VATProdPostingGroupCode);
            end;

        exit(PostSalesOrder(SalesHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocWithZeroVAT(var SalesHeader: Record "Sales Header"; IsReverseCharge: Boolean; IsOutsideTaxArea: Boolean): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type");

        NoOfLines := 2;
        VATProdPostingGroupCode := NewVATPostingSetup(0, SalesHeader."VAT Bus. Posting Group", IsReverseCharge);

        VATProductPostingGroup.Get(VATProdPostingGroupCode);
        VATProductPostingGroup.Validate("Outside Tax Area", IsOutsideTaxArea);
        VATProductPostingGroup.Modify(true);

        CreateSalesLines(SalesHeader, NoOfLines, VATProdPostingGroupCode);

        exit(PostSalesOrder(SalesHeader));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
    begin
        EInvoiceHelper.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");

        SalesHeader."Your Reference" := Customer."No.";
        SalesHeader.Validate("Shipment Date", SalesHeader."Posting Date");

        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLines(SalesHeader: Record "Sales Header"; NoOfLines: Integer; VATProdPostGroupCode: Code[20])
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do
            LibrarySales.CreateSalesLine(
              SalesLine,
              SalesHeader,
              SalesLine.Type::Item,
              EInvoiceHelper.CreateItem(VATProdPostGroupCode),
              LibraryRandom.RandInt(5))
    end;

    [Scope('OnPrem')]
    procedure DefaultUNECERec20Code(): Text[3]
    begin
        exit('NMP');
    end;

    local procedure PostSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Ship: Boolean;
        Invoice: Boolean;
    begin
        Ship := true;
        Invoice := true;
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);

        CustLedgEntry.FindLast();
        exit(CustLedgEntry."Document No.");
    end;

    procedure NewVATPostingSetup(VATRate: Decimal; VATBusPostingGrCode: Code[20]; ReverseCharge: Boolean): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Init();
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGrCode;

        if ReverseCharge then
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT"
        else
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."VAT %" := VATRate;
        VATPostingSetup."VAT Identifier" := 'VAT' + Format(VATRate, 0, '<Integer>');
        VATPostingSetup."Tax Category" := 'AA';
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Insert();

        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;
}

