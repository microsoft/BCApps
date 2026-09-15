// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

codeunit 5942 "ServContractQuote-Tmpl. Upd."
{
    TableNo = "Service Contract Header";

    trigger OnRun()
    begin
        ServiceContractTemplate.Reset();
        OnRunOnAfterResetServiceContractTemplate(Rec, ServiceContractTemplate);

        if not ServiceContractTemplate.FindFirst() then
            exit;
        CheckContractNo(Rec);

        PickAndApplyTemplate(Rec);
    end;

    var
        ServiceContractTemplate: Record "Service Contract Template";

    local procedure CheckContractNo(var ServiceContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContractNo(ServiceContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceContractHeader.TestField("Contract No.");
    end;

    local procedure PickAndApplyTemplate(var ServiceContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickAndApplyTemplate(ServiceContractHeader, ServiceContractTemplate, IsHandled);
        if IsHandled then
            exit;

        if Page.RunModal(Page::"Service Contract Template List", ServiceContractTemplate) = Action::LookupOK then
            ApplyTemplate(ServiceContractHeader, ServiceContractTemplate);
    end;

    procedure ApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
        TemplateContractServiceDiscount: Record "Contract/Service Discount";
    begin
        OnBeforeApplyTemplate(ServiceContractHeader, ServiceContractTemplate);
        ServiceContractHeader.Description := ServiceContractTemplate.Description;
        ServiceContractHeader.Validate("Contract Group Code", ServiceContractTemplate."Contract Group Code");
        ServiceContractHeader.Validate("Service Order Type", ServiceContractTemplate."Service Order Type");
        ServiceContractHeader.Validate("Service Period", ServiceContractTemplate."Default Service Period");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractTemplate."Price Update Period");
        ServiceContractHeader.Validate("Response Time (Hours)", ServiceContractTemplate."Default Response Time (Hours)");
        ServiceContractHeader.Validate("Max. Labor Unit Price", ServiceContractTemplate."Max. Labor Unit Price");
        ServiceContractHeader.Validate("Invoice after Service", ServiceContractTemplate."Invoice after Service");
        ServiceContractHeader.Validate("Invoice Period", ServiceContractTemplate."Invoice Period");
        ServiceContractHeader.Validate("Price Inv. Increase Code", ServiceContractTemplate."Price Inv. Increase Code");
        ServiceContractHeader.Validate("Allow Unbalanced Amounts", ServiceContractTemplate."Allow Unbalanced Amounts");
        ServiceContractHeader.Validate("Contract Lines on Invoice", ServiceContractTemplate."Contract Lines on Invoice");
        ServiceContractHeader.Validate("Combine Invoices", ServiceContractTemplate."Combine Invoices");
        ServiceContractHeader.Validate("Automatic Credit Memos", ServiceContractTemplate."Automatic Credit Memos");
        ServiceContractHeader.Validate(Prepaid, ServiceContractTemplate.Prepaid);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractTemplate."Serv. Contract Acc. Gr. Code");
        ServiceContractHeader."Template No." := ServiceContractTemplate."No.";

        OnApplyTemplateOnBeforeCreateDimFromDefaultDim(ServiceContractHeader, ServiceContractTemplate);
        ServiceContractHeader.CreateDimFromDefaultDim(0);

        ContractServiceDiscount.Reset();
        ContractServiceDiscount.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ContractServiceDiscount.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractServiceDiscount.DeleteAll();

        TemplateContractServiceDiscount.Reset();
        TemplateContractServiceDiscount.SetRange("Contract Type", TemplateContractServiceDiscount."Contract Type"::Template);
        TemplateContractServiceDiscount.SetRange("Contract No.", ServiceContractTemplate."No.");
        if TemplateContractServiceDiscount.Find('-') then
            repeat
                ContractServiceDiscount := TemplateContractServiceDiscount;
                ContractServiceDiscount."Contract Type" := ServiceContractHeader."Contract Type";
                ContractServiceDiscount."Contract No." := ServiceContractHeader."Contract No.";
                ContractServiceDiscount.Insert();
            until TemplateContractServiceDiscount.Next() = 0;
        OnAfterApplyTemplate(ServiceContractHeader, ServiceContractTemplate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContractNo(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickAndApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterResetServiceContractTemplate(ServiceContractHeader: Record "Service Contract Header"; var ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeCreateDimFromDefaultDim(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;
}

