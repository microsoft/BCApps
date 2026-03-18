// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.Foundation.NoSeries;

codeunit 5058 "BankCont-Update"
{
    Permissions = tabledata Contact = rimd;

    trigger OnRun()
    begin
    end;

    var
        RMSetup: Record "Marketing Setup";
        BankContactUpdateCategoryTxt: Label 'Bank Contact Orphaned Links', Locked = true;
        BankContactUpdateTelemetryMsg: Label 'Contact does not exist. The contact business relation which points to it has been deleted', Locked = true;

    procedure OnInsert(var BankAcc: Record "Bank Account")
    begin
        RMSetup.Get();
        if RMSetup."Bus. Rel. Code for Bank Accs." = '' then
            exit;

        InsertNewContact(BankAcc, true);
    end;

    procedure OnModify(var BankAcc: Record "Bank Account")
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
        OnBeforeOnModify(BankAcc, IsHandled);
        if IsHandled then
            exit;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        ContBusRel.SetRange("No.", BankAcc."No.");
        if not ContBusRel.FindFirst() then
            exit;
        if not Cont.Get(ContBusRel."Contact No.") then begin
            ContBusRel.Delete();
            Session.LogMessage('0000B38', BankContactUpdateTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankContactUpdateCategoryTxt);
            exit;
        end;
        OldCont := Cont;

        ContNo := Cont."No.";
        NoSeries := Cont."No. Series";
        SalespersonCode := Cont."Salesperson Code";
        Cont.Validate("E-Mail", BankAcc."E-Mail");
        Cont.TransferFields(BankAcc);
        OnAfterTransferFieldsFromBankAccToCont(Cont, BankAcc);
        Cont."No." := ContNo;
        Cont."No. Series" := NoSeries;
        Cont."Salesperson Code" := SalespersonCode;
        Cont.Validate(Name);
        Cont.DoModify(OldCont);
        IsHandled := false;
        OnOnModifyOnBeforeContModify(Cont, BankAcc, IsHandled);
        if not IsHandled then
            Cont.Modify(true);

        BankAcc.Get(BankAcc."No.");
    end;

    procedure OnDelete(var BankAcc: Record "Bank Account")
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        ContBusRel.SetRange("No.", BankAcc."No.");
        ContBusRel.DeleteAll(true);
    end;

    procedure InsertNewContact(var BankAcc: Record "Bank Account"; LocalCall: Boolean)
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertNewContact(BankAcc, LocalCall, IsHandled);
        if IsHandled then
            exit;

        if not LocalCall then begin
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
        end;

        InitContactFromBankAccount(Cont, BankAcc);
        OnBeforeContactInsert(Cont, BankAcc);
        Cont.Insert(true);

        ContBusRel.Init();
        ContBusRel."Contact No." := Cont."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::"Bank Account";
        ContBusRel."No." := BankAcc."No.";
        ContBusRel.Insert(true);
    end;

    local procedure InitContactFromBankAccount(var Contact: Record Contact; BankAcc: Record "Bank Account")
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitContactFromBankAccount(Contact, BankAcc, RMSetup, IsHandled);
        if IsHandled then
            exit;

        Contact.Init();
        Contact.TransferFields(BankAcc);
        Contact.Validate(Contact.Name);
        Contact.Validate(Contact."E-Mail");
        IsHandled := false;
        OnInitContactFromBankAccountOnBeforeAssignNo(Contact, BankAcc, RMSetup, IsHandled);
        if not IsHandled then begin
            Contact."No." := '';
            Contact."No. Series" := '';
            RMSetup.TestField("Contact Nos.");
                Contact."No. Series" := RMSetup."Contact Nos.";
                Contact."No." := NoSeries.GetNextNo(Contact."No. Series");
        end;
        Contact.Type := Contact.Type::Company;
        Contact.TypeChange();
        Contact.SetSkipDefault();
    end;

    procedure ContactNameIsBlank(BankAccountNo: Code[20]): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", ContactBusinessRelation."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        ContactBusinessRelation.SetRange("No.", BankAccountNo);
        if not ContactBusinessRelation.FindFirst() then
            exit(false);
        if not Contact.Get(ContactBusinessRelation."Contact No.") then
            exit(true);
        exit(Contact.Name = '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromBankAccToCont(var Contact: Record Contact; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitContactFromBankAccount(var Contact: Record Contact; BankAcc: Record "Bank Account"; RMSetup: Record "Marketing Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewContact(var BankAccount: Record "Bank Account"; LocalCall: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactInsert(var Contact: Record Contact; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitContactFromBankAccountOnBeforeAssignNo(var Contact: Record Contact; BankAccount: Record "Bank Account"; MarketingSetup: Record "Marketing Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnModifyOnBeforeContModify(var Contact: Record Contact; BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;
}
