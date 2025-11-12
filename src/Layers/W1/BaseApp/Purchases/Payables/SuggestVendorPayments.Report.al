// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Utilities;

report 393 "Suggest Vendor Payments"
{
    Caption = 'Suggest Vendor Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting(Blocked) where(Blocked = filter(= " "));
            RequestFilterFields = "No.", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                Clear(VendorBalance);
                CalcFields("Balance (LCY)");
                VendorBalance := "Balance (LCY)";

                if StopPayments then
                    CurrReport.Break();
                Window.Update(1, "No.");
                if IncludeVendor(Vendor, VendorBalance) then begin
                    GetVendLedgEntries(true, false);
                    GetVendLedgEntries(false, false);
                    CheckAmounts(false);
                    ClearNegative();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if UsePriority and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    SetCurrentKey(Priority);
                    SetRange(Priority, 0);
                    if FindSet() then
                        repeat
                            Clear(VendorBalance);
                            CalcFields("Balance (LCY)");
                            VendorBalance := "Balance (LCY)";
                            if IncludeVendor(Vendor, VendorBalance) then begin
                                Window.Update(1, "No.");
                                GetVendLedgEntries(true, false);
                                GetVendLedgEntries(false, false);
                                CheckAmounts(false);
                                ClearNegative();
                            end;
                        until (Next() = 0) or StopPayments;
                end;

                if UsePaymentDisc and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    Window2.Open(Text007);
                    if FindSet() then
                        repeat
                            Clear(VendorBalance);
                            CalcFields("Balance (LCY)");
                            VendorBalance := "Balance (LCY)";
                            Window2.Update(1, "No.");
                            TempPayableVendorLedgerEntry.SetRange("Vendor No.", "No.");
                            if IncludeVendor(Vendor, VendorBalance) then begin
                                GetVendLedgEntries(true, true);
                                GetVendLedgEntries(false, true);
                                CheckAmounts(true);
                                ClearNegative();
                            end;
                        until (Next() = 0) or StopPayments;
                    Window2.Close();
                end else
                    if FindSet() then
                        repeat
                            ClearNegative();
                        until Next() = 0;

                DimSetEntry.LockTable();
                GenJnlLine.LockTable();
                GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindLast() then begin
                    LastLineNo := GenJnlLine."Line No.";
                    GenJnlLine.Init();
                end;

                OnPostDataItemOnBeforeMakeGenJnlLines(GenJnlLine, GenJnlBatch, TempVendorLedgerEntry);
                Window2.Open(Text008);

                TempPayableVendorLedgerEntry.Reset();
                TempPayableVendorLedgerEntry.SetRange(Priority, 1, 2147483647);
                MakeGenJnlLines();
                TempPayableVendorLedgerEntry.Reset();
                TempPayableVendorLedgerEntry.SetRange(Priority, 0);
                MakeGenJnlLines();
                TempPayableVendorLedgerEntry.Reset();
                TempPayableVendorLedgerEntry.DeleteAll();

                OnAfterPostDataItem(GenJnlBatch, GenJnlLine2);

                Window2.Close();
                Window.Close();
                ShowMessage(MessageText);
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if LastDueDateToPayReq = 0D then
                    Error(Text000);
                if (PostingDate = 0D) and (not UseDueDateAsPostingDate) then
                    Error(Text001);

                BankPmtType := GenJnlLine2."Bank Payment Type";
                BalAccType := GenJnlLine2."Bal. Account Type";
                BalAccNo := GenJnlLine2."Bal. Account No.";
                GenJnlLineInserted := false;
                SeveralCurrencies := false;
                MessageText := '';

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::" ") or
                    SummarizePerVend) and
                   (NextDocNo = '')
                then
                    Error(Text002);

                if ((BankPmtType = GenJnlLine2."Bank Payment Type"::"Manual Check") and
                    not SummarizePerVend and
                    not DocNoPerLine)
                then
                    Error(Text017, GenJnlLine2.FieldCaption("Bank Payment Type"), Format(GenJnlLine2."Bank Payment Type"::"Manual Check"));

                if UsePaymentDisc and (LastDueDateToPayReq < WorkDate()) then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text003, WorkDate()), true) then
                        Error(Text005);

                Vend2.CopyFilters(Vendor);

                OriginalAmtAvailable := AmountAvailable;
                if UsePriority then begin
                    SetCurrentKey(Priority);
                    SetRange(Priority, 1, 2147483647);
                    UsePriority := true;
                end;
                Window.Open(Text006);

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Suggest Vendor Payments");
                SummarizePerDim := (not SelectedDim.IsEmpty) and SummarizePerVend;

                NextEntryNo := 1;
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
                    group("Find Payments")
                    {
                        Caption = 'Find Payments';
                        field(LastPaymentDate; LastDueDateToPayReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Payment Date';
                            ToolTip = 'Specifies the latest payment date that can appear on the vendor ledger entries to be included in the batch job. Only entries that have a due date or a payment discount date before or on this date will be included. If the payment date is earlier than the system date, a warning will be displayed.';
                        }
                        field(FindPaymentDiscounts; UsePaymentDisc)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Find Payment Discounts';
                            Importance = Additional;
                            MultiLine = true;
                            ToolTip = 'Specifies if you want the batch job to include vendor ledger entries for which you can receive a payment discount.';
                        }
                        field(UseVendorPriority; UsePriority)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Use Vendor Priority';
                            Importance = Additional;
                            ToolTip = 'Specifies if the Priority field on the vendor cards will determine in which order vendor entries are suggested for payment by the batch job. The batch job always prioritizes vendors for payment suggestions if you specify an available amount in the Available Amount (LCY) field.';

                            trigger OnValidate()
                            begin
                                if not UsePriority and (AmountAvailable <> 0) then
                                    Error(Text011);
                            end;
                        }
                        field("Available Amount (LCY)"; AmountAvailable)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Available Amount (LCY)';
                            Importance = Additional;
                            ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments. The batch job will then create a payment suggestion on the basis of this amount and the Use Vendor Priority check box. It will only include vendor entries that can be paid fully.';

                            trigger OnValidate()
                            begin
                                if AmountAvailable <> 0 then
                                    UsePriority := true;
                            end;
                        }
                        field(SkipExportedPayments; SkipExportedPayments)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Exported Payments';
                            Importance = Additional;
                            ToolTip = 'Specifies if you do not want the batch job to insert payment journal lines for documents for which payments have already been exported to a bank file.';
                        }
                        field(CheckOtherJournalBatches; CheckOtherJournalBatches)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Check Other Journal Batches';
                            ToolTip = 'Specifies whether to exclude payments that are already included in another journal batch from new suggested payments. This helps avoid duplicate payments.';
                        }
                    }
                    group("Summarize Results")
                    {
                        Caption = 'Summarize Results';
                        field(SummarizePerVendor; SummarizePerVend)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Summarize per Vendor';
                            ToolTip = 'Specifies if you want the batch job to make one line per vendor for each currency in which the vendor has ledger entries. If, for example, a vendor uses two currencies, the batch job will create two lines in the payment journal for this vendor. Please note that this option will consider all open entries. If you are using Remit Addresses the batch job will create a line for each remit address. The batch job then uses the Applies-to ID field when the journal lines are posted to apply the lines to vendor ledger entries. If you do not select this check box, then the batch job will make one line per invoice.';

                            trigger OnValidate()
                            begin
                                if SummarizePerVend and UseDueDateAsPostingDate then
                                    Error(PmtDiscUnavailableErr);
                            end;
                        }
                        field(SummarizePerDimText; SummarizePerDimText)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'By Dimension';
                            Editable = false;
                            Enabled = SummarizePerDimTextEnable;
                            Importance = Additional;
                            ToolTip = 'Specifies the dimensions that you want the batch job to consider.';

                            trigger OnAssistEdit()
                            var
                                DimSelectionBuf: Record "Dimension Selection Buffer";
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Suggest Vendor Payments", SummarizePerDimText);
                            end;
                        }
                    }
                    group("Fill in Journal Lines")
                    {
                        Caption = 'Fill in Journal Lines';
                        field(PostingDate; PostingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posting Date';
                            Editable = UseDueDateAsPostingDate = false;
                            Importance = Promoted;
                            ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';

                            trigger OnValidate()
                            begin
                                ValidatePostingDate();
                            end;
                        }
                        field(UseDueDateAsPostingDate; UseDueDateAsPostingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Calculate Posting Date from Applies-to-Doc. Due Date';
                            Importance = Additional;
                            ToolTip = 'Specifies if the due date on the purchase invoice will be used as a basis to calculate the payment posting date.';

                            trigger OnValidate()
                            begin
                                if UseDueDateAsPostingDate and SummarizePerVend then
                                    Error(PmtDiscUnavailableErr);
                                if not UseDueDateAsPostingDate then
                                    Clear(DueDateOffset);
                            end;
                        }
                        field(DueDateOffset; DueDateOffset)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Applies-to-Doc. Due Date Offset';
                            Editable = UseDueDateAsPostingDate;
                            Enabled = UseDueDateAsPostingDate;
                            Importance = Additional;
                            ToolTip = 'Specifies a period of time that will separate the payment posting date from the due date on the invoice. Example 1: To pay the invoice on the Friday in the week of the due date, enter CW-2D (current week minus two days). Example 2: To pay the invoice two days before the due date, enter -2D (minus two days).';
                        }
                        field(StartingDocumentNo; NextDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Document No.';
                            ToolTip = 'Specifies the next available number in the number series for the journal batch that is linked to the payment journal. When you run the batch job, this is the document number that appears on the first payment journal line. You can also fill in this field manually.';

                            trigger OnValidate()
                            begin
                                if NextDocNo <> '' then
                                    if IncStr(NextDocNo) = '' then
                                        Error(StartingDocumentNoErr);
                            end;
                        }
                        field(NewDocNoPerLine; DocNoPerLine)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'New Doc. No. per Line';
                            Importance = Additional;
                            ToolTip = 'Specifies if you want the batch job to fill in the payment journal lines with consecutive document numbers, starting with the document number specified in the Starting Document No. field.';

                            trigger OnValidate()
                            begin
                                if not UsePriority and (AmountAvailable <> 0) then
                                    Error(Text013);
                            end;
                        }
                        field(BalAccountType; GenJnlLine2."Bal. Account Type")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account Type';
                            Importance = Additional;
                            ToolTip = 'Specifies the balancing account type that payments on the payment journal are posted to.';

                            trigger OnValidate()
                            begin
                                if not (GenJnlLine2."Bal. Account Type" in
                                    [GenJnlLine2."Bal. Account Type"::"Bank Account", GenJnlLine2."Bal. Account Type"::"G/L Account"])
                                then
                                    error(
                                        BalAccountTypeErr,
                                        GenJnlLine2."Bal. Account Type"::"Bank Account", GenJnlLine2."Bal. Account Type"::"G/L Account");
                                GenJnlLine2."Bal. Account No." := '';
                            end;
                        }
                        field(BalAccountNo; GenJnlLine2."Bal. Account No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account No.';
                            Importance = Additional;
                            ToolTip = 'Specifies the balancing account number that payments on the payment journal are posted to.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                case GenJnlLine2."Bal. Account Type" of
                                    GenJnlLine2."Bal. Account Type"::"G/L Account":
                                        if PAGE.RunModal(0, GLAcc) = ACTION::LookupOK then
                                            GenJnlLine2."Bal. Account No." := GLAcc."No.";
                                    GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor:
                                        Error(Text009, GenJnlLine2.FieldCaption("Bal. Account Type"));
                                    GenJnlLine2."Bal. Account Type"::"Bank Account":
                                        if PAGE.RunModal(0, BankAcc) = ACTION::LookupOK then
                                            GenJnlLine2."Bal. Account No." := BankAcc."No.";
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if GenJnlLine2."Bal. Account No." <> '' then
                                    case GenJnlLine2."Bal. Account Type" of
                                        GenJnlLine2."Bal. Account Type"::"G/L Account":
                                            GLAcc.Get(GenJnlLine2."Bal. Account No.");
                                        GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor:
                                            Error(Text009, GenJnlLine2.FieldCaption("Bal. Account Type"));
                                        GenJnlLine2."Bal. Account Type"::"Bank Account":
                                            BankAcc.Get(GenJnlLine2."Bal. Account No.");
                                    end;
                            end;
                        }
                        field(BankPaymentType; GenJnlLine2."Bank Payment Type")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bank Payment Type';
                            Importance = Additional;
                            ToolTip = 'Specifies the check type to be used, if you use Bank Account as the balancing account type.';

                            trigger OnValidate()
                            begin
                                if (GenJnlLine2."Bal. Account Type" <> GenJnlLine2."Bal. Account Type"::"Bank Account") and
                                   (GenJnlLine2."Bank Payment Type".AsInteger() > 0)
                                then
                                    Error(
                                      Text010,
                                      GenJnlLine2.FieldCaption("Bank Payment Type"),
                                      GenJnlLine2.FieldCaption("Bal. Account Type"));
                            end;
                        }
                    }
                    group(Control22)
                    {
                        ShowCaption = false;
                        Visible = ServiceFieldsVisibiity;
                        field(JournalTemplateName; JnlTemplateName)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            ToolTip = 'Specifies the journal template name of the payment journal.';
                            Visible = ServiceFieldsVisibiity;
                        }
                        field(JournalBatchName; JnlBatchName)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            ToolTip = 'Specifies the journal batch name of the payment journal.';
                            Visible = ServiceFieldsVisibiity;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SummarizePerDimTextEnable := true;
            SkipExportedPayments := true;
            ServiceFieldsVisibiity := false;
        end;

        trigger OnOpenPage()
        begin
            if LastDueDateToPayReq = 0D then
                LastDueDateToPayReq := WorkDate();
            if PostingDate = 0D then
                PostingDate := WorkDate();
            ValidatePostingDate();
            SetDefaults();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            CheckOtherJournalBatches := true;
    end;

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Commit();
        if not TempVendorLedgerEntry.IsEmpty() then
            if ConfirmManagement.GetResponse(Text024, true) then
                PAGE.RunModal(0, TempVendorLedgerEntry);

        if CheckOtherJournalBatches then
            if not TempErrorMessage.IsEmpty() then
                if ConfirmManagement.GetResponse(ReviewNotSuggestedLinesQst, true) then
                    TempErrorMessage.ShowErrorMessages(false);
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        TempVendorLedgerEntry.DeleteAll();
        ShowPostingDateWarning := false;
    end;

    protected var
        GenJnlLine2: Record "Gen. Journal Line";
        LastDueDateToPayReq: Date;
        UsePaymentDisc: Boolean;
        UsePriority: Boolean;
        AmountAvailable: Decimal;
        SkipExportedPayments: Boolean;
        CheckOtherJournalBatches: Boolean;
        SummarizePerVend: Boolean;
        SummarizePerDimText: Text[250];
        PostingDate: Date;
        UseDueDateAsPostingDate: Boolean;
        DueDateOffset: DateFormula;
        NextDocNo: Code[20];
        DocNoPerLine: Boolean;

    var
        Vend2: Record Vendor;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DimSetEntry: Record "Dimension Set Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLAcc: Record "G/L Account";
        BankAcc: Record "Bank Account";
        TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary;
        CompanyInformation: Record "Company Information";
        TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary;
        TempOldVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary;
        SelectedDim: Record "Selected Dimension";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        Window2: Dialog;
        OriginalAmtAvailable: Decimal;
        SummarizePerDim: Boolean;
        LastLineNo: Integer;
        NextEntryNo: Integer;
        StopPayments: Boolean;
        BankPmtType: Enum "Bank Payment Type";
        BalAccType: Enum "Gen. Journal Account Type";
        BalAccNo: Code[20];
        MessageText: Text;
        GenJnlLineInserted: Boolean;
        SeveralCurrencies: Boolean;
        SummarizePerDimTextEnable: Boolean;
        ShowPostingDateWarning: Boolean;
        VendorBalance: Decimal;
        ServiceFieldsVisibiity: Boolean;
        JnlTemplateName: Code[10];
        JnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'In the Last Payment Date field, specify the last possible date that payments must be made.';
        Text001: Label 'In the Posting Date field, specify the date that will be used as the posting date for the journal entries.';
        Text002: Label 'In the Starting Document No. field, specify the first document number to be used.';
        Text003: Label 'The payment date is earlier than %1.\\Do you still want to run the batch job?', Comment = '%1 is a date';
        Text005: Label 'The batch job was interrupted.';
