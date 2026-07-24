// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Company;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 13411 "FICore InitReport Subscribers"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Company Information" = r;

    [EventSubscriber(ObjectType::Report, Report::"Standard Purchase - Order", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardPurchaseOrder(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Credit Memo", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesCreditMemo(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Draft Invoice", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesDraftInvoice(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesInvoice(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Order Conf.", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesOrderConf(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Pro Forma Inv", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesProFormaInv(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Quote", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesQuote(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Return Rcpt.", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesReturnRcpt(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Shipment", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesShipment(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Statement", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardStatement(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        BusinessIdentityCodeTxt: Text;
        BusinessIdentityCodeLbl: Text;
        ServiceSuppliesCode4CaptionTxt: Text;
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, LegalOfficeTxt, LegalOfficeLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT- VIES Declaration Tax Auth", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInVATVIESDeclaration(var IsHandled: Boolean; var BusinessIdentityCodeTxt: Text; var BusinessIdentityCodeLbl: Text; var RegisteredHomeCityTxt: Text; var RegisteredHomeCityLbl: Text; var ServiceSuppliesCode4CaptionTxt: Text)
    begin
        if IsHandled then
            exit;

        if not AssignCompanyInformationTexts(BusinessIdentityCodeTxt, BusinessIdentityCodeLbl, RegisteredHomeCityTxt, RegisteredHomeCityLbl, ServiceSuppliesCode4CaptionTxt) then
            exit;

        IsHandled := true;
    end;

    local procedure IsFeatureEnabled(): Boolean
    var
        VIESDeclarationFeature: Codeunit "FICore VIES Decl. Feature";
    begin
        exit(VIESDeclarationFeature.IsEnabled());
    end;

    local procedure AssignCompanyInformationTexts(var BusinessIdentityCodeTxt: Text; var BusinessIdentityCodeLbl: Text; var RegisteredHomeCityTxt: Text; var RegisteredHomeCityLbl: Text; var ServiceSuppliesCode4CaptionTxt: Text): Boolean
    var
        CompanyInformation: Record "Company Information";
        ServiceSuppliesCode4CaptionLbl: Label 'Total Value of Service Supplies(Code 4)';
    begin
        if not IsFeatureEnabled() then
            exit(false);

        CompanyInformation.Get();

        BusinessIdentityCodeTxt := CompanyInformation."Business Identity Code";
        BusinessIdentityCodeLbl := CompanyInformation.FieldCaption(CompanyInformation."Business Identity Code");
        RegisteredHomeCityTxt := CompanyInformation."Registered Home City";
        RegisteredHomeCityLbl := CompanyInformation.FieldCaption(CompanyInformation."Registered Home City");
        ServiceSuppliesCode4CaptionTxt := ServiceSuppliesCode4CaptionLbl;

        exit(true);
    end;
}
