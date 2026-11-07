// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Finance.VAT.Registration;

/// <summary>
/// Skips the duplicate VAT registration number check for customers, including the customer lookup and its message.
/// Bind it while creating test customers, whose VAT registration number is not relevant for the test.
/// </summary>
codeunit 148503 "E-Doc. DE VAT Reg. No. Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"VAT Registration No. Format", OnBeforeCheckCust, '', false, false)]
    local procedure SkipCheckCust(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
