// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

codeunit 906 "SO Activities Calculate"
{
    Permissions = tabledata "Sales Cue" = r;

    var
        Results: Dictionary of [Text, Text];

    trigger OnRun()
    var
        Parameters: Dictionary of [Text, Text];
    begin
        Parameters := Page.GetBackgroundParameters();

        CalculateFieldValues(Parameters, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    procedure CalculateFieldValues(Parameters: Dictionary of [Text, Text]; var ReturnResults: Dictionary of [Text, Text])
    var
        SalesCue: Record "Sales Cue";
    begin
        if SalesCue.Get() then;
        SalesCue.SetView(Parameters.Get('View'));
        CalculateCueFieldValues(SalesCue);

        ReturnResults.Add(SalesCue.FieldName("Average Days Delayed"), Format(SalesCue."Average Days Delayed"));
        ReturnResults.Add(SalesCue.FieldName("Avg. Days Delayed Updated On"), Format(SalesCue."Avg. Days Delayed Updated On", 0, 9));
        ReturnResults.Add(SalesCue.FieldName("Ready to Ship"), Format(SalesCue."Ready to Ship"));
        ReturnResults.Add(SalesCue.FieldName("Partially Shipped"), Format(SalesCue."Partially Shipped"));
        ReturnResults.Add(SalesCue.FieldName(Delayed), Format(SalesCue.Delayed));
        ReturnResults.Add(SalesCue.FieldName("S. Ord. - Reserved From Stock"), Format(SalesCue."S. Ord. - Reserved From Stock"));
    end;

    procedure EvaluateResults(var ResultsDictionary: Dictionary of [Text, Text]; var SalesCue: Record "Sales Cue")
    var
        ResultValue: Text;
    begin
        if ResultsDictionary.Count() = 0 then
            exit;

        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName("Average Days Delayed"), ResultValue) then
            Evaluate(SalesCue."Average Days Delayed", ResultValue);
        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName("Avg. Days Delayed Updated On"), ResultValue) then
            Evaluate(SalesCue."Avg. Days Delayed Updated On", ResultValue, 9);
        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName("Ready to Ship"), ResultValue) then
            Evaluate(SalesCue."Ready to Ship", ResultValue);
        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName("Partially Shipped"), ResultValue) then
            Evaluate(SalesCue."Partially Shipped", ResultValue);
        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName(Delayed), ResultValue) then
            Evaluate(SalesCue.Delayed, ResultValue);
        if TryGetDictionaryValue(ResultsDictionary, SalesCue.FieldName("S. Ord. - Reserved From Stock"), ResultValue) then
            Evaluate(SalesCue."S. Ord. - Reserved From Stock", ResultValue);
    end;

    [TryFunction]
    local procedure TryGetDictionaryValue(var ResultsDictionary: Dictionary of [Text, Text]; DictionaryKey: Text; var ReturnValue: Text)
    begin
        ReturnValue := ResultsDictionary.Get(DictionaryKey);
    end;

    local procedure CalculateCueFieldValues(var SalesCue: Record "Sales Cue")
    begin
        if SalesCue."Avg. Days Delayed Updated On" < CurrentDateTime - 5 * 60000 then begin
            SalesCue."Average Days Delayed" := SalesCue.CalculateAverageDaysDelayed();
            SalesCue."Avg. Days Delayed Updated On" := CurrentDateTime();
        end;
        SalesCue."Ready to Ship" := SalesCue.CountOrders(SalesCue.FieldNo("Ready to Ship"));
        SalesCue."Partially Shipped" := SalesCue.CountOrders(SalesCue.FieldNo("Partially Shipped"));
        SalesCue.Delayed := SalesCue.CountOrders(SalesCue.FieldNo(Delayed));
        SalesCue."S. Ord. - Reserved From Stock" := SalesCue.CalcNoOfReservedFromStockSalesOrders();
    end;
}
