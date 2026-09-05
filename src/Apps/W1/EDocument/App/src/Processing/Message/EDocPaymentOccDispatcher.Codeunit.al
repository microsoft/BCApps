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
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
        EntryNo: Integer;
    begin
        EDocPaymentOccurrence.SetFilter(Status, '%1|%2|%3', EDocPaymentOccurrence.Status::Pending, EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status::Processing);
        EDocPaymentOccurrence.SetFilter("Next Attempt At", '%1|<=%2', 0DT, CurrentDateTime());
        while EDocPaymentOccurrence.FindFirst() do begin
            EntryNo := EDocPaymentOccurrence."Entry No.";
            Commit();
            if EDocPaymentOccurrence.Get(EntryNo) then
                EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);
            EDocPaymentOccurrence.SetFilter(Status, '%1|%2|%3', EDocPaymentOccurrence.Status::Pending, EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status::Processing);
            EDocPaymentOccurrence.SetFilter("Next Attempt At", '%1|<=%2', 0DT, CurrentDateTime());
        end;
    end;
}