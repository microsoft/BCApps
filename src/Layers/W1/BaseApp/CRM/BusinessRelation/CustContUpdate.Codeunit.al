// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;

codeunit 5056 "CustCont-Update"
{
    Permissions = tabledata Contact = rimd;

    trigger OnRun()
    begin
    end;

    var
        MarketingSetup: Record "Marketing Setup";
        CustContactUpdateCategoryTxt: Label 'Customer Contact Orphaned Links', Locked = true;
        CustContactUpdateTelemetryMsg: Label 'Contact does not exist. The contact business relation which points to it has been deleted', Locked = true;

    procedure OnInsert(var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Cust, IsHandled);
        if IsHandled then
            exit;

        MarketingSetup.Get();
        if MarketingSetup."Bus. Rel. Code for Customers" = '' then
            exit;

        InsertNewContact(Cust, true);
    end;

    procedure OnModify(var Cust: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        OldContact: Record Contact;
        ContactNo: Code[20];
        NoSeries: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Cust, ContactBusinessRelation, IsHandled);
        if not IsHandled then begin
            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
            ContactBusinessRelation.SetRange("No.", Cust."No.");
            if not ContactBusinessRelation.FindFirst() then
                exit;
            if not Contact.Get(ContactBusinessRelation."Contact No.") then begin
                ContactBusinessRelation.Delete();
                Session.LogMessage('0000B37', CustContactUpdateTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CustContactUpdateCategoryTxt);
                exit;
            end;
            OldContact := Contact;

            ContactNo := Contact."No.";
            NoSeries := Contact."No. Series";
            Contact.Validate("E-Mail", Cust."E-Mail");

            OnModifyOnBeforeTransferFieldsFromCustToContact(Contact, Cust);
            Contact.TransferFields(Cust);
            Contact."No." := ContactNo;
            Contact."No. Series" := NoSeries;
            OnAfterTransferFieldsFromCustToCont(Contact, Cust);

            Contact.Type := OldContact.Type;
            Contact.Validate(Name);
            Contact.DoModify(OldContact);
            Contact.Modify(true);

            if (Cust."Contact Type" = Cust."Contact Type"::Person) and
               (Cust."Primary Contact No." = Contact."No.")
            then begin
                Cust.Validate(Contact, Contact.Name);
                Cust.Modify();
            end;
            Cust.Get(Cust."No.");
        end;

        OnAfterOnModify(Contact, OldContact, Cust);
    end;

    procedure OnDelete(var Cust: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Cust, ContactBusinessRelation, IsHandled);
        if IsHandled then
            exit;

        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Cust."No.");
        ContactBusinessRelation.DeleteAll(true);
    end;

    procedure InsertNewContact(var Cust: Record Customer; LocalCall: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(Cust, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            MarketingSetup.Get();
            MarketingSetup.TestField("Bus. Rel. Code for Customers");
        end;

        if ContactBusinessRelation.UpdateEmptyNoForContact(Cust."No.", Cust."Primary Contact No.", ContactBusinessRelation."Link to Table"::Customer) then
            exit;

        Contact.Init();
        Contact.TransferFields(Cust);
        OnAfterTransferFieldsFromCustToCont(Contact, Cust);
        Contact.Validate(Contact.Name);
        Contact.Validate(Contact."E-Mail");
        IsHandled := false;
        OnInsertNewContactOnBeforeAssignNo(Contact, IsHandled, Cust);
        if not IsHandled then begin
            Contact."No." := '';
            Contact."No. Series" := '';
            MarketingSetup.TestField("Contact Nos.");
            Contact."No. Series" := MarketingSetup."Contact Nos.";
            Contact."No." := NoSeries.GetNextNo(Contact."No. Series");
        end;
        Contact.Type := Cust."Contact Type";
        Contact.SetSkipDefault();
        OnBeforeContactInsert(Contact, Cust);
        Contact.Insert(true);

        OnInsertNewContactOnAfterContInsert(Contact, Cust);

        ContactBusinessRelation.Init();
        ContactBusinessRelation."Contact No." := Contact."No.";
        ContactBusinessRelation."Business Relation Code" := MarketingSetup."Bus. Rel. Code for Customers";
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := Cust."No.";
        OnInsertNewContactOnBeforeContBusRelInsert(ContactBusinessRelation, Contact, Cust);
        ContactBusinessRelation.Insert(true);

        if Cust."Contact Type" = Cust."Contact Type"::Person then
            Cust.Validate("Primary Contact No.", Contact."No.");
    end;

    procedure InsertNewContactPerson(var Cust: Record Customer; LocalCall: Boolean)
    var
        CompanyContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        PersonContact: Record Contact;
    begin
        if not LocalCall then begin
            MarketingSetup.Get();
            MarketingSetup.TestField("Bus. Rel. Code for Customers");
        end;

        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Cust."No.");
        if ContactBusinessRelation.FindFirst() then
            if CompanyContact.Get(ContactBusinessRelation."Contact No.") then begin
                OnInsertNewContactPersonOnBeforeValidateType(PersonContact, Cust, CompanyContact);
                PersonContact.Validate(PersonContact.Type, PersonContact.Type::Person);
                PersonContact.Insert(true);
                PersonContact."Company No." := CompanyContact."No.";
                PersonContact.Validate(PersonContact.Name, Cust.Contact);
                PersonContact.InheritCompanyToPersonData(CompanyContact);
                PersonContact.UpdateBusinessRelation();
                OnInsertNewContactPersonOnBeforeContactModify(PersonContact, Cust);
                PersonContact.Modify(true);
                OnInsertNewContactPersonOnAfterContactModify(PersonContact, Cust);
                Cust."Primary Contact No." := PersonContact."No.";
            end
    end;

    procedure DeleteCustomerContacts(var Customer: Record Customer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        if ContactBusinessRelation.FindSet() then
            repeat
                if Contact.Get(ContactBusinessRelation."Contact No.") then
                    Contact.Delete(true);
            until ContactBusinessRelation.Next() = 0;
    end;

    procedure ContactNameIsBlank(CustomerNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        if not ContactBusinessRelation.FindFirst() then
            exit(false);
        if not Contact.Get(ContactBusinessRelation."Contact No.") then
            exit(true);
        exit(Contact.Name = '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; var OldContact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromCustToCont(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var Customer: Record Customer; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(Customer: Record Customer; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(Customer: Record Customer; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnAfterContInsert(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnAfterContactModify(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeValidateType(var Contact: Record Contact; Customer: Record Customer; ContComp: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactModify(var Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeContBusRelInsert(var ContactBusinessRelation: Record "Contact Business Relation"; Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean; Customer: Record Customer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeTransferFieldsFromCustToContact(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;
}
