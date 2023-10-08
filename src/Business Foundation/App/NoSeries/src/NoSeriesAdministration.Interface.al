// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

interface "No. Series Administration"
{
    procedure ResetNoSeries(var NoSeries: Record "No. Series Line")

    procedure SetStartingNo(var NoSeries: Record "No. Series Line"; StartingNo: Code[20])

    // TODO: Make sure admin part of InitSeries is handled
}
