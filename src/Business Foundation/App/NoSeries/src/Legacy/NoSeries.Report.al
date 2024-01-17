#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Utilities;

report 21 "No. Series"
{
    Caption = 'No. Series';
    DefaultRenderingLayout = LayoutRdlc;
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Report data is available on page 457 "No. Series Lines". It can be analyzed with either the Data Analysis feature or Open in Excel.';

    dataset
    {
        dataitem("No. Series"; "No. Series")
        {
            RequestFilterFields = "Code";
            column(COMPANYNAME; CompanyProperty.DisplayName())
            {
            }
            column(No__Series__TABLECAPTION__________NoSeriesFilter; TableCaption + ': ' + NoSeriesFilter)
            {
            }
            column(No__Series_Line__TABLECAPTION__________NoSeriesLineFilter; "No. Series Line".TableCaption + ': ' + NoSeriesLineFilter)
            {
            }
            column(No__Series_Code; Code)
            {
            }
            column(No__Series_Description; Description)
            {
            }
            column(No__Series__Default_Nos__; Format("Default Nos."))
            {
            }
            column(No__Series__Manual_Nos__; Format("Manual Nos."))
            {
            }
            column(No__Series__Date_Order_; Format("Date Order"))
            {
            }
            column(No__SeriesCaption; No__SeriesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(No__Series_Line_OpenCaption; No__Series_Line_OpenCaptionLbl)
            {
            }
            column(No__Series_Line__Increment_by_No__Caption; "No. Series Line".FieldCaption("Increment-by No."))
            {
            }
            column(No__Series_Line__Warning_No__Caption; "No. Series Line".FieldCaption("Warning No."))
            {
            }
            column(No__Series_Line__Last_No__Used_Caption; "No. Series Line".FieldCaption("Last No. Used"))
            {
            }
            column(No__Series_Line__Ending_No__Caption; "No. Series Line".FieldCaption("Ending No."))
            {
            }
            column(No__Series_Line__Starting_No__Caption; "No. Series Line".FieldCaption("Starting No."))
            {
            }
            column(No__Series_Line__Starting_Date_Caption; No__Series_Line__Starting_Date_CaptionLbl)
            {
            }
            column(No__Series__Default_Nos__Caption; No__Series__Default_Nos__CaptionLbl)
            {
            }
            column(No__Series__Manual_Nos__Caption; No__Series__Manual_Nos__CaptionLbl)
            {
            }
            column(No__Series__Date_Order_Caption; No__Series__Date_Order_CaptionLbl)
            {
            }
            dataitem("No. Series Line"; "No. Series Line")
            {
                DataItemLink = "Series Code" = field(Code);
                DataItemTableView = sorting("Series Code");
                RequestFilterFields = "Starting Date";
                column(No__Series_Line__Starting_Date_; Format("Starting Date"))
                {
                }
                column(No__Series_Line__Starting_No__; "Starting No.")
                {
                }
                column(No__Series_Line__Ending_No__; "Ending No.")
                {
                }
                column(No__Series_Line__Last_No__Used_; "Last No. Used")
                {
                }
                column(No__Series_Line_Open; Format(Open))
                {
                }
                column(No__Series_Line__Warning_No__; "Warning No.")
                {
                }
                column(No__Series_Line__Increment_by_No__; "Increment-by No.")
                {
                }
                column(No__Series_Line_Series_Code; "Series Code")
                {
                }
            }
            dataitem("No. Series Relationship"; "No. Series Relationship")
            {
                DataItemLink = Code = field(Code);
                DataItemTableView = sorting(Code);
                column(No__Series_Relationship__Series_Code_; "Series Code")
                {
                }
                column(No__Series_Relationship__Series_Description_; "Series Description")
                {
                }
                column(No__Series_Relationship_Code; Code)
                {
                }
                column(Related_No__SeriesCaption; Related_No__SeriesCaptionLbl)
                {
                }
                dataitem(NoSeriesLine2; "No. Series Line")
                {
                    DataItemLink = "Series Code" = field("Series Code");
                    DataItemTableView = sorting("Series Code");
                    column(NoSeriesLine2__Starting_Date_; Format("Starting Date"))
                    {
                    }
                    column(NoSeriesLine2__Starting_No__; "Starting No.")
                    {
                    }
                    column(NoSeriesLine2__Ending_No__; "Ending No.")
                    {
                    }
                    column(NoSeriesLine2__Last_No__Used_; "Last No. Used")
                    {
                    }
                    column(NoSeriesLine2__Warning_No__; "Warning No.")
                    {
                    }
                    column(NoSeriesLine2__Increment_by_No__; "Increment-by No.")
                    {
                    }
                    column(NoSeriesLine2_Open; Format(Open))
                    {
                    }
                    column(NoSeriesLine2_Series_Code; "Series Code")
                    {
                    }
                }
            }
            dataitem(BlankLoop; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
            }
        }
    }
    rendering
    {
        layout(LayoutRdlc)
        {
            Type = RDLC;
            LayoutFile = './NoSeries/src/Legacy/NoSeries.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        NoSeriesFilter := "No. Series".GetFilters();
        NoSeriesLineFilter := "No. Series Line".GetFilters();
    end;

    var
        NoSeriesFilter: Text;
        NoSeriesLineFilter: Text;
        No__SeriesCaptionLbl: Label 'No. Series';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        No__Series_Line_OpenCaptionLbl: Label 'Open';
        No__Series_Line__Starting_Date_CaptionLbl: Label 'Starting Date';
        No__Series__Default_Nos__CaptionLbl: Label 'Default Nos.';
        No__Series__Manual_Nos__CaptionLbl: Label 'Manual Nos.';
        No__Series__Date_Order_CaptionLbl: Label 'Date Order';
        Related_No__SeriesCaptionLbl: Label 'Related No. Series';
}
#endif