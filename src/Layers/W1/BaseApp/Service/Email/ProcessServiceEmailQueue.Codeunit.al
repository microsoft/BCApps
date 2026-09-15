// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Email;
using System.Threading;

codeunit 5917 "Process Service Email Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ServEmailQueue: Record "Service Email Queue";
        ServEmailQueue2: Record "Service Email Queue";
        ServMailMgt: Codeunit ServMailManagement;
        RecRef: RecordRef;
        Success: Boolean;
    begin
        if RecRef.Get(Rec."Record ID to Process") then begin
            RecRef.SetTable(ServEmailQueue);
            if not ServEmailQueue.Find() then
                exit;
            ServEmailQueue.SetRecFilter();
        end else begin
            ServEmailQueue.Reset();
            ServEmailQueue.SetCurrentKey(Status, "Sending Date", "Document Type", "Document No.");
            ServEmailQueue.SetRange(Status, ServEmailQueue.Status::" ");
        end;
        ServEmailQueue.LockTable();
        if ServEmailQueue.FindSet() then
            repeat
                Commit();
                Clear(ServMailMgt);
                Success := ServMailMgt.Run(ServEmailQueue);
                ServEmailQueue2.Get(ServEmailQueue."Entry No.");
                if Success then
                    ServEmailQueue2.Status := ServEmailQueue2.Status::Processed
                else
                    ServEmailQueue2.Status := ServEmailQueue2.Status::Error;
                ServEmailQueue2.Modify();
                Sleep(200);
            until ServEmailQueue.Next() = 0;
    end;
}

