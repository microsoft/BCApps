// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Service.Document;

reportextension 6485 "Serv. Suggest Worksheet Lines" extends "Suggest Worksheet Lines"
{
    dataset
    {
        addafter("Sales Line")
        {
            dataitem("Service Line"; "Service Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, ServiceOrderTxt);
                    Window.Update(3, "Document No.");

                    ServiceHeader.Get("Document Type", "Document No.");
                    if ServiceHeader."Bill-to Customer No." <> '' then
                        Customer.Get(ServiceHeader."Bill-to Customer No.")
                    else
                        Customer.Init();

                    InsertCFLineForServiceLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addafter("ConsiderSource[SourceType::""Sales Order""]")
            {
#pragma warning disable AA0100
                field("ConsiderSource[SourceType::""Service Orders""]"; ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()])
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    ToolTip = 'Specifies if you want to include service orders in the cash flow forecast.';
                }
            }
        }

        trigger OnOpenPage()
        begin
            if ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := "Service Line".ReadPermission;
        end;
    }

    var
        ServiceOrderTxt: Label 'Service Orders';
        ServiceDocumentDescriptionTxt: Label 'Service %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Customer Name). Example: Service Invoice - 04-05-18 The Cannon Group PLC';

    protected var
        ServiceHeader: Record "Service Header";

    local procedure InsertCFLineForServiceLine()
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2 := "Service Line";
        if Summarized and (ServiceLine2.Next() <> 0) and (ServiceLine2."Customer No." <> '') and
           (ServiceLine2."Document No." = "Service Line"."Document No.")
        then begin
            TotalAmt += CalculateLineAmountForServiceLine("Service Line");

            MultiSalesLines := true;
        end else begin
            CFWorksheetLine2.Init();
            CFWorksheetLine2."Source Type" := CFWorksheetLine2."Source Type"::"Service Orders";
            CFWorksheetLine2."Source No." := "Service Line"."Document No.";
            CFWorksheetLine2."Source Line No." := "Service Line"."Line No.";
            CFWorksheetLine2."Document Type" := CFWorksheetLine2."Document Type"::Invoice;
            CFWorksheetLine2."Document Date" := ServiceHeader."Document Date";
            CFWorksheetLine2."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
            CFWorksheetLine2."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
            CFWorksheetLine2."Dimension Set ID" := ServiceHeader."Dimension Set ID";
            CFWorksheetLine2."Cash Flow Account No." := CFSetup."Service CF Account No.";
            CFWorksheetLine2.Description :=
              CopyStr(
                StrSubstNo(
                  ServiceDocumentDescriptionTxt,
                  ServiceHeader."Document Type",
                  ServiceHeader.Name,
                  Format(ServiceHeader."Order Date")),
                1, MaxStrLen(CFWorksheetLine2.Description));
            SetCashFlowDate(CFWorksheetLine2, ServiceHeader."Due Date");
            CFWorksheetLine2."Document No." := "Service Line"."Document No.";
            CFWorksheetLine2."Amount (LCY)" := CalculateLineAmountForServiceLine("Service Line");

            if Summarized and MultiSalesLines then begin
                CFWorksheetLine2."Amount (LCY)" := CFWorksheetLine2."Amount (LCY)" + TotalAmt;
                MultiSalesLines := false;
                TotalAmt := 0;
            end;

            if "Cash Flow Forecast"."Consider CF Payment Terms" and (Customer."Cash Flow Payment Terms Code" <> '') then
                CFWorksheetLine2."Payment Terms Code" := Customer."Cash Flow Payment Terms Code"
            else
                CFWorksheetLine2."Payment Terms Code" := ServiceHeader."Payment Terms Code";

            OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine(CFWorksheetLine2, "Cash Flow Forecast", "Service Line");
            InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure CalculateLineAmountForServiceLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(GetServiceAmountForCFLine(ServiceLine));
    end;

    local procedure GetServiceAmountForCFLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(ServiceLine."Outstanding Amount (LCY)" + ServiceLine."Shipped Not Invoiced (LCY)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowForecast: Record "Cash Flow Forecast"; ServiceLine: Record "Service Line")
    begin
    end;
}