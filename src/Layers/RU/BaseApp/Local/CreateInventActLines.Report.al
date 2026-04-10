#pragma warning disable AA0247
report 14913 "Create Invent. Act Lines"
{
    Caption = 'Create Invent. Act Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Invent. Act Header"; "Invent. Act Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                TestField("Inventory Date");
            end;

            trigger OnPreDataItem()
            begin
                if Count <> 1 then
                    Error(Text001);
            end;
        }
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                CustPostGroupBuffer.DeleteAll();

                CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
                CustLedgerEntry.SetRange("Customer No.", "No.");
                CustLedgerEntry.SetRange("Posting Date", 0D, "Invent. Act Header"."Inventory Date");
                if CustLedgerEntry.FindSet() then
                    repeat
                        if not CustPostGroupBuffer.Get(CustLedgerEntry."Customer Posting Group") then begin
                            CustPostGroup.Get(CustLedgerEntry."Customer Posting Group");
                            CustPostGroupBuffer := CustPostGroup;
                            CustPostGroupBuffer.Insert();
                        end;
                    until CustLedgerEntry.Next() = 0;

                if CustPostGroupBuffer.FindSet() then
                    repeat
                        DebtsAmount := 0;
                        LiabilitiesAmount := 0;

                        CustLedgerEntry.SetRange("Date Filter", 0D, "Invent. Act Header"."Inventory Date");
                        CustLedgerEntry.SetRange("Customer Posting Group", CustPostGroupBuffer.Code);
                        if CustLedgerEntry.FindSet() then
                            repeat
                                CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                                if CustLedgerEntry."Remaining Amt. (LCY)" > 0 then
                                    DebtsAmount += CustLedgerEntry."Remaining Amt. (LCY)"
                                else
                                    LiabilitiesAmount -= CustLedgerEntry."Remaining Amt. (LCY)"
                            until CustLedgerEntry.Next() = 0;

                        if DebtsAmount <> 0 then
                            AddLine(0, "No.", 0, CustPostGroupBuffer.Code, CustPostGroupBuffer."Receivables Account", DebtsAmount);
                        if LiabilitiesAmount <> 0 then
                            AddLine(0, "No.", 1, CustPostGroupBuffer.Code, CustPostGroupBuffer."Receivables Account", LiabilitiesAmount);
                    until CustPostGroupBuffer.Next() = 0;
            end;
        }
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                VendPostGroupBuffer.DeleteAll();

                VendLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date", "Currency Code");
                VendLedgerEntry.SetRange("Vendor No.", "No.");
                VendLedgerEntry.SetRange("Posting Date", 0D, "Invent. Act Header"."Inventory Date");
                if VendLedgerEntry.FindSet() then
                    repeat
                        if not VendPostGroupBuffer.Get(VendLedgerEntry."Vendor Posting Group") then begin
                            VendPostGroup.Get(VendLedgerEntry."Vendor Posting Group");
                            VendPostGroupBuffer := VendPostGroup;
                            VendPostGroupBuffer.Insert();
                        end;
                    until VendLedgerEntry.Next() = 0;

                if VendPostGroupBuffer.FindSet() then
                    repeat
                        DebtsAmount := 0;
                        LiabilitiesAmount := 0;

                        VendLedgerEntry.SetRange("Date Filter", 0D, "Invent. Act Header"."Inventory Date");
                        VendLedgerEntry.SetRange("Vendor Posting Group", VendPostGroupBuffer.Code);
                        if VendLedgerEntry.FindSet() then
                            repeat
                                VendLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                                if VendLedgerEntry."Remaining Amt. (LCY)" > 0 then
                                    DebtsAmount += VendLedgerEntry."Remaining Amt. (LCY)"
                                else
                                    LiabilitiesAmount -= VendLedgerEntry."Remaining Amt. (LCY)"
                            until VendLedgerEntry.Next() = 0;

                        if DebtsAmount <> 0 then
                            AddLine(1, "No.", 0, VendPostGroupBuffer.Code, VendPostGroupBuffer."Payables Account", DebtsAmount);
                        if LiabilitiesAmount <> 0 then
                            AddLine(1, "No.", 1, VendPostGroupBuffer.Code, VendPostGroupBuffer."Payables Account", LiabilitiesAmount);
                    until VendPostGroupBuffer.Next() = 0;
            end;
        }
    }

    requestpage
    {

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

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        InventActLine: Record "Invent. Act Line";
#pragma warning disable AA0074
        Text001: Label 'Incorrect using of report.';
#pragma warning restore AA0074
        CustPostGroup: Record "Customer Posting Group";
        CustPostGroupBuffer: Record "Customer Posting Group" temporary;
        VendPostGroup: Record "Vendor Posting Group";
        VendPostGroupBuffer: Record "Vendor Posting Group" temporary;
        DebtsAmount: Decimal;
        LiabilitiesAmount: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Line %1 already exists. Do you want to overwrite?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure AddLine(ContractorType: Option Customer,Vendor; ContractorNo: Code[20]; Category: Option Debts,Liabilities; PostingGroup: Code[20]; GLAccount: Code[20]; Amount: Decimal)
    begin
        InventActLine.Init();
        InventActLine."Act No." := "Invent. Act Header"."No.";
        InventActLine."Contractor Type" := ContractorType;
        InventActLine."Contractor No." := ContractorNo;
        InventActLine."Posting Group" := PostingGroup;
        InventActLine.Category := Category;
        if ContractorType = ContractorType::Customer then
            InventActLine."Contractor Name" := Customer.Name + Customer."Name 2"
        else
            InventActLine."Contractor Name" := Vendor.Name + Vendor."Name 2";
        InventActLine."G/L Account No." := GLAccount;
        InventActLine."Total Amount" := Amount;
        InventActLine."Confirmed Amount" := Amount;
        if not InventActLine.Insert() then
            if Confirm(Text002, false, InventActLine.GetRecDescription()) then
                InventActLine.Modify();
    end;
}

