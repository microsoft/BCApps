// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 305 "No. Series - Setup Impl."
{
    Access = Internal;


    [EventSubscriber(ObjectType::Table, Database::"No. Series", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnDeleteNoSeries(var Rec: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
#pragma warning restore AL0432
#endif
    begin
        if Rec.IsTemporary() then
            exit;

        NoSeriesLine.SetRange("Series Code", Rec.Code);
        NoSeriesLine.DeleteAll();

#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesLineSales.SetRange("Series Code", Rec.Code);
        NoSeriesLineSales.DeleteAll();

        NoSeriesLinePurchase.SetRange("Series Code", Rec.Code);
        NoSeriesLinePurchase.DeleteAll();
#pragma warning restore AL0432
#endif

        NoSeriesRelationship.SetRange(Code, Rec.Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange(Code);

        NoSeriesRelationship.SetRange("Series Code", Rec.Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange("Series Code");
    end;
}