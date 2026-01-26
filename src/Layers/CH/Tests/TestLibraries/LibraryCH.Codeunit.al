codeunit 143001 "Library - CH"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Scope('OnPrem')]
    procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; VATStatementCipher: Code[20]; AmountType: Enum "VAT Statement Line Amount Type"; VATPostingType: Enum "General Posting Type")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        CreateVATStatementNameWithTemplate(VATStatementName, VATStatementLine);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Account Totaling", GLAccountNo);
        VATStatementLine.Validate("Gen. Posting Type", VATPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate("VAT Statement Cipher", VATStatementCipher);
        VATStatementLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; SalesVATStatCipher: Code[20]; PurchaseVATStatCipher: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(25, 2));
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Stat. Cipher", SalesVATStatCipher);
        VATPostingSetup.Validate("Purch. VAT Stat. Cipher", PurchaseVATStatCipher);
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure CreateVATStatementNameWithTemplate(var VATStatementName: Record "VAT Statement Name"; VATStatementLine: Record "VAT Statement Line")
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        if VATStatementLine."Statement Template Name" = '' then begin
            LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
            LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        end else
            VATStatementName.Get(VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");
    end;
}

