// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10055 "IRS 1099 Doc. Suppl. Line"
{
    Caption = 'IRS 1099 Document Supplemental Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document ID"; Integer)
        {
            TableRelation = "IRS 1099 Form Doc. Header";
            Editable = false;
        }
        field(2; "Supplemental Box No."; Code[20])
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplySupplBoxSetup();
            end;
        }
        field(3; "Parent Form Box No."; Code[20])
        {
            Editable = false;
        }
        field(4; "Value Type"; Enum "IRS 1099 Supplemental Type")
        {
            Editable = false;
        }
        field(5; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';

            trigger OnValidate()
            begin
                ValidateEntry();
            end;
        }
        field(6; "Occupation Code 1"; Text[3])
        {
            trigger OnValidate()
            begin
                ValidateEntry();
            end;
        }
        field(7; "Occupation Code 2"; Text[3])
        {
            trigger OnValidate()
            begin
                ValidateEntry();
            end;
        }
    }

    keys
    {
        key(PK; "Document ID", "Supplemental Box No.")
        {
            Clustered = true;
        }
        key(Parent; "Document ID", "Parent Form Box No.")
        {
        }
        key(Definition; "Supplemental Box No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestStatusOpen();
        ApplySupplBoxSetup();
        ValidateEntry();
    end;

    trigger OnModify()
    begin
        TestStatusOpen();
        if ("Document ID" <> xRec."Document ID") or
           (("Supplemental Box No." = xRec."Supplemental Box No.") and
            (("Parent Form Box No." <> xRec."Parent Form Box No.") or ("Value Type" <> xRec."Value Type")))
        then
            Error(SnapshotChangedErr);
        ValidateEntry();
    end;

    trigger OnDelete()
    begin
        TestStatusOpen();
    end;

    trigger OnRename()
    begin
        TestStatusOpen();
        xRec.TestStatusOpen();
        TestField("Document ID", xRec."Document ID");
        ApplySupplBoxSetup();
        ValidateEntry();
    end;

    var
        Supplemental: Codeunit "IRS 1099 Supplemental";
        SnapshotChangedErr: Label 'You cannot change the document, parent form box, or value type of a saved supplemental line directly. To change the parent form box or value type, select the supplemental box again on a document with status Open.';

    local procedure ApplySupplBoxSetup()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        DocHeader.Get("Document ID");
        SupplBox.Get(DocHeader."Period No.", DocHeader."Form No.", "Supplemental Box No.");
        Supplemental.ValidateSupplBoxSetup(SupplBox);
        // Check the existing typed values before assigning the new type.
        Supplemental.ValidateTypedValues(Rec, SupplBox."Value Type");
        "Parent Form Box No." := SupplBox."Parent Form Box No.";
        "Value Type" := SupplBox."Value Type";
        Supplemental.ValidateLine(Rec);
    end;

    local procedure ValidateEntry()
    begin
        TestStatusOpen();
        Supplemental.ValidateLine(Rec);
    end;

    internal procedure TestStatusOpen()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        DocHeader.Get("Document ID");
        DocHeader.TestField(Status, DocHeader.Status::Open);
    end;
}
