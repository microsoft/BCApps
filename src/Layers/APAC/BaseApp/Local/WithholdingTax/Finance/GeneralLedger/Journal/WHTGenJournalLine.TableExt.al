// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;

tableextension 28001 WHTGenJournalLine extends "Gen. Journal Line"
{
    fields
    {
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "WHT Product Posting Group"; Code[20])
        {
            Caption = 'WHT Product Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Product Posting Group";
        }
        field(28042; "WHT Absorb Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'WHT Absorb Base';
            DataClassification = CustomerContent;
        }
        field(28043; "WHT Entry No."; Integer)
        {
            Caption = 'WHT Entry No.';
            DataClassification = CustomerContent;
        }
        field(28044; "WHT Report Line No."; Code[20])
        {
            Caption = 'WHT Report Line No.';
            DataClassification = CustomerContent;
        }
        field(28045; "Skip WHT"; Boolean)
        {
            Caption = 'Skip WHT';
            DataClassification = CustomerContent;
        }
        field(28046; "Certificate Printed"; Boolean)
        {
            Caption = 'Certificate Printed';
            DataClassification = CustomerContent;
        }
        field(28047; "WHT Payment"; Boolean)
        {
            Caption = 'WHT Payment';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                GLSetup.Get();
                if not GLSetup."Manual Sales WHT Calc." then
                    "WHT Payment" := false;
            end;
        }
        field(28048; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(28049; "Is WHT"; Boolean)
        {
            Caption = 'Is WHT';
            DataClassification = CustomerContent;
        }
    }

    trigger OnDelete()
    var
        TempWHTEntry: Record "Temp WHT Entry";
    begin
        TempWHTEntry.SetRange("Document Type", "Document Type");
        TempWHTEntry.SetRange("Original Document No.", "Document No.");
        if not TempWHTEntry.IsEmpty() then
            TempWHTEntry.DeleteAll();
    end;
}
