// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

report 99000753 "Quantity Explosion of BOM"
{
    DefaultRenderingLayout = WordLayout;
    ApplicationArea = Manufacturing;
    Caption = 'Quantity Explosion of BOM';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group";
            column(AsOfCalcDate; Text000 + Format(CalculateDate))
            {
            }
            // RDLC only
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            // RDLC only
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ItemTableCaptionFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_Item; Description)
            {
                IncludeCaption = true;
            }
            // RDLC only
            column(QtyExplosionofBOMCapt; QtyExplosionofBOMCaptLbl)
            {
            }
            // RDLC only
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            column(BOMQtyCaption; BOMQtyCaptionLbl)
            {
            }
            column(BomCompLevelQtyCapt; BomCompLevelQtyCaptLbl)
            {
            }
            column(BomCompLevelDescCapt; BomCompLevelDescCaptLbl)
            {
            }
            column(BomCompLevelNoCapt; BomCompLevelNoCaptLbl)
            {
            }
            column(LevelCapt; LevelCaptLbl)
            {
            }
            column(BomCompLevelUOMCodeCapt; BomCompLevelUOMCodeCaptLbl)
            {
            }
            dataitem(BOMLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(BomCompLevelNo; BomComponent[Level]."No.")
                    {
                        IncludeCaption = true;
                    }
                    column(BomCompLevelDesc; BomComponent[Level].Description)
                    {
                        IncludeCaption = true;
                    }
                    column(BOMQty; BOMQty)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(FormatLevel; PadStr('', Level, ' ') + Format(Level))
                    {
                    }
                    column(IndentLevel; IndentLevel)
                    {
                    }
                    column(BomCompLevelQty; BomComponent[Level].Quantity)
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(BomCompLevelUOMCode; BomComponent[Level]."Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(IndentLevel);
                        BOMQty := Quantity[Level] * QtyPerUnitOfMeasure * BomComponent[Level].Quantity;
                        while IndentLoop < Level do begin
                            IndentLevel += IndentLevel + '.';
                            IndentLoop += 1;
                        end;

                        IndentLoop := 0;
                    end;

                    trigger OnPostDataItem()
                    begin
                        Level := NextLevel;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BomItem: Record Item;
                begin
                    while BomComponent[Level].Next() = 0 do begin
                        Level := Level - 1;
                        if Level < 1 then
                            CurrReport.Break();
                    end;

                    NextLevel := Level;
                    Clear(CompItem);
                    QtyPerUnitOfMeasure := 1;
                    case BomComponent[Level].Type of
                        BomComponent[Level].Type::Item:
                            begin
                                CompItem.Get(BomComponent[Level]."No.");
                                if CompItem."Production BOM No." <> '' then begin
                                    ProdBOM.Get(CompItem."Production BOM No.");
                                    if ProdBOM.Status = ProdBOM.Status::Closed then
                                        CurrReport.Skip();
                                    NextLevel := Level + 1;
                                    if Level > 1 then
                                        if (NextLevel > 50) or (BomComponent[Level]."No." = NoList[Level - 1]) then
                                            Error(ProdBomErr, 50, Item."No.", NoList[Level], Level);
                                    Clear(BomComponent[NextLevel]);
                                    NoListType[NextLevel] := NoListType[NextLevel] ::Item;
                                    NoList[NextLevel] := CompItem."No.";
                                    VersionCode[NextLevel] :=
                                      VersionMgt.GetBOMVersion(CompItem."Production BOM No.", CalculateDate, true);
                                    BomComponent[NextLevel].SetRange("Production BOM No.", CompItem."Production BOM No.");
                                    BomComponent[NextLevel].SetRange("Version Code", VersionCode[NextLevel]);
                                    BomComponent[NextLevel].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                                    BomComponent[NextLevel].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);
                                end;
                                if Level > 1 then
                                    if BomComponent[Level - 1].Type = BomComponent[Level - 1].Type::Item then
                                        if BomItem.Get(BomComponent[Level - 1]."No.") then
                                            QtyPerUnitOfMeasure :=
                                              UOMMgt.GetQtyPerUnitOfMeasure(BomItem, BomComponent[Level - 1]."Unit of Measure Code") /
                                              UOMMgt.GetQtyPerUnitOfMeasure(
                                                BomItem, VersionMgt.GetBOMUnitOfMeasure(BomItem."Production BOM No.", VersionCode[Level]));
                            end;
                        BomComponent[Level].Type::"Production BOM":
                            begin
                                ProdBOM.Get(BomComponent[Level]."No.");
                                if ProdBOM.Status = ProdBOM.Status::Closed then
                                    CurrReport.Skip();
                                NextLevel := Level + 1;
                                if Level > 1 then
                                    if (NextLevel > 50) or (BomComponent[Level]."No." = NoList[Level - 1]) then
                                        Error(ProdBomErr, 50, Item."No.", NoList[Level], Level);
                                Clear(BomComponent[NextLevel]);
                                NoListType[NextLevel] := NoListType[NextLevel] ::"Production BOM";
                                NoList[NextLevel] := ProdBOM."No.";
                                VersionCode[NextLevel] := VersionMgt.GetBOMVersion(ProdBOM."No.", CalculateDate, true);
                                BomComponent[NextLevel].SetRange("Production BOM No.", NoList[NextLevel]);
                                BomComponent[NextLevel].SetRange("Version Code", VersionCode[NextLevel]);
                                BomComponent[NextLevel].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                                BomComponent[NextLevel].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);
                            end;
                    end;

                    if NextLevel <> Level then
                        Quantity[NextLevel] := BomComponent[NextLevel - 1].Quantity * QtyPerUnitOfMeasure * Quantity[Level];
                end;

                trigger OnPreDataItem()
                begin
                    Level := 1;

                    ProdBOM.Get(Item."Production BOM No.");

                    VersionCode[Level] := VersionMgt.GetBOMVersion(Item."Production BOM No.", CalculateDate, true);
                    Clear(BomComponent);
                    BomComponent[Level]."Production BOM No." := Item."Production BOM No.";
                    BomComponent[Level].SetRange("Production BOM No.", Item."Production BOM No.");
                    BomComponent[Level].SetRange("Version Code", VersionCode[Level]);
                    BomComponent[Level].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                    BomComponent[Level].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);
                    NoListType[Level] := NoListType[Level] ::Item;
                    NoList[Level] := Item."No.";
                    Quantity[Level] :=
                      UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure") /
                      UOMMgt.GetQtyPerUnitOfMeasure(
                        Item,
                        VersionMgt.GetBOMUnitOfMeasure(
                          Item."Production BOM No.", VersionCode[Level]));
                end;
            }

            trigger OnPreDataItem()
            begin
                ItemFilter := GetFilters();

                SetFilter("Production BOM No.", '<>%1', '');
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Quantity Explosion of BOM';
        AboutText = 'Provides an overview on the dynamic BOM availability. Visualise key inventory figures and forecast production capabilities to meet demand efficiently. Stay ahead with real-time insights into your assembly and production schedules.';


        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculateDate; CalculateDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date you want the program to calculate the quantity of the BOM lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CalculateDate := WorkDate();
        end;
    }

    rendering
    {
        layout(WordLayout)
        {
            Caption = 'Quantity Explosion of BOM Word';
            Type = Word;
            LayoutFile = './Manufacturing/Reports/QuantityExplosionofBOM.docx';
        }
        layout(ExcelLayout)
        {
            Caption = 'Quantity Explosion of BOM Excel';
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/QuantityExplosionOfBOM.xlsx';
        }
#if not CLEAN27
        layout(RDLCLayout)
        {
            Caption = 'Quantity Explosion of BOM RDLC';
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/QuantityExplosionofBOM.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        QuantityExplosionOfBOM = 'Quantity Explosion of BOM';
        QtyExplosionOfBOMPrint = 'Qty. Expl. Of BOM (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        BOMTopLvlPrint = 'BOM (Top Level) (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        QtyExplosionOfBOMAnalysis = 'Qty. Expl. Of BOM (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        QtyExplosionOfBOMAnalysisL1 = 'Qty. Expl. Of BOM (Analysis) L1', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemNo = 'Item No.';
        ItemDesc = 'Item Description';
        Level = 'Level';
        BOMQtyCapt = 'Total Quantity';
        CalculationDateLabel = 'Calculation Date:';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(Item);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'As of ';
#pragma warning restore AA0074
        ProdBOM: Record "Production BOM Header";
        CompItem: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        ItemFilter: Text;
        IndentLevel: Text;
        IndentLoop: Integer;
        CalculateDate: Date;
        NoList: array[99] of Code[20];
        VersionCode: array[99] of Code[20];
        Quantity: array[99] of Decimal;
        QtyPerUnitOfMeasure: Decimal;
        NextLevel: Integer;
        BOMQty: Decimal;
        // RDLC only
        QtyExplosionofBOMCaptLbl: Label 'Quantity Explosion of BOM';
        // RDLC only
        CurrReportPageNoCaptLbl: Label 'Page';
        BOMQtyCaptionLbl: Label 'Total Quantity';
        BomCompLevelQtyCaptLbl: Label 'BOM Quantity';
        BomCompLevelDescCaptLbl: Label 'Description';
        BomCompLevelNoCaptLbl: Label 'No.';
        LevelCaptLbl: Label 'Level';
        BomCompLevelUOMCodeCaptLbl: Label 'Unit of Measure Code';
        NoListType: array[99] of Option " ",Item,"Production BOM";
#pragma warning disable AA0470
        ProdBomErr: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.';
#pragma warning restore AA0470

    protected var
        BomComponent: array[99] of Record "Production BOM Line";
        Level: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var Item: Record Item)
    begin
    end;
}

