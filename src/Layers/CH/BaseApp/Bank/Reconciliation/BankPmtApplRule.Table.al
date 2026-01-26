// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using System.Text;

/// <summary>
/// Defines rules and criteria for automatic bank payment application with configurable matching thresholds.
/// This table contains scoring logic that determines when bank statement lines should be automatically
/// applied to customer, vendor, or other ledger entries based on various matching criteria including
/// amounts, document numbers, related party information, and tolerance settings. Each rule defines
/// a specific combination of matching conditions with associated confidence levels and automation settings.
/// </summary>
/// <remarks>
/// Key features include configurable match confidence levels, priority-based rule ordering, scoring algorithms,
/// automatic vs. manual application thresholds, and review requirements. Rules enable fine-tuning of automatic
/// matching behavior to balance automation efficiency with accuracy requirements. Integration with tolerance
/// settings, payment discounts, and multi-criteria matching provides comprehensive payment application logic.
/// Supports customization for different business scenarios and risk tolerance levels.
/// </remarks>
table 1252 "Bank Pmt. Appl. Rule"
{
    Caption = 'Bank Pmt. Appl. Rule';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Overall confidence level for this payment application rule.
        /// Determines the quality threshold and automation behavior for matches meeting this rule's criteria.
        /// </summary>
        field(1; "Match Confidence"; Option)
        {
            Caption = 'Match Confidence';
            OptionCaption = 'None,Low,Medium,High';
            OptionMembers = "None",Low,Medium,High;
        }
        /// <summary>
        /// Priority order for evaluating this rule within its confidence level.
        /// Lower numbers indicate higher priority and are evaluated first during matching processes.
        /// </summary>
        field(2; Priority; Integer)
        {
            Caption = 'Priority';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePriority(Rec, IsHandled);
                if IsHandled then
                    exit;

                if (Priority > GetMaximumPriorityNo()) or (Priority < 1) then
                    Error(WrongPriorityNoErr, FieldCaption(Priority), 1, GetMaximumPriorityNo());
            end;
        }
        /// <summary>
        /// Criteria for related party (customer/vendor) name matching requirements.
        /// Specifies whether and how closely party names must match for this rule to apply.
        /// </summary>
        field(3; "Related Party Matched"; Option)
        {
            Caption = 'Related Party Matched';
            OptionCaption = 'Not Considered,Fully,Partially,No';
            OptionMembers = "Not Considered",Fully,Partially,No;
        }
        /// <summary>
        /// Criteria for document number or external document number matching requirements.
        /// Determines the document reference matching conditions necessary for this rule.
        /// </summary>
        field(4; "Doc. No./Ext. Doc. No. Matched"; Option)
        {
            Caption = 'Doc. No./Ext. Doc. No. Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
        }
        /// <summary>
        /// Criteria for amount matching including payment tolerance considerations.
        /// Specifies requirements for transaction amount alignment with ledger entries.
        /// </summary>
        field(5; "Amount Incl. Tolerance Matched"; Option)
        {
            Caption = 'Amount Incl. Tolerance Matched';
            OptionCaption = 'Not Considered,One Match,Multiple Matches,No Matches';
            OptionMembers = "Not Considered","One Match","Multiple Matches","No Matches";
        }
        /// <summary>
        /// Criteria for direct debit collection matching in payment processing.
        /// Used for automatic matching of direct debit transactions with collection entries.
        /// </summary>
        field(6; "Direct Debit Collect. Matched"; Option)
        {
            Caption = 'Direct Debit Collect. Matched';
            OptionCaption = 'Not Considered,Yes,No';
            OptionMembers = "Not Considered",Yes,No;
        }
        /// <summary>
        /// Calculated scoring value for this rule based on its matching criteria combination.
        /// Used internally for rule evaluation and matching quality assessment.
        /// </summary>
        field(30; Score; Integer)
        {
            Caption = 'Score';
            Editable = false;
        }

        /// <summary>
        /// Indicates whether matches using this rule require manual review before application.
        /// When enabled, automatic application is disabled and user confirmation is required.
        /// </summary>
        field(40; "Review Required"; Boolean)
        {
            Caption = 'Review Required';
        }

        /// <summary>
        /// Enables immediate automatic application of payments matching this rule.
        /// When enabled, qualified matches are applied without user intervention or confirmation.
        /// </summary>
        field(41; "Apply Immediatelly"; Boolean)
        {
            Caption = 'Apply Immediatelly';
        }
    }

    keys
    {
        key(Key1; "Match Confidence", Priority)
        {
            Clustered = true;
        }
        key(Key2; Score)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Validate(Priority);
        UpdateScore(Rec);
    end;

    trigger OnRename()
    begin
        UpdateScore(Rec);
    end;

    var
        WrongPriorityNoErr: Label 'The %1 you entered is invalid. The %1 must be between %2 and %3.', Comment = '%1 - Table field with caption Priority. %2 and %3 are numbers presenting a range - e.g. 1 and 999';
        LoadRulesOnlyOnTempRecordsErr: Label 'Programming error: The LoadRules function can only be called from temporary records.', Comment = 'Description to developers, should not be seen by users';

    /// <summary>
    /// Loads all payment application rules into the current temporary record.
    /// Used for efficient processing of multiple rules during payment matching operations.
    /// Must be called on temporary table instances for performance optimization.
    /// </summary>
    procedure LoadRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if not IsTemporary then
            Error(LoadRulesOnlyOnTempRecordsErr);

        DeleteAll();
        if BankPmtApplRule.FindSet() then
            repeat
                TransferFields(BankPmtApplRule);
                Insert();
            until BankPmtApplRule.Next() = 0;
    end;

    /// <summary>
    /// Determines the best matching score for given payment application criteria.
    /// Evaluates all applicable rules based on the provided matching parameters and returns
    /// the highest score achievable, enabling optimal rule selection for payment matching.
    /// </summary>
    /// <param name="ParameterBankPmtApplRule">Payment application rule containing matching criteria to evaluate.</param>
    /// <returns>The highest matching score available for the specified criteria combination.</returns>
    procedure GetBestMatchScore(ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule"): Integer
    begin
        Clear(Rec);
        SetCurrentKey(Score);
        Ascending(false);

        SetFilter("Related Party Matched", '%1|%2',
          ParameterBankPmtApplRule."Related Party Matched",
          ParameterBankPmtApplRule."Related Party Matched"::"Not Considered");

        SetFilter("Doc. No./Ext. Doc. No. Matched", '%1|%2',
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched",
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");

        SetFilter("Amount Incl. Tolerance Matched", '%1|%2',
          ParameterBankPmtApplRule."Amount Incl. Tolerance Matched",
          ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");

        SetFilter("Direct Debit Collect. Matched", '%1|%2',
          ParameterBankPmtApplRule."Direct Debit Collect. Matched",
          ParameterBankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

        OnGetBestMatchScoreOnAfterSetFilters(Rec, ParameterBankPmtApplRule);

        if FindFirst() then
            exit(Score);

        exit(0);
    end;

    procedure GetReviewRequiredScoreFilter(): Text
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        BankPmtRecordRef: RecordRef;
    begin
        BankPmtApplRule.SetRange("Review Required", true);
        BankPmtApplRule.SetCurrentKey(Score);
        BankPmtRecordRef.GetTable(BankPmtApplRule);
        exit(SelectionFilterManagement.GetSelectionFilter(BankPmtRecordRef, BankPmtApplRule.FieldNo(Score)));
    end;

    procedure IsMatchedAutomatically(MatchConfidence: Option; NoOfAppliedEntries: Integer): Boolean
    begin
        if (NoOfAppliedEntries = 0) then
            exit(false);

        exit(MatchConfidence in ["Match Confidence"::None, "Match Confidence"::Low, "Match Confidence"::Medium, "Match Confidence"::High]);
    end;

    procedure GetTextMapperScore(): Integer
    var
        MediumConfidenceHighestScore: Integer;
    begin
        // Text mapper should override only Medium confidence and lower. It's base, lowest score is 3000, whereas the max for medium is 2999
        MediumConfidenceHighestScore := CalculateScore("Match Confidence"::Medium, 0);
        exit(MediumConfidenceHighestScore);
    end;

    procedure GetMaxTextMapperScore(): Integer
    begin
        // 3499
        exit(GetTextMapperScore() + (GetConfidenceScoreRange() div 2) - 1)
    end;

    internal procedure GetTextMapperScore(SubstringLength: Integer; ExactMatch: Boolean): Integer
    var
        TextMapperScore: Integer;
    begin
        // add the length of longest common substring to differentiate between multiple string nearness matches
        TextMapperScore := GetTextMapperScore() + SubstringLength;

        // give precedence to exact match and increase its score by 1
        if ExactMatch then
            TextMapperScore += 1;

        exit(TextMapperScore)
    end;

    local procedure UpdateScore(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
        BankPmtApplRule.Score := CalculateScore(BankPmtApplRule."Match Confidence", BankPmtApplRule.Priority);
    end;

    local procedure CalculateScore(MatchConfidence: Option; NewPriority: Integer): Integer
    var
        ConfidenceRangeScore: Integer;
    begin
        ConfidenceRangeScore := (MatchConfidence + 1) * GetConfidenceScoreRange();

        // Update the score based on priority
        exit(ConfidenceRangeScore - NewPriority);
    end;

    local procedure GetConfidenceScoreRange(): Integer
    begin
        exit(1000);
    end;

    local procedure GetMaximumPriorityNo(): Integer
    begin
        exit(GetConfidenceScoreRange() - 1);
    end;

    procedure GetMatchConfidence(MatchQuality: Integer): Integer
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        OptionNo: Integer;
    begin
        // we make sure that the range for Text Mapper scores is 3000-3499
        if (MatchQuality >= GetTextMapperScore()) and (MatchQuality <= GetMaxTextMapperScore()) then
            exit(BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping".AsInteger());

        OptionNo := MatchQuality div GetConfidenceScoreRange();
        case OptionNo of
            "Match Confidence"::None:
                exit(BankAccReconciliationLine."Match Confidence"::None.AsInteger());
            "Match Confidence"::Low:
                exit(BankAccReconciliationLine."Match Confidence"::Low.AsInteger());
            "Match Confidence"::Medium:
                exit(BankAccReconciliationLine."Match Confidence"::Medium.AsInteger());
            "Match Confidence"::High:
                exit(BankAccReconciliationLine."Match Confidence"::High.AsInteger());
        end;
    end;

    procedure GetLowestScoreInRange(AssignedScore: Integer): Integer
    begin
        // we make sure that the range for High confidence matches is 3500-3999
        if AssignedScore div GetConfidenceScoreRange() = Enum::"Bank Rec. Match Confidence"::High.AsInteger() then
            exit(GetMaxTextMapperScore() + 1);
        exit((AssignedScore div GetConfidenceScoreRange()) * GetConfidenceScoreRange());
    end;

    procedure GetHighestScoreInRange(AssignedScore: Integer): Integer
    begin
        exit(GetLowestScoreInRange(AssignedScore) + GetConfidenceScoreRange());
    end;

    procedure GetHighestPossibleScore(): Integer
    begin
        exit(GetConfidenceScoreRange() * ("Match Confidence"::High + 1));
    end;

    procedure InsertDefaultMatchingRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        RulePriority: Integer;
    begin
        if not BankPmtApplRule.IsEmpty() then
            exit;

        // Insert High Confidence rules
        RulePriority := 1;
        OnInsertDefaultMatchingRulesBeforeInsertHighConfidenceRules(Rec, RulePriority);
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes,
          true);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          true);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          true);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          true);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        // Insert Medium Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        // Insert Low Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);
    end;

    local procedure InsertBankPaymentApplicationRule(MatchConfidence: Option; var RulePriority: Integer; RelatedPartyIdentification: Option; DocumentMatch: Option; AmountMatch: Option; DirectDebitCollectionMatch: Option; ApplyAutomatically: Boolean)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.Init();
        BankPmtApplRule."Match Confidence" := MatchConfidence;
        BankPmtApplRule.Priority := RulePriority;
        BankPmtApplRule."Related Party Matched" := RelatedPartyIdentification;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocumentMatch;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountMatch;
        BankPmtApplRule."Direct Debit Collect. Matched" := DirectDebitCollectionMatch;
        BankPmtApplRule."Apply Immediatelly" := ApplyAutomatically;

        if BankPmtApplRule."Match Confidence" in [BankPmtApplRule."Match Confidence"::None, BankPmtApplRule."Match Confidence"::Low, BankPmtApplRule."Match Confidence"::Medium] then
            BankPmtApplRule."Review Required" := true;

        BankPmtApplRule.Insert(true);
        RulePriority += 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePriority(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDefaultMatchingRulesBeforeInsertHighConfidenceRules(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; var RulePriority: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBestMatchScoreOnAfterSetFilters(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
    end;
}

