// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

tableextension 28007 WHTPurchCrMemoHdr extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "Rem. WHT Prepaid Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry"."Remaining Unrealized Amount" where("Document Type" = const("Credit Memo"),
                                                                               "Document No." = field("No.")));
            Caption = 'Rem. WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28042; "Paid WHT Prepaid Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry".Amount where("Document Type" = const(Refund),
                                                        "Document No." = field("No.")));
            Caption = 'Paid WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28043; "Total WHT Prepaid Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry"."Unrealized Amount" where("Document Type" = const("Credit Memo"),
                                                                     "Document No." = field("No.")));
            Caption = 'Total WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28045; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
            TableRelation = Vendor;
        }
    }
}
