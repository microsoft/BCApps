// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Resources.Resource;

report 10198 "Resource Register"
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
            RequestFilterFields = "No.", "Creation Date", "Source Code", "Journal Batch Name";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ResEntryFilter; ResEntryFilter)
            {
            }
            column(ResRegFilter; ResRegFilter)
            {
            }
            column(Resource_Register__TABLECAPTION__________ResRegFilter; "Resource Register".TableCaption + ': ' + ResRegFilter)
            {
            }
            column(Res__Ledger_Entry__TABLECAPTION__________ResEntryFilter; "Res. Ledger Entry".TableCaption + ': ' + ResEntryFilter)
            {
            }
            column(Text000__________FORMAT__No___; Text000 + ': ' + Format("No."))
            {
            }
            column(SourceCodeText; SourceCodeText)
            {
            }
            column(SourceCode_Description; SourceCode.Description)
            {
            }
            column(Resource_Register___No__; "Resource Register"."No.")
            {
            }
            column(Resource_RegisterCaption; Resource_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Res__Ledger_Entry__Resource_No__Caption; "Res. Ledger Entry".FieldCaption("Resource No."))
            {
            }
            column(Res__Ledger_Entry__Document_No__Caption; "Res. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Res__Ledger_Entry_ChargeableCaption; Res__Ledger_Entry_ChargeableCaptionLbl)
            {
            }
            column(Res__Ledger_Entry__Posting_Date_Caption; "Res. Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Res__Ledger_Entry__Entry_Type_Caption; "Res. Ledger Entry".FieldCaption("Entry Type"))
            {
            }
            column(Res__Ledger_Entry__Work_Type_Code_Caption; "Res. Ledger Entry".FieldCaption("Work Type Code"))
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
            column(Res__Ledger_Entry__Unit_Price_Caption; "Res. Ledger Entry".FieldCaption("Unit Price"))
            {
            }
            column(Res__Ledger_Entry__Total_Price_Caption; "Res. Ledger Entry".FieldCaption("Total Price"))
            {
            }
            dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Entry Type", "Posting Date", "Work Type Code";
                column(Res__Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Res__Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Res__Ledger_Entry__Resource_No__; "Resource No.")
                {
                }
                column(Res__Ledger_Entry__Document_No__; "Document No.")
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
                    DecimalPlaces = 2 : 5;
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
                column(Res__Ledger_Entry_Chargeable; Format(Chargeable))
                {
                }
                column(ResDescription; ResDescription)
                {
                }
                column(PrintResourceDescriptions; PrintResourceDescriptions)
                {
                }
                column(Res__Led_Entry___Entry_No__; "Res. Ledger Entry"."Entry No.")
                {
                }
                column(Resource_Register___No___Control43; "Resource Register"."No.")
                {
                }
                column(Resource_Register___To_Entry_No______Resource_Register___From_Entry_No_____1; "Resource Register"."To Entry No." - "Resource Register"."From Entry No." + 1)
                {
                }
                column(Number_of_Entries_in_Register_No_Caption; Number_of_Entries_in_Register_No_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ResDescription := Description;
                    if ResDescription = '' then begin
                        if not Resource.Get("Resource No.") then
                            Resource.Init();
                        ResDescription := Resource.Name;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Resource Register"."From Entry No.", "Resource Register"."To Entry No.")
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> '' then begin
                    SourceCodeText := FieldCaption("Source Code") + ': ' + "Source Code";
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                end else begin
                    Clear(SourceCodeText);
                    SourceCode.Init();
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Resource Register';
        AboutText = 'Document a resource register''s contents for internal or external audits.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintResourceDescriptions; PrintResourceDescriptions)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Print Resource Desc.';
                        ToolTip = 'Specifies that you want to include a section with the resource description based on the value in the Description field on the resource ledger entry.';
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ResRegFilter := "Resource Register".GetFilters();
        ResEntryFilter := "Res. Ledger Entry".GetFilters();
    end;

    var
        Resource: Record Resource;
        CompanyInformation: Record "Company Information";
        SourceCode: Record "Source Code";
        PrintResourceDescriptions: Boolean;
        ResRegFilter: Text;
        ResEntryFilter: Text;
        ResDescription: Text[100];
        SourceCodeText: Text[50];
        Text000: Label 'Register';
        Resource_RegisterCaptionLbl: Label 'Resource Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Res__Ledger_Entry_ChargeableCaptionLbl: Label 'Chargeable';
        Number_of_Entries_in_Register_No_CaptionLbl: Label 'Number of Entries in Register No.';
}

