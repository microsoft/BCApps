// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;

codeunit 26100 "Update VAT-CH"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Do you want to delete the existing %1 %2 and create a new one?';
        Text002: Label 'Do you want to create a new %1 %2?';
        Text003: Label 'The %1 %2 has been successfully updated or created.';
        Text004: Label 'No %1 has been created or updated.';
        Text005: Label 'Standard';
        Text006: Label 'No VAT Posting Setup lines could be found with values in the VAT Statement Cipher fields. ';
        Text007: Label 'REVENUE';
        Text008: Label 'Total Revenue ( 39)';
        Text009: Label 'Not taxable revenue opted according  22';
        Text010: Label 'Deductions';
        Text011: Label 'Tax-exempt';
        Text012: Label 'Exempted from tax ( 23, 107)';
        Text013: Label 'Abroad';
        Text014: Label 'Total revenue abroad';
        Text015: Label 'Reporting proc.';
        Text016: Label 'Transfer in the reporting procedure';
        Text017: Label 'Non-taxable';
        Text018: Label 'Total non-taxable revenue ( 21)';
        Text019: Label 'Red. in payment';
        Text020: Label 'Total reduction in payment';
        Text021: Label 'Misc.';
        Text022: Label 'Total miscellaneous';
        Text023: Label 'Total deductions';
        Text024: Label 'Total taxable revenue';
        Text025: Label 'TAX COMPUTATION';
        Text026: Label 'Normal';
        Text027: Label 'Revenue at normal rate';
        Text028: Label 'Reduced';
        Text029: Label 'Revenue at reduced rate';
        Text030: Label 'Hotel';
        Text031: Label 'Revenue at Hotel Rate';
        Text032: Label 'Acquisition';
        Text033: Label 'Total acquisition tax';
        Text034: Label 'Input tax';
        Text035: Label 'Total input tax on material and services';
        Text036: Label 'Total input tax on investments';
        Text037: Label 'Total deposit tax ( 32)';
        Text038: Label 'Input tax corr.';
        Text039: Label 'Total input tax correction and own consumption';
        Text040: Label 'Input tax cut.';
        Text041: Label 'Total input tax cutbacks,grants';
        Text042: Label 'Total cipher 400-420';
        Text043: Label 'OTHER CASH FLOW';
        Text044: Label 'Total grants, visitor''s taxes, etc.';
        Text045: Label 'Donations, dividends, etc.';
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATCipherSetup: Record "VAT Cipher Setup";
        LineNo: Integer;
        Text046: Label 'Revenue at normal rate (other rate)';
        Text047: Label 'Revenue at reduced rate (other rate)';
        Text048: Label 'Revenue at Hotel rate (other rate)';
        Text049: Label 'Total acquisition tax  (other rate)';
        VATCalcType: Option "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";

    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplate(TemplateName: Code[10]; TemplateDescription: Text[80])
    begin
        if VATStatementTemplate.Get(TemplateName) then begin
            if not Confirm(Text001, true, VATStatementTemplate.TableCaption(), TemplateName) then
                Error(Text004, VATStatementTemplate.TableCaption())
        end else
            if not Confirm(Text002, true, VATStatementTemplate.TableCaption(), TemplateName) then
                Error(Text004, VATStatementTemplate.TableCaption());
        CreateVatStatementSetup(TemplateName, TemplateDescription);
        Message(Text003, VATStatementTemplate.TableCaption(), VATStatementTemplate.Name);
    end;

    local procedure CreateVatStatementSetup(TemplateName: Code[10]; TemplateDescription: Text[80])
    begin
        VATCipherSetup.Get();
        VATStatementLine.SetRange("Statement Template Name", TemplateName);
        VATStatementLine.SetRange("Statement Name", Text005);
        VATStatementLine.DeleteAll();
        if VATStatementName.Get(TemplateName, Text005) then
            VATStatementName.Delete();
        if VATStatementTemplate.Get(TemplateName) then
            VATStatementTemplate.Delete();

        VATStatementTemplate.Init();
        VATStatementTemplate.Name := TemplateName;
        VATStatementTemplate.Description := TemplateDescription;
        VATStatementTemplate."VAT Statement Report ID" := 26100;
        VATStatementTemplate."Page ID" := 317;
        VATStatementTemplate.Insert();

        VATStatementName.Init();
        VATStatementName."Statement Template Name" := TemplateName;
        VATStatementName.Name := Text005;
        VATStatementName.Insert();

        LineNo := 0;
        InsertSalestaxBaseamounts();
        InsertSalestaxAmounts();
        InsertPurchasetaxBaseamounts();
        InsertSalestaxEuAmount();
    end;

    local procedure InsertSalestaxBaseamounts()
    var
        InsertCipher200: Boolean;
        RowTotValue: Text[30];
    begin
        VATPostingSetup.SetFilter("Sales VAT Stat. Cipher", '<>%1', VATPostingSetup."Sales VAT Stat. Cipher");
        if VATPostingSetup.IsEmpty() then begin
            VATPostingSetup.Reset();
            VATPostingSetup.SetFilter("Purch. VAT Stat. Cipher", '<>%1', VATPostingSetup."Purch. VAT Stat. Cipher");
            if VATPostingSetup.IsEmpty() then
                Error(Text006);
        end;

        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        InsertVatStatLine(Text007, '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');

        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", VATCipherSetup."Revenue of Non-Tax. Services", VATCipherSetup.Miscellaneous);
        if VATPostingSetup.FindSet() then
            repeat
                if VATPostingSetup."Sales VAT Stat. Cipher" <> VATCipherSetup."Reduction in Payments" then begin
                    InsertVatStatLine(
                      Format(Text007 + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '', '200', false, true, false,
                      "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Base, "General Posting Type"::Sale, '');
                    InsertCipher200 := true;
                end;
            until VATPostingSetup.Next() = 0;

        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", VATCipherSetup."Reduction in Payments");
        if VATPostingSetup.FindFirst() then begin
            repeat
                InsertVatStatLine(
                  Format(Text007 + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '', '200', false, false, false,
                  "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Base, "General Posting Type"::Sale, '');
            until VATPostingSetup.Next() = 0;
            InsertCipher200 := true;
        end;

        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", VATCipherSetup."Tax Normal Rate Serv. Before", VATCipherSetup."Tax Hotel Rate Serv. After");
        if VATPostingSetup.FindFirst() then begin
            repeat
                InsertVatStatLine(
                  Format(Text007 + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '', '200', false, true, false,
                  "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Base, "General Posting Type"::Sale, '');
            until VATPostingSetup.Next() = 0;
            InsertCipher200 := true;
        end;

        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", VATCipherSetup."Acquisition Tax Before", VATCipherSetup."Acquisition Tax After");
        VATPostingSetup.SetFilter("VAT Calculation Type", '<>%1', VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.FindFirst() then begin
            repeat
                InsertVatStatLine(
                  Format(Text007 + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '', '200', false, false, false,
                  "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Base, "General Posting Type"::Purchase, '');
            until VATPostingSetup.Next() = 0;
            InsertCipher200 := true;
        end;
        VATPostingSetup.SetRange("VAT Calculation Type");

        if InsertCipher200 then begin
            InsertVatStatLine(
              Text008, '200', 'Z200', true, false, false, "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ",
              VATCipherSetup."Total Revenue");
            RowTotValue := 'Z200';
        end;

        CreateSalesStatLine(
          VATCipherSetup."Revenue of Non-Tax. Services", Text009, false, false, Text007, true, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Revenue of Non-Tax. Services");
        InsertVatStatLine('', '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        InsertVatStatLine(Text010, '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        CreateSalesStatLine(
          VATCipherSetup."Deduction of Tax-Exempt", Text012, false, true, Text011, false, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Deduction of Tax-Exempt");
        CreateSalesStatLine(
          VATCipherSetup."Deduction of Services Abroad", Text014, false, true, Text013, false, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Deduction of Services Abroad");
        CreateSalesStatLine(
          VATCipherSetup."Deduction of Transfer", Text016, false, true, Text015, false, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Deduction of Transfer");
        CreateSalesStatLine(
          VATCipherSetup."Deduction of Non-Tax. Services", Text018, false, true, Text017, false, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Deduction of Non-Tax. Services");
        CreateSalesStatLine(
          VATCipherSetup."Reduction in Payments", Text020, false, true, Text019, true, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Reduction in Payments");
        CreateSalesStatLine(
          VATCipherSetup.Miscellaneous, Text022, false, true, Text021, false, false, false, "General Posting Type"::Sale,
          VATCipherSetup.Miscellaneous);

        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", VATCipherSetup."Deduction of Tax-Exempt", VATCipherSetup.Miscellaneous);
        if VATPostingSetup.FindFirst() then begin
            InsertVatStatLine(Text023, 'Z220|Z221|Z225|Z230|Z235|Z280', 'Z289', true, false, true,
              "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", VATCipherSetup."Total Deductions");
            if RowTotValue <> '' then
                RowTotValue := RowTotValue + '|' + 'Z289'
            else
                RowTotValue := 'Z289';
        end;
        if RowTotValue <> '' then
            InsertVatStatLine(
              Text024, RowTotValue, 'Z299', true, false, false, "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ",
              VATCipherSetup."Total Taxable Revenue");
        InsertVatStatLine('', '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
    end;

    local procedure InsertSalestaxAmounts()
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        InsertVatStatLine(Text025, '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        CreateSalesStatLine(
          VATCipherSetup."Tax Normal Rate Serv. Before", Text027, false, false, Text026, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Normal Rate Serv. Before");
        CreateSalesStatLine(
          VATCipherSetup."Tax Normal Rate Serv. After", Text046, false, false, Text026, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Normal Rate Serv. After");
        CreateSalesStatLine(
          VATCipherSetup."Tax Reduced Rate Serv. Before", Text029, false, false, Text028, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Reduced Rate Serv. Before");
        CreateSalesStatLine(
          VATCipherSetup."Tax Reduced Rate Serv. After", Text047, false, false, Text028, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Reduced Rate Serv. After");
        CreateSalesStatLine(
          VATCipherSetup."Tax Hotel Rate Serv. Before", Text031, false, false, Text030, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Hotel Rate Serv. Before");
        CreateSalesStatLine(
          VATCipherSetup."Tax Hotel Rate Serv. After", Text048, false, false, Text030, true, false, true, "General Posting Type"::Sale,
          VATCipherSetup."Tax Hotel Rate Serv. After");
        VATCalcType := VATCalcType::"Reverse Charge VAT";
        CreateSalesStatLine(
          VATCipherSetup."Acquisition Tax Before", Text033, false, false, Text032, false,
          false, true, "General Posting Type"::Purchase, VATCipherSetup."Acquisition Tax Before");
        CreateSalesStatLine(
          VATCipherSetup."Acquisition Tax After", Text049, false, false, Text032, false,
          false, true, "General Posting Type"::Purchase, VATCipherSetup."Acquisition Tax After");
        InsertVatStatLine('', '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
    end;

    local procedure InsertPurchasetaxBaseamounts()
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.SetRange("Sales VAT Stat. Cipher");
        InsertVatStatLine(Text034, '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        CreatePurchStatLine(
          VATCipherSetup."Input Tax on Material and Serv", Text035, false, false, Text034, false, false,
          VATCipherSetup."Input Tax on Material and Serv");
        CreatePurchStatLine(
          VATCipherSetup."Input Tax on Investsments", Text036, false, false, Text034, false, false,
          VATCipherSetup."Input Tax on Investsments");
        CreatePurchStatLine(
          VATCipherSetup."Deposit Tax", Text037, false, false, Text034, false, false, VATCipherSetup."Deposit Tax");
        CreatePurchStatLine(
          VATCipherSetup."Input Tax Corrections", Text039, false, true, Text038, false, false, VATCipherSetup."Input Tax Corrections");
        CreatePurchStatLine(
          VATCipherSetup."Input Tax Cutbacks", Text041, false, true, Text040, false, false, VATCipherSetup."Input Tax Cutbacks");
        VATPostingSetup.SetRange("Purch. VAT Stat. Cipher", VATCipherSetup."Input Tax on Material and Serv", VATCipherSetup."Input Tax Cutbacks");
        if VATPostingSetup.FindFirst() then
            InsertVatStatLine(Text042, 'Z400|Z405|Z410|Z415|Z420', 'Z479', true, false, false,
              "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", VATCipherSetup."Total Input Tax");
    end;

    local procedure InsertSalestaxEuAmount()
    begin
        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("Sales VAT Stat. Cipher", '%1|%2', VATCipherSetup."Cash Flow Taxes", VATCipherSetup."Cash Flow Compensations");
        if not VATPostingSetup.FindFirst() then
            exit;
        InsertVatStatLine('', '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        InsertVatStatLine(Text043, '', '', true, false, false, "VAT Statement Line Type"::Description, "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        CreateSalesStatLine(
          VATCipherSetup."Cash Flow Taxes", Text044, false, false, Text026, true, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Cash Flow Taxes");
        CreateSalesStatLine(
          VATCipherSetup."Cash Flow Compensations", Text045, false, false, Text026, true, false, false, "General Posting Type"::Sale,
          VATCipherSetup."Cash Flow Compensations");
    end;

    local procedure InsertVatStatLine(Txt: Text[50]; RowTotal: Text[30]; Number: Code[10]; PrintSign: Boolean; ReverseSign: Boolean; PrintRevSign: Boolean; VATLineType2: Enum "VAT Statement Line Type"; AmountType2: Enum "VAT Statement Line Amount Type"; GenPostingType2: Enum "General Posting Type"; VATStatCipher: Code[20])
    begin
        VATStatementLine.Init();
        VATStatementLine."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementLine."Statement Name" := Text005;
        LineNo := LineNo + 10000;
        VATStatementLine."Line No." := LineNo;
        VATStatementLine."Row No." := Number;
        VATStatementLine.Description := Txt;
        VATStatementLine.Type := VATLineType2;
        if VATStatementLine.Type <> VATStatementLine.Type::Description then begin
            VATStatementLine."Gen. Posting Type" := GenPostingType2;
            VATStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            VATStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            VATStatementLine."Amount Type" := AmountType2;
            VATStatementLine."Row Totaling" := RowTotal;
            VATStatementLine."VAT Statement Cipher" := VATStatCipher;
        end;
        VATStatementLine.Print := PrintSign;
        if ReverseSign then
            VATStatementLine.Validate("Calculate with", VATStatementLine."Calculate with"::"Opposite Sign");
        if PrintRevSign then
            VATStatementLine.Validate("Print with", VATStatementLine."Print with"::"Opposite Sign");
        if (Number = '') or (VATStatementLine.Type = VATStatementLine.Type::"Row Totaling") then begin
            VATStatementLine."VAT Bus. Posting Group" := '';
            VATStatementLine."VAT Prod. Posting Group" := '';
        end;
        VATStatementLine.Insert();
    end;

    local procedure CreateSalesStatLine(FromCipher: Code[20]; TotTxtConst: Text[50]; TotReverseSign: Boolean; TotPrintSign: Boolean; LinTxtConst: Text[50]; LinReverseSign: Boolean; LinPrintSign: Boolean; CheckCondition: Boolean; LinGenPostingType: Enum "General Posting Type"; VatCipher: Code[20])
    begin
        VATPostingSetup.SetRange("Sales VAT Stat. Cipher", FromCipher);
        if VATPostingSetup.FindSet() then begin
            repeat
                if CheckCondition then begin
                    if VATCalcType <> VATCalcType::"Reverse Charge VAT" then
                        VATPostingSetup.TestField("VAT Calculation Type", VATCalcType);
                    if VATCalcType = VATCalcType::"Reverse Charge VAT" then
                        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                            VATPostingSetup.TestField("Purch. VAT Stat. Cipher")
                end;
                InsertVatStatLine(
                  Format(LinTxtConst + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '',
                  CopyStr(FromCipher, 1, 10),
                  false, LinReverseSign, LinPrintSign, "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Base, LinGenPostingType,
                  '');
            until VATPostingSetup.Next() = 0;
            InsertVatStatLine(
              Format(TotTxtConst, -50), Format(FromCipher, 0), 'Z' + '' + Format(FromCipher, 0), true, TotReverseSign, TotPrintSign,
              "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", VatCipher);
        end;
    end;

    local procedure CreatePurchStatLine(FromCipher: Code[20]; TotTxtConst: Text[50]; TotReverseSign: Boolean; TotPrintSign: Boolean; LinTxtConst: Text[50]; LinReverseSign: Boolean; LinPrintSign: Boolean; VatCipher: Code[20])
    begin
        VATPostingSetup.SetRange("Purch. VAT Stat. Cipher", FromCipher);
        if VATPostingSetup.FindSet() then begin
            repeat
                InsertVatStatLine(
                  Format(LinTxtConst + ' : ' + VATPostingSetup."VAT Bus. Posting Group" + ' / ' + VATPostingSetup."VAT Prod. Posting Group", -50), '',
                  CopyStr(FromCipher, 1, 10),
                  false, LinReverseSign, LinPrintSign, "VAT Statement Line Type"::"VAT Entry Totaling", "VAT Statement Line Amount Type"::Amount, "General Posting Type"::Purchase,
                  '');
            until VATPostingSetup.Next() = 0;
            InsertVatStatLine(
              Format(TotTxtConst, -50), FromCipher, CopyStr('Z' + '' + FromCipher, 1, 10), true, TotReverseSign, TotPrintSign,
              "VAT Statement Line Type"::"Row Totaling", "VAT Statement Line Amount Type"::" ", "General Posting Type"::" ", VatCipher);
        end;
    end;
}

