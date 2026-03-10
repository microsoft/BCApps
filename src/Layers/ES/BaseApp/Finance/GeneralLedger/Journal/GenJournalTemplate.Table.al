// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;
using System.Security.User;

/// <summary>
/// Stores journal template definitions that control journal behavior, validation rules, and user interface features.
/// Templates provide the framework for different types of journals with specialized functionality for specific business processes.
/// </summary>
/// <remarks>
/// Templates define default settings for journal batches including source codes, number series, posting reports, and page assignments.
/// Key relationships: Used by Gen. Journal Batch for template-based configuration inheritance.
/// Extensibility: Template types can be extended to support custom journal workflows and validation requirements.
/// </remarks>
table 80 "Gen. Journal Template"
{
    Caption = 'Gen. Journal Template';
    LookupPageID = "General Journal Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the journal template used to reference and configure journal batches.
        /// </summary>
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the journal template providing user-friendly identification.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Report ID used for testing journal lines before posting to validate transactions.
        /// </summary>
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Page ID that defines the user interface for entering journal lines with this template.
        /// </summary>
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        /// <summary>
        /// Report ID for the posting report that prints after successful journal posting.
        /// </summary>
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Indicates whether the posting report must be printed after journal posting.
        /// </summary>
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
        }
        /// <summary>
        /// Template type that determines journal behavior and specialized functionality for different business scenarios.
        /// </summary>
        field(9; Type; Enum "Gen. Journal Template Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "Test Report ID" := REPORT::"General Journal - Test";
                "Posting Report ID" := REPORT::"G/L Register";
                SourceCodeSetup.Get();
                case Type of
                    Type::General:
                        begin
                            "Source Code" := SourceCodeSetup."General Journal";
                            "Page ID" := PAGE::"General Journal";
                        end;
                    Type::Sales:
                        begin
                            "Source Code" := SourceCodeSetup."Sales Journal";
                            "Page ID" := PAGE::"Sales Journal";
                        end;
                    Type::Purchases:
                        begin
                            "Source Code" := SourceCodeSetup."Purchase Journal";
                            "Page ID" := PAGE::"Purchase Journal";
                        end;
                    Type::"Cash Receipts":
                        begin
                            "Source Code" := SourceCodeSetup."Cash Receipt Journal";
                            "Page ID" := PAGE::"Cash Receipt Journal";
                        end;
                    Type::Payments:
                        begin
                            "Source Code" := SourceCodeSetup."Payment Journal";
                            "Page ID" := PAGE::"Payment Journal";
                        end;
                    Type::Assets:
                        begin
                            "Source Code" := SourceCodeSetup."Fixed Asset G/L Journal";
                            "Page ID" := PAGE::"Fixed Asset G/L Journal";
                        end;
                    Type::Intercompany:
                        begin
                            "Source Code" := SourceCodeSetup."IC General Journal";
                            "Page ID" := PAGE::"IC General Journal";
                        end;
                    Type::Jobs:
                        begin
                            "Source Code" := SourceCodeSetup."Job G/L Journal";
                            "Page ID" := PAGE::"Job G/L Journal";
                        end;
                    Type::Cartera:
                        begin
                            "Source Code" := SourceCodeSetup."Cartera Journal";
                            "Page ID" := PAGE::"Cartera Journal";
                        end;
                end;

                if Recurring then
                    "Page ID" := PAGE::"Recurring General Journal";

                OnAfterValidateType(Rec, SourceCodeSetup);
            end;
        }
        /// <summary>
        /// Source code automatically applied to all journal lines created with this template for audit tracking.
        /// </summary>
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                GenJnlLine.SetRange("Journal Template Name", Name);
                GenJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        /// <summary>
        /// Default reason code applied to journal lines created with this template for transaction classification.
        /// </summary>
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Indicates whether this template is used for recurring journal entries with automated posting schedules.
        /// </summary>
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';

            trigger OnValidate()
            begin
                Validate(Type);
                if Recurring then
                    TestField("No. Series", '');
            end;
        }
        /// <summary>
        /// Display caption for the test report used with this journal template.
        /// </summary>
        field(15; "Test Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display caption for the page used for journal line entry with this template.
        /// </summary>
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display caption for the posting report used with this journal template.
        /// </summary>
        field(17; "Posting Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Posting Report ID")));
            Caption = 'Posting Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Requires journal documents to have balanced debit and credit amounts before posting.
        /// </summary>
        field(18; "Force Doc. Balance"; Boolean)
        {
            Caption = 'Force Doc. Balance';
            InitValue = false;
        }
        /// <summary>
        /// Account type for the default balancing account used in journal lines created with this template.
        /// </summary>
        field(19; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        /// <summary>
        /// Account number for the default balancing account used in journal lines created with this template.
        /// </summary>
        field(20; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" then
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        /// <summary>
        /// Number series used for automatic document number assignment in journal lines.
        /// </summary>
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeNoSeriesValidate(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "No. Series" <> '' then begin
                    if Recurring then
                        Error(
                          RecurringJnlFieldErr,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        "Posting No. Series" := '';
                end;
            end;
        }
        /// <summary>
        /// Number series used for posted document numbers after journal posting completion.
        /// </summary>
        field(22; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(ValueNotAllowedFieldErr, "Posting No. Series"));
            end;
        }
        /// <summary>
        /// Automatically copies VAT posting setup from accounts to journal lines for VAT calculation.
        /// </summary>
        field(23; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Copy VAT Setup to Jnl. Lines" <> xRec."Copy VAT Setup to Jnl. Lines" then begin
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Copy VAT Setup to Jnl. Lines", "Copy VAT Setup to Jnl. Lines");
                end;
            end;
        }
        /// <summary>
        /// Allows manual adjustment of VAT amounts in journal lines when posting with this template.
        /// </summary>
        field(24; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';

            trigger OnValidate()
            begin
                if "Allow VAT Difference" <> xRec."Allow VAT Difference" then begin
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Allow VAT Difference", "Allow VAT Difference");
                end;
            end;
        }
        /// <summary>
        /// Report ID for customer receipt reports generated from journal postings with this template.
        /// </summary>
        field(25; "Cust. Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Customer = R;
            Caption = 'Cust. Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Display caption for the customer receipt report used with this journal template.
        /// </summary>
        field(26; "Cust. Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Customer = R;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Cust. Receipt Report ID")));
            Caption = 'Cust. Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Report ID for vendor receipt reports generated from journal postings with this template.
        /// </summary>
        field(27; "Vendor Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Vendor = R;
            Caption = 'Vendor Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        /// <summary>
        /// Display caption for the vendor receipt report used with this journal template.
        /// </summary>
        field(28; "Vendor Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Vendor = R;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Vendor Receipt Report ID")));
            Caption = 'Vendor Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Automatically increments batch names when creating new batches with this template.
        /// </summary>
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
        }
        /// <summary>
        /// Creates copies of posted journal lines in the Posted General Journal Line table for audit history.
        /// </summary>
        field(31; "Copy to Posted Jnl. Lines"; Boolean)
        {
            Caption = 'Copy to Posted Jnl. Lines';

            trigger OnValidate()
            begin
                if "Copy to Posted Jnl. Lines" <> xRec."Copy to Posted Jnl. Lines" then begin
                    TestField(Recurring, false);
                    GenJnlBatch.SetRange("Journal Template Name", Name);
                    GenJnlBatch.ModifyAll("Copy to Posted Jnl. Lines", "Copy to Posted Jnl. Lines");
                end;
            end;
        }
        /// <summary>
        /// Start date for allowable posting dates when using this journal template.
        /// </summary>
        field(32; "Allow Posting Date From"; Date)
        {
            Caption = 'Allow Posting From';

            trigger OnValidate()
            begin
                if xRec."Allow Posting Date From" <> Rec."Allow Posting Date From" then begin
                    if Rec."Allow Posting Date From" <> 0D then
                        Evaluate(Rec."Allow Posting From DateFormula", '');

                    CheckDateRange();
                end;
            end;
        }
        /// <summary>
        /// End date for allowable posting dates when using this journal template.
        /// </summary>
        field(33; "Allow Posting Date To"; Date)
        {
            Caption = 'Allow Posting To';

            trigger OnValidate()
            begin
                if xRec."Allow Posting Date To" <> Rec."Allow Posting Date To" then begin
                    if Rec."Allow Posting Date To" <> 0D then
                        Evaluate(Rec."Allow Posting To DateFormula", '');

                    CheckDateRange();
                end;
            end;
        }
        /// <summary>
        /// Automatically unlinks incoming documents from journal lines when posting for document workflow management.
        /// </summary>
        field(34; "Unlink Inc. Doc On Posting"; Boolean)
        {
            Caption = 'Unlink Incoming Documents On Posting';

            trigger OnValidate()
            begin
                if "Unlink Inc. Doc On Posting" then
                    TestField(Recurring);
            end;
        }
        field(35; "Allow Posting From DateFormula"; DateFormula)
        {
            Caption = 'Allow Posting From DateFormula';

            trigger OnValidate()
            begin
                if xRec."Allow Posting From DateFormula" <> Rec."Allow Posting From DateFormula" then begin
                    if Format(Rec."Allow Posting From DateFormula") <> '' then
                        Rec.Validate("Allow Posting Date From", 0D);

                    CheckDateRange();
                end;
            end;
        }
        field(36; "Allow Posting To DateFormula"; DateFormula)
        {
            Caption = 'Allow Posting To DateFormula';

            trigger OnValidate()
            begin
                if xRec."Allow Posting To DateFormula" <> Rec."Allow Posting To DateFormula" then begin
                    if Format(Rec."Allow Posting To DateFormula") <> '' then
                        Rec.Validate("Allow Posting Date To", 0D);

                    CheckDateRange();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
        key(Key2; Type, "Bal. Account Type", "Bal. Account No.")
        {
        }
        key(Key3; Type, Recurring, "No. Series")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description, Type)
        {
        }
    }

    trigger OnDelete()
    begin
        GenJnlAlloc.SetRange("Journal Template Name", Name);
        GenJnlAlloc.DeleteAll();
        GenJnlLine.SetRange("Journal Template Name", Name);
        GenJnlLine.DeleteAll(true);
        GenJnlBatch.SetRange("Journal Template Name", Name);
        GenJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        SourceCodeSetup: Record "Source Code Setup";
        RecurringJnlFieldErr: Label 'Only the %1 field can be filled in on recurring journals.', comment = '%1 = a field name';
        ValueNotAllowedFieldErr: Label 'must not be %1', comment = '%1 = a field value';

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Direct Posting", true);
        end;

        OnAfterCheckGLAcc(Rec, GLAcc);
    end;

    local procedure CheckDateRange()
    var
        UserSetupManagement: Codeunit "User Setup Management";
        AllowedFrom: Date;
        AllowedTo: Date;
    begin
        AllowedFrom := Rec."Allow Posting Date From";
        AllowedTo := Rec."Allow Posting Date To";
        UserSetupManagement.GetDateRange(
            AllowedFrom, AllowedTo,
            Rec."Allow Posting From DateFormula", Rec."Allow Posting To DateFormula",
            Rec.RecordId());
    end;

    /// <summary>
    /// Integration event that occurs after validating the journal template type.
    /// Allows customization of template behavior based on type changes and source code setup configuration.
    /// </summary>
    /// <param name="GenJournalTemplate">The journal template record being validated.</param>
    /// <param name="SourceCodeSetup">Source code setup record containing configuration for source codes.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    /// <summary>
    /// Integration event that occurs before validating number series configuration for the journal template.
    /// Allows custom handling of number series validation logic and error prevention.
    /// </summary>
    /// <param name="GenJournalTemplate">The journal template record with number series being validated.</param>
    /// <param name="IsHandled">Set to true to skip standard validation processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoSeriesValidate(var GenJournalTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that occurs after checking G/L Account configuration for the journal template.
    /// Allows additional validation or processing based on the associated G/L Account settings.
    /// </summary>
    /// <param name="GenJournalTemplate">The journal template record being checked.</param>
    /// <param name="GLAccount">The G/L Account record associated with the template for validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GenJournalTemplate: Record "Gen. Journal Template"; GLAccount: Record "G/L Account")
    begin
    end;
}

