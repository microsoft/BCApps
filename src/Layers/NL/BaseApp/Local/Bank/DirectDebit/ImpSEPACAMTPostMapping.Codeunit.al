// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Statement;
using System.IO;

codeunit 11407 "Imp. SEPA CAMT Post-Mapping"
{
    TableNo = "CBG Statement Line";

    trigger OnRun()
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        // Insert additional entry information
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/AddtlNtryInf',
          CBGStatementLineAddInfo."Information Type"::"Description and Sundries", true, true);

        // Unstructured text
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RmtInf/Ustrd',
          CBGStatementLineAddInfo."Information Type"::"Description and Sundries", true, false);

        // Related party bank account (IBAN or Local)
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/DbtrAcct/Id/IBAN',
          CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/CdtrAcct/Id/IBAN',
          CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/DbtrAcct/Id/Othr/Id',
          CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/CdtrAcct/Id/Othr/Id',
          CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account", false, false);

        // Related party postal address
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/AdrLine',
          CBGStatementLineAddInfo."Information Type"::"Address Acct. Holder", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/PstlAdr/AdrLine',
          CBGStatementLineAddInfo."Information Type"::"Address Acct. Holder", false, false);

        // Related party city
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/TwnNm',
          CBGStatementLineAddInfo."Information Type"::"City Acct. Holder", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/PstlAdr/TwnNm',
          CBGStatementLineAddInfo."Information Type"::"City Acct. Holder", false, false);

        // Related party name
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/Nm',
          CBGStatementLineAddInfo."Information Type"::"Name Acct. Holder", false, false);

        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/Nm',
          CBGStatementLineAddInfo."Information Type"::"Name Acct. Holder", false, false);

        // Payment Identification
        InsertRelatedPartyInformation(Rec, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId',
          CBGStatementLineAddInfo."Information Type"::"Payment Identification", false, false);
    end;

    local procedure InsertRelatedPartyInformation(CurrentCBGStatementLine: Record "CBG Statement Line"; XmlPath: Text; InformationType: Enum "CBG Statement Information Type"; Multiline: Boolean; OverrideDescription: Boolean)
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchLineDef: Record "Data Exch. Line Def";
        CBGStatementLine: Record "CBG Statement Line";
        ImpBankTransDataUpdates: Codeunit "Imp. Bank Trans. Data Updates";
    begin
        DataExch.Get(CurrentCBGStatementLine."Data Exch. Entry No.");
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindLast();

        // Find entries
        DataExchField.SetRange("Data Exch. No.", CurrentCBGStatementLine."Data Exch. Entry No.");
        DataExchField.SetRange(
          "Column No.", ImpBankTransDataUpdates.FindColumnNoOfPath(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, XmlPath));
        CBGStatementLine.SetRange("Data Exch. Entry No.", CurrentCBGStatementLine."Data Exch. Entry No.");
        if DataExchField.FindSet() then
            repeat
                // Insert info into CBG Statement Line Add. Info.
                CBGStatementLine.SetRange("Data Exch. Line No.", DataExchField."Line No.");
                if CBGStatementLine.FindFirst() then
                    if Multiline then
                        UpdateCBGStatementLine(CBGStatementLine, DataExchField.Value, OverrideDescription)
                    else
                        InsertCBGStatementLineAddInfo(CBGStatementLine, DataExchField.Value, InformationType);
            until DataExchField.Next() = 0;
    end;

    local procedure UpdateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; Value: Text; OverrideDescription: Boolean)
    begin
        if OverrideDescription or (CBGStatementLine.Description = '') then begin
            CBGStatementLine.Validate(Description, CopyStr(Value, 1, MaxStrLen(CBGStatementLine.Description)));
            CBGStatementLine.Modify(true);
        end;
        InsertCBGStatementLineAddInfoMultiline(CBGStatementLine, Value);
    end;

    local procedure InsertCBGStatementLineAddInfo(ReferenceCBGStatementLine: Record "CBG Statement Line"; AddInfo: Text; InformationType: Enum "CBG Statement Information Type")
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        if AddInfo = '' then
            exit;
        PrepareCBGStatementLineAddInfo(CBGStatementLineAddInfo, ReferenceCBGStatementLine);
        CBGStatementLineAddInfo.Description := CopyStr(AddInfo, 1, MaxStrLen(CBGStatementLineAddInfo.Description));
        CBGStatementLineAddInfo."Information Type" := InformationType;
        CBGStatementLineAddInfo.Insert(true);
    end;

    local procedure InsertCBGStatementLineAddInfoMultiline(ReferenceCBGStatementLine: Record "CBG Statement Line"; AddInfo: Text)
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        if AddInfo = '' then
            exit;
        PrepareCBGStatementLineAddInfo(CBGStatementLineAddInfo, ReferenceCBGStatementLine);
        CBGStatementLineAddInfo.Description := CopyStr(AddInfo, 1, MaxStrLen(CBGStatementLineAddInfo.Description));
        CBGStatementLineAddInfo.Insert(true);
        InsertCBGStatementLineAddInfoMultiline(
          ReferenceCBGStatementLine, CopyStr(AddInfo, MaxStrLen(CBGStatementLineAddInfo.Description) + 1));
    end;

    local procedure PrepareCBGStatementLineAddInfo(var CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info."; ReferenceCBGStatementLine: Record "CBG Statement Line")
    begin
        CBGStatementLineAddInfo.SetRange("Journal Template Name", ReferenceCBGStatementLine."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", ReferenceCBGStatementLine."No.");
        CBGStatementLineAddInfo.SetRange("CBG Statement Line No.", ReferenceCBGStatementLine."Line No.");
        if CBGStatementLineAddInfo.FindLast() then
            CBGStatementLineAddInfo."Line No." += 10000
        else
            CBGStatementLineAddInfo."Line No." := 10000;

        CBGStatementLineAddInfo.Init();
        CBGStatementLineAddInfo."Journal Template Name" := ReferenceCBGStatementLine."Journal Template Name";
        CBGStatementLineAddInfo."CBG Statement No." := ReferenceCBGStatementLine."No.";
        CBGStatementLineAddInfo."CBG Statement Line No." := ReferenceCBGStatementLine."Line No.";
    end;
}

