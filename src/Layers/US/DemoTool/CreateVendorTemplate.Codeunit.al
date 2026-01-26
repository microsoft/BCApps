codeunit 101999 "Create Vendor Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Vendor: Record Vendor;
        CreateTemplateHelper: Codeunit "Create Template Helper";
        xCashDescriptionTxt: Label 'Cash-Payment Vendor (Cash)', Comment = 'Translate.';
        xBusinessDescriptionTxt: Label 'Business-to-Business Vendor (Bank)', Comment = 'Translate.';
        xManualTxt: Label 'Manual';
        xCODTxt: Label 'COD';
        X1M8DTxt: Label '1M(8D)';
        xBANKTxt: Label 'BANK', Comment = 'To be translated.';
        xCASHCAPTxt: Label 'CASH', Comment = 'Translated.';

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        DemoDataSetup.Get();
        // Cash-Payment vendor template
        InsertTemplate(ConfigTemplateHeader, xCashDescriptionTxt, '', DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, xCODTxt, xCASHCAPTxt);
        // Business-to-Business vendor template
        InsertTemplate(ConfigTemplateHeader, xBusinessDescriptionTxt, '', DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X1M8DTxt, xBANKTxt);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Vendor, ConfigTemplateHeader.Code, '', 0, 0);
    end;

    local procedure InsertTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50]; CountryCode: Text[50]; GenBusGroup: Code[20]; VendorGroup: Code[20]; TaxLiable: Boolean)
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Vendor), Description, DATABASE::Vendor);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Country/Region Code"), CountryCode);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Gen. Bus. Posting Group"), GenBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Vendor Posting Group"), VendorGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Tax Liable"), Format(TaxLiable));
    end;

    local procedure InsertPaymentsInfo(var ConfigTemplateHeader: Record "Config. Template Header"; ApplMethod: Text[20]; PaymentTerms: Code[20]; PaymentMethod: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Application Method"), ApplMethod);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Terms Code"), PaymentTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Method Code"), PaymentMethod);
    end;
}

