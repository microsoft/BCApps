// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;
using System.Globalization;

page 9297 "Inventory - G/L Recon Matrix"
{
    Caption = 'Inventory - G/L Reconciliation';
    DataCaptionExpression = GetCaption();
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Dimension Code Buffer";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    ToolTip = 'Specifies the name.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Style = Strong;
                    StyleExpr = true;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Style = Strong;
                    StyleExpr = true;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Style = Strong;
                    StyleExpr = true;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Style = Strong;
                    StyleExpr = true;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet" then begin
            if (ItemFilter = '') and (LocationFilter = '') then begin
                if ShowWarning then
                    RowIntegerLine.SetRange(Number, 1, 7)
                else
                    RowIntegerLine.SetRange(Number, 1, 6)
            end else
                RowIntegerLine.SetRange(Number, 1, 4)
        end else
            if InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement" then
                if (ItemFilter = '') and (LocationFilter = '') then begin
                    if ShowWarning then
                        RowIntegerLine.SetRange(Number, 1, 19)
                    else
                        RowIntegerLine.SetRange(Number, 1, 18)
                end else
                    RowIntegerLine.SetRange(Number, 1, 16);
        exit(FindRec(InvtReportHeader."Line Option", Rec, Which, true));
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(InvtReportHeader."Line Option", Rec, Steps, true));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
        InvtReportHeader."Show Warning" := ShowWarning;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Text004;
            ColumnDimCode := Text005;
        end;
        InvtReportHeader."Line Option" := DimCodeToOption(LineDimCode);
        InvtReportHeader."Column Option" := DimCodeToOption(ColumnDimCode);

        GetInvtReport.SetReportHeader(InvtReportHeader);
        GetInvtReport.Run(TempInventoryReportEntry);
        SetVisible();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        InvtReportHeader: Record "Inventory Report Header";
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        RowIntegerLine: Record "Integer";
        ColIntegerLine: Record "Integer";
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GetInvtReport: Codeunit "Get Inventory Report";
        LineDimCode: Text[20];
        ColumnDimCode: Text[20];
        DateFilter: Text;
#pragma warning disable AA0074
        Text000: Label '<Sign><Integer Thousand><Decimals,3>', Locked = true;
#pragma warning restore AA0074
        ItemFilter: Text;
        LocationFilter: Text;
        CellAmount: Decimal;
        GLSetupRead: Boolean;
#pragma warning disable AA0074
        Text004: Label 'Income Statement';
        Text005: Label 'Balance Sheet';
#pragma warning restore AA0074
        ShowWarning: Boolean;
#pragma warning disable AA0074
        Text006: Label 'Expected Cost Setup';
        Text007: Label 'Post Cost to G/L';
        Text008: Label 'Compression';
        Text009: Label 'Posting Group';
        Text010: Label 'Direct Posting';
        Text011: Label 'Posting Date';
        Text012: Label 'Closed Fiscal Year';
        Text013: Label 'Similar Accounts';
        Text014: Label 'Deleted Accounts';
        Text016: Label 'The program is not set up to use expected cost posting. Therefore, inventory interim G/L accounts are empty and this causes a difference between inventory and G/L totals.';
#pragma warning restore AA0074
        CostAmountsNotPostedTxt: Label 'Some of the cost amounts in the inventory ledger have not yet been posted to the G/L. You must run the Post Cost to G/L batch job to reconcile the ledgers.';
        EntriesCompressedTxt: Label 'Some inventory or G/L entries have been date compressed.';
        ReassigningAccountsTxt: Label 'You have possibly restructured your chart of accounts by re-assigning inventory related accounts in the General or Inventory Posting Setup.';
        PostedDirectlyTxt: Label 'Some inventory costs have been posted directly to a G/L account, bypassing the inventory subledger.';
#pragma warning disable AA0074
        Text021: Label 'There is a discrepancy between the posting date of the value entry and the associated G/L entry within the reporting period.';
#pragma warning restore AA0074
        PostedInClosedFiscalYearTxt: Label 'Some of the cost amounts are posted in a closed fiscal year. Therefore, the inventory related totals are different from their related G/L accounts in the income statement.';
#pragma warning disable AA0074
        Text023: Label 'You have possibly defined one G/L account for different inventory transactions.';
        Text024: Label 'You have possibly restructured your chart of accounts by deleting one or more inventory related G/L accounts.';
