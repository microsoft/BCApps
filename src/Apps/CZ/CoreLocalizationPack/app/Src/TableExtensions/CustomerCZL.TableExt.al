// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Finance.Registration;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;

tableextension 11701 "Customer CZL" extends Customer
{
    fields
    {
        modify("Registration Number")
        {
            trigger OnAfterValidate()
            var
                RegistrationLogCZL: Record "Registration Log CZL";
                RegNoServiceConfigCZL: Record "Reg. No. Service Config CZL";
                ResultRecordRef: RecordRef;
                LogNotVerified: Boolean;
                IsHandled: Boolean;
            begin
                OnBeforeOnValidateRegistrationNoCZL(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;
                if not RegistrationNoMgtCZL.CheckRegistrationNo(GetRegistrationNoTrimmedCZL(), "No.", Database::Customer) then
                    exit;

                LogNotVerified := true;
                if "Registration Number" <> xRec."Registration Number" then
                    if RegNoServiceConfigCZL.RegNoSrvIsEnabled() then begin
                        LogNotVerified := false;
                        RegistrationLogMgtCZL.ValidateRegNoWithARES(ResultRecordRef, Rec, "No.", RegistrationLogCZL."Account Type"::Customer);
                        if ResultRecordRef.Number <> 0 then
                            ResultRecordRef.SetTable(Rec);
                    end;
                if LogNotVerified then
                    RegistrationLogMgtCZL.LogCustomer(Rec);
            end;
        }
        field(11767; "Last Unreliab. Check Date CZL"; Date)
        {
            CalcFormula = max("Unreliable Payer Entry CZL"."Check Date" where("VAT Registration No." = field("VAT Registration No."),
                                                                              "Type" = const(Payer)));
            Caption = 'Last Unreliability Check Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11769; "Disable Unreliab. Check CZL"; Boolean)
        {
            Caption = 'Disable Unreliability Check';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA26
        field(11770; "Registration No. CZL"; Text[20])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
            ObsoleteReason = 'Replaced by standard "Registration Number" field.';
        }
#endif
        field(11771; "Tax Registration No. CZL"; Text[20])
        {
            Caption = 'Tax Registration No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RegistrationNoMgtCZL.CheckTaxRegistrationNo("Tax Registration No. CZL", "No.", Database::Customer);
            end;
        }
        field(11772; "Validate Registration No. CZL"; Boolean)
        {
            Caption = 'Validate Registration No.';
            DataClassification = CustomerContent;
        }
        field(11780; "Unreliable Payer Status CZL"; Enum "Unreliable Payer Status CZL")
        {
            CalcFormula = lookup("Unreliable Payer Entry CZL".Status where("VAT Registration No." = field("VAT Registration No."),
                                                                           Type = const(Payer), "Check Date" = field("Last Unreliab. Check Date CZL")));
            Caption = 'Unreliable Payer Status';
            Editable = false;
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA25
        field(31070; "Transaction Type CZL"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
            ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
        }
        field(31071; "Transaction Specification CZL"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
            ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions. This field will not be used anymore.';
        }
        field(31072; "Transport Method CZL"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
            ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
        }
#endif
    }

    trigger OnDelete()
    begin
        UnreliablePayerMgtCZL.UpdateUnreliablePayerEntriesOnDelete(Rec);
        RegistrationLogMgtCZL.DeleteCustomerLog(Rec);
    end;

    var
        RegistrationLogMgtCZL: Codeunit "Registration Log Mgt. CZL";
        RegistrationNoMgtCZL: Codeunit "Registration No. Mgt. CZL";
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
        RegistrationNo: Text[20];

    // procedure ImportUnrPayerStatusCZL()
    // var
    //     UnreliablePayerEntry: Record "Unreliable Payer Entry CZL";
    //     ConfirmManagement: Codeunit "Confirm Management";
    // begin
    //     if not UnreliablePayerMgtCZL.ImportUnrPayerStatusForVendor(Rec) then
    //         exit;
    //     if not ConfirmManagement.GetResponse(ImportSuccessfulQst, true) then
    //         exit;

    //     Commit();
    //     UnreliablePayerEntry.SetRange("Vendor No.", "No.");
    //     UnreliablePayerEntry."Vendor No." := "No.";
    //     Page.RunModal(Page::"Unreliable Payer Entries CZL", UnreliablePayerEntry);
    // end;

    procedure IsUnreliablePayerCheckPossibleCZL(): Boolean
    begin
        if "Disable Unreliab. Check CZL" then
            exit(false);
        if not UnreliablePayerMgtCZL.IsUnreliablePayerServiceEnabled() then
            exit(false);
        exit(UnreliablePayerMgtCZL.IsVATRegNoExportPossible("VAT Registration No.", "Country/Region Code"));
    end;

    procedure GetUnreliablePayerStatusCZL(): Enum "Unreliable Payer Status CZL"
    begin
        exit(UnreliablePayerMgtCZL.GetUnreliablePayerStatusCZL("VAT Registration No."));
    end;

    procedure ShowUnreliableEntriesCZL()
    var
        UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL";
        UnreliablePayerEntriesCZL: Page "Unreliable Payer Entries CZL";
        UnreliablePayerEntriesCZLCaptionTok: Label '%1 - %2', Comment = '%1 = Vendor No., %2 = Page caption', Locked = true;
    begin
        UnreliablePayerEntryCZL.SetCurrentKey("VAT Registration No.", "Vendor No.", "Check Date");
        UnreliablePayerEntryCZL.FilterGroup(2);
        UnreliablePayerEntryCZL.SetRange("VAT Registration No.", Rec."VAT Registration No.");
        UnreliablePayerEntryCZL.FilterGroup(0);
        UnreliablePayerEntriesCZL.SetTableView(UnreliablePayerEntryCZL);
        UnreliablePayerEntriesCZL.SetUnreliablePayerNoCZL(Rec."No.");
        UnreliablePayerEntriesCZL.Caption := StrSubstNo(UnreliablePayerEntriesCZLCaptionTok, Rec."No.", UnreliablePayerEntriesCZL.Caption);
        UnreliablePayerEntriesCZL.RunModal();
    end;

    procedure CheckOpenCustomerLedgerEntriesCZL()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ChangeErr: Label ' cannot be changed';
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", Open);
        CustLedgerEntry.SetRange("Customer No.", "No.");
        CustLedgerEntry.SetRange(Open, true);
        if not CustLedgerEntry.IsEmpty() then
            FieldError("Customer Posting Group", ChangeErr);
    end;

    procedure GetLinkedVendorCZL(): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", "No.");
        if ContactBusinessRelation.FindFirst() then begin
            ContactBusinessRelation.SetRange("Contact No.", ContactBusinessRelation."Contact No.");
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
            ContactBusinessRelation.SetRange("No.");
            if ContactBusinessRelation.FindFirst() then
                exit(ContactBusinessRelation."No.");
        end;
    end;

    internal procedure SaveRegistrationNoCZL()
    begin
        RegistrationNo := GetRegistrationNoTrimmedCZL();
    end;

    internal procedure GetSavedRegistrationNoCZL(): Text[20]
    begin
        exit(RegistrationNo);
    end;

    procedure GetRegistrationNoTrimmedCZL(): Text[20]
    begin
        exit(CopyStr("Registration Number", 1, 20));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnValidateRegistrationNoCZL(Customer: Record "Customer"; xCustomer: Record "Customer"; var IsHandled: Boolean)
    begin
    end;
}
