// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 12148 "No. Series IT"
{
    Access = Internal;

    var
        CantChangeNoSeriesLineTypeErr: Label '%1 must be deleted before changing the %2.', Comment = '%1 = Table caption %2 = No. Series Type';

    procedure ValidateNoSeriesType(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries."No. Series Type" = xRecNoSeries."No. Series Type" then
            exit;

        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        if not NoSeriesLine.IsEmpty() then
            Error(CantChangeNoSeriesLineTypeErr, NoSeriesLine.TableCaption(), NoSeries.FieldCaption("No. Series Type"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", OnBeforeValidateEvent, "Implementation", false, false)]
    local procedure DisableImplementationsWithGapsInNosOnBeforeValidate(var Rec: Record "No. Series Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        Rec.CalcFields("No. Series Type");
        if (Rec."No. Series Type" in [Rec."No. Series Type"::Sales, Rec."No. Series Type"::Purchase]) and NoSeries.MayProduceGaps(Rec) then
            Rec."Implementation" := Enum::"No. Series Implementation"::Normal;
    end;

}