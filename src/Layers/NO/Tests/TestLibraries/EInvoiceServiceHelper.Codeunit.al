codeunit 143010 "E-Invoice Service Helper"
{

    trigger OnRun()
    begin
    end;

    var
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        TestValueTxt: Label 'Test Value';
        EInvoiceSalesHelper: Codeunit "E-Invoice Sales Helper";

    [Scope('OnPrem')]
    procedure SetupEInvoiceForService(Path: Text)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("E-Invoice Service Invoice Path", Path);
        ServiceMgtSetup.Validate("E-Invoice Serv. Cr. Memo Path", Path);
        ServiceMgtSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateServiceInvoice(): Code[20]
    var
        ServHeader: Record "Service Header";
    begin
        CreateServDoc(ServHeader, ServHeader."Document Type"::Invoice);
        exit(PostServOrder(ServHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceInvNoUNECECode()
    var
        ServHeader: Record "Service Header";
    begin
        CreateServDoc(ServHeader, ServHeader."Document Type"::Invoice);
        BlankUNECECodes(ServHeader);
        PostServOrder(ServHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateServiceInvoiceWithCustomerAndSalesPerson(var NewCustomer: Record Customer; SalesPersonCode: Code[20]): Code[20]
    var
        ServHeader: Record "Service Header";
    begin
        EInvoiceHelper.SetCustomer(NewCustomer);
        CreateServDoc(ServHeader, ServHeader."Document Type"::Invoice);
        EInvoiceHelper.ClearCustomer();
        ServHeader."Salesperson Code" := SalesPersonCode;
        ServHeader.Modify(true);
        NewCustomer."No." := ServHeader."Bill-to Customer No.";
        exit(PostServOrder(ServHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceCrMemoWithCustomerAndSalesPerson(var NewCustomer: Record Customer; SalesPersonCode: Code[20]): Code[20]
    var
        ServHeader: Record "Service Header";
    begin
        EInvoiceHelper.SetCustomer(NewCustomer);
        CreateServDoc(ServHeader, ServHeader."Document Type"::"Credit Memo");
        EInvoiceHelper.ClearCustomer();
        ServHeader."Salesperson Code" := SalesPersonCode;
        ServHeader.Modify(true);
        NewCustomer."No." := ServHeader."Bill-to Customer No.";
        exit(PostServOrder(ServHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceCrMemo(): Code[20]
    var
        ServHeader: Record "Service Header";
    begin
        CreateServDoc(ServHeader, ServHeader."Document Type"::"Credit Memo");
        exit(PostServOrder(ServHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceCrMemoNoUNECECode()
    var
        ServHeader: Record "Service Header";
    begin
        CreateServDoc(ServHeader, ServHeader."Document Type"::"Credit Memo");
        BlankUNECECodes(ServHeader);
        PostServOrder(ServHeader);
    end;

    local procedure CreateServDoc(var ServHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        HowManyLinesToCreate: Integer;
        VATProdPostGroupCode: Code[20];
    begin
        CreateServiceHeader(ServHeader, DocumentType);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATProdPostGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        HowManyLinesToCreate := 1 + LibraryRandom.RandInt(5);
        CreateServiceLines(ServHeader, HowManyLinesToCreate, VATProdPostGroupCode);
    end;

    local procedure CreateServiceHeader(var ServHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
    begin
        EInvoiceHelper.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServHeader, DocumentType, Customer."No.");

        ServHeader.Validate("Bill-to Customer No.", Customer."No.");

        ServHeader."Your Reference" := Customer."No.";
        ServHeader."External Document No." := TestValueTxt;

        ServHeader.Modify(true);
    end;

    local procedure CreateServiceLines(ServHeader: Record "Service Header"; NoOfLines: Integer; VATProdPostGroupCode: Code[20])
    var
        ServLine: Record "Service Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do begin
            LibraryService.CreateServiceLine(
              ServLine,
              ServHeader,
              ServLine.Type::Item,
              EInvoiceHelper.CreateItem(VATProdPostGroupCode));
            ServLine.Validate(Quantity, LibraryRandom.RandInt(5));
            ServLine.Modify(true);
        end;
    end;

    local procedure BlankUNECECodes(ServHeader: Record "Service Header")
    var
        ServLine: Record "Service Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        ServLine.SetRange("Document Type", ServHeader."Document Type");
        ServLine.SetRange("Document No.", ServHeader."No.");
        if ServLine.FindSet() then
            repeat
                UnitOfMeasure.Get(ServLine."Unit of Measure");
                if UnitOfMeasure."International Standard Code" <> '' then begin
                    UnitOfMeasure."International Standard Code" := '';
                    UnitOfMeasure.Modify();
                end;
            until ServLine.Next() = 0;
    end;

    local procedure PostServOrder(var ServHeader: Record "Service Header"): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
    begin
        Ship := false;
        Invoice := false;
        Consume := false;
        LibraryService.PostServiceOrder(ServHeader, Ship, Consume, Invoice);

        CustLedgEntry.FindLast();
        exit(CustLedgEntry."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreateServiceInForeignCurrency(DocType: Enum "Service Document Type"): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        EInvoiceHelper.InitExpectedCustomerInfo(Customer);
        Customer.Validate("Currency Code", EInvoiceHelper.CreateExchangeRate(ServiceHeader."Posting Date"));
        EInvoiceHelper.SetCustomer(Customer);
        CreateServDoc(ServiceHeader, DocType);
        EInvoiceHelper.ClearCustomer();
        exit(PostServOrder(ServiceHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceDocWithVATGroups(var ServHeader: Record "Service Header"; VATRate: array[5] of Decimal): Code[20]
    var
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
        i: Integer;
    begin
        CreateServiceHeader(ServHeader, ServHeader."Document Type");

        for i := 1 to ArrayLen(VATRate) do
            if VATRate[i] >= 0 then begin
                NoOfLines := 2;
                VATProdPostingGroupCode := EInvoiceSalesHelper.NewVATPostingSetup(VATRate[i], ServHeader."VAT Bus. Posting Group", false);
                CreateServiceLines(ServHeader, NoOfLines, VATProdPostingGroupCode);
            end;

        exit(PostServOrder(ServHeader));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceDocWithZeroVAT(var ServHeader: Record "Service Header"; IsReverseCharge: Boolean; IsOutsideTaxArea: Boolean): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
    begin
        CreateServiceHeader(ServHeader, ServHeader."Document Type");

        NoOfLines := 2;
        VATProdPostingGroupCode := EInvoiceSalesHelper.NewVATPostingSetup(0, ServHeader."VAT Bus. Posting Group", IsReverseCharge);

        VATProductPostingGroup.Get(VATProdPostingGroupCode);
        VATProductPostingGroup.Validate("Outside Tax Area", IsOutsideTaxArea);
        VATProductPostingGroup.Modify(true);

        CreateServiceLines(ServHeader, NoOfLines, VATProdPostingGroupCode);

        exit(PostServOrder(ServHeader));
    end;
}

