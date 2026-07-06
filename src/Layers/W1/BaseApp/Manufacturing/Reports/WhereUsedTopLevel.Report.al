// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

report 99000757 "Where-Used (Top Level)"
{
    ApplicationArea = Manufacturing;
    Caption = 'Where-Used (Top Level)';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = WhereUsedTopLevelExcel;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description";
            column(FormattedToday; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CalcDateFormatted; Text000 + Format(CalculateDate))
            {
            }
            column(CalculateDateFilter; Format(CalculateDate))
            {
            }
            column(ItemTableCaptionItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(Search_Description; "Search Description")
            {
                IncludeCaption = true;
            }
            // RDLC Only 
            column(WhereUsedListTopLevelCapt; WhereUsedListTopLevelCaptLbl)
            {
            }
            // RDLC Only 
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            // RDLC Only 
            column(LevelCodeCaption; LevelCodeCaptionLbl)
            {
            }
            // RDLC Only 
            column(WhereUsedListItemNoCapt; WhereUsedListItemNoCaptLbl)
            {
            }
            // RDLC Only 
            column(WhereUsedListDescCapt; WhereUsedListDescCaptLbl)
            {
            }
            // RDLC Only 
            column(WhereUsedListQtyNeededCapt; WhereUsedListQtyNeededCaptLbl)
            {
            }
            dataitem(BOMLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(WhereUsedListItemNo; WhereUsedList."Item No.")
                {
                }
                column(WhereUsedListDesc; WhereUsedList.Description)
                {
                }
                column(WhereUsedListQtyNeeded; WhereUsedList."Quantity Needed")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(WhereUsedListLevelCode; PadStr('', WhereUsedList."Level Code", ' ') + Format(WhereUsedList."Level Code"))
                {
                }
                column(Sequence; Sequence)
                {
                }
                trigger OnAfterGetRecord()
                begin
                    Sequence += 1;
                    if First then begin
                        if not WhereUsedMgt.FindRecord('-', WhereUsedList) then
                            CurrReport.Break();
                        First := false;
                    end else
                        if WhereUsedMgt.NextRecord(1, WhereUsedList) = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    First := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                WhereUsedMgt.WhereUsedFromItem(Item, CalculateDate, true);
            end;

            trigger OnPreDataItem()
            begin
                OnBeforeOnPreDataItemItem(Item);

                ItemFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Where-Used (Top Level)';
        AboutText = 'Get an overview of where, and in what quantities, you use items in the product structures of other items.';

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
                        ToolTip = 'Specifies the date that you want the calculation done by. Note that the date filter takes version dates into account. The program automatically enters the working date.';
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
        layout(WhereUsedTopLevelExcel)
        {
            Caption = 'Where-Used (Top Level) Excel';
            LayoutFile = './Manufacturing/Reports/WhereUsedTopLevel.xlsx';
            Type = Excel;
        }
#if not CLEAN27
        layout(WhereUsedTopLevelRDLC)
        {
            Caption = 'Where-Used (Top Level) RDLC';
            LayoutFile = './Manufacturing/Reports/WhereUsedTopLevel.rdlc';
            Type = RDLC;
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }
    labels
    {
        WhereUsedListTopLevel = 'Where-Used List (Top Level)';
        // Print worksheet names
        WhereUsedTopLevelPrint = 'Where-Used Top Level (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        // Analysis worksheet name
        WhereUsedTopLevelAnalysis = 'Where-Used Top Level (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        LevelLabel = 'BOM Level';
        ItemNoLabel = 'BOM Item No.';
        DescLabel = 'BOM Item Description';
        QtyNeededLabel = 'Exploded Quantity';
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

    var
        WhereUsedList: Record "Where-Used Line";
        WhereUsedMgt: Codeunit "Where-Used Management";
        ItemFilter: Text;
        CalculateDate: Date;
        First: Boolean;
        Sequence: Integer;

#pragma warning disable AA0074
        Text000: Label 'As of ';
#pragma warning restore AA0074
        // RDLC Only layout field captions. To be removed in a future release along with the RDLC layout.
        WhereUsedListTopLevelCaptLbl: Label 'Where-Used List (Top Level)';
        CurrReportPageNoCaptLbl: Label 'Page';
        LevelCodeCaptionLbl: Label 'Level';
        WhereUsedListItemNoCaptLbl: Label 'No.';
        WhereUsedListDescCaptLbl: Label 'Description';
        WhereUsedListQtyNeededCaptLbl: Label 'Exploded Quantity.';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemItem(var Item: Record Item)
    begin
    end;
}

