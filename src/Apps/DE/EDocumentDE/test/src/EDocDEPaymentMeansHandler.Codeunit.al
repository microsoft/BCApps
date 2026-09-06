// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

/// <summary>
/// Stands in for an extension that supports a payment means code this app does not build data for.
/// Bind it to verify that OnBeforeCheckPaymentMeansCodeSupported lets such a code pass the check.
/// </summary>
codeunit 13927 "E-Doc. DE Paym. Means Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DE Payment Means Helper", OnBeforeCheckPaymentMeansCodeSupported, '', false, false)]
    local procedure HandlePaymentMeansCodeSupported(PaymentMeansCode: Code[3]; SourceDocumentHeader: RecordRef; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
