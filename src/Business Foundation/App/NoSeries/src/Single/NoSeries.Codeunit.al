// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides an interface for interacting with No. Series.
/// This codeunit actively uses the database to perform the operations (it does not batch requests). For further performance and batching, look at codeunit "No. Series Batch".
/// </summary>
codeunit 310 "No. Series"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region GetNextNo
    /// <summary>
    /// Get the next number in the No. Series.
    /// This function finds the first valid No. Series line based on WorkDate and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesCode, WorkDate(), false));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesCode, UsageDate, false));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesLine, UsageDate, false));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings">Whether errors should be ignored.</param>
    /// <returns>The next number in the series, if HideErrorsAndWarnings is true and errors occur, a blank code is returned.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesCode, UsageDate, HideErrorsAndWarnings));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings">Whether errors should be ignored.</param>
    /// <returns>The next number in the series, if HideErrorsAndWarnings is true and errors occur, a blank code is returned.</returns>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesLine, UsageDate, HideErrorsAndWarnings));
    end;
    #endregion

    #region PeekNextNo
    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to peek the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.PeekNextNo(NoSeriesCode, WorkDate()));
    end;

    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to peek the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.PeekNextNo(NoSeriesCode, UsageDate));
    end;

    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to peek the next number.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.PeekNextNo(NoSeriesLine, UsageDate));
    end;
    #endregion

    #region GetLastNoUsed
    /// <summary>
    /// Get the last number used in the No. Series.
    /// </summary>
    /// <remark>If a line was just closed, this function will return an empty string. Please use the NoSeriesLine overload to get the Last number for closed lines.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The last number used in the series.</returns>
    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetLastNoUsed(NoSeriesCode));
    end;

    /// <summary>
    /// Get the last number used in the No. Series.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <returns>The last number used in the series.</returns>
    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetLastNoUsed(NoSeriesLine));
    end;
    #endregion

    #region NoSeriesUsage
    /// <summary>
    /// Verifies that the No. Series allows using manual numbers.
    /// </summary>
    /// <remark>This function allows manual numbers for blank No. Series Codes.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestManual(NoSeriesCode);
    end;

    /// <summary>
    /// Verifies that the No. Series allows using manual numbers and throws an error for the document no. if it does not.
    /// </summary>
    /// <remark>This function allows manual numbers for blank No. Series Codes.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="DocumentNo">Document No. to be shown in the error message.</param>
    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20])
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestManual(NoSeriesCode, DocumentNo);
    end;

    /// <summary>
    /// Determines whether the No. Series allows using manual numbers.
    /// </summary>
    /// <remark>This function allows manual numbers for blank No. Series Codes.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>True if the No. Series allows manual numbers, false otherwise.</returns>
    procedure IsManual(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.IsManual(NoSeriesCode));
    end;

    /// <summary>
    /// Verifies that the No. Series is set up to automatically generate numbers.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    procedure TestAutomatic(NoSeriesCode: Code[20])
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestAutomatic(NoSeriesCode);
    end;

    /// <summary>
    /// Determines whether numbers should automatically be generated from the No. Series.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>True if the No. Series is automatic, false otherwise.</returns>
    procedure IsAutomatic(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.IsAutomatic(NoSeriesCode));
    end;
    #endregion

    #region NoSeriesRelations
    /// <summary>
    /// Returns true if the No. Series is related to one or more other No. Series.
    /// </summary>
    /// <param name="NoSeriesCode">The No. Series code to check</param>
    /// <returns>True if the No. Series is related to one or more other No. Series.</returns>
    procedure HasRelatedSeries(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.HasRelatedSeries(NoSeriesCode));
    end;

    /// <summary>
    /// Verifies that the two No. Series are related.
    /// </summary>
    /// <param name="DefaultNoSeriesCode">The primary No. Series code.</param>
    /// <param name="RelatedNoSeriesCode">The No. Series code that is related to the primary No. Series code.</param>
    procedure TestAreRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20])
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestAreRelated(DefaultNoSeriesCode, RelatedNoSeriesCode);
    end;

    /// <summary>
    /// Determines whether the two No. Series are related.
    /// </summary>
    /// <param name="DefaultNoSeriesCode">The primary No. Series code.</param>
    /// <param name="RelatedNoSeriesCode">The No. Series code that is related to the primary No. Series code.</param>
    /// <returns>True if the two No. Series are related, false otherwise.</returns>
    procedure AreRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.AreRelated(DefaultNoSeriesCode, RelatedNoSeriesCode));
    end;

    /// <summary>
    /// Opens a page to select a No. Series related to the OriginalNoSeriesCode (including the OriginalNoSeriesCode).
    /// </summary>
    /// <param name="OriginalNoSeriesCode">The No. Series code to find related No. Series for.</param>
    /// <param name="NewNoSeriesCode">The selected No. Series code.</param>
    /// <returns>True if a No. Series was selected, false otherwise.</returns>
    procedure LookupRelatedNoSeries(OriginalNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.LookupRelatedNoSeries(OriginalNoSeriesCode, OriginalNoSeriesCode, NewNoSeriesCode));
    end;

    /// <summary>
    /// Opens a page to select a No. Series related to the OriginalNoSeriesCode (including the OriginalNoSeriesCode).
    /// </summary>
    /// <param name="OriginalNoSeriesCode">The No. Series code to find related No. Series for.</param>
    /// <param name="DefaultHighlightedNoSeriesCode">The No. Series code to highlight by default. If empty, the OriginalNoSeriesCode will be used.</param>
    /// <param name="NewNoSeriesCode">The selected No. Series code.</param>
    /// <returns>True if a No. Series was selected, false otherwise.</returns>
    procedure LookupRelatedNoSeries(OriginalNoSeriesCode: Code[20]; DefaultHighlightedNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.LookupRelatedNoSeries(OriginalNoSeriesCode, DefaultHighlightedNoSeriesCode, NewNoSeriesCode));
    end;
    #endregion

    /// <summary>
    /// Drills down into the No Series Lines for the specified No. Series.
    /// </summary>
    /// <param name="NoSeries">The No. Series record to drill down on.</param>
    procedure DrillDown(NoSeries: Record "No. Series")
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        NoSeriesSetupImpl.DrillDown(NoSeries);
    end;

    /// <summary>
    /// Use this method to determine whether the specified No. Series line may produce gaps.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series Line to check.</param>
    /// <returns></returns>
    procedure MayProduceGaps(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        exit(NoSeriesSetupImpl.MayProduceGaps(NoSeriesLine));
    end;

    /// <summary>
    /// Get the No. Series line for the specified No. Series code and usage date.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use and return.</param>
    /// <param name="NoSeriesCode">The No. Series code to lookup.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings">Whether errors should be ignored.</param>
    /// <remarks>NoSeriesCode must not be empty.</remarks>
    /// <returns>True if the No. Series line was found, false otherwise.</returns>
    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNoSeriesLine(NoSeriesLine, NoSeriesCode, UsageDate, HideErrorsAndWarnings));
    end;

    /// <summary>
    /// Use this event to change the filters set on the No. Series Line record. These filters are used when viewing the No. Series page and when drilling down from a No. Series record.
    /// </summary>
    /// <param name="NoSeries">The No. Series record to drill down on.</param>
    /// <param name="NoSeriesLine">The No. Series Line to set filters on.</param>
    /// <param name="IsDrillDown">Specifies whether the filters are being set for a drill down.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterSetNoSeriesCurrentLineFilters(NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; IsDrillDown: Boolean);
    begin
    end;
}
