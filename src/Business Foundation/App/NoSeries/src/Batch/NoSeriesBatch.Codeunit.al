// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides an interface for interacting with number series.
/// This codeunit batches requests until SaveState() is called. For more direct database interactions, see codeunit "No. Series".
/// </summary>
codeunit 308 "No. Series - Batch"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NoSeriesBatchImpl: Codeunit "No. Series - Batch Impl."; // Required to keep state

    #region GetNextNo
    /// <summary>
    /// Get the next number in the No. Series.
    /// This function finds the first valid No. Series line based on WorkDate and calls the No. Series Line implementation to get the next number.
    /// Defaults UsageDate to WorkDate.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, WorkDate(), false));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, UsageDate, false));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <remark>The caller is responsible for providing an up to date Line.</remark>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The last date used, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesLine, UsageDate, false));
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
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, UsageDate, HideErrorsAndWarnings));
    end;

    /// <summary>
    /// Get the next number in the No. Series.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to get the next number.
    /// </summary>
    /// <remark>The caller is responsible for providing an up to date Line.</remark>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="HideErrorsAndWarnings">Whether errors should be ignored.</param>
    /// <returns>The next number in the series, if HideErrorsAndWarnings is true and errors occur, a blank code is returned.</returns>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesLine, UsageDate, HideErrorsAndWarnings));
    end;
    #endregion

    #region PeekNextNo
    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function finds the first valid No. Series line based on WorkDate and calls the No. Series Line implementation to peek the next number.
    /// Defaults UsageDate to WorkDate.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode));
    end;

    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function finds the first valid No. Series line based on UsageDate and calls the No. Series Line implementation to peek the next number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode, UsageDate));
    end;

    /// <summary>
    /// Get the next number in the No. Series, without incrementing the number.
    /// This function uses the specified No. Series line and calls the No. Series Line implementation to peek the next number.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <returns>The next number in the series.</returns>
    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesLine, UsageDate));
    end;
    #endregion
    /// <summary>
    /// Get the last number used in the No. Series.
    /// </summary>
    /// <remark>If a line was just closed, this function will return an empty string. Please use the NoSeriesLine overload to get the Last number for closed lines.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <returns>The last number used in the series.</returns>
    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetLastNoUsed(NoSeriesCode));
    end;

    /// <summary>
    /// Get the last number used in the No. Series.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series line to use.</param>
    /// <returns>The last number used in the series.</returns>
    procedure GetLastNoUsed(var NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetLastNoUsed(NoSeriesLine));
    end;

    /// <summary>
    /// Verifies that the No. Series allows using manual numbers.
    /// </summary>
    /// <remark>This function allows manual numbers for blank No. Series Codes.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.TestManual(NoSeriesCode);
    end;

    /// <summary>
    /// Verifies that the No. Series allows using manual numbers and throws an error for the document no. if it does not.
    /// </summary>
    /// <remark>This function allows manual numbers for blank No. Series Codes.</remark>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="DocumentNo">Document No. to be shown in the error message.</param>
    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20])
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.TestManual(NoSeriesCode, DocumentNo);
    end;

    /// <summary>
    /// Simulate the specified No. Series at the specified date starting with the indicated number.
    /// </summary>
    /// <param name="NoSeriesCode">Code for the No. Series.</param>
    /// <param name="UsageDate">The date of retrieval, this will influence which line is used.</param>
    /// <param name="LastNoUsed">Simulate this is the last number used.</param>
    /// <returns></returns>
    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; LastNoUsed: Code[20]): Code[20]
    var
        NoSeriesBatchImplSim: Codeunit "No. Series - Batch Impl.";
    begin
        exit(NoSeriesBatchImplSim.SimulateGetNextNo(NoSeriesCode, UsageDate, LastNoUsed));
    end;

    /// <summary>
    /// Puts the codeunit in simulation mode which disables the ability to save state.
    /// </summary>
    procedure SetSimulationMode()
    begin
        NoSeriesBatchImpl.SetSimulationMode();
    end;

    /// <summary>
    /// Save the state of the No. Series Line to the database.
    /// </summary>
    /// <param name="TempNoSeriesLine">No. Series Line we want to save state for.</param>
    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary);
    begin
        NoSeriesBatchImpl.SaveState(TempNoSeriesLine);
    end;

    /// <summary>
    /// Save all changes to the database.
    /// </summary>
    procedure SaveState();
    begin
        NoSeriesBatchImpl.SaveState();
    end;
}
