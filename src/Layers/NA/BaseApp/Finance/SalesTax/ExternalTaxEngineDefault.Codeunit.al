// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 400 ExternalTaxEngineDefault implements "External Tax Engine"
{
    var
        NotImplementedErr: Label 'Invalid function call. External tax engine not implemented.';

    procedure CallExternalTaxEngineForDoc(DocTable: Integer; DocType: Option Quote,Order,Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]) STETransactionID: Text[20]
    begin
        Error(NotImplementedErr);
    end;

    procedure CallExternalTaxEngineForJnl(var GenJnlLine: Record "Gen. Journal Line"; CalculationType: Option Normal,Reverse,Expense): Decimal
    begin
        Error(NotImplementedErr);
    end;

    procedure FinalizeExternalTaxCalcForDoc(DocTable: Integer; DocNo: Code[20])
    begin
        Error(NotImplementedErr);
    end;

    procedure FinalizeExternalTaxCalcForJnl(var GLEntry: Record "G/L Entry")
    begin
        Error(NotImplementedErr);
    end;
}
