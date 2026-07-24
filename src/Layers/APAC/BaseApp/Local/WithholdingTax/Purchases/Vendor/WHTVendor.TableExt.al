// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;

tableextension 28013 WHTVendor extends Vendor
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";

            trigger OnValidate()
            begin
                if (ABN <> '') or ("ABN Division Part No." <> '') then
                    Error(MustBeBlankErr, FieldCaption(ABN));
            end;
        }
        field(28041; "WHT Payable Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("WHT Entry"."Rem Unrealized Amount (LCY)" where("Bill-to/Pay-to No." = field("No."),
                                                                               "Transaction Type" = const(Purchase)));
            Caption = 'WHT Payable Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28042; "WHT Registration ID"; Text[20])
        {
            Caption = 'WHT Registration ID';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        modify(ABN)
        {
            trigger OnAfterValidate()
            begin
                if "WHT Business Posting Group" <> '' then
                    Error(MustBeBlankErr, FieldCaption("WHT Business Posting Group"));
            end;
        }
        modify("ABN Division Part No.")
        {
            trigger OnAfterValidate()
            begin
                if "WHT Business Posting Group" <> '' then
                    Error(MustBeBlankErr, FieldCaption("WHT Business Posting Group"));
            end;
        }
    }

    var
        MustBeBlankErr: Label 'The field %1 must be blank.', Comment = '%1 - Field Caption';
}
