// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

report 81 "Import Budget from Excel"
{
    Caption = 'Import Budget from Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem(BudgetBuf; "Budget Buffer")
        {
            UseTemporary = true;
            DataItemTableView = sorting("G/L Account No.", "Dimension Value Code 1", "Dimension Value Code 2", "Dimension Value Code 3", "Dimension Value Code 4", "Dimension Value Code 5", "Dimension Value Code 6", "Dimension Value Code 7", "Dimension Value Code 8", Date);

            trigger OnAfterGetRecord()
            begin
                RecNo := RecNo + 1;
                if (RecNo mod 100) = 0 then
                    Window.Update(1, 100 * RecNo div TotalRecNo);

                if ImportOption = ImportOption::"Replace entries" then begin
                    GLBudgetEntry.SetRange("G/L Account No.", "G/L Account No.");
                    GLBudgetEntry.SetRange(Date, Date);
                    GLBudgetEntry.SetFilter("Entry No.", '<=%1', LastEntryNoBeforeImport);
                    OnBudgetBufOnAfterGetRecordOnBeforeSetDimFilters(GLBudgetEntry);
                    if DimCode[1] <> '' then
                        SetBudgetDimFilter(DimCode[1], "Dimension Value Code 1", GLBudgetEntry);
                    if DimCode[2] <> '' then
                        SetBudgetDimFilter(DimCode[2], "Dimension Value Code 2", GLBudgetEntry);
                    if DimCode[3] <> '' then
                        SetBudgetDimFilter(DimCode[3], "Dimension Value Code 3", GLBudgetEntry);
                    if DimCode[4] <> '' then
                        SetBudgetDimFilter(DimCode[4], "Dimension Value Code 4", GLBudgetEntry);
                    if DimCode[5] <> '' then
                        SetBudgetDimFilter(DimCode[5], "Dimension Value Code 5", GLBudgetEntry);
                    if DimCode[6] <> '' then
                        SetBudgetDimFilter(DimCode[6], "Dimension Value Code 6", GLBudgetEntry);
                    if DimCode[7] <> '' then
                        SetBudgetDimFilter(DimCode[7], "Dimension Value Code 7", GLBudgetEntry);
                    if DimCode[8] <> '' then
                        SetBudgetDimFilter(DimCode[8], "Dimension Value Code 8", GLBudgetEntry);
                    if not GLBudgetEntry.IsEmpty() then
                        GLBudgetEntry.DeleteAll(true);
                end;

                if Amount = 0 then
                    CurrReport.Skip();
                if not IsPostingAccount("G/L Account No.") then
                    CurrReport.Skip();
                GLBudgetEntry.Init();
                GLBudgetEntry."Entry No." := EntryNo;
                GLBudgetEntry."Budget Name" := ToGLBudgetName;
                GLBudgetEntry."G/L Account No." := "G/L Account No.";
                GLBudgetEntry.Date := Date;
                GLBudgetEntry.Amount := Round(Amount);
                GLBudgetEntry.Description := Description;

                // Clear any entries in the temporary dimension set entry table
                if not TempDimSetEntry.IsEmpty() then
                    TempDimSetEntry.DeleteAll(true);

                InsertGLBudgetDimensions(BudgetBuf);
                GLBudgetEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                OnBudgetBufOnAfterGetRecordOnBeforeGLBudgetEntryInsert(GLBudgetEntry);
                GLBudgetEntry.Insert(true);
                EntryNo := EntryNo + 1;
            end;

            trigger OnPostDataItem()
            begin
                if RecNo > 0 then
                    Message(Text004, GLBudgetEntry.TableCaption(), RecNo);

                if ImportOption = ImportOption::"Replace entries" then begin
                    AnalysisView.SetRange("Include Budgets", true);
                    if AnalysisView.FindSet(true) then
                        repeat
                            AnalysisView.AnalysisviewBudgetReset();
                            AnalysisView.Modify();
                        until AnalysisView.Next() = 0;
                end;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                RecNo := 0;

                if not GLBudgetName.Get(ToGLBudgetName) then begin
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text001, GLBudgetName.TableCaption(), ToGLBudgetName), true)
                    then
                        CurrReport.Break();
                    GLBudgetName.Name := ToGLBudgetName;
                    GLBudgetName.Insert();
                end else begin
                    IsHandled := false;
                    OnBeforeCheckGLBudgetNameBlacked(GLBudgetName, IsHandled);
                    if not IsHandled then
                        if GLBudgetName.Blocked then begin
                            Message(Text002, GLBudgetEntry.FieldCaption("Budget Name"), ToGLBudgetName);
                            CurrReport.Break();
                        end;
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text003, LowerCase(Format(SelectStr(ImportOption + 1, Text027))), ToGLBudgetName), true)
                    then
                        CurrReport.Break();
                end;

                IsHandled := false;
                OnBeforeGetLastEntryNoBeforeImport(GLBudgetEntry3, LastEntryNoBeforeImport, EntryNo, IsHandled);
                if not IsHandled then begin
                    GLBudgetEntry3.LockTable();
                    LastEntryNoBeforeImport := GLBudgetEntry3.GetLastEntryNo();
                    EntryNo := LastEntryNoBeforeImport + 1;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ToGLBudgetName; ToGLBudgetName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Name';
                        TableRelation = "G/L Budget Name";
                        ToolTip = 'Specifies the name of the budget.';
                    }
                    field(ImportOption; ImportOption)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Option';
                        OptionCaption = 'Replace entries,Add entries';
                        ToolTip = 'Specifies if the budget entries are added from Excel to budget entries that are currently in the system or are replaced in Business Central with the budget entries from Excel.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the imported budget entries, so that the entries can be easily identified among other budget entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Description := Text005 + Format(WorkDate());
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            FileMgt: Codeunit "File Management";
        begin
            if CloseAction = ACTION::OK then begin
                if ServerFileName = '' then
                    ServerFileName := FileMgt.UploadFile(Text006, ExcelFileExtensionTok);
                if ServerFileName = '' then
                    exit(false);
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Window.Close();
        TempGlobalExcelBuf.DeleteAll();
        BudgetBuf.DeleteAll();
    end;

    trigger OnPreReport()
    var
        BusUnit: Record "Business Unit";
    begin
        OnBeforeOnPreReport(TempDim);
        if ToGLBudgetName = '' then
            Error(Text000);

        if SheetName = '' then
            SheetName := TempGlobalExcelBuf.SelectSheetsName(ServerFileName);

        BusUnitDimCode := 'BUSINESSUNIT_TAB220';
        TempDim.Init();
        TempDim.Code := BusUnitDimCode;
        TempDim."Code Caption" := BusUnit.TableCaption();
        TempDim.Insert();

        if Dim.Find('-') then
            repeat
                TempDim.Init();
                TempDim := Dim;
                TempDim."Code Caption" := TempDim."Code Caption";
                if TempDim."Code Caption" = '' then
                    Error(DimensionsNeedsCodeCaptionErr);
                TempDim.Insert();
            until Dim.Next() = 0;

        if GLAcc.Find('-') then
            repeat
                TempGLAcc.Init();
                TempGLAcc := GLAcc;
                TempGLAcc.Insert();
            until GLAcc.Next() = 0;

        GLBudgetEntry.SetRange("Budget Name", ToGLBudgetName);
        if not GLBudgetName.Get(ToGLBudgetName) then
            Clear(GLBudgetName);

        GLSetup.Get();
        GlobalDim1Code := GLSetup."Global Dimension 1 Code";
        GlobalDim2Code := GLSetup."Global Dimension 2 Code";
        BudgetDim1Code := GLBudgetName."Budget Dimension 1 Code";
        BudgetDim2Code := GLBudgetName."Budget Dimension 2 Code";
        BudgetDim3Code := GLBudgetName."Budget Dimension 3 Code";
        BudgetDim4Code := GLBudgetName."Budget Dimension 4 Code";

        TempGlobalExcelBuf.OpenBook(ServerFileName, SheetName);
        TempGlobalExcelBuf.SetReadDateTimeInUtcDate(true);
        TempGlobalExcelBuf.ReadSheet();
        TempGlobalExcelBuf.SetReadDateTimeInUtcDate(false);

        AnalyzeData();

        TotalRecNo := BudgetBuf.Count();
        Window.Open(InsertingEntriesLbl);
        Window.Update(1, 0);
    end;

    var
        TempGlobalExcelBuf: Record "Excel Buffer" temporary;
        Dim: Record Dimension;
        TempDim: Record Dimension temporary;
        GLBudgetEntry: Record "G/L Budget Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        TempGLAcc: Record "G/L Account" temporary;
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry3: Record "G/L Budget Entry";
        AnalysisView: Record "Analysis View";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        ServerFileName: Text;
        SheetName: Text[250];
        ToGLBudgetName: Code[10];
        DimCode: array[8] of Code[20];
        EntryNo: Integer;
        LastEntryNoBeforeImport: Integer;
        GlobalDim1Code: Code[20];
        GlobalDim2Code: Code[20];
        TotalRecNo: Integer;
        RecNo: Integer;
        Description: Text[50];
        BusUnitDimCode: Code[20];
        BudgetDim1Code: Code[20];
        BudgetDim2Code: Code[20];
        BudgetDim3Code: Code[20];
        BudgetDim4Code: Code[20];
        ImportOption: Option "Replace entries","Add entries";

