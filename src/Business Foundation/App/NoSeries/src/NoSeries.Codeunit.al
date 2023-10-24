// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 303 "No. Series"
{
    Access = Public;

    /// <summary>
    /// Get the next number in the number series.
    /// This function will select the proper No. Series line and use the appropriate implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the number series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesCode, UsageDate, false));
    end;

    /// <summary>
    /// Get the next number in the number series.
    /// This function will select the proper No. Series line and use the appropriate implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the number series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings"></param>
    /// <returns>The next number in the series, if HideErrorsAndWarnings is true and errors occured, a blank code is returned.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20] // TODO: This should return true/false of whether we could get the next no., not a blank code.
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetNextNo(NoSeriesCode, UsageDate, HideErrorsAndWarnings));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20] // TODO: Return boolean whether a number could actually be retrieved or not? Don't rely on whether the code is blank or not
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.PeekNextNo(NoSeriesCode, UsageDate));
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20] // TODO: Return boolean whether a number could actually be retrieved or not? Don't rely on whether the code is blank or not
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.PeekNextNo(NoSeries, UsageDate));
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetLastNoUsed(NoSeriesLine));
    end;

    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.GetLastNoUsed(NoSeriesCode));
    end;

    /// <summary>
    /// Verifies that the number series is set to manual.
    /// This function allows manual numbers for blank No. Series Codes.
    /// </summary>
    /// <param name="NoSeriesCode"></param>
    procedure TestManual(NoSeriesCode: Code[20]) // TODO: Make this a try function, such that partners can handle cases where the no. series is not set to manual
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestManual(NoSeriesCode);
    end;

    procedure IsAutomaticNoSeries(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.IsAutomaticNoSeries(NoSeriesCode));
    end;

    procedure TestAreNoSeriesRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20])
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestAreNoSeriesRelated(DefaultNoSeriesCode, RelatedNoSeriesCode);
    end;

    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20]) // TODO: Make this a try function, such that partners can handle cases where the no. series is not set to manual
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.TestManual(NoSeriesCode, DocumentNo);
    end;

    procedure AreNoSeriesRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Boolean // This is basically what InitSeries does, it then uses the other series if they are and gets a number
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.AreNoSeriesRelated(DefaultNoSeriesCode, RelatedNoSeriesCode));
    end;

    /// <summary>
    /// Selects a number series related to the OriginalNoSeriesCode (includes the OriginalNoSeriesCode).
    /// </summary>
    /// <param name="OriginalNoSeriesCode">The number series code to find related number series for.</param>
    /// <param name="DefaultHighlightedNoSeriesCode">The number series code to highlight by default. If empty, the OriginalNoSeriesCode will be used.</param>
    /// <param name="NewNoSeriesCode">The selected number series code.</param>
    /// <returns>True if a number series was selected, false otherwise.</returns>
    procedure SelectRelatedNoSeries(OriginalNoSeriesCode: Code[20]; DefaultHighlightedNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        exit(NoSeriesImpl.SelectRelatedNoSeries(OriginalNoSeriesCode, DefaultHighlightedNoSeriesCode, NewNoSeriesCode));
    end;

    // Implement?: FindNoSeriesLine, IsCurrentNoSeriesLine, ReverseGetNextNo(apac), 
}
