// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;

table 80 "Gen. Journal Template"
{
    Caption = 'Gen. Journal Template';
    LookupPageID = "General Journal Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
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
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
        }
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
                end;

                if Recurring then
                    "Page ID" := PAGE::"Recurring General Journal";

                OnAfterValidateType(Rec, SourceCodeSetup);
            end;
        }
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
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
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
        field(15; "Test Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Posting Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Posting Report ID")));
            Caption = 'Posting Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Force Doc. Balance"; Boolean)
        {
            Caption = 'Force Doc. Balance';
            InitValue = true;
        }
        field(19; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
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
        field(25; "Cust. Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Customer = R;
            Caption = 'Cust. Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(26; "Cust. Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Customer = R;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Cust. Receipt Report ID")));
            Caption = 'Cust. Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Vendor Receipt Report ID"; Integer)
        {
            AccessByPermission = TableData Vendor = R;
            Caption = 'Vendor Receipt Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(28; "Vendor Receipt Report Caption"; Text[250])
        {
            AccessByPermission = TableData Vendor = R;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Vendor Receipt Report ID")));
            Caption = 'Vendor Receipt Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
        }
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
        field(32; "Allow Posting Date From"; Date)
        {
            Caption = 'Allow Posting Date From';
        }
        field(33; "Allow Posting Date To"; Date)
        {
            Caption = 'Allow Posting Date To';
        }
        field(34; "Unlink Inc. Doc On Posting"; Boolean)
        {
            Caption = 'Unlink Incoming Documents On Posting';

            trigger OnValidate()
            begin
                if "Unlink Inc. Doc On Posting" then
                    TestField(Recurring);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoSeriesValidate(var GenJournalTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GenJournalTemplate: Record "Gen. Journal Template"; GLAccount: Record "G/L Account")
    begin
    end;
}

