// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Security.AccessControl;
using System.Utilities;

/// <summary>
/// Table 1205 "Credit Transfer Register" manages collections of credit transfer entries.
/// Each register represents a batch of payments exported to a bank file, containing metadata
/// about the export process including status, creation details, and the exported file content.
/// </summary>
/// <remarks>
/// Integrates with Credit Transfer Entry table for individual payment records and supports
/// file re-export functionality. Provides extensibility through OnBeforeExportFile event.
/// </remarks>
table 1205 "Credit Transfer Register"
{
    Caption = 'Credit Transfer Register';
    DataCaptionFields = Identifier, "Created Date-Time";
    DrillDownPageID = "Credit Transfer Registers";
    LookupPageID = "Credit Transfer Registers";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential number for the credit transfer register.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Identifier code for the credit transfer register, used in file naming.
        /// </summary>
        field(2; Identifier; Code[20])
        {
            Caption = 'Identifier';
        }
        /// <summary>
        /// Date and time when the credit transfer register was created.
        /// </summary>
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        /// <summary>
        /// User who created the credit transfer register.
        /// </summary>
        field(4; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Current status of the credit transfer register (Canceled, File Created, File Re-exported).
        /// </summary>
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Canceled,File Created,File Re-exported';
            OptionMembers = Canceled,"File Created","File Re-exported";
        }
        /// <summary>
        /// Number of individual credit transfer entries in this register.
        /// </summary>
        field(6; "No. of Transfers"; Integer)
        {
            CalcFormula = count("Credit Transfer Entry" where("Credit Transfer Register No." = field("No.")));
            Caption = 'No. of Transfers';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Bank account from which the credit transfers originate.
        /// </summary>
        field(7; "From Bank Account No."; Code[20])
        {
            Caption = 'From Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Name of the originating bank account.
        /// </summary>
        field(8; "From Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("From Bank Account No.")));
            Caption = 'From Bank Account Name';
            FieldClass = FlowField;
        }
        /// <summary>
        /// BLOB field containing the exported payment file content.
        /// </summary>
        field(9; "Exported File"; BLOB)
        {
            Caption = 'Exported File';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
    begin
        CreditTransferEntry.SetRange("Credit Transfer Register No.", "No.");
        CreditTransferEntry.DeleteAll();
    end;

    var
        PaymentsFileNotFoundErr: Label 'The original payment file was not found.\Export a new file from the Payment Journal window.';
        ExportToServerFile: Boolean;

    /// <summary>
    /// Creates a new credit transfer register with the specified identifier and bank account.
    /// </summary>
    /// <param name="NewIdentifier">Identifier for the new register</param>
    /// <param name="NewBankAccountNo">Bank account number for the register</param>
    procedure CreateNew(NewIdentifier: Code[20]; NewBankAccountNo: Code[20])
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
        "Created Date-Time" := CurrentDateTime;
        "Created by User" := UserId;
        "From Bank Account No." := NewBankAccountNo;
        Insert();
    end;

    /// <summary>
    /// Sets the status of the credit transfer register.
    /// </summary>
    /// <param name="NewStatus">New status option value</param>
    procedure SetStatus(NewStatus: Option)
    begin
        LockTable();
        Find();
        Status := NewStatus;
        Modify();
    end;

    /// <summary>
    /// Re-exports the payment file from the stored exported file content.
    /// Updates the status to "File Re-exported" and creates a re-export history entry.
    /// </summary>
    procedure Reexport()
    var
        CreditTransReExportHistory: Record "Credit Trans Re-export History";
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(Rec, FieldNo("Exported File"));

        if not TempBlob.HasValue() then
            Error(PaymentsFileNotFoundErr);

        CreditTransReExportHistory.Init();
        CreditTransReExportHistory."Credit Transfer Register No." := "No.";
        CreditTransReExportHistory.Insert(true);

        if ExportFile(TempBlob) then begin
            Status := Status::"File Re-exported";
            OnReexportOnBeforeModify(Rec, TempBlob, ExportToServerFile);
            Modify();
        end;
    end;

    local procedure ExportFile(var TempBlob: Codeunit "Temp Blob") Result: Boolean
    var
        FileManagement: Codeunit "File Management";
        FileNamePatternTok: Label '%1.XML', Locked = true;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportFile(TempBlob, Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := FileManagement.BLOBExport(TempBlob, StrSubstNo(FileNamePatternTok, Identifier), not ExportToServerFile) <> '';
    end;

    /// <summary>
    /// Sets the exported file content from a data exchange record.
    /// </summary>
    /// <param name="DataExch">Data exchange record containing the file content</param>
    procedure SetFileContent(var DataExch: Record "Data Exch.")
    begin
        LockTable();
        Find();
        DataExch.CalcFields("File Content");
        "Exported File" := DataExch."File Content";
        Modify();
    end;

    /// <summary>
    /// Enables export to server file mode instead of client download.
    /// </summary>
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    /// <summary>
    /// Integration event raised before exporting the payment file during re-export.
    /// Enables custom file export logic and allows bypassing standard export.
    /// </summary>
    /// <param name="TempBlob">Temp BLOB containing file content to export</param>
    /// <param name="CreditTransferRegister">Credit transfer register being re-exported</param>
    /// <param name="Result">Result of the export operation</param>
    /// <param name="IsHandled">Set to true to skip standard export processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportFile(var TempBlob: Codeunit "Temp Blob"; var CreditTransferRegister: Record "Credit Transfer Register"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying the credit transfer register after re-export.
    /// </summary>
    /// <param name="CreditTransferRegister">Credit transfer register being modified</param>
    /// <param name="TempBlob">Temp BLOB containing file content to export</param>
    /// <param name="ExportToServerFile">Indicates if export is to server file</param>
    [IntegrationEvent(false, false)]
    local procedure OnReexportOnBeforeModify(var CreditTransferRegister: Record "Credit Transfer Register"; var TempBlob: Codeunit "Temp Blob"; var ExportToServerFile: Boolean)
    begin
    end;
}

