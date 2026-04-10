// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Utilities;

/// <summary>
/// Stores positive pay export entries for bank accounts, tracking upload history and file details.
/// Each record represents a positive pay file export session with associated metadata and statistics.
/// </summary>
/// <remarks>
/// Integrates with Data Exchange Framework for export formatting and bank account setup.
/// Stores exported file content as BLOB for re-export capabilities.
/// </remarks>
table 1231 "Positive Pay Entry"
{
    Caption = 'Positive Pay Entry';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account number for which the positive pay export was generated.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            ToolTip = 'Specifies the bank account number. If you select Balance at Date, the balance as of the last day in the relevant time interval is displayed.';
            NotBlank = false;
            TableRelation = "Bank Account"."No.";

            trigger OnValidate()
            begin
                if "Bank Account No." <> '' then
                    "Upload Date-Time" := CurrentDateTime
                else
                    "Upload Date-Time" := CreateDateTime(0D, 0T);
            end;
        }
        /// <summary>
        /// Date and time when the positive pay file was uploaded or exported.
        /// </summary>
        field(2; "Upload Date-Time"; DateTime)
        {
            Caption = 'Upload Date-Time';
            ToolTip = 'Specifies when the Positive Pay file was uploaded.';
            Editable = false;
        }
        /// <summary>
        /// Date component of the last upload operation for this bank account.
        /// </summary>
        field(5; "Last Upload Date"; Date)
        {
            Caption = 'Last Upload Date';
            ToolTip = 'Specifies the last date that you exported a Positive Pay file.';
        }
        /// <summary>
        /// Time component of the last upload operation for this bank account.
        /// </summary>
        field(6; "Last Upload Time"; Time)
        {
            Caption = 'Last Upload Time';
            ToolTip = 'Specifies the last time that you exported a Positive Pay file.';
        }
        /// <summary>
        /// Total number of positive pay uploads performed for this bank account.
        /// </summary>
        field(7; "Number of Uploads"; Integer)
        {
            Caption = 'Number of Uploads';
            ToolTip = 'Specifies how many times the related Positive Pay file was uploaded.';
        }
        /// <summary>
        /// Total number of checks included in this positive pay export.
        /// </summary>
        field(8; "Number of Checks"; Integer)
        {
            Caption = 'Number of Checks';
            ToolTip = 'Specifies how many checks were processed with the Positive Pay entry.';
        }
        /// <summary>
        /// Total number of voided checks included in this positive pay export.
        /// </summary>
        field(9; "Number of Voids"; Integer)
        {
            Caption = 'Number of Voids';
            ToolTip = 'Specifies how many of the related checks were voided.';
        }
        /// <summary>
        /// Total amount of all checks included in this positive pay export.
        /// </summary>
        field(10; "Check Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Check Amount';
            ToolTip = 'Specifies the amount on the check.';
        }
        /// <summary>
        /// Total amount of all voided checks included in this positive pay export.
        /// </summary>
        field(11; "Void Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Void Amount';
            ToolTip = 'Specifies the amount in the Positive Pay file that is related to voided checks.';
        }
        /// <summary>
        /// Confirmation number received from the bank after successful positive pay file upload.
        /// </summary>
        field(12; "Confirmation Number"; Text[20])
        {
            Caption = 'Confirmation Number';
            ToolTip = 'Specifies the confirmation number that you receive when the file upload to the bank is successful.';
        }
        /// <summary>
        /// Binary content of the exported positive pay file for re-export purposes.
        /// </summary>
        field(13; "Exported File"; BLOB)
        {
            Caption = 'Exported File';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Upload Date-Time")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PositivePayFileNotFoundErr: Label 'The original positive pay export file was not found.';

    /// <summary>
    /// Gets the currency code from the associated bank account for amount formatting.
    /// </summary>
    /// <returns>Currency code from the bank account, or empty string if not found.</returns>
    local procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAccount: Record "Bank Account";
    begin
        if "Bank Account No." = '' then
            exit('');

        if BankAccount.Get("Bank Account No.") then
            exit(BankAccount."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Re-exports the previously generated positive pay file by downloading it from the stored BLOB.
    /// </summary>
    /// <remarks>
    /// This procedure allows users to download a copy of a previously exported positive pay file.
    /// The file name is formatted as BankAccountNo + Export Date in MMDDYYYY format with .TXT extension.
    /// Raises an error if the original file content is not found in the BLOB field.
    /// </remarks>
    [Scope('OnPrem')]
    procedure Reexport()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ReexportFileName: Text[50];
        ExportDate: Date;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Exported File"));

        if not TempBlob.HasValue() then
            Error(PositivePayFileNotFoundErr);

        ExportDate := DT2Date("Upload Date-Time");
        ReexportFileName := "Bank Account No." + Format(ExportDate, 0, '<Month><Day><Year4>');
        FileMgt.BLOBExport(TempBlob, StrSubstNo('%1.TXT', ReexportFileName), true);
    end;
}

