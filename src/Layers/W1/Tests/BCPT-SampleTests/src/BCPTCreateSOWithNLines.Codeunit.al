namespace System.Test.Tooling;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Tooling;

codeunit 149104 "BCPT Create SO with N Lines" implements "BCPT Test Param. Provider"
{
    SingleInstance = true;

    trigger OnRun();
    begin
        if not IsInitialized then begin
            InitTest();
            IsInitialized := true;
        end;
        CreateSalesOrder(GlobalBCPTTestContext);
    end;

    var
        GlobalBCPTTestContext: Codeunit "BCPT Test Context";
        IsInitialized: Boolean;
        NoOfLinesToCreate: Integer;
        NoOfLinesParamLbl: Label 'Lines';
        ParamValidationErr: Label 'Parameter is not defined in the correct format. The expected format is "%1"', Comment = '%1 = a string';

    local procedure InitTest();
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        RecordModified: Boolean;
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Order Nos.");
        NoSeriesLine.SetRange("Series Code", SalesSetup."Order Nos.");
        NoSeriesLine.FindSet(true);
        repeat
            if NoSeriesLine."Ending No." <> '' then begin
                NoSeriesLine."Ending No." := '';
                NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Sequence);
                NoSeriesLine.Modify(true);
                RecordModified := true;
            end;
        until NoSeriesLine.Next() = 0;

        if RecordModified then
            Commit();

        if Evaluate(NoOfLinesToCreate, GlobalBCPTTestContext.GetParameter(NoOfLinesParamLbl)) then;
    end;

    local procedure CreateSalesOrder(var BCPTTestContext: Codeunit "BCPT Test Context")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        if not Customer.get('10000') then
            Customer.FindFirst();
        if not item.get('70000') then
            Item.FindSet();
        if NoOfLinesToCreate < 0 then
            NoOfLinesToCreate := 0;
        if NoOfLinesToCreate > 10000 then
            NoOfLinesToCreate := 10000;
        BCPTTestContext.StartScenario('Add Order');
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        Commit();
        BCPTTestContext.EndScenario('Add Order');
        BCPTTestContext.UserWait();
        BCPTTestContext.StartScenario('Enter Account No.');
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);
        Commit();
        BCPTTestContext.EndScenario('Enter Account No.');
        BCPTTestContext.UserWait();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        for i := 1 to NoOfLinesToCreate do begin
            SalesLine."Line No." += 10000;
            SalesLine.Init();
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Insert(true);
            BCPTTestContext.UserWait();
            if i = 1 then
                BCPTTestContext.StartScenario('Enter Line Item No.');
            SalesLine.Validate("No.", Item."No.");
            if i = 1 then
                BCPTTestContext.EndScenario('Enter Line Item No.');
            BCPTTestContext.UserWait();
            if i = 1 then
                BCPTTestContext.StartScenario('Enter Line Quantity');
            SalesLine.Validate(Quantity, 1);
            SalesLine.Modify(true);
            if i = 1 then
                BCPTTestContext.EndScenario('Enter Line Quantity');
            BCPTTestContext.UserWait();
            if i mod 2 = 0 then
                if Item.Next() = 0 then
#pragma warning disable AA0181, AA0175
                    Item.FindSet();
#pragma warning restore AA0181, AA0175
        end;
    end;

    procedure GetDefaultParameters(): Text[1000]
    begin
        exit(copystr(NoOfLinesParamLbl + '=' + Format(10), 1, 1000));
    end;

    procedure ValidateParameters(Parameters: Text[1000])
    begin
        if StrPos(Parameters, NoOfLinesParamLbl) > 0 then begin
            Parameters := DelStr(Parameters, 1, StrLen(NoOfLinesParamLbl + '='));
            if Evaluate(NoOfLinesToCreate, Parameters) then
                exit;
        end;
        Error(ParamValidationErr, GetDefaultParameters());
    end;
}