#pragma warning disable AA0470
        Text006: Label 'Processing vendors     #1##########';
        Text007: Label 'Processing vendors for payment discounts #1##########';
        Text008: Label 'Inserting payment journal lines #1##########';
        Text009: Label '%1 must be G/L Account or Bank Account.';
        Text010: Label '%1 must be filled only when %2 is Bank Account.';
#pragma warning restore AA0470
        Text011: Label 'Use Vendor Priority must be activated when the value in the Amount Available field is not 0.';
        Text013: Label 'Use Vendor Priority must be activated when the value in the Amount Available Amount (LCY) field is not 0.';
#pragma warning disable AA0470
        Text017: Label 'If %1 = %2 and you have not selected the Summarize per Vendor field,\ then you must select the New Doc. No. per Line.', Comment = 'If Bank Payment Type = Computer Check and you have not selected the Summarize per Vendor field,\ then you must select the New Doc. No. per Line.';
        Text020: Label 'You have only created suggested vendor payment lines for the %1 %2.\ However, there are other open vendor ledger entries in currencies other than %2.\\', Comment = 'You have only created suggested vendor payment lines for the Currency Code EUR.\ However, there are other open vendor ledger entries in currencies other than EUR.';
        Text021: Label 'You have only created suggested vendor payment lines for the %1 %2.\ There are no other open vendor ledger entries in other currencies.\\', Comment = 'You have only created suggested vendor payment lines for the Currency Code EUR\ There are no other open vendor ledger entries in other currencies.\\';
