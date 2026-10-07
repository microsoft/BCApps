#pragma warning disable AA0247
report 17201 "Create Closing Gen. Jnl. Line"
{
    Caption = 'Create Closing Gen. Jnl. Line';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Tax Register CV Entry"; "Tax Register CV Entry")
        {
            DataItemTableView = sorting("Section Code", "Ending Date", "Object Type");
            RequestFilterFields = "Object Type", "C/V No.";
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                CalcFields = "Remaining Amt. (LCY)";
                DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date");

                trigger OnAfterGetRecord()
                begin
                    CustLedgEntry.Copy("Cust. Ledger Entry");
                    CustLedgEntry.SetRange("Date Filter");
                    CustLedgEntry.CalcFields("Remaining Amt. (LCY)");
                    SetFilter("Date Filter", '..%1', DateEnd);
                    if CustLedgEntry."Remaining Amt. (LCY)" = 0 then
                        CurrReport.Skip();

                    GenJnlLine.Init();
                    GenJnlLine."Line No." += 10000;
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                    GenJnlLine."Posting Date" := DateEnd;
                    GenJnlLine."Document No." := DocumentNo;
                    GenJnlLine.Validate("Account No.", "Customer No.");
                    GenJnlLine.Validate("Currency Code", '');
                    GenJnlLine.Validate(Amount, -CustLedgEntry."Remaining Amt. (LCY)");
                    GenJnlLine.Insert(true);
                    GenJnlLine.Validate("Shortcut Dimension 1 Code", "Global Dimension 1 Code");
                    GenJnlLine.Validate("Shortcut Dimension 2 Code", "Global Dimension 2 Code");
                    GenJnlLine.Modify(true);

                    GenJnlLine0.Amount += CustLedgEntry."Remaining Amt. (LCY)";
                    GenJnlLine0.Quantity := 1;
                end;

                trigger OnPreDataItem()
                begin
                    if "Tax Register CV Entry"."Object Type" <> "Tax Register CV Entry"."Object Type"::Customer then
                        CurrReport.Break();

                    SetCurrentKey("Customer No.", Open, Positive, "Due Date");
                    SetRange("Customer No.", "Tax Register CV Entry"."C/V No.");
                    SetRange(Positive, PositiveEntry);
                    SetFilter("Due Date", FilterDueDate3Years);
                    SetFilter("Date Filter", '..%1', DateEnd);
                    SetFilter("Remaining Amt. (LCY)", '<>0');
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                CalcFields = "Remaining Amt. (LCY)";
                DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date");

                trigger OnAfterGetRecord()
                begin
                    VendLedgEntry.Copy("Vendor Ledger Entry");
                    VendLedgEntry.SetRange("Date Filter");
                    VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
                    if VendLedgEntry."Remaining Amt. (LCY)" = 0 then
                        CurrReport.Skip();

                    GenJnlLine.Init();
                    GenJnlLine."Line No." += 10000;
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine."Posting Date" := DateEnd;
                    GenJnlLine."Document No." := DocumentNo;
                    GenJnlLine.Validate("Account No.", "Vendor No.");
                    GenJnlLine.Validate("Currency Code", '');
                    GenJnlLine.Validate(Amount, -VendLedgEntry."Remaining Amt. (LCY)");
                    GenJnlLine.Insert(true);
                    GenJnlLine.Validate("Shortcut Dimension 1 Code", "Global Dimension 1 Code");
                    GenJnlLine.Validate("Shortcut Dimension 2 Code", "Global Dimension 2 Code");
                    GenJnlLine.Modify(true);

                    GenJnlLine0.Amount += VendLedgEntry."Remaining Amt. (LCY)";
                    GenJnlLine0.Quantity := 1;
                end;

                trigger OnPreDataItem()
                begin
                    if "Tax Register CV Entry"."Object Type" <> "Tax Register CV Entry"."Object Type"::Vendor then
                        CurrReport.Break();

                    SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
                    SetRange("Vendor No.", "Tax Register CV Entry"."C/V No.");
                    SetRange(Positive, PositiveEntry);
                    SetFilter("Due Date", FilterDueDate3Years);
                    SetFilter("Date Filter", '..%1', DateEnd);
                    SetFilter("Remaining Amt. (LCY)", '<>0');
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange("Section Code", SectionCode);
                SetRange("Ending Date", DateEnd);
                if PositiveEntry then begin
                    SetRange("Register Type", "Register Type"::"Credit Balance");
                    SetFilter("CV Debit Balance Amnt 4", '<>0');
                end else begin
                    SetRange("Register Type", "Register Type"::"Debit Balance");
                    SetFilter("CV Credit Balance Amnt 2", '<>0');
                end;
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
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template" where(Type = const(General),
                                                                       Recurring = const(false));
                        ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Template Name" = '' then
                                GenJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        TableRelation = "Gen. Journal Batch";

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if GenJnlLine."Journal Template Name" <> '' then begin
                                GenJnlBatch.Reset();
                                GenJnlBatch.FilterGroup(2);
                                GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                                GenJnlBatch.FilterGroup(0);
                                LookupOK := ACTION::LookupOK = PAGE.RunModal(0, GenJnlBatch);
                                if LookupOK then begin
                                    GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
                                    GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                                end;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLineJournalBatchNameOnAfterValidate();
                        end;
                    }
                    field("GenJnlLine.""Bal. Account Type"""; GenJnlLine."Bal. Account Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bal. Account Type';
                        ToolTip = 'Specifies the type of the balancing account that has been entered on the journal line.';
                    }
                    field("GenJnlLine.""Bal. Account No."""; GenJnlLine."Bal. Account No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bal. Account No.';
                        ToolTip = 'Specifies the number of the balancing account that has been entered on the journal line.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            case GenJnlLine."Bal. Account Type" of
                                GenJnlLine."Bal. Account Type"::"G/L Account":
                                    begin
                                        if GLAccount.Get(GenJnlLine."Bal. Account No.") then;
                                        if ACTION::LookupOK = PAGE.RunModal(0, GLAccount) then begin
                                            GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
                                            GLAccount.TestField("Direct Posting", true);
                                            GLAccount.TestField(Blocked, false);
                                            GenJnlLine."Bal. Account No." := GLAccount."No.";
                                        end;
                                    end;
                                GenJnlLine."Bal. Account Type"::Customer:
                                    begin
                                        if Customer.Get(GenJnlLine."Bal. Account No.") then;
                                        if ACTION::LookupOK = PAGE.RunModal(0, Customer) then begin
                                            Customer.CheckBlockedCustOnJnls(Customer, GenJnlLine."Account Type", true);
                                            GenJnlLine."Bal. Account No." := Customer."No.";
                                        end;
                                    end;
                                GenJnlLine."Bal. Account Type"::Vendor:
                                    begin
                                        if Vendor.Get(GenJnlLine."Bal. Account No.") then;
                                        if ACTION::LookupOK = PAGE.RunModal(0, Vendor) then begin
                                            Vendor.CheckBlockedVendOnJnls(Vendor, GenJnlLine."Account Type", true);
                                            GenJnlLine."Bal. Account No." := Vendor."No.";
                                        end;
                                    end;
                                GenJnlLine."Bal. Account Type"::"Bank Account":
                                    begin
                                        if BankAccount.Get(GenJnlLine."Bal. Account No.") then;
                                        if ACTION::LookupOK = PAGE.RunModal(0, BankAccount) then begin
                                            BankAccount.TestField(Blocked, false);
                                            GenJnlLine."Bal. Account No." := BankAccount."No.";
                                        end;
                                    end;
                            end;
                        end;
                    }
                    field("GenJnlLine.""Source Code"""; GenJnlLine."Source Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Section Code';
                        Editable = false;
                    }
                    field("GenJnlLine.""Posting Date"""; GenJnlLine."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Date';
                        Editable = false;
                    }
                    field(BalanceTextText; BalanceTextText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance';
                        Editable = false;
                        ToolTip = 'Specifies the balance that has accumulated in the journal on the line where the cursor is.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnAfterGetRecord()
        begin
            BalanceTextText := Format(BalanceText);
            BalanceTextTextOnFormat(BalanceTextText);
        end;

        trigger OnOpenPage()
        begin
            GenJnlLine."Posting Date" := DateEnd;
            GenJnlLine."Source Code" := SectionCode;

            if PositiveEntry then
                BalanceText := SelectStr(1, Text1003)
            else
                BalanceText := SelectStr(2, Text1003);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if GenJnlLine0.Quantity <> 0 then begin
            GenJnlLine0.Validate(Amount);
            GenJnlLine0.Insert(true);
        end;
    end;

    trigger OnPreReport()
    begin
        GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
        GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
        GenJnlBatch.Find();

        GenJnlLine.Validate("Bal. Account No.");
        GenJnlLine.TestField("Bal. Account No.");

        if DateEnd = 0D then
            Error(Text1001);
        if SectionCode = '' then
            Error(Text1002);

        GenJnlLine0 := GenJnlLine;
        GenJnlLine0."Line No." := 0;
        GenJnlLine0.Reset();
        GenJnlLine0.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine0.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine0.FindLast() then;

        GenJnlLine0.Init();
        GenJnlLine0."Line No." += 10000;
        GenJnlLine0."Account Type" := GenJnlLine."Bal. Account Type";
        GenJnlLine0."Posting Date" := DateEnd;
        GenJnlLine0."Document No." := DocumentNo;
        GenJnlLine0.Validate("Account No.", GenJnlLine."Bal. Account No.");
        GenJnlLine0.Validate("Gen. Posting Type", 0);

        GenJnlLine := GenJnlLine0;
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine0: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        LookupOK: Boolean;
        PositiveEntry: Boolean;
        DateEnd: Date;
        DocumentNo: Code[20];
        SectionCode: Code[10];
#pragma warning disable AA0074
        Text1001: Label 'Date Period must be set.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'Section Code must be set.';
#pragma warning restore AA0074
        FilterDueDate3Years: Text[30];
#pragma warning disable AA0074
        Text1003: Label 'Debit,Credit';
#pragma warning restore AA0074
        BalanceText: Text[30];
        BalanceTextText: Text[1024];

    [Scope('OnPrem')]
    procedure SetSearching(NewSectionCode: Code[10]; NewDateEnd: Date; NewPositiveEntry: Boolean; NewFilterDueDate3Years: Text[30])
    begin
        SectionCode := NewSectionCode;
        DateEnd := NewDateEnd;
        PositiveEntry := NewPositiveEntry;
        FilterDueDate3Years := NewFilterDueDate3Years;
    end;

    local procedure GenJnlLineJournalBatchNameOnAfterValidate()
    begin
        if GenJnlLine."Journal Template Name" <> '' then
            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Template Name");
    end;

    local procedure BalanceTextTextOnFormat(var Text: Text[1024])
    begin
        if PositiveEntry then
            Text := SelectStr(1, Text1003)
        else
            Text := SelectStr(2, Text1003);
    end;
}

