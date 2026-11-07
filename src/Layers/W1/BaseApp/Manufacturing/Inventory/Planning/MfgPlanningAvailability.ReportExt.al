#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;

reportextension 99001048 "Mfg. Planning Availability" extends "Planning Availability"
{
    dataset
    {
        addafter("Transfer Line")
        {
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if not (Status in [Status::Simulated, Status::Finished]) then begin
                        ReqLine2.SetRange("Ref. Order Status", Status);
                        ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                        ReqLine2.SetRange("Ref. Line No.", "Line No.");
                        if ReqLine2.FindFirst() then
                            CurrReport.Skip();

                        if SelectionReq then begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Purchase Order";
                            TempPlanningBuffer."Document No." := "Prod. Order No.";
                            case Status of
                                Status::"Firm Planned":
                                    begin
                                        TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Firm Planned Prod. Order";
                                        TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                    end;
                                Status::Released:
                                    begin
                                        TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Released Prod. Order";
                                        TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                    end;
                                Status::Planned:
                                    begin
                                        TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Planned Prod. Order";
                                        TempPlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)";
                                    end;
                            end;
                            TempPlanningBuffer.Insert();
                        end else begin
                            TempPlanningBuffer.SetRange("Item No.", "Item No.");
                            TempPlanningBuffer.SetRange(Date, "Due Date");
                            if TempPlanningBuffer.Find('-') then begin
                                if Status = Status::Planned then
                                    TempPlanningBuffer."Planned Receipts" :=
                                    TempPlanningBuffer."Planned Receipts" +
                                    "Remaining Qty. (Base)"
                                else
                                    TempPlanningBuffer."Scheduled Receipts" :=
                                    TempPlanningBuffer."Scheduled Receipts" +
                                    "Remaining Qty. (Base)";
                                TempPlanningBuffer.Modify();
                            end else begin
                                NewRecordWithDetails("Due Date", "Item No.", Description);
                                if Status = Status::Planned then
                                    TempPlanningBuffer."Planned Receipts" := "Remaining Qty. (Base)"
                                else
                                    TempPlanningBuffer."Scheduled Receipts" := "Remaining Qty. (Base)";
                                TempPlanningBuffer.Insert();
                            end;
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    ReqLine2.Reset();
                    ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
                    ReqLine2.SetRange("Ref. Order Type", ReqLine2."Ref. Order Type"::"Prod. Order");
                end;
            }
        }
        addafter("Requisition Line")
        {
            dataitem("Prod. Order Component"; "Prod. Order Component")
            {
                DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if not (Status in [Status::Simulated, Status::Finished]) then begin
                        ReqLine2.SetRange("Ref. Order Status", Status);
                        ReqLine2.SetRange("Ref. Order No.", "Prod. Order No.");
                        ReqLine2.SetRange("Ref. Line No.", "Prod. Order Line No.");
                        if ReqLine2.FindFirst() then
                            CurrReport.Skip();

                        if SelectionReq then begin
                            NewRecordWithDetails("Due Date", "Item No.", Description);
                            TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Purchase Order";
                            TempPlanningBuffer."Document No." := "Prod. Order No.";
                            TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                            case Status of
                                Status::"Firm Planned":
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Firm Planned Prod. Order Comp.";
                                Status::Released:
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Released Prod. Order Comp.";
                                Status::Planned:
                                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Planned Prod. Order Comp.";
                            end;
                            TempPlanningBuffer.Insert();
                        end else begin
                            TempPlanningBuffer.SetRange("Item No.", "Item No.");
                            TempPlanningBuffer.SetRange(Date, "Due Date");
                            if TempPlanningBuffer.Find('-') then begin
                                TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + "Remaining Qty. (Base)";
                                TempPlanningBuffer.Modify();
                            end else begin
                                NewRecordWithDetails("Due Date", "Item No.", Description);
                                TempPlanningBuffer."Gross Requirement" := "Remaining Qty. (Base)";
                                TempPlanningBuffer.Insert();
                            end;
                        end;
                    end;
                    ModifyForecast("Item No.", "Due Date", TempPlanningBuffer."Document Type"::"Production Forecast-Component", "Remaining Qty. (Base)");
                end;

                trigger OnPreDataItem()
                begin
                    ReqLine2.Reset();
                    ReqLine2.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
                    ReqLine2.SetRange("Ref. Order Type", ReqLine2."Ref. Order Type"::"Prod. Order");
                end;
            }
        }
    }
}
#endif