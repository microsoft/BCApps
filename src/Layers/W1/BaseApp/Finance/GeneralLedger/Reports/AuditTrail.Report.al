// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

report 330 "Audit Trail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/AuditTrail.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Audit Trail';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";

            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(G_L_Register_TableCaption_GLRegFilter; TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter)
            {
            }
            column(G_L_Register_No; "No.")
            {
            }
            column(G_L_Register_From_Entry_No; "From Entry No.")
            {
            }
            column(G_L_Register_To_Entry_No; "To Entry No.")
            {
            }
            column(G_L_Register_Creation_Date; Format(DT2Date(SystemCreatedAt), 0, 0))
            {
            }
            column(G_L_Register_Creation_Time; Format(DT2Time(SystemCreatedAt), 0, 0))
            {
            }
            column(G_L_Register_User_ID; "User ID")
            {
            }
            column(G_L_Register_Reversed; Reversed)
            {
            }
            column(G_L_RegisterCaption; G_L_AuditCaptionLbl)
            {
            }
            column(CurrReport_PageNoCaption; CurrReport_PageNoCaptionLbl)
            {
            }
            column(G_L_Entry_Posting_Date_Caption; G_L_Entry_Posting_Date_CaptionLbl)
            {
            }
            column(G_L_Entry_Document_Type_Caption; G_L_Entry_Document_Type_CaptionLbl)
            {
            }
            column(G_L_Entry_Document_No_Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry_G_L_Account_No_Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(GLAcc_NameCaption; GLAcc_NameCaptionLbl)
            {
            }
            column(G_L_Entry_Source_Currency_Amount_Caption; G_L_Entry_Source_Currency_Amount_CaptionLbl)
            {
            }
            column(G_L_Entry_Source_Currency_Code_Caption; G_L_Entry_Source_Currency_Code_CaptionLbl)
            {
            }
            column(G_L_Entry_Source_Code_Caption; G_L_Entry_Source_Code_CaptionLbl)
            {
            }
            column(G_L_Entry_System_Created_Entry_Caption; G_L_Entry_System_Created_Entry_CaptionLbl)
            {
            }
            column(G_L_Entry_Source_Type_Caption; G_L_Entry_Source_Type_CaptionLbl)
            {
            }
            column(G_L_Entry_Source_No_Caption; G_L_Entry_Source_No_CaptionLbl)
            {
            }
            column(G_L_Entry_External_Document_No_Caption; G_L_Entry_External_Document_No_CaptionLbl)
            {
            }
            column(G_L_Entry_Document_Date_Caption; G_L_Entry_Document_Date_CaptionLbl)
            {
            }
            column(G_L_Entry_ReversedCaption; G_L_Entry_ReversedCaptionLbl)
            {
            }
            column(G_L_Entry_Reversed_by_Entry_No_Caption; G_L_Entry_Reversed_by_Entry_No_CaptionLbl)
            {
            }
            column(G_L_Entry_Reversed_Entry_No_Caption; G_L_Entry_Reversed_Entry_No_CaptionLbl)
            {
            }
            column(G_L_Entry_AmountCaption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(G_L_Entry_Entry_No_Caption; "G/L Entry".FieldCaption("Entry No."))
            {
            }
            column(G_L_Register_No_Caption; G_L_Register_No_CaptionLbl)
            {
            }
            column(G_L_Register_From_Entry_No_Caption; G_L_Register_From_Entry_No_CaptionLbl)
            {
            }
            column(G_L_Register_To_Entry_No_Caption; G_L_Register_To_Entry_No_CaptionLbl)
            {
            }
            column(G_L_Register_Creation_Date_Caption; G_L_Register_Creation_Date_CaptionLbl)
            {
            }
            column(G_L_Register_Creation_Time_Caption; G_L_Register_Creation_Time_CaptionLbl)
            {
            }
            column(G_L_Register_User_ID_Caption; G_L_Register_User_ID_CaptionLbl)
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Entry No.");

                column(G_L_Entry_Posting_Date; Format("Posting Date"))
                {
                }
                column(G_L_Entry_Document_Type; "Document Type")
                {
                }
                column(G_L_Entry_Document_No; "Document No.")
                {
                }
                column(G_L_Entry_G_L_Account_No; "G/L Account No.")
                {
                }
                column(GLAcc_Name; GLAcc.Name)
                {
                }
                column(G_L_Entry_Amount; Amount)
                {
                }
                column(G_L_Entry_Entry_No; "Entry No.")
                {
                }
                column(G_L_Entry_Source_Currency_Amount; "Source Currency Amount")
                {
                }
                column(G_L_Entry_Source_Currency_Code; "Source Currency Code")
                {
                }
                column(G_L_Entry_Source_Code; "Source Code")
                {
                }
                column(G_L_Entry_System_Created_Entry; "System-Created Entry")
                {
                }
                column(G_L_Entry_Source_Type; "Source Type")
                {
                }
                column(G_L_Entry_Source_No; "Source No.")
                {
                }
                column(G_L_Entry_External_Document_No; "External Document No.")
                {
                }
                column(G_L_Entry_Document_Date; Format("Document Date", 0, 0))
                {
                }
                column(G_L_Entry_Reversed; Reversed)
                {
                }
                column(G_L_Entry_Reversed_by_Entry_No; "Reversed by Entry No.")
                {
                }
                column(G_L_Entry_Reversed_Entry_No; "Reversed Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not GLAcc.Get("G/L Account No.") then
                        GLAcc.Init();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                end;
            }
        }
    }

    trigger OnPreReport()
    begin
        GLRegFilter := "G/L Register".GetFilters();
    end;

    var
        GLAcc: Record "G/L Account";
        GLRegFilter: Text;
        G_L_AuditCaptionLbl: Label 'Audit Trail';
        CurrReport_PageNoCaptionLbl: Label 'Page';
        G_L_Entry_Posting_Date_CaptionLbl: Label 'Posting Date';
        G_L_Entry_Document_Type_CaptionLbl: Label 'Document Type';
        GLAcc_NameCaptionLbl: Label 'Name';
        G_L_Register_No_CaptionLbl: Label 'Register No.';
        G_L_Register_From_Entry_No_CaptionLbl: Label 'From Entry No.';
        G_L_Register_To_Entry_No_CaptionLbl: Label 'To Entry No.';
        G_L_Register_Creation_Date_CaptionLbl: Label 'Creation Date';
        G_L_Register_Creation_Time_CaptionLbl: Label 'Creation Time';
        G_L_Register_User_ID_CaptionLbl: Label 'User ID';
        G_L_Entry_Source_Currency_Amount_CaptionLbl: Label 'Source Curr. Amount';
        G_L_Entry_Source_Currency_Code_CaptionLbl: Label 'Source Curr. Code';
        G_L_Entry_Source_Code_CaptionLbl: Label 'Source Code';
        G_L_Entry_System_Created_Entry_CaptionLbl: Label 'System-Created Entry';
        G_L_Entry_Source_Type_CaptionLbl: Label 'Source Type';
        G_L_Entry_Source_No_CaptionLbl: Label 'Source No.';
        G_L_Entry_External_Document_No_CaptionLbl: Label 'External Document No.';
        G_L_Entry_Document_Date_CaptionLbl: Label 'Document Date';
        G_L_Entry_ReversedCaptionLbl: Label 'Reversed';
        G_L_Entry_Reversed_by_Entry_No_CaptionLbl: Label 'Reversed by Entry No.';
        G_L_Entry_Reversed_Entry_No_CaptionLbl: Label 'Reversed Entry No.';
}