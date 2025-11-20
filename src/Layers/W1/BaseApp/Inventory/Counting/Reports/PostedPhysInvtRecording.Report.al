// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Reports;

using Microsoft.Inventory.Counting.History;
using System.Utilities;

report 5879 "Posted Phys. Invt. Recording"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Counting/Reports/PostedPhysInvtRecording.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Posted Phys. Invt. Recording';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Posted Phys. Invt. Record Hdr";

    dataset
    {
        dataitem("Posted Phys. Invt. Record Hdr"; "Pstd. Phys. Invt. Record Hdr")
        {
            DataItemTableView = sorting("Order No.", "Recording No.");
            RequestFilterFields = "Order No.", "Recording No.";
            column(Posted_Phys__Invt__Rec__Header_Order_No_; "Order No.")
            {
            }
            column(Posted_Phys__Invt__Rec__Header_Recording_No_; "Recording No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(USERID; UserId)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Order_No__; "Posted Phys. Invt. Record Hdr"."Order No.")
                {
                }
                column(Posted_Phys__Invt__Rec__Header__Status; "Posted Phys. Invt. Record Hdr".Status)
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Person_Responsible_; "Posted Phys. Invt. Record Hdr"."Person Responsible")
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Recording_No__; "Posted Phys. Invt. Record Hdr"."Recording No.")
                {
                }
                column(Posted_Phys__Invt__Rec__Header__Description; "Posted Phys. Invt. Record Hdr".Description)
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Time_Recorded_; Format("Posted Phys. Invt. Record Hdr"."Time Recorded"))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Date_Recorded_; Format("Posted Phys. Invt. Record Hdr"."Date Recorded"))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Person_Recorded_; "Posted Phys. Invt. Record Hdr"."Person Recorded")
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Posted_Phys__Inventory_RecordingCaption; Posted_Phys__Inventory_RecordingCaptionLbl)
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Order_No__Caption; "Posted Phys. Invt. Record Hdr".FieldCaption("Order No."))
                {
                }
                column(Posted_Phys__Invt__Rec__Header__StatusCaption; "Posted Phys. Invt. Record Hdr".FieldCaption(Status))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Person_Responsible_Caption; "Posted Phys. Invt. Record Hdr".FieldCaption("Person Responsible"))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Recording_No__Caption; "Posted Phys. Invt. Record Hdr".FieldCaption("Recording No."))
                {
                }
                column(Posted_Phys__Invt__Rec__Header__DescriptionCaption; "Posted Phys. Invt. Record Hdr".FieldCaption(Description))
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Time_Recorded_Caption; Posted_Phys__Invt__Rec__Header___Time_Recorded_CaptionLbl)
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Date_Recorded_Caption; Posted_Phys__Invt__Rec__Header___Date_Recorded_CaptionLbl)
                {
                }
                column(Posted_Phys__Invt__Rec__Header___Person_Recorded_Caption; "Posted Phys. Invt. Record Hdr".FieldCaption("Person Recorded"))
                {
                }
                dataitem("Pstd. Phys. Invt. Record Line"; "Pstd. Phys. Invt. Record Line")
                {
                    DataItemLink = "Order No." = field("Order No."), "Recording No." = field("Recording No.");
                    DataItemLinkReference = "Posted Phys. Invt. Record Hdr";
                    DataItemTableView = sorting("Order No.", "Recording No.", "Line No.");
                    column(Posted_Phys__Invt__Rec__Line__Item_No__; "Item No.")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Location_Code_; "Location Code")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Bin_Code_; "Bin Code")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_Description; Description)
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Unit_of_Measure_Code_; "Unit of Measure Code")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Variant_Code_; "Variant Code")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_Quantity; Quantity)
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_Order_No_; "Order No.")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_Recording_No_; "Recording No.")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_Line_No_; "Line No.")
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Item_No__Caption; FieldCaption("Item No."))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Location_Code_Caption; FieldCaption("Location Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Unit_of_Measure_Code_Caption; FieldCaption("Unit of Measure Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Rec__Line_QuantityCaption; FieldCaption(Quantity))
                    {
                    }
                }
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Posted_Phys__Inventory_RecordingCaptionLbl: Label 'Posted Phys. Inventory Recording';
        Posted_Phys__Invt__Rec__Header___Time_Recorded_CaptionLbl: Label 'Time Recorded';
        Posted_Phys__Invt__Rec__Header___Date_Recorded_CaptionLbl: Label 'Date Recorded';
}

