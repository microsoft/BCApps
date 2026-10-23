// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 8410 "IC Gen. Journal Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeader', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := PurchaseHeader."Pay-to IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeaderPrepmt', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := PurchaseHeader."Buy-from IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
        GenJournalLine."IC Partner Code" := PurchaseHeader."Buy-from IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeader', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := SalesHeader."Bill-to IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeaderPrepmt', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost', '', true, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
        GenJournalLine."IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateAccountTypeOnBeforeCheckTemplateType', '', true, false)]
    local procedure OnValidateAccountTypeOnBeforeCheckTemplateType(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if Rec."Journal Template Name" <> '' then
            if Rec."Account Type" = Rec."Account Type"::"IC Partner" then begin
                GenJnlTemplate.Get(Rec."Journal Template Name");
                if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                    Rec.FieldError("Account Type");
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateBalAccountTypeOnBeforeCheckTemplateType', '', true, false)]
    local procedure OnValidateBalAccountTypeOnBeforeCheckTemplateType(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if Rec."Journal Template Name" <> '' then
            if Rec."Bal. Account Type" = Rec."Bal. Account Type"::"IC Partner" then begin
                GenJnlTemplate.Get(Rec."Journal Template Name");
                if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                    Rec.FieldError("Bal. Account Type");
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnUpdateICAccountNo', '', true, false)]
    local procedure OnUpdateICAccountNo(var Rec: Record "Gen. Journal Line")
    begin
        if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
            Rec.Validate("IC Account No.", Rec.GetDefaultICPartnerGLAccNo());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateAccountNoOnAfterAssignValue', '', true, false)]
    local procedure OnValidateAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"IC Partner" then
            GenJournalLine.GetICPartnerAccount();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnValidateBalAccountNoOnAfterAssignValue', '', true, false)]
    local procedure OnValidateBalAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"IC Partner" then
            GenJournalLine.GetICPartnerBalAccount();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckCustomerPartner', '', true, false)]
    local procedure OnCheckCustomerPartner(var GenJournalLine: Record "Gen. Journal Line"; Cust: Record Customer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJournalLine.CheckICPartner(Cust."IC Partner Code", AccountType, AccountNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckVendorPartner', '', true, false)]
    local procedure OnCheckVendorPartner(var GenJournalLine: Record "Gen. Journal Line"; Vend: Record Vendor; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJournalLine.CheckICPartner(Vend."IC Partner Code", AccountType, AccountNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGetAccCurrencyCodeCaseElse', '', true, false)]
    local procedure OnGetAccCurrencyCodeCaseElse(var Rec: Record "Gen. Journal Line"; var CurrencyCode: Code[10])
    var
        ICPartner: Record "IC Partner";
    begin
        if Rec."Account Type" = Rec."Account Type"::"IC Partner" then begin
            ICPartner.Get(Rec."Account No.");
            CurrencyCode := ICPartner."Currency Code";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnIsAdHocDescriptionElseCase', '', true, false)]
    local procedure OnIsAdHocDescriptionElseCase(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        if xRec."Account Type" = xRec."Account Type"::"IC Partner" then begin
            Result := ICPartner.Get(xRec."Account No.") and (ICPartner.Name <> Rec.Description);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnSetICAccountNoBlank', '', true, false)]
    local procedure OnSetICAccountNoBlank(var Rec: Record "Gen. Journal Line")
    begin
        Rec.Validate("IC Account No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnSetICPartnerCodeBlank', '', true, false)]
    local procedure OnSetICPartnerCodeBlank(var Rec: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type")
    begin
        if AccountType in [AccountType::Customer, AccountType::Vendor, AccountType::"IC Partner"] then
            Rec."IC Partner Code" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnIsCustVendICAdded', '', true, false)]
    local procedure OnIsCustVendICAdded(var GenJournalLine: Record "Gen. Journal Line"; var Rec: Record "Gen. Journal Line"; var Result: Boolean)
    begin
        Result := Rec.CustVendICAdded(GenJournalLine);
    end;
}