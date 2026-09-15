// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10101 "Reconcile AP to GL"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/ReconcileAPtoGL.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Reconcile AP to GL';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purchase Line"; "Purchase Line")
        {
            DataItemTableView = where("Document Type" = const(Order));
            RequestFilterFields = "Document No.", "Buy-from Vendor No.", Type, "No.", "Location Code", "Posting Group", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code";
            RequestFilterHeading = 'Purchase Order Line';
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Purchase_Line_Type; Type)
            {
            }
            column(Purchase_Line__No__; "No.")
            {
            }
            column(ItemDescription; ItemDescription)
            {
            }
            column(Purchase_Line__Document_No__; "Document No.")
            {
            }
            column(Purchase_Line__Buy_from_Vendor_No__; "Buy-from Vendor No.")
            {
            }
            column(Purchase_Line__Posting_Group_; "Posting Group")
            {
            }
            column(Purchase_Line__Qty__Rcd__Not_Invoiced_; "Qty. Rcd. Not Invoiced")
            {
            }
            column(DollarAmount; DollarAmount)
            {
            }
            column(Purchase_Line_Document_Type; "Document Type")
            {
            }
            column(Purchase_Line_Line_No_; "Line No.")
            {
            }
            column(Reconcile_Accounts_Payable_to_General_LedgerCaption; Reconcile_Accounts_Payable_to_General_LedgerCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Purchase_Line_TypeCaption; Purchase_Line_TypeCaptionLbl)
            {
            }
            column(Purchase_Line__No__Caption; Purchase_Line__No__CaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(Purchase_Line__Document_No__Caption; Purchase_Line__Document_No__CaptionLbl)
            {
            }
            column(Purchase_Line__Buy_from_Vendor_No__Caption; Purchase_Line__Buy_from_Vendor_No__CaptionLbl)
            {
            }
            column(Purchase_Line__Posting_Group_Caption; FieldCaption("Posting Group"))
            {
            }
            column(Purchase_Line__Qty__Rcd__Not_Invoiced_Caption; FieldCaption("Qty. Rcd. Not Invoiced"))
            {
            }
            column(DollarAmountCaption; DollarAmountCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ItemDescription := '';
                case Type of
                    Type::" ", Type::Resource:
                        CurrReport.Skip();
                    Type::"G/L Account":
                        if GLAccount.Get("No.") then
                            ItemDescription := GLAccount.Name;
                    Type::Item:
                        if Item.Get("No.") then
                            ItemDescription := Item.Description;
                    Type::"Fixed Asset":
                        if FixedAsset.Get("No.") then
                            ItemDescription := FixedAsset.Description;
                    Type::"Charge (Item)":
                        if ItemCharge.Get("No.") then
                            ItemDescription := ItemCharge.Description;
                end;
                /* Convert the amount to dollars if necessary */
                PurchaseHeader.Get("Document Type", "Document No.");
                if PurchaseHeader."Currency Code" = '' then
                    DollarAmount := "Amt. Rcd. Not Invoiced"
                else
                    DollarAmount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToFCY(
                          WorkDate(),
                          "Currency Code",
                          '',
                          "Amt. Rcd. Not Invoiced"));
                /* Now, find the A/P Account */
                Account := Text000;
                if Vendor.Get("Buy-from Vendor No.") then
                    if VendorPostingGroup.Get(Vendor."Vendor Posting Group") then
                        if GLAccount.Get(VendorPostingGroup."Payables Account") then
                            Account := GLAccount."No.";
                AddToTable(Account, -DollarAmount);
                /* Now the expense or asset account */
                if Type = Type::"G/L Account" then    // Use GL Account directly
                    AddToTable("No.", DollarAmount)
                else
                    if Type = Type::"Fixed Asset" then
                        AddToTable(GetFixedAssetGLAcc(), DollarAmount)
                    else begin          // Use Posting Group
                        Account := Text000;
                        if GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            if GLAccount.Get(GenPostingSetup."Purch. Account") then
                                Account := GLAccount."No.";
                        AddToTable(Account, DollarAmount);
                    end;

            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Amt. Rcd. Not Invoiced", '<>0');
                Clear(AcntTab);
                Clear(AmtTab);
                TabMax := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(FORMAT_TODAY_0_4__Control31; Format(Today, 0, 4))
            {
            }
            column(TIME_Control32; Time)
            {
            }
            column(CompanyInformation_Name_Control33; CompanyInformation.Name)
            {
            }
            column(USERID_Control36; UserId)
            {
            }
            column(Subtitle; Subtitle)
            {
            }
            column(AcntTab_TabPtr_; AcntTab[TabPtr])
            {
            }
            column(GLAccount_Name; GLAccount.Name)
            {
            }
            column(AmtTab_TabPtr_; AmtTab[TabPtr])
            {
            }
            column(AmtTab_TabPtr__Control46; -AmtTab[TabPtr])
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Reconcile_Accounts_Payable_to_General_LedgerCaption_Control30; Reconcile_Accounts_Payable_to_General_LedgerCaption_Control30Lbl)
            {
            }
            column(CurrReport_PAGENOCaption_Control34; CurrReport_PAGENOCaption_Control34Lbl)
            {
            }
            column(AcntTab_TabPtr_Caption; AcntTab_TabPtr_CaptionLbl)
            {
            }
            column(GLAccount_NameCaption; GLAccount_NameCaptionLbl)
            {
            }
            column(AmtTab_TabPtr_Caption; AmtTab_TabPtr_CaptionLbl)
            {
            }
            column(AmtTab_TabPtr__Control46Caption; AmtTab_TabPtr__Control46CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if TabPtr = TabMax then
                    CurrReport.Break();
                TabPtr := TabPtr + 1;
                if not GLAccount.Get(AcntTab[TabPtr]) then
                    Clear(GLAccount);
            end;

            trigger OnPreDataItem()
            begin
                TabPtr := 0;
                if (TabMax = ArrayLen(AcntTab) - 1) and (AcntTab[ArrayLen(AcntTab)] <> '') then
                    TabMax := ArrayLen(AcntTab);

                Subtitle := Text001;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FilterString := "Purchase Line".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        FixedAsset: Record "Fixed Asset";
        ItemCharge: Record "Item Charge";
        VendorPostingGroup: Record "Vendor Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
        CurrExchRate: Record "Currency Exchange Rate";
        Account: Code[20];
        DollarAmount: Decimal;
        FilterString: Text;
        ItemDescription: Text;
        Subtitle: Text[126];
        AcntTab: array[100] of Code[20];
        AmtTab: array[100] of Decimal;
        TabMax: Integer;
        TabPtr: Integer;
        Top: Integer;
        Bottom: Integer;
        Middle: Integer;
        Found: Boolean;
        NotFound: Boolean;
        Text000: Label 'UNKNOWN';
        Text001: Label '(Accruals)';
        Reconcile_Accounts_Payable_to_General_LedgerCaptionLbl: Label 'Reconcile Accounts Payable to General Ledger';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Purchase_Line_TypeCaptionLbl: Label 'Line Type';
        Purchase_Line__No__CaptionLbl: Label 'Number';
        ItemDescriptionCaptionLbl: Label 'Description';
        Purchase_Line__Document_No__CaptionLbl: Label 'Purchase Order No.';
        Purchase_Line__Buy_from_Vendor_No__CaptionLbl: Label 'Vendor';
        DollarAmountCaptionLbl: Label 'Amt Received Not Invoiced';
        Reconcile_Accounts_Payable_to_General_LedgerCaption_Control30Lbl: Label 'Reconcile Accounts Payable to General Ledger';
        CurrReport_PAGENOCaption_Control34Lbl: Label 'Page';
        AcntTab_TabPtr_CaptionLbl: Label 'Account Number';
        GLAccount_NameCaptionLbl: Label 'Description';
        AmtTab_TabPtr_CaptionLbl: Label 'Debit';
        AmtTab_TabPtr__Control46CaptionLbl: Label 'Credit';

    procedure AddToTable(Acnt: Code[20]; Amt: Decimal)
    begin
        /* Adds the Account and Amount to the temporary table */
        /* First, search for Acnt in the Table (using binary search) */
        Top := 0;
        Bottom := TabMax + 1;
        Found := false;
        NotFound := false;
        repeat
            if Bottom - Top < 2 then begin
                Middle := Bottom;   // we can insert here
                NotFound := true;
            end else begin
                Middle := (Bottom + Top) div 2;
                if Acnt > AcntTab[Middle] then
                    Top := Middle
                else
                    if Acnt < AcntTab[Middle] then
                        Bottom := Middle
                    else    // must be equal; we found it
                        Found := true;
            end;
        until Found or NotFound;
        if NotFound then    // insert a new one
            if TabMax >= ArrayLen(AcntTab) - 1 then begin      // if no room, do our best
                Middle := ArrayLen(AcntTab);
                AcntTab[Middle] := 'OTHERS';
            end else begin
                for TabPtr := TabMax downto Middle do begin
                    AcntTab[TabPtr + 1] := AcntTab[TabPtr];
                    AmtTab[TabPtr + 1] := AmtTab[TabPtr];
                end;
                TabMax := TabMax + 1;
                AcntTab[Middle] := Acnt;
                AmtTab[Middle] := 0;
            end;
        AmtTab[Middle] := AmtTab[Middle] + Amt;

    end;

    local procedure GetFixedAssetGLAcc() GLAccNo: Code[20]
    var
        FADepBook: Record "FA Depreciation Book";
        DepBook: Record "Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        GLAccNo := Text000;
        FADepBook.Reset();
        FADepBook.SetRange("FA No.", FixedAsset."No.");
        FADepBook.SetFilter("Depreciation Book Code", '<>%1', '');
        FADepBook.SetFilter("FA Posting Group", '<>%1', '');
        if FADepBook.Find('-') then
            repeat
                DepBook.Get(FADepBook."Depreciation Book Code");
                if (("Purchase Line"."FA Posting Type" = "Purchase Line"."FA Posting Type"::"Acquisition Cost") and
                    DepBook."G/L Integration - Acq. Cost") or
                   (("Purchase Line"."FA Posting Type" = "Purchase Line"."FA Posting Type"::Maintenance) and
                    DepBook."G/L Integration - Maintenance")
                then begin
                    FAPostingGroup.Get(FADepBook."FA Posting Group");
                    if "Purchase Line"."FA Posting Type" = "Purchase Line"."FA Posting Type"::"Acquisition Cost" then
                        GLAccNo := FAPostingGroup."Acquisition Cost Account"
                    else
                        GLAccNo := FAPostingGroup."Maintenance Expense Account";
                    exit;
                end;
            until FADepBook.Next() = 0;
    end;
}

