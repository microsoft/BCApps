// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;

/// <summary>
/// Archive table for deferral header records, storing historical versions of deferral schedules.
/// Maintains deferral schedule history when documents are archived for audit and reference purposes.
/// </summary>
table 5127 "Deferral Header Archive"
{
    Caption = 'Deferral Header Archive';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this archived deferral.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        /// <summary>
        /// Document type ID from the archived source document.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number from the archived source document.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Line number within the archived source document.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Deferral template code used for this archived schedule.
        /// </summary>
        field(7; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
            TableRelation = "Deferral Template"."Deferral Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Amount that was deferred in the archived document currency.
        /// </summary>
        field(8; "Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Defer';
        }
        /// <summary>
        /// Amount that was deferred converted to local currency (LCY) at the time of archiving.
        /// </summary>
        field(9; "Amount to Defer (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount to Defer (LCY)';
        }
        /// <summary>
        /// Calculation method used for the archived deferral schedule.
        /// </summary>
        field(10; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        /// <summary>
        /// Start date used for the archived deferral schedule.
        /// </summary>
        field(11; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        /// <summary>
        /// Number of periods defined for the archived deferral schedule.
        /// </summary>
        field(12; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            NotBlank = true;
        }
        /// <summary>
        /// Description of the archived deferral schedule.
        /// </summary>
        field(13; "Schedule Description"; Text[100])
        {
            Caption = 'Schedule Description';
        }
        /// <summary>
        /// Original amount to defer before any modifications at the time of archiving.
        /// </summary>
        field(14; "Initial Amount to Defer"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Initial Amount to Defer';
        }
        /// <summary>
        /// Currency code of the archived source document.
        /// </summary>
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// Version number of the archived document.
        /// </summary>
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        /// <summary>
        /// Document number occurrence for handling duplicate document numbers.
        /// </summary>
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteLines("Deferral Doc. Type", "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.");
    end;

    /// <summary>
    /// Deletes an archived deferral header and all associated lines.
    /// Used when cleaning up document archives.
    /// </summary>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="DocumentType">Document type ID</param>
    /// <param name="DocumentNo">Document number</param>
    /// <param name="DocNoOcurrence">Document number occurrence for archive</param>
    /// <param name="VersionNo">Version number for archive</param>
    /// <param name="LineNo">Line number within the document</param>
    procedure DeleteHeader(DeferralDocType: Integer; DocumentType: Integer; DocumentNo: Code[20]; DocNoOcurrence: Integer; VersionNo: Integer; LineNo: Integer)
    begin
        if Get(DeferralDocType, DocumentType, DocumentNo, LineNo) then begin
            Delete();
            DeleteLines(Enum::"Deferral Document Type".FromInteger(DeferralDocType), DocumentType, DocumentNo, DocNoOcurrence, VersionNo, LineNo);
        end;
    end;

    local procedure DeleteLines(DeferralDocType: Enum "Deferral Document Type"; DocumentType: Integer; DocumentNo: Code[20]; DocNoOcurrence: Integer; VersionNo: Integer; LineNo: Integer)
    var
        DeferralLineArchive: Record "Deferral Line Archive";
    begin
        DeferralLineArchive.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLineArchive.SetRange("Document Type", DocumentType);
        DeferralLineArchive.SetRange("Document No.", DocumentNo);
        DeferralLineArchive.SetRange("Doc. No. Occurrence", DocNoOcurrence);
        DeferralLineArchive.SetRange("Version No.", VersionNo);
        DeferralLineArchive.SetRange("Line No.", LineNo);
        if DeferralLineArchive.FindFirst() then
            DeferralLineArchive.DeleteAll();
    end;
}
