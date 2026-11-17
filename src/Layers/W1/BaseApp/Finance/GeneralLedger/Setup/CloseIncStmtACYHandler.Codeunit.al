// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

/// <summary>
/// Makes the Close Income Statement report post the closed additional reporting currency amount
/// instead of recalculating it from the LCY amount at the closing date exchange rate.
/// </summary>
codeunit 117 "Close Inc. Stmt. ACY Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        ClosingAmountLCY: Decimal;
        ClosingAmountACY: Decimal;

    procedure SetAmounts(AmountLCY: Decimal; AmountACY: Decimal)
    begin
        ClosingAmountLCY := AmountLCY;
        ClosingAmountACY := AmountACY;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnGLCalcAddCurrencyPostingNone', '', false, false)]
    local procedure UseClosedACYAmount(var GenJnlLine: Record "Gen. Journal Line"; Amount: Decimal; AddCurrency: Record Currency; var Result: Decimal; var IsHandled: Boolean)
    begin
        if IsHandled or (ClosingAmountLCY = 0) then
            exit;

        // The balancing retained earnings entry is posted with the negated amount
        case Amount of
            ClosingAmountLCY:
                Result := ClosingAmountACY;
            -ClosingAmountLCY:
                Result := -ClosingAmountACY;
            else
                exit;
        end;
        IsHandled := true;
    end;
}
