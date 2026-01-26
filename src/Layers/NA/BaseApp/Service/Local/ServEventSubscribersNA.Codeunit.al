// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.History;

codeunit 10059 "Serv. Event Subscribers NA"
{
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";

#if not CLEAN27
    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
        if ServiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Stats.";
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnOpenOrderStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceHeaderOnOpenOrderStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
        if ServiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Order Stats.";
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceCrMemoHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var StatPageID: Integer)
    begin
        if ServiceCrMemoHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Credit Memo Stats.";
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnOpenStatisticsOnAfterSetStatPageID', '', false, false)]
    local procedure ServiceInvoiceHeaderOnOpenStatisticsOnAfterSetStatPageID(var ServiceInvoiceHeader: Record "Service Invoice Header"; var StatPageID: Integer)
    begin
        if ServiceInvoiceHeader."Tax Area Code" <> '' then
            StatPageID := Page::"Service Invoice Stats.";
    end;
#endif
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'Bill-to Customer No.', false, false)]
    local procedure OnAfterValidateBillToCustomerNo(var Rec: Record "Service Header"; var xRec: Record "Service Header")
    begin
        if xRec."Bill-to Customer No." <> Rec."Bill-to Customer No." then
            CopyCFDIFieldsFromCustomer(Rec);
    end;

    local procedure CopyCFDIFieldsFromCustomer(var Rec: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(Rec."Bill-to Customer No.") then begin
            Rec."CFDI Purpose" := Customer."CFDI Purpose";
            Rec."CFDI Relation" := Customer."CFDI Relation";
            Rec."CFDI Export Code" := Customer."CFDI Export Code";
            Rec."CFDI Period" := Customer."CFDI Period";
        end else begin
            Rec."CFDI Purpose" := '';
            Rec."CFDI Relation" := '';
            Rec."CFDI Export Code" := '';
            Rec."CFDI Period" := Rec."CFDI Period"::Diario;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyCustomerFields', '', false, false)]
    local procedure OnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Tax Exemption No." := Customer."Tax Exemption No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnBeforePrintRecords', '', false, false)]
    local procedure ServiceCrMemoHeaderOnBeforePrintRecords(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        EInvoiceMgt.EDocPrintValidation(ServiceCrMemoHeader."Electronic Document Status", ServiceCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnBeforePrintRecords', '', false, false)]
    local procedure ServiceInvoiceHeaderOnBeforePrintRecords(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        EInvoiceMgt.EDocPrintValidation(ServiceInvoiceHeader."Electronic Document Status", ServiceInvoiceHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServContractManagement", 'OnBeforeCheckCustomer', '', false, false)]
    local procedure ServContractManagementOnBeforeCheckCustomer(var Result: Boolean; var IsHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Result := GeneralLedgerSetup."VAT in Use";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Account Group", 'OnBeforeCheckProdPostingGroups', '', false, false)]
    local procedure ServiceContractAccountGroupOnBeforeCheckProdPostingGroups(var Result: Boolean; var IsHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Result := GeneralLedgerSetup."VAT in Use";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeCheckBusPostingGroups', '', false, false)]
    local procedure ServiceHeaderOnBeforeCheckBusPostingGroups(var Result: Boolean; var IsHandled: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Result := GeneralLedgerSetup."VAT in Use";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Inv. - Update", 'OnAfterRecordChanged', '', false, false)]
    local procedure OnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
            (ServiceInvoiceHeader."CFDI Cancellation Reason Code" <> xServiceInvoiceHeader."CFDI Cancellation Reason Code") or
            (ServiceInvoiceHeader."Substitution Document No." <> xServiceInvoiceHeader."Substitution Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnDeleteOnBeforeShowPostedDocsToPrint', '', false, false)]
    local procedure OnDeleteOnBeforeShowPostedDocsToPrint(var ServiceHeader: Record "Service Header")
    var
        SalesTaxDifference: Record "Sales Tax Amount Difference";
    begin
        if ServiceHeader."Tax Area Code" <> '' then begin
            SalesTaxDifference.Reset();
            SalesTaxDifference.SetRange("Document Product Area", SalesTaxDifference."Document Product Area"::Sales);
            SalesTaxDifference.SetRange("Document Type", ServiceHeader."Document Type");
            SalesTaxDifference.SetRange("Document No.", ServiceHeader."No.");
            SalesTaxDifference.DeleteAll();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnValidateUnitOfMeasureOnAfterAssignUnitofMeasureValue', '', false, false)]
    local procedure OnValidateUnitOfMeasureOnAfterAssignUnitofMeasureValue(var ServiceLine: Record "Service Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."PAC Environment" <> GLSetup."PAC Environment"::Disabled then
            if ServiceLine.Type <> ServiceLine.Type::"G/L Account" then
                ServiceLine.TestField("Unit of Measure Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServOrderManagement", 'OnCreateCustFromTemplateOnBeforeCustInsert', '', false, false)]
    local procedure OnCreateCustFromTemplateOnBeforeCustInsert(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; ServiceHeader: Record "Service Header")
    begin
        if CustomerTempl.State <> '' then
            Customer.County := CustomerTempl.State
        else
            Customer.County := ServiceHeader.County;
    end;
}
