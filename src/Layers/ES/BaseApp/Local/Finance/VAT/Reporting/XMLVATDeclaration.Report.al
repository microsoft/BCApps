// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using System;
using System.IO;
using System.Telemetry;
using System.Xml;

report 10718 "XML VAT Declaration"
{
    Caption = 'XML VAT Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));
                RequestFilterFields = "Date Filter";

                trigger OnAfterGetRecord()
                begin
                    VATStatementName.SetRange(Name, "Statement Name");
                    if not VATStatementName.FindFirst() then
                        Error(Text1100001);

                    CalcTotalLine("VAT Statement Line", TotalAmount, 0);
                    if IntegerPrinted then
                        TotalAmount := Round(TotalAmount, 1, '<');
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;

                    if Box <> '' then begin
                        TempAEATTransFormatXML.SetRange(Box, Box);
                        if TempAEATTransFormatXML.FindSet() then
                            repeat
                                if Type = Type::Description then
                                    Evaluate(TotalAmount, Description);
                                LoadValue(TempAEATTransFormatXML, TotalAmount);
                                TempAEATTransFormatXML.Modify();
                            until TempAEATTransFormatXML.Next() = 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TempAEATTransFormatXML.DeleteAll();
                    AEATTransFormatXML.SetRange("VAT Statement Name", "VAT Statement Name".Name);
                    if AEATTransFormatXML.FindSet() then
                        repeat
                            TempAEATTransFormatXML := AEATTransFormatXML;
                            TempAEATTransFormatXML.Insert();
                        until AEATTransFormatXML.Next() = 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Template Type" <> "Template Type"::"One Column Report" then
                    Error(Text1100000, "Template Type"::"One Column Report");

                XMLDoc := XMLDoc.XmlDocument();
                XMLProcessingInstruction := XMLDoc.CreateProcessingInstruction('xml', 'version="1.0" encoding="ISO-8859-9"');
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Statement Template Name", "VAT Statement Line"."Statement Template Name");
                SetRange(Name, "VAT Statement Line"."Statement Name");
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
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SilentMode := false;
    end;

    trigger OnPostReport()
    var
        FileManagement: Codeunit "File Management";
    begin
        FeatureTelemetry.LogUptake('1000HW3', ESVATXMLTok, Enum::"Feature Uptake Status"::"Used");
        TempAEATTransFormatXML.Reset();
        TempAEATTransFormatXML.SetRange("VAT Statement Name", VATStatementName.Name);
        TempAEATTransFormatXML.SetRange(Ask, true);
        if TempAEATTransFormatXML.FindFirst() then begin
            PAGE.RunModal(PAGE::"XML Transference Format", TempAEATTransFormatXML);
            TempAEATTransFormatXML.Modify();
            TempAEATTransFormatXML.SetRange(Ask);
        end;

        GenerateFile();

        ToFile := "VAT Statement Line"."Statement Name" + '.xml';

        if SilentMode then begin
            FileManagement.CopyServerFile(FileName, SilentModeFileName, true);
            exit;
        end;

        if not Download(FileName, Text1100002, '', Text1100004, ToFile) then
            exit;
        FeatureTelemetry.LogUsage('1000HW4', ESVATXMLTok, 'ES VAT Statements in XML Format Exported');
    end;

    trigger OnPreReport()
    var
        RBMgt: Codeunit "File Management";
    begin
        FileName := RBMgt.ServerTempFileName('xml');
    end;

    var
        Text1100000: Label 'VAT declaration must have Template Type %1.';
        Text1100001: Label 'The declaration does not exist.';
        Text1100002: Label 'Path XML VAT Declaration';
        ESVATXMLTok: Label 'ES Export VAT Statements in XML Format', Locked = true;
        AEATTransFormatXML: Record "AEAT Transference Format XML";
        TempAEATTransFormatXML: Record "AEAT Transference Format XML" temporary;
        GLAccount: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        XMLDOMMgt: Codeunit "XML DOM Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        XMLDoc: DotNet XmlDocument;
        XMLProcessingInstruction: DotNet XmlProcessingInstruction;
        RowNo: array[6] of Code[10];
        Amount: Decimal;
        Base: Decimal;
        VATAmount: Decimal;
        VATAmountACY: Decimal;
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalVATAmount: Decimal;
        VATPercentage: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelected: Enum "VAT Statement Report Period Selection";
        FileName: Text[250];
        TextError: Text[80];
        ToFile: Text[1024];
        i: Integer;
        PrintAmtInAddCurr: Boolean;
        IntegerPrinted: Boolean;
        Text1100004: Label 'Xml Files (.xml)|*.xml|All Files|*.*''';
        SilentMode: Boolean;
        SilentModeFileName: Text;

    [Scope('OnPrem')]
    procedure CalcTotalLine(VATStatementLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    begin
        if Level = 0 then
            TotalAmount := 0;

        case VATStatementLine2.Type of
            VATStatementLine2.Type::"Account Totaling":
                begin
                    GLAccount.SetFilter("No.", VATStatementLine2."Account Totaling");
                    "VAT Statement Line".CopyFilter("Date Filter", GLAccount."Date Filter");
                    Amount := 0;
                    if GLAccount.FindSet() and (VATStatementLine2."Account Totaling" <> '') then
                        repeat
                            GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAccount."Net Change", GLAccount."Additional-Currency Net Change");
                        until GLAccount.Next() = 0;
                    CalcTotalAmount(VATStatementLine2, TotalAmount);
                end;
            VATStatementLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
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
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelected = PeriodSelected::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if VATEntry.FindFirst() then;
                    case VATStatementLine2."Amount Type" of
                        VATStatementLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostingSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostingSetup."VAT+EC %") * VATEntry."VAT %";
                                        VATAmountACY := (VATEntry."Additional-Currency Amount" / VATPostingSetup."VAT+EC %") * VATEntry."VAT %";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountACY);
                                end;
                            end;
                        VATStatementLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
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
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                    end;
                    CalcTotalAmount(VATStatementLine2, TotalAmount);
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
                            if not CalcTotalLine(VATStatementLine2, TotalAmount, Level) then begin
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
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelected = PeriodSelected::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if VATEntry.FindFirst() then;
                    case VATStatementLine2."Amount Type" of
                        VATStatementLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    if VATPostingSetup."VAT+EC %" <> 0 then begin
                                        VATAmount := (VATEntry.Amount / VATPostingSetup."VAT+EC %") * VATEntry."EC %";
                                        VATAmountACY := (VATEntry."Additional-Currency Amount" / VATPostingSetup."VAT+EC %") * VATEntry."EC %";
                                    end;
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountACY);
                                end;
                            end;
                        VATStatementLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
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
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                    end;
                    CalcTotalAmount(VATStatementLine2, TotalAmount);
                end;
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStatementLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStatementLine2."Calculate with" = 1 then begin
            Amount := -Amount;
            Base := -Base;
        end;
        TotalAmount := TotalAmount + Amount;
        TotalBase := TotalBase + Base;

        if VATStatementLine2.Type <> VATStatementLine2.Type::"Account Totaling" then begin
            VATPostingSetup.Get(VATStatementLine2."VAT Bus. Posting Group", VATStatementLine2."VAT Prod. Posting Group");
            VATPercentage := VATPostingSetup."VAT %";
            VATAmount := Amount;
            if VATPostingSetup."VAT+EC %" <> 0 then
                VATAmount := VATAmount / VATPostingSetup."VAT+EC %" * VATPercentage;
            TotalVATAmount := TotalVATAmount + VATAmount;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeSettings(var NewVATDeclName: Record "VAT Statement Name"; var NewVATDDeclLineName: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintedInteger: Boolean)
    begin
        "VAT Statement Name".Copy(NewVATDeclName);
        "VAT Statement Line".Copy(NewVATDDeclLineName);
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
    procedure LoadValue(var TransFormatXML: Record "AEAT Transference Format XML"; var Amt: Decimal)
    begin
        if Amt < 0 then
            Amt := -Amt;

        case TransFormatXML."Value Type" of
            TransFormatXML."Value Type"::"Integer and Decimal Part":
                TransFormatXML.Value := ConvertStr(DelChr(Format(Amt, 0, '<Precision,2><Integer><Decimal>'), '=', '.'), ',', '.');
            TransFormatXML."Value Type"::"Integer Part":
                TransFormatXML.Value := Format(Amt, 0, '<Integer>');
            TransFormatXML."Value Type"::"Decimal Part":
                TransFormatXML.Value := '0' + ConvertStr(Format(Amt, 0, '<Precision,2><Decimal>'), ',', '.');
        end;
        TransFormatXML.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateFile()
    var
        XMLNode: DotNet XmlNode;
    begin
        AEATTransFormatXML.FindFirst();
        AEATTransFormatXML.TestField("Line Type", AEATTransFormatXML."Line Type"::Element);
        XMLNode := XMLDoc.CreateElement(AEATTransFormatXML.Description);
        AppendVATStatementLine(XMLNode, AEATTransFormatXML, true);

        XMLDoc.Save(FileName);
    end;

    [Scope('OnPrem')]
    procedure CurrentAssign(NewVATStatementLine: Record "VAT Statement Line")
    begin
        "VAT Statement Line" := NewVATStatementLine;
    end;

    [Scope('OnPrem')]
    procedure AppendVATStatementLine(var ParentXMLNode: DotNet XmlNode; AEATTransFormatXML: Record "AEAT Transference Format XML"; RootNode: Boolean)
    var
        NewXMLNode: DotNet XmlNode;
    begin
        TempAEATTransFormatXML.Get(AEATTransFormatXML."VAT Statement Name", AEATTransFormatXML."No.");
        if not
           TempAEATTransFormatXML."Exists Amount" or
           (TempAEATTransFormatXML."Exists Amount" and ((TempAEATTransFormatXML.Value <> '') or (TempAEATTransFormatXML.Box <> '')))
        then
            case AEATTransFormatXML."Line Type" of
                AEATTransFormatXML."Line Type"::Element:
                    begin
                        if RootNode then begin
                            XMLDoc.AppendChild(ParentXMLNode);
                            NewXMLNode := ParentXMLNode;
                        end else
                            XMLDOMMgt.AddElement(ParentXMLNode, TempAEATTransFormatXML.Description, TempAEATTransFormatXML.Value, '', NewXMLNode);
                        AEATTransFormatXML.Reset();
                        AEATTransFormatXML.SetCurrentKey("VAT Statement Name", "Parent Line No.");
                        AEATTransFormatXML.SetRange("VAT Statement Name", AEATTransFormatXML."VAT Statement Name");
                        AEATTransFormatXML.SetRange("Parent Line No.", AEATTransFormatXML."No.");
                        if AEATTransFormatXML.FindSet() then
                            repeat
                                AppendVATStatementLine(NewXMLNode, AEATTransFormatXML, false);
                            until AEATTransFormatXML.Next() = 0;
                    end;
                AEATTransFormatXML."Line Type"::Attribute:
                    XMLDOMMgt.AddAttribute(ParentXMLNode, AEATTransFormatXML.Description, AEATTransFormatXML.Value);
            end;
    end;

    [Scope('OnPrem')]
    procedure SetSilentMode(ServerFileName: Text)
    begin
        SilentMode := true;
        SilentModeFileName := ServerFileName;
    end;
}

