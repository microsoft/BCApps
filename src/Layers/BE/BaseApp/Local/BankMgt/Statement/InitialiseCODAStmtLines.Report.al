// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

report 2000058 "Initialise CODA Stmt. Lines"
{
    Caption = 'Initialise CODA Stmt. Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem(CodBankStmtSrcLine; "CODA Statement Source Line")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.", "Line No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";

            trigger OnAfterGetRecord()
            begin
                if (PrevCodBankStmtSrcLine."Bank Account No." <> "Bank Account No.") and
                   (PrevCodBankStmtSrcLine."Statement No." <> "Statement No.") and
                   (PrevCodBankStmtSrcLine."Line No." <> "Line No.")
                then begin
                    PrevCodBankStmtSrcLine := CodBankStmtSrcLine;
                    Skip := false;
                end;

                if Skip = false then begin
                    Window.Update(1, StrSubstNo(Text002, "Bank Account No."));
                    case ID of
                        ID::Header:
                            begin
                                CodBankStmtSrcLine2.Reset();
                                CodBankStmtSrcLine2.CopyFilters(CodBankStmtSrcLine);
                                CodBankStmtSrcLine2.SetRange("Statement No.", "Statement No.");
                                TotRecords := CodBankStmtSrcLine2.Count();
                                LineNo := 0;
                                CodaTrans.UpdateBankStatement(CodBankStmtSrcLine, CodBankStmt);
                            end;
                        ID::"Old Balance", ID::"New Balance":
                            begin
                                Skip := not CodaTrans.UpdateBankStatement(CodBankStmtSrcLine, CodBankStmt);
                                if Skip and (GetFilter("Statement No.") <> '') then
                                    if GetRangeMin("Statement No.") = GetRangeMax("Statement No.") then
                                        CurrReport.Break();
                                Window.Update(2, "Statement No.");
                                if ID = ID::"Old Balance" then begin
                                    CodBankStmtSrcLine2.Reset();
                                    CodBankStmtSrcLine2.CopyFilters(CodBankStmtSrcLine);
                                    CodBankStmtSrcLine2.SetRange("Statement No.", "Statement No.");
                                    TotRecords := CodBankStmtSrcLine2.Count();
                                    LineNo := 0
                                end;
                            end;
                        ID::Movement, ID::Information, ID::"Free Message":
                            CodaTrans.InsertBankStatementLine(CodBankStmtSrcLine, CodBankStmtLine);
                    end;
                    Modify();
                end else
                    Window.Update(1, StrSubstNo(Text003, "Bank Account No."));

                LineNo := LineNo + 1;
                Window.Update(3, LineNo);
                Window.Update(4, Round(LineNo / TotRecords * 10000, 1));
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                CodBankStmt.Reset();
                Skip := false;
                Window.Open(
                  '#1#################################\\' +
                  Text000 +
                  Text001);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'Statement No.         #2######\';
        Text001: Label 'Line                  #3###### @4@@@@@@@@@@@@@\';
        Text002: Label 'Transferring %1 ...';
        Text003: Label 'Skipping %1 ...';
        CodBankStmt: Record "CODA Statement";
        CodBankStmtLine: Record "CODA Statement Line";
        CodBankStmtSrcLine2: Record "CODA Statement Source Line";
        PrevCodBankStmtSrcLine: Record "CODA Statement Source Line";
        CodaTrans: Codeunit "CODA Write Statements";
        Window: Dialog;
        Skip: Boolean;
        LineNo: Integer;
        TotRecords: Integer;
}

