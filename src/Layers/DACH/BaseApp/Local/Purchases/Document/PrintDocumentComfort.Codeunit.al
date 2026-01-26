// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Reporting;

codeunit 5005396 "Print Document Comfort"
{

    trigger OnRun()
    begin
    end;

    procedure PrintDeliveryReminder(DeliveryReminderHeader: Record "Delivery Reminder Header")
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDeliveryReminder(DeliveryReminderHeader, IsHandled);
        if IsHandled then
            exit;

        DeliveryReminderHeader.SetRange("No.", DeliveryReminderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Delivery Reminder Test");
        ReportSelections.SetFilter("Report ID", '<>0');
        OnPrintDeliveryReminderOnAfterSetFilters(ReportSelections, DeliveryReminderHeader);
        ReportSelections.Find('-');
        repeat
            REPORT.RunModal(ReportSelections."Report ID", true, false, DeliveryReminderHeader)
        until ReportSelections.Next() = 0;
    end;


    procedure IssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        IssuedDeliveryReminderHeader.SetRange("No.", IssuedDeliveryReminderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Issued Delivery Reminder");
        ReportSelections.SetFilter("Report ID", '<>0');
        ReportSelections.Find('-');
        repeat
            REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, IssuedDeliveryReminderHeader)
        until ReportSelections.Next() = 0;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDeliveryReminder(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedDeliveryRemindPrint(var IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header"; var ShowRequestForm: Boolean; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnPrintDeliveryReminderOnAfterSetFilters(var ReportSelections: Record "Report Selections"; var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
    end;
}