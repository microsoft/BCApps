// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Reflection;

page 1286 "Payment Rec Match Details"
{
    Caption = 'Match Details';
    PageType = CardPart;
    SourceTable = "Bank Acc. Reconciliation Line";

    layout
    {
        area(content)
        {
            field(Status; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status';
                ToolTip = 'Specifies the status of the selected line.';
            }

            group(TextToAccountMappingGroup)
            {
                Visible = IsMapToTextAccount;
                ShowCaption = false;

                field(ApplicableTextToAccountMapping; TempTextToAccMapping.Count())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applicable Text-to-Account Mappings';
                    ToolTip = 'Specifies the number of text-to-account mappings that can be used.';
                }

                group(AppliedTextToAccountRuleGroup)
                {
                    Visible = IsAppliedTextToAccountVisible;
                    ShowCaption = false;

                    field(AppliedTextToAccount; TempTextToAccMapping."Mapping Text")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Text-to-Account Mapping Used';
                        ToolTip = 'Specifies the text-to-account mapping that was used.';

                        trigger OnDrillDown()
                        var
                            TextToAccMapping: REcord "Text-to-Account Mapping";
                        begin
                            if TextToAccMapping.Get(TempTextToAccMapping."Line No.") then
                                Page.Run(PAGE::"Text-to-Account Mapping", TextToAccMapping);
                        end;
                    }
                }
            }

            group(MatchedAutomaticallyGroup)
            {
                Visible = IsMatchedAutomatically;
                ShowCaption = false;

                field(MatchConfidence; BankPmtApplRule."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Confidence';
                    ToolTip = 'Specifies the quality of the match between the bank statement line and the open ledger entry.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Payment Application Rules", BankPmtApplRule);
                    end;
                }

                group(ReledatedParty)
                {
                    Caption = 'Related Party';
                    field(RelatedPatryMatchedOverview; RelatedPartyMatchedText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Related Party Matched';
                        Editable = false;
                        ToolTip = 'Specifies if information about the business partner on the bank statement line matches with the name on the open ledger entry.';

                        trigger OnDrillDown()
                        begin
                            Message(RelatedPartyMatchInfoText);
                        end;
                    }

                    field(RelatedPartyName; AppliedToName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Related Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the business partner matched.';
                        Enabled = RelatedPartyMatchInfoEnabled;

                        trigger OnDrillDown()
                        begin
                            Rec.AppliedToDrillDown();
                        end;
                    }
                }

                group(DocExtDocNoMatchedGroup)
                {
                    Caption = 'Document Number';
                    field(DocExtDocNoMatchedOverview; DocumentMatchedText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No./Ext. Document No. Matched';
                        Editable = false;
                        Enabled = DocumentMatchInfoEnabled;

                        ToolTip = 'Specifies if text on the bank statement line matches with text in the Document No. and/or External Document No. fields on the open ledger entry.';
                        trigger OnDrillDown()
                        begin
                            Message(DocumentMatchInfoText);
                        end;
                    }

                    field(DocExtDocNumber; Rec.GetAppliedToDocumentNo())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Number';
                        Editable = false;
                        ToolTip = 'Specifies the document number the payment was applied to.';

                        trigger OnDrillDown()
                        begin
                            Rec.ShowAppliedToEntries();
                        end;
                    }
                }

                group(DirectDebitGroup)
                {
                    Caption = 'Direct Debit';
                    Visible = DirectDebitMatched;
                    field(DirectDebit; DirectDebitMatchedText)
                    {
                        Visible = DirectDebitMatched;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Direct Debit Collect. Matched';
                        Editable = false;
                        ToolTip = 'Specifies information about a direct debit collection on the bank statement line matches with the open ledger entry.';
                    }
                }
                group(AmountMatchingDetails)
                {
                    Caption = 'Amount Matching Details';
                    field(AmountMatchText; AmountMatchText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Incl. Tolerance Matched:';
                        ToolTip = 'Specifies how many open ledger entries have a remaining amount, including payment tolerances, that matches the bank statement line amount.';
                    }

                    field(AccountName; AppliedToName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Open Ledger Entries for';
                        ToolTip = 'Specifies the number of open ledger entries for the customer or vendor on the line.';

                        trigger OnDrillDown()
                        begin
                            Rec.OpenAccountPage(Rec."Account Type".AsInteger(), Rec."Account No.");
                        end;
                    }

                    field(NoOfLedgerEntriesWithinAmount; NoOfLedgerEntriesWithinAmountTolerance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Within Amount Tolerance';
                        Editable = false;
                        ToolTip = 'Specifies the number of open ledger entries where the payment amount is within the payment tolerance of the amount.';

                        trigger OnDrillDown()
                        begin
                            Rec.DrillDownOnNoOfLedgerEntriesWithinAmountTolerance();
                        end;
                    }

                    field(NoOfLedgerEntriesOutsideAmount; NoOfLedgerEntriesOutsideAmountTolerance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Outside Amount Tolerance';
                        Editable = false;
                        ToolTip = 'Specifies the number of open ledger entries where the payment amount is outside of the payment tolerance amount.';

                        trigger OnDrillDown()
                        begin
                            Rec.DrillDownOnNoOfLedgerEntriesOutsideOfAmountTolerance();
                        end;
                    }
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Set Up Payment Application Rules';
                Ellipsis = true;
                Image = Setup;
                ToolTip = 'Set up or improve existing rules that govern how bank statement lines are automatically matched with open ledger entries for payment application.';
                RunObject = page "Payment Application Rules";
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ClearGlobals();
        FetchData();
    end;

    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TempTextToAccMapping: Record "Text-to-Account Mapping" temporary;
        AppliedToName: Text;
        IsMatchedAutomatically: Boolean;
        IsMapToTextAccount: Boolean;
        IsAppliedTextToAccountVisible: Boolean;
        StatusText: Text;

    protected var
        RelatedPartyMatchedText: Text;
        AmountMatchText: Text;
        DocumentMatchedText: Text;
        DirectDebitMatchedText: Text;
        DirectDebitMatched: Boolean;
        RelatedPartyMatchInfoText: Text;
        DocumentMatchInfoText: Text;
        RelatedPartyMatchInfoEnabled: Boolean;
        DocumentMatchInfoEnabled: Boolean;
        NoOfLedgerEntriesWithinAmountTolerance: Integer;
        NoOfLedgerEntriesOutsideAmountTolerance: Integer;

    local procedure ClearGlobals()
    begin
        Clear(BankPmtApplRule);
        Clear(NoOfLedgerEntriesWithinAmountTolerance);
        Clear(NoOfLedgerEntriesOutsideAmountTolerance);
        Clear(AppliedToName);
        Clear(StatusText);
        Clear(RelatedPartyMatchedText);
        Clear(AmountMatchText);
        Clear(DocumentMatchedText);
        Clear(DirectDebitMatchedText);
        Clear(DirectDebitMatched);
        Clear(IsMatchedAutomatically);
        Clear(IsAppliedTextToAccountVisible);
        Clear(IsMapToTextAccount);
        Clear(RelatedPartyMatchInfoText);
        Clear(DocumentMatchInfoText);
        Clear(RelatedPartyMatchInfoEnabled);
        Clear(DocumentMatchInfoEnabled);
        TempTextToAccMapping.Reset();
        TempTextToAccMapping.DeleteAll();
    end;

    local procedure FetchData()
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        StatementTypeFieldRef: FieldRef;
        StatementType: Option;
        BankAccountNo: Text;
        StatementNo: Text;
        StatementLineNo: Integer;
    begin
        Rec.FilterGroup(4);

        RecRef.Open(Database::"Bank Acc. Reconciliation Line", true);
        StatementTypeFieldRef := RecRef.Field(Rec.FieldNo("Statement Type"));
        StatementType := TypeHelper.GetOptionNo(Rec.GetFilter("Statement Type"), StatementTypeFieldRef.OptionCaption);

        BankAccountNo := Rec.GetFilter("Bank Account No.");
        StatementNo := Rec.GetFilter("Statement No.");
        Evaluate(StatementLineNo, Rec.GetFilter("Statement Line No."));

        Rec.SetAutoCalcFields("Match Quality", "Match Confidence");
        if not Rec.Get(StatementType, BankAccountNo, StatementNo, StatementLineNo) then
            exit;

        StatusText := Rec.GetStatusText();

        IsMapToTextAccount := MatchBankPayments.IsTextToAccountMappig(Rec, TempTextToAccMapping);
        if IsMapToTextAccount then begin
            IsAppliedTextToAccountVisible := TempTextToAccMapping.Count() > 0;
            exit;
        end;

        IsMatchedAutomatically := MatchBankPayments.IsMatchedAutomatically(Rec, BankPmtApplRule);
        MatchBankPayments.GetMatchPaymentDetailsInfo(Rec, BankPmtApplRule, IsMatchedAutomatically, RelatedPartyMatchedText, AmountMatchText, DocumentMatchedText, DirectDebitMatchedText, DirectDebitMatched, NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance, RelatedPartyMatchInfoText, DocumentMatchInfoText);
        AppliedToName := Rec.GetAppliedToName();
        RelatedPartyMatchInfoEnabled := RelatedPartyMatchInfoText <> '';
        DocumentMatchInfoEnabled := DocumentMatchInfoText <> '';
    end;
}

