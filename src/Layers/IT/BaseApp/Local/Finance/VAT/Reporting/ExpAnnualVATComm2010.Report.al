// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.IO;
using System.Utilities;

report 12127 "Exp.Annual VAT Comm. - 2010"
{
    Caption = 'Exp.Annual VAT Comm. - 2010';
    ProcessingOnly = true;

    dataset
    {
        dataitem(VATStatementFilters; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
        }
        dataitem("A-Record"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                RecordType: Code[1];
                ProvisionCode: Code[5];
                DataSupplierType: Code[2];
                ExportedText: array[2] of Text[1024];
            begin
                RecordType := 'A';
                ProvisionCode := 'IVC10';
                if CompanyInfo."Tax Representative No." <> '' then
                    DataSupplierType := '10'
                else
                    DataSupplierType := '01';

                ExportedText[1] :=
                  RecordType +
                  PadStr('', 14) +
                  ProvisionCode +
                  DataSupplierType +
                  PadStr(CompanyInfo."Fiscal Code", 16) +
                  PadStr('', 483) +
                  PadStr('', 4, '0') +
                  PadStr('', 4, '0') +
                  PadStr('', 100) +
                  PadStr('', 394);

                ExportedText[2] :=
                  PadStr('', 630) +
                  PadStr('', 44) +
                  PadStr('', 200) +
                  'A';

                ExportFile.TextMode := false;
                ExportFile.Write(ExportedText[1]);
                ExportFile.Seek(ExportFile.Pos - 2);
                ExportFile.TextMode := true;
                ExportFile.Write(ExportedText[2]);
            end;
        }
        dataitem("B-Record"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                AnnualVATComm2010: Report "Annual VAT Comm. - 2010";
                RecordType: Code[1];
                ColumnValue: Decimal;
                VATCommAmounts: array[18] of Decimal;
                VATCommAmountsText: array[18] of Text[11];
                ExportedText: array[2] of Text[1024];
                TaxYear: Integer;
                i: Integer;
                Signature: Boolean;
                ConfirmationFlag: Boolean;
                TaxCode: Code[20];
                AppCode: Code[2];
                VATRegNo: Text[20];
            begin
                RecordType := 'B';
                TaxYear := Date2DMY(VATStatementFilters.GetRangeMin("Date Filter"), 3);
                Signature := false;

                if CompanyInfo."Tax Representative No." <> '' then begin
                    TaxCode := Vendor."Fiscal Code";
                    AppCode := ConvertAppointmentCode(AppointmentCode);
                    VATRegNo := Vendor."VAT Registration No.";
                end else begin
                    TaxCode := PadStr('', 16);
                    VATRegNo := PadStr('', 11, '0');
                    AppCode := PadStr('', 2, '0');
                end;
                if VATStatementLine.FindSet() then
                    repeat
                        ColumnValue := 0;
                        AnnualVATComm2010.InitializeVATStatement(
                          VATStatementFilters,
                          VATStatementLine,
                          Selection::"Open and Closed",
                          PeriodSelection::"Within Period",
                          false,
                          false,
                          '');
                        AnnualVATComm2010.CalcLineTotal(
                          VATStatementLine,
                          ColumnValue,
                          0);
                        VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"] := Round(ColumnValue, 1);
                    until VATStatementLine.Next() = 0;

                VATCommAmounts[15] :=
                  VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD4 - Payable VAT"] -
                  VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD5 - Receivable VAT"];

                if VATCommAmounts[15] < 0 then begin
                    VATCommAmounts[16] := -VATCommAmounts[15];
                    Clear(VATCommAmounts[15]);
                end;

                for i := 1 to ArrayLen(VATCommAmounts) do
                    VATCommAmountsText[i] :=
                      PrefixString(
                        Format(VATCommAmounts[i], 0, '<Sign><Integer>'),
                        MaxStrLen(VATCommAmountsText[i]),
                        ' ');

                ConfirmationFlag := true;

                RecordCount := RecordCount + 1;

                ExportedText[1] :=
                  RecordType +
                  PadStr(CompanyInfo."Fiscal Code", 16) +
                  PadStr('', 8) +
                  PadStr('', 3) +
                  PadStr('', 25) +
                  PadStr('', 20) +
                  PadStr(TaxCode, 16) +
                  ConvertBoolean(ConfirmationFlag) +
                  PadStr(CompanyInfo.Name, 60) +
                  PadStr('', 24) +
                  PadStr('', 20) +
                  Format(TaxYear, 4) +
                  PadStr(CompanyInfo."VAT Registration No.", 11) +
                  PadStr(ActivityCode.Code, 6) +
                  ConvertBoolean(SeparateLedger) +
                  ConvertBoolean(GroupSettlement) +
                  ConvertBoolean(ExceptionalEvent) +
                  PadStr(TaxCode, 16) +
                  AppCode +
                  PadStr(VATRegNo, 11) +
                  VATCommAmountsText[1] +
                  VATCommAmountsText[2] +
                  VATCommAmountsText[3] +
                  VATCommAmountsText[4] +
                  VATCommAmountsText[17] +
                  VATCommAmountsText[5] +
                  VATCommAmountsText[6] +
                  VATCommAmountsText[7] +
                  VATCommAmountsText[8] +
                  VATCommAmountsText[18] +
                  VATCommAmountsText[9] +
                  VATCommAmountsText[10] +
                  VATCommAmountsText[11] +
                  VATCommAmountsText[12] +
                  VATCommAmountsText[13] +
                  VATCommAmountsText[14] +
                  VATCommAmountsText[15] +
                  VATCommAmountsText[16] +
                  ConvertBoolean(Signature) +
                  PadStr('', 16) +
                  PadStr('', 5, '0') +
                  ConvertBoolean(false) +
                  ConvertBoolean(false) +
                  PadStr('', 8, '0') +
                  ConvertBoolean(Signature) +
                  PadStr('', 545);

                ExportedText[2] :=
                  PadStr('', 456) +
                  PadStr('', 364) +
                  PadStr('', 20) +
                  PadStr('', 8) +
                  PadStr('', 8) +
                  PadStr('', 1) +
                  PadStr('', 17) +
                  'A';

                ExportFile.TextMode := false;
                ExportFile.Write(ExportedText[1]);
                ExportFile.Seek(ExportFile.Pos - 2);
                ExportFile.TextMode := true;
                ExportFile.Write(ExportedText[2]);
            end;

            trigger OnPreDataItem()
            begin
                RecordCount := 0;
            end;
        }
        dataitem("Z-Record"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                ExportedText: array[2] of Text[1024];
                RecordCountText: Text[9];
                RecordType: Code[1];
            begin
                RecordType := 'Z';
                RecordCountText := PrefixString(Format(RecordCount), MaxStrLen(RecordCountText), '0');

                ExportedText[1] :=
                  RecordType +
                  PadStr('', 14) +
                  RecordCountText +
                  PadStr('', 999);

                ExportedText[2] :=
                  PadStr('', 25) +
                  PadStr('', 849) +
                  'A';

                ExportFile.TextMode := false;
                ExportFile.Write(ExportedText[1]);
                ExportFile.Seek(ExportFile.Pos - 2);
                ExportFile.TextMode := true;
                ExportFile.Write(ExportedText[2]);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CompanyInfoName; CompanyInfo.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Name';
                        Editable = false;
                        ToolTip = 'Specifies the company name.';
                    }
                    field(SeparateLedger; SeparateLedger)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Separate Ledger';
                        ToolTip = 'Specifies the separate ledger.';
                    }
                    field(GroupSettlement; GroupSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group Settlement';
                        ToolTip = 'Specifies the related group settlement.';
                    }
                    field(ExceptionalEvent; ExceptionalEvent)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exceptional Event';
                        ToolTip = 'Specifies if this is for an exceptional event.';
                    }
                    field(AppointmentCode; AppointmentCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Appointment Code';
                        Enabled = AppointmentCodeEnable;
                        TableRelation = "Appointment Code".Code;
                        ToolTip = 'Specifies a code for the capacity in which the company can submit VAT statements on behalf of other legal entities.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            AppointmentCodeEnable := true;
        end;

        trigger OnOpenPage()
        begin
            AppointmentCodeEnable := CompanyInfo."Tax Representative No." <> '';
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField("VAT Registration No.");
        CompanyInfo.TestField("Fiscal Code");

        GeneralLedgerSetup.GetRecordOnce();

        if CompanyInfo."Tax Representative No." <> '' then begin
            Vendor.Get(CompanyInfo."Tax Representative No.");
            Vendor.TestField("Fiscal Code");
            Vendor.TestField("VAT Registration No.");
        end;
    end;

    trigger OnPostReport()
    begin
        ExportFile.Close();

        if not TestRun then
            if ServerFileName = '' then
                FileManagement.DownloadHandler(ServerTempFileName, '', '', Text003, DefaultFileNameTxt)
            else
                FileManagement.CopyServerFile(ServerTempFileName, ServerFileName, true);
    end;

    trigger OnPreReport()
    begin
        if (CompanyInfo."Tax Representative No." <> '') and (AppointmentCode = '') then
            Error(Text008, CompanyInfo.FieldCaption("Tax Representative No."), CompanyInfo.TableCaption());

        if GeneralLedgerSetup."Use Activity Code" then begin
            if VATStatementFilters.GetFilter("Activity Code Filter") = '' then
                Error(EmptyActivityCodeFilterErr, VATStatementFilters.FieldCaption("Activity Code Filter"));

            ActivityCode.SetFilter(Code, VATStatementFilters.GetFilter("Activity Code Filter"));
            if ActivityCode.Count() <> 1 then
                Error(TooManyActivityCodesErr, VATStatementFilters.FieldCaption("Activity Code Filter"), ActivityCode.TableCaption(),
                  VATStatementFilters.GetFilter("Activity Code Filter"));
            ActivityCode.FindFirst();

            VATStatementLine.SetFilter("Activity Code Filter", VATStatementFilters.GetFilter("Activity Code Filter"));
        end;


        VATStatementLine.SetFilter("Date Filter", VATStatementFilters.GetFilter("Date Filter"));
        VATStatementLine.SetFilter("Statement Template Name", VATStatementFilters.GetFilter("Statement Template Name"));
        VATStatementLine.SetFilter("Statement Name", VATStatementFilters.GetFilter(Name));
        VATStatementLine.SetFilter("Annual VAT Comm. Field", '<>%1', VATStatementLine."Annual VAT Comm. Field"::" ");

        ServerTempFileName := FileManagement.ServerTempFileName('');

        ExportFile.TextMode := true;
        ExportFile.WriteMode := true;
        ExportFile.Create(ServerTempFileName);
    end;

    var
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        ActivityCode: Record "Activity Code";
        VATStatementLine: Record "VAT Statement Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        ServerTempFileName: Text;
        ServerFileName: Text;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        RecordCount: Integer;
        SeparateLedger: Boolean;
        GroupSettlement: Boolean;
        ExceptionalEvent: Boolean;
        TooManyActivityCodesErr: Label 'The %1 should contain exactly 1 %2.\\%1: %3.', Comment = '%1 = Field name, %2 = Table name, %3 = Filter applied to the field';
        Text003: Label 'IVC Files (*.ivc)|*.ivc|Text Files (*.txt)|*.txt|All Files (*.*)|*.*', Comment = 'Only translate ''IVC Files'', ''Text Files'' and ''All Files'' {Split=r"[\|\(]\*\.[^ |)]*[|) ]?"}';
        AppointmentCodeEnable: Boolean;
        TestRun: Boolean;
        EmptyActivityCodeFilterErr: Label 'You must specify a value for the %1 field for the VAT statement.''', Comment = '%1 = Field name';
        Text008: Label 'You must specify an appointment code when the %1 field in the %2 window is not blank.';
        AppointmentCode: Code[2];
        DefaultFileNameTxt: Label 'Annual VAT.ivc', Locked = true;

    local procedure PrefixString(String: Text[1024]; Length: Integer; FillCharacter: Text[1]): Text[1024]
    var
        PaddingLength: Integer;
    begin
        PaddingLength := Length - StrLen(String);

        if PaddingLength <= 0 then
            exit(String);

        exit(PadStr('', PaddingLength, FillCharacter) + String);
    end;

    local procedure ConvertBoolean(Boolean: Boolean): Text[1]
    begin
        case Boolean of
            true:
                exit('1');
            false:
                exit('0');
        end;
    end;

    local procedure ConvertAppointmentCode(AppointmentCode: Code[2]): Text[2]
    begin
        case AppointmentCode <> '' of
            true:
                exit(PrefixString(AppointmentCode, 2, '0'));
            false:
                exit(PrefixString('', 2, ' '));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServerFileName(): Text[1024]
    begin
        exit(ServerTempFileName);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewServerFileName: Text[260]; NewAppointmentCode: Code[2]; NewSeparateLedger: Boolean; NewGroupSettlement: Boolean; NewExceptionalEvent: Boolean; NewTestRun: Boolean)
    begin
        SeparateLedger := NewSeparateLedger;
        GroupSettlement := NewGroupSettlement;
        ExceptionalEvent := NewExceptionalEvent;
        AppointmentCode := NewAppointmentCode;
        ServerFileName := NewServerFileName;
        TestRun := NewTestRun;
    end;
}

