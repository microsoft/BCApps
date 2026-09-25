// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Finance.CashDesk;

codeunit 148132 "Cash Doc Line Test Handler CZZ"
{
    EventSubscriberInstance = Manual;

    var
        ValidateAdvanceLetterNoEventRaised: Boolean;
        LookupAdvanceLetterNoEventRaised: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"Cash Document Line CZP", 'OnBeforeValidateAdvanceLetterNoCZZ', '', false, false)]
    local procedure HandleOnBeforeValidateAdvanceLetterNoCZZ(var CashDocumentLineCZP: Record "Cash Document Line CZP"; var IsHandled: Boolean)
    begin
        ValidateAdvanceLetterNoEventRaised := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cash Document Line CZP", 'OnBeforeLookupAdvanceLetterNoCZZ', '', false, false)]
    local procedure HandleOnBeforeLookupAdvanceLetterNoCZZ(var CashDocumentLineCZP: Record "Cash Document Line CZP"; var IsHandled: Boolean)
    begin
        LookupAdvanceLetterNoEventRaised := true;
        IsHandled := true;
    end;

    procedure GetValidateAdvanceLetterNoEventRaised(): Boolean
    begin
        exit(ValidateAdvanceLetterNoEventRaised);
    end;

    procedure GetLookupAdvanceLetterNoEventRaised(): Boolean
    begin
        exit(LookupAdvanceLetterNoEventRaised);
    end;
}