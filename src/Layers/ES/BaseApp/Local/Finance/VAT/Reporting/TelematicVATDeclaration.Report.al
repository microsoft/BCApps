// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using System.IO;
using System.Telemetry;

report 10715 "Telematic VAT Declaration"
{
    Caption = 'Telematic VAT Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            dataitem("VAT Declaration Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));
                RequestFilterFields = "Date Filter";

                trigger OnAfterGetRecord()
                begin
                    VATDeclarationName.SetRange(Name, "Statement Name");
                    if not VATDeclarationName.FindFirst() then
                        Error(Text1100005);

                    CalcTotLine("VAT Declaration Line", TotalAmount, 0);
                    if IntegerPrinted then
                        TotalAmount := Round(TotalAmount, 1, '<');
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;

                    if Box <> '' then begin
                        TransferenceFormat.SetRange(Box, Box);
                        if TransferenceFormat.Find('-') then
                            repeat
                                if Type = Type::Description then
                                    Evaluate(TotalAmount, Description);
                                LoadValue(TransferenceFormat, TotalAmount);
                            until (TransferenceFormat.Next() = 0);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TransferenceFormat.DeleteAll();
                    TemplateTransfFormat.SetRange("VAT Statement Name", "VAT Statement Name".Name);
                    TemplateTransfFormat.Find('-');
                    repeat
                        TransferenceFormat := TemplateTransfFormat;
                        if TransferenceFormat.Box = '' then
                            TransferenceFormat.Box := '**';
                        TransferenceFormat.Insert();
                    until TemplateTransfFormat.Next() = 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Template Type" <> "Template Type"::"One Column Report" then
                    Error(Text1100004, VATDeclarationName.FieldCaption("Template Type"),
                      "Template Type"::"One Column Report");
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                SetRange("Statement Template Name", "VAT Declaration Line"."Statement Template Name");
                SetRange(Name, "VAT Declaration Line"."Statement Name");
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
                    field(EntryType; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT entries included';
                        ToolTip = 'Specifies the type of VAT entries to include in the file. Options include Open, Closed or Open and Closed.';
                    }
                    field(EntryPeriod; PeriodSelected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT entries included';
                        ToolTip = 'Specifies the period you want to include in the file. Options include Before and Within Period or Within Period.';
                    }
                    field(AddtnlCurrency; PrintAmtInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Additional Currency';
                        ToolTip = 'Specifies if amounts are shown in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            OnActivateForm();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SilentMode := false;
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HV9', ESTelematicVATTok, Enum::"Feature Uptake Status"::"Used");
        TransferenceFormat.Reset();
        TransferenceFormat.Find('-');
        repeat
            if (TransferenceFormat.Value = '') and (TransferenceFormat.Type = TransferenceFormat.Type::Numerical) then
                LoadValue(TransferenceFormat, 0);
        until TransferenceFormat.Next() = 0;

        TransferenceFormat.SetRange(Type, TransferenceFormat.Type::Ask);
        PAGE.RunModal(10704, TransferenceFormat);
        TransferenceFormat.Reset();
        TransferenceFormat.Find('-');
        repeat
            if TransferenceFormat.Type = TransferenceFormat.Type::Currency then begin
                TransferenceFormat.Value := Text1100003;
                TransferenceFormat.Modify();
            end;
        until TransferenceFormat.Next() = 0;

        TemplateTransfFormat.Reset();
        TemplateTransfFormat.SetRange("VAT Statement Name", "VAT Declaration Line"."Statement Name");
        if TemplateTransfFormat.FindSet() then
            repeat
                TransferenceFormat.SetRange("VAT Statement Name", TemplateTransfFormat."VAT Statement Name");
                if TransferenceFormat.FindSet() then
                    repeat
                        if TemplateTransfFormat.Box = TransferenceFormat.Box then begin
                            TemplateTransfFormat.Value := TransferenceFormat.Value;
                            TemplateTransfFormat.Modify();
                        end;
                    until TransferenceFormat.Next() = 0;
            until TemplateTransfFormat.Next() = 0;

        TransferenceFormat.Modify();
        FileGeneration(TransferenceFormat);
        FeatureTelemetry.LogUsage('0000HW0', ESTelematicVATTok, 'ES Templates for Telematic VAT Statements in Text File Format Created');
    end;

    trigger OnPreReport()
    begin
        VATDeclLinFilt := "VAT Declaration Line".GetFilters();
        if PeriodSelected = PeriodSelected::"Before and Within Period" then
            Header := Text1100000
        else
            Header := Text1100001 + "VAT Declaration Line".GetFilter("Date Filter");
        GLSetup.Get();
        if PrintAmtInAddCurr then
            Currency.Get(GLSetup."Additional Reporting Currency");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESTelematicVATTok: Label 'ES Create Templates for Telematic VAT Statements in Text File Format', Locked = true;
        Text1100000: Label 'Previous and within the period VAT entries';
        Text1100001: Label 'Period: ';
        Text1100003: Label 'E';
        Text1100004: Label 'VAT declaration must be %1 %2.';
        Text1100005: Label 'The declaration does not exist';
        Text1100006: Label 'C:\';
        Text1100007: Label '.txt';
        Text1100008: Label 'Transference format line Nº %1 must be integer';
        Text1100009: Label 'N';
        Text1100010: Label '<Precision,', Locked = true;
        Text1100011: Label '><Integer><Decimal>', Locked = true;
        Text1100012: Label '<Integer>', Locked = true;
        Text1100013: Label '><Decimal>', Locked = true;
        GLAccount: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        VATPostSetup: Record "VAT Posting Setup";
        VATDeclarationName: Record "VAT Statement Name";
        GLSetup: Record "General Ledger Setup";
        TransferenceFormat: Record "AEAT Transference Format" temporary;
        TemplateTransfFormat: Record "AEAT Transference Format";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelected: Enum "VAT Statement Report Period Selection";
        IntegerPrinted: Boolean;
        VATDeclLinFilt: Text[250];
        Header: Text[50];
        Amount: Decimal;
        Base: Decimal;
        VATAmount: Decimal;
        VATAmountAC: Decimal;
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalECAmount: Decimal;
        TotalVATAmount: Decimal;
        RowNo: array[6] of Code[10];
        TextError: Text[80];
        i: Integer;
        VATPercentage: Decimal;
        ECPercentage: Decimal;
        PrintAmtInAddCurr: Boolean;
        Negative: Code[1];
        Counter: Integer;
        Position: Integer;
        FieldValue: Text[80];
        Acum: Integer;
        Decimal1: Text[30];
        Decimal2: Text[30];
        CM: Text;
        Line: Text[250];
        LineLen: Integer;
        OutFile: Text[30];
        RBMgt: Codeunit "File Management";
        FromFile: Text[1024];
        ToFile: Text[1024];
        Currency: Record Currency;
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure CalcTotLine(VATStatementLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportSetup: Record "VAT Report Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        IsNoTaxableEntry: Boolean;
    begin
        if Level = 0 then begin
            TotalAmount := 0;
            Amount := 0;
            VATAmount := 0;
            VATAmountAC := 0;
        end;

        case VATStatementLine2.Type of
            VATStatementLine2.Type::"Account Totaling":
                begin
                    GLAccount.SetFilter("No.", VATStatementLine2."Account Totaling");
                    "VAT Declaration Line".CopyFilter("Date Filter", GLAccount."Date Filter");
                    Amount := 0;
                    if GLAccount.Find('-') and (VATStatementLine2."Account Totaling" <> '') then
                        repeat
                            GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAccount."Net Change", GLAccount."Additional-Currency Net Change");
                        until GLAccount.Next() = 0;
                    CalcTotAmount(VATStatementLine2, TotalAmount);
                end;
            VATStatementLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    NoTaxableEntry.Reset();
                    IsNoTaxableEntry := false;
                    OnCalcTotLineOnBeforeSetVATEntryFilters(VATEntry, VATStatementLine2);

                    if VATPostingSetup.Get(VATStatementLine2."VAT Bus. Posting Group", VATStatementLine2."VAT Prod. Posting Group") and
                       (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"No Taxable VAT")
                    then begin
                        IsNoTaxableEntry := true;
                        SetFilterOnNoTaxableEntry(NoTaxableEntry, VATStatementLine2);
                        if NoTaxableEntry.FindFirst() then;
                    end
                    else begin
                        if VATEntry.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date") then begin
                            VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine2."VAT Bus. Posting Group");
                            VATEntry.SetRange("VAT Prod. Posting Group", VATStatementLine2."VAT Prod. Posting Group");
                        end
                        else begin
                            VATEntry.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                            VATEntry.SetRange("Tax Jurisdiction Code", VATStatementLine2."Tax Jurisdiction Code");
                            VATEntry.SetRange("Use Tax", VATStatementLine2."Use Tax");
                        end;
                        VATEntry.SetRange(Type, VATStatementLine2."Gen. Posting Type");
                        if "VAT Declaration Line".GetFilter("Date Filter") <> '' then
                            if PeriodSelected = PeriodSelected::"Before and Within Period" then
                                VATEntry.SetRange("VAT Reporting Date", 0D, "VAT Declaration Line".GetRangeMax("Date Filter"))
                            else
                                "VAT Declaration Line".CopyFilter("Date Filter", VATEntry."VAT Reporting Date");
                        SetSelectionFilterOnVATEntry(VATEntry, Selection);
                        if VATEntry.FindFirst() then;
                    end;

                    case VATStatementLine2."Amount Type" of
                        VATStatementLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostSetup."VAT+EC %") * VATEntry."VAT %";
                                        VATAmountAC := (VATEntry."Additional-Currency Amount" / VATPostSetup."VAT+EC %") * VATEntry."VAT %";
                                    end;
                                    if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then begin
                                        VATAmount := VATEntry.Amount;
                                        VATAmountAC := VATEntry."Additional-Currency Amount";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                            end;
                        VATStatementLine2."Amount Type"::Base:
                            if IsNoTaxableEntry then begin
                                NoTaxableEntry.CalcSums(Base);
                                Amount := NoTaxableEntry.Base;
                            end
                            else begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then begin
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, PrintAmtInAddCurr),
                                        CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", PrintAmtInAddCurr));
                                    Amount := Amount + Base;
                                end;
                            end;
                        VATStatementLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                            end;
                        VATStatementLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                            end;
                        VATStatementLine2."Amount Type"::"Amount+Base":
                            begin
                                VATEntry.CalcSums(Amount, Base, "Additional-Currency Amount", "Additional-Currency Base");
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostSetup."VAT+EC %") * VATEntry."VAT %";
                                        VATAmountAC := (VATEntry."Additional-Currency Amount" / VATPostSetup."VAT+EC %") *
                                          VATEntry."VAT %";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, PrintAmtInAddCurr),
                                        CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", PrintAmtInAddCurr))
                                else
                                    Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                Amount := Amount + Base;
                            end;
                        VATStatementLine2."Amount Type"::"Non-Deductible Amount":
                            begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY", "Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount ACY");
                                if VATReportSetup.Get() then;
                                if VATReportSetup."Report VAT Base" then
                                    Base := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end;
                        VATStatementLine2."Amount Type"::"Non-Deductible Base":
                            begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end;
                    end;
                    CalcTotAmount(VATStatementLine2, TotalAmount);
                end;
            VATStatementLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStatementLine2."Row No.";

                    if VATStatementLine2."Row Totaling" = '' then
                        exit(true);
                    VATStatementLine2.SetRange("Statement Template Name", VATStatementLine2."Statement Template Name");
                    VATStatementLine2.SetRange("Statement Name", VATStatementLine2."Statement Name");
                    VATStatementLine2.SetFilter("Row No.", VATStatementLine2."Row Totaling");
                    if VATStatementLine2.Find('-') then
                        repeat
                            if not CalcTotLine(VATStatementLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    TextError := TextError + RowNo[i] + ' => ';
                                TextError := TextError + '...';
                                VATStatementLine2.FieldError("Row No.", TextError);
                            end;
                        until VATStatementLine2.Next() = 0;
                end;
            VATStatementLine2.Type::Description:
                ;
            VATStatementLine2.Type::"EC Entry Totaling":
                begin
                    VATEntry.Reset();
                    OnCalcTotLineOnBeforeSetVATEntryFilters(VATEntry, VATStatementLine2);
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStatementLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStatementLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStatementLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStatementLine2."Gen. Posting Type");
                    if "VAT Declaration Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelected = PeriodSelected::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Declaration Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Declaration Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    SetSelectionFilterOnVATEntry(VATEntry, Selection);
                    if VATEntry.FindFirst() then;
                    case VATStatementLine2."Amount Type" of
                        VATStatementLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostSetup."VAT+EC %") * VATEntry."EC %";
                                        VATAmountAC := (VATEntry."Additional-Currency Amount" / VATPostSetup."VAT+EC %") * VATEntry."EC %";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                            end;
                        VATStatementLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then begin
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, PrintAmtInAddCurr),
                                        CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", PrintAmtInAddCurr));
                                    Amount := Amount + Base;
                                end;
                            end;
                        VATStatementLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                            end;
                        VATStatementLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                            end;
                        VATStatementLine2."Amount Type"::"Amount+Base":
                            begin
                                VATEntry.CalcSums(Amount, Base, "Additional-Currency Amount", "Additional-Currency Base");
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostSetup."VAT+EC %") * VATEntry."EC %";
                                        VATAmountAC := (VATEntry."Additional-Currency Amount" / VATPostSetup."VAT+EC %") *
                                          VATEntry."EC %";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, PrintAmtInAddCurr),
                                        CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", PrintAmtInAddCurr))
                                else
                                    Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                Amount := Amount + Base;
                            end;
                    end;
                    CalcTotAmount(VATStatementLine2, TotalAmount);
                end;
        end;

        exit(true);
    end;

    local procedure CalcTotAmount(VATStatementLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStatementLine2."Calculate with" = 1 then begin
            Amount := -Amount;
            Base := -Base;
        end;
        TotalAmount := TotalAmount + Amount;
        TotalBase := TotalBase + Base;
        if VATStatementLine2.Type <> VATStatementLine2.Type::"Account Totaling" then begin
            VATPostSetup.Get(VATStatementLine2."VAT Bus. Posting Group", VATStatementLine2."VAT Prod. Posting Group");
            VATPercentage := VATPostSetup."VAT %";
            ECPercentage := VATPostSetup."EC %";
            VATAmount := Amount;
            if VATPostSetup."VAT+EC %" <> 0 then
                VATAmount := VATAmount / VATPostSetup."VAT+EC %" * VATPercentage;
            TotalVATAmount := TotalVATAmount + VATAmount;
            TotalECAmount := TotalAmount - TotalVATAmount;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeSettings(var NewVATDeclName: Record "VAT Statement Name"; var NewVATDDeclLineName: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintedInteger: Boolean)
    begin
        "VAT Statement Name".Copy(NewVATDeclName);
        "VAT Declaration Line".Copy(NewVATDDeclLineName);
        Selection := NewSelection;
        PeriodSelected := NewPeriodSelection;
        IntegerPrinted := NewPrintedInteger;
    end;

    [Scope('OnPrem')]
    procedure ConditionalAdd(Amount: Decimal; AmtInAddCurr: Decimal; SumAmtInAddCurr: Decimal): Decimal
    begin
        if PrintAmtInAddCurr then
            exit(Amount + SumAmtInAddCurr);

        exit(Amount + AmtInAddCurr);
    end;

    [Scope('OnPrem')]
    procedure LoadValue(var TransFormat: Record "AEAT Transference Format"; Amt: Decimal)
    begin
        if TransFormat.Type <> TransFormat.Type::Numerical then
            Error(Text1100008, TransFormat."No.");

        if Amt < 0 then begin
            Negative := Text1100009;
            Amt := -Amt;
        end else
            Negative := '';

        case TransFormat.Subtype of
            TransFormat.Subtype::"Integer and Decimal Part":
                begin
                    TransFormat.Value := Format(Amt, TransFormat.Length, Text1100010 + '2' + Text1100011);
                    TransFormat.Value := ConvertStr(DelChr(TransFormat.Value, '=', ',.'), ' ', '0');
                    TransFormat.Value := Negative + PadStr('', TransFormat.Length - StrLen(Negative) -
                        StrLen(TransFormat.Value), '0') + TransFormat.Value;
                end;
            TransFormat.Subtype::"Integer Part":
                begin
                    TransFormat.Value := Negative + Format(Amt, TransFormat.Length - StrLen(Negative),
                        Text1100012);
                    TransFormat.Value := ConvertStr(ConvertStr(TransFormat.Value, ',', '.'), ' ', '0');
                end;
            TransFormat.Subtype::"Decimal Part":
                begin
                    TransFormat.Value := Format(Amt, TransFormat.Length, Text1100010 + '2' + Text1100013);
                    TransFormat.Value := ConvertStr(DelChr(TransFormat.Value, '=', '.,'), ' ', '0');
                    TransFormat.Value := Negative + PadStr('', TransFormat.Length - StrLen(Negative) -
                        StrLen(TransFormat.Value), '0') + TransFormat.Value;
                end;
        end;
        TransFormat.Modify();
    end;

    [Scope('OnPrem')]
    procedure FileGeneration(var TransFormat: Record "AEAT Transference Format")
    var
        FileManagement: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        TransFormat.FindLast();
        Clear(File);
        File.WriteMode(true);
        File.TextMode(false);
        FromFile := RBMgt.ServerTempFileName('');
        ToFile := "VAT Declaration Line"."Statement Name" + Text1100007;
        File.Create(FromFile);
        File.CreateOutStream(OutStream);

        Acum := 0;
        TransFormat.FindSet();
        repeat
            if (TransFormat.Position + TransFormat.Length) > Acum then
                Acum := TransFormat.Position + TransFormat.Length;
        until TransFormat.Next() = 0;
        Acum := Acum - 1;

        CM := PadStr(CM, Acum, ' ');

        TransFormat.FindSet();
        repeat
            Position := TransFormat.Position;
            Counter := TransFormat.Length - StrLen(TransFormat.Value);
            FieldValue := TransFormat.Value;
            case TransFormat.Type of
                TransFormat.Type::Alphanumerical:
                    for i := 1 to TransFormat.Length do begin
                        if i > StrLen(FieldValue) then
                            CM[Position] := ' '
                        else
                            CM[Position] := FieldValue[i];
                        Position := Position + 1;
                    end;
                TransFormat.Type::Numerical:
                    begin
                        while Counter > 0 do begin
                            Counter := Counter - 1;
                            CM[Position] := '0';
                            Position := Position + 1;
                        end;
                        if TransFormat.Subtype = TransFormat.Subtype::"Integer and Decimal Part" then
                            if StrPos(FieldValue, '.') <> 0 then begin
                                Decimal1 := DelStr(FieldValue, 1, StrLen(FieldValue) - 1);
                                Decimal2 := DelStr(FieldValue, 1, StrLen(FieldValue) - 2);
                                Decimal2 := DelStr(Decimal2, 2, 1);
                                FieldValue := DelStr(FieldValue, 15, 3);
                                FieldValue := '0' + FieldValue;
                                FieldValue := FieldValue + Decimal2 + Decimal1;
                            end;
                        for i := 1 to StrLen(FieldValue) do begin
                            CM[Position] := FieldValue[i];
                            Position := Position + 1;
                        end;
                    end;
                TransFormat.Type::Fix:
                    for i := 1 to TransFormat.Length do begin
                        CM[Position] := FieldValue[i];
                        Position := Position + 1;
                    end;
                TransFormat.Type::Ask:
                    for i := 1 to TransFormat.Length do begin
                        if i > StrLen(FieldValue) then
                            CM[Position] := ' '
                        else
                            CM[Position] := FieldValue[i];
                        Position := Position + 1;
                    end;
                TransFormat.Type::Currency:
                    for i := 1 to TransFormat.Length do begin
                        CM[Position] := FieldValue[i];
                        Position := Position + 1;
                    end;
            end;
        until TransFormat.Next() = 0;
        TransFormat.FindSet();

        LineLen := Acum;
        i := 0;
        repeat
            Line := '';
            if LineLen > 250 then begin
                Line := CopyStr(CM, 250 * i + 1, 250);
                OutStream.WriteText(Line);
                LineLen := LineLen - 250;
            end else begin
                Line := CopyStr(CM, 250 * i + 1, LineLen);
                OutStream.WriteText(CopyStr(Line, 1, StrLen(Line)));
                LineLen := 0;
            end;
            i := i + 1;
        until LineLen = 0;
        File.Close();
        if not SilentMode then
            Download(FromFile, '', Text1100006, '', ToFile)
        else
            FileManagement.CopyServerFile(FromFile, SilentModeFileName, true);
    end;

    [Scope('OnPrem')]
    procedure CurrentAsign(VATStatementLine: Record "VAT Statement Line")
    begin
        "VAT Declaration Line" := VATStatementLine;
    end;

    local procedure OnActivateForm()
    begin
        OutFile := Text1100006 + "VAT Declaration Line"."Statement Name" + Text1100007
    end;

    [Scope('OnPrem')]
    procedure CalcTotalVATBase(VAT: Decimal; EC: Decimal; VATAmount: Decimal; UseAddCurr: Boolean): Decimal
    begin
        if (VAT + EC) = 0 then
            exit;
        if UseAddCurr then
            exit(Round(100 * VATAmount / (VAT + EC), Currency."Amount Rounding Precision"));

        exit(Round(100 * VATAmount / (VAT + EC), GLSetup."Amount Rounding Precision"));
    end;

    [Scope('OnPrem')]
    procedure SetSilentMode(ServerFileName: Text)
    begin
        SilentMode := true;
        SilentModeFileName := ServerFileName;
    end;

    local procedure SetSelectionFilterOnVATEntry(var VATEntry: Record "VAT Entry"; Selection: Enum "VAT Statement Report Selection")
    begin
        case Selection of
            Selection::Open:
                VATEntry.SetRange(Closed, false);
            Selection::Closed:
                VATEntry.SetRange(Closed, true);
            else
                VATEntry.SetRange(Closed);
        end;
    end;

    local procedure SetFilterOnNoTaxableEntry(var NoTaxableEntry: Record "No Taxable Entry"; VATStatementLine: Record "VAT Statement Line")
    begin
        NoTaxableEntry.SetRange(Type, VATStatementLine."Gen. Posting Type");
        NoTaxableEntry.SetRange("VAT Bus. Posting Group", VATStatementLine."VAT Bus. Posting Group");
        NoTaxableEntry.SetRange("VAT Prod. Posting Group", VATStatementLine."VAT Prod. Posting Group");
        if "VAT Declaration Line".GetFilter("Date Filter") <> '' then
            if PeriodSelected = PeriodSelected::"Before and Within Period" then
                NoTaxableEntry.SetRange("Posting Date", 0D, "VAT Declaration Line".GetRangeMax("Date Filter"))
            else
                "VAT Declaration Line".CopyFilter("Date Filter", NoTaxableEntry."Posting Date");

        case Selection of
            Selection::Open:
                NoTaxableEntry.SetRange(Closed, false);
            Selection::Closed:
                NoTaxableEntry.SetRange(Closed, true);
            Selection::"Open and Closed":
                NoTaxableEntry.SetRange(Closed);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotLineOnBeforeSetVATEntryFilters(var VATEntry: Record "VAT Entry"; VATStatementLine2: Record "VAT Statement Line")
    begin
    end;
}

