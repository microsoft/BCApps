// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Finance.VAT.Registration;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 5055 "CustVendBank-Update"
{
    Permissions = TableData "Bank Account" = rm,
                  TableData Customer = rm,
                  TableData Employee = rm,
                  TableData Vendor = rm,
                  tabledata "Contact Business Relation" = r;
    TableNo = Contact;

    trigger OnRun()
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        ContBusRel.SetRange("Contact No.", Rec."No.");
        ContBusRel.SetFilter("Link to Table", '<>''''');

        if ContBusRel.Find('-') then
            repeat
                case ContBusRel."Link to Table" of
                    ContBusRel."Link to Table"::Customer:
                        UpdateCustomer(Rec, ContBusRel);
                    ContBusRel."Link to Table"::Vendor:
                        UpdateVendor(Rec, ContBusRel);
                    ContBusRel."Link to Table"::"Bank Account":
                        UpdateBankAccount(Rec, ContBusRel);
                    ContBusRel."Link to Table"::Employee:
                        UpdateEmployee(Rec, ContBusRel);
                    else
                        OnRunCustVendBankUpdateCaseElse(Rec, ContBusRel);
                end;
            until ContBusRel.Next() = 0;
    end;

    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        NoSeries: Code[20];
        PurchaserCode: Code[20];
        OurContactCode: Code[20];

    procedure UpdateCustomer(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    var
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        VATRegNo: Text[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustomer(Cust, Cont, ContBusRel, IsHandled);
        if not IsHandled then begin
            Cust.Get(ContBusRel."No.");
            OnUpdateCustomerOnAfterGetCust(Cust, Cont, ContBusRel);
            NoSeries := Cust."No. Series";
            VATRegNo := Cust."VAT Registration No.";
            CustCopyFieldsFromCont(Cont);
            Cust."No." := ContBusRel."No.";
            Cust."No. Series" := NoSeries;
            Cust."Last Modified Date Time" := CurrentDateTime;
            Cust."Last Date Modified" := Today;
            OnAfterUpdateCustomer(Cust, Cont, ContBusRel);
            Cust.Modify();
            if (Cust."VAT Registration No." <> '') and (Cust."VAT Registration No." <> VATRegNo) then
                VATRegistrationLogMgt.LogCustomer(Cust);
        end;

        OnAfterUpdateCustomerProcedure(Cust, Cont, ContBusRel);
    end;

    local procedure CustCopyFieldsFromCont(var Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustCopyFieldsFromCont(Cust, Cont, IsHandled);
        if IsHandled then
            exit;

        Cust.TransferFields(Cont);
    end;

    procedure UpdateVendor(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    var
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        VATRegNo: Text[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVendor(Vend, Cont, ContBusRel, IsHandled);
        if not IsHandled then begin
            Vend.Get(ContBusRel."No.");
            OnUpdateVendorOnAfterGetVend(Vend, Cont, ContBusRel);
            NoSeries := Vend."No. Series";
            PurchaserCode := Vend."Purchaser Code";
            VATRegNo := Vend."VAT Registration No.";
            VendCopyFieldsFromCont(Cont);
            Vend."No." := ContBusRel."No.";
            Vend."No. Series" := NoSeries;
            Vend."Purchaser Code" := PurchaserCode;
            Vend."Last Modified Date Time" := CurrentDateTime;
            Vend."Last Date Modified" := Today;
            OnAfterUpdateVendor(Vend, Cont, ContBusRel);
            Vend.Modify();
            if (Vend."VAT Registration No." <> '') and (Vend."VAT Registration No." <> VATRegNo) then
                VATRegistrationLogMgt.LogVendor(Vend);
        end;

        OnAfterUpdateVendorProcedure(Vend, Cont, ContBusRel);
    end;

    local procedure VendCopyFieldsFromCont(var Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendCopyFieldsFromCont(Vend, Cont, IsHandled);
        if IsHandled then
            exit;

        Vend.TransferFields(Cont);
    end;

    procedure UpdateBankAccount(var Cont: Record Contact; var ContBusRel: Record "Contact Business Relation")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBankAccount(BankAcc, Cont, ContBusRel, IsHandled);
        if not IsHandled then begin
            BankAcc.Get(ContBusRel."No.");
            NoSeries := BankAcc."No. Series";
            OurContactCode := BankAcc."Our Contact Code";
            BankAcc.Validate(BankAcc."Currency Code", Cont."Currency Code");
            BankAccountCopyFieldsFromCont(Cont);
            BankAcc."No." := ContBusRel."No.";
            BankAcc."No. Series" := NoSeries;
            BankAcc."Our Contact Code" := OurContactCode;
            BankAcc."Last Date Modified" := Today;
            OnAfterUpdateBankAccount(BankAcc, Cont, ContBusRel);
            BankAcc.Modify();
        end;

        OnAfterUpdateBankAccountProcedure(BankAcc, Cont, ContBusRel);
    end;

    local procedure BankAccountCopyFieldsFromCont(var Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBankAccountCopyFieldsFromCont(BankAcc, Cont, IsHandled);
        if IsHandled then
            exit;

        BankAcc.TransferFields(Cont);
    end;

    [Scope('Onprem')]
    procedure UpdateEmployee(Contact: Record Contact; ContBusRel: Record "Contact Business Relation")
    var
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateEmployee(Employee, Contact, ContBusRel, IsHandled);
        if not IsHandled then begin
            Employee.Get(ContBusRel."No.");
            Employee.Address := Contact.Address;
            Employee."Address 2" := Contact."Address 2";
            Employee.City := Contact.City;
            Employee."Phone No." := Contact."Phone No.";
            Employee."Country/Region Code" := Contact."Country/Region Code";
            Employee.Comment := Contact.Comment;
            Employee."Fax No." := Contact."Fax No.";
            Employee."Post Code" := Contact."Post Code";
            Employee.County := Contact.County;
            Employee."E-Mail" := Contact."E-Mail";
            Employee.Image := Contact.Image;
            Employee."First Name" := Contact."First Name";
            Employee."Middle Name" := Contact."Middle Name";
            Employee."Last Name" := Contact.Surname;
            Employee."Job Title" := Contact."Job Title";
            Employee.Initials := Contact.Initials;
            Employee."Mobile Phone No." := Contact."Mobile Phone No.";
            Employee.Pager := Contact.Pager;
            Employee.Modify(true);
        end;

        OnAfterUpdateEmployee(Employee, Contact);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustomer(var Customer: Record Customer; Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustomerProcedure(var Customer: Record Customer; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendor(var Vendor: Record Vendor; Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendorProcedure(var Vendor: Record Vendor; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBankAccount(var BankAccount: Record "Bank Account"; Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBankAccountProcedure(var BankAccount: Record "Bank Account"; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccountCopyFieldsFromCont(var BankAccount: Record "Bank Account"; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustCopyFieldsFromCont(var Customer: Record Customer; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustomer(var Customer: Record Customer; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendor(var Vendor: Record Vendor; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBankAccount(var BankAccount: Record "Bank Account"; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendCopyFieldsFromCont(var Vendor: Record Vendor; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCustVendBankUpdateCaseElse(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateEmployee(var Employee: Record Employee; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerOnAfterGetCust(var Customer: Record Customer; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorOnAfterGetVend(var Vendor: Record Vendor; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Business Relation", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertContBusRelation(var Rec: Record "Contact Business Relation"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        Rec.UpdateContactBusinessRelation();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Business Relation", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteContBusRelation(var Rec: Record "Contact Business Relation"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        Rec.UpdateContactBusinessRelation();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Business Relation", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyContBusRelation(var Rec: Record "Contact Business Relation"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        Rec.UpdateContactBusinessRelation();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contact Business Relation", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameContBusRelation(var Rec: Record "Contact Business Relation"; var xRec: Record "Contact Business Relation"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        xRec.UpdateContactBusinessRelation();
        Rec.UpdateContactBusinessRelation();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEmployee(var Employee: Record Employee; var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;
}

