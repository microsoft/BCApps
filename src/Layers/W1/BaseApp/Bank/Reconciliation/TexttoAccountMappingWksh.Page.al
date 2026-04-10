// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Setup;

/// <summary>
/// Worksheet page for text-to-account mapping configuration.
/// Provides advanced interface for creating and testing mapping rules.
/// </summary>
page 1254 "Text-to-Account Mapping Wksh."
{
    AutoSplitKey = true;
    Caption = 'Text-to-Account Mapping';
    DataCaptionFields = "Mapping Text";
    DelayedInsert = true;
    PageType = ListPlus;
    SourceTable = "Text-to-Account Mapping";

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                field(DefaultDebitAccName; DefaultDebitAccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Debit Account for Non-Item Lines';
                    Editable = false;
                    ToolTip = 'Specifies the debit account that is automatically inserted on purchase lines that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the Debit Acc. for Non-Item Lines field.';

                    trigger OnDrillDown()
                    var
                        AccType: Option Debit,Credit;
                    begin
                        SetUpDefaultGLAccounts(DefaultDebitAccNo, AccType::Debit);
                    end;
                }
                field(DefaultCreditAccName; DefaultCreditAccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Credit Account for Non-Item Lines';
                    Editable = false;
                    ToolTip = 'Specifies the credit account that is automatically inserted on purchase credit memo lines that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the Credit Acc. for Non-Item Lines field. For more information, see Debit Acc. for Non-Item Lines.';

                    trigger OnDrillDown()
                    var
                        AccType: Option Debit,Credit;
                    begin
                        SetUpDefaultGLAccounts(DefaultCreditAccNo, AccType::Credit);
                    end;
                }
            }
            group(MappingRules)
            {
                ShowCaption = false;
                repeater("Mapping Rules")
                {
                    field("Mapping Text"; Rec."Mapping Text")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Debit Acc. No."; Rec."Debit Acc. No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Credit Acc. No."; Rec."Credit Acc. No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bal. Source Type"; Rec."Bal. Source Type")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bal. Source No."; Rec."Bal. Source No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenPurchaseSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Default Accounts for Non-Item Lines';
                Image = Setup;
                RunObject = Page "Purchases & Payables Setup";
                ToolTip = 'Set up debit and credit accounts that are inserted on purchase credit memo lines by default, for example, when the product on the line can not be identified for text-to-account mapping.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenPurchaseSetup_Promoted; OpenPurchaseSetup)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        UpdateDefaultGLAccounts();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        VendorFilter: Text;
    begin
        VendorFilter := Rec.GetFilter("Vendor No.");
        if VendorFilter <> '' then
            Rec."Vendor No." := CopyStr(VendorFilter, 1, StrLen(VendorFilter));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Rec.CheckEntriesAreConsistent());
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        DefaultDebitAccNo: Code[20];
        DefaultDebitAccName: Text[100];
        DefaultCreditAccNo: Code[20];
        DefaultCreditAccName: Text[100];

    local procedure UpdateDefaultGLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        PurchasesPayablesSetup.Get();
        DefaultDebitAccNo := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        DefaultDebitAccName := '';
        DefaultCreditAccNo := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines";
        DefaultCreditAccName := '';
        if GLAccount.Get(DefaultDebitAccNo) then
            DefaultDebitAccName := StrSubstNo('%1 - %2', DefaultDebitAccNo, GLAccount.Name);
        if GLAccount.Get(DefaultCreditAccNo) then
            DefaultCreditAccName := StrSubstNo('%1 - %2', DefaultCreditAccNo, GLAccount.Name);
        CurrPage.Update();
    end;

    local procedure SetUpDefaultGLAccounts(Account: Code[20]; Type: Option Debit,Credit)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := Account;
        GLAccount.SetRange("Direct Posting", true);
        if PAGE.RunModal(PAGE::"G/L Account List", GLAccount) = ACTION::LookupOK then
            if Account <> GLAccount."No." then begin
                PurchasesPayablesSetup.Get();
                case Type of
                    Type::Debit:
                        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := GLAccount."No.";
                    Type::Credit:
                        PurchasesPayablesSetup."Credit Acc. for Non-Item Lines" := GLAccount."No.";
                end;
                PurchasesPayablesSetup.Modify();
                UpdateDefaultGLAccounts();
            end;
    end;
}

