// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;

/// <summary>
/// Generates G/L Register report displaying posted journal batches with detailed transaction information.
/// Shows register entries with source document references, posting dates, and associated G/L entries for audit trail purposes.
/// </summary>
/// <remarks>
/// Data sources: G/L Register and G/L Entry tables with detailed transaction and document tracking.
/// Provides comprehensive audit trail showing posting sequences, source documents, and entry distributions.
/// Used for audit procedures, posting verification, and transaction trace-back requirements.
/// </remarks>
report 10019 "G/L Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/GLRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Register';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Source Code";
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
            column(G_L_Register__TABLECAPTION__________GLRegFilter; "G/L Register".TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter)
            {
            }
            column(G_L_Entry__TABLECAPTION__________GLEntryFilter; "G/L Entry".TableCaption + ': ' + GLEntryFilter)
            {
            }
            column(GLEntryFilter; GLEntryFilter)
            {
            }
            column(STRSUBSTNO_Text000__No___; StrSubstNo(Text000, "No."))
            {
            }
            column(SourceCodeText; SourceCodeText)
            {
            }
            column(SourceCode_Description; SourceCode.Description)
            {
            }
            column(G_L_Register_No_; "No.")
            {
            }
            column(Journal_RegisterCaption; Journal_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Entry__Posting_Date_Caption; G_L_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(G_L_Entry__Document_Type_Caption; "G/L Entry".FieldCaption("Document Type"))
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry__G_L_Account_No__Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(G_L_Entry_DescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__Debit_Amount_Caption; "G/L Entry".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry__Credit_Amount_Caption; "G/L Entry".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry__Bal__Account_No__Caption; "G/L Entry".FieldCaption("Bal. Account No."))
            {
            }
            column(G_L_Entry__Source_Type_Caption; G_L_Entry__Source_Type_CaptionLbl)
            {
            }
            column(G_L_Entry__Source_No__Caption; "G/L Entry".FieldCaption("Source No."))
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Entry No.");
                RequestFilterFields = "Posting Date", "Document Type";
                column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(G_L_Entry__Document_Type_; "Document Type")
                {
                }
                column(G_L_Entry__Document_No__; "Document No.")
                {
                }
                column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                {
                }
                column(G_L_Entry_Description; Description)
                {
                }
                column(G_L_Entry__Debit_Amount_; "Debit Amount")
                {
                }
                column(G_L_Entry__Credit_Amount_; "Credit Amount")
                {
                }
                column(G_L_Entry__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(G_L_Entry__Source_Type_; SourceType)
                {
                }
                column(G_L_Entry__Source_No__; "Source No.")
                {
                }
                column(ShowAccountDescriptions; ShowAccountDescriptions)
                {
                }
                column(Sum1; Sum1)
                {
                }
                column(Sum2; Sum2)
                {
                }
                column(GLAcc_Name; GLAcc.Name)
                {
                }
                column(SourceName; SourceName)
                {
                }
                column(STRSUBSTNO_Text001__G_L_Register___No____G_L_Register___To_Entry_No______G_L_Register___From_Entry_No_____1_; StrSubstNo(Text001, "G/L Register"."No.", "G/L Register"."To Entry No." - "G/L Register"."From Entry No." + 1))
                {
                }
                column(G_L_Entry__Debit_Amount__Control43; "Debit Amount")
                {
                }
                column(G_L_Entry__Credit_Amount__Control44; "Credit Amount")
                {
                }
                column(G_L_Entry_Entry_No_; "Entry No.")
                {
                }
                column(G_L_Entry_Dimension_Set_ID; "Dimension Set ID")
                {
                }
                dataitem("Dimension Set Entry"; "Dimension Set Entry")
                {
                    DataItemLink = "Dimension Set ID" = field("Dimension Set ID");
                    DataItemTableView = sorting("Dimension Set ID", "Dimension Code");
                    column(Dimension_Set_Entry__Dimension_Code_; "Dimension Code")
                    {
                    }
                    column(Dimension_Set_Entry__Dimension_Value_Code_; "Dimension Value Code")
                    {
                    }
                    column(Dimension_Set_Entry_Dimension_Set_ID; "Dimension Set ID")
                    {
                    }
                    column(Dimension_Set_Entry__Dimension_Code_Caption; FieldCaption("Dimension Code"))
                    {
                    }
                    column(Dimension_Set_Entry__Dimension_Value_Code_Caption; FieldCaption("Dimension Value Code"))
                    {
                    }
                    column(ShowDimensions; ShowDimensions)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ShowDimensions then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ShowAccountDescriptions then begin
                        if not GLAcc.Get("G/L Account No.") then
                            GLAcc.Init();
                        if ("Source Type" = "Source Type"::" ") and ("IC Partner Code" <> '') then
                            if "Bal. Account Type" <> "Bal. Account Type"::"IC Partner" then
                                MapBalAccType("Bal. Account Type".AsInteger(), "Bal. Account No.")
                            else
                                SetSourceType("Source Type".AsInteger(), "IC Partner Code")
                        else
                            SetSourceType("Source Type".AsInteger(), "Source No.");
                    end;

                    Sum1 := Sum1 + "Debit Amount";
                    Sum2 := Sum2 + "Credit Amount";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");

                    Sum1 := 0;
                    Sum2 := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> SourceCode.Code then
                    if "Source Code" = '' then begin
                        SourceCodeText := '';
                        SourceCode.Init();
                    end else begin
                        SourceCodeText := SourceCode.TableCaption + ': ' + "Source Code";
                        if not SourceCode.Get("Source Code") then
                            SourceCode.Init();
                    end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About G/L Register';
        AboutText = 'The **G/L Register** report provides a batch-wise list of all posted general ledger entries, including entry numbers, posting dates, user IDs, and source descriptions. Use it for auditing, tracing who posted what and when, and verifying financial transaction integrity by filtering entries by source, user, or date';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(IncludeAccountDesc; ShowAccountDescriptions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Account Desc.';
                        ToolTip = 'Specifies if you want to include the name of the general ledger account in the list. If this field is selected, the name will appear on the line below the ledger line where it appears, and each ledger line will use two report lines. Otherwise, the name will not appear and each ledger line will use only one report line.';
                    }
                    field(ShowDimensions; ShowDimensions)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Dimensions';
                        ToolTip = 'Specifies if the register includes dimensions.';
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

    trigger OnInitReport()
    begin
        ShowDimensions := true;
    end;

    trigger OnPreReport()
    begin
        GLRegFilter := "G/L Register".GetFilters();
        GLEntryFilter := "G/L Entry".GetFilters();
        CompanyInformation.Get();
    end;

    var
        GLAcc: Record "G/L Account";
        CompanyInformation: Record "Company Information";
        SourceCode: Record "Source Code";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        FixedAsset: Record "Fixed Asset";
        BankAccount: Record "Bank Account";
        TypeHelper: Codeunit "Type Helper";
        GLRegFilter: Text;
        GLEntryFilter: Text;
        SourceCodeText: Text[30];
        SourceName: Text;
        ShowAccountDescriptions: Boolean;
        ShowDimensions: Boolean;
        Text000: Label 'Register No. %1';
        Text001: Label 'Number of Entries in Register No. %1: %2';
        Sum1: Decimal;
        Sum2: Decimal;
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset",Employee,"IC Partner";
        Journal_RegisterCaptionLbl: Label 'Journal Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        G_L_Entry__Source_Type_CaptionLbl: Label 'Source Type';

    procedure SetSourceType(AccountType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset",Employee,"IC Partner"; AccountNo: Code[20])
    var
        ICParnter: Record "IC Partner";
    begin
        SourceName := '';
        SourceType := SourceType::" ";
        case AccountType of
            AccountType::Customer:
                if Customer.ReadPermission then
                    if Customer.Get(AccountNo) then begin
                        SourceName := Customer.Name;
                        SourceType := AccountType;
                    end;
            AccountType::Vendor:
                if Vendor.ReadPermission then
                    if Vendor.Get(AccountNo) then begin
                        SourceName := Vendor.Name;
                        SourceType := AccountType;
                    end;
            AccountType::Employee:
                if Employee.ReadPermission then
                    if Employee.Get(AccountNo) then begin
                        SourceName := Employee."Last Name";
                        SourceType := AccountType;
                    end;
            AccountType::"Fixed Asset":
                if FixedAsset.ReadPermission then
                    if FixedAsset.Get(AccountNo) then begin
                        SourceName := FixedAsset.Description;
                        SourceType := AccountType;
                    end;
            AccountType::"Bank Account":
                if BankAccount.ReadPermission then
                    if BankAccount.Get(AccountNo) then begin
                        SourceName := BankAccount.Name;
                        SourceType := AccountType;
                    end;
            AccountType::" ":
                if ICParnter.ReadPermission then
                    if ICParnter.Get(AccountNo) then begin
                        SourceName := ICParnter.Name;
                        SourceType := SourceType::"IC Partner";
                    end;
        end;
    end;

    procedure MapBalAccType(BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee; BalAccNo: Code[20])
    begin
        SourceName := '';
        case BalAccType of
            BalAccType::Customer:
                SetSourceType(BalAccType::Customer, "G/L Entry"."Bal. Account No.");
            BalAccType::Vendor:
                SetSourceType(BalAccType::Vendor, "G/L Entry"."Bal. Account No.");
            BalAccType::Employee:
                SetSourceType(BalAccType::Employee, "G/L Entry"."Bal. Account No.");
            BalAccType::"Fixed Asset":
                SetSourceType(BalAccType::"Fixed Asset", "G/L Entry"."Bal. Account No.");
            BalAccType::"Bank Account":
                SetSourceType(BalAccType::"Bank Account", "G/L Entry"."Bal. Account No.");
        end;
    end;
}

