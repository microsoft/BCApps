// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

codeunit 5057 "VendCont-Update"
{
    Permissions = tabledata Contact = rimd;

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        VendContactUpdateCategoryTxt: Label 'Vendor Contact Orphaned Links', Locked = true;
        VendContactUpdateTelemetryMsg: Label 'Contact does not exist. The contact business relation which points to it has been deleted', Locked = true;

    procedure OnInsert(var Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Vend, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();
        if RMSetup."Bus. Rel. Code for Vendors" = '' then
            exit;

        InsertNewContact(Vend, true);
    end;

    procedure OnModify(var Vend: Record Vendor)
    var
        Cont: Record Contact;
        OldCont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContNo: Code[20];
        NoSeries: Code[20];
        SalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Vend, ContBusRel, IsHandled);
        if not IsHandled then begin
            ContBusRel.SetCurrentKey("Link to Table", "No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            ContBusRel.SetRange("No.", Vend."No.");
            if not ContBusRel.FindFirst() then
                exit;
            if not Cont.Get(ContBusRel."Contact No.") then begin
                ContBusRel.Delete();
                Session.LogMessage('0000B36', VendContactUpdateTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VendContactUpdateCategoryTxt);
                exit;
            end;
            OldCont := Cont;

            ContNo := Cont."No.";
            NoSeries := Cont."No. Series";
            SalespersonCode := Cont."Salesperson Code";

            OnBeforeTransferFieldsFromVendToCont(Cont, Vend, SalespersonCode);
            Cont.Validate("E-Mail", Vend."E-Mail");

            Cont.TransferFields(Vend);
            OnAfterTransferFieldsFromVendToCont(Cont, Vend);

            IsHandled := false;
            OnModifyOnBeforeAssignNo(Cont, IsHandled);
            if not IsHandled then begin
                Cont."No." := ContNo;
                Cont."No. Series" := NoSeries;
            end;
            Cont."Salesperson Code" := SalespersonCode;
            Cont.Validate(Name);
            Cont.DoModify(OldCont);
            Cont.Modify(true);

            Vend.Get(Vend."No.");
        end;
        OnAfterOnModify(Cont, OldCont, Vend);
    end;

    procedure OnDelete(var Vend: Record Vendor)
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Vend, ContBusRel, IsHandled);
        if IsHandled then
            exit;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        ContBusRel.SetRange("No.", Vend."No.");
        ContBusRel.DeleteAll(true);
    end;

    procedure InsertNewContact(var Vend: Record Vendor; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(Vend, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");
        end;

        if ContBusRel.UpdateEmptyNoForContact(Vend."No.", Vend."Primary Contact No.", ContBusRel."Link to Table"::Vendor) then
            exit;

        Cont.Init();
        Cont.TransferFields(Vend);
        OnAfterTransferFieldsFromVendToCont(Cont, Vend);
        Cont.Validate(Cont.Name);
        Cont.Validate(Cont."E-Mail");
        IsHandled := false;
        OnInsertNewContactOnBeforeAssignNo(Cont, IsHandled, Vend, RMSetup, LocalCall);
        if not IsHandled then begin
            Cont."No." := '';
            Cont."No. Series" := '';
            RMSetup.TestField("Contact Nos.");
                Cont."No. Series" := RMSetup."Contact Nos.";
                Cont."No." := NoSeries.GetNextNo(Cont."No. Series");
        end;
        Cont.Type := Cont.Type::Company;
        Cont.TypeChange();
        Cont.SetSkipDefault();
        OnBeforeContactInsert(Cont, Vend);
        Cont.Insert(true);
        OnInsertNewContactOnAfterContactInsert(Cont, Vend);

        ContBusRel.Init();
        ContBusRel."Contact No." := Cont."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
        ContBusRel."No." := Vend."No.";
        OnInsertNewContactOnBeforeContBusRelInsert(ContBusRel, Cont, Vend);
        ContBusRel.Insert(true);
    end;

    procedure InsertNewContactPerson(var Vend: Record Vendor; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContComp: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");
        end;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        ContBusRel.SetRange("No.", Vend."No.");
        if ContBusRel.FindFirst() then
            if ContComp.Get(ContBusRel."Contact No.") then begin
                Cont.Init();
                Cont."No." := '';
                OnInsertNewContactPersonOnBeforeContactInsert(Cont, Vend);
                Cont.Insert(true);
                Cont."Company No." := ContComp."No.";
                Cont.Type := Cont.Type::Person;
                Cont.Validate(Cont.Name, Vend.Contact);
                Cont.InheritCompanyToPersonData(ContComp);
                Cont.UpdateBusinessRelation();
                OnInsertNewContactPersonOnBeforeContactModify(Cont, Vend);
                Cont.Modify(true);
                Vend."Primary Contact No." := Cont."No.";
            end
    end;

    procedure ContactNameIsBlank(VendorNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", VendorNo);
        if not ContactBusinessRelation.FindFirst() then
            exit(false);
        if not Contact.Get(ContactBusinessRelation."Contact No.") then
            exit(true);
        exit(Contact.Name = '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromVendToCont(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; var OldContact: Record Contact; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFieldsFromVendToCont(var Contact: Record Contact; Vendor: Record Vendor; var SalespersonCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var Vendor: Record Vendor; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(Vendor: Record Vendor; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(Vend: Record Vendor; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactInsert(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactPersonOnBeforeContactModify(var Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean; Vendor: Record Vendor; MarketingSetup: Record "Marketing Setup"; LocalCall: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertNewContactOnBeforeContBusRelInsert(var ContactBusinessRelation: Record "Contact Business Relation"; Contact: Record Contact; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeAssignNo(var Contact: Record Contact; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertNewContactOnAfterContactInsert(var Contact: Record "Contact"; var Vendor: Record "Vendor")
    begin
    end;
}
