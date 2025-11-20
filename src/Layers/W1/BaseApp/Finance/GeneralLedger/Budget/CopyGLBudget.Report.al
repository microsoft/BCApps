// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Utilities;
using System.Text;
using System.Utilities;

report 96 "Copy G/L Budget"
{
    Caption = 'Copy G/L Budget';
    ProcessingOnly = true;

    dataset
    {
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
                    group("Copy from")
                    {
                        Caption = 'Copy from';
                        field(Source; FromSource)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Source';
                            OptionCaption = 'G/L Entry,G/L Budget Entry';
                            ToolTip = 'Specifies which kind of amounts that you want to copy to a new budget. You can select either general ledger entries or general ledger budget entries.';

                            trigger OnValidate()
                            begin
                                if FromSource = FromSource::"G/L Entry" then
                                    FromGLBudgetName := '';
                            end;
                        }
                        field(FromGLBudgetName; FromGLBudgetName)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Budget Name';
                            TableRelation = "G/L Budget Name";
                            ToolTip = 'Specifies the name of the budget.';

                            trigger OnValidate()
                            begin
                                if (FromGLBudgetName <> '') and (FromSource = FromSource::"G/L Entry") then
                                    FromSource := FromSource::"G/L Budget Entry";
                            end;
                        }
                        field(GLAccountNo; FromGLAccountNo)
                        {
                            ApplicationArea = Suite;
                            Caption = 'G/L Account No.';
                            TableRelation = "G/L Account";
                            ToolTip = 'Specifies the G/L account or accounts that the batch job will process.';
                        }
                        field(Date; FromDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Date';
                            ToolTip = 'Specifies the date.';

                            trigger OnValidate()
                            var
                                GLAcc: Record "G/L Account";
                                FilterTokens: Codeunit "Filter Tokens";
                            begin
                                FilterTokens.MakeDateFilter(FromDate);
                                GLAcc.SetFilter("Date Filter", FromDate);
                                FromDate := GLAcc.GetFilter("Date Filter");
                            end;
                        }
                        field(FromClosingEntryFilter; FromClosingEntryFilter)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Closing Entries';
                            OptionCaption = 'Include,Exclude';
                            ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';
                        }
                        field(ColumnDim; ColumnDim)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                            trigger OnAssistEdit()
                            var
                                DimSelectionBuf: Record "Dimension Selection Buffer";
                            begin
                                DimSelectionBuf.SetDimSelectionChange(3, REPORT::"Copy G/L Budget", ColumnDim);
                            end;
                        }
                    }
                    group("Copy to")
                    {
                        Caption = 'Copy to';
                        field(BudgetName; ToGLBudgetName)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Budget Name';
                            TableRelation = "G/L Budget Name";
                            ToolTip = 'Specifies the name of the budget.';
                        }
                        field(ToGLAccountNo; ToGLAccountNo)
                        {
                            ApplicationArea = Suite;
                            Caption = 'G/L Account No.';
                            TableRelation = "G/L Account";
                            ToolTip = 'Specifies the G/L account or accounts that the batch job will process.';

                            trigger OnValidate()
                            begin
                                ToGLAccountNoOnAfterValidate();
                            end;
                        }
                    }
                    group(Apply)
                    {
                        Caption = 'Apply';
                        field(AmountAdjustFactor; AmountAdjustFactor)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Adjustment Factor';
                            DecimalPlaces = 0 : 5;
                            MinValue = 0;
                            NotBlank = true;
                            ToolTip = 'Specifies an adjustment factor to multiply the amounts that you want to copy. By entering an adjustment factor, you can increase or decrease the amounts that are copied to the new budget.';
                        }
                        field("RoundingMethod.Code"; RoundingMethod.Code)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Rounding Method';
                            TableRelation = "Rounding Method";
                            ToolTip = 'Specifies a code for the rounding method that you want to apply to entries when you copy them to a new budget.';
                        }
                        field(DateAdjustExpression; DateAdjustExpression)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Date Change Formula';
                            ToolTip = 'Specifies how the dates on the entries that are copied will be changed. Use a date formula; for example, to copy last week''s budget to this week, use the formula 1W (one week).';
                        }
                        field(ToDateCompression; ToDateCompression)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Date Compression';
                            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
                            ToolTip = 'Specifies the length of the period whose entries are combined. To see the options, choose the field.';
                        }
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if AmountAdjustFactor = 0 then
            AmountAdjustFactor := 1;

        if ToDateCompression = ToDateCompression::None then
            ToDateCompression := ToDateCompression::Day;
    end;

    trigger OnPostReport()
    var
        FromGLBudgetEntry: Record "G/L Budget Entry";
        FromGLEntry: Record "G/L Entry";
    begin
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(Text007 + Text008 + Text009);

        case FromSource of
            FromSource::"G/L Entry":
                begin
                    FromGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    if FromGLAccountNo <> '' then
                        FromGLEntry.SetFilter("G/L Account No.", FromGLAccountNo);
                    FromGLEntry.SetFilter("Posting Date", FromDate);
                    OnOnPostReportOnAfterSetFromGLEntryFilters(FromGLEntry);
                    if FromGLEntry.Find('-') then
                        repeat
                            ProcessRecord(
                              FromGLEntry."G/L Account No.", FromGLEntry."Business Unit Code", FromGLEntry."Posting Date", FromGLEntry.Description,
                              FromGLEntry."Dimension Set ID", FromGLEntry.Amount);
                        until FromGLEntry.Next() = 0;
                end;
            FromSource::"G/L Budget Entry":
                begin
                    FromGLBudgetEntry.SetRange("Budget Name", FromGLBudgetName);
                    if FromGLAccountNo <> '' then
                        FromGLBudgetEntry.SetFilter("G/L Account No.", FromGLAccountNo);
                    if FromDate <> '' then
                        FromGLBudgetEntry.SetFilter(Date, FromDate);
                    if FromGLBudgetEntry.FindLast() then
                        FromGLBudgetEntry.SetFilter("Entry No.", '<=%1', FromGLBudgetEntry."Entry No.");
                    OnOnPostReportOnAfterSetFromGLBudgetEntryFilters(FromGLBudgetEntry);
                    FromGLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Description, Date);
                    if FromGLBudgetEntry.FindSet() then
                        repeat
                            ProcessRecord(
                              FromGLBudgetEntry."G/L Account No.", FromGLBudgetEntry."Business Unit Code", FromGLBudgetEntry.Date, FromGLBudgetEntry.Description,
                              FromGLBudgetEntry."Dimension Set ID", FromGLBudgetEntry.Amount);
                        until FromGLBudgetEntry.Next() = 0;
                end;
        end;
        InsertGLBudgetEntry();
        OnPostReportOnAfterInsertGLBudgetEntry(FromGLBudgetName, ToGLBudgetName);
        Window.Close();

        if not NoMessage then
            Message(Text010);
    end;

    trigger OnPreReport()
    var
        SelectedDim: Record "Selected Dimension";
        GLSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        ConfirmManagement: Codeunit "Confirm Management";
        Continue: Boolean;
    begin
        if not NoMessage then
            DimSelectionBuf.CompareDimText(3, REPORT::"Copy G/L Budget", '', ColumnDim, Text001);

        if (FromSource = FromSource::"G/L Budget Entry") and (FromGLBudgetName = '') then
            Error(Text002);

        if (FromSource = FromSource::"G/L Entry") and (FromDate = '') then
            Error(Text003);

        if ToGLBudgetName = '' then
            Error(Text004);

        Continue := true;
        GLBudgetName.SetRange(Name, ToGLBudgetName);
        if not GLBudgetName.FindFirst() then begin
            if not NoMessage then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text005, ToGLBudgetName), true) then
                    Continue := false;
            if Continue then begin
                GLBudgetName.Init();
                GLBudgetName.Name := ToGLBudgetName;
                GLBudgetName.Insert();
                Commit();
            end;
        end else begin
            OnPreReportOnBeforeCopyBudgetDimCodes(GLBudgetName);
            BudgetDim1Code := GLBudgetName."Budget Dimension 1 Code";
            BudgetDim2Code := GLBudgetName."Budget Dimension 2 Code";
            BudgetDim3Code := GLBudgetName."Budget Dimension 3 Code";
            BudgetDim4Code := GLBudgetName."Budget Dimension 4 Code";
        end;

        if (not NoMessage) and Continue then
            if not ConfirmManagement.GetResponseOrDefault(Text006, true) then
                Continue := false;

        if Continue then begin
            SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Copy G/L Budget", '', TempSelectedDim);
            if TempSelectedDim.Find('-') then
                repeat
                    TempSelectedDim.Level := 0;
                    if TempSelectedDim."Dimension Value Filter" <> '' then
                        if FilterIncludesBlanks(TempSelectedDim."Dimension Value Filter") then
                            TempSelectedDim.Level := 1;
                    TempSelectedDim.Modify();
                until TempSelectedDim.Next() = 0;

            ToGLBudgetEntry.LockTable();
            if ToGLBudgetEntry.FindLast() then
                GLBudgetEntryNo := ToGLBudgetEntry."Entry No." + 1
            else
                GLBudgetEntryNo := 1;

            GLSetup.Get();
            GlobalDim1Code := GLSetup."Global Dimension 1 Code";
            GlobalDim2Code := GLSetup."Global Dimension 2 Code";
        end else
            CurrReport.Quit();
    end;

    var
        ToGLBudgetEntry: Record "G/L Budget Entry";
        TempGLBudgetEntry: Record "G/L Budget Entry" temporary;
        TempSelectedDim: Record "Selected Dimension" temporary;
        TempDimEntryBuffer: Record "Dimension Entry Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        RoundingMethod: Record "Rounding Method";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DimMgt: Codeunit DimensionManagement;
        DateAdjustExpression: DateFormula;
        Window: Dialog;
        FromDate: Text;
        FromSource: Option "G/L Entry","G/L Budget Entry";
        FromGLBudgetName: Code[10];
        FromGLAccountNo: Code[250];
        FromClosingEntryFilter: Option Include,Exclude;
        ToGLBudgetName: Code[10];
        ToGLAccountNo: Code[20];
        ToBUCode: Code[20];
        ToDateCompression: Option "None",Day,Week,Month,Quarter,Year,Period;
        ColumnDim: Text[250];
        AmountAdjustFactor: Decimal;
        GLBudgetEntryNo: Integer;
        GlobalDim1Code: Code[20];
        GlobalDim2Code: Code[20];
        BudgetDim1Code: Code[20];
        BudgetDim2Code: Code[20];
        BudgetDim3Code: Code[20];
        BudgetDim4Code: Code[20];
        NoMessage: Boolean;
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
        OldGLAccountNo: Code[20];
        OldPostingDate: Date;
        OldPostingDescription: Text[100];
        OldBUCode: Code[20];
        WindowUpdateDateTime: DateTime;

