#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

report 22 "No. Series Check"
{
    Caption = 'No. Series Check';
    DefaultRenderingLayout = LayoutRdlc;
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Report data is available on page 457 "No. Series Lines". It can be analyzed with either the Data Analysis feature or Open in Excel.';

    dataset
    {
        dataitem("No. Series"; "No. Series")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem("No. Series Line"; "No. Series Line")
        {
            DataItemTableView = sorting("Starting No.");
            RequestFilterFields = "Starting Date";
            column(COMPANYNAME; CompanyProperty.DisplayName())
            {
            }
            column(No__Series__TABLECAPTION__________NoSeriesFilter; "No. Series".TableCaption + ': ' + NoSeriesFilter)
            {
            }
            column(NoSeriesFilter; NoSeriesFilter)
            {
            }
            column(NoSeriesLineFilter; NoSeriesLineFilter)
            {
            }
            column(No__Series_Line__Series_Code_; "Series Code")
            {
            }
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
            column(NoSeries2_Description; NoSeries2.Description)
            {
            }
            column(No__Series_CheckCaption; No__Series_CheckCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(No__Series_Line_OpenCaption; CaptionClassTranslate(FieldCaption(Open)))
            {
            }
            column(No__Series_Line__Increment_by_No__Caption; FieldCaption("Increment-by No."))
            {
            }
            column(No__Series_Line__Warning_No__Caption; FieldCaption("Warning No."))
            {
            }
            column(No__Series_Line__Last_No__Used_Caption; FieldCaption("Last No. Used"))
            {
            }
            column(No__Series_Line__Ending_No__Caption; FieldCaption("Ending No."))
            {
            }
            column(No__Series_Line__Starting_No__Caption; FieldCaption("Starting No."))
            {
            }
            column(No__Series_Line__Starting_Date_Caption; No__Series_Line__Starting_Date_CaptionLbl)
            {
            }
            column(NoSeries2_DescriptionCaption; NoSeries2_DescriptionCaptionLbl)
            {
            }
            column(No__Series_Line__Series_Code_Caption; No__Series_Line__Series_Code_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                NoSeries2.Code := "Series Code";
                if not NoSeries2.Find() then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Series Code");
            end;
        }
    }
    rendering
    {
        layout(LayoutRdlc)
        {
            Type = RDLC;
            LayoutFile = './NoSeries/src/Legacy/NoSeriesCheck.rdlc';
        }
    }

    trigger OnPreReport()
    begin
        NoSeriesFilter := "No. Series".GetFilters();
        NoSeriesLineFilter := "No. Series Line".GetFilters();
        NoSeries2.Copy("No. Series");
    end;

    var
        NoSeries2: Record "No. Series";
        NoSeriesFilter: Text;
        NoSeriesLineFilter: Text;
        No__Series_CheckCaptionLbl: Label 'No. Series Check';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        No__Series_Line__Starting_Date_CaptionLbl: Label 'Starting Date';
        NoSeries2_DescriptionCaptionLbl: Label 'Description';
        No__Series_Line__Series_Code_CaptionLbl: Label 'Code';
}
#endif