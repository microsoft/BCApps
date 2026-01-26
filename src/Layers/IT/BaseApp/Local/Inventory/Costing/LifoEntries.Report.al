// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Company;

report 12123 "Lifo Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Costing/LifoEntries.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Lifo Entries';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Lifo Band"; "Lifo Band")
        {
            RequestFilterFields = "Competence Year", "Lifo Category", "Item No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Lifo_Band__Competence_Year_; Format("Competence Year"))
            {
            }
            column(Lifo_Band__Absorbed_Quantity_; "Absorbed Quantity")
            {
            }
            column(Lifo_Band__Residual_Quantity_; "Residual Quantity")
            {
            }
            column(Lifo_Band__Increment_Quantity_; "Increment Quantity")
            {
            }
            column(Lifo_Band_CMP; CMP)
            {
            }
            column(Lifo_Band__Increment_Value_; "Increment Value")
            {
            }
            column(Lifo_Band__Qty_not_Invoiced_; "Qty not Invoiced")
            {
            }
            column(Lifo_Band__Amount_not_Invoiced_; "Amount not Invoiced")
            {
            }
            column(Lifo_Band__Invoiced_Quantity_; "Invoiced Quantity")
            {
            }
            column(Lifo_Band__Invoiced_Amount_; "Invoiced Amount")
            {
            }
            column(Lifo_Band__Item_No__; "Item No.")
            {
            }
            column(IsLine1; (not Positive) or (CompYearBlank))
            {
            }
            column(CMPText; StrSubstNo('%1', CMP))
            {
            }
            column(Lifo_Band__Item_No___Control1130045; "Item No.")
            {
            }
            column(Lifo_Band__Competence_Year__Control1130046; Format("Competence Year"))
            {
            }
            column(Lifo_Band_CMP_Control1130047; CMP)
            {
            }
            column(Lifo_Band__Invoiced_Amount__Control1130048; "Invoiced Amount")
            {
            }
            column(Lifo_Band__Invoiced_Quantity__Control1130049; "Invoiced Quantity")
            {
            }
            column(Lifo_Band__Amount_not_Invoiced__Control1130050; "Amount not Invoiced")
            {
            }
            column(Lifo_Band__Qty_not_Invoiced__Control1130051; "Qty not Invoiced")
            {
            }
            column(Lifo_Band__Increment_Quantity__Control1130052; "Increment Quantity")
            {
            }
            column(AbsorbedQty; AbsorbedQty)
            {
            }
            column(ResidualQty; ResidualQty)
            {
            }
            column(IncrementValue; IncrementValue)
            {
            }
            column(IsLine2; (not CompYearBlank) and (Positive))
            {
            }
            column(Lifo_Band__Increment_Quantity__Control1130021; "Increment Quantity")
            {
            }
            column(NotDefMsg; NotDefMsg)
            {
            }
            column(InventoryValue; InventoryValue)
            {
            }
            column(IsFooter; ShowTotals)
            {
            }
            column(Lifo_Band_Entry_No_; "Entry No.")
            {
            }
            column(Item_Fiscal_LIFO_ReportCaption; Item_Fiscal_LIFO_ReportCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(USERIDCaption; USERIDCaptionLbl)
            {
            }
            column(Lifo_Band__Competence_Year_Caption; Lifo_Band__Competence_Year_CaptionLbl)
            {
            }
            column(Lifo_Band__Absorbed_Quantity_Caption; FieldCaption("Absorbed Quantity"))
            {
            }
            column(Lifo_Band__Residual_Quantity_Caption; FieldCaption("Residual Quantity"))
            {
            }
            column(Lifo_Band__Increment_Quantity_Caption; FieldCaption("Increment Quantity"))
            {
            }
            column(Lifo_Band_CMPCaption; FieldCaption(CMP))
            {
            }
            column(Lifo_Band__Increment_Value_Caption; FieldCaption("Increment Value"))
            {
            }
            column(Lifo_Band__Qty_not_Invoiced_Caption; FieldCaption("Qty not Invoiced"))
            {
            }
            column(Lifo_Band__Amount_not_Invoiced_Caption; FieldCaption("Amount not Invoiced"))
            {
            }
            column(Lifo_Band__Invoiced_Quantity_Caption; FieldCaption("Invoiced Quantity"))
            {
            }
            column(Lifo_Band__Invoiced_Amount_Caption; FieldCaption("Invoiced Amount"))
            {
            }
            column(Lifo_Band__Item_No__Caption; FieldCaption("Item No."))
            {
            }
            column(InventoryCaption; InventoryCaptionLbl)
            {
            }
            column(Final_RemainingCaption; Final_RemainingCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Positive then begin
                    if "Residual Quantity" <> 0 then
                        InventoryValue := InventoryValue + "Increment Value";
                    if not CompYearBlank then
                        ValuesCalculation();
                end;
            end;

            trigger OnPreDataItem()
            begin
                InventoryValue := 0;
                ShowTotals := true;
                LifoBand2.Reset();

                if not CompYearBlank then begin
                    MarkFilteredRec();

                    if Count = 1 then
                        ShowTotals := false;
                end;
            end;
        }
    }

    requestpage
    {
        Caption = 'LIFO Entries';
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

    trigger OnPreReport()
    begin
        CompYearBlank := true;

        if "Lifo Band".GetFilter("Competence Year") <> '' then
            CompYearBlank := false;

        CompanyInfo.Get();
        "Lifo Band".SetRange(Definitive, false);
        if "Lifo Band".FindFirst() then
            NotDefMsg := Text1033;
    end;

    var
        CompanyInfo: Record "Company Information";
        LifoBand2: Record "Lifo Band";
        NotDefMsg: Text[250];
        InventoryValue: Decimal;
        AbsorbedQty: Decimal;
        ResidualQty: Decimal;
        IncrementValue: Decimal;
        CompYearBlank: Boolean;
        ShowTotals: Boolean;
        Text1033: Label 'Warning: Not all LIFO Bands are final, the current report is a draft.';
        Item_Fiscal_LIFO_ReportCaptionLbl: Label 'Item Fiscal LIFO Report';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        USERIDCaptionLbl: Label 'User :';
        Lifo_Band__Competence_Year_CaptionLbl: Label 'Competence Year';
        InventoryCaptionLbl: Label 'Inventory';
        Final_RemainingCaptionLbl: Label 'Final Remaining';

    [Scope('OnPrem')]
    procedure MarkFilteredRec()
    var
        LifoBand3: Record "Lifo Band";
    begin
        if (not CompYearBlank) then begin
            LifoBand3.Reset();
            LifoBand3.CopyFilters("Lifo Band");
            if LifoBand3.FindSet() then
                repeat
                    if LifoBand2.Get(LifoBand3."Entry No.") then
                        LifoBand2.Mark(true);
                until LifoBand3.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValuesCalculation()
    begin
        if LifoBand2.FindSet() then begin
            AbsorbedQty := "Lifo Band"."Absorbed Quantity";
            ResidualQty := "Lifo Band"."Residual Quantity";
            IncrementValue := "Lifo Band"."Increment Value";
            repeat
                if (not LifoBand2.Mark()) and
                   (LifoBand2."Closed by Entry No." = "Lifo Band"."Entry No.")
                then begin
                    AbsorbedQty += LifoBand2."Increment Quantity";
                    ResidualQty += -LifoBand2."Residual Quantity";
                    IncrementValue += -LifoBand2."Increment Value";
                    InventoryValue += -LifoBand2."Increment Value";
                end;
            until LifoBand2.Next() = 0;
        end;
    end;
}

