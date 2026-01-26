// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

report 15000003 "Rem. payment order - Import"
{
    Caption = 'Rem. payment order - import';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                ImportBankRep: Report "Remittance - Import (Bank)";
                ImportBBSRep: Report "Remittance - Import (BBS)";
                ImportPain002: Codeunit "Import Pain002";
                ImportCAMT054: Codeunit "Import CAMT054";
            begin
                // Import all files:
                ReturnFile.Reset();
                ReturnFile.SetRange(Import, true);
                if ReturnFile.FindSet() then
                    repeat
                        case ReturnFile.Format of
                            ReturnFile.Format::Telepay:
                                begin
                                    Clear(ImportBankRep);
                                    ImportBankRep.Initialize(CurrentGenJournalLine, ReturnFile."File Name", Note);
                                    ImportBankRep.RunModal();
                                    ImportBankRep.ReadStatus(NumberApproved, NumberRejected, NumberSettled, MoreReturnJournals, PaymOrder);
                                end;
                            ReturnFile.Format::BBS:
                                begin
                                    Clear(ImportBBSRep);
                                    ImportBBSRep.Initialize(CurrentGenJournalLine, ReturnFile."File Name", Note);
                                    ImportBBSRep.RunModal();
                                    ImportBBSRep.ReadStatus(NumberApproved, NumberRejected, NumberSettled, MoreReturnJournals, PaymOrder);
                                end;
                            ReturnFile.Format::Pain002:
                                begin
                                    ImportPain002.ImportAndHandlePain002File(CurrentGenJournalLine, ReturnFile."File Name", Note);
                                    ImportPain002.ReadStatus(NumberApproved, NumberRejected, NumberSettled, MoreReturnJournals, PaymOrder);
                                end;
                            ReturnFile.Format::CAMT054:
                                begin
                                    ImportCAMT054.ImportAndHandleCAMT054File(CurrentGenJournalLine, ReturnFile."File Name", Note);
                                    ImportCAMT054.ReadStatus(NumberApproved, NumberRejected, NumberSettled, MoreReturnJournals, PaymOrder);
                                end
                        end;
                    until ReturnFile.Next() = 0;
                if (NumberSettled > 0) and MoreReturnJournals and not ControlBatch then begin
                    Commit();
                    SettlementStatus.SetPaymOrder(PaymOrder);
                    SettlementStatus.RunModal();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if ReturnFile.Count = 0 then
                    Error(Text002);
            end;
        }
    }

    requestpage
    {
        Caption = 'Remittance payment order - import';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Note; Note)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment order note';
                        ToolTip = 'Specifies a note that is transferred to the payment order.';
                    }
                    field(ControlBatch; ControlBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Control batch';
                        ToolTip = 'Specifies if you want to create a file for a control during the export. No changes will be recorded.';

                        trigger OnValidate()
                        begin
                            ControlBatchOnPush();
                        end;
                    }
                    field(StatusText; StatusText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        MultiLine = true;
                    }
                    field(Filenames; Filenames)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Re&turn files';
                        Editable = false;
                        ToolTip = 'Specifies how many return files are found and imported.';

                        trigger OnAssistEdit()
                        begin
                            Clear(FileList);
                            ReturnFile.Reset();
                            FileList.SetRecord(ReturnFile);
                            FileList.SetTableView(ReturnFile);
                            FileList.RunModal();
                            SetStatusText();
                        end;
                    }
                }
            }
        }

        actions
        {
        }


        trigger OnOpenPage()
        begin
            ReturnFile.Reset();
            ReturnFile.DeleteAll();
            repeat
                FindFiles(ReturnFileSetup);
            until ReturnFileSetup.Next() = 0;

            SetStatusText();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        NextFileNo := 10000;
    end;

    trigger OnPostReport()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnPostReport(ReturnFile, IsHandled);
        if IsHandled then
            exit;

        if ControlBatch then
            Error(Text001);

        SaveReturnFiles();
    end;

    trigger OnPreReport()
    begin
        // Make sure the journal is empty:
        GenJnlLine.SetRange("Journal Template Name", CurrentGenJournalLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", CurrentGenJournalLine."Journal Batch Name");
        if not GenJnlLine.IsEmpty() then
            Error(Text000, CurrentGenJournalLine."Journal Batch Name");
    end;

    var
        Text000: Label ' %1 journal should be empty before import.';
        Text001: Label 'This was a check.\Import of return data is cancelled.';
        Text002: Label 'There are no return files to import.';
        Text004: Label 'Note:\With Control, return files are read in advance to check if the import can be made.\Return data is not imported to %1.', Comment = '%1 - product name';
        Text007: Label 'Return file format "%1" is unknown.\Import is aborted.';
        Text009: Label '*.tmp|*~';
        Text012: Label 'Number of files found: %1.\Number of files selected for import: %2.';
        Text013: Label 'AH';
        Text014: Label 'NY';
        RemAgreement: Record "Remittance Agreement";
        CurrentGenJournalLine: Record "Gen. Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
        ReturnFile: Record "Return File";
        ReturnFileSetup: Record "Return File Setup";
        PaymOrder: Record "Remittance Payment Order";
        RemTools: Codeunit "Remittance Tools";
        FileList: Page "Return Files";
        SettlementStatus: Page "Payment Order - Settl. Status";
        Note: Text[50];
        ControlBatch: Boolean;
        StatusText: Text[200];
        NextFileNo: Integer;
        NumberSettled: Integer;
        NumberRejected: Integer;
        NumberApproved: Integer;
        MoreReturnJournals: Boolean;
        Filenames: Code[10];
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    local procedure FindFiles(ReturnFileSetup: Record "Return File Setup")
    var
        FileCopy: Record File temporary;
        FileMgt: Codeunit "File Management";
        FilePath: Text[150];
        IsHandled: Boolean;
    begin
        // Two options:
        // 1. Exact filename.
        // Example: c:\bank\return.txt. is specified in file list and FileNumber
        // is counted (global var).
        // 2. Filename specified in search format.
        // Example: c:\bank\return.*. this includes all files starting with 'ret'. For instance, files
        // ret.001, ret.002 etc. Files with this format are created by Kreditkassen.
        // All existing files are placed in filelist and FileNumber is updates.

        IsHandled := false;
        OnBeforeFindFiles(ReturnFileSetup, IsHandled);
        if IsHandled then
            exit;

        if ReturnFileSetup."Return File Name" = '' then
            exit;

        // Note: File.Name is case-sensitive. Names are therefore copied to a temporary table:
        FilePath := FileMgt.GetDirectoryName(ReturnFileSetup."Return File Name") + '\';

        FileCopy.DeleteAll();

        // From now on use copies of file names :
        FileCopy.SetFilter(Name, LowerCase(FileMgt.GetFileName(ReturnFileSetup."Return File Name")));
        if FileCopy.FindSet() then
            repeat
                ReturnFile.Init();
                ReturnFile."Line No." := NextFileNo;
                NextFileNo := NextFileNo + 10000;
                ReturnFile."File Name" := FilePath + FileCopy.Name;
                ReturnFile.Date := FileCopy.Date;
                ReturnFile.Time := FileCopy.Time;
                ReturnFile.Size := FileCopy.Size;
                ReturnFile.Import := true;
                ReturnFile."Agreement Code" := ReturnFileSetup."Agreement Code";
                case FileFormat(CopyStr(FileMgt.UploadFile(ChooseFileTitleMsg, ''), 1, 250)) of
                    ReturnFile.Format::Telepay:
                        ReturnFile.Format := ReturnFile.Format::Telepay;
                    ReturnFile.Format::BBS:
                        ReturnFile.Format := ReturnFile.Format::BBS;
                    ReturnFile.Format::Pain002:
                        ReturnFile.Format := ReturnFile.Format::Pain002;
                    ReturnFile.Format::CAMT054:
                        ReturnFile.Format := ReturnFile.Format::CAMT054;
                    else
                        Error(Text007);
                end;
                ReturnFile.Insert();
            until FileCopy.Next() = 0;

        // Note: file name must not end with .tmp and '~'. Delete all such names :
        ReturnFile.Reset();
        ReturnFile.SetFilter("File Name", Text009);
        ReturnFile.DeleteAll();
        ReturnFile.Reset();
    end;

    [Scope('OnPrem')]
    procedure SetJournal(GenJnlLine: Record "Gen. Journal Line")
    begin
        // Specify variables used for import
        // Called from external function which imports upon return.
        CurrentGenJournalLine := GenJnlLine;
    end;

    local procedure SetStatusText()
    var
        FileNumber1: Integer;
        FileNumber2: Integer;
    begin
        ReturnFile.Reset();
        FileNumber1 := ReturnFile.Count();

        ReturnFile.SetRange(Import, true);
        FileNumber2 := ReturnFile.Count();

        if (FileNumber1 > 0) or (FileNumber2 > 0) then
            Filenames := '*'
        else
            Filenames := '';

        StatusText := StrSubstNo(Text012, FileNumber1, FileNumber2);
    end;

    [Scope('OnPrem')]
    procedure FileFormat(Filename: Text[250]): Integer
    var
        File: File;
        Line: Text[250];
        NumberOFChars: Integer;
    begin
        // Return value refers to Option in Return Files field.
        // Return: 0 = Telepay, 1 = BBS, 2 = Pain002, 3 = CAMT 054, -1 unknown file format.
        File.Open(Filename);
        File.TextMode(true);
        NumberOFChars := File.Read(Line);
        case true of
            NumberOFChars < 2:
                exit(-1);
            CopyStr(Line, 1, 2) = Text013:
                exit(ReturnFile.Format::Telepay);
            CopyStr(Line, 1, 2) = Text014:
                exit(ReturnFile.Format::BBS);
            StrPos(UpperCase(Line), 'XML') <> 0:
                exit(DetermineFileType(Filename));
            else
                exit(-1);
        end;
    end;

    local procedure ControlBatchOnPush()
    begin
        if ControlBatch then
            Message(Text004, PRODUCTNAME.Full());
    end;

    local procedure DetermineFileType(Filename: Text[250]): Integer
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        ImportPain002: Codeunit "Import Pain002";
        ImportCAMT054: Codeunit "Import CAMT054";
        XmlDocument: DotNet XmlDocument;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(Filename, XmlDocument);
        case XmlDocument.DocumentElement.NamespaceURI of
            ImportPain002.GetNamespace():
                exit(ReturnFile.Format::Pain002);
            ImportCAMT054.GetNamespace():
                exit(ReturnFile.Format::CAMT054);
        end;
        exit(-1);
    end;

    local procedure SaveReturnFiles()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveReturnFiles(ReturnFile, IsHandled);
        if IsHandled then
            exit;

        ReturnFile.Reset();
        ReturnFile.SetRange(Import, true);
        if ReturnFile.Find('-') then
            repeat
                RemAgreement.Get(ReturnFile."Agreement Code");
                if RemAgreement."Save Return File" then
                    RemTools.NewFilename(ReturnFile."File Name");
            until ReturnFile.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFiles(var ReturnFileSetup: Record "Return File Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostReport(var ReturnFile: Record "Return File"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReturnFiles(var ReturnFile: Record "Return File"; var IsHandled: Boolean)
    begin
    end;
}

