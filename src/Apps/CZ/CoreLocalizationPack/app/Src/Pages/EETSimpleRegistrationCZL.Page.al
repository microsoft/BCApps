// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.History;
using System.Utilities;

#pragma implicitwith disable
page 31137 "EET Simple Registration CZL"
{
    Caption = 'EET Simple Registration';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "EET Entry CZL";
    SourceTableTemporary = true;
    SourceTableView = sorting("Entry No.") where("Entry No." = const(0));
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Business Premises Code"; Rec."Business Premises Code")
                {
                    ShowMandatory = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupBusinessPremisesCode(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateBusinessPremisesCode();
                    end;
                }
                field("Cash Register Code"; Rec."Cash Register Code")
                {
                    ShowMandatory = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupCashRegisterCode(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCashRegisterCode();
                    end;
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Applied Document Type"; Rec."Applied Document Type")
                {
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        ValidateAppliedDocType();
                    end;
                }
                field("Applied Document No."; Rec."Applied Document No.")
                {
                    Importance = Additional;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupAppliedDocNo(Text));
                    end;

                    trigger OnValidate()
                    begin
                        ValidateAppliedDocNo();
                    end;
                }
            }
            group(TaxpayerAuthorization)
            {
                Caption = 'Taxpayer and Authorization';
                field("Taxpayer ID"; Rec."Taxpayer ID")
                {
                }
                field("Authorizing Taxpayer ID"; Rec."Authorizing Taxpayer ID")
                {
                }
                field("Multiple Taxpayer Auth."; Rec."Multiple Taxpayer Auth.")
                {
                }
            }
            group(Sales)
            {
                Caption = 'Sales';

                field(TotalSalesAmount; TotalSalesAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total Sales Amount';
                    ToolTip = 'Specifies the total amount of the sale that was actually received, in the local currency.';

                    trigger OnValidate()
                    begin
                        CheckTotalSalesAmount();
                    end;
                }
                field(AmtForSubseqDrawSettle; AmtForSubseqDrawSettle)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Amt. For Subseq. Draw/Settle';
                    Importance = Additional;
                    ToolTip = 'Specifies the amount of the payment that is intended for subsequent drawdown or settlement, for example when a voucher, a prepaid card or a chip is topped up.';

                    trigger OnValidate()
                    begin
                        CheckTotalSalesAmount();
                    end;
                }
                field(AmtSubseqDrawnSettled; AmtSubseqDrawnSettled)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Amt. Subseq. Drawn/Settled';
                    Importance = Additional;
                    ToolTip = 'Specifies the amount of the payment that is a subsequent drawdown or settlement of an amount that was paid earlier, for example when a voucher or a prepaid card is used.';

                    trigger OnValidate()
                    begin
                        CheckTotalSalesAmount();
                    end;
                }
                group(GroupVATRateBasic)
                {
                    Caption = 'VAT Rate Basic';
                    Visible = false;
                    Enabled = false;
                    field("SalesAmount[1]"; SalesAmount[1])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Sales Amount';
                        ToolTip = 'Specifies Sales Amount (VAT Rate Basic)';

                        trigger OnValidate()
                        begin
                            ValidateSalesAmount(1);
                        end;
                    }
                    field("VATBase[1]"; VATBase[1])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Base';
                        ToolTip = 'Specifies the VAT base amount.';

                        trigger OnValidate()
                        begin
                            ValidateVATBase(1);
                        end;
                    }
                    field("VATAmount[1]"; VATAmount[1])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Amount';
                        ToolTip = 'Specifies the base VAT amount.';

                        trigger OnValidate()
                        begin
                            ValidateVATAmount(1);
                        end;
                    }
                    field("VATRate[1]"; VATRate[1])
                    {
                        AutoFormatType = 0;
                        Caption = 'VAT %';
                        DecimalPlaces = 0 : 2;
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies VAT %';

                        trigger OnValidate()
                        begin
                            ValidateVATRate(1);
                        end;
                    }
                    field("AmountArt90[1]"; AmountArt90[1])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Amount - Art.90';
                        Importance = Additional;
                        ToolTip = 'Specifies the base amount under paragraph 90th.';

                        trigger OnValidate()
                        begin
                            UpdateTotalSalesAmount();
                        end;
                    }
                }
                group(GroupVATRateReduced)
                {
                    Caption = 'VAT Rate Reduced';
                    Visible = false;
                    Enabled = false;
                    field("SalesAmount[2]"; SalesAmount[2])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Sales Amount';
                        ToolTip = 'Specifies Sales Amount (VAT Rate Reduced)';

                        trigger OnValidate()
                        begin
                            ValidateSalesAmount(2);
                        end;
                    }
                    field("VATBase[2]"; VATBase[2])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Base';
                        ToolTip = 'Specifies the reduced VAT base amount.';

                        trigger OnValidate()
                        begin
                            ValidateVATBase(2);
                        end;
                    }
                    field("VATAmount[2]"; VATAmount[2])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Amount';
                        ToolTip = 'Specifies the reduced VAT amount.';

                        trigger OnValidate()
                        begin
                            ValidateVATAmount(2);
                        end;
                    }
                    field("VATRate[2]"; VATRate[2])
                    {
                        AutoFormatType = 0;
                        Caption = 'VAT %';
                        DecimalPlaces = 0 : 2;
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies VAT %';

                        trigger OnValidate()
                        begin
                            ValidateVATRate(2);
                        end;
                    }
                    field("AmountArt90[2]"; AmountArt90[2])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Amount - Art.90';
                        Importance = Additional;
                        ToolTip = 'Specifies the reduced amount under paragraph 90th.';

                        trigger OnValidate()
                        begin
                            UpdateTotalSalesAmount();
                        end;
                    }
                }
                group(GroupVATRateReduced2)
                {
                    Caption = 'VAT Rate Reduced 2';
                    Visible = false;
                    Enabled = false;
                    field("SalesAmount[3]"; SalesAmount[3])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Sales Amount';
                        ToolTip = 'Specifies Sales Amount (VAT Rate Reduced 2)';

                        trigger OnValidate()
                        begin
                            ValidateSalesAmount(3);
                        end;
                    }
                    field("VATBase[3]"; VATBase[3])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Base';
                        ToolTip = 'Specifies the reduced VAT base amount.';

                        trigger OnValidate()
                        begin
                            ValidateVATBase(3);
                        end;
                    }
                    field("VATAmount[3]"; VATAmount[3])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'VAT Amount';
                        ToolTip = 'Specifies the reduced VAT amount 2.';

                        trigger OnValidate()
                        begin
                            ValidateVATAmount(3);
                        end;
                    }
                    field("VATRate[3]"; VATRate[3])
                    {
                        AutoFormatType = 0;
                        Caption = 'VAT %';
                        DecimalPlaces = 0 : 2;
                        MaxValue = 100;
                        MinValue = 0;
                        ToolTip = 'Specifies VAT %';

                        trigger OnValidate()
                        begin
                            ValidateVATRate(3);
                        end;
                    }
                    field("AmountArt90[3]"; AmountArt90[3])
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Amount - Art.90';
                        Importance = Additional;
                        ToolTip = 'Specifies the reduced VAT base amount.';

                        trigger OnValidate()
                        begin
                            UpdateTotalSalesAmount();
                        end;
                    }
                }
                group(GroupAmountOthers)
                {
                    Caption = 'Others';
                    Visible = false;
                    Enabled = false;
                    field(AmountArt89; AmountArt89)
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Amount - Art.89';
                        Importance = Additional;
                        ToolTip = 'Specifies the amount under paragraph 89th.';

                        trigger OnValidate()
                        begin
                            UpdateTotalSalesAmount();
                        end;
                    }
                    field(AmountExtFromVAT; AmountExtFromVAT)
                    {
                        AutoFormatType = 1;
                        AutoFormatExpression = '';
                        Caption = 'Amount Exempted From VAT';
                        Importance = Additional;
                        ToolTip = 'Specifies the amount of cash document VAT-exempt.';

                        trigger OnValidate()
                        begin
                            UpdateTotalSalesAmount();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Send)
            {
                Caption = 'Send';
                Image = SendElectronicDocument;
                ToolTip = 'Creates a new EET entry from the entered sale and sends it to the EET service.';

                trigger OnAction()
                begin
                    SendToService();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Send_Promoted; Send)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        GetSetup();
    end;

    trigger OnInit()
    begin
        Rec."Taxpayer ID" := Rec.GetTaxpayerID();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        EETServiceSetupCZL: Record "EET Service Setup CZL";
        ConfirmManagement: Codeunit "Confirm Management";
        TotalSalesAmount: Decimal;
        SalesAmount: array[3] of Decimal;
        VATRate: array[3] of Decimal;
        VATBase: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        AmountArt89: Decimal;
        AmountArt90: array[3] of Decimal;
        AmountExtFromVAT: Decimal;
        AmtForSubseqDrawSettle: Decimal;
        AmtSubseqDrawnSettled: Decimal;
        TotalSalesAmountErr: Label 'Total Sales Amount cannot be less than the sum of subsequent drawn/settled amounts.';

    local procedure GetSetup()
    begin
        GeneralLedgerSetup.Get();
        EETServiceSetupCZL.Get();
        InitVATRate();
    end;

    local procedure InitVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        i: Integer;
    begin
        for i := 1 to 3 do begin
            VATPostingSetup.SetRange("VAT Rate CZL", i);
            if VATPostingSetup.FindFirst() then
                VATRate[i] := VATPostingSetup."VAT %";
        end;
    end;

    local procedure LookupBusinessPremisesCode(var Text: Text): Boolean
    var
        EETBusinessPremisesCZL: Record "EET Business Premises CZL";
    begin
        EETBusinessPremisesCZL.Code := Rec."Business Premises Code";
        if Page.RunModal(0, EETBusinessPremisesCZL) = Action::LookupOK then begin
            Rec."Business Premises Code" := EETBusinessPremisesCZL.Code;
            ValidateBusinessPremisesCode();
            Text := EETBusinessPremisesCZL.Code;
            exit(true);
        end;
    end;

    local procedure ValidateBusinessPremisesCode()
    var
        EETBusinessPremisesCZL: Record "EET Business Premises CZL";
    begin
        if Rec."Business Premises Code" <> '' then
            EETBusinessPremisesCZL.Get(Rec."Business Premises Code");
        Rec."Cash Register Code" := '';
        Rec."Taxpayer ID" := Rec.GetTaxpayerID();
    end;

    local procedure LookupCashRegisterCode(var Text: Text): Boolean
    var
        EETCashRegisterCZL: Record "EET Cash Register CZL";
    begin
        EETCashRegisterCZL.SetRange("Business Premises Code", Rec."Business Premises Code");
        EETCashRegisterCZL."Business Premises Code" := Rec."Business Premises Code";
        EETCashRegisterCZL.Code := Rec."Cash Register Code";
        if Page.RunModal(0, EETCashRegisterCZL) = Action::LookupOK then begin
            Text := EETCashRegisterCZL.Code;
            exit(true);
        end;
    end;

    local procedure ValidateCashRegisterCode()
    var
        EETCashRegisterCZL: Record "EET Cash Register CZL";
    begin
        Rec."Cash Register Type" := Rec."Cash Register Type"::Default;
        Rec."Cash Register No." := '';
        Rec."Authorizing Taxpayer ID" := '';
        Rec."Multiple Taxpayer Auth." := false;
        if Rec."Cash Register Code" <> '' then begin
            EETCashRegisterCZL.Get(Rec."Business Premises Code", Rec."Cash Register Code");
            Rec."Cash Register Type" := EETCashRegisterCZL."Cash Register Type";
            Rec."Cash Register No." := EETCashRegisterCZL."Cash Register No.";
            Rec."Authorizing Taxpayer ID" := EETCashRegisterCZL."Authorizing Taxpayer ID";
            Rec."Multiple Taxpayer Auth." := EETCashRegisterCZL."Multiple Taxpayer Auth.";
        end;
    end;

    local procedure ValidateAppliedDocType()
    begin
        Rec."Applied Document No." := '';
    end;

    local procedure LookupAppliedDocNo(var Text: Text): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case Rec."Applied Document Type" of
            Rec."Applied Document Type"::Invoice:
                begin
                    SalesInvoiceHeader."No." := Rec."Applied Document No.";
                    if Page.RunModal(0, SalesInvoiceHeader) = Action::LookupOK then begin
                        Text := SalesInvoiceHeader."No.";
                        exit(true);
                    end;
                end;
            Rec."Applied Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader."No." := Rec."Applied Document No.";
                    if Page.RunModal(0, SalesCrMemoHeader) = Action::LookupOK then begin
                        Text := SalesCrMemoHeader."No.";
                        exit(true);
                    end;
                end;
        end;
    end;

    local procedure ValidateAppliedDocNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if Rec."Applied Document No." <> '' then
            case Rec."Applied Document Type" of
                Rec."Applied Document Type"::Invoice:
                    SalesInvoiceHeader.Get(Rec."Applied Document No.");
                Rec."Applied Document Type"::"Credit Memo":
                    SalesCrMemoHeader.Get(Rec."Applied Document No.");
            end;
    end;

    local procedure ValidateSalesAmount(Index: Integer)
    begin
        VATBase[Index] := Round(SalesAmount[Index] / (1 + VATRate[Index] / 100), GeneralLedgerSetup."Amount Rounding Precision");
        VATAmount[Index] := SalesAmount[Index] - VATBase[Index];
        UpdateTotalSalesAmount();
    end;

    local procedure ValidateVATBase(Index: Integer)
    begin
        VATAmount[Index] := Round(VATBase[Index] * VATRate[Index] / 100, GeneralLedgerSetup."Amount Rounding Precision");
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        UpdateTotalSalesAmount();
    end;

    local procedure ValidateVATAmount(Index: Integer)
    begin
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        if VATBase[Index] <> 0 then
            VATRate[Index] := Round(VATAmount[Index] / VATBase[Index] * 100, 0.01);
        UpdateTotalSalesAmount();
    end;

    local procedure ValidateVATRate(Index: Integer)
    begin
        VATAmount[Index] := Round(VATBase[Index] * VATRate[Index] / 100, GeneralLedgerSetup."Amount Rounding Precision");
        SalesAmount[Index] := VATBase[Index] + VATAmount[Index];
        UpdateTotalSalesAmount();
    end;

    local procedure UpdateTotalSalesAmount()
    begin
        TotalSalesAmount :=
          SalesAmount[1] + SalesAmount[2] + SalesAmount[3] +
          AmountArt89 + AmountArt90[1] + AmountArt90[2] + AmountArt90[3] +
          AmountExtFromVAT + AmtForSubseqDrawSettle + AmtSubseqDrawnSettled;
    end;

    local procedure CheckTotalSalesAmount()
    begin
        if TotalSalesAmount < (AmtForSubseqDrawSettle + AmtSubseqDrawnSettled) then
            Error(TotalSalesAmountErr);
    end;

    procedure SendToService()
    var
        EETEntryCZL: Record "EET Entry CZL";
        EETManagementCZL: Codeunit "EET Management CZL";
        NewEETEntryNo: Integer;
        MustEnterErr: Label 'You must enter %1.', Comment = '%1 = Field Name';
        SendToServiceQst: Label 'Do you want to send sales to EET service?';
        OpenNewEntryQst: Label 'The new entry %1 has been created. Do you want to open the new entry?', Comment = '%1 = New EET Entry No.';
    begin
        if Rec."Business Premises Code" = '' then
            Error(MustEnterErr, Rec.FieldCaption("Business Premises Code"));
        if Rec."Cash Register Code" = '' then
            Error(MustEnterErr, Rec.FieldCaption("Cash Register Code"));
        if TotalSalesAmount = 0 then
            Error(MustEnterErr, Rec.FieldCaption("Total Sales Amount"));
        if not ConfirmManagement.GetResponseOrDefault(SendToServiceQst, true) then
            exit;

        Rec."Total Sales Amount" := TotalSalesAmount;
        Rec."Amount Exempted From VAT" := AmountExtFromVAT;
        Rec."VAT Base (Basic)" := VATBase[1];
        Rec."VAT Amount (Basic)" := VATAmount[1];
        Rec."VAT Base (Reduced)" := VATBase[2];
        Rec."VAT Amount (Reduced)" := VATAmount[2];
        Rec."VAT Base (Reduced 2)" := VATBase[3];
        Rec."VAT Amount (Reduced 2)" := VATAmount[3];
        Rec."Amount - Art.89" := AmountArt89;
        Rec."Amount (Basic) - Art.90" := AmountArt90[1];
        Rec."Amount (Reduced) - Art.90" := AmountArt90[2];
        Rec."Amount (Reduced 2) - Art.90" := AmountArt90[3];
        Rec."Amt. For Subseq. Draw/Settle" := AmtForSubseqDrawSettle;
        Rec."Amt. Subseq. Drawn/Settled" := AmtSubseqDrawnSettled;

        EETEntryCZL.Init();
        EETEntryCZL.CopyFromEETEntry(Rec);
        NewEETEntryNo := EETManagementCZL.CreateSimpleEETEntry(EETEntryCZL);
        Commit();

        EETEntryCZL.Get(NewEETEntryNo);
        EETManagementCZL.TrySendEntryToService(EETEntryCZL);

        Rec.Init();
        CurrPage.Update();
        InitVATRate();
        Clear(TotalSalesAmount);

        Commit();
        if ConfirmManagement.GetResponse(StrSubstNo(OpenNewEntryQst, EETEntryCZL."Entry No."), true) then
            Page.Run(Page::"EET Entry Card CZL", EETEntryCZL);
    end;
}