#pragma warning disable AA0074
        Text000: Label 'You must specify a budget name to import to.';
#pragma warning disable AA0470
        Text001: Label 'Do you want to create a %1 with the name %2?';
        Text002: Label '%1 %2 is blocked. You cannot import entries.';
        Text003: Label 'Are you sure that you want to %1 for the budget name %2?';
        Text004: Label '%1 table has been successfully updated with %2 entries.';
#pragma warning restore AA0470
        Text005: Label 'Imported from Excel ';
        Text006: Label 'Import Excel File';
        Text007: Label 'Analyzing Data % #1###', Comment = 'Progress indicator. % #1### just means %';
        Text008: Label 'You cannot specify more than 8 dimensions in your Excel worksheet.';
        Text010: Label 'G/L Account No.';
        Text011: Label 'The text G/L Account No. can only be specified once in the Excel worksheet.';
#pragma warning restore AA0074
        DimensionValueCodeEqualToDimensionCodeTelemetryMsg: Label 'Detected dimension value code in the Excel budget that is equal to the code of a dimension.', Locked = true;
        DimensionsNeedsCodeCaptionErr: Label 'To be able to import Budget from Excel. Dimensions need a Code Caption Please specify Code Caption for Dimension %1.', Comment = '%1 is a dimension value';
        TelemetryCategoryTxt: Label 'AL Import Budget', Locked = true;
