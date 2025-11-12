// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Text;

codeunit 368 "Format Document"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        AutoFormat: Codeunit "Auto Format";

        PurchaserTxt: Label 'Purchaser';
        SalespersonTxt: Label 'Salesperson';
        TotalTxt: Label 'Total %1', Comment = '%1 = Currency Code';
        TotalInclVATTxt: Label 'Total %1 Incl. VAT', Comment = '%1 = Currency Code';
        TotalExclVATTxt: Label 'Total %1 Excl. VAT', Comment = '%1 = Currency Code';
        COPYTxt: Label 'COPY', Comment = 'COPY';

    procedure GetRecordFiltersWithCaptions(RecVariant: Variant) Filters: Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldFilter: Text;
        Name: Text;
        Cap: Text;
        Pos: Integer;
        i: Integer;
    begin
        // <summary>
        // The function generated a string containing all filters applied to a record.
        // It is used mainly in reports to demonstrate which filters were used when the generating the report.
        // </summary>
        // <param name="RecVariant">Variant holding the record to check</param>
        // <returns>Text representation of all field filter applied to a record</returns>

        RecRef.GetTable(RecVariant);
        Filters := RecRef.GetFilters();
        if Filters = '' then
            exit;

        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            FieldFilter := FieldRef.GetFilter;
            if FieldFilter <> '' then begin
                Name := StrSubstNo('%1: ', FieldRef.Name);
                Cap := StrSubstNo('%1: ', FieldRef.Caption);
                Pos := StrPos(Filters, Name);
                if Pos <> 0 then
                    Filters := InsStr(DelStr(Filters, Pos, StrLen(Name)), Cap, Pos);
            end;
        end;
    end;

    procedure GetCOPYText(): Text[30]
    begin
        exit(' ' + COPYTxt);
    end;

    procedure ParseComment(Comment: Text[80]; var Description: Text[100]; var Description2: Text[100])
    var
        SpacePointer: Integer;
    begin
        if StrLen(Comment) <= MaxStrLen(Description) then begin
            Description := CopyStr(Comment, 1, MaxStrLen(Description));
            Description2 := '';
        end else begin
            SpacePointer := MaxStrLen(Description) + 1;
            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                SpacePointer := SpacePointer - 1;
            if SpacePointer = 1 then
                SpacePointer := MaxStrLen(Description) + 1;
            Description := CopyStr(Comment, 1, SpacePointer - 1);
            Description2 := CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(Description2));
        end;
    end;

    procedure SetTotalLabels(CurrencyCode: Code[10]; var TotalText: Text[50]; var TotalInclVATText: Text[50]; var TotalExclVATText: Text[50])
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            GLSetup.TestField("LCY Code");
            TotalText := StrSubstNo(TotalTxt, GLSetup."LCY Code");
            TotalInclVATText := StrSubstNo(TotalInclVATTxt, GLSetup."LCY Code");
            TotalExclVATText := StrSubstNo(TotalExclVATTxt, GLSetup."LCY Code");
        end else begin
            TotalText := StrSubstNo(TotalTxt, CurrencyCode);
            TotalInclVATText := StrSubstNo(TotalInclVATTxt, CurrencyCode);
            TotalExclVATText := StrSubstNo(TotalExclVATTxt, CurrencyCode);
        end;

        OnAfterSetTotalLabels(CurrencyCode, TotalText, TotalInclVATText, TotalExclVATText);
    end;

    procedure SetLogoPosition(LogoPosition: Option "No Logo",Left,Center,Right; var CompanyInfo1: Record "Company Information"; var CompanyInfo2: Record "Company Information"; var CompanyInfo3: Record "Company Information")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLogoPosition(LogoPosition, CompanyInfo1, CompanyInfo2, CompanyInfo3, IsHandled);
        if IsHandled then
            exit;

        case LogoPosition of
            LogoPosition::"No Logo":
                ;
            LogoPosition::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            LogoPosition::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            LogoPosition::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    procedure SetPaymentMethod(var PaymentMethod: Record "Payment Method"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            PaymentMethod.Init()
        else begin
            PaymentMethod.Get(Code);
            PaymentMethod.TranslateDescription(LanguageCode);
        end;
    end;

    procedure SetPaymentTerms(var PaymentTerms: Record "Payment Terms"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            PaymentTerms.Init()
        else begin
            PaymentTerms.Get(Code);
            PaymentTerms.TranslateDescription(PaymentTerms, LanguageCode);
        end;
    end;

    procedure SetPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser"; "Code": Code[20]; var PurchaserText: Text[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPurchaser(SalespersonPurchaser, "Code", PurchaserText, IsHandled);
        if IsHandled then
            exit;

        if Code = '' then begin
            SalespersonPurchaser.Init();
            PurchaserText := '';
        end else begin
            SalespersonPurchaser.Get(Code);
            PurchaserText := PurchaserTxt;
        end;
    end;

    procedure SetShipmentMethod(var ShipmentMethod: Record "Shipment Method"; "Code": Code[10]; LanguageCode: Code[10])
    begin
        if Code = '' then
            ShipmentMethod.Init()
        else begin
            ShipmentMethod.Get(Code);
            ShipmentMethod.TranslateDescription(ShipmentMethod, LanguageCode);
        end;
    end;

    procedure SetSalesPerson(var SalespersonPurchaser: Record "Salesperson/Purchaser"; "Code": Code[20]; var SalesPersonText: Text[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalesPerson(SalespersonPurchaser, "Code", SalesPersonText, IsHandled);
        if IsHandled then
            exit;

        if Code = '' then begin
            SalespersonPurchaser.Init();
            SalesPersonText := '';
        end else begin
            SalespersonPurchaser.Get(Code);
            SalesPersonText := SalespersonTxt;
        end;
    end;

    procedure SetText(Condition: Boolean; Caption: Text[80]): Text[80]
    begin
        if Condition then
            exit(Caption);

        exit('');
    end;

    procedure SetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetSalesInvoiceLine(SalesInvoiceLine);
        SetSalesPurchaseLine(not SalesInvoiceLine.HasTypeToFillMandatoryFields(),
          SalesInvoiceLine.Quantity,
          SalesInvoiceLine."Unit Price",
          SalesInvoiceLine."VAT %",
          SalesInvoiceLine."Line Amount",
          SalesInvoiceLine.GetCurrencyCode(),
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetSalesInvoiceLine(SalesInvoiceLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    procedure SetSalesLine(var SalesLine: Record "Sales Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetSalesLine(SalesLine);
        SetSalesPurchaseLine(not SalesLine.HasTypeToFillMandatoryFields(),
          SalesLine.Quantity,
          SalesLine."Unit Price",
          SalesLine."VAT %",
          SalesLine."Line Amount",
          SalesLine."Currency Code",
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetSalesLine(SalesLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    procedure SetSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        OnBeforeSetSalesCrMemoLine(SalesCrMemoLine);
        SetSalesPurchaseLine(not SalesCrMemoLine.HasTypeToFillMandatoryFields(),
          SalesCrMemoLine.Quantity,
          SalesCrMemoLine."Unit Price",
          SalesCrMemoLine."VAT %",
          SalesCrMemoLine."Line Amount",
          SalesCrMemoLine.GetCurrencyCode(),
          FormattedQuantity,
          FormattedUnitPrice,
          FormattedVATPercentage,
          FormattedLineAmount);
        OnAfterSetSalesCrMemoLine(SalesCrMemoLine, FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount);
    end;

    procedure SetPurchaseLine(var PurchaseLine: Record "Purchase Line"; var FormattedQuantity: Text; var FormattedDirectUnitCost: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    begin
        SetSalesPurchaseLine(not PurchaseLine.HasTypeToFillMandatoryFields(),
          PurchaseLine.Quantity,
          PurchaseLine."Direct Unit Cost",
          PurchaseLine."VAT %",
          PurchaseLine."Line Amount",
          PurchaseLine."Currency Code",
          FormattedQuantity,
          FormattedDirectUnitCost,
          FormattedVATPercentage,
          FormattedLineAmount);
    end;

    procedure SetPurchaseLine(var PurchaseLine: Record "Purchase Line"; var FormattedQuantity: Text; var FormattedDirectUnitCost: Text)
    var
        TempVatPct: Text;
        TempLineAmount: Text;
    begin
        SetSalesPurchaseLine(not PurchaseLine.HasTypeToFillMandatoryFields(),
          PurchaseLine.Quantity,
          PurchaseLine."Direct Unit Cost",
          PurchaseLine."VAT %",
          PurchaseLine."Line Amount",
          PurchaseLine."Currency Code",
          FormattedQuantity,
          FormattedDirectUnitCost,
          TempVatPct,
          TempLineAmount);
    end;

    local procedure SetSalesPurchaseLine(CommentLine: Boolean; Quantity: Decimal; UnitPrice: Decimal; VATPercentage: Decimal; LineAmount: Decimal; CurrencyCode: Code[10]; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text)
    var
        AutoFormatType: Enum "Auto Format";
    begin
        if CommentLine then begin
            FormattedQuantity := '';
            FormattedUnitPrice := '';
            FormattedVATPercentage := '';
            FormattedLineAmount := '';
        end else begin
            FormattedQuantity := Format(Quantity);
            FormattedUnitPrice := Format(UnitPrice, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::UnitAmountFormat, CurrencyCode));
            FormattedVATPercentage := Format(VATPercentage);
            FormattedLineAmount := Format(LineAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode));
        end;
        OnAfterSetSalesPurchaseLine(
          Quantity, UnitPrice, VATPercentage, LineAmount, CurrencyCode,
          FormattedQuantity, FormattedUnitPrice, FormattedVATPercentage, FormattedLineAmount, CommentLine);
    end;

    // <summary>
    // The function determines whether a line passed as Variant should be hidden in the printout.
    // It is used mainly in reports in order to hide lines for which the Quantity equals to 0.
    // </summary>
    // <param name="HideLinesWithZeroQuantity">Variant holding the boolean value whether the lines with quantity equal to zero should be printed</param>
    // <param name="RecordVariant">Variant holding the record to check</param>
    // <param name="QuantityFieldId">represents the field id for Quantity from RecordVariant</param>
    // <returns>true if Line lines should be hidden in the printout</returns>
    procedure HideDocumentLine(HideLinesWithZeroQuantity: Boolean; RecordVariant: Variant; QuantityFieldId: Integer) HideLine: Boolean
    begin
        if HideLinesWithZeroQuantity then
            HideLine := IsLineWithZeroQuantity(RecordVariant, QuantityFieldId)
        else
            HideLine := false;
        OnAfterHideDocumentLine(HideLinesWithZeroQuantity, RecordVariant, QuantityFieldId, HideLine);
    end;

    // <summary>
    // The function determines whether a line passed as Variant has Quantity equal to 0.
    // It is used mainly in reports in order to skip the lines for which the Quantity equals to 0.
    // The function can be used for all line tables that have the same id for following fields:
    // "Line No." - id = 4
    // Type - id = 5
    // "Attached to Line No." - id = 80
    // local variable TempSalesLine is used in order to improve readibility and clarity.
    // </summary>
    // <param name="RecordVariant">Variant holding the record to check</param>
    // <param name="QuantityFieldId">represents the field id for Quantity from RecordVariant</param>
    // <returns>true if Line has 0 in the quantity field represented by QuantityFieldId</returns>
    procedure IsLineWithZeroQuantity(RecordVariant: Variant; QuantityFieldId: Integer): Boolean
    var
        TempSalesLine: Record "Sales Line" temporary;
        RecRef: RecordRef;
        ParentRecRef: RecordRef;
        LineNo: Integer;
        LineType: Enum "Sales Line Type";
        ParentLineType: Enum "Sales Line Type";
        Quantity: Decimal;
        ParentQuantity: Decimal;
        AttachedToLineNo: Integer;
    begin
        RecRef.GetTable(RecordVariant);
        LineNo := RecRef.Field(TempSalesLine.FieldNo("Line No.")).Value;
        LineType := RecRef.Field(TempSalesLine.FieldNo(Type)).Value;
        Quantity := RecRef.Field(QuantityFieldId).Value;
        AttachedToLineNo := RecRef.Field(TempSalesLine.FieldNo("Attached to Line No.")).Value;
        case true of
            (Quantity = 0) and (LineType <> LineType::" "):
                exit(true);
            (LineType = LineType::" ") and (AttachedToLineNo <> 0):
                begin
                    ParentRecRef.Open(RecRef.Number);
                    ParentRecRef.Copy(RecRef);
                    ParentRecRef.SetRecFilter();
                    ParentRecRef.Field(TempSalesLine.FieldNo("Line No.")).SetFilter(Format(AttachedToLineNo));
                    if ParentRecRef.FindFirst() then begin
                        ParentLineType := ParentRecRef.Field(TempSalesLine.FieldNo(Type)).Value;
                        ParentQuantity := ParentRecRef.Field(QuantityFieldId).Value;
                        exit((ParentQuantity = 0) and (ParentLineType <> ParentLineType::" "));
                    end;
                end;
            else
                exit(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesPurchaseLine(Quantity: Decimal; UnitPrice: Decimal; VATPercentage: Decimal; LineAmount: Decimal; CurrencyCode: Code[10]; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text; CommentLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLine(var SalesLine: Record "Sales Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var FormattedQuantity: Text; var FormattedUnitPrice: Text; var FormattedVATPercentage: Text; var FormattedLineAmount: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTotalLabels(CurrencyCode: Code[10]; var TotalText: Text[50]; var TotalInclVATText: Text[50]; var TotalExclVATText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLogoPosition(var LogoPosition: Option "No Logo",Left,Center,Right; var CompanyInfo1: Record "Company Information"; var CompanyInfo2: Record "Company Information"; var CompanyInfo3: Record "Company Information"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser"; "Code": Code[20]; var PurchaserText: Text[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesPerson(var SalespersonPurchaser: Record "Salesperson/Purchaser"; "Code": Code[20]; var SalesPersonText: Text[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesLine(var SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHideDocumentLine(HideLinesWithZeroQuantity: Boolean; RecordVariant: Variant; QuantityFieldId: Integer; var HideLine: Boolean)
    begin
    end;
}

