// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;

page 35303 "Bank Account Information FB"
{
    Caption = 'Bank Account Information FB';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = "Bank Account";
    SourceTableView = sorting("Currency Code");

    layout
    {
        area(content)
        {
            field("CurrBillGr.Amount"; CurrBillGr.Amount)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = CurrBillGr."Currency Code";
                AutoFormatType = 1;
                Caption = 'Curr. Bill Gr. Amount';
                Editable = false;
                ToolTip = 'Specifies the current amount related to bill groups on the bank account.';

                trigger OnDrillDown()
                begin
                    Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code");
                    Doc.SetRange(Type, Doc.Type::Receivable);
                    Doc.SetRange("Bill Gr./Pmt. Order No.", CurrBillGr."No.");
                    Doc.SetFilter("Category Code", CategoryFilter);
                    PAGE.RunModal(0, Doc);
                end;

                trigger OnValidate()
                begin
                    CurrBillGrAmountOnAfterValidat();
                end;
            }
            field("CurrBillGr.""Currency Code"""; CurrBillGr."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Curr. Bill Gr.Currency Code';
                Editable = false;
                TableRelation = Currency;
                ToolTip = 'Specifies the currency of the bill groups amount. ';
            }
            field("CurrBillGr.""Amount (LCY)"""; CurrBillGr."Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Curr. Bill Gr. Amt. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the current amount related to bill groups on the bank account, in LCY.';

                trigger OnDrillDown()
                begin
                    Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code");
                    Doc.SetRange(Type, Doc.Type::Receivable);
                    Doc.SetRange("Bill Gr./Pmt. Order No.", CurrBillGr."No.");
                    Doc.SetFilter("Category Code", CategoryFilter);
                    PAGE.RunModal(0, Doc);
                end;

                trigger OnValidate()
                begin
                    CurrBillGrAmountLCYOnAfterVali();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RiskIncGr := Rec."Posted Receiv. Bills Rmg. Amt.";
        if (CurrBillGr."Dealing Type" = CurrBillGr."Dealing Type"::Discount) and
           (CurrBillGr.Factoring = CurrBillGr.Factoring::" ")
        then
            RiskIncGr := RiskIncGr + CurrBillGr.Amount;
        if Rec."Credit Limit for Discount" <> 0 then
            RiskPercIncGr := RiskIncGr / Rec."Credit Limit for Discount" * 100
        else
            if RiskIncGr = 0 then
                RiskPercIncGr := 0
            else
                RiskPercIncGr := 100;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount, "Amount (LCY)");
        if Rec.Get(CurrBillGr."Bank Account No.") then;
    end;

    var
        Doc: Record "Cartera Doc.";
        CurrBillGr: Record "Bill Group";
        RiskIncGr: Decimal;
        RiskPercIncGr: Decimal;
        CategoryFilter: Code[250];

    local procedure CurrBillGrAmountOnAfterValidat()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount);
        CurrPage.Update(false);
    end;

    local procedure CurrBillGrAmountLCYOnAfterVali()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount);
        CurrPage.Update(false);
    end;
}

