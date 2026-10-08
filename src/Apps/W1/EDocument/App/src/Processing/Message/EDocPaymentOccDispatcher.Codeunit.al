// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

codeunit 6248 "E-Doc. Payment Occ. Dispatcher"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "E-Doc. Payment Occurrence" = rm;

    trigger OnRun()
    var
        ProcessedCount: Integer;
    begin
        ProcessStatus("E-Doc. Payment Occ. Status"::Processing, ProcessedCount, MaxExpiredProcessingOccurrencesPerRun());
        ProcessStatus("E-Doc. Payment Occ. Status"::"Retry Pending", ProcessedCount, ProcessedCount + MaxRetryOccurrencesPerRun());
        ProcessStatus("E-Doc. Payment Occ. Status"::Pending, ProcessedCount, MaxOccurrencesPerRun());
        ProcessStatus("E-Doc. Payment Occ. Status"::Processing, ProcessedCount, MaxOccurrencesPerRun());
        ProcessStatus("E-Doc. Payment Occ. Status"::"Retry Pending", ProcessedCount, MaxOccurrencesPerRun());
    end;

    local procedure ProcessStatus(Status: Enum "E-Doc. Payment Occ. Status"; var ProcessedCount: Integer; MaxProcessedCount: Integer)
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
        EntryNo: Integer;
    begin
        if ProcessedCount >= MaxProcessedCount then
            exit;

        EDocPaymentOccurrence.SetCurrentKey(Status, "Next Attempt At");
        EDocPaymentOccurrence.SetRange(Status, Status);
        EDocPaymentOccurrence.SetFilter("Next Attempt At", '%1|<=%2', 0DT, CurrentDateTime());
        while (ProcessedCount < MaxProcessedCount) and EDocPaymentOccurrence.FindFirst() do begin
            EntryNo := EDocPaymentOccurrence."Entry No.";
            Commit();
            if EDocPaymentOccurrence.Get(EntryNo) then begin
                EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);
                ProcessedCount += 1;
            end;
            EDocPaymentOccurrence.Reset();
            EDocPaymentOccurrence.SetCurrentKey(Status, "Next Attempt At");
            EDocPaymentOccurrence.SetRange(Status, Status);
            EDocPaymentOccurrence.SetFilter("Next Attempt At", '%1|<=%2', 0DT, CurrentDateTime());
        end;
    end;

    local procedure MaxOccurrencesPerRun(): Integer
    begin
        exit(100);
    end;

    local procedure MaxExpiredProcessingOccurrencesPerRun(): Integer
    begin
        exit(10);
    end;

    local procedure MaxRetryOccurrencesPerRun(): Integer
    begin
        exit(20);
    end;
}