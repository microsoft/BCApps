// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Posting;

page 5939 "Serv. Apply Customer Entries"
{
    Caption = 'Apply Customer Entries';
    DataCaptionFields = "Customer No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Cust. Ledger Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ApplyingCustLedgEntryPostingDate; TempApplyingCustLedgEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the entry to be applied. This date is used to find the correct exchange rate when applying entries in different currencies.';
                }
                field(ApplyingCustLedgEntryDocumentType; TempApplyingCustLedgEntry."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type of the entry to be applied.';
                }
                field(ApplyingCustLedgEntryDocumentNo; TempApplyingCustLedgEntry."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(ApplyingCustLedgEntryCustomerNo; TempApplyingCustLedgEntry."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    Editable = false;
                    ToolTip = 'Specifies the customer number of the entry to be applied.';
                    Visible = false;
                }
                field(ApplyingCustLedgEntryCustomerName; TempApplyingCustLedgEntry."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name';
                    Editable = false;
                    ToolTip = 'Specifies the customer name of the entry to be applied.';
                    Visible = CustNameVisible;
                }
                field(ApplyingCustLedgEntryDescription; TempApplyingCustLedgEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry to be applied.';
                    Visible = false;
                }
                field(ApplyingCustLedgEntryCurrencyCode; TempApplyingCustLedgEntry."Currency Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field(ApplyingCustLedgEntryAmount; TempApplyingCustLedgEntry.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
                field(ApplyingCustLedgEntryRemainingAmount; TempApplyingCustLedgEntry."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(AppliesToID; Rec."Applies-to ID")
                {
                    ApplicationArea = All;
                    Visible = AppliesToIDVisible;

                    trigger OnValidate()
                    begin
                        if (CalcType = CalcType::"Gen. Jnl. Line") and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetCustApplId(true);
                        if Rec."Applies-to ID" <> '' then
                            UpdateCustomAppliesToIDForGenJournal(Rec."Applies-to ID");

                        CurrPage.Update(false);
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                }
                field(Prepayment; Rec.Prepayment)
                {
                    ApplicationArea = Prepayments;
                    Editable = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = CustNameVisible;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
#pragma warning disable AA0100
                field("CalcApplnRemainingAmount(""Remaining Amount"")"; CalcApplnRemainingAmount(Rec."Remaining Amount"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Amount to Apply"; Rec."Amount to Apply")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnValidate()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);

                        if (xRec."Amount to Apply" = 0) or (Rec."Amount to Apply" = 0) and
                           ((ApplnType = ApplnType::"Applies-to ID") or (CalcType = CalcType::Direct))
                        then
                            SetCustApplId(false);
                        Rec.Get(Rec."Entry No.");
                        AmountToApplyOnAfterValidate();
                    end;
                }
                field(ApplnAmountToApply; CalcApplnAmountToApply(Rec."Amount to Apply"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Amount to Apply';
                    ToolTip = 'Specifies the amount to apply.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnValidate()
                    begin
                        RecalcApplnAmount();
                    end;
                }
                field("Pmt. Disc. Tolerance Date"; Rec."Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Remaining Pmt. Disc. Possible"; Rec."Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnValidate()
                    begin
                        RecalcApplnAmount();
                    end;
                }
#pragma warning disable AA0100
                field("CalcApplnRemainingAmount(""Remaining Pmt. Disc. Possible"")"; CalcApplnRemainingAmount(Rec."Remaining Pmt. Disc. Possible"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Pmt. Disc. Possible';
                    ToolTip = 'Specifies the discount that the customer can obtain if the entry is applied to before the payment discount date.';
                }
                field("Max. Payment Tolerance"; Rec."Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
            }
            group(Control41)
            {
                ShowCaption = false;
                fixed(Control1903222401)
                {
                    ShowCaption = false;
                    group("Appln. Currency")
                    {
                        Caption = 'Appln. Currency';
                        field(ApplnCurrencyCode; ApplnCurrencyCode)
                        {
                            ApplicationArea = Suite;
                            Editable = false;
                            ShowCaption = false;
                            TableRelation = Currency;
                            ToolTip = 'Specifies the currency code that the amount will be applied in, in case of different currencies.';
                        }
                    }
                    group(Control1903098801)
                    {
                        Caption = 'Amount to Apply';
                        field(AmountToApply; AppliedAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Amount to Apply';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts on all the selected customer ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Pmt. Disc. Amount")
                    {
                        Caption = 'Pmt. Disc. Amount';
                        field(PmtDiscountAmount; -PmtDiscAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Amount';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the payment discount amounts granted on all the selected customer ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group(Rounding)
                    {
                        Caption = 'Rounding';
                        field(ApplnRounding; ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Rounding';
                            Editable = false;
                            ToolTip = 'Specifies the rounding difference when you apply entries in different currencies to one another. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Applied Amount")
                    {
                        Caption = 'Applied Amount';
                        field(AppliedAmount; AppliedAmount + (-PmtDiscAmount) + ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Applied Amount';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts in the Amount to Apply field, Pmt. Disc. Amount field, and the Rounding. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Available Amount")
                    {
                        Caption = 'Available Amount';
                        field(ApplyingAmount; ApplyingAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Available Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the journal entry, sales credit memo, or current customer ledger entry that you have selected as the applying entry.';
                        }
                    }
                    group(Balance)
                    {
                        Caption = 'Balance';
                        field(ControlBalance; AppliedAmount + (-PmtDiscAmount) + ApplyingAmount + ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies any extra amount that will remain after the application.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control1903096107; "Customer Ledger Entry FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Entry No." = field("Entry No.");
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Customer Entries";
                    RunPageOnRec = true;
                    ToolTip = 'View the ledger entries that have been applied to this record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Cust. Ledg. Entries";
                    RunPageLink = "Cust. Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Cust. Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of the all posted entries and adjustments related to a specific customer ledger entry.';
                }
                action("&Navigate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                    trigger OnAction()
                    begin
                        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                        Navigate.Run();
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Set Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AppliesToIDVisible;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Set the Applies-to ID field on the posted entry to automatically be filled in with the document number of the entry in the journal.';

                    trigger OnAction()
                    begin
                        if (CalcType = CalcType::"Gen. Jnl. Line") and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetCustApplId(false);
                    end;
                }
                action("Post Application")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CalledFromEntry;
                    Caption = 'Post Application';
                    Ellipsis = true;
                    Image = PostApplication;
                    ShortCutKey = 'F9';
                    ToolTip = 'Define the document number of the ledger entry to use to perform the application. In addition, you specify the Posting Date for the application.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CalledFromEntry;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(true);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("Show Only Selected Entries to Be Applied")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Only Selected Entries to Be Applied';
                    Image = ShowSelected;
                    ToolTip = 'View the selected ledger entries that will be applied to the specified record.';

                    trigger OnAction()
                    begin
                        ShowAppliedEntries := not ShowAppliedEntries;
                        if ShowAppliedEntries then
                            if CalcType = CalcType::"Gen. Jnl. Line" then
                                Rec.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
                            else begin
                                CustEntryApplID := UserId;
                                if CustEntryApplID = '' then
                                    CustEntryApplID := '***';
                                Rec.SetRange("Applies-to ID", CustEntryApplID);
                            end
                        else
                            Rec.SetRange("Applies-to ID");
                    end;
                }
            }
            action(ShowPostedDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Posted Document';
                Image = Document;
                ToolTip = 'Show details for the posted payment, invoice, or credit memo.';

                trigger OnAction()
                begin
                    Rec.ShowDoc();
                end;
            }
            action(ShowDocumentAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document Attachment';
                Enabled = HasDocumentAttachment;
                Image = Attach;
                ToolTip = 'View documents or images that are attached to the posted invoice or credit memo.';

                trigger OnAction()
                begin
                    Rec.ShowPostedDocAttachment();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Set Applies-to ID_Promoted"; "Set Applies-to ID")
                {
                }
                actionref("Post Application_Promoted"; "Post Application")
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref("Show Only Selected Entries to Be Applied_Promoted"; "Show Only Selected Entries to Be Applied")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(ShowPostedDocument_Promoted; ShowPostedDocument)
                    {
                    }
                    actionref(ShowDocumentAttachment_Promoted; ShowDocumentAttachment)
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category5)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                {
                }
                actionref("Detailed &Ledger Entries_Promoted"; "Detailed &Ledger Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ApplnType = ApplnType::"Applies-to Doc. No." then
            CalcApplnAmount();
        HasDocumentAttachment := Rec.HasPostedDocAttachment();
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    trigger OnInit()
    begin
        AppliesToIDVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);
        if Rec."Applies-to ID" <> xRec."Applies-to ID" then
            CalcApplnAmount();
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        if CalcType = CalcType::Direct then begin
            Cust.Get(Rec."Customer No.");
            ApplnCurrencyCode := Cust."Currency Code";
            FindApplyingEntry();
        end;

        ActivateFields();

        SalesSetup.Get();
        CustNameVisible := SalesSetup."Copy Customer Name to Entries";

        AppliesToIDVisible := ApplnType <> ApplnType::"Applies-to Doc. No.";

        GLSetup.Get();

        if ApplnType = ApplnType::"Applies-to Doc. No." then
            CalcApplnAmount();
        PostingDone := false;

        OnAfterOnOpenPage(GenJnlLine, Rec, TempApplyingCustLedgEntry);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RaiseError: Boolean;
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
        if ApplnType = ApplnType::"Applies-to Doc. No." then begin
            if OK then begin
                RaiseError := TempApplyingCustLedgEntry."Posting Date" < Rec."Posting Date";
                OnBeforeEarlierPostingDateError(TempApplyingCustLedgEntry, Rec, RaiseError, CalcType.AsInteger(), OK);
                if RaiseError then begin
                    OK := false;
                    Error(
                      EarlierPostingDateErr, TempApplyingCustLedgEntry."Document Type", TempApplyingCustLedgEntry."Document No.",
                      Rec."Document Type", Rec."Document No.");
                end;
                OnQueryClosePageOnAfterEarlierPostingDateTest(TempApplyingCustLedgEntry, Rec, CalcType, OK);
            end;
            if OK then begin
                if Rec."Amount to Apply" = 0 then
                    Rec."Amount to Apply" := Rec."Remaining Amount";
                CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);
            end;
        end;
        if (CalcType = CalcType::Direct) and not OK and not PostingDone then begin
            Rec := TempApplyingCustLedgEntry;
            Rec."Applying Entry" := false;
            if AppliesToID = '' then begin
                Rec."Applies-to ID" := '';
                Rec."Amount to Apply" := 0;
            end;

            OnOnQueryClosePageOnBeforeRunCustEntryEdit(Rec);
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);
        end;
    end;

    var
        ServHeader: Record "Service Header";
        Cust: Record Customer;
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        TotalServLine: Record "Service Line";
        TotalServLineLCY: Record "Service Line";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        Navigate: Page Navigate;
        StyleTxt: Text;
        AppliesToID: Code[50];
        CustomAppliesToID: Code[50];
        TimesSetCustomAppliesToID: Integer;
        ValidExchRate: Boolean;
        MustSelectEntryErr: Label 'You must select an applying entry before you can post the application.';
        PostingInWrongContextErr: Label 'You must post the application from the window where you entered the applying entry.';
        CannotSetAppliesToIDErr: Label 'You cannot set Applies-to ID while selecting Applies-to Doc. No.';
        ShowAppliedEntries: Boolean;
        CalledFromEntry: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.\\Instead, post the document of type %1 with the number %2 and then apply it to the document of type %3 with the number %4.', Comment = '%1 - document type, %2 - document number,%3 - document type,%4 - document number';
        ApplicationPostedMsg: Label 'The application was successfully posted.';
#pragma warning disable AA0470
        ApplicationDateErr: Label 'The %1 entered must not be before the %1 on the %2.';
#pragma warning restore AA0470
        HasDocumentAttachment: Boolean;
        CustNameVisible: Boolean;
        GenJnlLineApply: Boolean;

    protected var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempApplyingCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        ApplnDate: Date;
        ApplnRoundingPrecision: Decimal;
        ApplnRounding: Decimal;
        ApplnType: Enum "Customer Apply-to Type";
        AmountRoundingPrecision: Decimal;
        VATAmount: Decimal;
        VATAmountText: Text[30];
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        PmtDiscAmount: Decimal;
        ApplnCurrencyCode: Code[10];
        CustEntryApplID: Code[50];
        AppliesToIDVisible: Boolean;
        DifferentCurrenciesInAppln: Boolean;
        PostingDone: Boolean;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        CalcType: Enum "Customer Apply Calculation Type";
        OK: Boolean;

    procedure SetService(NewServHeader: Record "Service Header"; var NewCustLedgEntry: Record "Cust. Ledger Entry"; ApplnTypeSelect: Integer)
    var
        ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
        TotalAdjCostLCY: Decimal;
    begin
        ServHeader := NewServHeader;
        Rec.CopyFilters(NewCustLedgEntry);

        ServAmountsMgt.SumServiceLines(
          ServHeader, 0, TotalServLine, TotalServLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);

        case ServHeader."Document Type" of
            ServHeader."Document Type"::"Credit Memo":
                ApplyingAmount := -TotalServLine."Amount Including VAT"
            else
                ApplyingAmount := TotalServLine."Amount Including VAT";
        end;

        ApplnDate := ServHeader."Posting Date";
        ApplnCurrencyCode := ServHeader."Currency Code";
        CalcType := CalcType::"Service Header";

        case ApplnTypeSelect of
            ServHeader.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            ServHeader.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        SetApplyingCustLedgEntry();
    end;

    procedure SetCustLedgEntry(NewCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        Rec := NewCustLedgEntry;
    end;

    procedure SetApplyingCustLedgEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplyingCustLedgEntry(TempApplyingCustLedgEntry, GenJnlLine, ServHeader, CalcType, IsHandled);
        if not IsHandled then begin
            case CalcType of
                CalcType::"Service Header":
                    SetApplyingCustledgEntryServiceHeader();
            end;

            CalcApplnAmount();
        end;

        OnAfterSetApplyingCustLedgEntry(TempApplyingCustLedgEntry, GenJnlLine, ServHeader);
    end;

    internal procedure GetCustomAppliesToID(): Code[50]
    begin
        if TimesSetCustomAppliesToID <> 1 then
            exit('');
        exit(CustomAppliesToID);
    end;

    local procedure UpdateCustomAppliesToIDForGenJournal(NewAppliesToID: Code[50])
    begin
        if (not GenJnlLineApply) or (ApplnType <> ApplnType::"Applies-to ID") then
            exit;
        if JournalHasDocumentNo(NewAppliesToID) then
            exit;
        if (CustomAppliesToID = '') or ((CustomAppliesToID <> '') and (CustomAppliesToID <> NewAppliesToID)) then
            TimesSetCustomAppliesToID += 1;

        CustomAppliesToID := NewAppliesToID;
    end;

    local procedure JournalHasDocumentNo(AppliesToIDCode: Code[50]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJournalLine.SetRange("Document No.", CopyStr(AppliesToIDCode, 1, MaxStrLen(GenJournalLine."Document No.")));
        exit(not GenJournalLine.IsEmpty());
    end;

    local procedure SetApplyingCustledgEntryServiceHeader()
    begin
        TempApplyingCustLedgEntry."Entry No." := 1;
        TempApplyingCustLedgEntry."Posting Date" := ServHeader."Posting Date";
        if ServHeader."Document Type" = ServHeader."Document Type"::"Credit Memo" then
            TempApplyingCustLedgEntry."Document Type" := TempApplyingCustLedgEntry."Document Type"::"Credit Memo"
        else
            TempApplyingCustLedgEntry."Document Type" := TempApplyingCustLedgEntry."Document Type"::Invoice;
        TempApplyingCustLedgEntry."Document No." := ServHeader."No.";
        TempApplyingCustLedgEntry."Customer No." := ServHeader."Bill-to Customer No.";
        TempApplyingCustLedgEntry.Description := ServHeader."Posting Description";
        TempApplyingCustLedgEntry."Currency Code" := ServHeader."Currency Code";
        if TempApplyingCustLedgEntry."Document Type" = TempApplyingCustLedgEntry."Document Type"::"Credit Memo" then begin
            TempApplyingCustLedgEntry.Amount := -TotalServLine."Amount Including VAT";
            TempApplyingCustLedgEntry."Remaining Amount" := -TotalServLine."Amount Including VAT";
        end else begin
            TempApplyingCustLedgEntry.Amount := TotalServLine."Amount Including VAT";
            TempApplyingCustLedgEntry."Remaining Amount" := TotalServLine."Amount Including VAT";
        end;

        OnAfterSetApplyingCustLedgEntryServiceHeader(TempApplyingCustLedgEntry, ServHeader);
    end;

    procedure SetCustApplId(CurrentRec: Boolean)
    begin
        CurrPage.SetSelectionFilter(CustLedgEntry);
        CheckCustLedgEntry(CustLedgEntry);

        OnSetCustApplIdAfterCheckAgainstApplnCurrency(Rec, CalcType.AsInteger(), GenJnlLine, ServHeader, TempApplyingCustLedgEntry);

        SetCustEntryApplID(CurrentRec);

        CalcApplnAmount();
    end;

    local procedure SetCustEntryApplID(CurrentRec: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCustEntryApplID(Rec, CurrentRec, ApplyingAmount, TempApplyingCustLedgEntry, GetAppliesToID(), IsHandled, GenJnlLine);
        if IsHandled then
            exit;

        CustLedgEntry.Copy(Rec);
        if CurrentRec then begin
            CustLedgEntry.SetRecFilter();
            CustEntrySetApplID.SetApplId(CustLedgEntry, TempApplyingCustLedgEntry, Rec."Applies-to ID")
        end else begin
            CurrPage.SetSelectionFilter(CustLedgEntry);
            CustEntrySetApplID.SetApplId(CustLedgEntry, TempApplyingCustLedgEntry, GetAppliesToID())
        end;
    end;

    procedure CheckCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        if CustLedgerEntry.FindSet() then
            repeat
                if CalcType = CalcType::"Gen. Jnl. Line" then begin
                    RaiseError := TempApplyingCustLedgEntry."Posting Date" < CustLedgerEntry."Posting Date";
                    OnBeforeEarlierPostingDateError(TempApplyingCustLedgEntry, CustLedgerEntry, RaiseError, CalcType.AsInteger(), OK);
                    if RaiseError then
                        Error(
                            EarlierPostingDateErr, TempApplyingCustLedgEntry."Document Type", TempApplyingCustLedgEntry."Document No.",
                            CustLedgerEntry."Document Type", CustLedgerEntry."Document No.");

                    OnCheckCustLedgEntryOnAfterEarlierPostingDateTest(TempApplyingCustLedgEntry, Rec, CalcType, OK);
                end;

                OnCheckCustLedgEntryOnBeforeCheckAgainstApplnCurrency(CustLedgerEntry, GenJnlLine, TempApplyingCustLedgEntry, CalcType);

                if TempApplyingCustLedgEntry."Entry No." <> 0 then begin
                    OnCheckCustLedgEntryOnBeforeCheckAgainstApplnCurrencyWhenEntryNoIsNotNull(CustLedgerEntry, GenJnlLine);
                    GenJnlApply.CheckAgainstApplnCurrency(
                        ApplnCurrencyCode, CustLedgerEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure GetAppliesToID() AppliesToID: Code[50]
    begin
        case CalcType of
            CalcType::"Service Header":
                AppliesToID := ServHeader."Applies-to ID";
        end;
        OnAfterGetAppliesToID(CalcType, AppliesToID);
    end;

    procedure CalcApplnAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcApplnAmount(
            Rec, GenJnlLine, ServHeader, AppliedCustLedgEntry, CalcType.AsInteger(), ApplnType.AsInteger(), IsHandled);
        if not IsHandled then begin
            AppliedAmount := 0;
            PmtDiscAmount := 0;
            DifferentCurrenciesInAppln := false;

            case CalcType of
                CalcType::Direct:
                    begin
                        FindAmountRounding();
                        CustEntryApplID := UserId;
                        if CustEntryApplID = '' then
                            CustEntryApplID := '***';

                        CustLedgEntry := TempApplyingCustLedgEntry;

                        AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                        AppliedCustLedgEntry.SetRange("Customer No.", Rec."Customer No.");
                        AppliedCustLedgEntry.SetRange(Open, true);
                        if AppliesToID = '' then
                            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID)
                        else
                            AppliedCustLedgEntry.SetRange("Applies-to ID", AppliesToID);

                        if TempApplyingCustLedgEntry."Entry No." <> 0 then begin
                            CustLedgEntry.CalcFields("Remaining Amount");
                            AppliedCustLedgEntry.SetFilter("Entry No.", '<>%1', TempApplyingCustLedgEntry."Entry No.");
                        end;

                        HandleChosenEntries(
                            CalcType::Direct, CustLedgEntry."Remaining Amount", CustLedgEntry."Currency Code", CustLedgEntry."Posting Date");
                    end;
                CalcType::"Gen. Jnl. Line":
                    begin
                        FindAmountRounding();
                        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer then
                            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

                        case ApplnType of
                            ApplnType::"Applies-to Doc. No.":
                                begin
                                    AppliedCustLedgEntry := Rec;
                                    AppliedCustLedgEntry.CalcFields("Remaining Amount");
                                    if AppliedCustLedgEntry."Currency Code" <> ApplnCurrencyCode then
                                        AppliedCustLedgEntry.UpdateAmountsForApplication(ApplnDate, ApplnCurrencyCode, false, false);

                                    OnCalcApplnAmountOnCalcTypeGenJnlLineOnApplnTypeToDocNoOnBeforeSetAppliedAmount(Rec, ApplnDate, ApplnCurrencyCode);
                                    if AppliedCustLedgEntry."Amount to Apply" <> 0 then
                                        AppliedAmount := Round(AppliedCustLedgEntry."Amount to Apply", AmountRoundingPrecision)
                                    else
                                        AppliedAmount := Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);
                                    OnCalcApplnAmountOnCalcTypeGenJnlLineOnApplnTypeToDocNoOnAfterSetAppliedAmount(Rec, ApplnDate, ApplnCurrencyCode, AppliedAmount);

                                    if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(
                                        GenJnlLine, AppliedCustLedgEntry, 0, false) and
                                       ((Abs(GenJnlLine.Amount) + ApplnRoundingPrecision >=
                                        Abs(AppliedAmount - AppliedCustLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date"))) or
                                        (GenJnlLine.Amount = 0))
                                    then
                                        PmtDiscAmount := AppliedCustLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date");

                                    if not DifferentCurrenciesInAppln then
                                        DifferentCurrenciesInAppln := ApplnCurrencyCode <> AppliedCustLedgEntry."Currency Code";
                                    CheckRounding();
                                end;
                            ApplnType::"Applies-to ID":
                                begin
                                    GenJnlLine2 := GenJnlLine;
                                    AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                                    AppliedCustLedgEntry.SetRange("Customer No.", GenJnlLine."Account No.");
                                    AppliedCustLedgEntry.SetRange(Open, true);
                                    AppliedCustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

                                    HandleChosenEntries(
                                        CalcType::"Gen. Jnl. Line", GenJnlLine2.Amount, GenJnlLine2."Currency Code", GenJnlLine2."Posting Date");
                                end;
                        end;
                    end;
                CalcType::"Sales Header", CalcType::"Service Header":
                    begin
                        FindAmountRounding();

                        case ApplnType of
                            ApplnType::"Applies-to Doc. No.":
                                begin
                                    AppliedCustLedgEntry := Rec;
                                    AppliedCustLedgEntry.CalcFields("Remaining Amount");

                                    if AppliedCustLedgEntry."Currency Code" <> ApplnCurrencyCode then
                                        AppliedCustLedgEntry."Remaining Amount" :=
                                        CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, AppliedCustLedgEntry."Currency Code", ApplnCurrencyCode, AppliedCustLedgEntry."Remaining Amount");

                                    OnCalcApplnAmountOnCalcTypeSalesHeaderOnApplnTypeToDocNoOnBeforeSetAppliedAmount(Rec, ApplnDate, ApplnCurrencyCode);
                                    AppliedAmount := Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);

                                    if not DifferentCurrenciesInAppln then
                                        DifferentCurrenciesInAppln := ApplnCurrencyCode <> AppliedCustLedgEntry."Currency Code";
                                    CheckRounding();
                                end;
                            ApplnType::"Applies-to ID":
                                begin
                                    AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                                    AppliedCustLedgEntry.SetRange("Customer No.", ServHeader."Bill-to Customer No.");
                                    AppliedCustLedgEntry.SetRange(Open, true);
                                    AppliedCustLedgEntry.SetRange("Applies-to ID", GetAppliesToID());

                                    HandleChosenEntries(CalcType::"Sales Header", ApplyingAmount, ApplnCurrencyCode, ApplnDate);
                                end;
                        end;
                    end;
            end;
        end;

        OnAfterCalcApplnAmount(Rec, AppliedAmount, ApplyingAmount, CalcType, AppliedCustLedgEntry, GenJnlLine);
    end;

    protected procedure CalcApplnRemainingAmount(Amount: Decimal): Decimal
    var
        ApplnRemainingAmount: Decimal;
    begin
        ValidExchRate := true;
        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(Amount);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnRemainingAmount :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, Amount, ValidExchRate);

        OnAfterCalcApplnRemainingAmount(Rec, ApplnRemainingAmount);
        exit(ApplnRemainingAmount);
    end;

    local procedure CalcApplnAmountToApply(AmountToApply: Decimal): Decimal
    var
        ApplnAmountToApply: Decimal;
    begin
        ValidExchRate := true;

        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(AmountToApply);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnAmountToApply :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, AmountToApply, ValidExchRate);

        OnAfterCalcApplnAmountToApply(Rec, ApplnAmountToApply);
        exit(ApplnAmountToApply);
    end;

    protected procedure FindAmountRounding()
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else
            if ApplnCurrencyCode <> Currency.Code then
                Currency.Get(ApplnCurrencyCode);

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    procedure CheckRounding()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRounding(CalcType, ApplnRounding, IsHandled);
        if IsHandled then
            exit;

        ApplnRounding := 0;

        case CalcType of
            CalcType::"Sales Header", CalcType::"Service Header":
                exit;
            CalcType::"Gen. Jnl. Line":
                if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
                   (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)
                then
                    exit;
        end;

        if ApplnCurrencyCode = '' then
            ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision"
        else begin
            if ApplnCurrencyCode <> Rec."Currency Code" then
                Currency.Get(ApplnCurrencyCode);
            ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
        end;

        if (Abs((AppliedAmount - PmtDiscAmount) + ApplyingAmount) <= ApplnRoundingPrecision) and DifferentCurrenciesInAppln then
            ApplnRounding := -((AppliedAmount - PmtDiscAmount) + ApplyingAmount);
    end;

    procedure GetCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry := Rec;
    end;

    local procedure FindApplyingEntry()
    begin
        if CalcType = CalcType::Direct then begin
            CustEntryApplID := UserId;
            if CustEntryApplID = '' then
                CustEntryApplID := '***';

            CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
            CustLedgEntry.SetRange("Customer No.", Rec."Customer No.");
            if AppliesToID = '' then
                CustLedgEntry.SetRange("Applies-to ID", CustEntryApplID)
            else
                CustLedgEntry.SetRange("Applies-to ID", AppliesToID);
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("Applying Entry", true);
            OnFindFindApplyingEntryOnAfterCustLedgEntrySetFilters(Rec, CustLedgEntry);
            if CustLedgEntry.FindFirst() then begin
                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                TempApplyingCustLedgEntry := CustLedgEntry;
                Rec.SetFilter("Entry No.", '<>%1', CustLedgEntry."Entry No.");
                ApplyingAmount := CustLedgEntry."Remaining Amount";
                ApplnDate := CustLedgEntry."Posting Date";
                ApplnCurrencyCode := CustLedgEntry."Currency Code";
            end;
            OnFindApplyingEntryOnBeforeCalcApplnAmount(Rec);
            CalcApplnAmount();
        end;
    end;

    protected procedure HandleChosenEntries(Type: Enum "Customer Apply Calculation Type"; CurrentAmount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        PossiblePmtDisc: Decimal;
        OldPmtDisc: Decimal;
        CorrectionAmount: Decimal;
        RemainingAmountExclDiscounts: Decimal;
        CanUseDisc: Boolean;
        FromZeroGenJnl: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandledChosenEntries(Type.AsInteger(), CurrentAmount, CurrencyCode, PostingDate, AppliedCustLedgEntry, IsHandled, CustLedgEntry);
        if IsHandled then
            exit;

        if not AppliedCustLedgEntry.FindSet(false) then
            exit;

        repeat
            TempAppliedCustLedgEntry := AppliedCustLedgEntry;
            TempAppliedCustLedgEntry.Insert();
            OnHandleChosenEntriesOnAfterTempAppliedCustLedgEntryInsert(TempAppliedCustLedgEntry);
        until AppliedCustLedgEntry.Next() = 0;

        FromZeroGenJnl := (CurrentAmount = 0) and (Type = Type::"Gen. Jnl. Line");

        repeat
            if not FromZeroGenJnl then
                TempAppliedCustLedgEntry.SetRange(Positive, CurrentAmount < 0);
            if TempAppliedCustLedgEntry.FindFirst() then begin
                ExchangeLedgerEntryAmounts(Type, CurrencyCode, TempAppliedCustLedgEntry, PostingDate);

                case Type of
                    Type::Direct:
                        CanUseDisc := PaymentToleranceMgt.CheckCalcPmtDiscCust(CustLedgEntry, TempAppliedCustLedgEntry, 0, false, false);
                    Type::"Gen. Jnl. Line":
                        CanUseDisc := PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine2, TempAppliedCustLedgEntry, 0, false)
                    else
                        CanUseDisc := false;
                end;

                if CanUseDisc and
                   (Abs(TempAppliedCustLedgEntry."Amount to Apply") >=
                    Abs(TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate)))
                then
                    if Abs(CurrentAmount) >
                       Abs(TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate))
                    then begin
                        PmtDiscAmount += TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                        CurrentAmount += TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                    end else
                        if Abs(CurrentAmount) =
                           Abs(TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate))
                        then begin
                            PmtDiscAmount += TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                            CurrentAmount +=
                              TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                            AppliedAmount += CorrectionAmount;
                        end else
                            if FromZeroGenJnl then begin
                                PmtDiscAmount += TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                                CurrentAmount +=
                                  TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                            end else begin
                                PossiblePmtDisc := TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                                RemainingAmountExclDiscounts :=
                                  TempAppliedCustLedgEntry."Remaining Amount" - PossiblePmtDisc - TempAppliedCustLedgEntry."Max. Payment Tolerance";
                                if Abs(CurrentAmount) + Abs(CalcOppositeEntriesAmount(TempAppliedCustLedgEntry)) >=
                                   Abs(RemainingAmountExclDiscounts)
                                then begin
                                    PmtDiscAmount += PossiblePmtDisc;
                                    AppliedAmount += CorrectionAmount;
                                end;
                                CurrentAmount +=
                                  TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry.GetRemainingPmtDiscPossible(PostingDate);
                            end
                else begin
                    if ((CurrentAmount + TempAppliedCustLedgEntry."Amount to Apply") * CurrentAmount) <= 0 then
                        AppliedAmount += CorrectionAmount;
                    CurrentAmount += TempAppliedCustLedgEntry."Amount to Apply";
                end;
            end else begin
                TempAppliedCustLedgEntry.SetRange(Positive);
                TempAppliedCustLedgEntry.FindFirst();
                ExchangeLedgerEntryAmounts(Type, CurrencyCode, TempAppliedCustLedgEntry, PostingDate);
            end;

            if OldPmtDisc <> PmtDiscAmount then
                AppliedAmount += TempAppliedCustLedgEntry."Remaining Amount"
            else
                AppliedAmount += TempAppliedCustLedgEntry."Amount to Apply";
            OldPmtDisc := PmtDiscAmount;

            if PossiblePmtDisc <> 0 then
                CorrectionAmount := TempAppliedCustLedgEntry."Remaining Amount" - TempAppliedCustLedgEntry."Amount to Apply"
            else
                CorrectionAmount := 0;

            if not DifferentCurrenciesInAppln then
                DifferentCurrenciesInAppln := ApplnCurrencyCode <> TempAppliedCustLedgEntry."Currency Code";

            OnHandleChosenEntriesOnBeforeDeleteTempAppliedCustLedgEntry(Rec, TempAppliedCustLedgEntry, CurrencyCode);
            TempAppliedCustLedgEntry.Delete();
            TempAppliedCustLedgEntry.SetRange(Positive);

        until not TempAppliedCustLedgEntry.FindFirst();
        CheckRounding();
    end;

    local procedure AmountToApplyOnAfterValidate()
    begin
        if ApplnType <> ApplnType::"Applies-to Doc. No." then begin
            CalcApplnAmount();
            CurrPage.Update(false);
        end;
    end;

    local procedure RecalcApplnAmount()
    begin
        CurrPage.Update(true);
        CalcApplnAmount();
    end;

    local procedure LookupOKOnPush()
    begin
        OK := true;

        OnAfterLookupOKOnPush(OK);
    end;

    local procedure PostDirectApplication(PreviewMode: Boolean)
    var
        RecBeforeRunPostApplicationCustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        NewApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PostApplication: Page "Post Application";
        Applied: Boolean;
        ApplicationDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDirectApplication(Rec, PreviewMode, IsHandled, TempApplyingCustLedgEntry);
        if IsHandled then
            exit;

        if CalcType = CalcType::Direct then begin
            if TempApplyingCustLedgEntry."Entry No." <> 0 then begin
                Rec := TempApplyingCustLedgEntry;
                IsTheApplicationValid();
                ApplicationDate := CustEntryApplyPostedEntries.GetApplicationDate(Rec);

                OnPostDirectApplicationBeforeSetValues(ApplicationDate);
                Clear(ApplyUnapplyParameters);
                ApplyUnapplyParameters.CopyFromCustLedgEntry(Rec);
                GLSetup.GetRecordOnce();
                ApplyUnapplyParameters."Posting Date" := ApplicationDate;
                if GLSetup."Journal Templ. Name Mandatory" then begin
                    GLSetup.TestField("Apply Jnl. Template Name");
                    GLSetup.TestField("Apply Jnl. Batch Name");
                    ApplyUnapplyParameters."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
                    ApplyUnapplyParameters."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
                end;
                PostApplication.SetParameters(ApplyUnapplyParameters);
                RecBeforeRunPostApplicationCustLedgerEntry := Rec;
                if ACTION::OK = PostApplication.RunModal() then begin
                    if Rec."Entry No." <> RecBeforeRunPostApplicationCustLedgerEntry."Entry No." then
                        Rec := RecBeforeRunPostApplicationCustLedgerEntry;
                    PostApplication.GetParameters(NewApplyUnapplyParameters);
                    if NewApplyUnapplyParameters."Posting Date" < ApplicationDate then
                        Error(ApplicationDateErr, Rec.FieldCaption("Posting Date"), Rec.TableCaption());
                end else
                    exit;

                OnPostDirectApplicationBeforeApply(GLSetup, NewApplyUnapplyParameters);
                if PreviewMode then
                    CustEntryApplyPostedEntries.PreviewApply(Rec, NewApplyUnapplyParameters)
                else
                    Applied := CustEntryApplyPostedEntries.Apply(Rec, NewApplyUnapplyParameters);

                if (not PreviewMode) and Applied then begin
                    Message(ApplicationPostedMsg);
                    PostingDone := true;
                    CurrPage.Close();
                end;
            end else
                Error(MustSelectEntryErr);
        end else
            Error(PostingInWrongContextErr);
    end;

    procedure SetAppliesToID(AppliesToID2: Code[50])
    begin
        AppliesToID := AppliesToID2;
    end;

    procedure ExchangeLedgerEntryAmounts(Type: Enum "Customer Apply Calculation Type"; CurrencyCode: Code[10]; var CalcCustLedgEntry: Record "Cust. Ledger Entry"; PostingDate: Date)
    var
        CalculateCurrency, IsHandled : Boolean;
    begin
        CalcCustLedgEntry.CalcFields("Remaining Amount");

        if Type = Type::Direct then
            CalculateCurrency := TempApplyingCustLedgEntry."Entry No." <> 0
        else
            CalculateCurrency := true;

        IsHandled := false;
        OnExchangeLedgerEntryAmountsOnBeforeCalculateAmounts(CalcCustLedgEntry, CustLedgEntry, CurrencyCode, CalculateCurrency, IsHandled);
        if IsHandled then
            exit;

        if (CurrencyCode <> CalcCustLedgEntry."Currency Code") and CalculateCurrency then begin
            CalcCustLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                CalcCustLedgEntry."Remaining Amount", CalcCustLedgEntry."Currency Code", CurrencyCode, PostingDate);
            CalcCustLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                CalcCustLedgEntry."Remaining Pmt. Disc. Possible", CalcCustLedgEntry."Currency Code", CurrencyCode, PostingDate);
            CalcCustLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                CalcCustLedgEntry."Amount to Apply", CalcCustLedgEntry."Currency Code", CurrencyCode, PostingDate);
        end;

        OnAfterExchangeLedgerEntryAmounts(CalcCustLedgEntry, CustLedgEntry, CurrencyCode);
    end;

    local procedure IsTheApplicationValid()
    var
        ApplyToCustLedgEntry: Record "Cust. Ledger Entry";
        IsFirst, IsPositiv, ThereAreEntriesToApply : boolean;
        Counter: Integer;
        AllEntriesHaveTheSameSignErr: Label 'All entries have the same sign this will not lead to an application. Update the application by including entries with opposite sign.';
    begin
        IsFirst := true;
        ThereAreEntriesToApply := false;
        Counter := 0;
        ApplyToCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID");
        ApplyToCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        ApplyToCustLedgEntry.SetRange("Applies-to ID", CustLedgEntry."Applies-to ID");
        if ApplyToCustLedgEntry.FindSet() then
            repeat
                if not IsFirst then
                    ThereAreEntriesToApply := (IsPositiv <> ApplyToCustLedgEntry.Positive)
                else
                    IsPositiv := ApplyToCustLedgEntry.Positive;
                IsFirst := false;
                Counter += 1;
            until (ApplyToCustLedgEntry.next() = 0) or ThereAreEntriesToApply;
        if not ThereAreEntriesToApply and (Counter > 1) then
            error(AllEntriesHaveTheSameSignErr)
    end;

    local procedure ActivateFields()
    begin
        CalledFromEntry := CalcType = CalcType::Direct;
        AppliesToIDVisible := ApplnType <> ApplnType::"Applies-to Doc. No.";
    end;

    procedure CalcOppositeEntriesAmount(var TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary) Result: Decimal
    var
        SavedAppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        CurrPosFilter: Text;
    begin
        CurrPosFilter := TempAppliedCustLedgerEntry.GetFilter(Positive);
        if CurrPosFilter <> '' then begin
            SavedAppliedCustLedgerEntry := TempAppliedCustLedgerEntry;
            TempAppliedCustLedgerEntry.SetRange(Positive, not TempAppliedCustLedgerEntry.Positive);
            if TempAppliedCustLedgerEntry.FindSet() then
                repeat
                    TempAppliedCustLedgerEntry.CalcFields("Remaining Amount");
                    Result += TempAppliedCustLedgerEntry."Remaining Amount";
                until TempAppliedCustLedgerEntry.Next() = 0;
            TempAppliedCustLedgerEntry.SetFilter(Positive, CurrPosFilter);
            TempAppliedCustLedgerEntry := SavedAppliedCustLedgerEntry;
        end;
    end;

    procedure GetApplnCurrencyCode(): Code[10]
    begin
        exit(ApplnCurrencyCode);
    end;

    procedure GetCalcType(): Integer
    begin
        exit(CalcType.AsInteger());
    end;

    procedure SetCalcType(NewCalcType: Enum "Customer Apply Calculation Type")
    begin
        CalcType := NewCalcType;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcApplnAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var CalcType: Enum "Customer Apply Calculation Type"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnAmountToApply(CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplnAmountToApply: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnRemainingAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplnRemainingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExchangeLedgerEntryAmounts(var CalcCustLedgEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetAppliesToID(CalcType: Enum "Customer Apply Calculation Type"; var AppliesToID: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupOKOnPush(var OK: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplyingCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetApplyingCustLedgEntry(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcApplnAmount(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; ServHeader: Record "Service Header"; var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; CalculationType: Option; ApplicationType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRounding(CalcType: Enum "Customer Apply Calculation Type"; var ApplnRounding: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeHandledChosenEntries(Type: Option Direct,GenJnlLine,SalesHeader; CurrentAmount: Decimal; CurrencyCode: Code[10]; PostingDate: Date; var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEarlierPostingDateError(ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var RaiseError: Boolean; CalcType: Option; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDirectApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; PreviewMode: Boolean; var IsHandled: Boolean; var ApplyingCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetApplyingCustLedgEntry(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var ServHeader: Record "Service Header"; var CalcType: Enum "Customer Apply Calculation Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustEntryApplID(CustLedgerEntry: Record "Cust. Ledger Entry"; CurrentRec: Boolean; var ApplyingAmount: Decimal; var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]; var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplnAmountOnCalcTypeGenJnlLineOnApplnTypeToDocNoOnBeforeSetAppliedAmount(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustLedgEntryOnBeforeCheckAgainstApplnCurrency(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var TempApplyingCustLedgEntry: Record "Cust. Ledger Entry" temporary; CalcType: Enum "Customer Apply Calculation Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplnAmountOnCalcTypeGenJnlLineOnApplnTypeToDocNoOnAfterSetAppliedAmount(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10]; var AppliedAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplnAmountOnCalcTypeSalesHeaderOnApplnTypeToDocNoOnBeforeSetAppliedAmount(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFindApplyingEntryOnAfterCustLedgEntrySetFilters(ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindApplyingEntryOnBeforeCalcApplnAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnHandleChosenEntriesOnAfterTempAppliedCustLedgEntryInsert(var TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleChosenEntriesOnBeforeDeleteTempAppliedCustLedgEntry(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetCustApplIdAfterCheckAgainstApplnCurrency(var CustLedgerEntry: Record "Cust. Ledger Entry"; CalcType: Option; var GenJnlLine: Record "Gen. Journal Line"; ServHeader: Record "Service Header"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnSetApplyingCustLedgEntryOnBeforeCalcTypeDirectCalcApplnAmount(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplyingAmount: Decimal; var TempApplyingCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;
#endif
    [IntegrationEvent(true, false)]
    local procedure OnOnQueryClosePageOnBeforeRunCustEntryEdit(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDirectApplicationBeforeSetValues(var ApplicationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDirectApplicationBeforeApply(GLSetup: Record "General Ledger Setup"; var NewApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyingCustLedgEntryServiceHeader(var TempApplyingCustLedgEntry: Record "Cust. Ledger Entry" temporary; var ServiceHeader: Record "Service Header")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyingCustLedgEntryGenJnlLine(var TempApplyingCustLedgEntry: Record "Cust. Ledger Entry" temporary; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnExchangeLedgerEntryAmountsOnBeforeCalculateAmounts(var CalcCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; CalculateCurrency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustLedgEntryOnAfterEarlierPostingDateTest(ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; CalcType: Enum "Customer Apply Calculation Type"; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnAfterEarlierPostingDateTest(ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; CalcType: Enum "Customer Apply Calculation Type"; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustLedgEntryOnBeforeCheckAgainstApplnCurrencyWhenEntryNoIsNotNull(CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
