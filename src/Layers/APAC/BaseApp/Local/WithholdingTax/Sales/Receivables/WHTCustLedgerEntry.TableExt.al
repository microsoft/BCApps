// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.Receivables;

tableextension 28028 WHTCustLedgerEntry extends "Cust. Ledger Entry"
{
    fields
    {
        field(28040; "Rem. Amt for WHT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Rem. Amt for WHT';
            DataClassification = CustomerContent;
        }
        field(28042; "WHT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("WHT Entry".Amount where("Bill-to/Pay-to No." = field("Customer No."),
                                                        "Transaction No." = field("Transaction No.")));
            Caption = 'WHT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28043; "WHT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry"."Amount (LCY)" where("Bill-to/Pay-to No." = field("Customer No."),
                                                                "Transaction No." = field("Transaction No.")));
            Caption = 'WHT Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28044; "WHT Payment"; Boolean)
        {
            Caption = 'WHT Payment';
            DataClassification = CustomerContent;
        }
    }
}
