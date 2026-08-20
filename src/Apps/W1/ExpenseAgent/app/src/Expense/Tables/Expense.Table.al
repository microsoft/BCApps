// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;

table 6900 Expense
{
    Access = Internal;
    Caption = 'Expense';
    DataClassification = CustomerContent;
    LookupPageId = Expenses;
    DrillDownPageId = Expenses;
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the expense document number. Leave blank to assign a number from the Expense Nos. number series.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    if AllowModificationOnPerDiemCategory(xRec."Expense Detail Required") then
                        DeleteExpensePerDiem();

                    CheckForAssociatedRecords(xRec."No.", Rec.FieldCaption("No."));
                    ExpenseAgentSetup.GetRecordOnce();
                    NoSeries.TestManual(ExpenseAgentSetup."Expense Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";

            trigger OnValidate()
            var
                ExpenseUser: Record "Expense User";
                Employee: Record Employee;
            begin
                TestStatusOpen();
                if xRec."Expense User No." <> Rec."Expense User No." then
                    if Rec."Expense User No." = '' then
                        Rec.Validate("Expense Category", '')
                    else begin
                        ExpenseUser.Get(Rec."Expense User No.");
                        if not Employee.Get(ExpenseUser."Employee No.") then
                            Error(ExpenseUserMustBeLinkedToAnEmployeeErr, Rec."Expense User No.");

                        Employee.TestField("Employee Posting Group");
                    end;

                CreateDimFromDefaultDim(Rec.FieldNo("Expense User No."));
            end;
        }
        field(3; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Expense Report Header"."No.";
            Editable = false;
        }
        field(4; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category" where(Inactive = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Expense Category" <> xRec."Expense Category" then begin
                    ConfirmAndDeleteAssociatedRecords(Rec.FieldCaption("Expense Category"));

                    ClearRuleId();
                    UpdateFromExpenseCategory();
                    ApplyRule();
                end;
            end;
        }
        field(39; "Expense Ext. Doc. No."; Code[30])
        {
            Caption = 'Expense External Document No.';

            trigger OnValidate()
            begin
                if xRec."Expense Ext. Doc. No." <> Rec."Expense Ext. Doc. No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(38; "Expense Subcategory"; Code[20])
        {
            Caption = 'Expense Subcategory';
            TableRelation = "Expense Subcategory".Code where("Expense Category Code" = field("Expense Category"), Inactive = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(40; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(5; "Status"; Enum "Expense Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(6; "Description"; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(7; "Justification"; Text[100])
        {
            Caption = 'Justification';

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(8; "Expense Date"; Date)
        {
            Caption = 'Expense Date';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Expense Date" <> xRec."Expense Date" then begin
                    ClearRuleId();
                    ApplyRule();
                end;
            end;
        }
        field(9; "Expense Time"; Time)
        {
            Caption = 'Expense Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = "Currency";

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmount();
                ApplyRule();
            end;
        }
        field(11; "Amount"; Decimal)
        {
            Caption = 'Amount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmount();
                ApplyRule();
            end;
        }
        field(12; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(13; "Merchant Name"; Text[100])
        {
            Caption = 'Merchant Name';

            trigger OnValidate()
            begin
                if xRec."Merchant Name" <> Rec."Merchant Name" then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(14; "Receipt Attached"; Boolean)
        {
            Caption = 'Receipt Attached';
            Editable = false;
        }
        field(15; "Receipt Entry"; Integer)
        {
            Caption = 'Receipt Entry';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Receipt Entry" <> 0) then
                    Rec.Validate("Receipt Attached", true)
                else
                    Rec.Validate("Receipt Attached", false)
            end;
        }
        field(16; "Extraction Confidence"; Integer)
        {
            Caption = 'Extraction Confidence';
        }
        field(17; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
            trigger OnValidate()
            begin
                TestStatusOpen();

                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(18; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            trigger OnValidate()
            begin
                TestStatusOpen();

                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(19; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Expense Payment Method";

            trigger OnValidate()
            var
                ExpensePaymentMethod: Record "Expense Payment Method";
            begin
                TestStatusOpen();

                if xRec."Payment Method Code" <> Rec."Payment Method Code" then begin
                    Rec.Validate("Reimbursement Type", Rec."Reimbursement Type"::" ");

                    if ExpensePaymentMethod.Get(Rec."Payment Method Code") then
                        Rec.Validate("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type");
                end;
            end;
        }
        field(20; "Refundable"; Boolean)
        {
            Caption = 'Refundable';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if not Rec.Refundable then
                    Rec.TestField("Non-Refundable Amount", 0);

                UpdateAmount();
            end;
        }
        field(21; "Billable"; Boolean)
        {
            Caption = 'Billable';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(22; "Billable to Customer"; Code[20])
        {
            Caption = 'Billable to Customer';
            TableRelation = "Customer";

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Billable to Customer" <> '') and (Rec."Job No." <> '') then
                    Error(BillableCustomerAndProjectErr, Rec.FieldCaption("Billable to Customer"), Rec.FieldCaption("Job No."));

                CreateDimFromDefaultDim(Rec.FieldNo("Billable to Customer"));
            end;
        }
        field(23; "Expense Location"; Code[30])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Expense Location" <> xRec."Expense Location" then begin
                    if AllowModificationOnPerDiemCategory(xRec."Expense Detail Required") then
                        DeleteExpensePerDiem();

                    CheckForAssociatedRecords(Rec."No.", Rec.FieldCaption("Expense Location"));
                    if Rec."Expense Location" <> '' then
                        if not (Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem") then
                            Error(OnlyUseExpenseLocationWithPerDiemErr, Rec."Expense Location", Rec."Expense Category", Rec."No.");

                    if Rec."Starting Date and Time" = 0DT then
                        Rec."Starting Date and Time" := CurrentDateTime;

                    if Rec."Ending Date and Time" = 0DT then
                        Rec."Ending Date and Time" := CurrentDateTime;

                    ClearRuleId();
                end;

                ApplyRule();
            end;
        }
        field(24; "Starting Date and Time"; DateTime)
        {
            Caption = 'Starting Date and Time';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Starting Date and Time" = 0DT then
                    Rec."Ending Date and Time" := 0DT;

                if Rec."Starting Date and Time" > Rec."Ending Date and Time" then
                    Rec."Ending Date and Time" := Rec."Starting Date and Time";

                ApplyRule();
            end;
        }
        field(25; "Ending Date and Time"; DateTime)
        {
            Caption = 'Ending Date and Time';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Ending Date and Time" <> 0DT) and (Rec."Ending Date and Time" < Rec."Starting Date and Time") then
                    Error(InvalidEndingDateErr);

                ApplyRule();
            end;
        }
        field(26; "Non-Refundable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Non-Refundable Amount" < 0 then
                    Error(NonRefundableAmountCannotBeNegativeErr, Rec.FieldCaption("Non-Refundable Amount"), Rec."No.");

                if Amount < "Non-Refundable Amount" then
                    Error(NonRefundableAmountGreaterThanAmountErr, Rec.FieldCaption("Non-Refundable Amount"));

                UpdateAmount();
                ApplyRule();
            end;
        }
        field(27; "Mileage"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mileage';

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(28; "Starting Point"; Text[50])
        {
            Caption = 'Starting Point';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(29; "Ending Point"; Text[50])
        {
            Caption = 'Ending Point';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(53; "Round Trip"; Boolean)
        {
            Caption = 'Round Trip';
            ToolTip = 'Specifies whether the mileage expense is a round trip. When enabled, the distance is doubled for reimbursement calculation.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                ApplyRule();
            end;
        }
        field(30; "Reimbursable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmount();
            end;
        }
        field(31; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(32; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(33; "Credit Card Feed No."; Integer)
        {
            Caption = 'Credit Card Feed No.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(34; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            var
                DimMgt: Codeunit DimensionManagement;
                OldDimSetID: Integer;
            begin
                OldDimSetID := Rec."Dimension Set ID";
                Rec."Dimension Set ID" :=
                  DimMgt.EditDimensionSet(
                    Rec, Rec."Dimension Set ID", StrSubstNo('%1', Rec."No."),
                    Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                if OldDimSetID <> Rec."Dimension Set ID" then
                    Modify();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(35; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(36; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(37; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
        }
        field(41; "Applied Rule Id"; Guid)
        {
            Caption = 'Applied Rule Id';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(42; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteReason = 'This field is no longer required.';
            ObsoleteTag = '29.0';
#endif

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(43; "Reimbursement Type"; Enum "Expense Reimbursement Type")
        {
            Caption = 'Reimbursement Type';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmount();
            end;
        }
        field(44; "Rule Violations"; Boolean)
        {
            Caption = 'Rule Violations';
            FieldClass = FlowField;
            CalcFormula = exist("Expense Rule Violation" where("Expense No." = field("No.")));
            Editable = false;
        }
        field(45; "Expense Detail Required"; Enum "Expense Detail Needed")
        {
            Caption = 'Expense Detail Required';
        }
        field(46; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No." where(Status = filter(<> Completed));

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Job No." <> '') and (Rec."Billable to Customer" <> '') then
                    Error(BillableCustomerAndProjectErr, Rec.FieldCaption("Billable to Customer"), Rec.FieldCaption("Job No."));

                if xRec."Job No." <> Rec."Job No." then
                    Rec.Validate("Job Task No.", '');

                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
            end;
        }
        field(47; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(48; "Refundable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Refundable Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmount();
            end;
        }
        field(49; "Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Refundable Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(50; "Posted Expense Report No."; Code[20])
        {
            Caption = 'Posted Expense Report No.';
            TableRelation = "Posted Expense Report Header"."No.";
            Editable = false;
        }
        field(51; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount (LCY)';
            Editable = false;
        }
        field(52; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date Time';
            DataClassification = SystemMetadata;
        }
        field(54; "Created By Exp. User Id"; Guid)
        {
            Caption = 'Created By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(55; "Modified By Exp. User Id"; Guid)
        {
            Caption = 'Modified By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(60; "Merchant Registration No."; Text[50])
        {
            Caption = 'Merchant Registration No.';

            trigger OnValidate()
            begin
                if xRec."Merchant Registration No." <> Rec."Merchant Registration No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(61; "Merchant VAT Registration No."; Text[20])
        {
            Caption = 'Merchant VAT Registration No.';

            trigger OnValidate()
            begin
                if xRec."Merchant VAT Registration No." <> Rec."Merchant VAT Registration No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(62; "Expense Vendor No."; Code[20])
        {
            Caption = 'Expense Vendor No.';
            ToolTip = 'Specifies the expense vendor record created for accountant review and matching to a Business Central vendor.';
            TableRelation = "Expense Vendor";
            Editable = false;
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Expense User No.", Amount, Description, "Amount (LCY)") { }
        fieldgroup(Brick; "No.", "Expense User No.", Amount, Description, "Amount (LCY)") { }
    }

    trigger OnInsert()
    var
        NoSeriesManagement: Codeunit "No. Series";
        EAKPITrack: Codeunit "EA KPI Track";
    begin
        if Rec."No." = '' then begin
            ExpenseAgentSetup.GetRecordOnce();
            ExpenseAgentSetup.TestField("Expense Nos.");
            Rec."No." := NoSeriesManagement.GetNextNo(ExpenseAgentSetup."Expense Nos.", WorkDate(), true);
            "No. Series" := ExpenseAgentSetup."Expense Nos.";
        end;

        if Rec."Created Date-Time" = 0DT then
            Rec."Created Date-Time" := CurrentDateTime;

        SetExpenseUserOnCreate();

        if CalledFromExpenseAgent then
            EAKPITrack.UpdateExpenseEntry(Rec);
    end;

    trigger OnModify()
    begin
        UpdateExpenseUserOnModify();
    end;

    trigger OnDelete()
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpenseVATSpecification: Record "Expense VAT Specification";
    begin
        if Rec."Expense Report No." <> '' then
            Error(CannotDeleteWithExpenseReportErr, Rec."No.", Rec."Expense Report No.");

        DeleteExpenseParticipant();
        DeleteExpenseItemization();
        DeleteExpensePerDiem();

        ExpenseRuleViolation.SetRange("Expense No.", Rec."No.");
        if not ExpenseRuleViolation.IsEmpty() then
            ExpenseRuleViolation.DeleteAll(true);

        ExpenseVATSpecification.SetRange("Expense No.", Rec."No.");
        if not ExpenseVATSpecification.IsEmpty() then
            ExpenseVATSpecification.DeleteAll();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        HideValidationDialog: Boolean;
        SkipRuleApplication: Boolean;
        CalledFromExpenseAgent: Boolean;
        EmptyGuid: Guid;
        CannotDeleteWithExpenseReportErr: Label 'You cannot delete expense %1 because it is associated with expense report %2.', Comment = '%1 = Expense No., %2 = Expense Report No.';
        CannotModifyWithParticipantsErr: Label 'You cannot modify %1 field of expense %2 because it has associated participants.', Comment = '%1 = Field Name, %2 = Expense No.';
        CannotModifyWithItemizationErr: Label 'You cannot modify %1 field of expense %2 because it has associated itemizations.', Comment = '%1 = Field Name, %2 = Expense No.';
        DeleteAssociatedRecordsQst: Label 'If you change %1, the existing %2 details will be deleted.\\Do you want to continue?', Comment = '%1 = Field Name, %2 = Expense Detail Required';
        OnlyUseExpenseLocationWithPerDiemErr: Label 'The selected Expense Location %1 and Expense Category %2 can only be used with per diem expenses on Expense No. %3.', Comment = '%1 = Expense Location, %2 = Expense Category, %3 = Expense No.';
        InvalidEndingDateErr: Label 'Ending Date and Time cannot be earlier than Starting Date and Time.';
        NonRefundableAmountGreaterThanAmountErr: Label '%1 cannot be greater than Amount.', Comment = '%1 = Field Caption';
        NonRefundableAmountCannotBeNegativeErr: Label '%1 cannot be in negative on Expense No. %2.', Comment = '%1 = Field Caption, %2 = Expense No.';
        ExpenseUserMustBeLinkedToAnEmployeeErr: Label 'Expense User %1 must be linked to an Employee No.', Comment = '%1 = Expense User No.';
        BillableCustomerAndProjectErr: Label 'You cannot use both %1 and %2 at the same time.', Comment = '%1 = Billable to Customer field caption, %2 = Project No. field caption';

    procedure AssistEdit() Result: Boolean
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.TestField("Expense Nos.");
        if NoSeries.LookupRelatedNoSeries(ExpenseAgentSetup."Expense Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    local procedure SetExpenseUserOnCreate()
    var
        ExpenseUser: Record "Expense User";
    begin
        // Only update the Created By and Modified By Expense User Id when the change is made through Expense Agent, otherwise leave them unchanged as the change is made by other Business Central user.
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            exit;

        if Rec."Expense User No." = '' then
            exit;

        if not ExpenseUser.Get(Rec."Expense User No.") then
            exit;

        Rec."Created By Exp. User Id" := ExpenseUser.SystemId;
        Rec."Modified By Exp. User Id" := ExpenseUser.SystemId;
    end;

    local procedure UpdateExpenseUserOnModify()
    var
        ExpenseUser: Record "Expense User";
    begin
        // Only update Modified By Expense User Id when the change is made through Expense Agent, otherwise change it to Blank as the change is made by other Business Central user.
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then begin
            Rec."Modified By Exp. User Id" := EmptyGuid;
            exit;
        end;

        if Rec."Expense User No." = '' then
            exit;

        if not ExpenseUser.Get(Rec."Expense User No.") then
            exit;

        Rec."Modified By Exp. User Id" := ExpenseUser.SystemId;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();
    end;

    procedure PerformManualRelease()
    var
        ReleaseExpenseDoc: Codeunit "Release Expense Document";
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        ReleaseExpenseDoc.PerformManualRelease(Rec);
        Commit();
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1', "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then
            Modify();
    end;

    procedure PerformManualRelease(var Expense: Record Expense)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
        PrevFilterGroup: Integer;
    begin
        NoOfSelected := Expense.Count;
        PrevFilterGroup := Expense.FilterGroup();
        Expense.FilterGroup(10);
        Expense.SetFilter(Status, '<>%1', Expense.Status::Released);
        NoOfSkipped := NoOfSelected - Expense.Count;
        BatchProcessingMgt.BatchProcess(Expense, Codeunit::"Expense Manual Release", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
        Expense.SetRange(Status);
        Expense.FilterGroup(PrevFilterGroup);
    end;

    procedure PerformManualReopen(var Expense: Record Expense)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
    begin
        NoOfSelected := Expense.Count;
        Expense.SetFilter(Status, '<>%1', Expense.Status::Open);
        NoOfSkipped := NoOfSelected - Expense.Count;
        BatchProcessingMgt.BatchProcess(Expense, Codeunit::"Expense Manual Reopen", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
    end;

#if not CLEAN29
    [Obsolete('This function is no longer used.', '29.0')]
    procedure FilterByUserId(FilterUserId: Code[50])
    begin
    end;
#endif

    internal procedure FilterByCurrentUser()
    var
        ExpenseUser: Record "Expense User";
    begin
        Rec.SetRange("Expense User No.", ExpenseUser.GetExpenseUserNoByCurrentUser());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';
    end;

    procedure TestStatusOpen()
    begin
        Rec.TestField(Status, Status::Open);
    end;

    procedure GetRuleStyleText() StatusStyleText: Text
    begin
        if IsNullGuid("Applied Rule Id") then
            StatusStyleText := 'Attention'
        else
            StatusStyleText := 'Strong';
    end;

    local procedure AllowModificationOnPerDiemCategory(ExpenseDetail: Enum "Expense Detail Needed"): Boolean
    begin
        exit(ExpenseDetail = ExpenseDetail::"Per Diem");
    end;

    local procedure DeleteExpensePerDiem()
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        ExpensePerDiem.SetRange("Expense No.", Rec."No.");
        if not ExpensePerDiem.IsEmpty() then
            ExpensePerDiem.DeleteAll();
    end;

    local procedure DeleteExpenseItemization()
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.SetRange("Expense No.", Rec."No.");
        if not ExpenseItemization.IsEmpty() then
            ExpenseItemization.DeleteAll();
    end;

    local procedure DeleteExpenseParticipant()
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.SetRange("Expense No.", Rec."No.");
        if not ExpenseParticipant.IsEmpty() then
            ExpenseParticipant.DeleteAll();
    end;

    local procedure ClearRuleId()
    begin
        Rec."Applied Rule Id" := EmptyGuid;
    end;

    local procedure CheckForAssociatedRecords(ExpenseNo: Code[20]; FieldName: Text)
    var
        ExpenseParticipant: Record "Expense Participant";
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseParticipant.SetRange("Expense No.", ExpenseNo);
        if not ExpenseParticipant.IsEmpty() then
            Error(CannotModifyWithParticipantsErr, FieldName, ExpenseNo);

        ExpenseItemization.SetRange("Expense No.", ExpenseNo);
        if not ExpenseItemization.IsEmpty() then
            Error(CannotModifyWithItemizationErr, FieldName, ExpenseNo);
    end;

    local procedure ConfirmAndDeleteAssociatedRecords(FieldCaption: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not HasAssociatedRecords() then
            exit;

        if not HideValidationDialog then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteAssociatedRecordsQst, FieldCaption, Rec."Expense Detail Required"), true) then
                Error('');

        DeleteAssociatedRecords();
    end;

    local procedure HasAssociatedRecords(): Boolean
    var
        ExpenseParticipant: Record "Expense Participant";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        case Rec."Expense Detail Required" of
            Rec."Expense Detail Required"::Itemize:
                begin
                    ExpenseItemization.SetRange("Expense No.", Rec."No.");
                    exit(not ExpenseItemization.IsEmpty());
                end;
            Rec."Expense Detail Required"::Participants:
                begin
                    ExpenseParticipant.SetRange("Expense No.", Rec."No.");
                    exit(not ExpenseParticipant.IsEmpty());
                end;
            Rec."Expense Detail Required"::"Per Diem":
                begin
                    ExpensePerDiem.SetRange("Expense No.", Rec."No.");
                    exit(not ExpensePerDiem.IsEmpty());
                end;
        end;
    end;

    local procedure DeleteAssociatedRecords()
    begin
        DeleteExpenseParticipant();
        DeleteExpenseItemization();
        DeleteExpensePerDiem();
    end;

    procedure ApplyRule(ApplyAndValidateRuleOnExpense: Boolean; ValidateRuleOnly: Boolean)
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if ApplyAndValidateRuleOnExpense then begin
            ApplyRule();
            exit;
        end;

        if ValidateRuleOnly then begin
            TestStatusOpen();
            ExpenseRuleValidation.ValidateExpenseAgainstRule(Rec);
        end;
    end;

    procedure ApplyRule()
    var
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if Rec."No." = '' then
            exit;

        TestStatusOpen();
        if SkipRuleApplication then
            exit;

        Rec.SetSkipRuleApplication(true);
        ExpenseAutoPopulation.FindRuleAndUpdateExpense(Rec);
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Rec);
        Rec.SetSkipRuleApplication(false);
    end;

    procedure SetSkipRuleApplication(NewSkipRuleApplication: Boolean)
    begin
        SkipRuleApplication := NewSkipRuleApplication;
    end;

    /// <summary>
    /// Initializes the dimensions for the Expense.
    /// </summary>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    /// <summary>
    /// Creates dimensions from default dimension sources for the expense.
    /// </summary>
    /// <param name="DefaultDimSource">List of dictionaries containing dimension source data.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        DimMgt.UpdateGlobalDimFromDimSetID(Rec."Dimension Set ID", Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Employee, GetEmployeeNo(), FieldNo = Rec.FieldNo("Expense User No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Billable to Customer", FieldNo = Rec.FieldNo("Billable to Customer"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", GetSalesPersonCodeFromEmployee());
    end;

    local procedure GetEmployeeNo(): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseUser.Get(Rec."Expense User No.") then
            exit(ExpenseUser."Employee No.")
        else
            exit('');
    end;

    local procedure GetSalesPersonCodeFromEmployee(): Code[20]
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
    begin
        if ExpenseUser.Get(Rec."Expense User No.") then begin
            if Employee.Get(ExpenseUser."Employee No.") then
                exit(Employee."Salespers./Purch. Code");
        end else
            exit('');
    end;

    procedure CheckExpensePrerequisitesBeforeUsing()
    begin
        Rec.TestField("No.");
        Rec.TestField("Expense User No.");
        Rec.TestField("Expense Category");
    end;

    procedure UpdateAmount()
    begin
        GeneralLedgerSetup.GetRecordOnce();
        UpdateCurrencyFactor();

        if Rec."Non-Refundable Amount" <> 0 then
            Rec.TestField(Refundable, true);

        Rec."Reimbursable Amount" := 0;
        Rec."Refundable Amount" := 0;

        if Rec.Refundable then begin
            if Rec."Reimbursement Type" = Rec."Reimbursement Type"::"Employee Paid" then
                Rec."Reimbursable Amount" := Rec.Amount - Rec."Non-Refundable Amount"
            else
                Rec."Reimbursable Amount" := -Rec."Non-Refundable Amount";

            Rec."Refundable Amount" := Rec.Amount - Rec."Non-Refundable Amount";
        end else
            if Rec."Reimbursement Type" <> Rec."Reimbursement Type"::"Employee Paid" then
                Rec."Reimbursable Amount" := -Rec.Amount;

        UpdateAmountLCY();
    end;

    local procedure UpdateAmountLCY()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpenseCurrency: Record Currency;
    begin
        ExpenseCurrency.Initialize(Rec."Currency Code");
        if Rec."Currency Code" = '' then begin
            Rec."Amount (LCY)" := Rec.Amount;
            Rec."Non-Refundable Amount (LCY)" := Rec."Non-Refundable Amount";
            Rec."Reimbursable Amount (LCY)" := Rec."Reimbursable Amount";
            Rec."Refundable Amount (LCY)" := Rec."Refundable Amount";
        end else begin
            Rec."Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(Rec."Expense Date", Rec."Currency Code", Rec.Amount, Rec."Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
            Rec."Reimbursable Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(Rec."Expense Date", Rec."Currency Code", Rec."Reimbursable Amount", Rec."Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
            Rec."Refundable Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(Rec."Expense Date", Rec."Currency Code", Rec."Refundable Amount", Rec."Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
            Rec."Non-Refundable Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(Rec."Expense Date", Rec."Currency Code", Rec."Non-Refundable Amount", Rec."Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
        end;
    end;

    local procedure UpdateCurrencyFactor()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        CurrencyDate: Date;
    begin
        if Rec."Currency Code" <> '' then begin
            if Rec."Expense Date" <> 0D then
                CurrencyDate := "Expense Date"
            else
                CurrencyDate := WorkDate();

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, Rec."Currency Code") then
                Rec."Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, Rec."Currency Code")
            else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Currency Code");
        end else
            Rec."Currency Factor" := 0;
    end;

    local procedure UpdateFromExpenseCategory()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        Rec.Description := '';
        Rec."Expense Detail Required" := Rec."Expense Detail Required"::" ";

        if Rec."Expense Category" = '' then begin
            Rec.Validate("Expense Location", '');
            Rec."Unit of Measure Code" := '';
            Rec.Amount := 0;
            Rec.UpdateAmount();
            exit;
        end;

        if not ExpenseCategory.Get(Rec."Expense Category") then begin
            Rec.Validate("Expense Location", '');
            exit;
        end;

        if ExpenseCategory."Expense Detail Required" <> ExpenseCategory."Expense Detail Required"::"Per Diem" then
            Rec.Validate("Expense Location", '');

        Rec.TestField("Expense User No.");

        Rec.Validate(Refundable, ExpenseCategory.Refundable);
        Rec.Validate(Description, ExpenseCategory."Posting Description");
        Rec.Validate("Reimbursement Type", ExpenseCategory."Reimbursement Type");
        if ExpenseCategory."Default Payment Method" <> '' then
            Rec.Validate("Payment Method Code", ExpenseCategory."Default Payment Method");

        Rec.Validate("Expense Detail Required", ExpenseCategory."Expense Detail Required");

        ExpenseAgentSetup.GetRecordOnce();
        if Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage then begin
            ExpenseAgentSetup.TestField("Default Mileage UOM");
            Rec.Validate("Unit of Measure Code", ExpenseAgentSetup."Default Mileage UOM");
        end;

        Rec.Validate("Currency Code", '');
        Rec.Amount := 0;
        Rec.UpdateAmount();
    end;

    procedure ShowItemization()
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.SetRange("Expense No.", Rec."No.");
        ExpenseItemization.SetRange("Expense Category Code", Rec."Expense Category");

        Page.RunModal(Page::"Expense Itemizations", ExpenseItemization);
    end;

    procedure ShowParticipants()
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.SetRange("Expense No.", Rec."No.");

        Page.RunModal(Page::"Expense Participants", ExpenseParticipant);
    end;

    procedure ShowPerDiem()
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        ExpensePerDiem.SetRange("Expense No.", Rec."No.");

        Page.RunModal(Page::"Per Diem Expenses", ExpensePerDiem);
    end;

    internal procedure SetCalledFromExpenseAgent(NewCalledFromExpenseAgent: Boolean)
    begin
        CalledFromExpenseAgent := NewCalledFromExpenseAgent;
    end;

    procedure GetVATAmounts(var VATAmount: Decimal; var VATAmountLCY: Decimal): Boolean
    var
        ExpenseVATSpecification: Record "Expense VAT Specification";
    begin
        ExpenseVATSpecification.SetRange("Expense No.", Rec."No.");
        ExpenseVATSpecification.CalcSums("VAT Amount", "VAT Amount (LCY)");
        VATAmount := ExpenseVATSpecification."VAT Amount";
        VATAmountLCY := ExpenseVATSpecification."VAT Amount (LCY)";
        exit(VATAmount <> 0);
    end;

    internal procedure UpdateVATSpecification(ExpenseNo: Code[20])
    var
        ExpenseItemization: Record "Expense Itemization";
        ExpenseVATSpec: Record "Expense VAT Specification";
        TempExpenseVATSpec: Record "Expense VAT Specification" temporary;
        LineNo: Integer;
    begin
        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Default VAT Bus. Posting Group" = '' then
            exit;

        ExpenseItemization.SetRange("Expense No.", ExpenseNo);
        if ExpenseItemization.IsEmpty() then
            exit;

        ExpenseVATSpec.SetRange("Expense No.", ExpenseNo);
        ExpenseVATSpec.DeleteAll();

        LineNo := 0;
        ExpenseItemization.FindSet();
        repeat
            TempExpenseVATSpec.SetRange("Expense Category", ExpenseItemization."Expense Category Code");
            TempExpenseVATSpec.SetRange("Expense Subcategory", ExpenseItemization."Expense Subcategory Code");
            if TempExpenseVATSpec.FindFirst() then begin
                TempExpenseVATSpec."Amount" += ExpenseItemization."Amount";
                TempExpenseVATSpec.Modify();
            end else begin
                TempExpenseVATSpec.Init();
                TempExpenseVATSpec."Expense No." := ExpenseNo;
                LineNo += 1;
                TempExpenseVATSpec."Line No." := LineNo;
                TempExpenseVATSpec.Validate("Expense Category", ExpenseItemization."Expense Category Code");
                TempExpenseVATSpec.Validate("Expense Subcategory", ExpenseItemization."Expense Subcategory Code");
                TempExpenseVATSpec.Validate("VAT Bus. Posting Group", ExpenseAgentSetup."Default VAT Bus. Posting Group");
                TempExpenseVATSpec.Validate("Amount", ExpenseItemization.Amount);
                TempExpenseVATSpec.Insert();
            end;
        until ExpenseItemization.Next() = 0;

        TempExpenseVATSpec.Reset();
        if TempExpenseVATSpec.FindSet() then
            repeat
                ExpenseVATSpec := TempExpenseVATSpec;
                ExpenseVATSpec.Insert();
            until TempExpenseVATSpec.Next() = 0;
    end;
}