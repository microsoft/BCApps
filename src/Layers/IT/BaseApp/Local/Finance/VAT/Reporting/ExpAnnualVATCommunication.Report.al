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

report 12125 "Exp. Annual VAT Communication"
{
    Caption = 'Exp. Annual VAT Communication';
    ProcessingOnly = true;

    dataset
    {
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
                ProvisionCode := 'IVC' + Format(CalcDate('<+1Y>', StartDate), 2, '<Year,2>');
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
                VATCommAmounts: array[16] of Decimal;
                VATCommAmountsText: array[16] of Text[11];
                ExportedText: array[2] of Text[1024];
                TaxYear: Integer;
                i: Integer;
                Signature: Boolean;
                ConfirmationFlag: Boolean;
            begin
                RecordType := 'B';
                TaxYear := Date2DMY(StartDate, 3);
                Signature := false;

                if VATStatementLine.FindSet() then
                    repeat
                        ColumnValue := 0;
                        AnnualVATComm2010.InitializeVATStatement(
                          VATStatementName,
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

                ConfirmationFlag :=
                  not (VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD1 - Total sales"] >=
                       VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD1 - Sales with zero VAT"] +
                       VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD1 - VAT exempt sales"] +
                       VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD1 - EU sales"]) and
                  (VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD2 - Total purchases"] >=
                   VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD2 - Purchases with zero VAT"] +
                   VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD2 - VAT exempt purchases"] +
                   VATCommAmounts[VATStatementLine."Annual VAT Comm. Field"::"CD2 - EU purchases"]);

                RecordCount := RecordCount + 1;

                ExportedText[1] :=
                  RecordType +
                  PadStr(CompanyInfo."Fiscal Code", 16) +
                  PadStr('', 8) +
                  PadStr('', 3) +
                  PadStr('', 25) +
                  PadStr('', 20) +
                  PadStr('', 16) +
                  ConvertBoolean(ConfirmationFlag) +
                  PadStr(CompanyInfo.Name, 60) +
                  PadStr('', 24) +
                  PadStr('', 20) +
                  Format(TaxYear, 4) +
                  PadStr(CompanyInfo."VAT Registration No.", 11) +
                  PADSTR(ActivityCode.Code, 5) +
                  ConvertBoolean(SeparateLedger) +
                  ConvertBoolean(GroupSettlement) +
                  ConvertBoolean(ExceptionalEvent) +
                  PadStr(Vendor."Fiscal Code", 16) +
                  ConvertAppointmentCode(AppointmentCode.Code) +
                  PadStr(Vendor."VAT Registration No.", 11) +
                  VATCommAmountsText[1] +
                  VATCommAmountsText[2] +
                  VATCommAmountsText[3] +
                  VATCommAmountsText[4] +
                  VATCommAmountsText[5] +
                  VATCommAmountsText[6] +
                  VATCommAmountsText[7] +
                  VATCommAmountsText[8] +
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
                  PadStr('', 568);

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
                RecordCountText :=
                  CopyStr(PrefixString(Format(RecordCount), MaxStrLen(RecordCountText), '0'), 1, MaxStrLen(RecordCountText));

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
                    field("CompanyInfo.Name"; CompanyInfo.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the name of the company.';
                    }
                    field("VATStatementName.""Statement Template Name"""; VATStatementName."Statement Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Template';
                        TableRelation = "VAT Statement Template".Name;
                        ToolTip = 'Specifies the statement template.';

                        trigger OnValidate()
                        begin
                            VATStatementName.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
                        end;
                    }
                    field("VATStatementName.Name"; VATStatementName.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Name';
                        ToolTip = 'Specifies the statement name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if ACTION::LookupOK = PAGE.RunModal(0, VATStatementName, VATStatementName.Name) then;
                        end;
                    }
                    field("ActivityCode.Code"; ActivityCode.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Activity Code';
                        TableRelation = "Activity Code".Code;
                        ToolTip = 'Specifies a code that describes a primary activity for the company.';
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the start date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the end date.';
                    }
                    field("Vendor.""No."""; Vendor."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor No.';
                        TableRelation = Vendor."No.";
                        ToolTip = 'Specifies the vendor.';

                        trigger OnValidate()
                        begin
                            AppointmentCodeEnable := Vendor."No." <> '';
                        end;
                    }
                    field(AppointmentCode; AppointmentCode.Code)
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
            AppointmentCodeEnable := Vendor."No." <> '';
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

        if Vendor.Get(Vendor."No.") then begin
            Vendor.TestField("Fiscal Code");
            Vendor.TestField("VAT Registration No.");
            AppointmentCode.TestField(Code);
        end else
            Clear(AppointmentCode);
    end;

    trigger OnPostReport()
    var
        ToFile: Text[260];
    begin
        ExportFile.Close();
        ToFile := Text004;
        Download(ExportFileName, Text005, '', Text003, ToFile);
    end;

    trigger OnPreReport()
    var
        RBMgt: Codeunit "File Management";
    begin
        VATStatementLine.FilterGroup := 99;
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        VATStatementLine.SetFilter("Annual VAT Comm. Field", '<>%1', VATStatementLine."Annual VAT Comm. Field"::" ");
        VATStatementLine.FilterGroup := 0;
        if GeneralLedgerSetup."Use Activity Code" then
            VATStatementLine.SetRange("Activity Code Filter", ActivityCode.Code);
        VATStatementLine.SetRange("Date Filter", StartDate, EndDate);

        ExportFileName := RBMgt.ServerTempFileName('');

        ExportFile.TextMode := true;
        ExportFile.WriteMode := true;
        ExportFile.Create(ExportFileName);
    end;

    var
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        ActivityCode: Record "Activity Code";
        AppointmentCode: Record "Appointment Code";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExportFile: File;
        ExportFileName: Text[260];
        StartDate: Date;
        EndDate: Date;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        RecordCount: Integer;
        SeparateLedger: Boolean;
        GroupSettlement: Boolean;
        ExceptionalEvent: Boolean;
        InvalidActivityCodeFilterErr: Label 'The Activity Code Filter should contain exactly one Activity Code.';
        Text003: Label 'IVC Files (*.ivc)|*.ivc|Text Files (*.txt)|*.txt|All Files (*.*)|*.*';
        Text004: Label 'default.ivc';
        Text005: Label 'Export';
        AppointmentCodeEnable: Boolean;

    local procedure PrefixString(String: Text[1024]; Length: Integer; FillCharacter: Text[1]): Text[1024]
    var
        PaddingLength: Integer;
    begin
        PaddingLength := Length - StrLen(String);

        if PaddingLength <= 0 then
            exit;

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

    local procedure ConvertAppointmentCode(AppointmentCode: Code[1]): Text[2]
    begin
        case AppointmentCode <> '' of
            true:
                exit(PrefixString(AppointmentCode, 2, '0'));
            false:
                exit(PrefixString('', 2, ' '));
        end;
    end;

    [Scope('OnPrem')]
    procedure InitialiseRequest(var NewVATStmtName: Record "VAT Statement Name")
    begin
        VATStatementName.Copy(NewVATStmtName);

        if VATStatementName.GetFilter("Date Filter") <> '' then begin
            StartDate := VATStatementName.GetRangeMin("Date Filter");
            EndDate := VATStatementName.GetRangeMax("Date Filter");
        end;

        if GeneralLedgerSetup."Use Activity Code" then begin
            if VATStatementName.GetFilter("Activity Code Filter") <> '' then begin
                ActivityCode.SetFilter(Code, VATStatementName.GetFilter("Activity Code Filter"));
                if ActivityCode.Count() <> 1 then
                    Error(InvalidActivityCodeFilterErr);

                ActivityCode.FindFirst();
            end else
                Error(InvalidActivityCodeFilterErr);

            VATStatementLine.SetFilter("Activity Code Filter", VATStatementName.GetFilter("Activity Code Filter"));
        end;

        VATStatementLine.SetFilter("Date Filter", VATStatementName.GetFilter("Date Filter"));
    end;
}

