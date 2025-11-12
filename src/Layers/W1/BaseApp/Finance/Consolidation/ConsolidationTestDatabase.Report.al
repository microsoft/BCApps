// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Project.Job;
using System.Utilities;

report 14 "Consolidation - Test Database"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/ConsolidationTestDatabase.rdlc';
    Caption = 'Consolidation - Test Database (same environment)';

    dataset
    {
        dataitem("Business Unit"; "Business Unit")
        {
            DataItemTableView = sorting(Code) where(Consolidate = const(true));
            RequestFilterFields = "Code";
            column(Business_Unit_Code; Code)
            {
            }
            dataitem(Header; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(STRSUBSTNO_Text009_ConsolidStartDate_ConsolidEndDate_; StrSubstNo(Text009, ConsolidStartDate, ConsolidEndDate))
                {
                }
                column(Business_Unit__Code; "Business Unit".Code)
                {
                }
                column(Business_Unit___Company_Name_; "Business Unit"."Company Name")
                {
                }
                column(Business_Unit___Consolidation___; "Business Unit"."Consolidation %")
                {
                }
                column(Business_Unit___Currency_Code_; "Business Unit"."Currency Code")
                {
                }
                column(Business_Unit___Currency_Exchange_Rate_Table_; "Business Unit"."Currency Exchange Rate Table")
                {
                }
                column(Business_Unit___Data_Source_; "Business Unit"."Data Source")
                {
                }
                column(Print_control; Print_control)
                {
                }
                column(Consolidation___Test_DatabaseCaption; Consolidation___Test_DatabaseCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Business_Unit__CodeCaption; "Business Unit".FieldCaption(Code))
                {
                }
                column(Business_Unit___Company_Name_Caption; "Business Unit".FieldCaption("Company Name"))
                {
                }
                column(Business_Unit___Consolidation___Caption; "Business Unit".FieldCaption("Consolidation %"))
                {
                }
                column(Business_Unit___Currency_Code_Caption; "Business Unit".FieldCaption("Currency Code"))
                {
                }
                column(Business_Unit___Currency_Exchange_Rate_Table_Caption; "Business Unit".FieldCaption("Currency Exchange Rate Table"))
                {
                }
                column(Business_Unit___Data_Source_Caption; "Business Unit".FieldCaption("Data Source"))
                {
                }
                column(Selected_dimensions_will_be_copied_Caption; Selected_dimensions_will_be_copied_CaptionLbl)
                {
                }
                dataitem(BusUnitErrorLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(Errors_in_Business_Unit_Caption; Errors_in_Business_Unit_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ClearErrors();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, NextErrorIndex);
                    end;
                }
                dataitem("G/L Account"; "G/L Account")
                {
                    DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
                    PrintOnlyIfDetail = true;
                    column(G_L_Account__No__; "No.")
                    {
                    }
                    column(G_L_Account_Name; Name)
                    {
                    }
                    column(G_L_Account__Consol__Translation_Method_; "Consol. Translation Method")
                    {
                    }
                    column(G_L_Account__Consol__Debit_Acc__; "Consol. Debit Acc.")
                    {
                    }
                    column(G_L_Account__Consol__Credit_Acc__; "Consol. Credit Acc.")
                    {
                    }
                    column(G_L_Account__No__Caption; FieldCaption("No."))
                    {
                    }
                    column(G_L_Account_NameCaption; FieldCaption(Name))
                    {
                    }
                    column(G_L_Account__Consol__Translation_Method_Caption; FieldCaption("Consol. Translation Method"))
                    {
                    }
                    column(G_L_Account__Consol__Debit_Acc__Caption; FieldCaption("Consol. Debit Acc."))
                    {
                    }
                    column(G_L_Account__Consol__Credit_Acc__Caption; FieldCaption("Consol. Credit Acc."))
                    {
                    }
                    dataitem("G/L Entry"; "G/L Entry")
                    {
                        DataItemLink = "G/L Account No." = field("No.");
                        DataItemTableView = sorting("G/L Account No.", "Posting Date");
                        column(EntryNo_GLEntry; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            TempDimBufIn: Record "Dimension Buffer" temporary;
                            TableID: array[10] of Integer;
                            No: array[10] of Code[20];
                            CheckFinished: Boolean;
                        begin
                            if ("Posting Date" <> NormalDate("Posting Date")) and
                               not ConsolidatingClosingDate and
                               not ReportedClosingDateError
                            then begin
                                AddError(StrSubstNo(
                                    Text008, TableCaption(),
                                    FieldCaption("Posting Date"), "Posting Date"));
                                ReportedClosingDateError := true;
                            end;

                            if TempSelectedDim.FindFirst() then begin
                                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                                TempDimBufIn.DeleteAll();
                                if DimSetEntry.FindSet() then begin
                                    repeat
                                        if TempSelectedDim.Get(UserId, 3, REPORT::"Consolidation - Test Database", '', DimSetEntry."Dimension Code") then begin
                                            TempDimBufIn.Init();
                                            TempDimBufIn."Table ID" := DATABASE::"G/L Entry";
                                            TempDimBufIn."Entry No." := "Entry No.";
                                            if TempDim.Get(DimSetEntry."Dimension Code") then
                                                if TempDim."Consolidation Code" <> '' then
                                                    TempDimBufIn."Dimension Code" := TempDim."Consolidation Code"
                                                else
                                                    TempDimBufIn."Dimension Code" := TempDim.Code
                                            else
                                                TempDimBufIn."Dimension Code" := DimSetEntry."Dimension Code";
                                            if TempDimVal.Get(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code") then
                                                if TempDimVal."Consolidation Code" <> '' then
                                                    TempDimBufIn."Dimension Value Code" := TempDimVal."Consolidation Code"
                                                else
                                                    TempDimBufIn."Dimension Value Code" := TempDimVal.Code
                                            else
                                                TempDimBufIn."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                                            TempDimBufIn.Insert();
                                        end;
                                    until DimSetEntry.Next() = 0;

                                    if not DimMgt.CheckDimBuffer(TempDimBufIn) then
                                        AddError(StrSubstNo(
                                            '%1 %2: %3',
                                            TableCaption, "Entry No.",
                                            DimMgt.GetDimCombErr()));

                                    TableID[1] := DATABASE::"G/L Account";
                                    No[1] := "G/L Account No.";
                                    TableID[2] := DATABASE::"G/L Account";
                                    No[2] := "Bal. Account No.";
                                    TableID[3] := DATABASE::Job;
                                    No[3] := "Job No.";
                                    CheckFinished := DimMgt.CheckDimBufferValuePosting(TempDimBufIn, TableID, No);
                                    if not CheckFinished then
                                        AddError(StrSubstNo(
                                            '%1 %2: %3',
                                            TableCaption, "Entry No.",
                                            DimMgt.GetDimValuePostingErr()));
                                end;
                            end;
                            if GLEntryAddedToDataset then
                                CurrReport.Skip();
                            GLEntryAddedToDataset := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Posting Date", ConsolidStartDate, ConsolidEndDate);

                            ReportedClosingDateError := false;
                            GLEntryAddedToDataset := false;
                        end;
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control23; ErrorText[Number])
                        {
                        }
                        column(Errors_in_this_G_L_Account_Caption; Errors_in_this_G_L_Account_CaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ClearErrors();
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, NextErrorIndex);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TestGLAccounts();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Print_control := TempSelectedDim.FindFirst();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField("Company Name");

                ClearErrors();

                if ("Starting Date" <> 0D) or ("Ending Date" <> 0D) then begin
                    if "Starting Date" = 0D then
                        AddError(StrSubstNo(
                            Text031, FieldCaption("Starting Date"),
                            FieldCaption("Ending Date"), "Company Name"));
                    if "Ending Date" = 0D then
                        AddError(StrSubstNo(
                            Text031, FieldCaption("Ending Date"),
                            FieldCaption("Starting Date"), "Company Name"));
                    if "Starting Date" > "Ending Date" then
                        AddError(StrSubstNo(
                            Text032, FieldCaption("Starting Date"),
                            FieldCaption("Ending Date"), "Company Name"));
                end;

                SubsidGLSetup.ChangeCompany("Company Name");
                SubsidGLSetup.Get();
                if (SubsidGLSetup."Additional Reporting Currency" = '') and
                   ("Data Source" = "Data Source"::"Add. Rep. Curr. (ACY)")
                then
                    AddError(StrSubstNo(
                        Text020,
                        FieldCaption("Data Source"),
                        TableCaption,
                        "Data Source",
                        SubsidGLSetup.FieldCaption("Additional Reporting Currency")));

                "G/L Account".ChangeCompany("Company Name");
                "G/L Entry".ChangeCompany("Company Name");
                DimSetEntry.ChangeCompany("Company Name");
                Dim.ChangeCompany("Company Name");
                TempDim.Reset();
                TempDim.DeleteAll();
                if Dim.Find('-') then
                    repeat
                        TempDim.Init();
                        TempDim := Dim;
                        TempDim.Insert();
                    until Dim.Next() = 0;

                TempConsolidDim.Reset();
                TempConsolidDim.DeleteAll();
                if ConsolidDim.Find('-') then
                    repeat
                        TempConsolidDim.Init();
                        TempConsolidDim := ConsolidDim;
                        TempConsolidDim.Insert();
                    until ConsolidDim.Next() = 0;

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Consolidation - Test Database");
                TempSelectedDim.Reset();
                TempSelectedDim.DeleteAll();
                if SelectedDim.Find('-') then
                    repeat
                        TempSelectedDim.Init();
                        TempSelectedDim := SelectedDim;
                        if not TempDim.Get(SelectedDim."Dimension Code") then begin
                            TempDim.SetRange("Consolidation Code", SelectedDim."Dimension Code");
                            if TempDim.FindFirst() then
                                TempSelectedDim."Dimension Code" := TempDim.Code
                            else
                                AddError(StrSubstNo(
                                    Text016,
                                    SelectedDim.TableCaption(), SelectedDim."Dimension Code", "Company Name"));
                        end else
                            if TempDim."Consolidation Code" <> '' then
                                if not TempConsolidDim.Get(TempDim."Consolidation Code") then
                                    AddError(StrSubstNo(
                                        Text017,
                                        SelectedDim.FieldCaption("Dimension Code"), TempDim.Code, "Company Name",
                                        TempDim.FieldCaption("Consolidation Code"), TempDim."Consolidation Code",
                                        CompanyName));
                        TempSelectedDim.Insert();
                    until SelectedDim.Next() = 0;

                TempDim.Reset();
                TempDimVal.Reset();
                TempDimVal.DeleteAll();
                DimVal.ChangeCompany("Company Name");
                if DimVal.Find('-') then
                    repeat
                        TempDimVal.Init();
                        TempDimVal := DimVal;
                        TempDimVal.Insert();
                    until DimVal.Next() = 0;

                TempConsolidDimVal.Reset();
                TempConsolidDimVal.DeleteAll();
                if ConsolidDimVal.Find('-') then
                    repeat
                        TempConsolidDimVal.Init();
                        TempConsolidDimVal := ConsolidDimVal;
                        TempConsolidDimVal.Insert();
                    until ConsolidDimVal.Next() = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Consolidation Period")
                    {
                        Caption = 'Consolidation Period';
                        field(StartingDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which the business units'' entries will be tested. If a business unit has a different fiscal year than the consolidated company, its starting and ending dates must be entered in the Business Unit table.';
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the last date in the period from which the business units'' entries will be tested.';
                        }
                    }
                    group("Copy Field Contents")
                    {
                        Caption = 'Copy Field Contents';
                        field(CopyDimensions; ColumnDim)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Copy Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies dimensions that are to be copied.';

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Consolidation - Test Database", ColumnDim);
                            end;
                        }
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
        if ConsolidStartDate = 0D then
            Error(Text004);
        if ConsolidEndDate = 0D then
            Error(Text005);
        ConsolidatingClosingDate :=
          (ConsolidStartDate = ConsolidEndDate) and
          (ConsolidStartDate <> NormalDate(ConsolidStartDate));
        if (ConsolidStartDate <> NormalDate(ConsolidStartDate)) and
           (ConsolidStartDate <> ConsolidEndDate)
        then
            Error(Text007);

        DimSelectionBuf.CompareDimText(
          3, REPORT::"Consolidation - Test Database", '', ColumnDim, Text015);
    end;

    var
        ConsolidGLAcc: Record "G/L Account";
        SubsidGLSetup: Record "General Ledger Setup";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        Dim: Record Dimension;
        DimVal: Record "Dimension Value";
        TempDim: Record Dimension temporary;
        TempDimVal: Record "Dimension Value" temporary;
        ConsolidDim: Record Dimension;
        ConsolidDimVal: Record "Dimension Value";
        TempConsolidDim: Record Dimension temporary;
        TempConsolidDimVal: Record "Dimension Value" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        DimMgt: Codeunit DimensionManagement;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        ColumnDim: Text[250];
        NextErrorIndex: Integer;
        ConsolidatingClosingDate: Boolean;
        ReportedClosingDateError: Boolean;
        GLEntryAddedToDataset: Boolean;
        ErrorText: array[100] of Text[250];
        Print_control: Boolean;

#pragma warning disable AA0074
        Text004: Label 'Enter the starting date for the consolidation period.';
        Text005: Label 'Enter the ending date for the consolidation period.';
        Text007: Label 'When using closing dates, the starting and ending dates must be the same.';
#pragma warning disable AA0470
        Text008: Label 'A %1 with %2 on a closing date (%3) was found while consolidating non-closing entries.';
        Text009: Label 'Period: %1..%2';
#pragma warning restore AA0470
        Text015: Label 'Copy Dimensions';
#pragma warning disable AA0470
        Text016: Label '%1 %2 doesn''t exist in %3.';
        Text017: Label '%1 %2 in %3 has a %4 %5 that doesn''t exist in %6.';
        Text018: Label 'There are more than %1 errors.';
        Text020: Label '%1 for this %2 is set to %3, but there is no %4 set up in the %2.';
        Text021: Label 'Within the Subsidiary (%5), there are two G/L Accounts: %1 and %4; which refer to the same %2, but with a different %3.';
        Text022: Label '%1 %2, referenced by Subsidiary (%5) %3 %4, does not exist in the Consolidated %3 table.';
        Text023: Label 'Subsidiary (%7) %1 %2 must have the same %3 as Consolidated %1 %4.  (%5 <> %6)';
        Text031: Label '%1 must not be empty when %2 is not empty, in company %3.';
        Text032: Label 'The %1 is later than the %2 in company %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Consolidation___Test_DatabaseCaptionLbl: Label 'Consolidation - Test Database';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Selected_dimensions_will_be_copied_CaptionLbl: Label 'Selected dimensions will be copied.';
        Errors_in_Business_Unit_CaptionLbl: Label 'Errors in Business Unit:';
        Errors_in_this_G_L_Account_CaptionLbl: Label 'Errors in this G/L Account:';
        AccountDoesNotExistTxt: Label '%1 %2 referenced by Subsidiary (%3) does not exist in the Consolidated %1 table.', Comment = '%1 is G/L Account, %2 is G/L Account No., %3 Business Unit';

    local procedure AddError(Text: Text[250])
    begin
        if NextErrorIndex = ArrayLen(ErrorText) then
            ErrorText[NextErrorIndex] := StrSubstNo(Text018, ArrayLen(ErrorText))
        else begin
            NextErrorIndex := NextErrorIndex + 1;
            ErrorText[NextErrorIndex] := Text;
        end;
    end;

    local procedure ClearErrors()
    begin
        Clear(ErrorText);
        NextErrorIndex := 0;
    end;

    local procedure TestGLAccounts()
    var
        AccountToTest: Record "G/L Account";
    begin
        // First test within the Subsidiary Chart of Accounts
        AccountToTest := "G/L Account";
        if AccountToTest.TranslationMethodConflict("G/L Account") then begin
            if "G/L Account".GetFilter("Consol. Debit Acc.") <> '' then
                AddError(StrSubstNo(
                    Text021,
                    "G/L Account"."No.",
                    "G/L Account".FieldCaption("Consol. Debit Acc."),
                    "G/L Account".FieldCaption("Consol. Translation Method"),
                    AccountToTest."No.", "Business Unit".TableCaption()))
            else
                AddError(StrSubstNo(
                    Text021,
                    "G/L Account"."No.",
                    "G/L Account".FieldCaption("Consol. Credit Acc."),
                    "G/L Account".FieldCaption("Consol. Translation Method"),
                    AccountToTest."No.", "Business Unit".TableCaption()));
        end else begin
            "G/L Account".Reset();
            "G/L Account".FilterGroup(2);
            "G/L Account".SetRange("Account Type", "G/L Account"."Account Type"::Posting);
            "G/L Account" := AccountToTest;
            "G/L Account".Find('=');
        end;
        // Then, test for conflicts between subsidiary and parent (consolidated)
        if "G/L Account"."Consol. Debit Acc." <> '' then begin
            if not ConsolidGLAcc.Get("G/L Account"."Consol. Debit Acc.") then
                AddError(StrSubstNo(
                    Text022,
                    "G/L Account".FieldCaption("Consol. Debit Acc."), "G/L Account"."Consol. Debit Acc.",
                    "G/L Account".TableCaption(), "G/L Account"."No.", "Business Unit".TableCaption()))
            else
                CheckConsolTranslationMethod();
        end else
            if not ConsolidGLAcc.Get(AccountToTest."No.") then
                AddError(StrSubstNo(
                    AccountDoesNotExistTxt,
                    "G/L Account".TableCaption(), "G/L Account"."No.", "Business Unit".TableCaption()))
            else
                CheckConsolTranslationMethod();

        if "G/L Account"."Consol. Debit Acc." = "G/L Account"."Consol. Credit Acc." then
            exit;

        if "G/L Account"."Consol. Credit Acc." <> '' then begin
            if not ConsolidGLAcc.Get("G/L Account"."Consol. Credit Acc.") then
                AddError(StrSubstNo(
                    Text022,
                    "G/L Account".FieldCaption("Consol. Credit Acc."), "G/L Account"."Consol. Credit Acc.",
                    "G/L Account".TableCaption(), "G/L Account"."No.", "Business Unit".TableCaption()))
            else
                CheckConsolTranslationMethod();
        end else
            if not ConsolidGLAcc.Get(AccountToTest."No.") then
                AddError(StrSubstNo(
                    AccountDoesNotExistTxt,
                    "G/L Account".TableCaption(), "G/L Account"."No.", "Business Unit".TableCaption()))
            else
                CheckConsolTranslationMethod();
    end;

    local procedure CheckConsolTranslationMethod()
    begin
        if "G/L Account"."Consol. Translation Method" <> ConsolidGLAcc."Consol. Translation Method" then
            AddError(StrSubstNo(
                Text023,
                "G/L Account".TableCaption(), "G/L Account"."No.",
                "G/L Account".FieldCaption("Consol. Translation Method"), ConsolidGLAcc."No.",
                "G/L Account"."Consol. Translation Method", ConsolidGLAcc."Consol. Translation Method",
                "Business Unit".TableCaption()));
    end;
}

