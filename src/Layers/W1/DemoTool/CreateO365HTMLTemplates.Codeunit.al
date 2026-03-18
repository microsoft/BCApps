codeunit 119204 "Create O365 HTML Templates"
{

    trigger OnRun()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        CreateHTMLTemplates();
        O365BrandColor.CreateDefaultBrandColors();
        SetDefaultColor();
        CreatePaymentServiceLogos();
    end;

    var
        SalesMailTok: Label 'SALESEMAIL', Locked = true;
        SalesMailDescTxt: Label 'Invoicing sales mail';
        BlueCodeTok: Label 'BLUE', Comment = 'Blue';

    local procedure CreateHTMLTemplates()
    begin
        CreateO365HTMLTemplate(
          SalesMailTok, SalesMailDescTxt,
          'HTMLTemplates\', 'Invoicing - SalesMail.html');
    end;

    local procedure CreateO365HTMLTemplate("Code": Code[10]; Description: Text[50]; FilePath: Text; FileName: Text)
    var
        O365HTMLTemplate: Record "O365 HTML Template";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if not Exists(FilePath + FileName) then
            exit;
        O365HTMLTemplate.Code := Code;
        O365HTMLTemplate.Description := Description;
        O365HTMLTemplate.Validate("Media Resources Ref", MediaResourcesMgt.InsertBLOBFromFile(FilePath, FileName));
        O365HTMLTemplate.Insert();
    end;

    local procedure CreatePaymentServiceLogos()
    var
        DummyPaymentReportingArgument: Record "Payment Reporting Argument";
    begin
        CreatePaymentServiceLogo(DummyPaymentReportingArgument.GetPayPalServiceID(), DummyPaymentReportingArgument.GetPayPalLogoFile());
        CreatePaymentServiceLogo(DummyPaymentReportingArgument.GetMSWalletServiceID(), DummyPaymentReportingArgument.GetMSWalletLogoFile());
        CreatePaymentServiceLogo(DummyPaymentReportingArgument.GetWorldPayServiceID(), DummyPaymentReportingArgument.GetWorldPayLogoFile());
    end;

    local procedure CreatePaymentServiceLogo(PaymentServiceID: Integer; FileName: Text)
    var
        O365PaymentServiceLogo: Record "O365 Payment Service Logo";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if not Exists(FileName) then
            exit;
        O365PaymentServiceLogo.Init();
        O365PaymentServiceLogo."Payment Service ID" := PaymentServiceID;
        O365PaymentServiceLogo.Validate("Media Resources Ref", MediaResourcesMgt.InsertBLOBFromFile('', FileName));
        O365PaymentServiceLogo.Insert();
    end;

    local procedure SetDefaultColor()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Code", BlueCodeTok);
        CompanyInformation.Modify();
    end;
}

