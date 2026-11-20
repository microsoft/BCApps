// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10054 "IRS 1099 Suppl. Box"
{
    Caption = 'IRS 1099 Supplemental Box';
    DataClassification = CustomerContent;
    LookupPageId = "IRS 1099 Suppl. Boxes";
    DrillDownPageId = "IRS 1099 Suppl. Boxes";

    fields
    {
        field(1; "Period No."; Code[20])
        {
            TableRelation = "IRS Reporting Period";
        }
        field(2; "Form No."; Code[20])
        {
            TableRelation = "IRS 1099 Form"."No." where("Period No." = field("Period No."));
        }
        field(3; "No."; Code[20])
        {
            NotBlank = true;
        }
        field(4; Description; Text[250])
        {
        }
        field(5; "Parent Form Box No."; Code[20])
        {
            TableRelation = "IRS 1099 Form Box"."No." where("Period No." = field("Period No."), "Form No." = field("Form No."));
        }
        field(6; "Value Type"; Enum "IRS 1099 Supplemental Type")
        {
        }
        field(7; "XML Element Name"; Text[100])
        {
        }
    }

    keys
    {
        key(PK; "Period No.", "Form No.", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Parent Form Box No.", "Value Type")
        {
        }
    }

    trigger OnInsert()
    begin
        Supplemental.ValidateDefinition(Rec);
    end;

    trigger OnModify()
    var
        StoredDefinition: Record "IRS 1099 Suppl. Box";
    begin
        StoredDefinition.Get("Period No.", "Form No.", "No.");
        if ("Parent Form Box No." <> StoredDefinition."Parent Form Box No.") or
           ("Value Type" <> StoredDefinition."Value Type") or ("XML Element Name" <> StoredDefinition."XML Element Name")
        then
            StoredDefinition.CheckNotUsed();
        Supplemental.ValidateDefinition(Rec);
    end;

    trigger OnDelete()
    begin
        CheckNotUsed();
    end;

    trigger OnRename()
    begin
        xRec.CheckNotUsed();
        Supplemental.ValidateDefinition(Rec);
    end;

    var
        Supplemental: Codeunit "IRS 1099 Supplemental";

    procedure CheckNotUsed()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        StatementLine: Record "IRS 1099 Form Statement Line";
        InUseErr: Label 'Supplemental box %1 in period %2, form %3 is used by document %4. You cannot delete the box or change its reporting period, form, number, parent form box, value type, or XML element while it is in use.', Comment = '%1 = supplemental box, %2 = period, %3 = form, %4 = document ID';
        StatementInUseErr: Label 'Supplemental box %1 in period %2, form %3 is used by statement row %4 (line %5). You cannot delete the box or change its reporting period, form, number, parent form box, value type, or XML element. Remove or change the box selection on the IRS 1099 Form Statement page first.', Comment = '%1 = supplemental box, %2 = period, %3 = form, %4 = statement row, %5 = statement line';
    begin
        StatementLine.SetRange("Period No.", "Period No.");
        StatementLine.SetRange("Form No.", "Form No.");
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        StatementLine.SetRange("Supplemental Box No.", "No.");
        if StatementLine.FindFirst() then
            Error(StatementInUseErr, "No.", "Period No.", "Form No.", StatementLine."Row No.", StatementLine."Line No.");
        SupplLine.SetRange("Supplemental Box No.", "No.");
        if SupplLine.FindSet() then
            repeat
                if DocHeader.Get(SupplLine."Document ID") then
                    if (DocHeader."Period No." = "Period No.") and (DocHeader."Form No." = "Form No.") then
                        Error(InUseErr, "No.", "Period No.", "Form No.", DocHeader.ID);
            until SupplLine.Next() = 0;
    end;
}
