// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Configuration page for payment application settings.
/// Manages matching tolerances, rules, and automated processing options.
/// </summary>
page 1253 "Payment Application Settings"
{
    AdditionalSearchTerms = 'payment matching rules,automatic payment application';
    Caption = 'Payment Application Settings';
    ApplicationArea = Basic, Suite;
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "Bank Pmt. Appl. Settings";
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Settings)
            {
                group(General)
                {
                    Caption = 'General Settings';

                    field(ApplyManDisableSuggestions; Rec."Apply Man. Disable Suggestions")
                    {
                        Caption = 'Disable Suggestions for Apply Manually page';
                        ApplicationArea = All;
                    }

                    field(EnableApplyImmediatelly; Rec."Enable Apply Immediatelly")
                    {
                        Caption = 'Enable Apply Immediately Rules';
                        ApplicationArea = All;
                    }

                    field(RelatedPartyNameMatching; Rec."RelatedParty Name Matching")
                    {
                        Caption = 'Related Party Name Matching';
                        ApplicationArea = All;
                    }
                }

                group(LedgerEntriesSpecific)
                {
                    Caption = 'Ledger Entries Matching Settings';

                    field(CustLedgerEntriesMatching; Rec."Cust. Ledger Entries Matching")
                    {
                        Caption = 'Enable Customer Ledger Entries Matching';
                        ApplicationArea = All;
                    }

                    field(VendorLedgerEntriesMatching; Rec."Vendor Ledger Entries Matching")
                    {
                        Caption = 'Enable Vendor Ledger Entries Matching';
                        ApplicationArea = All;
                    }
                    field(EmployeeLedgerEntriesMatching; Rec."Empl. Ledger Entries Matching")
                    {
                        Caption = 'Enable Employee Ledger Entries Matching';
                        ApplicationArea = All;
                    }
                    field(BankLedgerEntriesMatching; Rec."Bank Ledger Entries Matching")
                    {
                        Caption = 'Enable Bank Ledger Entries Matching';
                        ApplicationArea = All;
                    }

                    field(BankLedgClosingDocNoMatch; Rec."Bank Ledg Closing Doc No Match")
                    {
                        Caption = 'Match Closing Document No. on Bank Ledger Entries';
                        ApplicationArea = All;
                    }
                }
                group(LedgersInApplyManually)
                {
                    Caption = 'Ledger Entries in "Apply Manually" page';
                    field(CustLedgerEntriesShown; CustomerLedgerEntriesShown)
                    {
                        Caption = 'Show Customer Ledger Entries in "Apply Manually" page';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if Customer Ledger Entries are shown in the "Apply Manually page".';
                        trigger OnValidate()
                        begin
                            Rec."Cust Ledg Hidden In Apply Man" := not CustomerLedgerEntriesShown;
                            Rec.Modify();
                        end;
                    }

                    field(VendorLedgerEntriesShown; VendorLedgerEntriesShown)
                    {
                        Caption = 'Show Vendor Ledger Entries in "Apply Manually" page';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if Vendor Ledger Entries are shown in the "Apply Manually page".';
                        trigger OnValidate()
                        begin
                            Rec."Vend Ledg Hidden In Apply Man" := not VendorLedgerEntriesShown;
                            Rec.Modify();
                        end;
                    }
                    field(EmployeeLedgerEntriesShown; EmployeeLedgerEntriesShown)
                    {
                        Caption = 'Show Employee Ledger Entries in "Apply Manually" page';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if Employee Ledger Entries are shown in the "Apply Manually page".';
                        trigger OnValidate()
                        begin
                            Rec."Empl Ledg Hidden In Apply Man" := not EmployeeLedgerEntriesShown;
                            Rec.Modify();
                        end;
                    }
                    field(BankLedgerEntriesShown; BankLedgerEntriesShown)
                    {
                        Caption = 'Show Bank Ledger Entries in "Apply Manually" page';
                        ApplicationArea = All;
                        ToolTip = 'Specifies if Bank Ledger Entries are shown in the "Apply Manually page".';
                        trigger OnValidate()
                        begin
                            Rec."Bank Ledg Hidden In Apply Man" := not BankLedgerEntriesShown;
                            Rec.Modify();
                        end;
                    }
                }
            }
        }
    }

    var
        CustomerLedgerEntriesShown, VendorLedgerEntriesShown, EmployeeLedgerEntriesShown, BankLedgerEntriesShown : Boolean;

    trigger OnOpenPage()
    begin
        Rec.GetOrInsert();
        CustomerLedgerEntriesShown := not Rec."Cust Ledg Hidden In Apply Man";
        VendorLedgerEntriesShown := not Rec."Vend Ledg Hidden In Apply Man";
        EmployeeLedgerEntriesShown := not Rec."Empl Ledg Hidden In Apply Man";
        BankLedgerEntriesShown := not Rec."Bank Ledg Hidden In Apply Man";
    end;
}
