// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

report 28091 "Create Check Installments"
{
    Caption = 'Create Check Installments';
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(PostDatedCheckLine; "Post Dated Check Line")
        {

            trigger OnPreDataItem()
            begin
                if NoInstallments <= 1 then
                    Error(Text000);
                if StartDocNo = '' then
                    Error(text001);
                PostDatedCheck.Reset();
                if PostDatedCheck.FindLast() then
                    LineNo := PostDatedCheck."Line Number";
                CheckDate := "Check Date";
                NextDocNo := StartDocNo;
                CheckNo := "Check No.";
                GLSetup.Get();
                TempPostDatedCheck.Reset();
                TempPostDatedCheck.SetRange("Document No.", "Document No.");
                if TempPostDatedCheck.FindFirst() then begin
                    if NoInstallments > 1 then
                        for i := 1 to (NoInstallments - 1) do begin
                            PostDatedCheck.Init();
                            PostDatedCheck.TransferFields(PostDatedCheckLine);
                            PostDatedCheck."Line Number" := LineNo + 10000;
                            PostDatedCheck."Check No." := IncStr(PostDatedCheck."Check No.");
                            PostDatedCheck.Validate("Check No.", IncStr(CheckNo));
                            PostDatedCheck.Validate("Document No.", IncStr(NextDocNo));
                            if GLSetup."Interest Cal Excl. VAT" then begin
                                AmountExcVAT := CalAmtExcVAT();
                                PostDatedCheck.Validate(Amount, (Amount + "Interest %" * AmountExcVAT / 100) / NoInstallments);
                                PostDatedCheck.Validate("Interest Amount", Round(AmountExcVAT * ("Interest %" / 100) / NoInstallments));
                            end else begin
                                PostDatedCheck.Validate(Amount, Amount * (1 + "Interest %" / 100) / NoInstallments);
                                PostDatedCheck.Validate("Interest Amount", Round(Amount * ("Interest %" / 100) / NoInstallments));
                            end;
                            TempAmount := TempAmount + (Amount / NoInstallments);
                            PostDatedCheck.Validate("Check Date", CalcDate("Period Length", CheckDate));
                            PostDatedCheck.Insert();
                            LineNo := LineNo + 10000;
                            CheckNo := IncStr(CheckNo);
                            NextDocNo := IncStr(NextDocNo);
                            CheckDate := CalcDate("Period Length", CheckDate);
                        end;
                    if GLSetup."Interest Cal Excl. VAT" then begin
                        Validate("Interest Amount", Round((AmountExcVAT * "Interest %" / 100) / NoInstallments));
                        Validate(Amount, Round((Amount - TempAmount) + (AmountExcVAT * "Interest %" / 100) / NoInstallments));
                    end else begin
                        Validate("Interest Amount", Round((Amount - TempAmount) * ("Interest %" / 100)));
                        Validate(Amount, (Amount - TempAmount) * (1 + "Interest %" / 100));
                    end;
                    Validate("Document No.", StartDocNo);
                    Modify();
                end;
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
                    field(NoOfInstallments; NoInstallments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Installments';
                        ToolTip = 'Specifies the number of installments for the check.';
                    }
                    field(InterestPct; "Interest %")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Interest %';
                        ToolTip = 'Specifies the percent.';
                    }
                    field(PeriodLength; "Period Length")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(StartDocumentNo; StartDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Document No';
                        ToolTip = 'Specifies the first document number.';
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

    var
        NoInstallments: Integer;
        "Interest %": Decimal;
        "Period Length": DateFormula;
        PostDatedCheck: Record "Post Dated Check Line";
        LineNo: Integer;
        TempAmount: Decimal;
        i: Integer;
        CheckDate: Date;
        StartDocNo: Code[20];
        NextDocNo: Code[20];
        Text000: Label 'The number of Installments should be greater than 1';
        text001: Label 'Please enter Start Document No ';
        GLSetup: Record "General Ledger Setup";
        AmountExcVAT: Decimal;
        TempPostDatedCheck: Record "Post Dated Check Line";
        CheckNo: Code[20];

    [Scope('OnPrem')]
    procedure SetPostDatedCheckLine(var tempPostDatedCheckLine: Record "Post Dated Check Line")
    begin
        PostDatedCheckLine := tempPostDatedCheckLine;
    end;

    [Scope('OnPrem')]
    procedure CalAmtExcVAT() VATBaseAmt: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmtVAT: Decimal;
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        if TempPostDatedCheck."Account Type" = TempPostDatedCheck."Account Type"::Vendor then
            if (TempPostDatedCheck."Applies-to Doc. Type" = TempPostDatedCheck."Applies-to Doc. Type"::Invoice) and
               (TempPostDatedCheck."Applies-to Doc. No." <> '')
            then begin
                VendorLedgerEntry.Reset();
                VendorLedgerEntry.SetRange(Open, true);
                VendorLedgerEntry.SetRange("Document Type", TempPostDatedCheck."Applies-to Doc. Type");
                VendorLedgerEntry.SetRange("Document No.", TempPostDatedCheck."Applies-to Doc. No.");
                if VendorLedgerEntry.FindSet() then
                    repeat
                        VendorLedgerEntry.CalcFields(Amount);
                        PurchInvLine.Reset();
                        PurchInvLine.SetRange("Document No.", VendorLedgerEntry."Document No.");
                        if PurchInvLine.Find('-') then
                            repeat
                                AmtVAT := AmtVAT + ((PurchInvLine."Amount Including VAT" - PurchInvLine."VAT Base Amount") *
                                                    TempPostDatedCheck.Amount / Abs(VendorLedgerEntry.Amount));
                            until PurchInvLine.Next() = 0;
                        VATBaseAmt := (Abs(VendorLedgerEntry.Amount) - AmtVAT);
                    until VendorLedgerEntry.Next() = 0;
            end;
    end;
}

