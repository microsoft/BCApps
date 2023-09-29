// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 4143 "No. Series Check"
{
    TableNo = "No. Series";

    trigger OnRun()
    var
        StatelessNoSeriesManagement: Codeunit StatelessNoSeriesManagement;
    begin
        StatelessNoSeriesManagement.DoGetNextNo(Rec.Code, WorkDate(), false, false);
    end;
}