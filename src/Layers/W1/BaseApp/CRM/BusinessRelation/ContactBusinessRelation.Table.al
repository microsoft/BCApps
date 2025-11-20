// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 5054 "Contact Business Relation"
{
    Caption = 'Contact Business Relation';
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact Business Relations";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));

            trigger OnValidate()
            begin
                if "Contact No." <> '' then
                    Validate("Business Relation Code");
            end;
        }
        field(2; "Business Relation Code"; Code[10])
        {
            Caption = 'Business Relation Code';
            NotBlank = true;
            TableRelation = "Business Relation";

            trigger OnValidate()
            var
                RMSetup: Record "Marketing Setup";
                Cust: Record Customer;
                Vend: Record Vendor;
                BankAcc: Record "Bank Account";
            begin
                if ("No." = '') and
                   ("Contact No." <> '') and
                   ("Business Relation Code" <> '') and
                   (CurrFieldNo <> 0)
                then begin
                    RMSetup.Get();
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Customers" then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption(), Cust.TableCaption());
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Vendors" then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption(), Vend.TableCaption());
                    if "Business Relation Code" = RMSetup."Bus. Rel. Code for Bank Accs." then
                        Error(Text001,
                          FieldCaption("Business Relation Code"), "Business Relation Code",
                          Cont.TableCaption(), BankAcc.TableCaption());
                end;
            end;
        }
        field(3; "Link to Table"; Enum "Contact Business Relation Link To Table")
        {
            Caption = 'Link to Table';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Link to Table" = const(Customer)) Customer
            else
            if ("Link to Table" = const(Vendor)) Vendor
            else
            if ("Link to Table" = const("Bank Account")) "Bank Account"
            else
            if ("Link to Table" = const(Employee)) Employee;
        }
        field(5; "Business Relation Description"; Text[100])
        {
            CalcFormula = lookup("Business Relation".Description where(Code = field("Business Relation Code")));
            Caption = 'Business Relation Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Business Relation Code")
        {
            Clustered = true;
        }
        key(Key2; "Link to Table", "No.")
        {
        }
        key(Key3; "Link to Table", "Contact No.")
        {
        }
        key(Key4; "Business Relation Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnInsertOnBeforeFindByContact(Rec, IsHandled);
        if not IsHandled then
            if ContBusRel.FindByContact("Link to Table", "Contact No.") then
                Error(Text000, Cont.TableCaption(), "Contact No.", TableCaption(), "Link to Table", ContBusRel."No.");

        IsHandled := false;
        OnInsertOnBeforeFindByRelation(Rec, IsHandled);
        if not IsHandled then
            if ContBusRel.FindByRelation("Link to Table", "No.") then
                if GetContactBusinessRelation(ContBusRel) then
                    Error(Text000, "Link to Table", "No.", TableCaption(), Cont.TableCaption(), ContBusRel."Contact No.");

        ContBusRel.Reset();
        ContBusRel.SetRange("Contact No.", "Contact No.");
        ContBusRel.SetRange("Business Relation Code", "Business Relation Code");
        ContBusRel.SetRange("No.", '');
        ContBusRel.DeleteAll();
    end;

    var
        Cont: Record Contact;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 already has a %3 with %4 %5.';
        Text001: Label '%1 %2 is used when a %3 is linked with a %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FailedCBRTxt: Label 'Failed to find contact business relation for contact number %1.', Comment = '%1 = Contact number', Locked = true;
        TelemetryCategoryTxt: Label 'ContactBusinessRelation', Locked = true;

    local procedure GetContactBusinessRelation(ContactBusinessRelation: Record "Contact Business Relation"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        RecordRead: Boolean;
    begin
        case ContactBusinessRelation."Link to Table" of
            ContactBusinessRelation."Link to Table"::"Bank Account":
                RecordRead := BankAccount.Get(ContactBusinessRelation."No.");
            ContactBusinessRelation."Link to Table"::Customer:
                RecordRead := Customer.Get(ContactBusinessRelation."No.");
            ContactBusinessRelation."Link to Table"::Vendor:
                RecordRead := Vendor.Get(ContactBusinessRelation."No.");
            ContactBusinessRelation."Link to Table"::Employee:
                RecordRead := Employee.Get(ContactBusinessRelation."No.");
        end;
        OnGetContactBusinessRelation(ContactBusinessRelation, RecordRead);
        exit(RecordRead);
    end;

    procedure GetLinkedTables(FromLinkToTable: Enum "Contact Business Relation Link To Table"; FromNo: Code[20]; ToLinkToTable: Enum "Contact Business Relation Link To Table"): Code[20];
    begin
        SetLoadFields("Contact No.", "Link to Table");
        if FindByRelation(FromLinkToTable, FromNo) then
            if FindByContact(ToLinkToTable, "Contact No.") then
                exit("No.");
    end;

    procedure FindByContact(LinkType: Enum "Contact Business Relation Link To Table"; ContactNo: Code[20]): Boolean
    begin
        Reset();
        SetCurrentKey("Link to Table", "Contact No.");
        SetRange("Link to Table", LinkType);
        SetRange("Contact No.", ContactNo);
        exit(FindFirst());
    end;

    procedure FindByRelation(LinkType: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Boolean
    begin
        Reset();
        SetCurrentKey("Link to Table", "No.");
        SetRange("Link to Table", LinkType);
        SetRange("No.", LinkNo);
        exit(FindFirst());
    end;

    procedure GetContactNo(LinkType: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Code[20]
    begin
        if FindByRelation(LinkType, LinkNo) then
            exit("Contact No.");
        exit('');
    end;

    procedure CreateRelation(ContactNo: Code[20]; LinkNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table")
    begin
        Init();
        "Contact No." := ContactNo;
        "Business Relation Code" := GetBusinessRelationCodeFromSetup(LinkToTable);
        "Link to Table" := LinkToTable;
        "No." := LinkNo;
        Insert(true);
    end;

    procedure FindOrRestoreContactBusinessRelation(var Cont: Record Contact; RecVar: Variant; LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        ContCompany: Record Contact;
        CustContUpdate: Codeunit "CustCont-Update";
        VendContUpdate: Codeunit "VendCont-Update";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        FieldRef := RecRef.Field(1);

        if not FindByRelation(LinkToTable, Format(FieldRef.Value)) then
            if Cont.Type = Cont.Type::Person then
                if ContCompany.Get(Cont."Company No.") then begin
                    ContCompany.CheckForExistingRelationships(LinkToTable);
                    CreateRelation(ContCompany."No.", Format(FieldRef.Value), LinkToTable);
                end else begin
                    case RecRef.Number of
                        DATABASE::Customer:
                            CustContUpdate.OnInsert(RecVar);
                        DATABASE::Vendor:
                            VendContUpdate.OnInsert(RecVar);
                        else
                            OnFindOrRestoreContactBusinessRelationCaseElse(RecVar);
                    end;
                    FindFirst();
                    Cont.Validate("Company No.", "Contact No.");
                    Cont.Modify(true);
                end;
    end;

    local procedure GetBusinessRelationCodeFromSetup(LinkToTable: Enum "Contact Business Relation Link To Table") Result: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        MarketingSetup.Get();
        case LinkToTable of
            ContactBusinessRelation."Link to Table"::Customer:
                begin
                    MarketingSetup.TestField("Bus. Rel. Code for Customers");
                    exit(MarketingSetup."Bus. Rel. Code for Customers");
                end;
            ContactBusinessRelation."Link to Table"::Vendor:
                begin
                    MarketingSetup.TestField("Bus. Rel. Code for Vendors");
                    exit(MarketingSetup."Bus. Rel. Code for Vendors");
                end;
            ContactBusinessRelation."Link to Table"::Employee:
                begin
                    MarketingSetup.TestField("Bus. Rel. Code for Employees");
                    exit(MarketingSetup."Bus. Rel. Code for Employees");
                end;
            else
                OnGetBusinessRelationCodeFromSetupCaseElse(LinkToTable, Result);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateEmptyNoForContact(EntityNo: Code[20]; PrimaryContactNo: Code[20]; LinkToTableOption: Enum "Contact Business Relation Link To Table"): Boolean
    var
        PersonContact: Record Contact;
        CompanyContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if (EntityNo = '') or (PrimaryContactNo = '') then
            exit(false);

        if not PersonContact.Get(PrimaryContactNo) then
            exit(false);

        if PersonContact.Type <> PersonContact.Type::Person then
            exit(false);

        if CompanyContact.Get(PersonContact."Company No.") then
            if ContactBusinessRelation.FindByContact(LinkToTableOption, CompanyContact."No.") then
                if ContactBusinessRelation."No." = '' then begin
                    ContactBusinessRelation."No." := EntityNo;
                    ContactBusinessRelation.Modify();
                    exit(true);
                end;

        exit(false);
    end;

    procedure FindContactsByRelation(var Contact: Record Contact; LinkType: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Boolean
    begin
        if FindByRelation(LinkType, LinkNo) then begin
            Contact.SetRange("Company No.", "Contact No.");
            if Contact.IsEmpty() then begin
                Contact.SetRange("Company No.");
                Contact.SetRange("No.", "Contact No.");
            end;
            exit(Contact.FindSet());
        end;
        exit(false);
    end;

    procedure GetName() Name: Text;
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        Employee: Record Employee;
    begin
        if "No." = '' then
            exit('');

        case "Link to Table" of
            "Link to Table"::Customer:
                begin
                    Cust.Get("No.");
                    exit(Cust.Name);
                end;
            "Link to Table"::Vendor:
                begin
                    Vend.Get("No.");
                    exit(Vend.Name);
                end;
            "Link to Table"::"Bank Account":
                begin
                    BankAcc.Get("No.");
                    exit(BankAcc.Name);
                end;
            "Link to Table"::Employee:
                begin
                    Employee.Get("No.");
                    exit(Employee.FullName());
                end;
            else
                OnGetNameCaseElse(Rec, Name);
        end;
    end;

    procedure ShowRelatedCardPage();
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        Employee: Record Employee;
    begin
        if "No." = '' then begin
            PAGE.Run(PAGE::"Contact Business Relations", Rec);
            exit;
        end;

        case "Link to Table" of
            "Link to Table"::Customer:
                begin
                    Cust.Get("No.");
                    Cust.SetRange("Date Filter", 0D, WorkDate());
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            "Link to Table"::Vendor:
                begin
                    Vend.Get("No.");
                    Vend.SetRange("Date Filter", 0D, WorkDate());
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
            "Link to Table"::"Bank Account":
                begin
                    BankAcc.Get("No.");
                    BankAcc.SetRange("Date Filter", 0D, WorkDate());
                    PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                end;
            "Link to Table"::Employee:
                begin
                    Employee.Get("No.");
                    Page.Run(Page::"Employee Card", Employee);
                end;
            else
                OnShowRelatedCardPageCaseElse(Rec);
        end;
    end;

    procedure UpdateContactBusinessRelation()
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        if IsTemporary() then
            exit;

        IsHandled := false;
        OnBeforeUpdateContactBusinessRelation(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then begin
                if Contact.UpdateBusinessRelation() then
                    Contact.Modify();

                Contact.SetFilter("No.", '<>%1', "Contact No.");
                Contact.SetRange("Company No.", "Contact No.");
                if Contact.FindSet(true) then
                    repeat
                        if Contact.UpdateBusinessRelation() then
                            Contact.Modify();
                    until Contact.Next() = 0;
            end;
    end;

    internal procedure GetBusinessRelatedSystemIds(TableId: Integer; SystemId: Guid; var RelatedSystemIds: Dictionary of [Integer, List of [Guid]])
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        IContactBusinessRelationLink: Interface "Contact Business Relation Link";
        SystemIds: List of [Guid];
        RelatedTableId: Integer;
        RelatedSystemId: Guid;
    begin
        if TableId <> Database::Contact then
            exit;

        if Contact.GetBySystemId(SystemId) then begin
            if Contact."Contact Business Relation" = Contact."Contact Business Relation"::None then
                exit;

            ContactBusinessRelation.SetRange("Contact No.", Contact."Company No.");
            if not ContactBusinessRelation.FindSet() then begin
                Session.LogMessage('0000GCZ', StrSubstNo(FailedCBRTxt, Contact."Company No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTxt);
                exit;
            end;

            repeat
                if ContactBusinessRelation."Link to Table" <> ContactBusinessRelation."Link to Table"::" " then begin
                    IContactBusinessRelationLink := ContactBusinessRelation."Link to Table";
                    IContactBusinessRelationLink.GetTableAndSystemId(ContactBusinessRelation."No.", RelatedTableId, RelatedSystemId);

                    Clear(SystemIds);
                    if RelatedSystemIds.ContainsKey(RelatedTableId) then begin
                        SystemIds := RelatedSystemIds.Get(RelatedTableId);
                        if not SystemIds.Contains(RelatedSystemId) then
                            SystemIds.Add(RelatedSystemId);
                    end else
                        SystemIds.Add(RelatedSystemId);
                    RelatedSystemIds.Set(RelatedTableId, SystemIds);
                end;
            until ContactBusinessRelation.Next() <= 0;

        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindOrRestoreContactBusinessRelationCaseElse(RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBusinessRelationCodeFromSetupCaseElse(LinkToTable: Enum "Contact Business Relation Link To Table"; var Result: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetContactBusinessRelation(var ContactBusinessRelation: Record "Contact Business Relation"; var RecordRead: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNameCaseElse(ContactBusinessRelation: Record "Contact Business Relation"; var Name: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowRelatedCardPageCaseElse(ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeFindByRelation(ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeFindByContact(ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateContactBusinessRelation(ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;
}