#pragma warning disable AA0074
        Text001: Label 'Dimensions';
        Text002: Label 'You must specify a budget name to copy from.';
        Text003: Label 'You must specify a date interval to copy from.';
        Text004: Label 'You must specify a budget name to copy to.';
#pragma warning disable AA0470
        Text005: Label 'Do you want to create G/L Budget Name %1?';
#pragma warning restore AA0470
        Text006: Label 'Do you want to start the copy?';
        Text007: Label 'Copying budget...\\';
#pragma warning disable AA0470
        Text008: Label 'G/L Account No. #1####################\';
        Text009: Label 'Posting Date    #2######';
#pragma warning restore AA0470
        Text010: Label 'Budget has been successfully copied.';
        Text011: Label 'You can define only one G/L Account.';
#pragma warning restore AA0074

    local procedure ProcessRecord(GLAccNo: Code[20]; BUCode: Code[20]; PostingDate: Date; PostingDescription: Text[100]; DimSetID: Integer; Amount: Decimal)
    var
        NewDate: Date;
        NewDimSetID: Integer;
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 750 then begin
            Window.Update(1, GLAccNo);
            Window.Update(2, PostingDate);
            WindowUpdateDateTime := CurrentDateTime;
        end;
        NewDate := CalculatePeriodStart(PostingDate);
        if (FromClosingEntryFilter = FromClosingEntryFilter::Exclude) and (NewDate = ClosingDate(NewDate)) then
            exit;

        if (FromSource = FromSource::"G/L Entry") and
           (ToDateCompression <> ToDateCompression::None)
        then
            PostingDescription := '';

        if OldGLAccountNo = '' then begin
            OldGLAccountNo := GLAccNo;
            OldPostingDate := NewDate;
            OldBUCode := BUCode;
            OldPostingDescription := PostingDescription;
        end;

        if (GLAccNo <> OldGLAccountNo) or
           (NewDate <> OldPostingDate) or
           (BUCode <> OldBUCode) or
           (PostingDescription <> OldPostingDescription) or
           (ToDateCompression = ToDateCompression::None)
        then begin
            OldGLAccountNo := GLAccNo;
            OldPostingDate := NewDate;
            OldBUCode := BUCode;
            OldPostingDescription := PostingDescription;
            InsertGLBudgetEntry();
        end;

        NewDimSetID := DimSetID;
        if not IncludeFromEntry(NewDimSetID) then
            exit;

        UpdateTempGLBudgetEntry(GLAccNo, NewDate, Amount, PostingDescription, BUCode, NewDimSetID);
    end;

    local procedure UpdateTempGLBudgetEntry(GLAccNo: Code[20]; PostingDate: Date; Amount: Decimal; Description: Text[100]; BUCode: Code[20]; DimSetID: Integer)
    begin
        TempGLBudgetEntry.SetRange("G/L Account No.", GLAccNo);
        TempGLBudgetEntry.SetRange(Date, PostingDate);
        TempGLBudgetEntry.SetRange(Description, Description);
        TempGLBudgetEntry.SetRange("Business Unit Code", BUCode);
        TempGLBudgetEntry.SetRange("Dimension Set ID", DimSetID);

        if TempGLBudgetEntry.FindFirst() then begin
            TempGLBudgetEntry.Amount := TempGLBudgetEntry.Amount + Amount;
            TempGLBudgetEntry.Modify();
            TempGLBudgetEntry.Reset();
        end else begin
            TempGLBudgetEntry.Reset();
            if TempGLBudgetEntry.FindLast() then
                TempGLBudgetEntry."Entry No." := TempGLBudgetEntry."Entry No." + 1
            else
                TempGLBudgetEntry."Entry No." := 1;
            TempGLBudgetEntry."Dimension Set ID" := DimSetID;
            TempGLBudgetEntry."G/L Account No." := GLAccNo;
            TempGLBudgetEntry.Date := PostingDate;
            TempGLBudgetEntry.Amount := Amount;
            TempGLBudgetEntry.Description := Description;
            TempGLBudgetEntry."Business Unit Code" := BUCode;
            TempGLBudgetEntry.Insert();
        end;
    end;

    local procedure InsertGLBudgetEntry()
    var
        Sign: Decimal;
    begin
        if TempGLBudgetEntry.Find('-') then
            repeat
                if TempGLBudgetEntry.Amount <> 0 then begin
                    ToGLBudgetEntry := TempGLBudgetEntry;
                    ToGLBudgetEntry."Entry No." := GLBudgetEntryNo;
                    GLBudgetEntryNo := GLBudgetEntryNo + 1;
                    ToGLBudgetEntry."Budget Name" := ToGLBudgetName;
                    if ToGLAccountNo <> '' then
                        ToGLBudgetEntry."G/L Account No." := ToGLAccountNo;
                    if ToBUCode <> '' then
                        ToGLBudgetEntry."Business Unit Code" := ToBUCode;
                    ToGLBudgetEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ToGLBudgetEntry."User ID"));
                    ToGLBudgetEntry."Last Date Modified" := Today;
                    ToGLBudgetEntry.Date := TempGLBudgetEntry.Date;
                    ToGLBudgetEntry.Amount := Round(TempGLBudgetEntry.Amount * AmountAdjustFactor);
                    if RoundingMethod.Code <> '' then begin
                        if ToGLBudgetEntry.Amount >= 0 then
                            Sign := 1
                        else
                            Sign := -1;
                        RoundingMethod."Minimum Amount" := Abs(ToGLBudgetEntry.Amount);
                        if RoundingMethod.Find('=<') then begin
                            ToGLBudgetEntry.Amount :=
                              ToGLBudgetEntry.Amount + Sign * RoundingMethod."Amount Added Before";
                            if RoundingMethod.Precision > 0 then
                                ToGLBudgetEntry.Amount :=
                                  Sign *
                                  Round(
                                    Abs(
                                      ToGLBudgetEntry.Amount), RoundingMethod.Precision, CopyStr('=><',
                                      RoundingMethod.Type + 1, 1));
                            ToGLBudgetEntry.Amount :=
                              ToGLBudgetEntry.Amount + Sign * RoundingMethod."Amount Added After";
                        end;
                    end;
                    DimSetEntry.Reset();
                    DimSetEntry.SetRange("Dimension Set ID", TempGLBudgetEntry."Dimension Set ID");
                    if DimSetEntry.Find('-') then
                        repeat
                            if DimSetEntry."Dimension Code" = GlobalDim1Code then
                                ToGLBudgetEntry."Global Dimension 1 Code" := DimSetEntry."Dimension Value Code";
                            if DimSetEntry."Dimension Code" = GlobalDim2Code then
                                ToGLBudgetEntry."Global Dimension 2 Code" := DimSetEntry."Dimension Value Code";
                            if DimSetEntry."Dimension Code" = BudgetDim1Code then
                                ToGLBudgetEntry."Budget Dimension 1 Code" := DimSetEntry."Dimension Value Code";
                            if DimSetEntry."Dimension Code" = BudgetDim2Code then
                                ToGLBudgetEntry."Budget Dimension 2 Code" := DimSetEntry."Dimension Value Code";
                            if DimSetEntry."Dimension Code" = BudgetDim3Code then
                                ToGLBudgetEntry."Budget Dimension 3 Code" := DimSetEntry."Dimension Value Code";
                            if DimSetEntry."Dimension Code" = BudgetDim4Code then
                                ToGLBudgetEntry."Budget Dimension 4 Code" := DimSetEntry."Dimension Value Code";
                        until DimSetEntry.Next() = 0;

                    if ToGLBudgetEntry.Amount <> 0 then begin
                        OnInsertGLBudgetEntryOnBeforeToGLBudgetEntryInsert(ToGLBudgetEntry, ToDateCompression);
                        ToGLBudgetEntry.Insert();
                    end;
                end;
            until TempGLBudgetEntry.Next() = 0;

        TempGLBudgetEntry.Reset();
        TempGLBudgetEntry.DeleteAll();
    end;

    procedure Initialize(FromSource2: Option; FromGLBudgetName2: Code[10]; FromGLAccountNo2: Code[250]; FromDate2: Text[30]; ToGlBudgetName2: Code[10]; ToGLAccountNo2: Code[20]; ToBUCode2: Code[20]; AmountAdjustFactor2: Decimal; RoundingMethod2: Code[10]; DateAdjustExpression2: DateFormula; NoMessage2: Boolean)
    begin
        FromSource := FromSource2;
        FromGLBudgetName := FromGLBudgetName2;
        FromGLAccountNo := FromGLAccountNo2;
        FromDate := FromDate2;
        ToGLBudgetName := ToGlBudgetName2;
        ToGLAccountNo := ToGLAccountNo2;
        ToBUCode := ToBUCode2;
        AmountAdjustFactor := AmountAdjustFactor2;
        RoundingMethod.Code := RoundingMethod2;
        DateAdjustExpression := DateAdjustExpression2;
        NoMessage := NoMessage2;
    end;

    local procedure CalculatePeriodStart(PostingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if Format(DateAdjustExpression) <> '' then
            if PostingDate = ClosingDate(PostingDate) then
                PostingDate := ClosingDate(CalcDate(DateAdjustExpression, NormalDate(PostingDate)))
            else
                PostingDate := CalcDate(DateAdjustExpression, PostingDate);
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        case ToDateCompression of
            ToDateCompression::Week:
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            ToDateCompression::Month:
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            ToDateCompression::Quarter:
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            ToDateCompression::Year:
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            ToDateCompression::Period:
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure FilterIncludesBlanks(TheFilter: Code[250]): Boolean
    var
        TempDimBuf2: Record "Dimension Buffer" temporary;
    begin
        TempDimBuf2.DeleteAll(); // Necessary because of C/SIDE error
        TempDimBuf2.Init();
        TempDimBuf2.Insert();
        TempDimBuf2.SetFilter("Dimension Code", TheFilter);
        exit(TempDimBuf2.FindFirst());
    end;

    local procedure IncludeFromEntry(var DimSetID: Integer): Boolean
    var
        IncludeEntry: Boolean;
    begin
        if TempDimEntryBuffer.Get(DimSetID) then begin
            DimSetID := TempDimEntryBuffer."Dimension Entry No.";
            exit(true);
        end;
        TempDimEntryBuffer."No." := DimSetID;

        IncludeEntry := true;
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        if TempSelectedDim.Find('-') then
            repeat
                DimSetEntry.Init();
                DimSetEntry.SetRange("Dimension Code", TempSelectedDim."Dimension Code");
                if TempSelectedDim."Dimension Value Filter" <> '' then
                    DimSetEntry.SetFilter("Dimension Value Code", TempSelectedDim."Dimension Value Filter");
                if DimSetEntry.FindFirst() then begin
                    TempDimSetEntry := DimSetEntry;
                    TempDimSetEntry."Dimension Set ID" := 0;
                    if TempSelectedDim."New Dimension Value Code" <> '' then
                        TempDimSetEntry.Validate("Dimension Value Code", TempSelectedDim."New Dimension Value Code");
                    TempDimSetEntry.Insert(true);
                end else begin
                    if TempSelectedDim."Dimension Value Filter" <> '' then
                        if TempSelectedDim.Level = 1 then begin
                            DimSetEntry.SetRange("Dimension Value Code");
                            IncludeEntry := not DimSetEntry.FindFirst();
                        end else
                            IncludeEntry := false;
                    if IncludeEntry and (TempSelectedDim."New Dimension Value Code" <> '') then begin
                        TempDimSetEntry."Dimension Set ID" := 0;
                        TempDimSetEntry."Dimension Code" := CopyStr(TempSelectedDim."Dimension Code", 1, 20);
                        TempDimSetEntry.Validate("Dimension Value Code", TempSelectedDim."New Dimension Value Code");
                        TempDimSetEntry.Insert(true);
                    end;
                end;
                DimSetEntry.SetRange("Dimension Code");
                DimSetEntry.SetRange("Dimension Value Code");
            until (TempSelectedDim.Next() = 0) or not IncludeEntry;
        if IncludeEntry then begin
            DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
            TempDimEntryBuffer."Dimension Entry No." := DimSetID;
            TempDimEntryBuffer.Insert();
            exit(true);
        end;
        exit(false);
    end;

    procedure InitializeRequest(FromSource2: Option; FromGLBudgetName2: Code[10]; FromGLAccountNo2: Code[250]; FromDate2: Text[30]; FromClosingEntryFilter2: Option; DimensionText: Text[250]; ToGlBudgetName2: Code[10]; ToGLAccountNo2: Code[20]; AmountAdjustFactor2: Decimal; RoundingMethod2: Code[10]; DateAdjustExpression2: DateFormula; ToDateCompression2: Option)
    begin
        FromSource := FromSource2;
        FromGLBudgetName := FromGLBudgetName2;
        FromGLAccountNo := FromGLAccountNo2;
        FromDate := FromDate2;
        FromClosingEntryFilter := FromClosingEntryFilter2;
        ColumnDim := DimensionText;
        ToGLBudgetName := ToGlBudgetName2;
        ToGLAccountNo := ToGLAccountNo2;
        AmountAdjustFactor := AmountAdjustFactor2;
        RoundingMethod.Code := RoundingMethod2;
        DateAdjustExpression := DateAdjustExpression2;
        ToDateCompression := ToDateCompression2;
    end;

    local procedure ToGLAccountNoOnAfterValidate()
    var
        GLAccount: Record "G/L Account";
    begin
        if ToGLAccountNo <> '' then begin
            GLAccount.Get(ToGLAccountNo);
            Message(Text011)
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyBudgetDimCodes(var GLBudgetName: Record "G/L Budget Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostReportOnAfterInsertGLBudgetEntry(FromBudgetName: Code[10]; ToBudgetName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnInsertGLBudgetEntryOnBeforeToGLBudgetEntryInsert(var ToGLBudgetEntry: Record "G/L Budget Entry"; ToDateCompression: Option "None",Day,Week,Month,Quarter,Year,Period)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnPostReportOnAfterSetFromGLEntryFilters(var FromGLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnPostReportOnAfterSetFromGLBudgetEntryFilters(var FromGLBudgetEntry: Record "G/L Budget Entry")
    begin
    end;
}

