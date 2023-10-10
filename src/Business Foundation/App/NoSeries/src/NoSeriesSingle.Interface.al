// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

interface "No. Series - Single"
{
    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]

    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    // procedure GetNextNo(var NoSeries: Record "No. Series"; SaveRecord: Boolean): Code[20]

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
}
