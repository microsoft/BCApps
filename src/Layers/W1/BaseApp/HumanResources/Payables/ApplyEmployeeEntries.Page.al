// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.CRM.Outlook;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Payables;

page 234 "Apply Employee Entries"
{
    Caption = 'Apply Employee Entries';
    DataCaptionFields = "Employee No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "Employee Ledger Entry" = m;
    SourceTable = "Employee Ledger Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
#pragma warning disable AA0204
#pragma warning disable AA0100
                field("TempApplyingEmplLedgEntry.""Posting Date"""; TempApplyingEmplLedgEntry."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Document Type"""; TempApplyingEmplLedgEntry."Document Type")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type of the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Document No."""; TempApplyingEmplLedgEntry."Document No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
#pragma warning restore AA0100
                field(ApplyingEmployeeNo; TempApplyingEmplLedgEntry."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Employee No.';
                    Editable = false;
                    ToolTip = 'Specifies the employee number of the entry to be applied.';
                    Visible = false;
                }
                field(ApplyingDescription; TempApplyingEmplLedgEntry.Description)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry to be applied.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("TempApplyingEmplLedgEntry.""Currency Code"""; TempApplyingEmplLedgEntry."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field("TempApplyingEmplLedgEntry.Amount"; TempApplyingEmplLedgEntry.Amount)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
                field("TempApplyingEmplLedgEntry.""Remaining Amount"""; TempApplyingEmplLedgEntry."Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
#pragma warning restore AA0100
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = AppliesToIDVisible;
                    trigger OnValidate()
                    begin
                        if Rec."Applies-to ID" <> '' then
                            UpdateCustomAppliesToIDForGenJournal(Rec."Applies-to ID");
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s document number.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the employee account that the entry is linked to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies a description of the employee entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original entry.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry.';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
#pragma warning disable AA0100
                field("CalcApplnRemainingAmount(""Remaining Amount"")"; CalcApplnRemainingAmount(Rec."Remaining Amount"))
                {
                    ApplicationArea = BasicHR;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
#pragma warning restore AA0100
                field("Amount to Apply"; Rec."Amount to Apply")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount to apply.';

                    trigger OnValidate()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);

                        if (xRec."Amount to Apply" = 0) or (Rec."Amount to Apply" = 0) and
                           ((ApplnType = ApplnType::"Applies-to ID") or (CalcType = CalcType::Direct))
                        then
                            SetEmplApplId();
                        Rec.Get(Rec."Entry No.");
                        AmounttoApplyOnAfterValidate();
                    end;
                }
#pragma warning disable AA0100
                field("CalcApplnAmounttoApply(""Amount to Apply"")"; CalcApplnAmounttoApply(Rec."Amount to Apply"))
                {
                    ApplicationArea = BasicHR;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Amount to Apply';
                    ToolTip = 'Specifies the amount to apply.';
                }
#pragma warning restore AA0100
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment to the employee.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies if the entry to be applied is positive.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
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
                            ApplicationArea = BasicHR;
                            Editable = false;
                            ShowCaption = false;
                            TableRelation = Currency;
                            ToolTip = 'Specifies the currency code that the amount will be applied in, in case of different currencies.';
                        }
                    }
                    group(Control1900545201)
                    {
                        Caption = 'Amount to Apply';
                        field(AmountToApply; AppliedAmount)
                        {
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Amount to Apply';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts on all the selected employee ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group(Rounding)
                    {
                        Caption = 'Rounding';
                        field(ApplnRounding; ApplnRounding)
                        {
                            ApplicationArea = BasicHR;
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
                            ApplicationArea = BasicHR;
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
                            ApplicationArea = BasicHR;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Available Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the journal entry, purchase credit memo, or current employee ledger entry that you have selected as the applying entry.';
                        }
                    }
                    group(Balance)
                    {
                        Caption = 'Balance';
                        field(ControlBalance; AppliedAmount + (-PmtDiscAmount) + ApplyingAmount + ApplnRounding)
                        {
                            ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Employee Entries";
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
                    ApplicationArea = BasicHR;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Empl. Ledger Entries";
                    RunPageLink = "Employee Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Employee Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of all the posted entries and adjustments related to a specific employee ledger entry.';
                }
                action(Navigate)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    Visible = not IsOfficeAddin;

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
                action(ActionSetAppliesToID)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Set the Applies-to ID field on the posted entry to automatically be filled in with the document number of the entry in the journal.';

                    trigger OnAction()
                    begin
                        if (CalcType = CalcType::"Gen. Jnl. Line") and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetEmplApplId();
                    end;
                }
                action(ActionPostApplication)
                {
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
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
                    ApplicationArea = BasicHR;
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
                                EmplEntryApplID := CopyStr(UserId(), 1, 50);
                                if EmplEntryApplID = '' then
                                    EmplEntryApplID := '***';
                                Rec.SetRange("Applies-to ID", EmplEntryApplID);
                            end
                        else
                            Rec.SetRange("Applies-to ID");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ActionSetAppliesToID_Promoted; ActionSetAppliesToID)
                {
                }
                actionref(ActionPostApplication_Promoted; ActionPostApplication)
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref("Show Only Selected Entries to Be Applied_Promoted"; "Show Only Selected Entries to Be Applied")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

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
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ApplnType = ApplnType::"Applies-to Doc. No." then
            CalcApplnAmount();
    end;

    trigger OnInit()
    begin
        AppliesToIDVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
        if Rec."Applies-to ID" <> xRec."Applies-to ID" then
            CalcApplnAmount();
        exit(false);
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        if CalcType = CalcType::Direct then begin
            Empl.Get(Rec."Employee No.");
            ApplnCurrencyCode := Empl."Currency Code";
            FindApplyingEntry();
        end;

        AppliesToIDVisible := ApplnType <> ApplnType::"Applies-to Doc. No.";

        GLSetup.Get();

        if CalcType = CalcType::"Gen. Jnl. Line" then
            CalcApplnAmount();
        PostingDone := false;
        IsOfficeAddin := OfficeMgt.IsAvailable();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
        if ApplnType = ApplnType::"Applies-to Doc. No." then begin
            CheckEarlierPostingDate();
            if OK then begin
                if Rec."Amount to Apply" = 0 then
                    Rec."Amount to Apply" := Rec."Remaining Amount";
                CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
            end;
        end;

        if CheckActionPerformed() then begin
            Rec := TempApplyingEmplLedgEntry;
            Rec."Applying Entry" := false;
            if AppliesToID = '' then begin
                Rec."Applies-to ID" := '';
                Rec."Amount to Apply" := 0;
            end;
            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
        end;
    end;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        Empl: Record Employee;
        GLSetup: Record "General Ledger Setup";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        Navigate: Page Navigate;
        GenJnlLineApply: Boolean;
        EmplEntryApplID: Code[50];
        AppliesToID: Code[50];
        CustomAppliesToID: Code[50];
        TimesSetCustomAppliesToID: Integer;
        ValidExchRate: Boolean;
        MustSelectEntryErr: Label 'You must select an applying entry before you can post the application.';
        PostingInWrongContextErr: Label 'You must post the application from the window where you entered the applying entry.';
        CannotSetAppliesToIDErr: Label 'You cannot set Applies-to ID field while selecting Applies-to Doc. No field.';
        ShowAppliedEntries: Boolean;
        OK: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.\\Instead, post the document of type %1 with the number %2 and then apply it to the document of type %3 with the number %4.', Comment = '%1 - document type, %2 - document number,%3 - document type,%4 - document number';
        PostingDone: Boolean;
        AppliesToIDVisible: Boolean;
        ActionPerformed: Boolean;
        ApplicationPostedMsg: Label 'The application was successfully posted.';
        ApplicationDateErr: Label 'The posting date entered must not be before the posting date on the employee ledger entry.';
        ApplicationProcessCanceledErr: Label 'Post application process has been canceled.';
        IsOfficeAddin: Boolean;

    protected var
        TempApplyingEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        AppliedEmplLedgEntry: Record "Employee Ledger Entry";
        GenJnlLine2: Record "Gen. Journal Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
        ApplnDate: Date;
        ApplnRoundingPrecision: Decimal;
        ApplnRounding: Decimal;
        ApplnType: Enum "Vendor Apply-to Type";
        AmountRoundingPrecision: Decimal;
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        PmtDiscAmount: Decimal;
        ApplnCurrencyCode: Code[10];
        DifferentCurrenciesInAppln: Boolean;
        CalcType: Enum "Vendor Apply Calculation Type";

    local procedure CheckEarlierPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEarlierPostingDate(TempApplyingEmplLedgEntry, Rec, CalcType.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        if OK and (TempApplyingEmplLedgEntry."Posting Date" < Rec."Posting Date") then begin
            OK := false;
            Error(
              EarlierPostingDateErr, TempApplyingEmplLedgEntry."Document Type", TempApplyingEmplLedgEntry."Document No.",
              Rec."Document Type", Rec."Document No.");
        end;
    end;

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line"; ApplnTypeSelect: Integer)
    begin
        GenJnlLine := NewGenJnlLine;
        GenJnlLineApply := true;

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then
            ApplyingAmount := GenJnlLine.Amount;
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then
            ApplyingAmount := -GenJnlLine.Amount;
        ApplnDate := GenJnlLine."Posting Date";
        ApplnCurrencyCode := GenJnlLine."Currency Code";
        CalcType := CalcType::"Gen. Jnl. Line";

        case ApplnTypeSelect of
            GenJnlLine.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            GenJnlLine.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        SetApplyingEmplLedgEntry();
    end;

    procedure SetEmplLedgEntry(NewEmplLedgEntry: Record "Employee Ledger Entry")
    begin
        Rec := NewEmplLedgEntry;
    end;

    procedure SetApplyingEmplLedgEntry()
    var
        Employee: Record Employee;
    begin
        OnBeforeSetApplyingEmplLedgEntry(TempApplyingEmplLedgEntry, GenJnlLine);
        case CalcType of
            CalcType::Direct:
                begin
                    if Rec."Applying Entry" then begin
                        if TempApplyingEmplLedgEntry."Entry No." <> 0 then
                            EmplLedgEntry := TempApplyingEmplLedgEntry;
                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", Rec);
                        if Rec."Applies-to ID" = '' then
                            SetEmplApplId();
                        Rec.CalcFields(Amount);
                        TempApplyingEmplLedgEntry := Rec;
                        if EmplLedgEntry."Entry No." <> 0 then begin
                            Rec := EmplLedgEntry;
                            Rec."Applying Entry" := false;
                            SetEmplApplId();
                        end;
                        Rec.SetFilter("Entry No.", '<> %1', TempApplyingEmplLedgEntry."Entry No.");
                        ApplyingAmount := TempApplyingEmplLedgEntry."Remaining Amount";
                        ApplnDate := TempApplyingEmplLedgEntry."Posting Date";
                        ApplnCurrencyCode := TempApplyingEmplLedgEntry."Currency Code";
                    end;
                    CalcApplnAmount();
                end;
            CalcType::"Gen. Jnl. Line":
                begin
                    TempApplyingEmplLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                    TempApplyingEmplLedgEntry."Document Type" := GenJnlLine."Document Type";
                    TempApplyingEmplLedgEntry."Document No." := GenJnlLine."Document No.";
                    if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then begin
                        TempApplyingEmplLedgEntry."Employee No." := GenJnlLine."Bal. Account No.";
                        Employee.Get(TempApplyingEmplLedgEntry."Employee No.");
                        TempApplyingEmplLedgEntry.Description := CopyStr(Employee.FullName(), 1, MaxStrLen(TempApplyingEmplLedgEntry.Description));
                    end else begin
                        TempApplyingEmplLedgEntry."Employee No." := GenJnlLine."Account No.";
                        TempApplyingEmplLedgEntry.Description := GenJnlLine.Description;
                    end;
                    TempApplyingEmplLedgEntry."Currency Code" := GenJnlLine."Currency Code";
                    TempApplyingEmplLedgEntry.Amount := GenJnlLine.Amount;
                    TempApplyingEmplLedgEntry."Remaining Amount" := GenJnlLine.Amount;
                    CalcApplnAmount();
                end;
        end;
    end;

    procedure SetEmplApplId()
    begin
        CurrPage.SetSelectionFilter(EmplLedgEntry);
        CheckEmplApplId(EmplLedgEntry);

        if TempApplyingEmplLedgEntry."Entry No." <> 0 then
            GenJnlApply.CheckAgainstApplnCurrency(
              ApplnCurrencyCode, Rec."Currency Code", GenJnlLine."Account Type"::Employee, true);
        OnSetCustApplIdAfterCheckAgainstApplnCurrency(Rec, CalcType.AsInteger(), GenJnlLine);

        EmplLedgEntry.Copy(Rec);
        CurrPage.SetSelectionFilter(EmplLedgEntry);

        if GenJnlLineApply then
            EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempApplyingEmplLedgEntry, GenJnlLine."Applies-to ID")
        else
            EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempApplyingEmplLedgEntry, '');

        ActionPerformed := EmplLedgEntry."Applies-to ID" <> '';
        CalcApplnAmount();
    end;

    procedure CheckEmplApplId(var EmplLedgerEntry: Record "Employee Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        if EmplLedgerEntry.FindSet() then
            repeat
                if CalcType = CalcType::"Gen. Jnl. Line" then begin
                    RaiseError := TempApplyingEmplLedgEntry."Posting Date" < EmplLedgerEntry."Posting Date";
                    OnCheckEmplApplIdOnBeforeEarlierPostingDateError(TempApplyingEmplLedgEntry, EmplLedgerEntry, RaiseError, CalcType);
                    if RaiseError then
                        Error(
                            EarlierPostingDateErr, TempApplyingEmplLedgEntry."Document Type", TempApplyingEmplLedgEntry."Document No.",
                            EmplLedgerEntry."Document Type", EmplLedgerEntry."Document No.");
                end;
            until EmplLedgerEntry.Next() = 0;
    end;

    protected procedure CalcApplnAmount()
    begin
        OnBeforeCalcApplnAmount(Rec, GenJnlLine, AppliedEmplLedgEntry, CalcType.AsInteger(), ApplnType.AsInteger());

        AppliedAmount := 0;
        PmtDiscAmount := 0;
        DifferentCurrenciesInAppln := false;

        case CalcType of
            CalcType::Direct:
                begin
                    FindAmountRounding();
                    EmplEntryApplID := CopyStr(UserId(), 1, 50);
                    if EmplEntryApplID = '' then
                        EmplEntryApplID := '***';

                    EmplLedgEntry := TempApplyingEmplLedgEntry;

                    AppliedEmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
                    AppliedEmplLedgEntry.SetRange("Employee No.", Rec."Employee No.");
                    AppliedEmplLedgEntry.SetRange(Open, true);
                    if AppliesToID = '' then
                        AppliedEmplLedgEntry.SetRange("Applies-to ID", EmplEntryApplID)
                    else
                        AppliedEmplLedgEntry.SetRange("Applies-to ID", AppliesToID);

                    if TempApplyingEmplLedgEntry."Entry No." <> 0 then begin
                        EmplLedgEntry.CalcFields("Remaining Amount");
                        AppliedEmplLedgEntry.SetFilter("Entry No.", '<>%1', EmplLedgEntry."Entry No.");
                    end;

                    HandleChosenEntries(0, EmplLedgEntry."Remaining Amount", EmplLedgEntry."Currency Code", EmplLedgEntry."Posting Date");
                end;
            CalcType::"Gen. Jnl. Line":
                begin
                    FindAmountRounding();
                    if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

                    case ApplnType of
                        ApplnType::"Applies-to Doc. No.":
                            begin
                                AppliedEmplLedgEntry := Rec;
                                AppliedEmplLedgEntry.CalcFields("Remaining Amount");
                                if AppliedEmplLedgEntry."Currency Code" <> ApplnCurrencyCode then begin
                                    AppliedEmplLedgEntry."Remaining Amount" :=
                                      CurrExchRate.ExchangeAmtFCYToFCY(
                                        ApplnDate, AppliedEmplLedgEntry."Currency Code", ApplnCurrencyCode, AppliedEmplLedgEntry."Remaining Amount");
                                    AppliedEmplLedgEntry."Amount to Apply" :=
                                      CurrExchRate.ExchangeAmtFCYToFCY(
                                        ApplnDate, AppliedEmplLedgEntry."Currency Code", ApplnCurrencyCode, AppliedEmplLedgEntry."Amount to Apply");
                                end;

                                if AppliedEmplLedgEntry."Amount to Apply" <> 0 then
                                    AppliedAmount := Round(AppliedEmplLedgEntry."Amount to Apply", AmountRoundingPrecision)
                                else
                                    AppliedAmount := Round(AppliedEmplLedgEntry."Remaining Amount", AmountRoundingPrecision);

                                if not DifferentCurrenciesInAppln then
                                    DifferentCurrenciesInAppln := ApplnCurrencyCode <> AppliedEmplLedgEntry."Currency Code";
                                CheckRounding();
                            end;
                        ApplnType::"Applies-to ID":
                            begin
                                GenJnlLine2 := GenJnlLine;
                                AppliedEmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
                                AppliedEmplLedgEntry.SetRange("Employee No.", GenJnlLine."Account No.");
                                AppliedEmplLedgEntry.SetRange(Open, true);
                                AppliedEmplLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

                                HandleChosenEntries(1, GenJnlLine2.Amount, GenJnlLine2."Currency Code", GenJnlLine2."Posting Date");
                            end;
                    end;
                end;
        end;

        OnAfterCalcApplnAmount(Rec, AppliedAmount, ApplyingAmount);
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

    local procedure CalcApplnRemainingAmount(Amt: Decimal) ApplnRemainingAmount: Decimal
    begin
        ValidExchRate := true;
        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(Amt);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnRemainingAmount :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, Amt, ValidExchRate);

        OnAfterCalcApplnRemainingAmount(Rec, ApplnRemainingAmount);
    end;

    local procedure CalcApplnAmounttoApply(AmounttoApply: Decimal) ApplnAmountToApply: Decimal
    begin
        ValidExchRate := true;

        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(AmounttoApply);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnAmountToApply :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, AmounttoApply, ValidExchRate);

        OnAfterCalcApplnAmountToApply(Rec, ApplnAmountToApply);
    end;

    local procedure FindAmountRounding()
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

    protected procedure CheckRounding()
    begin
        ApplnRounding := 0;

        case CalcType of
            CalcType::"Purchase Header":
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

    procedure GetEmplLedgEntry(var EmplLedgEntry2: Record "Employee Ledger Entry")
    begin
        EmplLedgEntry2 := Rec;
    end;

    local procedure FindApplyingEntry()
    begin
        if CalcType = CalcType::Direct then begin
            EmplEntryApplID := CopyStr(UserId(), 1, 50);
            if EmplEntryApplID = '' then
                EmplEntryApplID := '***';

            EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
            EmplLedgEntry.SetRange("Employee No.", Rec."Employee No.");
            if AppliesToID = '' then
                EmplLedgEntry.SetRange("Applies-to ID", EmplEntryApplID)
            else
                EmplLedgEntry.SetRange("Applies-to ID", AppliesToID);
            EmplLedgEntry.SetRange(Open, true);
            EmplLedgEntry.SetRange("Applying Entry", true);
            OnFindFindApplyingEntryOnAfterEmplLedgEntrySetFilters(Rec, EmplLedgEntry);
            if EmplLedgEntry.FindFirst() then begin
                EmplLedgEntry.CalcFields(Amount, "Remaining Amount");
                TempApplyingEmplLedgEntry := EmplLedgEntry;
                Rec.SetFilter("Entry No.", '<>%1', EmplLedgEntry."Entry No.");
                ApplyingAmount := EmplLedgEntry."Remaining Amount";
                ApplnDate := EmplLedgEntry."Posting Date";
                ApplnCurrencyCode := EmplLedgEntry."Currency Code";
            end;
            CalcApplnAmount();
        end;
    end;

    local procedure AmounttoApplyOnAfterValidate()
    begin
        if ApplnType <> ApplnType::"Applies-to Doc. No." then begin
            CalcApplnAmount();
            CurrPage.Update(false);
        end;
    end;

    local procedure LookupOKOnPush()
    begin
        OK := true;
    end;

    local procedure PostDirectApplication(PreviewMode: Boolean)
    var
        RecBeforeRunPostApplicationEmployeeLedgerEntry: Record "Employee Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        NewApplyUnapplyParameters: Record "Apply Unapply Parameters";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
        PostApplication: Page "Post Application";
        ApplicationDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDirectApplication(Rec, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        if CalcType = CalcType::Direct then begin
            if TempApplyingEmplLedgEntry."Entry No." <> 0 then begin
                Rec := TempApplyingEmplLedgEntry;
                IsTheApplicationValid();
                ApplicationDate := EmplEntryApplyPostedEntries.GetApplicationDate(Rec);

                OnPostDirectApplicationBeforeSetValues(ApplicationDate);
                Clear(ApplyUnapplyParameters);
                ApplyUnapplyParameters.CopyFromEmplLedgEntry(Rec);
                GLSetup.GetRecordOnce();
                ApplyUnapplyParameters."Posting Date" := ApplicationDate;
                if GLSetup."Journal Templ. Name Mandatory" then begin
                    GLSetup.TestField("Apply Jnl. Template Name");
                    GLSetup.TestField("Apply Jnl. Batch Name");
                    ApplyUnapplyParameters."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
                    ApplyUnapplyParameters."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
                end;
                PostApplication.SetParameters(ApplyUnapplyParameters);
                RecBeforeRunPostApplicationEmployeeLedgerEntry := Rec;
                if ACTION::OK = PostApplication.RunModal() then begin
                    if Rec."Entry No." <> RecBeforeRunPostApplicationEmployeeLedgerEntry."Entry No." then
                        Rec := RecBeforeRunPostApplicationEmployeeLedgerEntry;
                    PostApplication.GetParameters(NewApplyUnapplyParameters);
                    if NewApplyUnapplyParameters."Posting Date" < ApplicationDate then
                        Error(ApplicationDateErr);
                end else
                    Error(ApplicationProcessCanceledErr);

                OnPostDirectApplicationBeforeApply(GLSetup, NewApplyUnapplyParameters);
                if PreviewMode then
                    EmplEntryApplyPostedEntries.PreviewApply(Rec, NewApplyUnapplyParameters)
                else
                    EmplEntryApplyPostedEntries.Apply(Rec, NewApplyUnapplyParameters);

                if not PreviewMode then begin
                    Message(ApplicationPostedMsg);
                    PostingDone := true;
                    CurrPage.Close();
                end;
            end else
                Error(MustSelectEntryErr);
        end else
            Error(PostingInWrongContextErr);
    end;

    local procedure CheckActionPerformed(): Boolean
    begin
        if ActionPerformed then
            exit(false);
        if (not (CalcType = CalcType::Direct) and not OK and not PostingDone) or
           (ApplnType = ApplnType::"Applies-to Doc. No.")
        then
            exit(false);
        exit(CalcType = CalcType::Direct);
    end;

    procedure SetAppliesToID(AppliesToID2: Code[50])
    begin
        AppliesToID := AppliesToID2;
    end;

    local procedure HandleChosenEntries(Type: Option Direct,GenJnlLine; CurrentAmount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        TempAppliedEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        CorrectionAmount: Decimal;
        FromZeroGenJnl: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandledChosenEntries(Type, CurrentAmount, CurrencyCode, AppliedEmplLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CorrectionAmount := 0;
        if AppliedEmplLedgEntry.FindSet(false) then
            repeat
                TempAppliedEmplLedgEntry := AppliedEmplLedgEntry;
                TempAppliedEmplLedgEntry.Insert();
            until AppliedEmplLedgEntry.Next() = 0
        else
            exit;

        FromZeroGenJnl := (CurrentAmount = 0) and (Type = Type::GenJnlLine);

        repeat
            if not FromZeroGenJnl then
                TempAppliedEmplLedgEntry.SetRange(Positive, CurrentAmount < 0);
            if TempAppliedEmplLedgEntry.FindFirst() then begin
                ExchangeLedgerEntryAmounts(Type, CurrencyCode, TempAppliedEmplLedgEntry, PostingDate);
                if ((CurrentAmount + TempAppliedEmplLedgEntry."Amount to Apply") * CurrentAmount) >= 0 then
                    AppliedAmount := AppliedAmount + CorrectionAmount;
                CurrentAmount := CurrentAmount + TempAppliedEmplLedgEntry."Amount to Apply";
            end else begin
                TempAppliedEmplLedgEntry.SetRange(Positive);
                TempAppliedEmplLedgEntry.FindFirst();
            end;

            AppliedAmount := AppliedAmount + TempAppliedEmplLedgEntry."Amount to Apply";

            TempAppliedEmplLedgEntry.Delete();
            TempAppliedEmplLedgEntry.SetRange(Positive);

        until not TempAppliedEmplLedgEntry.FindFirst();
        CheckRounding();
    end;

    local procedure IsTheApplicationValid()
    var
        ApplyToEmployeeLedgerEntry: Record "Employee Ledger Entry";
        IsFirst, IsPositiv, ThereAreEntriesToApply : boolean;
        Counter: Integer;
        AllEntriesHaveTheSameSignErr: Label 'All entries have the same sign this will not lead top an application. Update the application by including entries with opposite sign.';
    begin
        IsFirst := true;
        ThereAreEntriesToApply := false;
        Counter := 0;
        ApplyToEmployeeLedgerEntry.SetCurrentKey("Employee No.", "Applies-to ID");
        ApplyToEmployeeLedgerEntry.SetRange("Employee No.", EmplLedgEntry."Employee No.");
        ApplyToEmployeeLedgerEntry.SetRange("Applies-to ID", EmplLedgEntry."Applies-to ID");
        if ApplyToEmployeeLedgerEntry.FindSet() then
            repeat
                if not IsFirst then
                    ThereAreEntriesToApply := (IsPositiv <> ApplyToEmployeeLedgerEntry.Positive)
                else
                    IsPositiv := ApplyToEmployeeLedgerEntry.Positive;
                IsFirst := false;
                Counter += 1;
            until (ApplyToEmployeeLedgerEntry.next() = 0) or ThereAreEntriesToApply;
        if not ThereAreEntriesToApply and (Counter > 1) then
            error(AllEntriesHaveTheSameSignErr)
    end;

    protected procedure ExchangeLedgerEntryAmounts(Type: Option Direct,GenJnlLine; CurrencyCode: Code[10]; var CalcEmplLedgEntry: Record "Employee Ledger Entry"; PostingDate: Date)
    var
        CalculateCurrency: Boolean;
        IsHandled: Boolean;
    begin
        CalcEmplLedgEntry.CalcFields("Remaining Amount");

        if Type = Type::Direct then
            CalculateCurrency := TempApplyingEmplLedgEntry."Entry No." <> 0
        else
            CalculateCurrency := true;

        OnBeforeExchangeLedgerEntryAmounts(CalcEmplLedgEntry, EmplLedgEntry, CurrencyCode, CalculateCurrency, IsHandled);
        if IsHandled then
            exit;

        if (CurrencyCode <> CalcEmplLedgEntry."Currency Code") and CalculateCurrency then begin
            CalcEmplLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                CalcEmplLedgEntry."Remaining Amount", CalcEmplLedgEntry."Currency Code", CurrencyCode, PostingDate);
            CalcEmplLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                CalcEmplLedgEntry."Amount to Apply", CalcEmplLedgEntry."Currency Code", CurrencyCode, PostingDate);
        end;

        OnAfterExchangeLedgerEntryAmounts(CalcEmplLedgEntry, EmplLedgEntry, CurrencyCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnAmount(EmplLedgerEntry: Record "Employee Ledger Entry"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnAmountToApply(EmplLedgerEntry: Record "Employee Ledger Entry"; var ApplnAmountToApply: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnRemainingAmount(EmplLedgerEntry: Record "Employee Ledger Entry"; var ApplnRemainingAmount: Decimal)
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
    local procedure OnBeforeCalcApplnAmount(var EmplLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; var AppliedEmplLedgerEntry: Record "Employee Ledger Entry"; CalculationType: Option; ApplicationType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEarlierPostingDate(var TempApplyingEmplLedgEntry: Record "Employee Ledger Entry" temporary; EmplLedgerEntry: Record "Employee Ledger Entry"; CalcType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeHandledChosenEntries(Type: Option Direct,GenJnlLine; CurrentAmount: Decimal; CurrencyCode: Code[10]; var AppliedEmplLedgerEntry: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDirectApplication(var EmplLedgerEntry: Record "Employee Ledger Entry"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetApplyingEmplLedgEntry(var ApplyingEmplLedgEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFindApplyingEntryOnAfterEmplLedgEntrySetFilters(ApplyingEmplLedgerEntry: Record "Employee Ledger Entry"; var EmplLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetCustApplIdAfterCheckAgainstApplnCurrency(var EmplLedgerEntry: Record "Employee Ledger Entry"; CalcType: Option; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExchangeLedgerEntryAmounts(var CalcEmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry"; CurrencyCode: Code[10]; CalculateCurrency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExchangeLedgerEntryAmounts(var CalcEmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry"; CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckEmplApplIdOnBeforeEarlierPostingDateError(var ApplyingEmplLedgEntry: Record "Employee Ledger Entry"; EmplLedgerEntry: Record "Employee Ledger Entry"; var RaiseError: Boolean; CalcType: Enum "Vendor Apply Calculation Type")
    begin
    end;
}
#pragma warning restore AA0204
