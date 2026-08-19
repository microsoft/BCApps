// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

codeunit 10976 "FR E-Invoice Lifecycle Worker"
{
    Access = Internal;
    InherentEntitlements = X;
    TableNo = "FR E-Invoice Lifecycle";

    trigger OnRun()
    var
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        Rec.TestField("Processing Status", Rec."Processing Status"::Queued);
        if Rec."E-Document Message Entry No." = 0 then begin
            FREInvoiceLifecycleMgt.CreateLifecycleMessage(Rec);
            Commit();
        end;
        FREInvoiceLifecycleMgt.SendLifecycleMessage(Rec);
    end;
}