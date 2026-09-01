// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Worksheet;

report 7306 "Get Inbound Source Documents"
{
    Caption = 'Get Inbound Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Whse. Put-away Request"; "Whse. Put-away Request")
        {
            DataItemTableView = where("Completely Put Away" = const(false));
            RequestFilterFields = "Document Type", "Document No.";
            dataitem("Posted Whse. Receipt Header"; "Posted Whse. Receipt Header")
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.");
                dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.", "Line No.");
                    CalcFields = "Put-away Qty.", "Put-away Qty. (Base)";

                    trigger OnPreDataItem()
                    begin
                        OnPostedWhseReceiptLineOnPreDataItem("Posted Whse. Receipt Line");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        OnBeforeWhsePutAwayRequestOnAfterGetRecord("Posted Whse. Receipt Line");
                        if "Qty. (Base)" > "Qty. Put Away (Base)" + "Put-away Qty. (Base)" then
                            if WhseWkshCreate.FromWhseRcptLine(
                                 WhseWkshTemplateName, WhseWkshName, LocationCode, "Posted Whse. Receipt Line")
                            then
                                LineCreated := true;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Put-away Request"."Document Type" <> "Whse. Put-away Request"."Document Type"::Receipt then
                        CurrReport.Break();
                end;
            }
            dataitem("Whse. Internal Put-away Header"; "Whse. Internal Put-away Header")
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.");
                dataitem("Whse. Internal Put-away Line"; "Whse. Internal Put-away Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.", "Line No.");
                    CalcFields = "Put-away Qty.", "Put-away Qty. (Base)";

                    trigger OnAfterGetRecord()
                    begin
                        if "Qty. (Base)" > "Qty. Put Away (Base)" + "Put-away Qty. (Base)" then
                            if WhseWkshCreate.FromWhseInternalPutawayLine(
                                 WhseWkshTemplateName, WhseWkshName, LocationCode, "Whse. Internal Put-away Line")
                            then
                                LineCreated := true;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Put-away Request"."Document Type" <> "Whse. Put-away Request"."Document Type"::"Internal Put-away" then
                        CurrReport.Break();
                end;
            }
        }
    }

    trigger OnPostReport()
    begin
        if not HideDialog then
            if not LineCreated then
                Error(NoLinesCreatedErr);
    end;

    trigger OnPreReport()
    begin
        LineCreated := false;
    end;

    var
        WhseWkshCreate: Codeunit "Whse. Worksheet-Create";
        NoLinesCreatedErr: Label 'There are no Warehouse Worksheet Lines created.';

    protected var
        WhseWkshTemplateName: Code[10];
        WhseWkshName: Code[10];
        LocationCode: Code[10];
        LineCreated: Boolean;
        HideDialog: Boolean;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetWhseWkshName(WhseWkshTemplateName2: Code[10]; WhseWkshName2: Code[10]; LocationCode2: Code[10])
    begin
        WhseWkshTemplateName := WhseWkshTemplateName2;
        WhseWkshName := WhseWkshName2;
        LocationCode := LocationCode2;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeWhsePutAwayRequestOnAfterGetRecord(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostedWhseReceiptLineOnPreDataItem(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line");
    begin
    end;
}

