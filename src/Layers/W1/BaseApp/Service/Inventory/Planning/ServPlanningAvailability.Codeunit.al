#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Service.Document;

codeunit 6497 "Serv. Planning Availability"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The referenced report "Planning Availability" has been deprecated and will be removed in a future release.';
    ObsoleteTag = '27.0';

    [EventSubscriber(ObjectType::Report, Report::Microsoft.Manufacturing.Reports."Planning Availability", 'OnCollectData', '', false, false)]
    local procedure OnCollectData(var TempPlanningBuffer: Record "Planning Buffer" temporary; Selection: Boolean; var sender: Report Microsoft.Manufacturing.Reports."Planning Availability")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", "Service Document Type"::Order);
        ServiceLine.SetRange(Type, "Service Line Type"::Item);
        if ServiceLine.FindSet() then
            repeat
                if Selection then begin
                    sender.NewRecordWithDetails(ServiceLine."Needed by Date", ServiceLine."No.", ServiceLine.Description);
                    TempPlanningBuffer."Document Type" := TempPlanningBuffer."Document Type"::"Service Order";
                    TempPlanningBuffer."Document No." := ServiceLine."Document No.";
                    TempPlanningBuffer."Gross Requirement" := ServiceLine."Outstanding Qty. (Base)";
                    TempPlanningBuffer.Insert();
                end else begin
                    TempPlanningBuffer.SetRange("Item No.", ServiceLine."No.");
                    TempPlanningBuffer.SetRange(Date, ServiceLine."Needed by Date");
                    if TempPlanningBuffer.Find('-') then begin
                        TempPlanningBuffer."Gross Requirement" := TempPlanningBuffer."Gross Requirement" + ServiceLine."Outstanding Qty. (Base)";
                        TempPlanningBuffer.Modify();
                    end else begin
                        sender.NewRecordWithDetails(ServiceLine."Posting Date", ServiceLine."No.", ServiceLine.Description);
                        TempPlanningBuffer."Gross Requirement" := ServiceLine."Outstanding Qty. (Base)";
                        TempPlanningBuffer.Insert();
                    end;
                end;
            until ServiceLine.Next() = 0;
    end;
}
#endif