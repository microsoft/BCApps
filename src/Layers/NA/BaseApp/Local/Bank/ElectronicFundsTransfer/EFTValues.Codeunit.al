// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

codeunit 10340 "EFT Values"
{

    trigger OnRun()
    begin
    end;

    var
        BatchHashTotal: Decimal;
        TotalBatchDebit: Decimal;
        TotalBatchCredit: Decimal;
        FileHashTotal: Decimal;
        TotalFileDebit: Decimal;
        TotalFileCredit: Decimal;
        FileEntryAddendaCount: Integer;
        SequenceNumber: Integer;
        TraceNumber: Integer;
        BatchNumber: Integer;
        EntryAddendaCount: Integer;
        BatchCount: Integer;
        NoOfRecords: Integer;
        NumberOfCustInfoRec: Integer;
        Transactions: Integer;
        DataExchEntryNo: Integer;
        IsParent: Boolean;
        ParentDefCode: Code[20];
        EFTFileIsCreated: Boolean;
        IATFileIsCreated: Boolean;
        FileCreationNumber: Integer;
        IsFileCreationNumber: Boolean;

    [Scope('OnPrem')]
    procedure GetSequenceNo() SequenceNo: Integer
    begin
        SequenceNo := SequenceNumber;
    end;

    [Scope('OnPrem')]
    procedure SetSequenceNo(SequenceNo: Integer)
    begin
        SequenceNumber := SequenceNo;
    end;

    [Scope('OnPrem')]
    procedure GetTraceNo() TraceNo: Integer
    begin
        TraceNo := TraceNumber;
    end;

    [Scope('OnPrem')]
    procedure SetTraceNo(TraceNo: Integer)
    begin
        TraceNumber := TraceNo;
    end;

    [Scope('OnPrem')]
    procedure GetFileHashTotal() FileHashTot: Decimal
    begin
        FileHashTot := FileHashTotal;
    end;

    [Scope('OnPrem')]
    procedure SetFileHashTotal(FileHashTot: Decimal)
    begin
        FileHashTotal := FileHashTot;
    end;

    [Scope('OnPrem')]
    procedure GetTotalFileDebit() TotalFileDr: Decimal
    begin
        TotalFileDr := TotalFileDebit;
    end;

    [Scope('OnPrem')]
    procedure SetTotalFileDebit(TotalFileDr: Decimal)
    begin
        TotalFileDebit := TotalFileDr;
    end;

    [Scope('OnPrem')]
    procedure GetTotalFileCredit() TotalFileCr: Decimal
    begin
        TotalFileCr := TotalFileCredit;
    end;

    [Scope('OnPrem')]
    procedure SetTotalFileCredit(TotalFileCr: Decimal)
    begin
        TotalFileCredit := TotalFileCr;
    end;

    [Scope('OnPrem')]
    procedure GetFileEntryAddendaCount() FileEntryAddendaCt: Integer
    begin
        FileEntryAddendaCt := FileEntryAddendaCount;
    end;

    [Scope('OnPrem')]
    procedure SetFileEntryAddendaCount(FileEntryAddendaCt: Integer)
    begin
        FileEntryAddendaCount := FileEntryAddendaCt;
    end;

    [Scope('OnPrem')]
    procedure GetBatchCount() BatchCt: Integer
    begin
        BatchCt := BatchCount;
    end;

    [Scope('OnPrem')]
    procedure SetBatchCount(BatchCt: Integer)
    begin
        BatchCount := BatchCt;
    end;

    [Scope('OnPrem')]
    procedure GetBatchNo() BatchNo: Integer
    begin
        BatchNo := BatchNumber;
    end;

    [Scope('OnPrem')]
    procedure SetBatchNo(BatchNo: Integer)
    begin
        BatchNumber := BatchNo;
    end;

    [Scope('OnPrem')]
    procedure GetBatchHashTotal() BatchHashTot: Decimal
    begin
        BatchHashTot := BatchHashTotal;
    end;

    [Scope('OnPrem')]
    procedure SetBatchHashTotal(BatchHashTot: Decimal)
    begin
        BatchHashTotal := BatchHashTot;
    end;

    [Scope('OnPrem')]
    procedure GetTotalBatchDebit() TotalBatchDr: Decimal
    begin
        TotalBatchDr := TotalBatchDebit;
    end;

    [Scope('OnPrem')]
    procedure SetTotalBatchDebit(TotalBatchDr: Decimal)
    begin
        TotalBatchDebit := TotalBatchDr;
    end;

    [Scope('OnPrem')]
    procedure GetTotalBatchCredit() TotalBatchCr: Decimal
    begin
        TotalBatchCr := TotalBatchCredit;
    end;

    [Scope('OnPrem')]
    procedure SetTotalBatchCredit(TotalBatchCr: Decimal)
    begin
        TotalBatchCredit := TotalBatchCr;
    end;

    [Scope('OnPrem')]
    procedure GetEntryAddendaCount() EntryAddendaCt: Integer
    begin
        EntryAddendaCt := EntryAddendaCount;
    end;

    [Scope('OnPrem')]
    procedure SetEntryAddendaCount(EntryAddendaCt: Integer)
    begin
        EntryAddendaCount := EntryAddendaCt;
    end;

    [Scope('OnPrem')]
    procedure GetNoOfRec() NoOfRec: Integer
    begin
        NoOfRec := NoOfRecords;
    end;

    [Scope('OnPrem')]
    procedure SetNoOfRec(NoOfRec: Integer)
    begin
        NoOfRecords := NoOfRec;
    end;

    [Scope('OnPrem')]
    procedure GetNoOfCustInfoRec() NoOfCustInfoRec: Integer
    begin
        NoOfCustInfoRec := NumberOfCustInfoRec;
    end;

    [Scope('OnPrem')]
    procedure SetNoOfCustInfoRec(NoOfCustInfoRec: Integer)
    begin
        NumberOfCustInfoRec := NoOfCustInfoRec;
    end;

    [Scope('OnPrem')]
    procedure GetTransactions() Trxs: Integer
    begin
        Trxs := Transactions;
    end;

    [Scope('OnPrem')]
    procedure SetTransactions(Trxs: Integer)
    begin
        Transactions := Trxs;
    end;

    [Scope('OnPrem')]
    procedure GetPaymentAmt(TempEFTExportWorkset: Record "EFT Export Workset" temporary): Decimal
    begin
        if TempEFTExportWorkset."Account Type" = TempEFTExportWorkset."Account Type"::"Bank Account" then
            exit(TempEFTExportWorkset."Amount (LCY)");

        exit(-TempEFTExportWorkset."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure GetDataExchEntryNo() DataExchEntryNumber: Integer
    begin
        DataExchEntryNumber := DataExchEntryNo;
    end;

    [Scope('OnPrem')]
    procedure SetDataExchEntryNo(DataExchEntryNumber: Integer)
    begin
        DataExchEntryNo := DataExchEntryNumber;
    end;

    [Scope('OnPrem')]
    procedure GetParentDefCode() ParentDefinitionCode: Code[20]
    begin
        ParentDefinitionCode := ParentDefCode;
    end;

    [Scope('OnPrem')]
    procedure SetParentDefCode(ParentDefinitionCode: Code[20])
    begin
        ParentDefCode := ParentDefinitionCode;
    end;

    [Scope('OnPrem')]
    procedure GetParentBoolean() IsAParent: Boolean
    begin
        IsAParent := IsParent;
    end;

    [Scope('OnPrem')]
    procedure SetParentBoolean(SetParent: Boolean)
    begin
        IsParent := SetParent;
    end;

    [Scope('OnPrem')]
    procedure GetIATFileCreated() IATIsCreated: Boolean
    begin
        IATIsCreated := IATFileIsCreated;
    end;

    [Scope('OnPrem')]
    procedure SetIATFileCreated(SetIATFile: Boolean)
    begin
        IATFileIsCreated := SetIATFile;
    end;

    [Scope('OnPrem')]
    procedure GetEFTFileCreated() EFTIsCreated: Boolean
    begin
        EFTIsCreated := EFTFileIsCreated;
    end;

    [Scope('OnPrem')]
    procedure SetEFTFileCreated(SetEFTFile: Boolean)
    begin
        EFTFileIsCreated := SetEFTFile;
    end;

    [Scope('OnPrem')]
    procedure GetFileCreationNumber(): Integer
    begin
        exit(FileCreationNumber);
    end;

    [Scope('OnPrem')]
    procedure SetFileCreationNumber(NewFileCreationNumber: Integer)
    begin
        FileCreationNumber := NewFileCreationNumber;
        IsFileCreationNumber := true;
    end;

    [Scope('OnPrem')]
    procedure IsSetFileCreationNumber(): Boolean
    begin
        exit(IsFileCreationNumber);
    end;
}

