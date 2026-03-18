// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 1310 "O365 Activities Dictionary"
{
    var
        ActivitiesMgt: Codeunit "Activities Mgt.";

    trigger OnRun()
    var
        ActivitiesCue: Record "Activities Cue";
        Input: Text;
        Inputs: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Inputs := Page.GetBackgroundParameters();

        foreach Input in Inputs.Keys() do
            case Input of
                ActivitiesCue.FieldName("Sales This Month"):
                    Results.Add(ActivitiesCue.FieldName("Sales This Month"), Format(ActivitiesMgt.CalcSalesThisMonthAmount(false)));
                ActivitiesCue.FieldName("Overdue Sales Invoice Amount"):
                    Results.Add(ActivitiesCue.FieldName("Overdue Sales Invoice Amount"), Format(ActivitiesMgt.OverdueSalesInvoiceAmount(false, true)));
                ActivitiesCue.FieldName("Overdue Purch. Invoice Amount"):
                    Results.Add(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount"), Format(ActivitiesMgt.OverduePurchaseInvoiceAmount(false, true)));
                ActivitiesCue.FieldName("Average Collection Days"):
                    Results.Add(ActivitiesCue.FieldName("Average Collection Days"), Format(ActivitiesMgt.CalcAverageCollectionDays(true)));
                ActivitiesCue.FieldName("S. Ord. - Reserved From Stock"):
                    Results.Add(ActivitiesCue.FieldName("S. Ord. - Reserved From Stock"), Format(ActivitiesMgt.CalcNoOfReservedFromStockSalesOrders(true)));
            end;

        OnRunOnBeforeSetBackgroundTaskResult(Results, ActivitiesCue);

        Page.SetBackgroundTaskResult(Results);
    end;

    procedure FillActivitiesCue(DataList: Dictionary of [Text, Text]; var ActivitiesCue: record "Activities Cue")
    begin
        if DataList.ContainsKey(ActivitiesCue.FieldName("Sales This Month")) then
            Evaluate(ActivitiesCue."Sales This Month", DataList.Get(ActivitiesCue.FieldName("Sales This Month")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Overdue Sales Invoice Amount")) then
            Evaluate(ActivitiesCue."Overdue Sales Invoice Amount", DataList.Get(ActivitiesCue.FieldName("Overdue Sales Invoice Amount")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount")) then
            Evaluate(ActivitiesCue."Overdue Purch. Invoice Amount", DataList.Get(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Average Collection Days")) then
            Evaluate(ActivitiesCue."Average Collection Days", DataList.Get(ActivitiesCue.FieldName("Average Collection Days")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("S. Ord. - Reserved From Stock")) then
            Evaluate(ActivitiesCue."S. Ord. - Reserved From Stock", DataList.Get(ActivitiesCue.FieldName("S. Ord. - Reserved From Stock")));

        OnAfterFillActivitiesCue(DataList, ActivitiesCue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillActivitiesCue(DataList: Dictionary of [Text, Text]; var ActivitiesCue: record "Activities Cue")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSetBackgroundTaskResult(var Results: Dictionary of [Text, Text]; ActivitiesCue: Record "Activities Cue")
    begin
    end;
}
