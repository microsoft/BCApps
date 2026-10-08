codeunit 122006 "Create New Vendor Template"
{
    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        VendorTempl: Record "Vendor Templ.";
        Contact: Record Contact;
        CreatePaymentTerms: Codeunit "Create Payment Terms";
        CreatePaymentMethod: Codeunit "Create Payment Method";
    begin
        DemoDataSetup.Get();

        InsertTemplate(VendorTempl, VendorPersonCodeTxt, VendorPersonDescTxt);
        InsertPostingInfo(VendorTempl, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPaymentInfo(VendorTempl, CreatePaymentTerms.CashOnDeliveryCode(), CreatePaymentMethod.GetCashCode());
        InsertOtherInfo(VendorTempl, Contact.Type::Person, DemoDataSetup."Country/Region Code", true, false);

        InsertTemplate(VendorTempl, VendorCompanyCodeTxt, VendorCompanyDescTxt);
        InsertPostingInfo(VendorTempl, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPaymentInfo(VendorTempl, CreatePaymentTerms.OneMonthEightDaysCode(), CreatePaymentMethod.GetBankCode());
        InsertOtherInfo(VendorTempl, Contact.Type::Company, DemoDataSetup."Country/Region Code", false, false);

        InsertTemplate(VendorTempl, VendorEUCompanyCodeTxt, VendorEUCompanyDescTxt);
        InsertPostingInfo(VendorTempl, DemoDataSetup.EUCode(), DemoDataSetup.EUCode(), DemoDataSetup.EUCode());
        InsertPaymentInfo(VendorTempl, CreatePaymentTerms.FourteenDaysCode(), CreatePaymentMethod.GetBankCode());
        InsertOtherInfo(VendorTempl, Contact.Type::Company, '', false, true);
    end;

    var
        VendorCompanyCodeTxt: Label 'VENDOR COMPANY', MaxLength = 20;
        VendorCompanyDescTxt: Label 'Business-to-Business Vendor (Bank)', MaxLength = 100;
        VendorPersonCodeTxt: Label 'VENDOR PERSON', MaxLength = 20;
        VendorPersonDescTxt: Label 'Cash-Payment Vendor (Cash)', MaxLength = 100;
        VendorEUCompanyCodeTxt: Label 'VENDOR EU COMPANY', MaxLength = 20;
        VendorEUCompanyDescTxt: Label 'EU Vendor (Bank)', MaxLength = 100;

    local procedure InsertTemplate(var VendorTempl: Record "Vendor Templ."; Code: Code[20]; Description: Text[100])
    begin
        VendorTempl.Init();
        VendorTempl.Validate(Code, Code);
        VendorTempl.Validate(Description, Description);
        VendorTempl.Insert(true);
    end;

    local procedure InsertPostingInfo(var VendorTempl: Record "Vendor Templ."; GenBusPostingGr: Code[20]; VATBusPostingGr: Code[20]; VendorPostingGr: Code[20])
    begin
        VendorTempl.Validate("Gen. Bus. Posting Group", GenBusPostingGr);
        VendorTempl.Validate("VAT Bus. Posting Group", VATBusPostingGr);
        VendorTempl.Validate("Vendor Posting Group", VendorPostingGr);
        VendorTempl.Modify(true);
    end;

    local procedure InsertPaymentInfo(var VendorTempl: Record "Vendor Templ."; PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    begin
        VendorTempl.Validate("Payment Terms Code", PaymentTermsCode);
        VendorTempl.Validate("Payment Method Code", PaymentMethodCode);
        VendorTempl.Modify(true);
    end;

    local procedure InsertOtherInfo(var VendorTempl: Record "Vendor Templ."; ContactType: Enum "Contact Type"; CountryRegionCode: Code[10]; PricesIncludingVAT: Boolean; ValidateEUVatRegNo: Boolean)
    begin
        VendorTempl.Validate("Contact Type", ContactType);
        VendorTempl.Validate("Country/Region Code", CountryRegionCode);
        VendorTempl.Validate("Prices Including VAT", PricesIncludingVAT);
        VendorTempl.Validate("Validate EU Vat Reg. No.", ValidateEUVatRegNo);
        VendorTempl.Modify(true);
    end;
}