#pragma warning restore AA0470
        Text022: Label 'You have created suggested vendor payment lines for all currencies.\\';
        Text024: Label 'There are one or more entries for which no payment suggestions have been made because the posting dates of the entries are later than the requested posting date. Do you want to see the entries?';
#pragma warning disable AA0470
        Text025: Label 'The %1 with the number %2 has a %3 with the number %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        BalAccountTypeErr: label 'Balancing account must be %1 or %2.';
#pragma warning restore AA0470
        ReplacePostingDateMsg: Label 'For one or more entries, the requested posting date is before the work date.\\These posting dates will use the work date.';
        PmtDiscUnavailableErr: Label 'You cannot use Summarize per Vendor together with Calculate Posting Date from Applies-to-Doc. Due Date, because the resulting posting date might not match the due date.';
        MessageToRecipientMsg: Label 'Payment of %1 %2 ', Comment = '%1 document type, %2 Document No.';
        StartingDocumentNoErr: Label 'The value in the Starting Document No. field must have a number so that we can assign the next number in the series.';
        ReviewNotSuggestedLinesQst: Label 'There are payments in other journal batches that are not suggested here. This helps avoid duplicate payments. To add them to this batch, remove the payment from the other batch, and then suggest payments again.\\Do you want to review the payments from the other journal batches now?';
#pragma warning disable AA0470
        NotSuggestedPaymentInfoTxt: Label 'There are payments in %1 %2, %3 %4, %5 %6', Comment = 'There are payments in Journal Template Name PAYMENT, Journal Batch Name GENERAL, Applies-to Doc. No. 101321';
