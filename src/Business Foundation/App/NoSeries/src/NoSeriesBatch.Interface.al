// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

interface "No. Series - Batch"
{
    procedure SetInitialState(TempNoSeriesLine: Record "No. Series Line" temporary);

    procedure GetNoSeriesLine(var TempNoSeriesLine: Record "No. Series Line" temporary; NoSeries: Record "No. Series"; UsageDate: Date)

    procedure PeekNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date): Code[20];

    procedure GetNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; LastDateUsed: Date): Code[20];

    procedure GetLastNoUsed(var TempNoSeriesLine: Record "No. Series Line" temporary): Code[20] // would be better to not have here

    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary);

    procedure SaveState();
}
