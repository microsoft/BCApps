// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
report 10408 "Bank Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Reconciliation/BankReconciliation.rdlc';
    Caption = 'Bank Reconciliation';

    dataset
    {
        dataitem("Posted Bank Rec. Header"; "Posted Bank Rec. Header")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_; ("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks")
            {
            }
            column(Posted_Bank_Rec__Header__Outstanding_Checks_; "Outstanding Checks")
            {
            }
            column(Statement_Balance_____Outstanding_Deposits_; "Statement Balance" + "Outstanding Deposits")
            {
            }
            column(Posted_Bank_Rec__Header__Positive_Adjustments_; "Positive Adjustments" - "Negative Bal. Adjustments")
            {
            }
            column(Posted_Bank_Rec__Header__Negative_Adjustments_; "Negative Adjustments" - "Positive Bal. Adjustments")
            {
            }
            column(Posted_Bank_Rec__Header__Outstanding_Deposits_; "Outstanding Deposits")
            {
            }
            column(G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__; "G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments"))
            {
            }
            column(G_L_Balance__Positive_Adjustments_Negative_Bal__Adjustments__Negative_Adjustments__Positive_Bal__Adjustments__; "G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments") + ("Negative Adjustments" - "Positive Bal. Adjustments"))
            {
            }
            column(G_L_Bal__Pos_Adj__Neg_Bal__Adj__Neg_Adj__Pos_Bal__Adj__Statement_Balance__Outstanding_Deposits__Outstanding_Checks__; Difference)
            {
            }
            column(Posted_Bank_Rec__Header__G_L_Balance__LCY__; "G/L Balance (LCY)")
            {
            }
            column(Posted_Bank_Rec__Header__Statement_Balance_; "Statement Balance")
            {
            }
            column(Posted_Bank_Rec__Header__Statement_Date_; "Statement Date")
            {
            }
            column(Posted_Bank_Rec__Header__Currency_Code_; "Currency Code")
            {
            }
            column(Posted_Bank_Rec__Header__Statement_No__; "Statement No.")
            {
            }
            column(Posted_Bank_Rec__Header__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Posted_Bank_Rec__Header__G_L_Balance_; "G/L Balance")
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(PrintChecks; PrintChecks)
            {
            }
            column(PrintDeposits; PrintDeposits)
            {
            }
            column(PrintAdjustments; PrintAdjustments)
            {
            }
            column(PrintOutstandingChecks; PrintOutstandingChecks)
            {
            }
            column(PrintOutstandingDeposits; PrintOutstandingDeposits)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Bank_ReconciliationCaption; Bank_ReconciliationCaptionLbl)
            {
            }
            column(Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_Caption; Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_CaptionLbl)
            {
            }
            column(Posted_Bank_Rec__Header__Outstanding_Checks_Caption; FieldCaption("Outstanding Checks"))
            {
            }
            column(Statement_Balance_____Outstanding_Deposits_Caption; Statement_Balance_____Outstanding_Deposits_CaptionLbl)
            {
            }
            column(Posted_Bank_Rec__Header__Positive_Adjustments_Caption; Posted_Bank_Rec__Header__Positive_Adjustments_CaptionLbl)
            {
            }
            column(Posted_Bank_Rec__Header__Negative_Adjustments_Caption; Posted_Bank_Rec__Header__Negative_Adjustments_CaptionLbl)
            {
            }
            column(Posted_Bank_Rec__Header__Outstanding_Deposits_Caption; FieldCaption("Outstanding Deposits"))
            {
            }
            column(G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__Caption; G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__CaptionLbl)
            {
            }
            column(G_L_Balance__Positive_Adjustments_Negative_Bal__Adjustments__Negative_Adjustments__Positive_Bal__Adjustments__Caption; G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustments_Lbl)
            {
            }
            column(G_L_Bal__Pos_Adj__Neg_Bal__Adj_Neg_Adj__Positive_Bal__Adj__Stat_Balance__Outstanding_Depos__Outstanding_Checks__Caption; G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustmen000Lbl)
            {
            }
            column(Posted_Bank_Rec__Header__G_L_Balance__LCY__Caption; FieldCaption("G/L Balance (LCY)"))
            {
            }
            column(Posted_Bank_Rec__Header__Statement_Balance_Caption; FieldCaption("Statement Balance"))
            {
            }
            column(Posted_Bank_Rec__Header__Statement_Date_Caption; FieldCaption("Statement Date"))
            {
            }
            column(Posted_Bank_Rec__Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Posted_Bank_Rec__Header__Statement_No__Caption; FieldCaption("Statement No."))
            {
            }
            column(Posted_Bank_Rec__Header__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Posted_Bank_Rec__Header__G_L_Balance_Caption; FieldCaption("G/L Balance"))
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            column(Cleared_AmountCaption; Cleared_AmountCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Bal__Account_No_Caption; Bal__Account_No_CaptionLbl)
            {
            }
            column(Bal__Account_TypeCaption; Bal__Account_TypeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Account_No_Caption; Account_No_CaptionLbl)
            {
            }
            column(Account_TypeCaption; Account_TypeCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Document_TypeCaption; Document_TypeCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            dataitem(Checks; "Posted Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.") where("Record Type" = const(Check), Cleared = const(true));
                column(Checks__Posting_Date_; "Posting Date")
                {
                }
                column(Checks__Document_Type_; "Document Type")
                {
                }
                column(Checks__Document_No__; "Document No.")
                {
                }
                column(Checks_Description; Description)
                {
                }
                column(Checks_Amount; Amount)
                {
                }
                column(Checks__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(Amount____Cleared_Amount_; Amount - "Cleared Amount")
                {
                }
                column(Checks__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Checks__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Checks__Account_No__; "Account No.")
                {
                }
                column(Checks__Account_Type_; "Account Type")
                {
                }
                column(Checks_Amount_Control1020059; Amount)
                {
                }
                column(Checks__Cleared_Amount__Control1020060; "Cleared Amount")
                {
                }
                column(Amount____Cleared_Amount__Control1020061; Amount - "Cleared Amount")
                {
                }
                column(Checks_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Checks_Statement_No_; "Statement No.")
                {
                }
                column(Checks_Record_Type; "Record Type")
                {
                }
                column(Checks_Line_No_; "Line No.")
                {
                }
                column(ChecksCaption; ChecksCaptionLbl)
                {
                }
                column(ChecksCaption_Control1020052; ChecksCaption_Control1020052Lbl)
                {
                }
                column(Total_ChecksCaption; Total_ChecksCaptionLbl)
                {
                }
            }
            dataitem(Deposits; "Posted Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.") where("Record Type" = const(Deposit), Cleared = const(true));
                column(Deposits_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020129; Amount - "Cleared Amount")
                {
                }
                column(Deposits__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(Deposits__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Deposits__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Deposits_Description; Description)
                {
                }
                column(Deposits__Account_No__; "Account No.")
                {
                }
                column(Deposits__Account_Type_; "Account Type")
                {
                }
                column(Deposits__Document_No__; "Document No.")
                {
                }
                column(Deposits__Document_Type_; "Document Type")
                {
                }
                column(Deposits__Posting_Date_; "Posting Date")
                {
                }
                column(Amount____Cleared_Amount__Control1020094; Amount - "Cleared Amount")
                {
                }
                column(Deposits__Cleared_Amount__Control1020095; "Cleared Amount")
                {
                }
                column(Deposits_Amount_Control1020096; Amount)
                {
                }
                column(Deposits_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Deposits_Statement_No_; "Statement No.")
                {
                }
                column(Deposits_Record_Type; "Record Type")
                {
                }
                column(Deposits_Line_No_; "Line No.")
                {
                }
                column(DepositsCaption; DepositsCaptionLbl)
                {
                }
                column(DepositsCaption_Control1020062; DepositsCaption_Control1020062Lbl)
                {
                }
                column(Total_DepositsCaption; Total_DepositsCaptionLbl)
                {
                }
            }
            dataitem(Adjustments; "Posted Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.") where("Record Type" = const(Adjustment), Cleared = const(true));
                column(Adjustments_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020146; Amount - "Cleared Amount")
                {
                }
                column(Adjustments__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(Adjustments__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Adjustments__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Adjustments_Description; Description)
                {
                }
                column(Adjustments__Account_No__; "Account No.")
                {
                }
                column(Adjustments__Account_Type_; "Account Type")
                {
                }
                column(Adjustments__Document_No__; "Document No.")
                {
                }
                column(Adjustments__Document_Type_; "Document Type")
                {
                }
                column(Adjustments__Posting_Date_; "Posting Date")
                {
                }
                column(Adjustments_Amount_Control1020131; Amount)
                {
                }
                column(Adjustments_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Adjustments_Statement_No_; "Statement No.")
                {
                }
                column(Adjustments_Record_Type; "Record Type")
                {
                }
                column(Adjustments_Line_No_; "Line No.")
                {
                }
                column(AdjustmentsCaption; AdjustmentsCaptionLbl)
                {
                }
                column(AdjustmentsCaption_Control1020063; AdjustmentsCaption_Control1020063Lbl)
                {
                }
                column(Total_AdjustmentsCaption; Total_AdjustmentsCaptionLbl)
                {
                }
            }
            dataitem(OutstandingChecks; "Posted Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.") where("Record Type" = const(Check), Cleared = const(false));
                column(OutstandingChecks_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020157; Amount - "Cleared Amount")
                {
                }
                column(OutstandingChecks__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(OutstandingChecks__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(OutstandingChecks__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(OutstandingChecks_Description; Description)
                {
                }
                column(OutstandingChecks__Account_No__; "Account No.")
                {
                }
                column(OutstandingChecks__Account_Type_; "Account Type")
                {
                }
                column(OutstandingChecks__Document_No__; "Document No.")
                {
                }
                column(OutstandingChecks__Document_Type_; "Document Type")
                {
                }
                column(OutstandingChecks__Posting_Date_; "Posting Date")
                {
                }
                column(OutstandingChecks_Amount_Control1020136; Amount)
                {
                }
                column(OutstandingChecks_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(OutstandingChecks_Statement_No_; "Statement No.")
                {
                }
                column(OutstandingChecks_Record_Type; "Record Type")
                {
                }
                column(OutstandingChecks_Line_No_; "Line No.")
                {
                }
                column(Outstanding_ChecksCaption; Outstanding_ChecksCaptionLbl)
                {
                }
                column(Outstanding_ChecksCaption_Control1020064; Outstanding_ChecksCaption_Control1020064Lbl)
                {
                }
                column(Total_Outstanding_ChecksCaption; Total_Outstanding_ChecksCaptionLbl)
                {
                }
            }
            dataitem(OutstandingDeposits; "Posted Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Record Type", "Line No.") where("Record Type" = const(Deposit), Cleared = const(false));
                column(OutstandingDeposits_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020168; Amount - "Cleared Amount")
                {
                }
                column(OutstandingDeposits__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(OutstandingDeposits__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(OutstandingDeposits__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(OutstandingDeposits_Description; Description)
                {
                }
                column(OutstandingDeposits__Account_No__; "Account No.")
                {
                }
                column(OutstandingDeposits__Account_Type_; "Account Type")
                {
                }
                column(OutstandingDeposits__Document_No__; "Document No.")
                {
                }
                column(OutstandingDeposits__Document_Type_; "Document Type")
                {
                }
                column(OutstandingDeposits__Posting_Date_; "Posting Date")
                {
                }
                column(OutstandingDeposits_Amount_Control1020187; Amount)
                {
                }
                column(OutstandingDeposits_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(OutstandingDeposits_Statement_No_; "Statement No.")
                {
                }
                column(OutstandingDeposits_Record_Type; "Record Type")
                {
                }
                column(OutstandingDeposits_Line_No_; "Line No.")
                {
                }
                column(Outstanding_DepositsCaption; Outstanding_DepositsCaptionLbl)
                {
                }
                column(Outstanding_DepositsCaption_Control1020069; Outstanding_DepositsCaption_Control1020069Lbl)
                {
                }
                column(Total_Outstanding_DepositsCaption; Total_Outstanding_DepositsCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                SetupRecord();

                Difference :=
                  ("G/L Balance" +
                   ("Positive Adjustments" - "Negative Bal. Adjustments") +
                   ("Negative Adjustments" - "Positive Bal. Adjustments")) -
                  (("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks");
            end;

            trigger OnPostDataItem()
            begin
                if not CurrReport.Preview then
                    UpdateBankRecPrinted.Run("Posted Bank Rec. Header");
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
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print details';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';

                        trigger OnValidate()
                        begin
                            if PrintDetails then begin
                                PrintChecks := true;
                                PrintDeposits := true;
                                PrintAdjustments := true;
                                PrintOutstandingChecks := true;
                                PrintOutstandingDeposits := true;
                            end;
                            PrintDetailsOnAfterValidate();
                        end;
                    }
                    field(PrintChecks; PrintChecks)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print checks';
                        Editable = PrintChecksEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for checks.';
                    }
                    field(PrintDeposits; PrintDeposits)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print deposits';
                        Editable = PrintDepositsEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for deposits.';
                    }
                    field(PrintAdj; PrintAdjustments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print adjustments';
                        Editable = PrintAdjEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for adjustments.';
                    }
                    field(PrintOutChecks; PrintOutstandingChecks)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print outstanding checks';
                        Editable = PrintOutChecksEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for outstanding checks.';
                    }
                    field(PrintOutDeposits; PrintOutstandingDeposits)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print outstanding deposits';
                        Editable = PrintOutDepositsEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for outstanding deposits.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintChecksEditable := true;
            PrintDepositsEditable := true;
            PrintAdjEditable := true;
            PrintOutDepositsEditable := true;
            PrintOutChecksEditable := true;
        end;

        trigger OnOpenPage()
        begin
            SetupRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        UpdateBankRecPrinted: Codeunit "BankRec-Printed";
        PrintDetails: Boolean;
        PrintChecks: Boolean;
        PrintDeposits: Boolean;
        PrintAdjustments: Boolean;
        PrintOutstandingChecks: Boolean;
        PrintOutstandingDeposits: Boolean;
        Difference: Decimal;
        PrintOutChecksEditable: Boolean;
        PrintOutDepositsEditable: Boolean;
        PrintAdjEditable: Boolean;
        PrintDepositsEditable: Boolean;
        PrintChecksEditable: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bank_ReconciliationCaptionLbl: Label 'Bank Reconciliation';
        Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_CaptionLbl: Label 'Ending Balance';
        Statement_Balance_____Outstanding_Deposits_CaptionLbl: Label 'Subtotal';
        Posted_Bank_Rec__Header__Positive_Adjustments_CaptionLbl: Label 'Positive Adjustments';
        Posted_Bank_Rec__Header__Negative_Adjustments_CaptionLbl: Label 'Negative Adjustments';
        G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__CaptionLbl: Label 'Subtotal';
        G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustments_Lbl: Label 'Ending G/L Balance';
        G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustmen000Lbl: Label 'Difference';
        DifferenceCaptionLbl: Label 'Difference';
        Cleared_AmountCaptionLbl: Label 'Cleared Amount';
        AmountCaptionLbl: Label 'Amount';
        Bal__Account_No_CaptionLbl: Label 'Bal. Account No.';
        Bal__Account_TypeCaptionLbl: Label 'Bal. Account Type';
        DescriptionCaptionLbl: Label 'Description';
        Account_No_CaptionLbl: Label 'Account No.';
        Account_TypeCaptionLbl: Label 'Account Type';
        Document_No_CaptionLbl: Label 'Document No.';
        Document_TypeCaptionLbl: Label 'Document Type';
        Posting_DateCaptionLbl: Label 'Posting Date';
        ChecksCaptionLbl: Label 'Checks';
        ChecksCaption_Control1020052Lbl: Label 'Checks';
        Total_ChecksCaptionLbl: Label 'Total Checks';
        DepositsCaptionLbl: Label 'Deposits';
        DepositsCaption_Control1020062Lbl: Label 'Deposits';
        Total_DepositsCaptionLbl: Label 'Total Deposits';
        AdjustmentsCaptionLbl: Label 'Adjustments';
        AdjustmentsCaption_Control1020063Lbl: Label 'Adjustments';
        Total_AdjustmentsCaptionLbl: Label 'Total Adjustments';
        Outstanding_ChecksCaptionLbl: Label 'Outstanding Checks';
        Outstanding_ChecksCaption_Control1020064Lbl: Label 'Outstanding Checks';
        Total_Outstanding_ChecksCaptionLbl: Label 'Total Outstanding Checks';
        Outstanding_DepositsCaptionLbl: Label 'Outstanding Deposits';
        Outstanding_DepositsCaption_Control1020069Lbl: Label 'Outstanding Deposits';
        Total_Outstanding_DepositsCaptionLbl: Label 'Total Outstanding Deposits';

    procedure SetupRecord()
    begin
        "Posted Bank Rec. Header".SetRange("Date Filter", "Posted Bank Rec. Header"."Statement Date");
        "Posted Bank Rec. Header".CalcFields("Positive Adjustments", "Positive Bal. Adjustments", "Negative Adjustments", "Negative Bal. Adjustments", "Outstanding Deposits", "Outstanding Checks");
    end;

    procedure SetupRequestForm()
    begin
        PageSetupRequestForm();
    end;

    local procedure PrintDetailsOnAfterValidate()
    begin
        SetupRequestForm();
    end;

    local procedure PageSetupRequestForm()
    begin
        if not PrintDetails then begin
            PrintChecks := false;
            PrintDeposits := false;
            PrintAdjustments := false;
            PrintOutstandingChecks := false;
            PrintOutstandingDeposits := false;
        end;

        PrintOutChecksEditable := PrintDetails;
        PrintOutDepositsEditable := PrintDetails;
        PrintAdjEditable := PrintDetails;
        PrintDepositsEditable := PrintDetails;
        PrintChecksEditable := PrintDetails;
    end;
}