#pragma warning restore AA0470

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGenJnlLine;
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if not GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            GenJnlBatch.Get(JnlTemplateName, JnlBatchName)
        else begin
            JnlTemplateName := GenJnlLine."Journal Template Name";
            JnlBatchName := GenJnlLine."Journal Batch Name";
        end;
        if GenJnlBatch."No. Series" = '' then
            NextDocNo := ''
        else
            NextDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", PostingDate);
    end;

    procedure InitializeRequest(LastPmtDate: Date; FindPmtDisc: Boolean; NewAvailableAmount: Decimal; NewSkipExportedPayments: Boolean; NewPostingDate: Date; NewStartDocNo: Code[20]; NewSummarizePerVend: Boolean; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; BankPmtType: Enum "Bank Payment Type")
    begin
        LastDueDateToPayReq := LastPmtDate;
        UsePaymentDisc := FindPmtDisc;
        AmountAvailable := NewAvailableAmount;
        SkipExportedPayments := NewSkipExportedPayments;
        PostingDate := NewPostingDate;
        NextDocNo := NewStartDocNo;
        SummarizePerVend := NewSummarizePerVend;
        GenJnlLine2."Bal. Account Type" := BalAccType;
        GenJnlLine2."Bal. Account No." := BalAccNo;
        GenJnlLine2."Bank Payment Type" := BankPmtType;
    end;

    local procedure GetVendLedgEntries(Positive: Boolean; Future: Boolean)
    var
        IsHandled: Boolean;
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange(Positive, Positive);
        VendLedgEntry.SetRange("Applies-to ID", '');
        if Future then begin
            VendLedgEntry.SetRange("Due Date", LastDueDateToPayReq + 1, DMY2Date(31, 12, 9999));
            VendLedgEntry.SetRange("Pmt. Discount Date", PostingDate, LastDueDateToPayReq);
            VendLedgEntry.SetFilter("Remaining Pmt. Disc. Possible", '<>0');
        end else
            VendLedgEntry.SetRange("Due Date", 0D, LastDueDateToPayReq);
        if SkipExportedPayments then
            VendLedgEntry.SetRange("Exported to Payment File", false);
        VendLedgEntry.SetRange("On Hold", '');
        VendLedgEntry.SetFilter("Currency Code", Vendor.GetFilter("Currency Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vendor.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vendor.GetFilter("Global Dimension 2 Filter"));
        OnGetVendLedgEntriesOnAfterVendLedgEntrySetFilters(VendLedgEntry, Vendor, PostingDate, LastDueDateToPayReq, Positive, Future);

        if VendLedgEntry.FindSet() then
            repeat
                IsHandled := false;
                OnGetVendLedgEntriesOnBeforeLoop(VendLedgEntry, PostingDate, LastDueDateToPayReq, Future, IsHandled);
                if not IsHandled then begin
                    SaveAmount();
                    if VendLedgEntry."Accepted Pmt. Disc. Tolerance" or (VendLedgEntry."Accepted Payment Tolerance" <> 0) then begin
                        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        VendLedgEntry."Accepted Payment Tolerance" := 0;
                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                    end;
                end;
            until VendLedgEntry.Next() = 0;
        OnAfterGetVendLedgEntries(VendLedgEntry, Vendor, PostingDate, LastDueDateToPayReq, UsePriority, UseDueDateAsPostingDate, DueDateOffset, Positive, Future, TempPayableVendorLedgerEntry, NextEntryNo, SkipExportedPayments);
    end;

    local procedure IncludeVendor(Vendor: Record Vendor; VendorBalance: Decimal) Result: Boolean
    begin
        Result := VendorBalance > 0;

        OnAfterIncludeVendor(Vendor, VendorBalance, Result);
    end;

    local procedure SaveAmount()
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        GenJnlLine.Init();
        SetPostingDate(GenJnlLine, GetVendorLedgerEntryDueDate(VendLedgEntry."Entry No."), PostingDate);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        Vend2.Get(VendLedgEntry."Vendor No.");
        Vend2.CheckBlockedVendOnJnls(Vend2, GenJnlLine."Document Type", false);
        GenJnlLine.Description := Vend2.Name;
        GenJnlLine."Salespers./Purch. Code" := Vend2."Purchaser Code";
        GenJnlLine."Payment Terms Code" := Vend2."Payment Terms Code";
        GenJnlLine.Validate("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        GenJnlLine.Validate("Sell-to/Buy-from No.", GenJnlLine."Account No.");
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        GenJnlLine.Validate("Payment Terms Code");
        VendLedgEntry.CalcFields("Remaining Amount");
        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) then
            GenJnlLine.Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date"))
        else
            GenJnlLine.Amount := -VendLedgEntry."Remaining Amount";
        GenJnlLine.Validate(Amount);

        if UsePriority then
            TempPayableVendorLedgerEntry.Priority := Vendor.Priority
        else
            TempPayableVendorLedgerEntry.Priority := 0;
        TempPayableVendorLedgerEntry."Vendor No." := VendLedgEntry."Vendor No.";
        TempPayableVendorLedgerEntry."Entry No." := NextEntryNo;
        TempPayableVendorLedgerEntry."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
        TempPayableVendorLedgerEntry.Amount := GenJnlLine.Amount;
        TempPayableVendorLedgerEntry."Amount (LCY)" := GenJnlLine."Amount (LCY)";
        TempPayableVendorLedgerEntry.Positive := (TempPayableVendorLedgerEntry.Amount > 0);
        TempPayableVendorLedgerEntry.Future := (VendLedgEntry."Due Date" > LastDueDateToPayReq);
        TempPayableVendorLedgerEntry."Currency Code" := VendLedgEntry."Currency Code";
        TempPayableVendorLedgerEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
        OnAfterSaveAmount(GenJnlLine, TempPayableVendorLedgerEntry, VendLedgEntry);
    end;

    local procedure CheckAmounts(Future: Boolean)
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAmounts(TempPayableVendorLedgerEntry, OriginalAmtAvailable, AmountAvailable, StopPayments, Future, Vendor, IsHandled);
        if IsHandled then
            exit;

        TempPayableVendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        TempPayableVendorLedgerEntry.SetRange(Future, Future);

        PrevCurrency := '';
        CurrencyBalance := 0;
        if TempPayableVendorLedgerEntry.FindSet() then begin
            repeat
                if TempPayableVendorLedgerEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance > 0 then
                        AmountAvailable := AmountAvailable - CurrencyBalance;
                    CurrencyBalance := 0;
                    PrevCurrency := TempPayableVendorLedgerEntry."Currency Code";
                end;
                if (OriginalAmtAvailable = 0) or
                   (AmountAvailable >= CurrencyBalance + TempPayableVendorLedgerEntry."Amount (LCY)")
                then
                    CurrencyBalance := CurrencyBalance + TempPayableVendorLedgerEntry."Amount (LCY)"
                else
                    TempPayableVendorLedgerEntry.Delete();
            until TempPayableVendorLedgerEntry.Next() = 0;
            if OriginalAmtAvailable > 0 then
                AmountAvailable := AmountAvailable - CurrencyBalance;
            if (OriginalAmtAvailable > 0) and (AmountAvailable <= 0) then
                StopPayments := true;
        end;
        TempPayableVendorLedgerEntry.Reset();
    end;

    local procedure MakeGenJnlLines()
    var
        GenJnlLine1: Record "Gen. Journal Line";
        DimBuf: Record "Dimension Buffer";
        RemainingAmtAvailable: Decimal;
        HandledEntry: Boolean;
    begin
        TempVendorPaymentBuffer.Reset();
        TempVendorPaymentBuffer.DeleteAll();

        if BalAccType = BalAccType::"Bank Account" then begin
            CheckCurrencies(BalAccType, BalAccNo, TempPayableVendorLedgerEntry);
            SetBankAccCurrencyFilter(BalAccType, BalAccNo, TempPayableVendorLedgerEntry);
        end;

        if OriginalAmtAvailable <> 0 then begin
            RemainingAmtAvailable := OriginalAmtAvailable;
            RemovePaymentsAboveLimit(TempPayableVendorLedgerEntry, RemainingAmtAvailable);
        end;
        if TempPayableVendorLedgerEntry.Find('-') then
            repeat
                TempPayableVendorLedgerEntry.SetRange("Vendor No.", TempPayableVendorLedgerEntry."Vendor No.");
                TempPayableVendorLedgerEntry.Find('-');
                repeat
                    VendLedgEntry.Get(TempPayableVendorLedgerEntry."Vendor Ledg. Entry No.");
                    SetPostingDate(GenJnlLine1, GetVendorLedgerEntryDueDate(VendLedgEntry."Entry No."), PostingDate);
                    HandledEntry := VendLedgEntry."Posting Date" <= GenJnlLine1."Posting Date";
                    OnBeforeHandledVendLedgEntry(VendLedgEntry, GenJnlLine1, HandledEntry);
                    if HandledEntry then begin
                        TempVendorPaymentBuffer."Vendor No." := VendLedgEntry."Vendor No.";
                        TempVendorPaymentBuffer."Currency Code" := VendLedgEntry."Currency Code";
                        TempVendorPaymentBuffer."Payment Method Code" := VendLedgEntry."Payment Method Code";

                        TempVendorPaymentBuffer.CopyFieldsFromVendorLedgerEntry(VendLedgEntry);
                        OnUpdateVendorPaymentBufferFromVendorLedgerEntry(TempVendorPaymentBuffer, VendLedgEntry);
                        SetTempPaymentBufferDims(DimBuf);

                        VendLedgEntry.CalcFields("Remaining Amount");

                        if IsNotAppliedEntry(GenJnlLine, VendLedgEntry) then begin
                            OnMakeGenJnlLinesOnBeforeUpdateVendorPaymentBufferAmounts(TempVendorPaymentBuffer, VendLedgEntry, SummarizePerVend);
                            if SummarizePerVend then begin
                                TempVendorPaymentBuffer."Vendor Ledg. Entry No." := 0;
                                TempVendorPaymentBuffer."Applies-to Ext. Doc. No." := '';
                                if TempVendorPaymentBuffer.Find() then begin
                                    TempVendorPaymentBuffer.Amount := TempVendorPaymentBuffer.Amount + TempPayableVendorLedgerEntry.Amount;
                                    TempVendorPaymentBuffer.Validate("Vendor Ledg. Entry Doc. Type", VendLedgEntry."Document Type");
                                    OnMakeGenJnlLinesOnBeforeVendorPaymentBufferModify(TempVendorPaymentBuffer, VendLedgEntry, TempPayableVendorLedgerEntry);
                                    TempVendorPaymentBuffer.Modify();
                                end else begin
                                    TempVendorPaymentBuffer."Document No." := NextDocNo;
                                    if DocNoPerLine then
                                        RunIncrementDocumentNo(true);
                                    TempVendorPaymentBuffer.Amount := TempPayableVendorLedgerEntry.Amount;
                                    TempVendorPaymentBuffer.Validate("Vendor Ledg. Entry Doc. Type", VendLedgEntry."Document Type");
                                    Window2.Update(1, VendLedgEntry."Vendor No.");
                                    OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsert(TempVendorPaymentBuffer, VendLedgEntry, TempPayableVendorLedgerEntry);
                                    TempVendorPaymentBuffer.Insert();
                                end;
                                VendLedgEntry."Applies-to ID" := TempVendorPaymentBuffer."Document No.";
                            end else begin
                                TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type" := VendLedgEntry."Document Type";
                                TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. No." := VendLedgEntry."Document No.";
                                TempVendorPaymentBuffer."Ledg. Entry System Id" := VendLedgEntry.SystemId;
                                TempVendorPaymentBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                                TempVendorPaymentBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                                TempVendorPaymentBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                TempVendorPaymentBuffer."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
                                TempVendorPaymentBuffer.Amount := TempPayableVendorLedgerEntry.Amount;
                                Window2.Update(1, VendLedgEntry."Vendor No.");
                                OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsertNonSummarize(TempVendorPaymentBuffer, VendLedgEntry, SummarizePerVend, NextDocNo, TempPayableVendorLedgerEntry);
                                TempVendorPaymentBuffer.Insert();
                            end;
                        end;
                        VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                        OnMakeGenJnlLinesOnBeforeModifyVendorLedgerEntry(VendLedgEntry);
                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                    end else begin
                        TempVendorLedgerEntry := VendLedgEntry;
                        TempVendorLedgerEntry.Insert();
                    end;

                    TempPayableVendorLedgerEntry.Delete();
                    if OriginalAmtAvailable <> 0 then begin
                        RemainingAmtAvailable := RemainingAmtAvailable - TempPayableVendorLedgerEntry."Amount (LCY)";
                        RemovePaymentsAboveLimit(TempPayableVendorLedgerEntry, RemainingAmtAvailable);
                    end;

                until not TempPayableVendorLedgerEntry.FindSet();
                TempPayableVendorLedgerEntry.DeleteAll();
                TempPayableVendorLedgerEntry.SetRange("Vendor No.");
            until not TempPayableVendorLedgerEntry.Find('-');

        Clear(TempOldVendorPaymentBuffer);
        TempVendorPaymentBuffer.SetCurrentKey("Document No.");
        TempVendorPaymentBuffer.SetFilter(
          "Vendor Ledg. Entry Doc. Type", '<>%1&<>%2', TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type"::Refund,
          TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type"::Payment);

        if TempVendorPaymentBuffer.Find('-') then
            repeat
                InsertGenJournalLine();
            until TempVendorPaymentBuffer.Next() = 0;
    end;

    local procedure InsertGenJournalLine()
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        GenJnlLine.Init();
        Window2.Update(1, TempVendorPaymentBuffer."Vendor No.");
        LastLineNo := LastLineNo + 10000;
        GenJnlLine."Line No." := LastLineNo;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";
        GenJnlLine."Journal Batch Id" := GenJnlBatch.SystemId;

        IsHandled := false;
        OnInsertGenJournalLineOnBeforeAssignDocumentNo(GenJnlLine, GenJnlLine2, GenJnlBatch, TempVendorPaymentBuffer, NextDocNo, BankPmtType, DocNoPerLine, TempOldVendorPaymentBuffer, SummarizePerVend, IsHandled);
        if not IsHandled then
            if SummarizePerVend then
                GenJnlLine."Document No." := TempVendorPaymentBuffer."Document No."
            else
                if DocNoPerLine then begin
                    if TempVendorPaymentBuffer.Amount < 0 then
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;

                    GenJnlLine."Document No." := NextDocNo;
                    RunIncrementDocumentNo(false);
                end else
                    if (GenJnlLine2."Bal. Account No." = '') and not DocNoPerLine then
                        GenJnlLine."Document No." := NextDocNo
                    else
                        if (TempVendorPaymentBuffer."Vendor No." = TempOldVendorPaymentBuffer."Vendor No.") and
                        (TempVendorPaymentBuffer."Currency Code" = TempOldVendorPaymentBuffer."Currency Code")
                        then
                            GenJnlLine."Document No." := TempOldVendorPaymentBuffer."Document No."
                        else begin
                            GenJnlLine."Document No." := NextDocNo;
                            RunIncrementDocumentNo(false);
                            TempOldVendorPaymentBuffer := TempVendorPaymentBuffer;
                            TempOldVendorPaymentBuffer."Document No." := GenJnlLine."Document No.";
                        end;

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.SetHideValidation(true);
        ShowPostingDateWarning := ShowPostingDateWarning or
          SetPostingDate(GenJnlLine, GetVendorLedgerEntryDueDate(TempVendorPaymentBuffer."Vendor Ledg. Entry No."), PostingDate);
        GenJnlLine.Validate("Account No.", TempVendorPaymentBuffer."Vendor No.");
        Vendor.Get(TempVendorPaymentBuffer."Vendor No.");
        if (Vendor."Pay-to Vendor No." <> '') and (Vendor."Pay-to Vendor No." <> GenJnlLine."Account No.") then
            Message(Text025, Vendor.TableCaption(), Vendor."No.", Vendor.FieldCaption("Pay-to Vendor No."),
              Vendor."Pay-to Vendor No.");
        GenJnlLine."Bal. Account Type" := BalAccType;
        GenJnlLine.Validate("Bal. Account No.", BalAccNo);
        GenJnlLine.Validate("Currency Code", TempVendorPaymentBuffer."Currency Code");
        GenJnlLine."Message to Recipient" := GetMessageToRecipient(SummarizePerVend);
        GenJnlLine."Bank Payment Type" := BankPmtType;
        if SummarizePerVend then
            GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
        GenJnlLine.Description := Vendor.Name;
        GenJnlLine."Source Line No." := TempVendorPaymentBuffer."Vendor Ledg. Entry No.";
        GenJnlLine."Shortcut Dimension 1 Code" := TempVendorPaymentBuffer."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TempVendorPaymentBuffer."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := TempVendorPaymentBuffer."Dimension Set ID";
        GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
        GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJnlLine.Validate(Amount, TempVendorPaymentBuffer.Amount);
        GenJnlLine."Applies-to Doc. Type" := TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type";
        GenJnlLine."Applies-to Doc. No." := TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. No.";
        GenJnlLine."Applies-to Invoice Id" := TempVendorPaymentBuffer."Ledg. Entry System Id";
        GenJnlLine."Payment Method Code" := TempVendorPaymentBuffer."Payment Method Code";
        GenJnlLine."Remit-to Code" := TempVendorPaymentBuffer."Remit-to Code";

        TempVendorPaymentBuffer.CopyFieldsToGenJournalLine(GenJnlLine);

        OnBeforeUpdateGnlJnlLineDimensionsFromVendorPaymentBuffer(GenJnlLine, TempVendorPaymentBuffer, SummarizePerVend, DocNoPerLine, NextDocNo);
        UpdateDimensions(GenJnlLine);
        GenJnlLine.Insert();
        GenJnlLineInserted := true;
    end;

    local procedure RunIncrementDocumentNo(PrepareBuffer: Boolean)
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunIncrementDocumentNo(GenJnlLine, GenJnlBatch, PrepareBuffer, DocNoPerLine, BalAccNo, IsHandled);
        if IsHandled then
            exit;

        NextDocNo := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", GenJnlLine."Posting Date", NextDocNo);
    end;

    local procedure UpdateDimensions(var GenJnlLine: Record "Gen. Journal Line")
    var
        DimBuf: Record "Dimension Buffer";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        NewDimensionID: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        NewDimensionID := GenJnlLine."Dimension Set ID";
        if SummarizePerVend then begin
            DimBuf.Reset();
            DimBuf.DeleteAll();
            DimBufMgt.GetDimensions(TempVendorPaymentBuffer."Dimension Entry No.", DimBuf);
            if DimBuf.FindSet() then
                repeat
                    DimVal.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                    TempDimSetEntry."Dimension Code" := DimBuf."Dimension Code";
                    TempDimSetEntry."Dimension Value Code" := DimBuf."Dimension Value Code";
                    TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                    TempDimSetEntry.Insert();
                until DimBuf.Next() = 0;
            NewDimensionID := DimMgt.GetDimensionSetID(TempDimSetEntry);
            GenJnlLine."Dimension Set ID" := NewDimensionID;
        end;
        GenJnlLine.CreateDimFromDefaultDim(0);
        if NewDimensionID <> GenJnlLine."Dimension Set ID" then begin
            DimSetIDArr[1] := GenJnlLine."Dimension Set ID";
            DimSetIDArr[2] := NewDimensionID;
            GenJnlLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimSetIDArr, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
        end;

        if SummarizePerVend then begin
            DimMgt.GetDimensionSet(TempDimSetEntry, GenJnlLine."Dimension Set ID");
            if AdjustAgainstSelectedDim(TempDimSetEntry, TempDimSetEntry2) then
                GenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry2);
            DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
              GenJnlLine."Shortcut Dimension 2 Code");
        end;

        OnAfterUpdateDimensions(GenJnlLine, SummarizePerVend);
    end;

    local procedure SetBankAccCurrencyFilter(BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
    begin
        OnBeforeSetBankAccCurrencyFilter(BalAccType, BalAccNo, TempPayableVendorLedgerEntry);
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then
                    TempPayableVendorLedgerEntry.SetRange("Currency Code", BankAcc."Currency Code");
            end;
    end;

    local procedure ShowMessage(Text: Text)
    begin
        if GenJnlLineInserted then begin
            if ShowPostingDateWarning then
                Text += ReplacePostingDateMsg;
            if Text <> '' then
                Message(Text);
        end;
    end;

    local procedure CheckCurrencies(BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; var TmpTempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry")
    var
        BankAcc: Record "Bank Account";
        TempPayableVendorLedgerEntry2: Record "Payable Vendor Ledger Entry" temporary;
    begin
        if BalAccType = BalAccType::"Bank Account" then
            if BalAccNo <> '' then begin
                BankAcc.Get(BalAccNo);
                if BankAcc."Currency Code" <> '' then begin
                    TempPayableVendorLedgerEntry2.Reset();
                    TempPayableVendorLedgerEntry2.DeleteAll();
                    if TmpTempPayableVendorLedgerEntry.FindSet() then
                        repeat
                            TempPayableVendorLedgerEntry2 := TmpTempPayableVendorLedgerEntry;
                            TempPayableVendorLedgerEntry2.Insert();
                        until TmpTempPayableVendorLedgerEntry.Next() = 0;

                    TempPayableVendorLedgerEntry2.SetFilter("Currency Code", '<>%1', BankAcc."Currency Code");
                    SeveralCurrencies := SeveralCurrencies or TempPayableVendorLedgerEntry2.FindFirst();

                    if SeveralCurrencies then
                        MessageText :=
                          StrSubstNo(Text020, BankAcc.FieldCaption("Currency Code"), BankAcc."Currency Code")
                    else
                        MessageText :=
                          StrSubstNo(Text021, BankAcc.FieldCaption("Currency Code"), BankAcc."Currency Code");
                end else
                    MessageText := Text022;
            end;
    end;

    local procedure ClearNegative()
    var
        TempCurrency: Record Currency temporary;
        TempPayableVendorLedgerEntry2: Record "Payable Vendor Ledger Entry" temporary;
        CurrencyBalance: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearNegative(TempPayableVendorLedgerEntry, AmountAvailable, Vendor, IsHandled);
        if IsHandled then
            exit;

        Clear(TempPayableVendorLedgerEntry);
        TempPayableVendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");

        while TempPayableVendorLedgerEntry.Next() <> 0 do begin
            TempCurrency.Code := TempPayableVendorLedgerEntry."Currency Code";
            CurrencyBalance := 0;
            if TempCurrency.Insert() then begin
                TempPayableVendorLedgerEntry2 := TempPayableVendorLedgerEntry;
                TempPayableVendorLedgerEntry.SetRange("Currency Code", TempPayableVendorLedgerEntry."Currency Code");
                repeat
                    CurrencyBalance := CurrencyBalance + TempPayableVendorLedgerEntry."Amount (LCY)"
                until TempPayableVendorLedgerEntry.Next() = 0;
                if CurrencyBalance < 0 then begin
                    TempPayableVendorLedgerEntry.DeleteAll();
                    AmountAvailable += CurrencyBalance;
                end;
                TempPayableVendorLedgerEntry.SetRange("Currency Code");
                TempPayableVendorLedgerEntry := TempPayableVendorLedgerEntry2;
            end;
        end;
        TempPayableVendorLedgerEntry.Reset();
    end;

    local procedure DimCodeIsInDimBuf(DimCode: Code[20]; DimBuf: Record "Dimension Buffer"): Boolean
    begin
        DimBuf.Reset();
        DimBuf.SetRange("Dimension Code", DimCode);
        exit(not DimBuf.IsEmpty);
    end;

    local procedure RemovePaymentsAboveLimit(var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry"; RemainingAmtAvailable: Decimal)
    begin
        TempPayableVendorLedgerEntry.SetFilter("Amount (LCY)", '>%1', RemainingAmtAvailable);
        TempPayableVendorLedgerEntry.DeleteAll();
        TempPayableVendorLedgerEntry.SetRange("Amount (LCY)");
    end;

    local procedure InsertDimBuf(var DimBuf: Record "Dimension Buffer"; TableID: Integer; EntryNo: Integer; DimCode: Code[20]; DimValue: Code[20])
    begin
        DimBuf.Init();
        DimBuf."Table ID" := TableID;
        DimBuf."Entry No." := EntryNo;
        DimBuf."Dimension Code" := DimCode;
        DimBuf."Dimension Value Code" := DimValue;
        DimBuf.Insert();
    end;

    local procedure GetMessageToRecipient(SummarizePerVend: Boolean): Text[140]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
        Message: Text[140];
    begin
        OnBeforeGetMessageToRecipient(SummarizePerVend, TempVendorPaymentBuffer, IsHandled, Message);
        if IsHandled then
            exit(Message);

        if SummarizePerVend then
            exit(CompanyInformation.Name);

        VendorLedgerEntry.Get(TempVendorPaymentBuffer."Vendor Ledg. Entry No.");
        if VendorLedgerEntry."Message to Recipient" <> '' then
            exit(VendorLedgerEntry."Message to Recipient");

        exit(
          StrSubstNo(
            MessageToRecipientMsg,
            TempVendorPaymentBuffer."Vendor Ledg. Entry Doc. Type",
            TempVendorPaymentBuffer."Applies-to Ext. Doc. No."));
    end;

    local procedure SetPostingDate(var GenJnlLine: Record "Gen. Journal Line"; DueDate: Date; PostingDate: Date): Boolean
    begin
        if not UseDueDateAsPostingDate then begin
            GenJnlLine.Validate("Posting Date", PostingDate);
            exit(false);
        end;

        if DueDate = 0D then
            DueDate := GetDueDateOrPaymentDiscountDate(GenJnlLine.GetAppliesToDocDueDate(), GenJnlLine.GetAppliesToDocPmtDiscountDate(), UsePaymentDisc and (GenJnlLine."Payment Discount %" <> 0));
        exit(GenJnlLine.SetPostingDateAsDueDate(DueDate, DueDateOffset));
    end;

    local procedure GetVendorLedgerEntryDueDate(VendorLedgerEntryNo: Integer): Date
    var
        FromVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if FromVendorLedgerEntry.Get(VendorLedgerEntryNo) then
            exit(GetDueDateOrPaymentDiscountDate(FromVendorLedgerEntry."Due Date", FromVendorLedgerEntry."Pmt. Discount Date", UsePaymentDisc and (FromVendorLedgerEntry."Original Pmt. Disc. Possible" <> 0)));
        exit(PostingDate);
    end;

    local procedure GetDueDateOrPaymentDiscountDate(DueDate: Date; PmtDiscountDate: Date; PmtDiscountPossible: Boolean): Date
    begin
        if not PmtDiscountPossible or (PmtDiscountDate = 0D) then
            exit(DueDate);

        if PmtDiscountDate < DueDate then
            exit(PmtDiscountDate);
        exit(DueDate);
    end;

    local procedure AdjustAgainstSelectedDim(var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempDimSetEntry2: Record "Dimension Set Entry" temporary): Boolean
    begin
        if SelectedDim.FindSet() then begin
            repeat
                TempDimSetEntry.SetRange("Dimension Code", SelectedDim."Dimension Code");
                if TempDimSetEntry.FindFirst() then begin
                    TempDimSetEntry2.TransferFields(TempDimSetEntry, true);
                    TempDimSetEntry2.Insert();
                end;
            until SelectedDim.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetTempPaymentBufferDims(var DimBuf: Record "Dimension Buffer")
    var
        GLSetup: Record "General Ledger Setup";
        EntryNo: Integer;
    begin
        OnBeforeSetTempPaymentBufferDims(VendLedgEntry, SummarizePerDim);
        if SummarizePerDim then begin
            DimBuf.Reset();
            DimBuf.DeleteAll();
            if SelectedDim.FindSet() then
                repeat
                    if DimSetEntry.Get(VendLedgEntry."Dimension Set ID", SelectedDim."Dimension Code") then
                        InsertDimBuf(DimBuf, DATABASE::"Dimension Buffer", 0, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                until SelectedDim.Next() = 0;
            EntryNo := DimBufMgt.FindDimensions(DimBuf);
            if EntryNo = 0 then
                EntryNo := DimBufMgt.InsertDimensions(DimBuf);
            TempVendorPaymentBuffer."Dimension Entry No." := EntryNo;
            if TempVendorPaymentBuffer."Dimension Entry No." <> 0 then begin
                GLSetup.Get();
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 1 Code", DimBuf) then
                    TempVendorPaymentBuffer."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code"
                else
                    TempVendorPaymentBuffer."Global Dimension 1 Code" := '';
                if DimCodeIsInDimBuf(GLSetup."Global Dimension 2 Code", DimBuf) then
                    TempVendorPaymentBuffer."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code"
                else
                    TempVendorPaymentBuffer."Global Dimension 2 Code" := '';
            end else begin
                TempVendorPaymentBuffer."Global Dimension 1 Code" := '';
                TempVendorPaymentBuffer."Global Dimension 2 Code" := '';
            end;
            TempVendorPaymentBuffer."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        end else begin
            TempVendorPaymentBuffer."Dimension Entry No." := 0;
            TempVendorPaymentBuffer."Global Dimension 1 Code" := '';
            TempVendorPaymentBuffer."Global Dimension 2 Code" := '';
            TempVendorPaymentBuffer."Dimension Set ID" := 0;
        end;
    end;

    local procedure IsNotAppliedEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        if not IsNotAppliedToCurrentBatchLine(GenJournalLine, VendorLedgerEntry) then
            exit(false);
        exit(IsNotAppliedToOtherBatchLine(GenJournalLine, VendorLedgerEntry));
    end;

    local procedure IsNotAppliedToCurrentBatchLine(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        PaymentGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentGenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        PaymentGenJournalLine.SetRange("Account No.", VendorLedgerEntry."Vendor No.");
        PaymentGenJournalLine.SetRange("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
        PaymentGenJournalLine.SetRange("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        exit(PaymentGenJournalLine.IsEmpty);
    end;

    local procedure IsNotAppliedToOtherBatchLine(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        PaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        if not CheckOtherJournalBatches then
            exit(true);

        PaymentGenJournalLine.SetRange("Document Type", PaymentGenJournalLine."Document Type"::Payment);
        PaymentGenJournalLine.SetRange("Account Type", PaymentGenJournalLine."Account Type"::Vendor);
        PaymentGenJournalLine.SetRange("Account No.", VendorLedgerEntry."Vendor No.");
        PaymentGenJournalLine.SetRange("Applies-to Doc. Type", VendorLedgerEntry."Document Type");
        PaymentGenJournalLine.SetRange("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        if PaymentGenJournalLine.IsEmpty() then
            exit(true);

        if PaymentGenJournalLine.FindSet() then begin
            repeat
                if (PaymentGenJournalLine."Journal Batch Name" <> GenJournalLine."Journal Batch Name") or
                   (PaymentGenJournalLine."Journal Template Name" <> GenJournalLine."Journal Template Name")
                then
                    LogNotSuggestedPaymentMessage(PaymentGenJournalLine);
            until PaymentGenJournalLine.Next() = 0;
            exit(TempErrorMessage.IsEmpty);
        end;
    end;

    local procedure LogNotSuggestedPaymentMessage(GenJournalLine: Record "Gen. Journal Line")
    begin
        TempErrorMessage.LogMessage(
          GenJournalLine, GenJournalLine.FieldNo("Applies-to ID"),
          TempErrorMessage."Message Type"::Warning,
          StrSubstNo(
            NotSuggestedPaymentInfoTxt,
            GenJournalLine.FieldCaption("Journal Template Name"),
            GenJournalLine."Journal Template Name",
            GenJournalLine.FieldCaption("Journal Batch Name"),
            GenJournalLine."Journal Batch Name",
            GenJournalLine.FieldCaption("Applies-to Doc. No."),
            GenJournalLine."Applies-to Doc. No."));
    end;

    local procedure SetDefaults()
    begin
        if not GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            GenJnlBatch.Get(JnlTemplateName, JnlBatchName);
        if GenJnlBatch."Bal. Account No." <> '' then begin
            GenJnlLine2."Bal. Account Type" := GenJnlBatch."Bal. Account Type";
            GenJnlLine2."Bal. Account No." := GenJnlBatch."Bal. Account No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDataItem(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveAmount(var GenJournalLine: Record "Gen. Journal Line"; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensions(var GenJournalLine: Record "Gen. Journal Line"; SummarizePerVend: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncludeVendor(Vendor: Record Vendor; VendorBalance: Decimal; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetVendLedgEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; PostingDate: Date; LastDueDateToPayReq: Date; UseVendorPriority: Boolean; UseDueDateAsPostingDate: Boolean; DueDateOffset: DateFormula; Positive: Boolean; Future: Boolean; var PayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary; var NextEntryNo: Integer; SkipImportedPayments: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorPaymentBufferFromVendorLedgerEntry(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAmounts(var PayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry"; var OriginalAmtAvailable: Decimal; var AmountAvailable: Decimal; var StopPayments: Boolean; Future: Boolean; Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearNegative(var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary; var AmountAvailable: Decimal; Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var HandledEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunIncrementDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; PrepareBuffer: Boolean; DocNoPerLine: Boolean; BalAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTempPaymentBufferDims(VendorLedgerEntry: Record "Vendor Ledger Entry"; var SummarizePerDim: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateGnlJnlLineDimensionsFromVendorPaymentBuffer(var GenJournalLine: Record "Gen. Journal Line"; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; SummarizePerVend: Boolean; DocNoPerLine: Boolean; var NextDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgEntriesOnBeforeLoop(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PostingDate: Date; LastDueDateToPayReq: Date; Future: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgEntriesOnAfterVendLedgEntrySetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; PostingDate: Date; LastDueDateToPayReq: Date; Positive: Boolean; Future: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertGenJournalLineOnBeforeAssignDocumentNo(var GenJournalLine: record "Gen. Journal Line"; GenJournalLine2: record "Gen. Journal Line"; GenJournalBatch: record "Gen. Journal Batch"; TempVendorPaymentBuffer: record "Vendor Payment Buffer" temporary; var NextDocNo: Code[20]; BankPmtType: Enum "Bank Payment Type"; DocNoPerLine: Boolean; var TempOldVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; SummarizePerVend: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeGenJnlLinesOnBeforeModifyVendorLedgerEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeGenJnlLinesOnBeforeUpdateVendorPaymentBufferAmounts(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; var SummarizePerVend: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsertNonSummarize(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; var SummarizePerVend: Boolean; var NextDocNo: Code[20]; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeGenJnlLinesOnBeforeVendorPaymentBufferInsert(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeGenJnlLinesOnBeforeVendorPaymentBufferModify(var TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; VendorLederEntry: Record "Vendor Ledger Entry"; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMessageToRecipient(SummarizePerVend: Boolean; TempVendorPaymentBuffer: Record "Vendor Payment Buffer" temporary; var IsHandled: Boolean; var Message: Text[140])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnBeforeMakeGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; var TempPayableVendorLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBankAccCurrencyFilter(BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; var TempPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry" temporary)
    begin
    end;
}
