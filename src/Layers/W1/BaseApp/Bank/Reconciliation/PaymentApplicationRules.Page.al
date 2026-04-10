// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Configuration page for payment application matching rules.
/// Allows setup of automated matching criteria and confidence levels.
/// </summary>
page 1252 "Payment Application Rules"
{
    AdditionalSearchTerms = 'payment matching rules,automatic payment application';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Application Rules';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Bank Pmt. Appl. Rule";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Rules)
            {
                field("Match Confidence"; Rec."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Related Party Matched"; Rec."Related Party Matched")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Doc. No./Ext. Doc. No. Matched"; Rec."Doc. No./Ext. Doc. No. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No./Ext. Document No. Matched';
                }
                field("Amount Incl. Tolerance Matched"; Rec."Amount Incl. Tolerance Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of Entries Within Amount Tolerance Found';
                }
                field("Direct Debit Collect. Matched"; Rec."Direct Debit Collect. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direct Debit Collection Matched';
                }
                field("Review Required"; Rec."Review Required")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Review Required';
                }

                field("Apply Immediatelly"; Rec."Apply Immediatelly")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Immediatelly';
                    Visible = ApplyAutomaticallyVisible;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RestoreDefaultRules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restore Default Rules';
                Image = Restore;
                ToolTip = 'Delete the application rules and replace them with the default rules, which control whether payments are automatically applied to open ledger entries.';

                trigger OnAction()
                begin
                    if not Confirm(ResetToDefaultsQst) then
                        exit;

                    Rec.DeleteAll();
                    Rec.InsertDefaultMatchingRules();
                end;
            }

            action(AdvancedSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advanced Settings';
                Image = Setup;
                ToolTip = 'Opens advanced settings for configuring payment application matching.';
                RunObject = page "Payment Application Settings";
                RunPageOnRec = false;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RestoreDefaultRules_Promoted; RestoreDefaultRules)
                {
                }
                actionref(AdvancedSettings_Promoted; AdvancedSettings)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        Rec.SetCurrentKey(Score);
        Rec.Ascending(false);
        BankPmtApplSettings.GetOrInsert();
        ApplyAutomaticallyVisible := BankPmtApplSettings."Enable Apply Immediatelly";
    end;

    var
        ResetToDefaultsQst: Label 'All current payment application rules will be deleted and replaced with the default payment application rules.\\Do you want to continue?';
        ApplyAutomaticallyVisible: Boolean;
}

