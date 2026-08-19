// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Reflection;

report 10108 "AP - Vendor Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/APVendorRegister.rdlc';
    Caption = 'AP - Vendor Register';
    UsageCategory = ReportsAndAnalysis;

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
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(TIME; TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone('f'))
            {
            }
            column(TABLECAPTION__________FilterString; TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Vendor_Ledger_Entry__TABLECAPTION__________FilterString2; "Vendor Ledger Entry".TableCaption + ': ' + FilterString2)
            {
            }
            column(FilterString2; FilterString2)
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
            column(Vendor_Journal_RegisterCaption; Vendor_Journal_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Applies_to_Doc__No__Caption; "Vendor Ledger Entry".FieldCaption("Applies-to Doc. No."))
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; "Vendor Ledger Entry".FieldCaption("Vendor No."))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; "Vendor Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; "Vendor Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amt___LCY__Caption; "Vendor Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY__Caption; "Vendor Ledger Entry".FieldCaption("Amount (LCY)"))
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(VendorNameCaption; VendorNameCaptionLbl)
            {
            }
            column(Register_No_Caption; Register_No_CaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Vendor No.", "Document Type";
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry_Description; Description)
                {
                }
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                {
                }
                column(Vendor_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(Vendor_Ledger_Entry__Applies_to_Doc__No__; "Applies-to Doc. No.")
                {
                }
                column(VendorName; VendorName)
                {
                }
                column(G_L_Register___To_Entry_No______G_L_Register___From_Entry_No_____1; "G/L Register"."To Entry No." - "G/L Register"."From Entry No." + 1)
                {
                }
                column(Vendor_Ledger_Entry__Remaining_Amt___LCY___Control39; "Remaining Amt. (LCY)")
                {
                }
                column(Vendor_Ledger_Entry__Amount__LCY___Control40; "Amount (LCY)")
                {
                }
                column(VendorEntries; VendorEntries)
                {
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Number_of_entries_recorded__this_posting_Caption; Number_of_entries_recorded__this_posting_CaptionLbl)
                {
                }
                column(Number_of_Vendor_entries__this_posting_Caption; Number_of_Vendor_entries__this_posting_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
                    if not Vendor.Get("Vendor No.") then
                        Clear(Vendor);
                    VendorName := Vendor.Name;
                    VendorEntries := VendorEntries + 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                    VendorEntries := 0;
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
        FilterString2 := "Vendor Ledger Entry".GetFilters();
        CompanyInformation.Get();
    end;

    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        SourceCode: Record "Source Code";
        TypeHelper: Codeunit "Type Helper";
        VendorName: Text[100];
        FilterString: Text;
        FilterString2: Text;
        SourceCodeText: Text;
        VendorEntries: Integer;
        Vendor_Journal_RegisterCaptionLbl: Label 'Vendor Journal Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        DescriptionCaptionLbl: Label 'Description';
        VendorNameCaptionLbl: Label 'Name';
        Register_No_CaptionLbl: Label 'Register No:';
        Number_of_entries_recorded__this_posting_CaptionLbl: Label 'Number of entries recorded (this posting)';
        Number_of_Vendor_entries__this_posting_CaptionLbl: Label 'Number of Vendor entries (this posting)';
}
