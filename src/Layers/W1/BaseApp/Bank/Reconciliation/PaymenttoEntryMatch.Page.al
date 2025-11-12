// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Reflection;

page 1288 "Payment-to-Entry Match"
{
    Caption = 'Payment-to-Entry Match';
    PageType = CardPart;
    SourceTable = "Applied Payment Entry";

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
                field(MatchConfidence; BankPmtApplRule."Match Confidence")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Confidence';
                    ToolTip = 'Specifies the quality of the match between the payment and the open entry for payment purposes.';
                }
                field(RelatedPatryMatchedOverview; BankPmtApplRule."Related Party Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Party Matched';
                    Editable = false;
                    ToolTip = 'Specifies how much information on the payment reconciliation journal line must match with the open entry before a payment is automatically applied.';
                }
                field(DocExtDocNoMatchedOverview; BankPmtApplRule."Doc. No./Ext. Doc. No. Matched")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No./Ext. Document No. Matched';
                    Editable = false;
                    ToolTip = 'Specifies if text must match with the field on the open entry before the application rule will be used to automatically apply the payment.';
                }
                field(AmountMatchText; AmountMatchText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Incl. Tolerance Matched:';
                    ToolTip = 'Specifies how many entries must match the amount, including payment tolerance, before a payment is automatically applied to the open entry.';
                }
#pragma warning disable AA0100
                field("BankAccReconciliationLine.GetAppliedEntryAccountName(""Applies-to Entry No."")"; BankAccReconciliationLine.GetAppliedEntryAccountName(Rec."Applies-to Entry No."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Open Entries for';
                    ToolTip = 'Specifies the number of open entries for the customer or vendor.';

                    trigger OnDrillDown()
                    begin
                        BankAccReconciliationLine.AppliedEntryAccountDrillDown(Rec."Applies-to Entry No.");
                    end;
                }
                field(NoOfLedgerEntriesWithinAmount; NoOfLedgerEntriesWithinAmountTolerance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Within Amount Tolerance';
                    Editable = false;
                    ToolTip = 'Specifies the number of open entries where the payment amount is within the payment tolerance of the amount.';

                    trigger OnDrillDown()
                    begin
                        BankAccReconciliationLine.DrillDownOnNoOfLedgerEntriesWithinAmountTolerance();
                    end;
                }
                field(NoOfLedgerEntriesOutsideAmount; NoOfLedgerEntriesOutsideAmountTolerance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Outside Amount Tolerance';
                    Editable = false;
                    ToolTip = 'Specifies the number of open entries where the payment amount is outside of the payment tolerance amount.';

                    trigger OnDrillDown()
                    begin
                        BankAccReconciliationLine.DrillDownOnNoOfLedgerEntriesOutsideOfAmountTolerance();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        FetchData();
    end;

    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AccTypeErr: Label 'Wrong account type.';
        NoOfLedgerEntriesWithinAmountTolerance: Integer;
        NoOfLedgerEntriesOutsideAmountTolerance: Integer;
        AmountMatchText: Text;

    local procedure FetchData()
    var
        MatchBankPayments: Codeunit "Match Bank Payments";
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        AccountTypeFieldRef: FieldRef;
        StatementTypeFieldRef: FieldRef;
        MatchConfidenceFieldRef: FieldRef;
        AppliesToEntryNo: Integer;
        AccountType: Enum "Gen. Journal Account Type";
        StatementType: Option;
        BankAccountNo: Text;
        StatementNo: Text;
        StatementLineNo: Integer;
        Quality: Decimal;
    begin
        Rec.FilterGroup(4);
        Evaluate(AppliesToEntryNo, Rec.GetFilter("Applies-to Entry No."));
        RecRef.GetTable(Rec);
        AccountTypeFieldRef := RecRef.Field(Rec.FieldNo("Account Type"));
        AccountType :=
            Enum::"Gen. Journal Account Type".FromInteger(
                TypeHelper.GetOptionNo(Rec.GetFilter("Account Type"), AccountTypeFieldRef.OptionCaption));
        StatementTypeFieldRef := RecRef.Field(Rec.FieldNo("Statement Type"));
        StatementType := TypeHelper.GetOptionNo(Rec.GetFilter("Statement Type"), StatementTypeFieldRef.OptionCaption);

        BankAccountNo := Rec.GetFilter("Bank Account No.");
        StatementNo := Rec.GetFilter("Statement No.");
        Evaluate(StatementLineNo, Rec.GetFilter("Statement Line No."));

        GetBankAccReconciliationLine(StatementType, BankAccountNo, StatementNo, StatementLineNo, AccountType);

        if AppliesToEntryNo = 0 then begin // TextMapper
            BankPmtApplRule.Init();
            NoOfLedgerEntriesWithinAmountTolerance := 0;
            NoOfLedgerEntriesOutsideAmountTolerance := 0;
        end else begin
            case AccountType of
                Rec."Account Type"::Customer:
                    MatchBankPayments.MatchSingleLineCustomer(
                      BankPmtApplRule, BankAccReconciliationLine, AppliesToEntryNo,
                      NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance);
                Rec."Account Type"::Vendor:
                    MatchBankPayments.MatchSingleLineVendor(
                      BankPmtApplRule, BankAccReconciliationLine, AppliesToEntryNo,
                      NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance);
                Rec."Account Type"::Employee:
                    MatchBankPayments.MatchSingleLineEmployee(
                      BankPmtApplRule, BankAccReconciliationLine, AppliesToEntryNo,
                      NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance);
                Rec."Account Type"::"Bank Account":
                    MatchBankPayments.MatchSingleLineBankAccountLedgerEntry(
                      BankPmtApplRule, BankAccReconciliationLine, AppliesToEntryNo,
                      NoOfLedgerEntriesWithinAmountTolerance, NoOfLedgerEntriesOutsideAmountTolerance);
                else
                    Error(AccTypeErr);
            end;

            Evaluate(Quality, Rec.GetFilter(Quality));
            BankPmtApplRule.SetRange(Score, Quality);
            if not BankPmtApplRule.FindFirst() then
                BankPmtApplRule."Match Confidence" := BankPmtApplRule."Match Confidence"::None;
        end;

        RecRef.GetTable(BankAccReconciliationLine);
        MatchConfidenceFieldRef := RecRef.Field(BankAccReconciliationLine.FieldNo("Match Confidence"));
        BankAccReconciliationLine."Match Confidence" :=
            Enum::"Bank Rec. Match Confidence".FromInteger(TypeHelper.GetOptionNo(Rec.GetFilter("Match Confidence"), MatchConfidenceFieldRef.OptionCaption()));

        AmountMatchText := Format(BankPmtApplRule."Amount Incl. Tolerance Matched");
    end;

    local procedure GetBankAccReconciliationLine(StatementType: Option; BankAccountNo: Text; StatementNo: Text; StatementLineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
        BankAccReconciliationLine.Get(StatementType, BankAccountNo, StatementNo, StatementLineNo);
        BankAccReconciliationLine."Account Type" := AccountType;
        BankAccReconciliationLine."Account No." := CopyStr(Rec.GetFilter("Account No."), 1);
    end;
}

