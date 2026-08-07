// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.Foundation.PaymentTerms;

codeunit 13438 "Create Payment Terms FI"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Payment Terms", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertPaymentTerms(var Rec: Record "Payment Terms")
    var
        CreatePaymentTerms: Codeunit "Create Payment Terms";
    begin
        case Rec.Code of
            CreatePaymentTerms.PaymentTermsM8D():
                ValidateRecordFields(Rec, true);
        end;
    end;

#if CLEAN29
#pragma warning disable AA0137 // PaymentTerms and DisregPmtDiscatFullPmt are only consumed by pre-CLEAN29 code below
#endif
    local procedure ValidateRecordFields(var PaymentTerms: Record "Payment Terms"; DisregPmtDiscatFullPmt: Boolean)
    begin
#if CLEAN29
#pragma warning restore AA0137
#endif
#if not CLEAN29
#pragma warning disable AL0432
        PaymentTerms.Validate("Disreg. Pmt. Disc. at Full Pmt", DisregPmtDiscatFullPmt);
#pragma warning restore AL0432
#endif
    end;
}
