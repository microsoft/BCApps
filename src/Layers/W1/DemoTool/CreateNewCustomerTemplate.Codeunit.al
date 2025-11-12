codeunit 122007 "Create New Customer Template"
{
    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        CustomerTempl: Record "Customer Templ.";
        Contact: Record Contact;
        CreatePaymentTerms: Codeunit "Create Payment Terms";
        CreatePaymentMethod: Codeunit "Create Payment Method";
    begin
        DemoDataSetup.Get();

        InsertTemplate(CustomerTempl, CustomerPersonCodeTxt, CustomerPersonDescTxt);
        InsertPostingInfo(CustomerTempl, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPaymentInfo(CustomerTempl, CreatePaymentTerms.CashOnDeliveryCode(), CreatePaymentMethod.GetCashCode());
        InsertOtherInfo(CustomerTempl, Contact.Type::Person, DemoDataSetup."Country/Region Code", true, false);

        InsertTemplate(CustomerTempl, CustomerCompanyCodeTxt, CustomerCompanyDescTxt);
        InsertPostingInfo(CustomerTempl, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPaymentInfo(CustomerTempl, CreatePaymentTerms.OneMonthEightDaysCode(), CreatePaymentMethod.GetBankCode());
        InsertOtherInfo(CustomerTempl, Contact.Type::Company, DemoDataSetup."Country/Region Code", false, false);

        InsertTemplate(CustomerTempl, CustomerEUCompanyCodeTxt, CustomerEUCompanyDescTxt);
        InsertPostingInfo(CustomerTempl, DemoDataSetup.EUCode(), DemoDataSetup.EUCode(), DemoDataSetup.EUCode());
        InsertPaymentInfo(CustomerTempl, CreatePaymentTerms.FourteenDaysCode(), CreatePaymentMethod.GetBankCode());
        InsertOtherInfo(CustomerTempl, Contact.Type::Company, '', false, true);
    end;

    var
        CustomerCompanyCodeTxt: Label 'Customer COMPANY', MaxLength = 20;
        CustomerCompanyDescTxt: Label 'Business-to-Business Customer (Bank)', MaxLength = 100;
        CustomerPersonCodeTxt: Label 'Customer PERSON', MaxLength = 20;
        CustomerPersonDescTxt: Label 'Cash-Payment Customer (Cash)', MaxLength = 100;
        CustomerEUCompanyCodeTxt: Label 'Customer EU COMPANY', MaxLength = 20;
        CustomerEUCompanyDescTxt: Label 'EU Customer (Bank)', MaxLength = 100;

    local procedure InsertTemplate(var CustomerTempl: Record "Customer Templ."; Code: Code[20]; Description: Text[100])
    begin
        CustomerTempl.Init();
        CustomerTempl.Validate(Code, Code);
        CustomerTempl.Validate(Description, Description);
        CustomerTempl.Insert(true);
    end;

    local procedure InsertPostingInfo(var CustomerTempl: Record "Customer Templ."; GenBusPostingGr: Code[20]; VATBusPostingGr: Code[20]; CustomerPostingGr: Code[20])
    begin
        CustomerTempl.Validate("Gen. Bus. Posting Group", GenBusPostingGr);
        CustomerTempl.Validate("VAT Bus. Posting Group", VATBusPostingGr);
        CustomerTempl.Validate("Customer Posting Group", CustomerPostingGr);
        CustomerTempl.Modify(true);
    end;

    local procedure InsertPaymentInfo(var CustomerTempl: Record "Customer Templ."; PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10])
    begin
        CustomerTempl.Validate("Payment Terms Code", PaymentTermsCode);
        CustomerTempl.Validate("Payment Method Code", PaymentMethodCode);
        CustomerTempl.Modify(true);
    end;

    local procedure InsertOtherInfo(var CustomerTempl: Record "Customer Templ."; ContactType: Enum "Contact Type"; CountryRegionCode: Code[10]; PricesIncludingVAT: Boolean; ValidateEUVatRegNo: Boolean)
    begin
        CustomerTempl.Validate("Contact Type", ContactType);
        CustomerTempl.Validate("Country/Region Code", CountryRegionCode);
        CustomerTempl.Validate("Prices Including VAT", PricesIncludingVAT);
        CustomerTempl.Validate("Validate EU Vat Reg. No.", ValidateEUVatRegNo);
        CustomerTempl.Modify(true);
    end;
}