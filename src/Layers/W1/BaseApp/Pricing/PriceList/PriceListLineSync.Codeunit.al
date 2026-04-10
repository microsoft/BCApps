// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using System.Threading;

codeunit 4114 "Price List Line Sync"
{
    Access = Internal;

    trigger OnRun()
    var
        PriceListLine: Record "Price List Line";
        i: Integer;
    begin
        ApplyFilter(PriceListLine);
        if PriceListLine.FindSet() then
            repeat
                PriceListLine.SyncDropDownLookupFields();
                PriceListLine.Modify();
                i += 1;
                // Commit often to limit locking + ensuring job will eventually finish (in case of very large table) .
                if i = 1000 then begin
                    i := 0;
                    Commit();
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure IsPriceListLineSynchronized(): Boolean
    var
        PriceListLine: Record "Price List Line";
    begin
        ApplyFilter(PriceListLine);
        exit(PriceListLine.IsEmpty());
    end;

    procedure StartSync(Notification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Price List Line Sync");

        if JobQueueEntry.FindFirst() then begin
            if JobQueueEntry.Status <> JobQueueEntry.Status::"In Process" then
                Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)
        end
        else begin
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := Codeunit::"Price List Line Sync";
            JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        end;
    end;

    procedure SendOutOfSyncNotification()
    var
        OutOfSyncNotification: Notification;
    begin
        OutOfSyncNotification.Id := OutOfSyncNotificationIdTxt;
        OutOfSyncNotification.Message := OutOfSyncNotificationMsg;
        OutOfSyncNotification.Scope := NOTIFICATIONSCOPE::LocalScope;

        if HasRequiredPermissions() then
            OutOfSyncNotification.AddAction(StartBackgroundSyncLbl, Codeunit::"Price List Line Sync", 'StartSync');

        OutOfSyncNotification.Send();
    end;

    local procedure ApplyFilter(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetRange("Product No.", '');
        PriceListLine.SetFilter("Asset No.", '<>''''');
    end;

    local procedure HasRequiredPermissions(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        JobQueueEntry: Record "Job Queue Entry";
        [SecurityFiltering(SecurityFilter::Ignored)]
        PriceListLine: Record "Price List Line";
    begin
        exit(JobQueueEntry.WritePermission() and JobQueueEntry.ReadPermission() and
            PriceListLine.WritePermission() and PriceListLine.ReadPermission());
    end;

    var
        OutOfSyncNotificationIdTxt: Label '97df7b9a-8063-4b8a-ba9f-efa316e2bb3d', Locked = true;
        OutOfSyncNotificationMsg: Label 'We have detected that price list lines exists, which are out of sync. We have disabled the new lookups to prevent issues.';
        StartBackgroundSyncLbl: Label 'Start background synchronization';
}