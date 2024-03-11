// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides helper methods used in the setup of No. Series and No. Series lines.
/// </summary>
codeunit 299 "No. Series - Setup"
{
    Access = Public;

    /// <summary>
    /// Verifies the state of a line and returns whether or not the line is open and can be used to generate a new No.
    /// </summary>
    /// <param name="NoSeriesLine">the No. Series Line to verify.</param>
    /// <returns>Returns true if the line is open, false if the line is closed.</returns>
    procedure CalculateOpen(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        exit(NoSeriesSetupImpl.CalculateOpen(NoSeriesLine))
    end;

    /// <summary>
    /// Increments the given No. by the specified Increment.
    /// </summary>
    /// <param name="No">The number, as a code string to increment</param>
    /// <param name="Increment">Indicates by how much to increment the No.</param>
    /// <returns>The incremented No.</returns>
    procedure IncrementNoText(No: Code[20]; Increment: Integer): Code[20]
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        exit(NoSeriesSetupImpl.IncrementNoText(No, Increment));
    end;

    /// <summary>
    /// Updates the different No. fields in the No. Series Line based on the pattern provided in the NewNo parameter.
    /// </summary>
    /// <param name="NoSeriesLine">The No. Series Line to update.</param>
    /// <param name="NewNo">The new No. used as template to update the fields.</param>
    /// <param name="NewFieldName">The caption of the field the NewNo was entered in.</param>
    procedure UpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldCaption: Text[100])
    var
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        NoSeriesSetupImpl.UpdateNoSeriesLine(NoSeriesLine, NewNo, NewFieldCaption);
    end;
}
