// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

codeunit 148134 "Cash Doc. Release Handler CZP"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Document-Release CZP", 'OnBeforeCheckMandatoryFieldsSkipAmounts', '', false, false)]
    local procedure SetSkipAmountsTestFieldsOnBeforeCheckMandatoryFieldsSkipAmounts(CashDocumentHeaderCZP: Record "Cash Document Header CZP"; var SkipAmountsTestFields: Boolean)
    begin
        SkipAmountsTestFields := true;
    end;
}
