// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 305 "No. Series - Setup Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure SetImplementation(var NoSeries: Record "No. Series"; Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.SetRange(Open, true);
        NoSeriesLine.ModifyAll(Implementation, Implementation, true);
    end;
}