// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

report 1103 "Resource Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Resources/Reports/ResourceRegister.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Resource Register"; "Resource Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Resource_Register__TABLECAPTION__________ResRegFilter; TableCaption + ': ' + ResRegFilter)
            {
            }
            column(ResRegFilter; ResRegFilter)
            {
            }
            column(Resource_Register__No__; "No.")
            {
            }
            column(ChargeableFormat; Format("Res. Ledger Entry".Chargeable))
            {
            }
            column(Res__Ledger_Entry___Total_Price_; "Res. Ledger Entry"."Total Price")
            {
            }
            column(Res__Ledger_Entry___Total_Cost_; "Res. Ledger Entry"."Total Cost")
            {
            }
            column(Resource_RegisterCaption; Resource_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Res__Ledger_Entry_ChargeableCaption; "Res. Ledger Entry".FieldCaption(Chargeable))
            {
            }
            column(Res__Ledger_Entry__Total_Price_Caption; "Res. Ledger Entry".FieldCaption("Total Price"))
            {
            }
            column(Res__Ledger_Entry__Unit_Price_Caption; "Res. Ledger Entry".FieldCaption("Unit Price"))
            {
            }
            column(Res__Ledger_Entry__Unit_of_Measure_Code_Caption; "Res. Ledger Entry".FieldCaption("Unit of Measure Code"))
            {
            }
            column(Res__Ledger_Entry_QuantityCaption; "Res. Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Res__Ledger_Entry__Unit_Cost_Caption; "Res. Ledger Entry".FieldCaption("Unit Cost"))
            {
            }
            column(Res__Ledger_Entry__Total_Cost_Caption; "Res. Ledger Entry".FieldCaption("Total Cost"))
            {
            }
            column(Res__Ledger_Entry__Entry_Type_Caption; "Res. Ledger Entry".FieldCaption("Entry Type"))
            {
            }
            column(Res__Ledger_Entry__Document_No__Caption; "Res. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Res__Ledger_Entry__Posting_Date_Caption; Res__Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Res__Ledger_Entry__Resource_No__Caption; "Res. Ledger Entry".FieldCaption("Resource No."))
            {
            }
            column(Res__Ledger_Entry__Work_Type_Code_Caption; "Res. Ledger Entry".FieldCaption("Work Type Code"))
            {
            }
            column(Res__Ledger_Entry__Entry_No__Caption; "Res. Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Resource_Register__No__Caption; Resource_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Res__Ledger_Entry___Total_Cost_Caption; Res__Ledger_Entry___Total_Cost_CaptionLbl)
            {
            }
            dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Res__Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Res__Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Res__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Res__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Res__Ledger_Entry__Resource_No__; "Resource No.")
                {
                }
                column(Res__Ledger_Entry__Work_Type_Code_; "Work Type Code")
                {
                }
                column(Res__Ledger_Entry__Unit_of_Measure_Code_; "Unit of Measure Code")
                {
                }
                column(Res__Ledger_Entry_Quantity; Quantity)
                {
                }
                column(Res__Ledger_Entry__Unit_Cost_; "Unit Cost")
                {
                }
                column(Res__Ledger_Entry__Total_Cost_; "Total Cost")
                {
                }
                column(Res__Ledger_Entry__Unit_Price_; "Unit Price")
                {
                }
                column(Res__Ledger_Entry__Total_Price_; "Total Price")
                {
                }
                column(Res__Ledger_Entry_Chargeable; Chargeable)
                {
                }
                column(Total_Amount; TotalAmount)
                {
                }
                column(Total_Cost; TotalCost)
                {
                }
                column(TotalSubCost; TotalSubCost)
                {
                }
                column(TotalSubAmount; TotalSubAmount)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalSubCost += "Total Cost";
                    TotalCost += "Total Cost";
                    TotalSubAmount += "Total Price";
                    TotalAmount += "Total Price";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Resource Register"."From Entry No.", "Resource Register"."To Entry No.");
                    TotalSubAmount := 0;
                    TotalSubCost := 0;
                end;
            }

            trigger OnPreDataItem()
            begin
                ResRegFilter := GetFilters();
                TotalAmount := 0;
                TotalCost := 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Resource Register';
        AboutText = 'Document a resource register''s contents for internal or external audits.';

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
        ResRegFilter: Text;
        TotalSubAmount: Decimal;
        TotalAmount: Decimal;
        TotalSubCost: Decimal;
        TotalCost: Decimal;
        Resource_RegisterCaptionLbl: Label 'Resource Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Res__Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Resource_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        Res__Ledger_Entry___Total_Cost_CaptionLbl: Label 'Total';
}

