// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

report 15 "Consolidation - Test File"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Consolidation/ConsolidationTestFile.rdlc';
    Caption = 'Consolidation - Test File';
    AllowScheduling = false;

    dataset
    {
        dataitem("Business Unit"; "Business Unit")
        {
            DataItemTableView = sorting(Code);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                SetRange(Code, BusUnit.Code);
            end;
        }
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));

            trigger OnAfterGetRecord()
            begin
                "Consol. Debit Acc." := "No.";
                "Consol. Credit Acc." := "No.";
                "Consol. Translation Method" := "Consol. Translation Method"::"Average Rate (Manual)";
                Consolidate.InsertGLAccount("G/L Account");
            end;

            trigger OnPostDataItem()
            begin
                if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
                    CurrReport.Break();

                Consolidate.SetGlobals(
                  '', '', BusUnit."Company Name",
                  SubsidCurrencyCode, AdditionalCurrencyCode, ParentCurrencyCode,
                  0, ConsolidStartDate, ConsolidEndDate);

                // Import G/L entries
                while GLEntryFile.Pos <> GLEntryFile.Len do begin
                    GLEntryFile.Read(TextLine);
                    case CopyStr(TextLine, 1, 4) of
                        '<02>':
                            begin
                                TempGLEntry.Init();
                                Evaluate(TempGLEntry."G/L Account No.", CopyStr(TextLine, 5, 20));
                                Evaluate(TempGLEntry."Posting Date", CopyStr(TextLine, 26, 9));
                                Evaluate(TempGLEntry.Amount, CopyStr(TextLine, 36, 22));
                                if TempGLEntry.Amount > 0 then
                                    TempGLEntry."Debit Amount" := TempGLEntry.Amount
                                else
                                    TempGLEntry."Credit Amount" := -TempGLEntry.Amount;
                                TempGLEntry."Entry No." := Consolidate.InsertGLEntry(TempGLEntry);
                                OnGLAccountOnPostDataItemOnAfterLoopIteration(TempGLEntry, TextLine);
                            end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
                    CurrReport.Break();
            end;
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
            column(Business_Unit___Data_Source_; "Business Unit"."Data Source")
            {
            }
            column(Business_Unit___Currency_Exchange_Rate_Table_; "Business Unit"."Currency Exchange Rate Table")
            {
            }
            column(Business_Unit___Currency_Code_; "Business Unit"."Currency Code")
            {
            }
            column(Business_Unit___Consolidation___; "Business Unit"."Consolidation %")
            {
            }
            column(Business_Unit___Company_Name_; "Business Unit"."Company Name")
            {
            }
            column(Business_Unit__Code; "Business Unit".Code)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Consolidation___Test_FileCaption; Consolidation___Test_FileCaptionLbl)
            {
            }
            column(Business_Unit___Data_Source_Caption; "Business Unit".FieldCaption("Data Source"))
            {
            }
            column(Business_Unit___Currency_Exchange_Rate_Table_Caption; "Business Unit".FieldCaption("Currency Exchange Rate Table"))
            {
            }
            column(Business_Unit___Currency_Code_Caption; "Business Unit".FieldCaption("Currency Code"))
            {
            }
            column(Business_Unit___Consolidation___Caption; "Business Unit".FieldCaption("Consolidation %"))
            {
            }
            column(Business_Unit___Company_Name_Caption; "Business Unit".FieldCaption("Company Name"))
            {
            }
            column(Business_Unit__CodeCaption; "Business Unit".FieldCaption(Code))
            {
            }
            dataitem(BusUnitErrorLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
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
            dataitem(GLAccount; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(AccountType; Format("G/L Account"."Account Type", 0, 2))
                {
                }
                column(G_L_Account___Consol__Credit_Acc__; "G/L Account"."Consol. Credit Acc.")
                {
                }
                column(G_L_Account___Consol__Debit_Acc__; "G/L Account"."Consol. Debit Acc.")
                {
                }
                column(G_L_Account___Consol__Translation_Method_; "G/L Account"."Consol. Translation Method")
                {
                }
                column(G_L_Account__Name; "G/L Account".Name)
                {
                }
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(G_L_Account___Consol__Credit_Acc__Caption; "G/L Account".FieldCaption("Consol. Credit Acc."))
                {
                }
                column(G_L_Account___Consol__Debit_Acc__Caption; "G/L Account".FieldCaption("Consol. Debit Acc."))
                {
                }
                column(G_L_Account___Consol__Translation_Method_Caption; "G/L Account".FieldCaption("Consol. Translation Method"))
                {
                }
                column(G_L_Account__NameCaption; "G/L Account".FieldCaption(Name))
                {
                }
                column(G_L_Account___No__Caption; "G/L Account".FieldCaption("No."))
                {
                }
                dataitem(GLEntry; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            Consolidate.Get1stSubsidGLEntry(TempGLEntry)
                        else
                            Consolidate.GetNxtSubsidGLEntry(TempGLEntry);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, Consolidate.GetNumSubsidGLEntry());
                    end;
                }
                dataitem(ErrorLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    PrintOnlyIfDetail = true;
                    column(ErrorText_Number__Control33; ErrorText[Number])
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
                        Consolidate.GetAccumulatedErrors(NextErrorIndex, ErrorText);
                        SetRange(Number, 1, NextErrorIndex);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Consolidate.Get1stSubsidGLAcc("G/L Account")
                    else
                        Consolidate.GetNxtSubsidGLAcc("G/L Account");
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, Consolidate.GetNumSubsidGLAcc());
                end;
            }
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
                    field(FileFormat; FileFormat)
                    {
                        ApplicationArea = Suite;
                        Caption = 'File Format';
                        ToolTip = 'Specifies the format of the file to be imported.';
                    }
                    field(FileName; FileName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'File Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the file to be imported.';

                        trigger OnAssistEdit()
                        begin
                            UploadFile();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            FileName := '';
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        BusUnit2: Record "Business Unit";
        GLSetup: Record "General Ledger Setup";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ServerFileName = '' then
            Error(Text000);

        Consolidate.SetTestMode(true);
        if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then begin
            Consolidate.ImportFromXML(ServerFileName);
            Consolidate.GetGlobals(
              ProductVersion, FormatVersion, BusUnit."Company Name",
              SubsidCurrencyCode, AdditionalCurrencyCode, ParentCurrencyCode,
              CheckSum, ConsolidStartDate, ConsolidEndDate);
            CalculatedCheckSum := Consolidate.CalcCheckSum();
            if CheckSum <> CalculatedCheckSum then
                AddError(StrSubstNo(Text036, CheckSum, CalculatedCheckSum));
            TransferPerDay := true;
        end else begin
            Clear(GLEntryFile);
            GLEntryFile.TextMode := true;
            GLEntryFile.Open(ServerFileName);
            GLEntryFile.Read(TextLine);
            if CopyStr(TextLine, 1, 4) = '<01>' then begin
                BusUnit."Company Name" := DelChr(CopyStr(TextLine, 5, 30), '>');
                Evaluate(ConsolidStartDate, CopyStr(TextLine, 36, 9));
                Evaluate(ConsolidEndDate, CopyStr(TextLine, 46, 9));
                Evaluate(TransferPerDay, CopyStr(TextLine, 56, 3));
            end;
        end;

        if (BusUnit."Company Name" = '') or (ConsolidStartDate = 0D) or (ConsolidEndDate = 0D) then
            Error(Text001);

        BusUnit.SetCurrentKey("Company Name");
        BusUnit.SetRange("Company Name", BusUnit."Company Name");
        BusUnit.Find('-');
        if BusUnit.Next() <> 0 then
            AddError(StrSubstNo(
                Text005 +
                Text006,
                BusUnit.FieldCaption("Company Name"), BusUnit."Company Name"));
        if not BusUnit.Consolidate then
            AddError(StrSubstNo(
                Text017,
                BusUnit.FieldCaption(Consolidate),
                BusUnit.TableCaption(), BusUnit.Code));

        BusUnit2."File Format" := FileFormat;
        if BusUnit."File Format" <> FileFormat then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   FileFormatQst, BusUnit.FieldCaption("File Format"), BusUnit2."File Format",
                   BusUnit.TableCaption(), BusUnit."File Format"), true)
            then
                CurrReport.Quit()
            else
                AddError(StrSubstNo(
                    Text037, BusUnit.FieldCaption("File Format"), BusUnit2."File Format",
                    BusUnit.TableCaption(), BusUnit."File Format"));

        if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
            if SubsidCurrencyCode = '' then
                SubsidCurrencyCode := BusUnit."Currency Code"
            else begin
                GLSetup.Get();
                if ((SubsidCurrencyCode <> BusUnit."Currency Code") and (BusUnit."Currency Code" <> '')) or
                   ((SubsidCurrencyCode <> GLSetup."LCY Code") and (BusUnit."Currency Code" = ''))
                then
                    AddError(StrSubstNo(
                        Text002,
                        BusUnit.FieldCaption("Currency Code"), SubsidCurrencyCode,
                        BusUnit.TableCaption(), BusUnit."Currency Code"));
            end
        else
            SubsidCurrencyCode := BusUnit."Currency Code";
    end;

    var
        BusUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        Consolidate: Codeunit Consolidate;
        GLEntryFile: File;
        FileName: Text;
        ServerFileName: Text;
        FileFormat: Enum "Business Unit File Format";
        TextLine: Text[250];
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        TransferPerDay: Boolean;
        CheckSum: Decimal;
        CalculatedCheckSum: Decimal;
        ParentCurrencyCode: Code[10];
        SubsidCurrencyCode: Code[10];
        AdditionalCurrencyCode: Code[10];
        ProductVersion: Code[10];
        FormatVersion: Code[10];
        NextErrorIndex: Integer;
        ErrorText: array[100] of Text[250];

