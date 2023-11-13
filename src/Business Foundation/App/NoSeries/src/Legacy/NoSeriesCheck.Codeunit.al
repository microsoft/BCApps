// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 4143 "No. Series Check"
{
    Access = Public;
    TableNo = "No. Series";

    trigger OnRun()
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.PeekNextNo(Rec, WorkDate());
    end;
}