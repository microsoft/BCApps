codeunit 101999 "Create Vendor Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Vendor: Record Vendor;
        CreateTemplateHelper: Codeunit "Create Template Helper";
        xBlankDescrTxt: Label 'Blank Vendor Card', Comment = 'Translate.';
        xCashDescriptionTxt: Label 'Cash-Payment Vendor (Cash, VAT)', Comment = 'Translate.';
        xPrivateDescriptionTxt: Label 'Private Vendor (Giro, No VAT)', Comment = 'Translate.';
        xBusinessDescriptionTxt: Label 'Business-to-Business Vendor (Bank, VAT)', Comment = 'Translate.';
        xManualTxt: Label 'Manual';
        xCODTxt: Label 'COD';
        X14DAYSTxt: Label '14 DAYS';
        X1M8DTxt: Label '1M(8D)';
        xGIROTxt: Label 'GIRO', Comment = 'To be translated.';
        xBANKTxt: Label 'BANK', Comment = 'To be translated.';
        xCASHCAPTxt: Label 'CASH', Comment = 'Translated.';

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        DemoDataSetup.Get();
        // Blank Template
        InsertTemplate(ConfigTemplateHeader, xBlankDescrTxt, '', '', '', '', false);
        // Cash-Payment vendor template
        InsertTemplate(ConfigTemplateHeader,
          xCashDescriptionTxt, DemoDataSetup."Country/Region Code", DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, xCODTxt, xCASHCAPTxt);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Vendor, ConfigTemplateHeader.Code, '', 0, 0);
        // Private vendor template
        InsertTemplate(ConfigTemplateHeader,
          xPrivateDescriptionTxt, DemoDataSetup."Country/Region Code", DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X14DAYSTxt, xGIROTxt);
        // Business-to-Business vendor template
        InsertTemplate(ConfigTemplateHeader,
          xBusinessDescriptionTxt, DemoDataSetup."Country/Region Code", DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), false);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X1M8DTxt, xBANKTxt);
        // EU vendor template
        // Skipped
    end;

    local procedure InsertTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50]; CountryCode: Text[50]; GenBusGroup: Code[20]; VATBusGroup: Code[20]; VendorGroup: Code[20]; PriceWithVAT: Boolean)
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Vendor), Description, DATABASE::Vendor);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Country/Region Code"), CountryCode);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Gen. Bus. Posting Group"), GenBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("VAT Bus. Posting Group"), VATBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Prices Including VAT"), Format(PriceWithVAT));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Vendor Posting Group"), VendorGroup);
    end;

    local procedure InsertPaymentsInfo(var ConfigTemplateHeader: Record "Config. Template Header"; ApplMethod: Text[20]; PaymentTerms: Code[20]; PaymentMethod: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Application Method"), ApplMethod);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Terms Code"), PaymentTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Method Code"), PaymentMethod);
    end;
}
