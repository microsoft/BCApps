// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Reports;

using Microsoft.Inventory.Counting.Recording;
using System.Utilities;

report 5878 "Phys. Invt. Recording"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Counting/Reports/PhysInvtRecording.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Phys. Invt. Recording';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Phys. Invt. Record Header";

    dataset
    {
        dataitem("Phys. Invt. Record Header"; "Phys. Invt. Record Header")
        {
            DataItemTableView = sorting("Order No.", "Recording No.");
            RequestFilterFields = "Order No.", "Recording No.";
            column(Phys__Invt__Recording_Header_Order_No_; "Order No.")
            {
            }
            column(Phys__Invt__Recording_Header_Recording_No_; "Recording No.")
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
                column(Phys__Invt__Recording_Header___Order_No__; "Phys. Invt. Record Header"."Order No.")
                {
                }
                column(Phys__Invt__Recording_Header__Status; "Phys. Invt. Record Header".Status)
                {
                }
                column(Phys__Invt__Recording_Header___Person_Responsible_; "Phys. Invt. Record Header"."Person Responsible")
                {
                }
                column(Phys__Invt__Recording_Header___Recording_No__; "Phys. Invt. Record Header"."Recording No.")
                {
                }
                column(Phys__Invt__Recording_Header__Description; "Phys. Invt. Record Header".Description)
                {
                }
                column(EmptyString; '')
                {
                }
                column(EmptyString_Control30; '')
                {
                }
                column(EmptyString_Control33; '')
                {
                }
                column(Phys__Invt__Recording_Header__FIELDCAPTION__Person_Recorded__; "Phys. Invt. Record Header".FieldCaption("Person Recorded"))
                {
                }
                column(Phys__Invt__Recording_Header__FIELDCAPTION__Date_Recorded__; "Phys. Invt. Record Header".FieldCaption("Date Recorded"))
                {
                }
                column(Phys__Invt__Recording_Header__FIELDCAPTION__Time_Recorded__; "Phys. Invt. Record Header".FieldCaption("Time Recorded"))
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Phys__Inventory_RecordingCaption; Phys__Inventory_RecordingCaptionLbl)
                {
                }
                column(Phys__Invt__Recording_Header___Order_No__Caption; "Phys. Invt. Record Header".FieldCaption("Order No."))
                {
                }
                column(Phys__Invt__Recording_Header__StatusCaption; "Phys. Invt. Record Header".FieldCaption(Status))
                {
                }
                column(Phys__Invt__Recording_Header___Person_Responsible_Caption; "Phys. Invt. Record Header".FieldCaption("Person Responsible"))
                {
                }
                column(Phys__Invt__Recording_Header___Recording_No__Caption; "Phys. Invt. Record Header".FieldCaption("Recording No."))
                {
                }
                column(Phys__Invt__Recording_Header__DescriptionCaption; "Phys. Invt. Record Header".FieldCaption(Description))
                {
                }
                dataitem("Phys. Invt. Record Line"; "Phys. Invt. Record Line")
                {
                    DataItemLink = "Order No." = field("Order No."), "Recording No." = field("Recording No.");
                    DataItemLinkReference = "Phys. Invt. Record Header";
                    DataItemTableView = sorting("Order No.", "Recording No.", "Line No.");
                    column(Phys__Invt__Recording_Line__FIELDCAPTION_Quantity_; FieldCaption(Quantity))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Item_No__; "Item No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Location_Code_; "Location Code")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Bin_Code_; "Bin Code")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Serial_No_; "Serial No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Lot_No_; "Lot No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line_Description; Description)
                    {
                    }
                    column(Phys__Invt__Recording_Line__Unit_of_Measure_Code_; "Unit of Measure Code")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Variant_Code_; "Variant Code")
                    {
                    }
                    column(EmptyString_Control20; '')
                    {
                    }
                    column(Phys__Invt__Recording_Line_Order_No_; "Order No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line_Recording_No_; "Recording No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Phys__Invt__Recording_Line__Item_No__Caption; FieldCaption("Item No."))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Location_Code_Caption; FieldCaption("Location Code"))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                    {
                    }
                    column(Phys__Invt__Recording_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Unit_of_Measure_Code_Caption; FieldCaption("Unit of Measure Code"))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Serial_No__Caption; FieldCaption("Serial No."))
                    {
                    }
                    column(Phys__Invt__Recording_Line__Lot_No__Caption; FieldCaption("Lot No."))
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
        Phys__Inventory_RecordingCaptionLbl: Label 'Phys. Inventory Recording';
}

