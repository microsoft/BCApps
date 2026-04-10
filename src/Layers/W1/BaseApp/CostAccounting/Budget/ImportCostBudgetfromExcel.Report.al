// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using System.IO;

report 1143 "Import Cost Budget from Excel"
{
    Caption = 'Import Cost Budget from Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem(TempCostBudgetBuffer; "Cost Budget Buffer")
        {
            DataItemTableView = sorting("Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
            UseTemporary = true;

            trigger OnAfterGetRecord()
            begin
                RecNo := RecNo + 1;
                if RecNo = 1 then begin
                    Window.Open(
                      Text028 +
                      '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
                    TotalRecNo := Count;
                    Window.Update(1, 0);
                end;
                if ImportOption = ImportOption::"Replace entries" then begin
                    CostBudgetEntry.SetRange("Cost Type No.", "Cost Type No.");
                    CostBudgetEntry.SetRange(Date, Date);
                    CostBudgetEntry.SetFilter("Entry No.", '<=%1', LastEntryNoBeforeImport);
                    if not CostBudgetEntry.IsEmpty() then
                        CostBudgetEntry.DeleteAll(true);
                end;

                if Amount = 0 then
                    CurrReport.Skip();
                if not IsLineTypeCostType("Cost Type No.") then
                    CurrReport.Skip();
                CostBudgetEntry.Init();
                CostBudgetEntry."Entry No." := EntryNo;
                CostBudgetEntry."Budget Name" := ToCostBudgetName;
                CostBudgetEntry."Cost Type No." := "Cost Type No.";
                CostBudgetEntry.Date := Date;
                CostBudgetEntry.Amount := Round(Amount);
                CostBudgetEntry.Description := Description;
                CostBudgetEntry."Cost Center Code" := "Cost Center Code";
                CostBudgetEntry."Cost Object Code" := "Cost Object Code";
                CostBudgetEntry.Insert(true);
                EntryNo := EntryNo + 1;
                Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
            end;

            trigger OnPostDataItem()
            begin
                if RecNo > 0 then
                    Message(Text004, CostBudgetEntry.TableCaption(), RecNo);
            end;

            trigger OnPreDataItem()
            begin
                RecNo := 0;

                if not CostBudgetName.Get(ToCostBudgetName) then begin
                    if not Confirm(Text001, false, CostBudgetName.TableCaption(), ToCostBudgetName) then
                        CurrReport.Break();
                    CostBudgetName.Name := ToCostBudgetName;
                    OnPreDataItemOnBeforeCostBudgetNameInsert(CostBudgetName);
                    CostBudgetName.Insert();
                end else
                    if not Confirm(Text003, false, LowerCase(Format(SelectStr(ImportOption + 1, Text027))), ToCostBudgetName) then
                        CurrReport.Break();

                LastEntryNoBeforeImport := CostBudgetEntry3.GetLastEntryNo();
                EntryNo := LastEntryNoBeforeImport + 1
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ToCostBudgetName; ToCostBudgetName)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Budget Name';
                        TableRelation = "Cost Budget Name";
                        ToolTip = 'Specifies the name of the budget.';
                    }
                    field(ImportOption; ImportOption)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Option';
                        OptionCaption = 'Replace entries,Add entries';
                        ToolTip = 'Specifies whether the budget entries are added from Excel to budget entries that are currently in cost accounting, or whether the entries are replaced in cost accounting with the budget entries from Excel.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description of what you are importing from Excel.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            FileMgt: Codeunit "File Management";
        begin
            if CloseAction = ACTION::OK then begin
                ServerFileName := FileMgt.UploadFile(Text006, ExcelFileExtensionTok);
                if ServerFileName = '' then
                    exit(false);

                SheetName := ExcelBuffer.SelectSheetsName(ServerFileName);
                if SheetName = '' then
                    exit(false);
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelBuffer.DeleteAll();
        TempCostBudgetBuffer.DeleteAll();
    end;

    trigger OnPreReport()
    begin
        if ToCostBudgetName = '' then
            Error(Text000);

        if CostType.Find('-') then
            repeat
                TempCostType.Init();
                TempCostType := CostType;
                TempCostType.Insert();
            until CostType.Next() = 0;

        ExcelBuffer.LockTable();
        CostBudgetEntry.SetRange("Budget Name", ToCostBudgetName);
        if not CostBudgetName.Get(ToCostBudgetName) then
            Clear(CostBudgetName);

        CostAccSetup.Get();

        ExcelBuffer.OpenBook(ServerFileName, SheetName);
        ExcelBuffer.ReadSheet();

        AnalyzeData();
    end;

    var
        ExcelBuffer: Record "Excel Buffer";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostAccSetup: Record "Cost Accounting Setup";
        CostType: Record "Cost Type";
        TempCostType: Record "Cost Type" temporary;
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry3: Record "Cost Budget Entry";
        Window: Dialog;
        ServerFileName: Text;
        SheetName: Text[250];
        ToCostBudgetName: Code[10];
        EntryNo: Integer;
        LastEntryNoBeforeImport: Integer;
        TotalRecNo: Integer;
        RecNo: Integer;
        Description: Text[50];
        ImportOption: Option "Replace entries","Add entries";
#pragma warning disable AA0074
        Text000: Label 'You must specify a budget name to which to import.';
#pragma warning disable AA0470
        Text001: Label 'Do you want to create %1 with the name %2?';
        Text003: Label 'Are you sure that you want to %1 for the budget name %2?';
        Text004: Label '%1 table has been successfully updated with %2 entries.';
#pragma warning restore AA0470
        Text006: Label 'Import Excel File';
        Text007: Label 'Analyzing Data...\\';
        Text009: Label 'Cost Type No';
#pragma warning disable AA0470
        Text011: Label 'The text %1 can only be specified once in the Excel worksheet.';
#pragma warning restore AA0470
        Text014: Label 'Date';
        Text017: Label 'Cost Center Code';
        Text018: Label 'Cost Object Code';
#pragma warning disable AA0470
        Text019: Label 'You cannot import %1 value, which is not available in the %2 table.';
#pragma warning restore AA0470
        Text023: Label 'You cannot import the same information more than once.';
        Text025: Label 'Cost Types have not been found in the Excel worksheet.';
        Text026: Label 'Dates have not been recognized in the Excel worksheet.';
        Text027: Label 'Replace entries,Add entries';
        Text028: Label 'Importing from Excel worksheet';
#pragma warning restore AA0074
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;

    local procedure AnalyzeData()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempCostBudgetBuffer2: Record "Cost Budget Buffer" temporary;
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        HeaderRowNo: Integer;
        TestDateTime: DateTime;
        OldRowNo: Integer;
    begin
        Window.Open(
          Text007 +
          '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
        Window.Update(1, 0);
        TotalRecNo := ExcelBuffer.Count();
        RecNo := 0;
        TempCostBudgetBuffer2.Init();
        TempCostBudgetBuffer.DeleteAll();

        HeaderRowNo := 0;
        OldRowNo := 0;

        if ExcelBuffer.Find('-') then
            repeat
                RecNo := RecNo + 1;
                Window.Update(1, Round(RecNo / TotalRecNo * 10000, 1));
                case true of
                    StrPos(UpperCase(ExcelBuffer."Cell Value as Text"), UpperCase(Text009)) <> 0:
                        if HeaderRowNo = 0 then begin
                            HeaderRowNo := ExcelBuffer."Row No.";
                            InsertTempExcelBuffer(ExcelBuffer, TempExcelBuffer, Text009);
                        end else
                            Error(Text011, Text009);
                    StrPos(UpperCase(ExcelBuffer."Cell Value as Text"), UpperCase(Text017)) <> 0:
                        if HeaderRowNo = ExcelBuffer."Row No." then
                            InsertTempExcelBuffer(ExcelBuffer, TempExcelBuffer, Text017)
                        else
                            if (HeaderRowNo < ExcelBuffer."Row No.") and (HeaderRowNo <> 0) then
                                Error(Text011, Text017);
                    StrPos(UpperCase(ExcelBuffer."Cell Value as Text"), UpperCase(Text018)) <> 0:
                        if HeaderRowNo = ExcelBuffer."Row No." then
                            InsertTempExcelBuffer(ExcelBuffer, TempExcelBuffer, Text018)
                        else
                            if (HeaderRowNo < ExcelBuffer."Row No.") and (HeaderRowNo <> 0) then
                                Error(Text011, Text018);
                    ExcelBuffer."Row No." = HeaderRowNo:
                        begin
                            TempExcelBuffer := ExcelBuffer;
                            if Evaluate(TestDateTime, TempExcelBuffer."Cell Value as Text") then begin
                                TempExcelBuffer."Cell Value as Text" := Format(DT2Date(TestDateTime));
                                TempExcelBuffer.Comment := Text014;
                                TempExcelBuffer.Insert();
                            end;
                        end;
                    (ExcelBuffer."Row No." > HeaderRowNo) and (HeaderRowNo > 0):
                        begin
                            if ExcelBuffer."Row No." <> OldRowNo then begin
                                OldRowNo := ExcelBuffer."Row No.";
                                Clear(TempCostBudgetBuffer2);
                            end;
                            TempExcelBuffer.SetRange("Column No.", ExcelBuffer."Column No.");
                            if TempExcelBuffer.Find('-') then
                                case TempExcelBuffer.Comment of
                                    Text009:
                                        begin
                                            TempCostType.SetRange(
                                              "No.",
                                              CopyStr(
                                                ExcelBuffer."Cell Value as Text",
                                                1, MaxStrLen(TempCostBudgetBuffer2."Cost Type No.")));
                                            if TempCostType.FindFirst() then
                                                TempCostBudgetBuffer2."Cost Type No." :=
                                                  CopyStr(
                                                    ExcelBuffer."Cell Value as Text",
                                                    1, MaxStrLen(TempCostBudgetBuffer2."Cost Type No."))
                                            else
                                                TempCostBudgetBuffer2."Cost Type No." := '';
                                        end;
                                    Text017:
                                        if CostCenter.Get(CopyStr(
                                                ExcelBuffer."Cell Value as Text", 1, MaxStrLen(TempCostBudgetBuffer2."Cost Center Code")))
                                        then
                                            TempCostBudgetBuffer2."Cost Center Code" := CostCenter.Code
                                        else
                                            Error(Text019, TempCostBudgetBuffer2.FieldCaption("Cost Center Code"), CostCenter.TableCaption());
                                    Text018:
                                        if CostObject.Get(CopyStr(
                                                ExcelBuffer."Cell Value as Text", 1, MaxStrLen(TempCostBudgetBuffer2."Cost Object Code")))
                                        then
                                            TempCostBudgetBuffer2."Cost Object Code" := CostObject.Code
                                        else
                                            Error(Text019, TempCostBudgetBuffer2.FieldCaption("Cost Object Code"), CostObject.TableCaption());
                                    Text014:
                                        if TempCostBudgetBuffer2."Cost Type No." <> '' then begin
                                            TempCostBudgetBuffer := TempCostBudgetBuffer2;
                                            Evaluate(TempCostBudgetBuffer.Date, TempExcelBuffer."Cell Value as Text");
                                            Evaluate(TempCostBudgetBuffer.Amount, ExcelBuffer."Cell Value as Text");
                                            if not TempCostBudgetBuffer.Find('=') then
                                                TempCostBudgetBuffer.Insert()
                                            else
                                                Error(Text023);
                                        end;
                                end;
                        end;
                end;
            until ExcelBuffer.Next() = 0;

        Window.Close();
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange(Comment, Text009);
        if not TempExcelBuffer.FindFirst() then
            Error(Text025);
        TempExcelBuffer.SetRange(Comment, Text014);
        if not TempExcelBuffer.FindFirst() then
            Error(Text026);
    end;

    procedure SetGLBudgetName(NewToCostBudgetName: Code[10])
    begin
        ToCostBudgetName := NewToCostBudgetName;
    end;

    local procedure IsLineTypeCostType(CostTypeNo: Code[20]): Boolean
    var
        CostType: Record "Cost Type";
    begin
        if not CostType.Get(CostTypeNo) then
            exit(false);
        exit(CostType.Type = CostType.Type::"Cost Type");
    end;

    local procedure InsertTempExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; var TempExcelBuffer: Record "Excel Buffer" temporary; Text: Text[250])
    begin
        TempExcelBuffer := ExcelBuffer;
        TempExcelBuffer.Comment := Text;
        TempExcelBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemOnBeforeCostBudgetNameInsert(var CostBudgetName: Record "Cost Budget Name")
    begin
    end;
}

