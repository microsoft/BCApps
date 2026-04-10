namespace System.Integration;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 1812 "Data Migration Del G/L Account"
{

    trigger OnRun()
    begin
        RemoveAccountsFromAccountScheduleLine();
        RemoveAccountsFromCustomerPostingGroup();
        RemoveAccountsFromVendorPostingGroup();
        RemoveAccountsFromBankAccountPostingGroup();
        RemoveAccountsFromGenJournalBatch();
        RemoveAccountsFromGenPostingSetup();
        RemoveAccountsFromPaymentMethod();
        RemoveAccountsFromInventoryPostingSetup();
        RemoveAccountsFromTaxSetup();
        RemoveAccountsFromCurrency();
        DeleteGLAccounts();
        RemoveGLAccountsFromVATPostingSetup();
    end;

    local procedure DeleteGLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        if GLAccount.FindFirst() then
            GLAccount.DeleteAll();
        Commit();
    end;

    local procedure RemoveAccountsFromCustomerPostingGroup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerCode: Code[20];
    begin
        CustomerPostingGroup.Reset();
        if CustomerPostingGroup.FindSet() then
            repeat
                CustomerCode := CustomerPostingGroup.Code;
                CustomerPostingGroup.Delete();
                CustomerPostingGroup.Init();
                CustomerPostingGroup.Code := CustomerCode;
                CustomerPostingGroup.Insert();
            until CustomerPostingGroup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromVendorPostingGroup()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorCode: Code[20];
    begin
        VendorPostingGroup.Reset();
        if VendorPostingGroup.FindSet() then
            repeat
                VendorCode := VendorPostingGroup.Code;
                VendorPostingGroup.Delete();
                VendorPostingGroup.Init();
                VendorPostingGroup.Code := VendorCode;
                VendorPostingGroup.Insert();
            until VendorPostingGroup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromBankAccountPostingGroup()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankAccountCode: Code[20];
    begin
        BankAccountPostingGroup.Reset();
        if BankAccountPostingGroup.FindSet() then
            repeat
                BankAccountCode := BankAccountPostingGroup.Code;
                BankAccountPostingGroup.Delete();
                BankAccountPostingGroup.Init();
                BankAccountPostingGroup.Code := BankAccountCode;
                BankAccountPostingGroup.Insert();
            until BankAccountPostingGroup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromGenJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Reset();
        if GenJournalBatch.FindSet() then
            repeat
                GenJournalBatch."Bal. Account No." := '';
                GenJournalBatch.Modify();
            until GenJournalBatch.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromGenPostingSetup()
    var
        GenPostingSetup: Record "General Posting Setup";
        GenBusPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        GenPostingSetup.Reset();
        if GenPostingSetup.FindSet() then
            repeat
                GenBusPostingGroup := GenPostingSetup."Gen. Bus. Posting Group";
                GenProdPostingGroup := GenPostingSetup."Gen. Prod. Posting Group";
                GenPostingSetup.Delete();
                GenPostingSetup.Init();
                GenPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
                GenPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
                GenPostingSetup.Insert();
            until GenPostingSetup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromPaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Reset();
        if PaymentMethod.FindSet() then
            repeat
                PaymentMethod."Bal. Account No." := '';
                PaymentMethod.Modify();
            until PaymentMethod.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromInventoryPostingSetup()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        LocationCode: Code[10];
        InvPostingGroupCode: Code[20];
    begin
        InventoryPostingSetup.Reset();
        if InventoryPostingSetup.FindSet() then
            repeat
                LocationCode := InventoryPostingSetup."Location Code";
                InvPostingGroupCode := InventoryPostingSetup."Invt. Posting Group Code";
                InventoryPostingSetup.Delete();
                InventoryPostingSetup.Init();
                InventoryPostingSetup."Location Code" := LocationCode;
                InventoryPostingSetup."Invt. Posting Group Code" := InvPostingGroupCode;
                InventoryPostingSetup.Insert();
            until InventoryPostingSetup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromTaxSetup()
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Reset();
        if TaxSetup.FindSet() then
            repeat
                TaxSetup."Tax Account (Sales)" := '';
                TaxSetup."Tax Account (Purchases)" := '';
                TaxSetup."Unreal. Tax Acc. (Sales)" := '';
                TaxSetup."Unreal. Tax Acc. (Purchases)" := '';
                TaxSetup."Reverse Charge (Purchases)" := '';
                TaxSetup."Unreal. Rev. Charge (Purch.)" := '';
                TaxSetup.Modify();
            until TaxSetup.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromAccountScheduleLine()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.Reset();
        if AccScheduleLine.FindSet() then
            repeat
                if AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::"Posting Accounts" then begin
                    AccScheduleLine.Totaling := '';
                    AccScheduleLine.Modify();
                end
                  ;
            until AccScheduleLine.Next() = 0;
        Commit();
    end;

    local procedure RemoveAccountsFromCurrency()
    var
        Currency: Record Currency;
    begin
        Currency.Reset();
        if Currency.FindSet() then
            repeat
                Currency."Unrealized Gains Acc." := '';
                Currency."Realized Gains Acc." := '';
                Currency."Unrealized Losses Acc." := '';
                Currency."Realized Losses Acc." := '';
                Currency."Realized G/L Gains Account" := '';
                Currency."Realized G/L Losses Account" := '';
                Currency."Residual Gains Account" := '';
                Currency."Residual Losses Account" := '';
                Currency."Conv. LCY Rndg. Credit Acc." := '';
                Currency."Conv. LCY Rndg. Debit Acc." := '';
                Currency.Modify();
            until Currency.Next() = 0;
        Commit();
    end;

    local procedure RemoveGLAccountsFromVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Reset();
        VATPostingSetup.ModifyAll("Sales VAT Account", '');
        VATPostingSetup.ModifyAll("Purchase VAT Account", '');
        VATPostingSetup.ModifyAll("Reverse Chrg. VAT Acc.", '');
    end;
}

