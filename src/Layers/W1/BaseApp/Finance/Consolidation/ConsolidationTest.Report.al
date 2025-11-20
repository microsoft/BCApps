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

report 1826 "Consolidation - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/ConsolidationTest.rdlc';
    Caption = 'Consolidation - Test';

    dataset
    {
        dataitem(BusUnit; "Business Unit")
        {
            DataItemTableView = sorting(Code) where(Consolidate = const(true));
            RequestFilterFields = "Code";
            UseTemporary = true;
            column(Business_Unit_Code; Code)
            {
            }
            dataitem(Header; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(STRSUBSTNO_Text009_ConsolidStartDate_ConsolidEndDate_; StrSubstNo(Text009Lbl, ConsolidStartDate, ConsolidEndDate))
                {
                }
                column(Business_Unit__Code; BusUnit.Code)
                {
                }
                column(Business_Unit___Company_Name_; BusUnit."Company Name")
                {
                }
                column(Business_Unit___Consolidation___; BusUnit."Consolidation %")
                {
                }
                column(Business_Unit___Currency_Code_; BusUnit."Currency Code")
                {
                }
                column(Business_Unit___Currency_Exchange_Rate_Table_; BusUnit."Currency Exchange Rate Table")
                {
                }
                column(Business_Unit___Data_Source_; BusUnit."Data Source")
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
                column(Business_Unit__CodeCaption; BusUnit.FieldCaption(Code))
                {
                }
                column(Business_Unit___Company_Name_Caption; BusUnit.FieldCaption("Company Name"))
                {
                }
                column(Business_Unit___Consolidation___Caption; BusUnit.FieldCaption("Consolidation %"))
                {
                }
                column(Business_Unit___Currency_Code_Caption; BusUnit.FieldCaption("Currency Code"))
                {
                }
                column(Business_Unit___Currency_Exchange_Rate_Table_Caption; BusUnit.FieldCaption("Currency Exchange Rate Table"))
                {
                }
                column(Business_Unit___Data_Source_Caption; BusUnit.FieldCaption("Data Source"))
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
                                    Text008Txt, TableCaption(),
                                    FieldCaption("Posting Date"), "Posting Date"));
                                ReportedClosingDateError := true;
                            end;

                            if TempSelectedDim.FindFirst() then begin
                                DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                                TempDimBufIn.DeleteAll();
                                if DimSetEntry.FindSet() then begin
                                    repeat
                                        if TempSelectedDim.Get(UserId, 3, REPORT::"Consolidation - Test", '', DimSetEntry."Dimension Code") then begin
                                            TempDimBufIn.Init();
                                            TempDimBufIn."Entry No." := "Entry No.";
                                            TempDimBufIn."Table ID" := DATABASE::"G/L Entry";
                                            if TempDimVal.Get(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code") then
                                                if TempDimVal."Consolidation Code" <> '' then
                                                    TempDimBufIn."Dimension Value Code" := TempDimVal."Consolidation Code"
                                                else
                                                    TempDimBufIn."Dimension Value Code" := TempDimVal.Code
                                            else
                                                TempDimBufIn."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                                            if TempDim.Get(DimSetEntry."Dimension Code") then
                                                if TempDim."Consolidation Code" <> '' then
                                                    TempDimBufIn."Dimension Code" := TempDim."Consolidation Code"
                                                else
                                                    TempDimBufIn."Dimension Code" := TempDim.Code
                                            else
                                                TempDimBufIn."Dimension Code" := DimSetEntry."Dimension Code";
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
                            Text031Txt, FieldCaption("Starting Date"),
                            FieldCaption("Ending Date"), "Company Name"));
                    if "Ending Date" = 0D then
                        AddError(StrSubstNo(
                            Text031Txt, FieldCaption("Ending Date"),
                            FieldCaption("Starting Date"), "Company Name"));
                    if "Starting Date" > "Ending Date" then
                        AddError(StrSubstNo(
                            Text032Txt, FieldCaption("Starting Date"),
                            FieldCaption("Ending Date"), "Company Name"));
                end;

                SubsidGLSetup.ChangeCompany("Company Name");
                SubsidGLSetup.Get();
                if (SubsidGLSetup."Additional Reporting Currency" = '') and
                   ("Data Source" = "Data Source"::"Add. Rep. Curr. (ACY)")
                then
                    AddError(StrSubstNo(
                        Text020Txt,
                        FieldCaption("Data Source"),
                        TableCaption,
                        "Data Source",
                        SubsidGLSetup.FieldCaption("Additional Reporting Currency")));

                "G/L Account".ChangeCompany("Company Name");
                DimSetEntry.ChangeCompany("Company Name");
                "G/L Entry".ChangeCompany("Company Name");
                Dim.ChangeCompany("Company Name");
                TempConsolidDim.Reset();
                TempConsolidDim.DeleteAll();
                if ConsolidDim.Find('-') then
                    repeat
                        TempConsolidDim.Init();
                        TempConsolidDim := ConsolidDim;
                        TempConsolidDim.Insert();
                    until ConsolidDim.Next() = 0;

                TempDim.Reset();
                TempDim.DeleteAll();
                if Dim.Find('-') then
                    repeat
                        TempDim.Init();
                        TempDim := Dim;
                        TempDim.Insert();
                    until Dim.Next() = 0;

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object ID", REPORT::"Consolidation - Test");
                SelectedDim.SetRange("Object Type", 3);
                TempSelectedDim.Reset();
                TempSelectedDim.DeleteAll();
                if SelectedDim.Find('-') then
                    repeat
                        TempSelectedDim.Init();
                        TempSelectedDim := SelectedDim;
                        if TempDim.Get(SelectedDim."Dimension Code") then begin
                            if TempDim."Consolidation Code" <> '' then
                                if not TempConsolidDim.Get(TempDim."Consolidation Code") then
                                    AddError(StrSubstNo(
                                        Text017Txt,
                                        SelectedDim.FieldCaption("Dimension Code"), TempDim.Code, "Company Name",
                                        TempDim.FieldCaption("Consolidation Code"), TempDim."Consolidation Code",
                                        CompanyName));
                        end else begin
                            TempDim.SetRange("Consolidation Code", SelectedDim."Dimension Code");
                            if TempDim.FindFirst() then
                                TempSelectedDim."Dimension Code" := TempDim.Code
                            else
                                AddError(StrSubstNo(
                                    Text016Txt,
                                    SelectedDim.TableCaption(), SelectedDim."Dimension Code", "Company Name"));
                        end;
                        TempSelectedDim.Insert();
                    until SelectedDim.Next() = 0;

                TempDim.Reset();
                TempConsolidDimVal.Reset();
                TempConsolidDimVal.DeleteAll();
                if ConsolidDimVal.Find('-') then
                    repeat
                        TempConsolidDimVal.Init();
                        TempConsolidDimVal := ConsolidDimVal;
                        TempConsolidDimVal.Insert();
                    until ConsolidDimVal.Next() = 0;

                SetTempDimValue(DimVal, TempDimVal, "Company Name");
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
                            ToolTip = 'Specifies the Starting Date.';
                        }
                        field(EndingDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the Ending Date.';
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
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Consolidation - Test", ColumnDim);
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
            Error(Text004Err);
        if ConsolidEndDate = 0D then
            Error(Text005Err);
        ConsolidatingClosingDate :=
          (ConsolidStartDate = ConsolidEndDate) and
          (ConsolidStartDate <> NormalDate(ConsolidStartDate));
        if (ConsolidStartDate <> NormalDate(ConsolidStartDate)) and
           (ConsolidStartDate <> ConsolidEndDate)
        then
            Error(Text007Err);

        DimSelectionBuf.CompareDimText(
          3, REPORT::"Consolidation - Test", '', ColumnDim, Text015Txt);

        CreateBusinessUnits();
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
        BusinessUnit: Record "Business Unit";
        DimMgt: Codeunit DimensionManagement;
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        ColumnDim: Text[250];
        NextErrorIndex: Integer;
        ConsolidatingClosingDate: Boolean;
        ReportedClosingDateError: Boolean;
        GLEntryAddedToDataset: Boolean;
        ErrorText: array[100] of Text[250];
        ConsolidatedCompany: Text[30];
        Print_control: Boolean;

        Text004Err: Label 'Enter the starting date for the consolidation period.';
        Text005Err: Label 'Enter the ending date for the consolidation period.';
        Text007Err: Label 'When using closing dates, the starting and ending dates must be the same.';
        Text008Txt: Label 'A %1 with %2 on a closing date (%3) was found while consolidating non-closing entries.', Comment = '%1=Table Caption for Business Unit table.;%2=Field Caption for Posting Date field.;%3=Posting Date.';
        Text009Lbl: Label 'Period: %1..%2', Comment = '%1=Consolidate Starting Date.;%2=Consolidate Ending Date.';
        Text015Txt: Label 'Copy Dimensions';
        Text016Txt: Label '%1 %2 doesn''t exist in %3.', Comment = '%1=Selected Dimension table caption.;%2=Dimension Code value.; %3=Company Name value.';
        Text017Txt: Label '%1 %2 in %3 has a %4 %5 that doesn''t exist in %6.', Comment = '%1=Field caption for Dimension Code field.;%2=Dimension Code value.;%3=Current Company Name value.;%4=Field caption for Consolidation Code.;%5=Consolidation Code value.;%6=Current Company name.';
        Text018Txt: Label 'There are more than %1 errors.', Comment = '%1=The number of errors reported.';
        Text020Txt: Label '%1 for this %2 is set to %3, but there is no %4 set up in the %2.', Comment = '%1=Field caption for Data Source field.;%2=Table caption for Business Unit table.;%3=Data Source value.;%4=Field caption for Additional Reporting Currency field.';
        Text021Txt: Label 'Within the Subsidiary (%5), there are two G/L Accounts: %1 and %4; which refer to the same %2, but with a different %3.', Comment = '%1=Value of No. field from GL Account table.;%2=Field caption for Consol. Debit Acc. field.;%3=Field caption for Consol. Translation Method field.;%4=No. value from GL Account table.;%5=Caption for Business Unit table.';
        Text022Txt: Label '%1 %2, referenced by Subsidiary (%5) %3 %4, does not exist in the Consolidated %3 table.', Comment = '%1=Field caption for Consol. Debit Acc. field.;%2=Consol. Debit Acc. value from GL Account table.;%3=Caption for GL Account table.;%4=No. value from GL Account table.;%5=Caption for Business Unit table.';
        Text023Txt: Label 'Subsidiary (%7) %1 %2 must have the same %3 as Consolidated %1 %4.  (%5 <> %6)', Comment = '%1=Caption for GL Account table.;%2=Value of No. field from GL Account table.;%3=Caption for Consol. Translation Method field.;%4=Value of No. field from Consolidated GL Account table.;%5=Value of Consol. Translation Method field from GL Account.;%6=Value of Consol. Translation Method from the Consolidated GL Account table.;%7=Caption for Business Unit table.';
        Text031Txt: Label '%1 must not be empty when %2 is not empty, in company %3.', Comment = '%1=Caption for Starting Date field.;%2=Caption for Ending Date field.;%3=Company Name value from Business Unit table.';
        Text032Txt: Label 'The %1 is later than the %2 in company %3.', Comment = '%1=Caption for Starting Date field.;%2=Caption for Ending Date field.;%3=Company Name value from Business Unit table.';
        Consolidation___Test_DatabaseCaptionLbl: Label 'Consolidation - Test Database';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Selected_dimensions_will_be_copied_CaptionLbl: Label 'Selected dimensions will be copied.';
        Errors_in_Business_Unit_CaptionLbl: Label 'Errors in Business Unit:';
        Errors_in_this_G_L_Account_CaptionLbl: Label 'Errors in this G/L Account:';
        AccountDoesNotExistTxt: Label '%1 %2 referenced by Subsidiary (%3) does not exist in the Consolidated %1 table.', Comment = '%1 is "G/L Account", %2 is the G/L Account No., %3 is "Business Unit"';

    local procedure AddError(Text: Text[250])
    begin
        if NextErrorIndex = ArrayLen(ErrorText) then
            ErrorText[NextErrorIndex] := StrSubstNo(Text018Txt, ArrayLen(ErrorText))
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
        GLAccountToTest: Record "G/L Account";
    begin
        // First test within the Subsidiary Chart of Accounts
        GLAccountToTest := "G/L Account";
        if GLAccountToTest.TranslationMethodConflict("G/L Account") then begin
            if "G/L Account".GetFilter("Consol. Debit Acc.") <> '' then
                AddError(StrSubstNo(
                    Text021Txt,
                    "G/L Account"."No.",
                    "G/L Account".FieldCaption("Consol. Debit Acc."),
                    "G/L Account".FieldCaption("Consol. Translation Method"),
                    GLAccountToTest."No.", BusUnit.TableCaption()))
            else
                AddError(StrSubstNo(
                    Text021Txt,
                    "G/L Account"."No.",
                    "G/L Account".FieldCaption("Consol. Credit Acc."),
                    "G/L Account".FieldCaption("Consol. Translation Method"),
                    GLAccountToTest."No.", BusUnit.TableCaption()));
        end else begin
            "G/L Account".Reset();
            "G/L Account".FilterGroup(2);
            "G/L Account".SetRange("Account Type", "G/L Account"."Account Type"::Posting);
            "G/L Account" := GLAccountToTest;
            "G/L Account".Find('=');
        end;
        // Then, test for conflicts between subsidiary and parent (consolidated)
        ConsolidGLAcc.ChangeCompany(ConsolidatedCompany);
        if "G/L Account"."Consol. Debit Acc." <> '' then begin
            if not ConsolidGLAcc.Get("G/L Account"."Consol. Debit Acc.") then
                AddError(StrSubstNo(
                    Text022Txt,
                    "G/L Account".FieldCaption("Consol. Debit Acc."), "G/L Account"."Consol. Debit Acc.",
                    "G/L Account".TableCaption(), "G/L Account"."No.", BusUnit.TableCaption()))
            else
                TestTranslationMethod();
        end else
            if not ConsolidGLAcc.Get(GLAccountToTest."No.") then
                AddError(StrSubstNo(
                    AccountDoesNotExistTxt,
                    "G/L Account".TableCaption(), "G/L Account"."No.", BusUnit.TableCaption()))
            else
                TestTranslationMethod();

        if "G/L Account"."Consol. Debit Acc." = "G/L Account"."Consol. Credit Acc." then
            exit;

        if "G/L Account"."Consol. Credit Acc." <> '' then begin
            if not ConsolidGLAcc.Get("G/L Account"."Consol. Credit Acc.") then
                AddError(StrSubstNo(
                    Text022Txt,
                    "G/L Account".FieldCaption("Consol. Credit Acc."), "G/L Account"."Consol. Credit Acc.",
                    "G/L Account".TableCaption(), "G/L Account"."No.", BusUnit.TableCaption()))
            else
                TestTranslationMethod();
        end else
            if not ConsolidGLAcc.Get(GLAccountToTest."No.") then
                AddError(StrSubstNo(
                    AccountDoesNotExistTxt,
                    "G/L Account".TableCaption(), "G/L Account"."No.", BusUnit.TableCaption()))
            else
                TestTranslationMethod();
    end;

    procedure SetConsolidatedCompany(CompanyName: Text[30])
    begin
        ConsolidatedCompany := CompanyName;
    end;

    local procedure CreateBusinessUnits()
    begin
        BusinessUnit.ChangeCompany(ConsolidatedCompany);
        if BusinessUnit.Find('-') then
            repeat
                BusUnit.TransferFields(BusinessUnit);
                BusUnit.Insert();
            until BusinessUnit.Next() = 0;
    end;

    local procedure SetTempDimValue(var DimVal2: Record "Dimension Value"; var TempDimVal2: Record "Dimension Value" temporary; CompanyName: Text[30])
    begin
        TempDimVal2.Reset();
        TempDimVal2.DeleteAll();
        DimVal2.ChangeCompany(CompanyName);
        if DimVal.Find('-') then
            repeat
                TempDimVal2.Init();
                TempDimVal2 := DimVal2;
                TempDimVal2.Insert();
            until DimVal2.Next() = 0;
    end;

    local procedure TestTranslationMethod()
    begin
        if "G/L Account"."Consol. Translation Method" <> ConsolidGLAcc."Consol. Translation Method" then
            AddError(StrSubstNo(
                Text023Txt,
                "G/L Account".TableCaption(), "G/L Account"."No.",
                "G/L Account".FieldCaption("Consol. Translation Method"), ConsolidGLAcc."No.",
                "G/L Account"."Consol. Translation Method", ConsolidGLAcc."Consol. Translation Method",
                BusUnit.TableCaption()));
    end;
}

