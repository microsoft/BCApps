// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Reflection;

report 10046 "Customer Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Register';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Source Code", "Journal Batch Name";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone('f'))
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(G_L_Register__TABLECAPTION__________FilterString; "G/L Register".TableCaption + ': ' + FilterString)
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION_________FilterString2; "Cust. Ledger Entry".TableCaption + ': ' + FilterString2)
            {
            }
            column(GlobalDim1Code; GlobalDim1Code)
            {
            }
            column(GlobalDim2Code; GlobalDim2Code)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(G_L_Register__No__; "No.")
            {
            }
            column(SourceCodeText; SourceCodeText)
            {
            }
            column(SourceCode_Description; SourceCode.Description)
            {
            }
            column(Customer_RegisterCaption; Customer_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Cust__Ledger_Entry__Applies_to_Doc__No__Caption; "Cust. Ledger Entry".FieldCaption("Applies-to Doc. No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Global_Dimension_1_Code_Caption; "Cust. Ledger Entry".FieldCaption("Global Dimension 1 Code"))
            {
            }
            column(DateCaption; "Cust. Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Cust__Ledger_Entry__Document_Type_Caption; "Cust. Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Cust__Ledger_Entry_DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__Caption; "Cust. Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__Caption; "Cust. Ledger Entry".FieldCaption("Amount (LCY)"))
            {
            }
            column(Cust__Ledger_Entry__Global_Dimension_2_Code_Caption; "Cust. Ledger Entry".FieldCaption("Global Dimension 2 Code"))
            {
            }
            column(G_L_Register__No__Caption; G_L_Register__No__CaptionLbl)
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Customer No.", "Document Type";
                column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                {
                }
                column(Cust__Ledger_Entry__Global_Dimension_1_Code_; "Global Dimension 1 Code")
                {
                }
                column(Cust__Ledger_Entry__Global_Dimension_2_Code_; "Global Dimension 2 Code")
                {
                }
                column(Cust__Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Cust__Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Cust__Ledger_Entry_Description; Description)
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Applies_to_Doc__No__; "Applies-to Doc. No.")
                {
                }
                column(CustomerName; CustomerName)
                {
                }
                column(Cust__L_E___Entry_No__; "Cust. Ledger Entry"."Entry No.")
                {
                }
                column(G_L_Register___To_Entry_No______G_L_Register___From_Entry_No_____1; "G/L Register"."To Entry No." - "G/L Register"."From Entry No." + 1)
                {
                }
                column(Cust__Ledger_Entry__Remaining_Amt___LCY___Control39; "Remaining Amt. (LCY)")
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY___Control40; "Amount (LCY)")
                {
                }
                column(CustomerEntries; CustomerEntries)
                {
                }
                column(Number_of_entries_recorded__this_posting__Caption; Number_of_entries_recorded__this_posting__CaptionLbl)
                {
                }
                column(Number_of_Customer_entries__this_posting__Caption; Number_of_Customer_entries__this_posting__CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Customer.Get("Customer No.") then
                        Clear(Customer);
                    CustomerName := Customer.Name;
                    CustomerEntries := CustomerEntries + 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                    CustomerEntries := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> '' then begin
                    SourceCodeText := SourceCode.TableCaption + ': ' + "Source Code";
                    if not SourceCode.Get("Source Code") then
                        Clear(SourceCode);
                end else begin
                    Clear(SourceCodeText);
                    Clear(SourceCode);
                end;
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                Dimension: Record Dimension;
            begin
                GLSetup.Get();

                if Dimension.Get(GLSetup."Global Dimension 1 Code") then
                    GlobalDim1Code := Dimension."Code Caption";

                if Dimension.Get(GLSetup."Global Dimension 2 Code") then
                    GlobalDim2Code := Dimension."Code Caption";
            end;
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

    trigger OnPreReport()
    begin
        FilterString := "G/L Register".GetFilters();
        FilterString2 := "Cust. Ledger Entry".GetFilters();
        CompanyInformation.Get();
    end;

    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        SourceCode: Record "Source Code";
        TypeHelper: Codeunit "Type Helper";
        CustomerName: Text[100];
        FilterString: Text;
        FilterString2: Text;
        SourceCodeText: Text[50];
        GlobalDim1Code: Text[30];
        GlobalDim2Code: Text[30];
        CustomerEntries: Integer;
        Customer_RegisterCaptionLbl: Label 'Customer Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        NameCaptionLbl: Label 'Name';
        G_L_Register__No__CaptionLbl: Label 'Register No:';
        Number_of_entries_recorded__this_posting__CaptionLbl: Label 'Number of entries recorded (this posting):';
        Number_of_Customer_entries__this_posting__CaptionLbl: Label 'Number of Customer entries (this posting):';

}