#pragma warning disable AA0074
        Text013: Label 'Dimension', Locked = true;
        Text014: Label 'Date';
        Text015: Label 'Dimension1', Locked = true;
        Text016: Label 'Dimension2', Locked = true;
        Text017: Label 'Dimension3', Locked = true;
        Text018: Label 'Dimension4', Locked = true;
        Text019: Label 'Dimension5', Locked = true;
        Text020: Label 'Dimension6', Locked = true;
        Text021: Label 'Dimension7', Locked = true;
        Text022: Label 'Dimension8', Locked = true;
        Text023: Label 'You cannot import the same information twice.\';
        Text024: Label 'The combination G/L Account No. - Dimensions - Date must be unique: %1', Comment = '%1 - Record ID';
        Text025: Label 'G/L Accounts have not been found in the Excel worksheet.';
        Text026: Label 'Dates have not been recognized in the Excel worksheet.';
#pragma warning restore AA0074
        TheUsedDimensionValueAreAlsoUsedAsACaptionForADimensionErr: Label 'The used Dimension value %1 are also used as a caption for a Dimension.', Comment = '%1 is a dimension value';
#pragma warning disable AA0074
        Text027: Label 'Replace Entries,Add Entries';
#pragma warning disable AA0470
        Text028: Label 'A filter has been used on the %1 when the budget was exported. When a filter on a dimension has been used, a column with the same dimension must be present in the worksheet imported. The column in the worksheet must specify the dimension value codes the program should use when importing the budget.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InsertingEntriesLbl: Label 'Inserting new entries % #1###', Comment = 'Progress indicator. % #1### just means %';
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;

    local procedure AnalyzeData()
    var
        TempExcelBuf: Record "Excel Buffer" temporary;
        TempLocalBudgetBuf: Record "Budget Buffer" temporary;
        HeaderRowNo: Integer;
        CountDim: Integer;
        TestDateTime: DateTime;
        OldRowNo: Integer;
        DimRowNo: Integer;
        DimCode3: Code[20];
        IsHandled: Boolean;
    begin
        Window.Open(Text007);
        Window.Update(1, 0);
        TotalRecNo := TempGlobalExcelBuf.Count();
        RecNo := 0;
        CountDim := 0;
        BudgetBuf.DeleteAll();

        HeaderRowNo := 0;
        OldRowNo := 0;

        if TempGlobalExcelBuf.Find('-') then
            repeat
                RecNo := RecNo + 1;
                if (RecNo mod 1000) = 0 then
                    Window.Update(1, 100 * RecNo div TotalRecNo);
                TempDim.SetRange(
                  "Code Caption", CopyStr(TempGlobalExcelBuf."Cell Value as Text", 1, MaxStrLen(TempDim."Code Caption")));
                case true of
                    TempGlobalExcelBuf."Cell Value as Text" = GLBudgetEntry.FieldCaption("G/L Account No."):
                        begin
                            IsHandled := false;
                            OnAnalyzeDataOnBeforeCheckHeaderRowNo(HeaderRowNo, TempGlobalExcelBuf, TempExcelBuf, IsHandled);
                            if IsHandled then
                                exit;

                            if HeaderRowNo = 0 then begin
                                HeaderRowNo := TempGlobalExcelBuf."Row No.";
                                TempExcelBuf := TempGlobalExcelBuf;
                                TempExcelBuf.Comment := Text010;
                                TempExcelBuf.Insert();
                            end else
                                Error(Text011);
                            OnAnalyzeDataOnAfterCheckHeaderRowNo(HeaderRowNo, TempGlobalExcelBuf, TempExcelBuf)
                        end;
                    TempDim.FindFirst() and (TempGlobalExcelBuf."Row No." <> HeaderRowNo):
                        begin
                            IsHandled := false;
                            OnAnalyzeDataOnBeforeCheckHeaderRowNo2(HeaderRowNo, TempGlobalExcelBuf, DimCode, DimRowNo, CountDim, TempDim, IsHandled);
                            if IsHandled then
                                exit;

                            if HeaderRowNo <> 0 then begin
                                Session.LogMessage('0000G7G', DimensionValueCodeEqualToDimensionCodeTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
                                Error(TheUsedDimensionValueAreAlsoUsedAsACaptionForADimensionErr, Format(TempDim.Code));
                            end else begin
                                IncreaseAndCheckCountDim(CountDim);
                                DimCode[CountDim] := TempDim.Code;
                                DimRowNo := TempGlobalExcelBuf."Row No.";
                                DimCode3 := TempDim.Code;
                            end;
                            OnAnalyzeDataOnAfterCheckHeaderRowNo2(HeaderRowNo, TempGlobalExcelBuf, DimCode, DimRowNo, CountDim, TempDim)
                        end;
                    (TempGlobalExcelBuf."Row No." = DimRowNo) and (TempGlobalExcelBuf."Column No." > 1) and (ImportOption = ImportOption::"Replace entries"):
                        begin
                            IsHandled := false;
                            OnAnalyzeDataOnBeforeGLBudgetEntrySetFilters(GLBudgetEntry, TempGlobalExcelBuf, DimCode3, IsHandled);
                            if IsHandled then
                                exit;

                            case DimCode3 of
                                BusUnitDimCode:
                                    GLBudgetEntry.SetFilter("Business Unit Code", TempGlobalExcelBuf."Cell Value as Text");
                                GlobalDim1Code:
                                    GLBudgetEntry.SetFilter("Global Dimension 1 Code", TempGlobalExcelBuf."Cell Value as Text");
                                GlobalDim2Code:
                                    GLBudgetEntry.SetFilter("Global Dimension 2 Code", TempGlobalExcelBuf."Cell Value as Text");
                                BudgetDim1Code:
                                    GLBudgetEntry.SetFilter("Budget Dimension 1 Code", TempGlobalExcelBuf."Cell Value as Text");
                                BudgetDim2Code:
                                    GLBudgetEntry.SetFilter("Budget Dimension 2 Code", TempGlobalExcelBuf."Cell Value as Text");
                                BudgetDim3Code:
                                    GLBudgetEntry.SetFilter("Budget Dimension 3 Code", TempGlobalExcelBuf."Cell Value as Text");
                                BudgetDim4Code:
                                    GLBudgetEntry.SetFilter("Budget Dimension 4 Code", TempGlobalExcelBuf."Cell Value as Text");
                            end;
                            OnAnalyzeDataOnAfterGLBudgetEntrySetFilters(GLBudgetEntry, TempGlobalExcelBuf, DimCode3)
                        end;

                    TempGlobalExcelBuf."Row No." = HeaderRowNo:
                        begin
                            IsHandled := false;
                            OnAnalyzeDataOnBeforeConditionalTempExcelBufInsert(TempGlobalExcelBuf, TempDim, CountDim, DimCode, IsHandled);
                            if IsHandled then
                                exit;

                            TempExcelBuf := TempGlobalExcelBuf;
                            case true of
                                TempDim.FindFirst():
                                    begin
                                        TempDim.Mark(false);
                                        IncreaseAndCheckCountDim(CountDim);
                                        TempExcelBuf.Comment := Text013 + Format(CountDim);
                                        TempExcelBuf.Insert();
                                        DimCode[CountDim] := TempDim.Code;
                                    end;
                                Evaluate(TestDateTime, TempExcelBuf."Cell Value as Text"):
                                    begin
                                        TempExcelBuf."Cell Value as Text" := Format(DT2Date(TestDateTime));
                                        TempExcelBuf.Comment := Text014;
                                        TempExcelBuf.Insert();
                                    end;
                            end;
                            OnAnalyzeDataOnAfterConditionalTempExcelBufInsert(TempExcelBuf, TempDim, CountDim, DimCode, TestDateTime);
                        end;
                    (TempGlobalExcelBuf."Row No." > HeaderRowNo) and (HeaderRowNo > 0):
                        begin
                            if TempGlobalExcelBuf."Row No." <> OldRowNo then begin
                                OldRowNo := TempGlobalExcelBuf."Row No.";
                                Clear(TempLocalBudgetBuf);
                            end;

                            TempExcelBuf.SetRange("Column No.", TempGlobalExcelBuf."Column No.");
                            if TempExcelBuf.FindFirst() then
                                case TempExcelBuf.Comment of
                                    Text010:
                                        begin
                                            TempGLAcc.SetRange(
                                              "No.",
                                              CopyStr(
                                                TempGlobalExcelBuf."Cell Value as Text",
                                                1, MaxStrLen(TempLocalBudgetBuf."G/L Account No.")));
                                            if TempGLAcc.FindFirst() then
                                                TempLocalBudgetBuf."G/L Account No." :=
                                                  CopyStr(
                                                    TempGlobalExcelBuf."Cell Value as Text",
                                                    1, MaxStrLen(TempLocalBudgetBuf."G/L Account No."))
                                            else
                                                TempLocalBudgetBuf."G/L Account No." := '';
                                        end;
                                    Text015:
                                        TempLocalBudgetBuf."Dimension Value Code 1" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 1"));
                                    Text016:
                                        TempLocalBudgetBuf."Dimension Value Code 2" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 2"));
                                    Text017:
                                        TempLocalBudgetBuf."Dimension Value Code 3" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 3"));
                                    Text018:
                                        TempLocalBudgetBuf."Dimension Value Code 4" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 4"));
                                    Text019:
                                        TempLocalBudgetBuf."Dimension Value Code 5" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 5"));
                                    Text020:
                                        TempLocalBudgetBuf."Dimension Value Code 6" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 6"));
                                    Text021:
                                        TempLocalBudgetBuf."Dimension Value Code 7" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 7"));
                                    Text022:
                                        TempLocalBudgetBuf."Dimension Value Code 8" :=
                                          CopyStr(
                                            TempGlobalExcelBuf."Cell Value as Text",
                                            1, MaxStrLen(TempLocalBudgetBuf."Dimension Value Code 8"));
                                    Text014:
                                        begin
                                            if TempLocalBudgetBuf."G/L Account No." <> '' then begin
                                                BudgetBuf := TempLocalBudgetBuf;
                                                if GLBudgetEntry.GetFilter("Global Dimension 1 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 1", GLBudgetEntry.GetFilter("Global Dimension 1 Code"));
                                                if GLBudgetEntry.GetFilter("Global Dimension 2 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 2", GLBudgetEntry.GetFilter("Global Dimension 2 Code"));
                                                if GLBudgetEntry.GetFilter("Budget Dimension 1 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 3", GLBudgetEntry.GetFilter("Budget Dimension 1 Code"));
                                                if GLBudgetEntry.GetFilter("Budget Dimension 2 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 4", GLBudgetEntry.GetFilter("Budget Dimension 2 Code"));
                                                if GLBudgetEntry.GetFilter("Budget Dimension 3 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 5", GLBudgetEntry.GetFilter("Budget Dimension 3 Code"));
                                                if GLBudgetEntry.GetFilter("Budget Dimension 4 Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 6", GLBudgetEntry.GetFilter("Budget Dimension 4 Code"));
                                                if GLBudgetEntry.GetFilter("Business Unit Code") <> '' then
                                                    Evaluate(BudgetBuf."Dimension Value Code 7", GLBudgetEntry.GetFilter("Business Unit Code"));
                                                Evaluate(BudgetBuf.Date, TempExcelBuf."Cell Value as Text");
                                                Evaluate(BudgetBuf.Amount, TempGlobalExcelBuf."Cell Value as Text");
                                                
                                                IsHandled := false;
                                                OnAnalyzeDataOnBeforeInsertBudgetBuf(BudgetBuf, IsHandled);
                                                if not IsHandled then
                                                    if not BudgetBuf.Find('=') then
                                                        BudgetBuf.Insert()
                                                    else begin
                                                        IsHandled := false;
                                                        OnAnalyzeDataOnBeforeCombinationMustBeUniqueError(BudgetBuf, IsHandled);
                                                    if not IsHandled then
                                                        Error(Text023 + Text024 + Format(BudgetBuf.RecordId()));
                                                end;
                                            end;
                                            OnAnalyzeDataOnAfterCaseText014(BudgetBuf);
                                        end;
                                end;
                        end;
                end;
            until TempGlobalExcelBuf.Next() = 0;

        TempDim.SetRange("Code Caption");
        TempDim.MarkedOnly(true);
        if TempDim.FindFirst() then begin
            Dim.Get(TempDim.Code);
            Error(Text028, Dim."Code Caption");
        end;

        Window.Close();
        TempExcelBuf.Reset();
        TempExcelBuf.SetRange(Comment, Text010);
        if not TempExcelBuf.FindFirst() then
            Error(Text025);
        TempExcelBuf.SetRange(Comment, Text014);
        if TempExcelBuf.IsEmpty() then
            Error(Text026);
    end;

    local procedure IncreaseAndCheckCountDim(var CountDim: Integer)
    var
        MaxCountDim: Integer;
    begin
        MaxCountDim := 8;
        CountDim := CountDim + 1;
        if CountDim > MaxCountDim then
            Error(Text008);
    end;

    local procedure InsertGLBudgetDimensions(var BudgetBuffer: Record "Budget Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertGLBudgetDimensions(GLBudgetEntry, BudgetBuffer, IsHandled);
        if IsHandled then
            exit;

        InsertGLBudgetDim(DimCode[1], BudgetBuffer."Dimension Value Code 1", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[2], BudgetBuffer."Dimension Value Code 2", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[3], BudgetBuffer."Dimension Value Code 3", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[4], BudgetBuffer."Dimension Value Code 4", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[5], BudgetBuffer."Dimension Value Code 5", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[6], BudgetBuffer."Dimension Value Code 6", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[7], BudgetBuffer."Dimension Value Code 7", GLBudgetEntry);
        InsertGLBudgetDim(DimCode[8], BudgetBuffer."Dimension Value Code 8", GLBudgetEntry);
    end;

    local procedure InsertGLBudgetDim(DimCode2: Code[20]; DimValCode2: Code[20]; var GLBudgetEntry2: Record "G/L Budget Entry")
    var
        DimValue: Record "Dimension Value";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertGLBudgetDim(DimCode2, IsHandled);
        if not IsHandled then begin
            if DimValCode2 = '' then
                exit;

            if DimCode2 <> BusUnitDimCode then begin
                DimValue.Get(DimCode2, DimValCode2);
                if TempDimSetEntry.Get(TempDimSetEntry."Dimension Set ID", DimCode2) then begin
                    TempDimSetEntry.Validate("Dimension Value Code", DimValCode2);
                    TempDimSetEntry.Validate("Dimension Value ID", DimValue."Dimension Value ID");
                    TempDimSetEntry.Modify(true);
                end else begin
                    TempDimSetEntry.Init();
                    TempDimSetEntry.Validate("Dimension Code", DimCode2);
                    TempDimSetEntry.Validate("Dimension Value Code", DimValCode2);
                    TempDimSetEntry.Validate("Dimension Value ID", DimValue."Dimension Value ID");
                    TempDimSetEntry.Insert();
                end;
            end;
            case DimCode2 of
                BusUnitDimCode:
                    GLBudgetEntry2."Business Unit Code" := CopyStr(DimValCode2, 1, MaxStrLen(GLBudgetEntry2."Business Unit Code"));
                GlobalDim1Code:
                    GLBudgetEntry2."Global Dimension 1 Code" := DimValCode2;
                GlobalDim2Code:
                    GLBudgetEntry2."Global Dimension 2 Code" := DimValCode2;
                BudgetDim1Code:
                    GLBudgetEntry2."Budget Dimension 1 Code" := DimValCode2;
                BudgetDim2Code:
                    GLBudgetEntry2."Budget Dimension 2 Code" := DimValCode2;
                BudgetDim3Code:
                    GLBudgetEntry2."Budget Dimension 3 Code" := DimValCode2;
                BudgetDim4Code:
                    GLBudgetEntry2."Budget Dimension 4 Code" := DimValCode2;
            end;
        end;
        OnAfterInsertGLBudgetDim(GLBudgetEntry, DimCode2, DimValCode2);
    end;

    procedure IsPostingAccount(AccNo: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(AccNo) then
            exit(false);
        exit(GLAccount."Account Type" in [GLAccount."Account Type"::Posting, GLAccount."Account Type"::"Begin-Total"]);
    end;

    procedure SetParameters(NewToGLBudgetName: Code[10]; NewImportOption: Option)
    begin
        ToGLBudgetName := NewToGLBudgetName;
        ImportOption := NewImportOption;
    end;

    procedure SetBudgetDimFilter(DimCode2: Code[20]; DimValCode2: Code[20]; var GLBudgetEntry2: Record "G/L Budget Entry")
    begin
        case DimCode2 of
            BusUnitDimCode:
                GLBudgetEntry2.SetRange("Business Unit Code", DimValCode2);
            GlobalDim1Code:
                GLBudgetEntry2.SetRange("Global Dimension 1 Code", DimValCode2);
            GlobalDim2Code:
                GLBudgetEntry2.SetRange("Global Dimension 2 Code", DimValCode2);
            BudgetDim1Code:
                GLBudgetEntry2.SetRange("Budget Dimension 1 Code", DimValCode2);
            BudgetDim2Code:
                GLBudgetEntry2.SetRange("Budget Dimension 2 Code", DimValCode2);
            BudgetDim3Code:
                GLBudgetEntry2.SetRange("Budget Dimension 3 Code", DimValCode2);
            BudgetDim4Code:
                GLBudgetEntry2.SetRange("Budget Dimension 4 Code", DimValCode2);
        end;
        OnAfterSetBudgetDimFilter(GLBudgetEntry2, DimValCode2, DimCode2);
    end;

    procedure SetFileName(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeGLBudgetEntrySetFilters(var GLBudgetEntry: Record "G/L Budget Entry"; var ExcelBuf: Record "Excel Buffer"; DimCode3: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnAfterGLBudgetEntrySetFilters(var GLBudgetEntry: Record "G/L Budget Entry"; var ExcelBuf: Record "Excel Buffer"; DimCode3: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGLBudgetDim(var GLBudgetEntry: Record "G/L Budget Entry"; DimCode2: Code[20]; DimValCode2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetBudgetDimFilter(var GLBudgetEntry: Record "G/L Budget Entry"; DimValCode2: Code[20]; DimCode2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLBudgetDimensions(var GLBudgetEntry: Record "G/L Budget Entry"; var BudgetBuffer: Record "Budget Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLBudgetDim(DimCode2: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var TempDimension: Record Dimension temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeCombinationMustBeUniqueError(var BudgetBuf: Record "Budget Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLastEntryNoBeforeImport(var GLBudgetEntry3: Record "G/L Budget Entry"; var LastEntryNoBeforeImport: Integer; var EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLBudgetNameBlacked(GLBudgetName: Record "G/L Budget Name"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBudgetBufOnAfterGetRecordOnBeforeGLBudgetEntryInsert(var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBudgetBufOnAfterGetRecordOnBeforeSetDimFilters(var GLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeCheckHeaderRowNo(var HeaderRowNo: Integer; var TempGlobalExcelBuf: Record "Excel Buffer" temporary; var TempExcelBuf: Record "Excel Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnAfterCheckHeaderRowNo(var HeaderRowNo: Integer; var TempGlobalExcelBuf: Record "Excel Buffer" temporary; var TempExcelBuf: Record "Excel Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeCheckHeaderRowNo2(var HeaderRowNo: Integer; var TempGlobalExcelBuf: Record "Excel Buffer" temporary; var DimCode: array[8] of Code[20]; var DimRowNo: Integer; var CountDim: Integer; var TempDim: Record Dimension temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnAfterCheckHeaderRowNo2(var HeaderRowNo: Integer; var TempGlobalExcelBuf: Record "Excel Buffer" temporary; var DimCode: array[8] of Code[20]; var DimRowNo: Integer; var CountDim: Integer; var TempDim: Record Dimension temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeConditionalTempExcelBufInsert(var TempGlobalExcelBuf: Record "Excel Buffer" temporary; var TempDim: Record Dimension temporary; var CountDim: Integer; var DimCode: array[8] of Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnAfterConditionalTempExcelBufInsert(var TempExcelBuf: Record "Excel Buffer" temporary; var TempDim: Record Dimension temporary; var CountDim: Integer; var DimCode: array[8] of Code[20]; var TestDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnBeforeInsertBudgetBuf(var BudgetBuf: Record "Budget Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAnalyzeDataOnAfterCaseText014(var BudgetBuf: Record "Budget Buffer")
    begin
    end;
}

