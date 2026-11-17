// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.Foundation.PaymentTerms;
using System.Environment.Configuration;

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

    local procedure ValidateRecordFields(var PaymentTerms: Record "Payment Terms"; DisregPmtDiscatFullPmt: Boolean)
#if not CLEAN30
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN30
        if not FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI') then begin
#pragma warning disable AL0432
            PaymentTerms.Validate("Disreg. Pmt. Disc. at Full Pmt", DisregPmtDiscatFullPmt);
#pragma warning restore AL0432
            exit;
        end;
#endif
        PaymentTerms.Validate("Disreg. Full Payment Discount", DisregPmtDiscatFullPmt);
    end;
}