#pragma warning restore AA0074
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Text[250];
        MATRIX_CaptionSet: array[32] of Text[80];
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;
        TotalEmphasize: Boolean;

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    begin
        case DimCode of
            '':
                exit(-1);
            Text005:
                exit(0);
            Text004:
                exit(1);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; IsRow: Boolean): Boolean
    var
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := RowIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := ColIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; IsRow: Boolean): Integer
    var
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := RowIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := ColIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer"; IsRow: Boolean)
    begin
        case true of
            ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Balance Sheet") and not IsRow):
                case TheDimValue.Number of
                    1:
                        InsertRow('1', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), 0, false, TheDimCodeBuf);
                    2:
                        InsertRow('2', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"), 0, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), 0, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), 0, true, TheDimCodeBuf);
                    5:
                        InsertRow('5', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), 0, true, TheDimCodeBuf);
                    6:
                        InsertRow('6', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference), 0, true, TheDimCodeBuf);
                    7:
                        InsertRow('7', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning), 0, true, TheDimCodeBuf);
                end;
            ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Income Statement") and not IsRow):
                case TheDimValue.Number of
                    1:
                        InsertRow('1', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory To WIP"), 0, false, TheDimCodeBuf);
                    2:
                        InsertRow('2', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP To Interim"), 0, false, TheDimCodeBuf);
                    3:
                        InsertRow('3', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"), 0, false, TheDimCodeBuf);
                    4:
                        InsertRow('4', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"), 0, false, TheDimCodeBuf);
                    5:
                        InsertRow('5', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"), 0, false, TheDimCodeBuf);
                    6:
                        InsertRow('6', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."), 0, false, TheDimCodeBuf);
                    7:
                        InsertRow('7', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"), 0, false, TheDimCodeBuf);
                    8:
                        InsertRow('8', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS), 0, false, TheDimCodeBuf);
                    9:
                        InsertRow('9', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"), 0, false, TheDimCodeBuf);
                    10:
                        InsertRow('10', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"), 0, false, TheDimCodeBuf);
                    11:
                        InsertRow('11', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"), 0, false, TheDimCodeBuf);
                    12:
                        InsertRow('12', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"), 0, false, TheDimCodeBuf);
                    13:
                        InsertRow('13', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"), 0, false, TheDimCodeBuf);
                    14:
                        InsertRow('14', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"), 0, false, TheDimCodeBuf);
                    15:
                        InsertRow('15', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"), 0, false, TheDimCodeBuf);
                    16:
                        InsertRow('16', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), 0, true, TheDimCodeBuf);
                    17:
                        InsertRow('17', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), 0, true, TheDimCodeBuf);
                    18:
                        InsertRow('18', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference), 0, true, TheDimCodeBuf);
                    19:
                        InsertRow('19', TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning), 0, true, TheDimCodeBuf);
                end;
        end
    end;

    local procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        TheDimCodeBuf.Init();
        TheDimCodeBuf.Code := Code1;
        TheDimCodeBuf.Name := CopyStr(Name1, 1, MaxStrLen(TheDimCodeBuf.Name));
        TheDimCodeBuf.Indentation := Indentation1;
        TheDimCodeBuf."Show in Bold" := Bold1;
    end;

    local procedure Calculate(MATRIX_ColumnOrdinal: Integer) Amount: Decimal
    begin
        GetGLSetup();
        case true of
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total") in [Rec.Name, MatrixRecords[MATRIX_ColumnOrdinal].Name]:
                TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::"G/L Account");
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference) in [Rec.Name, MatrixRecords[MATRIX_ColumnOrdinal].Name],
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) in [Rec.Name, MatrixRecords[MATRIX_ColumnOrdinal].Name]:
                TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::" ");
            else
                TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::Item);
        end;
        case InvtReportHeader."Line Option" of
            InvtReportHeader."Line Option"::"Balance Sheet",
          InvtReportHeader."Line Option"::"Income Statement":
                case Rec.Name of
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference):
                        case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry.Inventory);
                                    Amount := TempInventoryReportEntry.Inventory;
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."WIP Inventory");
                                    Amount := TempInventoryReportEntry."WIP Inventory";
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Inventory (Interim)");
                                    Amount := TempInventoryReportEntry."Inventory (Interim)";
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."COGS (Interim)");
                            Amount := TempInventoryReportEntry."COGS (Interim)";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"):
                        case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Direct Cost Applied");
                                    Amount := TempInventoryReportEntry."Direct Cost Applied";
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Direct Cost Applied Actual");
                                    Amount := TempInventoryReportEntry."Direct Cost Applied Actual";
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Direct Cost Applied WIP");
                                    Amount := TempInventoryReportEntry."Direct Cost Applied WIP";
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"):
                        case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Overhead Applied");
                                    Amount := TempInventoryReportEntry."Overhead Applied";
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Overhead Applied Actual");
                                    Amount := TempInventoryReportEntry."Overhead Applied Actual";
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Overhead Applied WIP");
                                    Amount := TempInventoryReportEntry."Overhead Applied WIP";
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Inventory Adjmt.");
                            Amount := TempInventoryReportEntry."Inventory Adjmt.";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Invt. Accrual (Interim)");
                            Amount := TempInventoryReportEntry."Invt. Accrual (Interim)";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry.COGS);
                            Amount := TempInventoryReportEntry.COGS;
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Purchase Variance");
                            Amount := TempInventoryReportEntry."Purchase Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Material Variance");
                            Amount := TempInventoryReportEntry."Material Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Mat. Non-Inventory Variance");
                            Amount := TempInventoryReportEntry."Mat. Non-Inventory Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Capacity Variance");
                            Amount := TempInventoryReportEntry."Capacity Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Subcontracted Variance");
                            Amount := TempInventoryReportEntry."Subcontracted Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Capacity Overhead Variance");
                            Amount := TempInventoryReportEntry."Capacity Overhead Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Mfg. Overhead Variance");
                            Amount := TempInventoryReportEntry."Mfg. Overhead Variance";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied Actual"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Direct Cost Applied Actual");
                            Amount := TempInventoryReportEntry."Direct Cost Applied Actual";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied WIP"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Direct Cost Applied WIP");
                            Amount := TempInventoryReportEntry."Direct Cost Applied WIP";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied WIP"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Difference)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Overhead Applied WIP");
                            Amount := TempInventoryReportEntry."Overhead Applied WIP";
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory To WIP"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."Inventory To WIP");
                            Amount := TempInventoryReportEntry."Inventory To WIP";
                            if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory) then
                                Amount := -Amount;
                        end else
                            Amount := 0;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP To Interim"):
                        if MatrixRecords[MATRIX_ColumnOrdinal].Name in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"),
                                                                        TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)")]
                        then begin
                            TempInventoryReportEntry.CalcSums(TempInventoryReportEntry."WIP To Interim");
                            Amount := TempInventoryReportEntry."WIP To Interim";
                            if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory") then
                                Amount := -Amount;
                        end else
                            Amount := 0;
                end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetWarningText(TheField: Text; ShowType: Option ReturnAsText,ShowAsMessage): Text[250]
    begin
        if TempInventoryReportEntry."Expected Cost Posting Warning" then
            if TheField in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"),
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"),
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"),
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"),
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory")]
            then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text006);
                exit(Text016);
            end;
        if TempInventoryReportEntry."Cost is Posted to G/L Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text007);
            exit(CostAmountsNotPostedTxt);
        end;
        if TempInventoryReportEntry."Compression Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text008);
            exit(EntriesCompressedTxt);
        end;
        if TempInventoryReportEntry."Posting Group Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text009);
            exit(ReassigningAccountsTxt);
        end;
        if TempInventoryReportEntry."Direct Postings Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text010);
            exit(PostedDirectlyTxt);
        end;
        if TempInventoryReportEntry."Posting Date Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text011);
            exit(Text021);
        end;
        if TempInventoryReportEntry."Closing Period Overlap Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text012);
            exit(PostedInClosedFiscalYearTxt);
        end;
        if TempInventoryReportEntry."Similar Accounts Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text013);
            exit(Text023);
        end;
        if TempInventoryReportEntry."Deleted G/L Accounts Warning" then begin
            if ShowType = ShowType::ReturnAsText then
                exit(Text014);
            exit(Text024);
        end;
    end;

    local procedure ShowWarningText(ShowType: Option ReturnAsText,ShowAsMessage; MATRIX_ColumnOrdinal: Integer): Text[250]
    var
        Text: Text[250];
    begin
        case Rec.Name of
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning):
                case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                        if TempInventoryReportEntry.Inventory <> 0 then
                            Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory), ShowType);
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                        if TempInventoryReportEntry."WIP Inventory" <> 0 then
                            Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), ShowType);
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"):
                        if TempInventoryReportEntry."Inventory (Interim)" <> 0 then
                            Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"), ShowType);
                end;
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."COGS (Interim)" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Direct Cost Applied" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Overhead Applied" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Inventory Adjmt." <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Invt. Accrual (Interim)" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry.COGS <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Purchase Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Material Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Mat. Non-Inventory Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Capacity Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Subcontracted Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Capacity Overhead Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Mfg. Overhead Variance" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied Actual"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Direct Cost Applied Actual" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied Actual"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied WIP"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Direct Cost Applied WIP" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied WIP"), ShowType);
            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied WIP"):
                if MatrixRecords[MATRIX_ColumnOrdinal].Name = TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) then
                    if TempInventoryReportEntry."Overhead Applied WIP" <> 0 then
                        Text := GetWarningText(TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied WIP"), ShowType);
        end;

        if ShowType = ShowType::ReturnAsText then
            exit(Text);
        Message(Text);
    end;

    local procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        SourceTableName: Text;
        LocationTableName: Text;
    begin
        SourceTableName := '';
        LocationTableName := '';
        if ItemFilter <> '' then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27);
        if LocationFilter <> '' then
            LocationTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 14);
        exit(StrSubstNo('%1 %2 %3 %4', SourceTableName, ItemFilter, LocationTableName, LocationFilter));
    end;

    procedure Load(MatrixColumns1: array[32] of Text[100]; var MatrixRecords1: array[32] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; ShowWarningLocal: Boolean; DateFilterLocal: Text; ItemFilterLocal: Text; LocationFilterLocal: Text)
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        ShowWarning := ShowWarningLocal;
        DateFilter := DateFilterLocal;
        ItemFilter := ItemFilterLocal;
        LocationFilter := LocationFilterLocal;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        GetGLSetup();

        if TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) = MATRIX_CaptionSet[MATRIX_ColumnOrdinal] then begin
            ShowWarningText(1, MATRIX_ColumnOrdinal);
            exit;
        end;

        TempInventoryReportEntry.Reset();
        if TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total") in [MATRIX_CaptionSet[MATRIX_ColumnOrdinal], Rec.Name] then
            TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::"G/L Account")
        else
            TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::Item);

        TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Posting Date Filter", InvtReportHeader.GetFilter("Posting Date Filter"));
        TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Location Filter", InvtReportHeader.GetFilter("Location Filter"));

        if TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) in [Rec.Name, MATRIX_CaptionSet[MATRIX_ColumnOrdinal]] then begin
            ShowWarningText(1, MATRIX_ColumnOrdinal);
            exit;
        end;

        case InvtReportHeader."Line Option" of
            InvtReportHeader."Line Option"::"Balance Sheet",
          InvtReportHeader."Line Option"::"Income Statement":
                case Rec.Name of
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"):
                        case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry.Inventory, '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry.Inventory);
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."WIP Inventory", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."WIP Inventory");
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Inventory (Interim)", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Inventory (Interim)");
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."COGS (Interim)"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)")]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."COGS (Interim)", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."COGS (Interim)");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied"):
                        case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Direct Cost Applied", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Direct Cost Applied");
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Direct Cost Applied Actual", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Direct Cost Applied Actual");
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Direct Cost Applied WIP", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Direct Cost Applied WIP");
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied"):
                        case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Overhead Applied", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Overhead Applied");
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Overhead Applied Actual", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Overhead Applied Actual");
                                end;
                            TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"):
                                begin
                                    TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Overhead Applied WIP", '<>%1', 0);
                                    PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Overhead Applied WIP");
                                end;
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory Adjmt."):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Inventory Adjmt.", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Inventory Adjmt.");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Invt. Accrual (Interim)"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)")]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Invt. Accrual (Interim)", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Invt. Accrual (Interim)");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.COGS):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry.COGS, '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry.COGS);
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Purchase Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Purchase Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Purchase Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Material Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Material Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Material Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mat. Non-Inventory Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Mat. Non-Inventory Variance", '<>%1', 0);
                            Page.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Mat. Non-Inventory Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Capacity Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Capacity Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Subcontracted Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Subcontracted Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Subcontracted Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Capacity Overhead Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Capacity Overhead Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Capacity Overhead Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Mfg. Overhead Variance"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Mfg. Overhead Variance", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Mfg. Overhead Variance");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied Actual"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Direct Cost Applied Actual", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Direct Cost Applied Actual");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Direct Cost Applied WIP"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory")]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Direct Cost Applied WIP", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Direct Cost Applied WIP");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Overhead Applied WIP"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Total), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory")]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Overhead Applied WIP", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Overhead Applied WIP");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory To WIP"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"), TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Inventory)]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."Inventory To WIP", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."Inventory To WIP");
                        end;
                    TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP To Interim"):
                        if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."G/L Total"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."WIP Inventory"),
                                                                       TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry."Inventory (Interim)")]
                        then begin
                            TempInventoryReportEntry.SetFilter(TempInventoryReportEntry."WIP To Interim", '<>%1', 0);
                            PAGE.Run(0, TempInventoryReportEntry, TempInventoryReportEntry."WIP To Interim");
                        end;
                end;
        end;
        TempInventoryReportEntry.Reset();
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        CellAmount := Calculate(MATRIX_ColumnOrdinal);
        if CellAmount <> 0 then
            MATRIX_CellData[MATRIX_ColumnOrdinal] := Format(CellAmount, 0, Text000)
        else
            MATRIX_CellData[MATRIX_ColumnOrdinal] := '';

        TotalEmphasize := Rec."Show in Bold";

        if TempInventoryReportEntry.FieldCaption(TempInventoryReportEntry.Warning) in [Rec.Name, MatrixRecords[MATRIX_ColumnOrdinal].Name] then begin
            TempInventoryReportEntry.SetRange(TempInventoryReportEntry.Type, TempInventoryReportEntry.Type::" ");
            if TempInventoryReportEntry.FindFirst() then;
            case InvtReportHeader."Line Option" of
                InvtReportHeader."Line Option"::"Balance Sheet",
              InvtReportHeader."Line Option"::"Income Statement":
                    MATRIX_CellData[MATRIX_ColumnOrdinal] := ShowWarningText(0, MATRIX_ColumnOrdinal);
            end;
        end;
    end;

    procedure SetVisible()
    begin
        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
        Field5Visible := MATRIX_CaptionSet[5] <> '';
        Field6Visible := MATRIX_CaptionSet[6] <> '';
        Field7Visible := MATRIX_CaptionSet[7] <> '';
        Field8Visible := MATRIX_CaptionSet[8] <> '';
        Field9Visible := MATRIX_CaptionSet[9] <> '';
        Field10Visible := MATRIX_CaptionSet[10] <> '';
        Field11Visible := MATRIX_CaptionSet[11] <> '';
        Field12Visible := MATRIX_CaptionSet[12] <> '';
        Field13Visible := MATRIX_CaptionSet[13] <> '';
        Field14Visible := MATRIX_CaptionSet[14] <> '';
        Field15Visible := MATRIX_CaptionSet[15] <> '';
        Field16Visible := MATRIX_CaptionSet[16] <> '';
        Field17Visible := MATRIX_CaptionSet[17] <> '';
        Field18Visible := MATRIX_CaptionSet[18] <> '';
        Field19Visible := MATRIX_CaptionSet[19] <> '';
        Field20Visible := MATRIX_CaptionSet[20] <> '';
        Field21Visible := MATRIX_CaptionSet[21] <> '';
        Field22Visible := MATRIX_CaptionSet[22] <> '';
        Field23Visible := MATRIX_CaptionSet[23] <> '';
        Field24Visible := MATRIX_CaptionSet[24] <> '';
        Field25Visible := MATRIX_CaptionSet[25] <> '';
        Field26Visible := MATRIX_CaptionSet[26] <> '';
        Field27Visible := MATRIX_CaptionSet[27] <> '';
        Field28Visible := MATRIX_CaptionSet[28] <> '';
        Field29Visible := MATRIX_CaptionSet[29] <> '';
        Field30Visible := MATRIX_CaptionSet[30] <> '';
        Field31Visible := MATRIX_CaptionSet[31] <> '';
        Field32Visible := MATRIX_CaptionSet[32] <> '';
    end;
}

