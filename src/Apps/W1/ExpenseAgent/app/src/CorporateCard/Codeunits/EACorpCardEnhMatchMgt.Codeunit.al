// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Enhanced matching for corporate card transactions.
/// Provides receipt-based matching, fuzzy merchant matching, and match scoring.
/// </summary>
codeunit 7216 "EA Corp Card Enh. Match Mgt"
{
    Access = Internal;

    var
        MediumScoreThreshold: Decimal;

    /// <summary>
    /// Enhanced transaction matching with multiple strategies.
    /// Tries receipt-based first, then fuzzy merchant matching.
    /// </summary>
    internal procedure EnhancedMatchTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]): Boolean
    var
        MatchScore: Decimal;
    begin
        // Initialize thresholds
        MediumScoreThreshold := 0.70; // 70% similarity for medium confidence

        // Strategy 1: Exact match by amount, date, user (highest priority)
        if ExactAmountDateMatch(CorpCardTrans, ExpenseNo, MatchScore) then begin
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Full;
            CorpCardTrans."Match Score" := MatchScore;
            exit(true);
        end;

        // Strategy 2: Fuzzy merchant name matching (medium priority)
        if FuzzyMerchantMatch(CorpCardTrans, ExpenseNo, MatchScore) then begin
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Expense;
            CorpCardTrans."Match Score" := MatchScore;
            exit(true);
        end;

        // Strategy 3: Employee-only match (lowest priority, requires manual review)
        if EmployeeOnlyMatch(CorpCardTrans, ExpenseNo) then begin
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Employee;
            CorpCardTrans."Match Score" := 50; // Manual review needed
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Exact match on amount, date within window, and expense user.
    /// Returns match score 90-100 based on exactness.
    /// </summary>
    local procedure ExactAmountDateMatch(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]; var MatchScore: Decimal): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        DateDiff: Integer;
        AmountDiff: Decimal;
        MaxDateDiff: Integer;
        MaxAmountDiff: Decimal;
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            exit(false);

        if not ExpenseAgentSetup.Get() then
            exit(false);

        MaxDateDiff := ExpenseAgentSetup."Corp Card Date Match Window";
        MaxAmountDiff := ExpenseAgentSetup."Corp Card Amount Tolerance";

        Expense.SetRange("Expense User No.", CorpCard."Expense User No.");
        Expense.SetRange("Status", Expense."Status"::Open);
        Expense.SetRange("Currency Code", CorpCardTrans."Currency Code");
        Expense.SetFilter("Expense Date", '%1..%2', CorpCardTrans."Trans Date" - MaxDateDiff, CorpCardTrans."Trans Date" + MaxDateDiff);
        Expense.SetFilter("Amount", '%1..%2', CorpCardTrans.Amount - MaxAmountDiff, CorpCardTrans.Amount + MaxAmountDiff);

        if Expense.FindFirst() then begin
            DateDiff := Abs(DaysBetween(CorpCardTrans."Trans Date", Expense."Expense Date"));
            AmountDiff := Abs(CorpCardTrans.Amount - Expense.Amount);

            // Calculate score: Perfect match = 100, decreased by date/amount variance
            MatchScore := 100 - (DateDiff * 5) - ((AmountDiff / MaxAmountDiff) * 10);
            if MatchScore < 50 then
                MatchScore := 50;

            ExpenseNo := Expense."No.";
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Fuzzy merchant name matching using string similarity.
    /// Returns true if similarity >= MediumScoreThreshold.
    /// </summary>
    local procedure FuzzyMerchantMatch(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]; var MatchScore: Decimal): Boolean
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        SimilarityScore: Decimal;
        BestScore: Decimal;
        BestExpenseNo: Code[20];
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            exit(false);

        Expense.SetRange("Expense User No.", CorpCard."Expense User No.");
        Expense.SetRange("Status", Expense."Status"::Open);

        if not Expense.FindSet() then
            exit(false);

        BestScore := 0;
        repeat
            SimilarityScore := CalculateSimilarity(CorpCardTrans."Merchant Norm", Expense."Merchant Name");
            if SimilarityScore > BestScore then begin
                BestScore := SimilarityScore;
                BestExpenseNo := Expense."No.";
            end;
        until Expense.Next() = 0;

        if BestScore >= MediumScoreThreshold then begin
            MatchScore := BestScore * 100; // Convert to 0-100 scale
            ExpenseNo := BestExpenseNo;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Employee-only match: matches to any Open expense for same user.
    /// Requires manual review by user before posting.
    /// </summary>
    local procedure EmployeeOnlyMatch(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]): Boolean
    var
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            exit(false);

        Expense.SetRange("Expense User No.", CorpCard."Expense User No.");
        Expense.SetRange("Status", Expense."Status"::Open);

        if Expense.FindFirst() then begin
            ExpenseNo := Expense."No.";
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Calculates string similarity using Levenshtein distance.
    /// Returns value between 0.0 and 1.0 where 1.0 = exact match.
    /// </summary>
    local procedure CalculateSimilarity(Text1: Text; Text2: Text): Decimal
    var
        Len1: Integer;
        Len2: Integer;
        MaxLen: Integer;
        Distance: Integer;
    begin
        Text1 := LowerCase(Text1);
        Text2 := LowerCase(Text2);
        Len1 := StrLen(Text1);
        Len2 := StrLen(Text2);

        if (Len1 = 0) or (Len2 = 0) then
            exit(0);

        Distance := LevenshteinDistance(Text1, Text2);
        MaxLen := Max(Len1, Len2);

        exit(1 - (Distance / MaxLen));
    end;

    /// <summary>
    /// Computes Levenshtein distance between two strings.
    /// Distance of 0 = exact match, higher = more different.
    /// </summary>
    local procedure LevenshteinDistance(Text1: Text; Text2: Text): Integer
    var
        Len1: Integer;
        Len2: Integer;
        i: Integer;
        j: Integer;
        Cost: Integer;
        Matrix: array[101, 101] of Integer;
    begin
        Len1 := StrLen(Text1);
        Len2 := StrLen(Text2);

        // Edge cases
        if Len1 = 0 then
            exit(Len2);
        if Len2 = 0 then
            exit(Len1);

        // Limit to prevent array overflow
        if Len1 > 100 then
            Len1 := 100;
        if Len2 > 100 then
            Len2 := 100;

        // Use a 1-based matrix where row/column 1 represents distance against empty string.
        for i := 1 to Len1 + 1 do
            Matrix[i, 1] := i - 1;
        for j := 1 to Len2 + 1 do
            Matrix[1, j] := j - 1;

        // Compute distance
        for i := 2 to Len1 + 1 do
            for j := 2 to Len2 + 1 do begin
                if Text1[i - 1] = Text2[j - 1] then
                    Cost := 0
                else
                    Cost := 1;
                Matrix[i, j] := Min(Min(Matrix[i - 1, j] + 1, Matrix[i, j - 1] + 1), Matrix[i - 1, j - 1] + Cost);
            end;

        exit(Matrix[Len1 + 1, Len2 + 1]);
    end;

    local procedure DaysBetween(Date1: Date; Date2: Date): Integer
    begin
        if Date1 > Date2 then
            exit((Date1 - Date2) / 1);
        exit((Date2 - Date1) / 1);
    end;

    local procedure Min(Value1: Integer; Value2: Integer): Integer
    begin
        if Value1 < Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure Max(Value1: Integer; Value2: Integer): Integer
    begin
        if Value1 > Value2 then
            exit(Value1);
        exit(Value2);
    end;
}
