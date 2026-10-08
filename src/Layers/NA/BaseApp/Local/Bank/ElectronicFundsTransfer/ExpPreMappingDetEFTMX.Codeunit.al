// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;

codeunit 10339 "Exp. Pre-Mapping Det EFT MX"
{
    Permissions = TableData "EFT Export" = rimd;
    TableNo = "EFT Export Workset";

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure PrepareEFTDetails(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; DataExchangeEntryNo: Integer; LineNo: Integer; var DetailArray: array[100] of Integer; var ExportEFTCecoban: Codeunit "Export EFT (Cecoban)"; DataExchLineDefCode: Code[20])
    var
        BankAccount: Record "Bank Account";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        DetailCount: Integer;
    begin
        DetailCount := 0;
        DetailCount := DetailCount + 1;
        DetailArray[DetailCount] := DataExchangeEntryNo;
        LineNo += 1;
        PrepareEFTDetail(DataExchangeEntryNo, DataExchLineDefCode);
        BankAccount.Get(TempEFTExportWorkset."Bank Account No.");
        ExportEFTCecoban.ExportElectronicPayment(
          TempEFTExportWorkset, EFTValues.GetPaymentAmt(TempEFTExportWorkset),
          TempEFTExportWorkset.UserSettleDate, DataExchangeEntryNo, DataExchLineDefCode);
        GenerateEFT.UpdateEFTExport(TempEFTExportWorkset);
        DataExchangeEntryNo := DataExchangeEntryNo + 1;
    end;

    local procedure PrepareEFTDetail(DataExchangeEntryNo: Integer; DataExchLineDefCode: Code[20])
    var
        ACHCecobanDetail: Record "ACH Cecoban Detail";
    begin
        ACHCecobanDetail.Init();
        ACHCecobanDetail."Data Exch. Entry No." := DataExchangeEntryNo;
        ACHCecobanDetail."Data Exch. Line Def Code" := DataExchLineDefCode;
        ACHCecobanDetail.Insert(true);
    end;
}

