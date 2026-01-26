// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 12206 "Fattura Document Type"
{
    DrillDownPageID = "Fattura Document Type List";
    LookupPageID = "Fattura Document Type List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Description; Text[250])
        {
        }
        field(10; Invoice; Boolean)
        {

            trigger OnValidate()
            var
                FatturaDocumentType: Record "Fattura Document Type";
            begin
                if Invoice then begin
                    FatturaDocumentType.SetFilter("No.", '<>%1', "No.");
                    FatturaDocumentType.SetRange(Invoice, true);
                    if FatturaDocumentType.FindFirst() then
                        Error(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Invoice), FatturaDocumentType."No.");
                end;
            end;
        }
        field(11; "Credit Memo"; Boolean)
        {

            trigger OnValidate()
            var
                FatturaDocumentType: Record "Fattura Document Type";
            begin
                if "Credit Memo" then begin
                    FatturaDocumentType.SetFilter("No.", '<>%1', "No.");
                    FatturaDocumentType.SetRange("Credit Memo", true);
                    if FatturaDocumentType.FindFirst() then
                        Error(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Credit Memo"), FatturaDocumentType."No.");
                end;
            end;
        }
        field(12; "Self-Billing"; Boolean)
        {

            trigger OnValidate()
            var
                FatturaDocumentType: Record "Fattura Document Type";
            begin
                if "Self-Billing" then begin
                    FatturaDocumentType.SetFilter("No.", '<>%1', "No.");
                    FatturaDocumentType.SetRange("Self-Billing", true);
                    if FatturaDocumentType.FindFirst() then
                        Error(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Self-Billing"), FatturaDocumentType."No.");
                end;
            end;
        }
        field(13; Prepayment; Boolean)
        {

            trigger OnValidate()
            var
                FatturaDocumentType: Record "Fattura Document Type";
            begin
                if Prepayment then begin
                    FatturaDocumentType.SetFilter("No.", '<>%1', "No.");
                    FatturaDocumentType.SetRange(Prepayment, true);
                    if FatturaDocumentType.FindFirst() then
                        Error(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Prepayment), FatturaDocumentType."No.");
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        OptionAlreadySpecifiedErr: Label 'Documents of type %1 already have code %2 as default. You can only use one code for each type of document.', Comment = '%1 = field caption;%2 = code value.';
}

