// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 8422 ICStandardGeneralJournalLine
{
    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnCheckCustomerPartner', '', true, false)]
    local procedure OnCheckCustomerPartner(var StandardGeneralJournalLine: Record "Standard General Journal Line"; Cust: Record Customer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        StandardGeneralJournalLine.CheckICPartner(Cust."IC Partner Code", AccountType, AccountNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnCheckVendorPartner', '', true, false)]
    local procedure OnCheckVendorPartner(var StandardGeneralJournalLine: Record "Standard General Journal Line"; Vend: Record Vendor; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        StandardGeneralJournalLine.CheckICPartner(Vend."IC Partner Code", AccountType, AccountNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnSetICAccountNoBlank', '', true, false)]
    local procedure OnSetICAccountNoBlank(var Rec: Record "Standard General Journal Line")
    begin
        Rec.Validate("IC Account No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnSetICPartnerCodeBlank', '', true, false)]
    local procedure OnSetICPartnerCodeBlank(var Rec: Record "Standard General Journal Line"; AccountType: Enum "Gen. Journal Account Type")
    begin
        if AccountType in [AccountType::Customer, AccountType::Vendor, AccountType::"IC Partner"] then
            Rec."IC Partner Code" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnValidateAccountNoOnAfterAssignValue', '', true, false)]
    local procedure OnValidateAccountNoOnAfterAssignValue(var StandardGeneralJournalLine: Record "Standard General Journal Line"; var xStandardGeneralJournalLine: Record "Standard General Journal Line")
    begin
        if StandardGeneralJournalLine."Account Type" = StandardGeneralJournalLine."Account Type"::"IC Partner" then
            StandardGeneralJournalLine.GetICPartnerAccount();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnValidateBalAccountNoOnAfterAssignValue', '', true, false)]
    local procedure OnValidateBalAccountNoOnAfterAssignValue(var StandardGeneralJournalLine: Record "Standard General Journal Line"; var xStandardGeneralJournalLine: Record "Standard General Journal Line")
    begin
        if StandardGeneralJournalLine."Bal. Account Type" = StandardGeneralJournalLine."Bal. Account Type"::"IC Partner" then
            StandardGeneralJournalLine.GetICPartnerBalAccount();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnUpdateICAccountNo', '', true, false)]
    local procedure OnUpdateICAccountNo(var Rec: Record "Standard General Journal Line")
    begin
        if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
            Rec.Validate("IC Account No.", Rec.GetDefaultICPartnerGLAccNo());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard General Journal Line", 'OnCheckAccountElseCase', '', true, false)]
    local procedure OnCheckAccountElseCase(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if AccountType = AccountType::"IC Partner" then begin
            ICPartner.Get(AccountNo);
            ICPartner.CheckICPartner();
        end;
    end;
}
