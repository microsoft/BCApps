// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Tests.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.WithholdingTax.Employee;

codeunit 148324 "WHT Empl. Group Test Subscr."
{
    EventSubscriberInstance = Manual;

    var
        GroupCodeToResolve: Code[20];

    procedure SetWHTGroupCode(NewWHTGroupCode: Code[20])
    begin
        GroupCodeToResolve := NewWHTGroupCode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeResolveWHTGroupComponents, '', false, false)]
    local procedure OnBeforeResolveWHTGroupComponents(GenJnlLine: Record "Gen. Journal Line"; var WHTGroupCode: Code[20]; var Result: Boolean)
    begin
        WHTGroupCode := GroupCodeToResolve;
        Result := true;
    end;
}
