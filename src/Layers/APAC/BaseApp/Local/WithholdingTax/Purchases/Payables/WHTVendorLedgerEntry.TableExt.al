// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Payables;

tableextension 28029 WHTVendorLedgerEntry extends "Vendor Ledger Entry"
{
    fields
    {
        field(28040; "Rem. Amt for WHT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Rem. Amt for WHT';
            DataClassification = CustomerContent;
        }
        field(28042; "WHT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("WHT Entry".Amount where("Bill-to/Pay-to No." = field("Vendor No."),
                                                        "Original Document No." = field("Document No.")));
            Caption = 'WHT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28043; "WHT Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("WHT Entry"."Amount (LCY)" where("Bill-to/Pay-to No." = field("Vendor No."),
                                                                "Original Document No." = field("Document No.")));
            Caption = 'WHT Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
