// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSBase;

using Microsoft.Finance.TaxBase;
using Microsoft.Purchases.Vendor;

table 18688 "TDS Concessional Code"
{
    Caption = 'TDS Concessional Code';
    DrillDownPageId = "TDS Concessional Codes";
    LookupPageId = "TDS Concessional Codes";
    DataCaptionFields = "Vendor No.", "Section";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;
        }
        field(2; Section; Code[10])
        {
            Caption = 'Section';
            TableRelation = "Allowed Sections"."TDS Section" where("Vendor No" = field("Vendor No."));
            DataClassification = CustomerContent;
        }
        field(3; "Concessional Code"; Code[10])
        {
            Caption = 'Concessional Code';
            TableRelation = "Concessional Code";
            DataClassification = CustomerContent;
        }
        field(4; "Certificate No."; Code[20])
        {
            Caption = 'Certificate No.';
            DataClassification = CustomerContent;
        }
        field(5; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = CustomerContent;
        }
        field(6; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ShorterEndDateErr: Label 'End Date should not be greater than the Start Date';
            begin
                if "End Date" < "Start Date" then
                    Error(ShorterEndDateErr);
            end;
        }
        field(7; "Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Certificate Value';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Remaining Certificate Value" = 0) or ("Certificate Value" <> xRec."Certificate Value") then
                    "Remaining Certificate Value" := "Certificate Value";
            end;
        }
        field(8; "Remaining Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Certificate Value';
            DataClassification = CustomerContent;
        }
        field(9; "Used Certificate Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Used Certificate Value';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Vendor No.", Section, "Concessional Code", "Certificate No.", "Start Date", "End Date")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        ArchiveExistingCertIfAny();
    end;

    local procedure ArchiveExistingCertIfAny()
    var
        ExistingCert: Record "TDS Concessional Code";
        ArchivedCert: Record "TDS Concessional Code Archive";
        ReplaceExistingCertQst: Label 'An existing TDS Concessional Code (%1) is already defined for Vendor %2, Section %3. It will be moved to the archive and replaced by this new certificate.\Do you want to continue?', Comment = '%1 = Certificate No., %2 = Vendor No., %3 = Section';
        CannotReplaceErr: Label 'Insert cancelled. The existing certificate (%1) for Vendor %2, Section %3 was not replaced.', Comment = '%1 = Certificate No., %2 = Vendor No., %3 = Section';
    begin
        if ("Vendor No." = '') or (Section = '') then
            exit;

        ExistingCert.SetRange("Vendor No.", "Vendor No.");
        ExistingCert.SetRange(Section, Section);
        if not ExistingCert.FindSet() then
            exit;

        if not Confirm(ReplaceExistingCertQst, false,
            ExistingCert."Certificate No.",
            ExistingCert."Vendor No.",
            ExistingCert.Section)
        then
            Error(CannotReplaceErr,
                ExistingCert."Certificate No.",
                ExistingCert."Vendor No.",
                ExistingCert.Section);

        repeat
            ArchivedCert.Init();
            ArchivedCert.TransferFields(ExistingCert, true);
            ArchivedCert."Archived On" := CurrentDateTime();
            ArchivedCert."Archived By" := CopyStr(UserId(), 1, MaxStrLen(ArchivedCert."Archived By"));
            if not ArchivedCert.Insert() then
                ArchivedCert.Modify();
        until ExistingCert.Next() = 0;

        ExistingCert.Reset();
        ExistingCert.SetRange("Vendor No.", "Vendor No.");
        ExistingCert.SetRange(Section, Section);
        ExistingCert.DeleteAll();
    end;
}
