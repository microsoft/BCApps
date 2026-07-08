// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

tableextension 28001 WHTGenJournalLine extends "Gen. Journal Line"
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "WHT Product Posting Group"; Code[20])
        {
            Caption = 'WHT Product Posting Group';
            TableRelation = "WHT Product Posting Group";
        }
        field(28042; "WHT Absorb Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'WHT Absorb Base';
        }
        field(28043; "WHT Entry No."; Integer)
        {
            Caption = 'WHT Entry No.';
        }
        field(28044; "WHT Report Line No."; Code[20])
        {
            Caption = 'WHT Report Line No.';
        }
        field(28045; "Skip WHT"; Boolean)
        {
            Caption = 'Skip WHT';
        }
        field(28046; "Certificate Printed"; Boolean)
        {
            Caption = 'Certificate Printed';
        }
        field(28047; "WHT Payment"; Boolean)
        {
            Caption = 'WHT Payment';

            trigger OnValidate()
            begin
                ReadGLSetup();
                if not GLSetup."Manual Sales WHT Calc." then
                    "WHT Payment" := false;
            end;
        }
        field(28048; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
            TableRelation = Vendor;
        }
        field(28049; "Is WHT"; Boolean)
        {
            Caption = 'Is WHT';
        }
    }
}
