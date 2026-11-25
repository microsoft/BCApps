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

    var
        ExpectedPaymentMeansCode: Code[3];

    /// <summary>
    /// Sets the payment means code this handler accepts. Any other code is left to the standard check.
    /// </summary>
    /// <param name="PaymentMeansCode">The UNCL4461 payment means code to accept.</param>
    procedure SetExpectedPaymentMeansCode(PaymentMeansCode: Code[3])
    begin
        ExpectedPaymentMeansCode := PaymentMeansCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DE Payment Means Helper", OnBeforeCheckPaymentMeansCodeSupported, '', false, false)]
    local procedure HandlePaymentMeansCodeSupported(PaymentMeansCode: Code[3]; SourceDocumentHeader: RecordRef; var IsHandled: Boolean)
    begin
        if (ExpectedPaymentMeansCode = '') or (PaymentMeansCode <> ExpectedPaymentMeansCode) then
            exit;
        IsHandled := true;
    end;
}
