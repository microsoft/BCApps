codeunit 11297 "SECore InitReport Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Report, Report::"Standard Purchase - Order", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardPurchaseOrder(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Credit Memo", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesCreditMemo(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Draft Invoice", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesDraftInvoice(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Invoice", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesInvoice(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Order Conf.", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesOrderConf(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Pro Forma Inv", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesProFormaInv(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Quote", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesQuote(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Return Rcpt.", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesReturnRcpt(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Sales - Shipment", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardSalesShipment(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl, LegalStatementLbl);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Standard Statement", 'OnInitReportForGlobalVariable', '', false, false)]
    local procedure OnInitReportForGlobalVariableInStandardStatement(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    begin
        if IsHandled then
            exit;

        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl);

        IsHandled := true;
    end;

    local procedure AssignGlobalLabels(var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text; var LegalStatementLbl: Text)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl);

        LegalStatementLbl := SalesReceivablesSetup.GetLegalStatementLabel();
    end;

    local procedure AssignGlobalLabels(var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        AssignGlobalLabels(LegalOfficeTxt, LegalOfficeLbl);

        CompanyInformation.Get();

        CustomGiroTxt := CompanyInformation."Plus Giro No.";
        CustomGiroLbl := CompanyInformation.FieldCaption(CompanyInformation."Plus Giro No.");
    end;

    local procedure AssignGlobalLabels(var LegalOfficeTxt: Text; var LegalOfficeLbl: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        LegalOfficeTxt := CompanyInformation."Registered Office";
        LegalOfficeLbl := CompanyInformation.GetLegalOfficeLabel();
    end;
}