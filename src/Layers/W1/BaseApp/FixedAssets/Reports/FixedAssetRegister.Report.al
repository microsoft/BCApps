// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;

report 5603 "Fixed Asset Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetRegister.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FA Register"; "FA Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FA_Register__TABLECAPTION__________FARegFilter; TableCaption + ': ' + FARegFilter)
            {
            }
            column(FARegFilter; FARegFilter)
            {
            }
            column(FA_Register__No__; "No.")
            {
            }
            column(Fixed_Asset_RegisterCaption; Fixed_Asset_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Date_Caption; FA_Ledger_Entry__FA_Posting_Date_CaptionLbl)
            {
            }
            column(FA_Ledger_Entry__Document_Type_Caption; "FA Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(FA_Ledger_Entry__Document_No__Caption; "FA Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(FA_Ledger_Entry_DescriptionCaption; "FA Ledger Entry".FieldCaption(Description))
            {
            }
            column(FA_Ledger_Entry__Depreciation_Book_Code_Caption; "FA Ledger Entry".FieldCaption("Depreciation Book Code"))
            {
            }
            column(FA_Ledger_Entry_AmountCaption; "FA Ledger Entry".FieldCaption(Amount))
            {
            }
            column(FA_Ledger_Entry__FA_No__Caption; "FA Ledger Entry".FieldCaption("FA No."))
            {
            }
            column(FA_DescriptionCaption; FA_DescriptionCaptionLbl)
            {
            }
            column(FA_Ledger_Entry__Entry_No__Caption; "FA Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Type_Caption; "FA Ledger Entry".FieldCaption("FA Posting Type"))
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Category_Caption; "FA Ledger Entry".FieldCaption("FA Posting Category"))
            {
            }
            column(FA_Ledger_Entry__Posting_Date_Caption; FA_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(FA_Ledger_Entry__G_L_Entry_No__Caption; "FA Ledger Entry".FieldCaption("G/L Entry No."))
            {
            }
            column(FA_Register__No__Caption; FA_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("FA Ledger Entry"; "FA Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(FA_Ledger_Entry__FA_Posting_Date_; Format("FA Posting Date"))
                {
                }
                column(FA_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(FA_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(FA_Ledger_Entry_Description; Description)
                {
                }
                column(FA_Ledger_Entry__Depreciation_Book_Code_; "Depreciation Book Code")
                {
                }
                column(FA_Ledger_Entry_Amount; Amount)
                {
                }
                column(FA_Ledger_Entry__FA_No__; "FA No.")
                {
                }
                column(FA_Description; FA.Description)
                {
                }
                column(FA_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(FA_Ledger_Entry__FA_Posting_Category_; "FA Posting Category")
                {
                }
                column(FA_Ledger_Entry__FA_Posting_Type_; "FA Posting Type")
                {
                }
                column(FA_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(FA_Ledger_Entry__G_L_Entry_No__; "G/L Entry No.")
                {
                }
                column(CanceledLedgEntry; CanceledLedgEntry)
                {
                }
                column(FAAmonut; FATotalAmount)
                {
                }
                column(TotalCaption_Control33; TotalCaption_Control33Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CanceledLedgEntry := '';
                    if ("FA No." = '') and ("Canceled from FA No." <> '') then begin
                        CanceledLedgEntry := Text000;
                        "FA No." := "Canceled from FA No.";
                    end;
                    if not FA.Get("FA No.") then
                        FA.Init();
                    FATotalAmount := FATotalAmount + Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "FA Register"."From Entry No.", "FA Register"."To Entry No.");
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Fixed Asset Register';
        AboutText = 'The **Fixed Asset Register** report is a comprehensive and structured document that serves as the central repository of all fixed asset transactions done by an organization.';

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
        FARegFilter := "FA Register".GetFilters();
    end;

    var
        FA: Record "Fixed Asset";
        FARegFilter: Text;
        CanceledLedgEntry: Text[30];
        FATotalAmount: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Canceled';
#pragma warning restore AA0074
        Fixed_Asset_RegisterCaptionLbl: Label 'Fixed Asset Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FA_Ledger_Entry__FA_Posting_Date_CaptionLbl: Label 'FA Posting Date';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        FA_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        FA_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control33Lbl: Label 'Total';
}

