// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.Customer;

tableextension 28026 WHTCustomer extends Customer
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "WHT Payable Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry"."Rem Unrealized Amount (LCY)" where("Bill-to/Pay-to No." = field("No."),
                                                                               "Transaction Type" = const(Sale)));
            Caption = 'WHT Payable Amount (LCY)';
            FieldClass = FlowField;
        }
    }
}
