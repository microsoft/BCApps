// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

tableextension 8400 "IC Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        modify("Bal. Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        /// <summary>
        /// Intercompany partner code for IC transactions enabling cross-company business workflows and eliminations.
        /// </summary>
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Intercompany direction indicating whether the transaction is inbound or outbound for IC processing workflows.
        /// </summary>
        field(114; "IC Direction"; Enum Microsoft.Intercompany.Setup."IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Intercompany transaction number for tracking and matching IC transactions across partner companies.
        /// </summary>
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /// <summary>
        /// Intercompany account type for IC transactions determining posting account classification.
        /// </summary>
        field(130; "IC Account Type"; Enum Microsoft.Intercompany.Journal."IC Journal Account Type")
        {
            Caption = 'IC Account Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the type of the account that you want to use for the transaction with your IC partner.';
        }
        /// <summary>
        /// Intercompany account number for posting IC transactions to partner company accounts.
        /// </summary>
        field(131; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
            ToolTip = 'Specifies the number of the general ledger or bank account that the IC transaction is posted to.';
            DataClassification = CustomerContent;
            TableRelation =
            if ("IC Account Type" = const("G/L Account")) "IC G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Account No."), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Bal. Account No."), Blocked = const(false));
        }
    }

    procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
            ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
            "IC Partner Code" := ICPartnerCode;
        end;
    end;

    procedure GetDefaultICPartnerGLAccNo(): Code[20]
    var
        GLAcc: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        if Rec."IC Partner Code" <> '' then begin
            if Rec."Account Type" = Rec."Account Type"::"G/L Account" then
                GLAccNo := "Account No."
            else
                GLAccNo := Rec."Bal. Account No.";
            if GLAcc.Get(GLAccNo) then
                exit(GLAcc."Default IC Partner G/L Acc. No")
        end;
    end;

    procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner();
        UpdateDescription(ICPartner.Name);
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearPostingGroups();
        "IC Partner Code" := "Account No.";

        OnAfterAccountNoOnValidateGetICPartnerAccount(Rec, ICPartner);
    end;

    procedure GetICPartnerBalAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Bal. Account No.");
        UpdateDescriptionFromBalAccount(ICPartner.Name);

        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearBalancePostingGroups();
        "IC Partner Code" := "Bal. Account No.";

        OnAfterAccountNoOnValidateGetICPartnerBalAccount(Rec, ICPartner);
    end;

    internal procedure CustVendICAdded(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCustVendICAdded(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJournalLine."Account No." <> '') and
           (GenJournalLine."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Account Type", GenJournalLine."Account No."));

        if (GenJournalLine."Bal. Account No." <> '') and
           (GenJournalLine."Bal. Account Type" in ["Bal. Account Type"::Customer,
                                                   "Bal. Account Type"::Vendor,
                                                   "Bal. Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No."));

        exit(false);
    end;

    local procedure AddCustVendIC(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Boolean
    begin
        SetRange("Account Type", AccountType);
        SetRange("Account No.", AccountNo);
        if not IsEmpty() then
            exit(false);

        Reset();
        if FindLast() then;
        "Line No." += 10000;

        "Account Type" := AccountType;
        "Account No." := AccountNo;
        Insert();
        exit(true);
    end;

    /// <summary>
    /// Event triggered after retrieving an intercompany partner record for the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing intercompany partner account data. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to intercompany partner accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the intercompany partner account is being processed.
    /// </param>
    /// <param name="ICPartner">
    /// The intercompany partner record that has been retrieved and processed.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    /// <summary>
    /// Event triggered after retrieving an intercompany partner record for the balancing account in the general journal line.
    /// Subscribing to this event allows developers to extend or customize the behavior
    /// when processing intercompany partner data for the balancing account. This can be useful for implementing additional logic,
    /// validations, or handling specific business rules related to balancing intercompany partner accounts.
    /// </summary>
    /// <param name="GenJournalLine">
    /// The general journal line record for which the balancing intercompany partner account is being processed.
    /// </param>
    /// <param name="ICPartner">
    /// The intercompany partner record that has been retrieved and processed as the balancing account.
    /// </param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    /// <summary>
    /// Event triggered before determining if a Customer, Vendor, or IC Partner is added based on the General Journal Line.
    /// This event allows developers to add custom logic or skip the default logic for checking the addition of Customer, Vendor, or IC Partner.
    /// </summary>
    /// <param name="GenJournalLine">The General Journal Line record being processed.</param>
    /// <param name="IsHandled">A boolean variable that, if set to true, skips the default logic for determining if a Customer, Vendor, or IC Partner is added.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}