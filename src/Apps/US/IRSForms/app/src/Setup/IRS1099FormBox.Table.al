// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10033 "IRS 1099 Form Box"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "IRS 1099 Form Boxes";
    LookupPageId = "IRS 1099 Form Boxes";

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
        field(5; "Minimum Reportable Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
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
        fieldgroup(DropDown; "No.", Description)
        {
        }
        fieldgroup(Brick; "No.", Description)
        {
        }
    }

    var
        FormBoxCannotBeDeletedErr: Label 'The 1099 form box %1 cannot be deleted because it is used in the 1099 form document lines.', Comment = '%1 = Form box number';

    trigger OnInsert()
    begin
        CheckSupplementalIdentity();
    end;

    trigger OnDelete()
    begin
        CheckFormBoxIsNotInUse();
    end;

    trigger OnRename()
    begin
        xRec.CheckFormBoxIsNotInUse();
        CheckSupplementalIdentity();
    end;

    local procedure CheckSupplementalIdentity()
    var
        Conflict: Text;
    begin
        Conflict := GetSupplementalIdentityConflict();
        if Conflict <> '' then
            Error(Conflict);
    end;

    internal procedure GetSupplementalIdentityConflict(): Text
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        IdentifierConflictErr: Label 'Company %1, period %2, form %3, box %4 already exists as a supplemental box and cannot be used as a form box. Existing setup has not been changed. Use a different box number or remove the unused supplemental box first.', Comment = '%1 = company, %2 = period, %3 = form, %4 = box';
    begin
        SupplementalBox.ChangeCompany(CurrentCompany());
        if SupplementalBox.Get("Period No.", "Form No.", "No.") then
            exit(StrSubstNo(IdentifierConflictErr, CurrentCompany(), "Period No.", "Form No.", "No."));
    end;

    internal procedure CheckFormBoxIsNotInUse()
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        ParentReferencedErr: Label 'Form box %1 in period %2, form %3 is the parent of supplemental box %4. On the IRS 1099 Supplemental Boxes page, remove that supplemental box or select a different Parent Form Box No. before deleting or renaming this form box.', Comment = '%1 = form box, %2 = period, %3 = form, %4 = supplemental box';
    begin
        SupplementalBox.SetRange("Period No.", "Period No.");
        SupplementalBox.SetRange("Form No.", "Form No.");
        SupplementalBox.SetRange("Parent Form Box No.", "No.");
        if SupplementalBox.FindFirst() then
            Error(ParentReferencedErr, "No.", "Period No.", "Form No.", SupplementalBox."No.");
        DocLine.SetRange("Period No.", "Period No.");
        DocLine.SetRange("Form No.", "Form No.");
        DocLine.SetRange("Form Box No.", "No.");
        if not DocLine.IsEmpty() then
            Error(FormBoxCannotBeDeletedErr, "No.");
    end;
}
