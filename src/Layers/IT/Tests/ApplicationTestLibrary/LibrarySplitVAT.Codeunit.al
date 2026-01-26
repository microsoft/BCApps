codeunit 143003 "Library - Split VAT"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";

    procedure AddSalesLine(SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; LineAmountExcludingVAT: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Add a line to the header
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithVATProdPostGroup(VATProdPostingGroup), 1);
        SalesLine.Validate("Unit Price", LineAmountExcludingVAT);
        SalesLine.Validate(Reserve, SalesLine.Reserve::Always);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithVATProdPostGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Service Document Type"; VATBusPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode));
    end;

    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATProdPostGroup(VATProdPostingGroupCode), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; VATBusPostingGroupCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode));
    end;

    procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          CreateItemWithVATProdPostGroup(VATProdPostingGroupCode));
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    procedure CreateServiceDoc(var ServiceHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, VATPostingSetup."VAT Bus. Posting Group");
        CreateServiceLine(ServiceLine, ServiceHeader, VATPostingSetup."VAT Prod. Posting Group");
    end;

    procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATBusinessPostingGroupCode = '' then begin
            LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            VATBusinessPostingGroupCode := VATBusinessPostingGroup.Code;
        end;
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."VAT Transaction Nature" := CreateVATTransactionNatureCode();
        VATPostingSetup.Modify(true);
    end;

    procedure CreateVATPostingSetupForSplitVAT(var VATPostingSetup: Record "VAT Posting Setup"; var SplitVATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Decimal)
    begin
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group");
        VATPostingSetup.Validate("VAT %", VATPercentage);
        VATPostingSetup.Modify(true);

        CreateVATPostingSetup(SplitVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group");
        SplitVATPostingSetup."Reversed VAT Bus. Post. Group" := VATPostingSetup."VAT Bus. Posting Group";
        SplitVATPostingSetup."Reversed VAT Prod. Post. Group" := VATPostingSetup."VAT Prod. Posting Group";
        SplitVATPostingSetup.Modify(true);
    end;

    procedure CreateVATTransactionNatureCode(): Code[4]
    var
        VATTransactionNature: Record "VAT Transaction Nature";
    begin
        VATTransactionNature.Init();
        VATTransactionNature.Code := CopyStr(LibraryUtility.GenerateRandomCode(VATTransactionNature.FieldNo(Code), DATABASE::"VAT Transaction Nature"), 1, MaxStrLen(VATTransactionNature.Code));
        VATTransactionNature.Description := LibraryUtility.GenerateGUID();
        VATTransactionNature.Insert(true);

        exit(VATTransactionNature.Code);
    end;

    procedure UpdateVATPostingSetupFullVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Modify(true);
    end;

    procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; AutomaticallyGenerated: Boolean)
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Automatically Generated", AutomaticallyGenerated);
        SalesLine.FindFirst();
    end;

    procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; AutomaticallyGenerated: Boolean)
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Automatically Generated", AutomaticallyGenerated);
        ServiceLine.FindFirst();
    end;
}