#pragma warning disable AA0074
        Text000: Label 'Enter the file name.';
        Text001: Label 'The file to be imported has an unknown format.';
#pragma warning disable AA0470
        Text002: Label 'The %1 in the file to be imported (%2) does not match the %1 in the %3 (%4).';
        Text005: Label 'The business unit %1 %2 is not unique.\\';
        Text006: Label 'Delete %1 in the extra records.';
        Text009: Label 'Period: %1..%2';
        Text017: Label '%1 must be Yes in %2 %3.';
        Text018: Label 'There are more than %1 errors.';
#pragma warning restore AA0470
        Text031: Label 'Import from Text File';
        Text034: Label 'Import from XML File';
#pragma warning disable AA0470
        Text036: Label 'Imported checksum (%1) does not equal the calculated checksum (%2). The file may be corrupt.';
        Text037: Label 'The entered %1, %2, does not equal the %1 on this %3, %4.';
#pragma warning restore AA0470
        Text039: Label 'The file was successfully uploaded to server.';
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Consolidation___Test_FileCaptionLbl: Label 'Consolidation - Test File';
        Errors_in_Business_Unit_CaptionLbl: Label 'Errors in Business Unit:';
        Errors_in_this_G_L_Account_CaptionLbl: Label 'Errors in this G/L Account:';
        FileFormatQst: Label 'The entered %1, %2, does not equal the %1 on this %3, %4.\ Do you want to continue?', Comment = '%1 - field caption, %2 - field value, %3 - table caption, %4 - field value';

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

    local procedure UploadFile()
    var
        FileMgt: Codeunit "File Management";
    begin
        if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
            ServerFileName := FileMgt.UploadFile(Text034, '.xml')
        else
            ServerFileName := FileMgt.UploadFile(Text031, '.txt');

        if ServerFileName <> '' then
            FileName := Text039
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGLAccountOnPostDataItemOnAfterLoopIteration(var TempGLEntry: Record "G/L Entry" temporary; TextLine: Text[250])
    begin
    end;
}

