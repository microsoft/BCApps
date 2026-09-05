// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

table 6906 "Expense Report Header"
{
    Access = Internal;
    Caption = 'Expense Report Header';
    DataClassification = CustomerContent;
    DataCaptionFields = "No.", Description;
    LookupPageId = "Expense Reports";
    DrillDownPageId = "Expense Reports";
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ExpenseAgentSetup.GetRecordOnce();
                    NoSeries.TestManual(ExpenseAgentSetup."Expense Reports Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Expense User No." <> xRec."Expense User No." then
                    if ExpenseLinesExist() then
                        Error(CannotChangeExpenseUserErr, Rec.FieldCaption("Expense User No."), Rec."No.");

                UpdateFromEmployee();

                if Rec."Expense User No." <> xRec."Expense User No." then begin

                    if Rec."Expense User No." <> '' then
                        CheckExpenseUserWhenApprovalIsEnabled();

                    Rec.Validate("Approver Expense User No.", '');
                    Rec.Validate("Approver Expense User ID", '');
                    Rec.Validate("Spend Request No.", '');
                    Rec."Final Approver No." := GetFinalApproverNo(Rec."Expense User No.");
                    Rec."Interim Approver No." := '';
                end;

                Rec.CreateDimFromDefaultDim(Rec.FieldNo("Expense User No."));
            end;
        }
        field(3; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(4; "Expense Report Date"; Date)
        {
            Caption = 'Expense Report Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateCurrencyFactor();

                if xRec."Posting Date" <> Rec."Posting Date" then
                    UpdateReportLines(Rec.FieldCaption("Posting Date"));
            end;
        }
        field(6; "Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the value of the Description field.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
#pragma warning disable AA0232
        field(10; "Amount (LCY)"; Decimal)
#pragma warning restore AA0232
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Amount (LCY)" where("Document No." = field("No.")));
        }
        field(12; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Non-Refundable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(13; "Reimbursable Amount"; Decimal)
        {
            AutoFormatExpression = "Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount';
            ToolTip = 'Specifies the value of the Reimbursable Amount field.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Reimbursable Amount" where("Document No." = field("No.")));
        }
        field(14; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Reimbursable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
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
        field(16; "Shortcut Dimension 2 Code"; Code[20])
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
        field(17; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            ToolTip = 'Specifies the employee''s type to link business transactions made for the employee with the appropriate account in the general ledger.';
            TableRelation = "Employee Posting Group".Code;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(18; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language.Code;
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(19; Comment; Boolean)
        {
            Caption = 'Comment';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code".Code;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = SystemMetadata;
        }
        field(22; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = SystemMetadata;
        }
        field(23; Status; Enum "Expense Report Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(24; "Anti-Corruption Attestation"; Boolean)
        {
            Caption = 'Anti-Corruption Attestation';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(25; "Anti-Corruption Description"; Text[100])
        {
            Caption = 'Anti-Corruption Description';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(26; Corrected; Boolean)
        {
            Caption = 'Corrected';
            Editable = false;
        }
        field(27; "Responsibility Center"; Code[20])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center".Code;
            trigger OnValidate()
            begin
                TestStatusOpen();

                Rec.CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));
            end;
        }
        field(28; "Reimbursement Currency Code"; Code[10])
        {
            Caption = 'Reimbursement Currency Code';
            ToolTip = 'Specifies the value of the Reimbursement Currency Code field.';
            TableRelation = Currency.Code;

            trigger OnValidate()
            begin
                if Rec."Reimbursement Currency Code" <> xRec."Reimbursement Currency Code" then begin
                    TestStatusOpen();
                    UpdateCurrencyFactor();
                end;
            end;
        }
        field(29; "Corrected Document No."; Code[20])
        {
            Caption = 'Corrected Document No.';
            Editable = false;
        }
        field(30; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim();
            end;

            trigger OnValidate()
            var
                DimensionManagement: Codeunit DimensionManagement;
            begin
                DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(31; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."VAT Amount (LCY)" where("Document No." = field("No.")));
        }
        field(32; "Amount without VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount without VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Amount without VAT (LCY)" where("Document No." = field("No.")));
        }
        field(33; "Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Refundable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Refundable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(34; "Refundable Amount"; Decimal)
        {
            AutoFormatExpression = "Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Refundable Amount';
            ToolTip = 'Specifies the value of the Refundable Amount field.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line"."Refundable Amount" where("Document No." = field("No.")));
        }
        field(40; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if xRec."VAT Bus. Posting Group" <> Rec."VAT Bus. Posting Group" then
                    UpdateReportLines(Rec.FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(42; "Submission DateTime"; DateTime)
        {
            Caption = 'Submission Date and Time';
        }
        field(43; "Approved/Rejected DateTime"; DateTime)
        {
            Caption = 'Approved/Rejected Date and Time';
            Description = 'The date and time when the expense report was actually approved or rejected.';
            Editable = false;
        }
        field(44; "Approved/Rejected By"; Code[50])
        {
            Caption = 'Approved/Rejected By User';
            Description = 'The user who actually approved or rejected the expense report. May differ from the designated approver.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            Editable = false;
        }
        field(441; "Approved/Rejected Exp.User No."; Code[50])
        {
            Caption = 'Approved/Rejected Expense User Number';
            Description = 'The expense user who actually approved or rejected the expense report. May differ from the designated approver.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Expense User"."No.";
            Editable = false;
        }
        field(442; "Approved/Rejected Exp.UserName"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Approved/Rejected Exp.User No.")));
            Caption = 'Approved/Rejected Expense User Display Name';
            Editable = false;
        }
        field(45; "Approver Expense User No."; Code[20])
        {
            Caption = 'Approver Expense User No.';
            Description = 'The designated approver from the approval setup, assigned when the report is submitted for approval.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(46; "Approver Expense User ID"; Code[50])
        {
            Caption = 'Approver Expense User ID';
            Description = 'The user ID of the designated approver from the approval setup, assigned when the report is submitted for approval.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(47; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(48; "Approver Comment"; Blob)
        {
            Caption = 'Approver Comment';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the latest comment from the approver when approving or rejecting an expense report.';
        }
        field(49; "Submitter Comment"; Blob)
        {
            Caption = 'Submitter Comment';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the latest comment from the submitter when submitting an expense report or resubmitting a rejected expense report.';
        }
        field(50; "Reimbursement Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reimbursement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Reimbursement Currency Factor" <> xRec."Reimbursement Currency Factor" then begin
                    TestStatusOpen();
                    UpdateReportLines(Rec.FieldCaption("Reimbursement Currency Factor"));
                end;
            end;
        }
        field(55; "Pending Approval By"; Code[20])
        {
            Caption = 'Pending Approval By';
            FieldClass = FlowFilter;
            TableRelation = "Expense User"."No.";
        }
        field(56; "Submitter Expense User No."; Code[20])
        {
            Caption = 'Submitter Expense User No.';
            TableRelation = "Expense User"."No.";
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the expense user number of the submitter when the expense report is in pending approval, approved or rejected status.';
        }
        field(57; "Submitter Expense User ID"; Code[50])
        {
            Caption = 'Submitter Expense User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(58; "Created By Exp. User Id"; Guid)
        {
            Caption = 'Created By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(59; "Modified By Exp. User Id"; Guid)
        {
            Caption = 'Modified By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Expense Report Header"."No.";
        }
        field(66; "Has VAT Specification"; Boolean)
        {
            AutoFormatType = 0;
            Caption = 'Has VAT Specification';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = exist("Expense Report Line VAT Spec." where("Document No." = field("No.")));
            ToolTip = 'Specifies whether this expense report contains at least one VAT specification line.';
        }
        field(67; "Approved Reclaim VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Approved Reclaim VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line VAT Spec."."Reclaim VAT Amount (LCY)" where("Document No." = field("No."), "Reclaim Status" = const(Approved)));
            ToolTip = 'Specifies the total VAT amount approved for reclaim across all VAT specification lines of this expense report, in local currency.';
        }
        field(68; "Final Approver No."; Code[20])
        {
            Caption = 'Final Approver No.';
            ToolTip = 'Specifies the expense user who gives final approval. Prepopulated from the expense user''s approver.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));
        }
        field(69; "Final Approver Name"; Text[100])
        {
            Caption = 'Final Approver Name';
            ToolTip = 'Specifies the name of the final approver.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Final Approver No.")));
        }
        field(70; "Interim Approver No."; Code[20])
        {
            Caption = 'Interim Approver No.';
            ToolTip = 'Specifies an optional interim approver who must approve before the final approver.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));
        }
        field(71; "Interim Approver Name"; Text[100])
        {
            Caption = 'Interim Approver Name';
            ToolTip = 'Specifies the name of the interim approver.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Interim Approver No.")));
        }
        field(100; "Spend Request No."; Code[20])
        {
            Caption = 'Travel Request No.';
            ToolTip = 'Specifies the travel request number that is associated with this expense report.';
            TableRelation = "Spend Request" where(Status = const(Approved), "Document Type" = const("Travel Request"));

            trigger OnValidate()
            var
                SpendRequest: Record "Spend Request";
                DimensionSetIDArr: array[10] of Integer;
            begin
                if Rec."Spend Request No." <> '' then begin
                    CheckTraveler();
                    SpendRequest.SetSkipSpendRequestClose(GetHideValidationDialog());
                    SpendRequest.ValidateSpendRequest(Rec."Spend Request No.", Rec."Spend Request Close");

                    if SpendRequest."Dimension Set ID" <> 0 then begin
                        DimensionSetIDArr[1] := Rec."Dimension Set ID";
                        DimensionSetIDArr[2] := SpendRequest."Dimension Set ID";
                        Rec."Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                    end;
                end else
                    Rec."Spend Request Close" := false;

                if xRec."Spend Request No." <> Rec."Spend Request No." then
                    UpdateReportLines(Rec.FieldCaption("Spend Request No."));
            end;
        }
        field(101; "Spend Request Close"; Boolean)
        {
            Caption = 'Travel Request Close';
            ToolTip = 'Specifies that the travel request will be closed when the expense report is posted.';
            DataClassification = CustomerContent;
        }
        field(102; "Travel Request SystemId"; Guid)
        {
            Caption = 'Travel Request SystemId';
            ToolTip = 'Specifies the immutable SystemId of the travel request that is associated with this expense report.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Spend Request".SystemId where("No." = field("Spend Request No.")));
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(SpendRequestNo; "Spend Request No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Expense User Name", "Reimbursable Amount (LCY)", Status)
        {
        }
        fieldgroup(Brick; "No.", "Expense User Name", "Reimbursable Amount (LCY)", Status)
        {
        }
    }

    trigger OnInsert()
    var
        NoSeriesManagement: Codeunit "No. Series";
        EAKPITrack: Codeunit "EA KPI Track";
    begin
        if Rec."No." = '' then begin
            ExpenseAgentSetup.GetRecordOnce();
            ExpenseAgentSetup.TestField("Expense Reports Nos.");
            Rec."No." := NoSeriesManagement.GetNextNo(ExpenseAgentSetup."Expense Reports Nos.", WorkDate(), true);
            "No. Series" := ExpenseAgentSetup."Expense Reports Nos.";
        end;

        Rec."Created By" := CopyStr(UserId(), 1, 50);

        SetExpenseUserOnCreate();

        ValidateDate();

        if CalledFromExpenseAgent then
            EAKPITrack.UpdateExpenseReportEntry(Rec);
    end;

    trigger OnModify()
    begin
        UpdateExpenseUserOnModify();
    end;

    trigger OnDelete()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        ExpenseActivityLogMgt.DeleteEntriesForSource(Database::"Expense Report Header", Rec.SystemId);
        ExpenseReportCommentLine.DeleteComments(ExpenseReportCommentLine."Document Type"::"Expense Report", Rec."No.");

        ExpenseReportLine.SetRange("Document No.", Rec."No.");
        ExpenseReportLine.DeleteAll(true);
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        CurrencyDate: Date;
        HideValidationDialog: Boolean;
        SkipExpenseUserApprovalCheck: Boolean;
        CalledFromExpenseAgent: Boolean;
        EmptyGuid: Guid;
        DimChangeQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        DoYouWantToKeepExistingDimensionsQst: Label 'This will change the dimension specified on the document. Do you want to recalculate/update dimensions?';
        InvalidApprovalStatusErr: Label 'Status must be Released or Rejected for Expense Report No. %1.', Comment = '%1 - Expense Report No.';
        NotPendingApprovalErr: Label 'Status must be Pending Approval or Interim Approved for Expense Report No. %1.', Comment = '%1 - Expense Report No.';
        ExpenseUserIsConfiguredForDifferentEmployeeWhenApprovalIsEnabledErr: Label '%1 must be %2 to select this %3 %4.', Comment = '%1 = Field Caption, %2 = User Id, %3 = Table Caption, %4 = Field Value';
        ExpenseApprovalSetupNotExistErr: Label '%1 does not exist for %2 %3.', Comment = '%1 = Table Caption, %2 = Field Caption, %3 = Field Value';
        ExpenseUserSetupNotExistErr: Label '%1 does not exist for %2.', Comment = '%1 = Table Caption, %2 = Field Value';
        CanModifyLinesQst: Label 'You have modified %1 which will also update the lines.\\Do you want to continue?', Comment = '%1 = Field Caption';
        CannotChangeExpenseUserErr: Label 'You cannot change %1 in Expense Report No. %2 as there are associated lines to it.', Comment = '%1 = Field Caption, %2 = Expense Report No.';
        ExpenseUserMustBeLinkedToAnEmployeeErr: Label 'Expense User %1 must be linked to an Employee No.', Comment = '%1 - Expense User No.';
        ExpenseUserNotTravelerErr: Label 'Expense User %1 is not a traveler on Travel Request %2.', Comment = '%1 = Expense User No., %2 = Travel Request No.';

    procedure AssistEdit() Result: Boolean
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.TestField("Expense Reports Nos.");
        if NoSeries.LookupRelatedNoSeries(ExpenseAgentSetup."Expense Reports Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
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
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if ExpenseLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            if not IsNullGuid(Rec.SystemId) then
                Modify();
            if ExpenseLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateReportLines(CalledFromFieldCaption: Text)
    var
        ExpenseReportLine: Record "Expense Report Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ExpenseLinesExist() then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CanModifyLinesQst, CalledFromFieldCaption), true) then
            Error('');

        ExpenseReportLine.SetRange("Document No.", "No.");
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.Initialize(Rec);

                case CalledFromFieldCaption of
                    Rec.FieldCaption("Reimbursement Currency Code"), Rec.FieldCaption("Reimbursement Currency Factor"):
                        UpdateCurrFactorOnReportLine(ExpenseReportLine);
                    Rec.FieldCaption("VAT Bus. Posting Group"):
                        UpdateVATBusPostingGroupOnReportLine(ExpenseReportLine);
                    Rec.FieldCaption("Posting Date"):
                        UpdatePostingDateOnReportLine(ExpenseReportLine);
                    Rec.FieldCaption("Spend Request No."):
                        UpdateSpendRequestOnReportLine(ExpenseReportLine);
                end;
            until ExpenseReportLine.Next() = 0;

        if CalledFromFieldCaption in [Rec.FieldCaption("Reimbursement Currency Code"), Rec.FieldCaption("Reimbursement Currency Factor"), Rec.FieldCaption("Posting Date")] then
            UpdateVATSpecReimbursementAmounts();
    end;

    local procedure UpdateVATSpecReimbursementAmounts()
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseReportLineVATSpec.SetRange("Document No.", "No.");
        ExpenseReportLineVATSpec.SetLoadFields(
            "Currency Code", "VAT Base Amount (LCY)", "VAT Amount", "VAT Amount (LCY)", "Amount (LCY)", "Reclaim %",
            "VAT Base Amount (RCY)", "VAT Amount (RCY)", "Amount (RCY)", "Reclaim VAT Amount",
            "Reclaim VAT Amount (LCY)", "Reclaim VAT Amount (RCY)");
        if ExpenseReportLineVATSpec.FindSet(true) then
            repeat
                ExpenseReportLineVATSpec.UpdateReimbursementAmounts(Rec);
#pragma warning disable AA0214
                ExpenseReportLineVATSpec.Modify();
#pragma warning restore AA0214                
            until ExpenseReportLineVATSpec.Next() = 0;
    end;

    local procedure UpdateCurrFactorOnReportLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLine.UpdateAmounts();
        ExpenseReportLine.Modify(true);
    end;

    local procedure UpdateVATBusPostingGroupOnReportLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        if Rec."VAT Bus. Posting Group" <> ExpenseReportLine."VAT Bus. Posting Group" then begin
            ExpenseReportLine."VAT Bus. Posting Group" := Rec."VAT Bus. Posting Group";
            ExpenseReportLine.Validate("VAT Prod. Posting Group");
            ExpenseReportLine.UpdateAmounts();
            ExpenseReportLine.Modify(true);
        end;
    end;

    local procedure UpdatePostingDateOnReportLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLine.UpdateAmounts();
        ExpenseReportLine.Modify(true);
    end;

    local procedure UpdateSpendRequestOnReportLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        if (Rec."Spend Request No." <> ExpenseReportLine."Spend Request No.") and ExpenseReportLine.Refundable then begin
            ExpenseReportLine.SetSkipSpendRequestClose(true);
            ExpenseReportLine.Validate("Spend Request No.", Rec."Spend Request No.");
            ExpenseReportLine."Spend Request Close" := Rec."Spend Request Close";
            ExpenseReportLine.SetSkipSpendRequestClose(false);
            ExpenseReportLine.Modify(true);
        end;
    end;

    procedure ExpenseLinesExist(): Boolean
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", "No.");

        exit(not ExpenseReportLine.IsEmpty());
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
        xExpenseReportLine: Record "Expense Report Line";
        NewDimSetID: Integer;
    begin
        if NewParentDimSetID = OldParentDimSetID then
            exit;

        if not GetHideValidationDialog() and GuiAllowed then
            if not ConfirmUpdateAllLineDim() then
                exit;

        ExpenseReportLine.SetRange("Document No.", "No.");
        ExpenseReportLine.LockTable();
        if ExpenseReportLine.FindSet() then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ExpenseReportLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ExpenseReportLine."Dimension Set ID" <> NewDimSetID then begin
                    xExpenseReportLine := ExpenseReportLine;
                    ExpenseReportLine."Dimension Set ID" := NewDimSetID;

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ExpenseReportLine."Dimension Set ID", ExpenseReportLine."Shortcut Dimension 1 Code", ExpenseReportLine."Shortcut Dimension 2 Code");

                    ExpenseReportLine.Modify(true);
                end;
            until ExpenseReportLine.Next() = 0;
    end;

    /// <summary>
    /// Releases the expense document if it's not already released.
    /// </summary>
    /// <remarks>
    /// The transaction is committed after release.
    /// </remarks>
    procedure PerformManualRelease()
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        ReleaseExpenseReportDoc.PerformManualRelease(Rec);
        Commit();
    end;

    /// <summary>
    /// Releases the sales documents that are not yet released.
    /// </summary>
    /// <param name="ExpenseReportHeader">Filtered Expenses to release.</param>
    procedure PerformManualRelease(var ExpenseReportHeader: Record "Expense Report Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
        PrevFilterGroup: Integer;
    begin
        NoOfSelected := ExpenseReportHeader.Count;
        PrevFilterGroup := ExpenseReportHeader.FilterGroup();
        ExpenseReportHeader.FilterGroup(10);
        ExpenseReportHeader.SetFilter(Status, '<>%1', ExpenseReportHeader.Status::Released);
        NoOfSkipped := NoOfSelected - ExpenseReportHeader.Count;
        BatchProcessingMgt.BatchProcess(ExpenseReportHeader, Codeunit::"Expense Report Manual Release", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
        ExpenseReportHeader.SetRange(Status);
        ExpenseReportHeader.FilterGroup(PrevFilterGroup);
    end;

    /// <summary>
    /// Reopens sales documents that are not already open.
    /// </summary>
    /// <param name="ExpenseReportHeader">Filtered Expenses to reopen.</param>
    procedure PerformManualReopen(var ExpenseReportHeader: Record "Expense Report Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
    begin
        NoOfSelected := ExpenseReportHeader.Count;
        ExpenseReportHeader.SetFilter(Status, '<>%1', ExpenseReportHeader.Status::Open);
        NoOfSkipped := NoOfSelected - ExpenseReportHeader.Count;
        BatchProcessingMgt.BatchProcess(ExpenseReportHeader, Codeunit::"Expense Report Manual Reopen", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
    end;

    /// <summary>
    /// Pending Approval the expense document if it's not already "Pending Approval".
    /// </summary>
    /// <remarks>
    /// The transaction is committed after pending approval.
    /// </remarks>
    /// <param name="SubmitterExpenseUserNo">The expense user number of the submitter.</param>
    procedure PerformManualPendingApproval(SubmitterExpenseUserNo: Code[20])
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        if Rec.Status = Rec.Status::"Pending Approval" then
            exit;

        ReleaseExpenseReportDoc.PerformManualPendingApproval(Rec, SubmitterExpenseUserNo);
        Commit();
    end;

    /// <summary>
    /// Releases and marks as pending approval in a single atomic operation.
    /// </summary>
    /// <param name="SubmitterExpenseUserNo">The expense user number of the submitter.</param>
    procedure PerformManualReleaseAndPendingApproval(SubmitterExpenseUserNo: Code[20])
    begin
        PerformManualReleaseAndPendingApproval(SubmitterExpenseUserNo, '');
    end;

    /// <summary>
    /// Releases and submits an expense report with an optional submitter comment.
    /// </summary>
    /// <param name="SubmitterExpenseUserNo">The expense user number of the submitter.</param>
    /// <param name="SubmissionComment">The optional comment supplied by the submitter.</param>
    procedure PerformManualReleaseAndPendingApproval(SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        ReleaseExpenseReportDoc.PerformManualReleaseAndPendingApproval(Rec, SubmitterExpenseUserNo, SubmissionComment);
    end;

    /// <summary>
    /// Approved the expense document if it's not already "Approved".
    /// </summary>
    /// <remarks>
    /// The transaction is committed after approval.
    /// </remarks>
    /// <param name="ApproverExpenseUserNo">The expense user number of the approver.</param>
    procedure PerformManualApproved(ApproverExpenseUserNo: Code[20])
    begin
        PerformManualApproved(ApproverExpenseUserNo, false);
    end;

    /// <summary>
    /// Approves the expense document, optionally skipping policy validation.
    /// </summary>
    /// <param name="ApproverExpenseUserNo">The expense user number of the approver.</param>
    /// <param name="SkipPolicyValidation">Specifies whether approval can proceed with stale or unevaluated policies.</param>
    procedure PerformManualApproved(ApproverExpenseUserNo: Code[20]; SkipPolicyValidation: Boolean)
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        if Rec.Status = Rec.Status::Approved then
            exit;

        ReleaseExpenseReportDoc.PerformManualApproved(Rec, ApproverExpenseUserNo, SkipPolicyValidation);
        Commit();
    end;

    /// <summary>
    /// Rejected the expense document if it's not already "Rejected".
    /// </summary>
    /// <remarks>
    /// The transaction is committed after rejection.
    /// </remarks>
    /// <param name="ApproverExpenseUserNo">The expense user number of the approver.</param>
    /// <param name="RejectReason">The reason for rejection.</param>
    procedure PerformManualRejected(ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        if Rec.Status = Rec.Status::Rejected then
            exit;

        ReleaseExpenseReportDoc.PerformManualRejected(Rec, ApproverExpenseUserNo, RejectReason);
        Commit();
    end;

    procedure PerformManualRejectedAndReopen(ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
    begin
        ReleaseExpenseReportDoc.PerformManualRejectedAndReopen(Rec, ApproverExpenseUserNo, RejectReason);
    end;

    /// <summary>
    /// Sets the value of the global flag HideValidationDialog.
    /// </summary>
    /// <remarks>
    /// Global flag HideValidationDialog is used to hide various confirmation/message/other dialogs.
    /// </remarks>
    /// <param name="NewHideValidationDialog">The new value to set.</param>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    /// <summary>
    /// Returns the value of the global flag HideValidationDialog.
    /// </summary>
    /// <remarks>
    /// Global flag HideValidationDialog is used to hide various confirmation/message/other dialogs.
    /// </remarks>
    /// <returns>The value of the global flag HideValidationDialog.</returns>
    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    /// <summary>
    /// Returns document status field style expression based on the status of the sales header.
    /// </summary>
    /// <returns>Status style expression.</returns>
    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';
    end;

    /// <summary>
    /// Checks if expense status is open. If it is not, an error is raised.
    /// </summary>
    procedure TestStatusOpen()
    begin
        Rec.TestField(Status, Status::Open);
    end;

    /// <summary>
    /// Retrieves approver comment from the expense report header.
    /// </summary>
    /// <returns>Approver comment.</returns>
    procedure GetApproverComment() ApproverComment: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Approver Comment");
        Rec."Approver Comment".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName(Rec."Approver Comment")));
    end;

    /// <summary>
    /// Retrieves submitter comment from the expense report header.
    /// </summary>
    /// <returns>Submitter comment.</returns>
    procedure GetSubmitterComment() SubmitterComment: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Submitter Comment");
        Rec."Submitter Comment".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName(Rec."Submitter Comment")));
    end;

    local procedure ConfirmUpdateAllLineDim() Confirmed: Boolean;
    begin
        Confirmed := Confirm(DimChangeQst);
    end;

    local procedure ValidateDate()
    begin
        if Rec."Posting Date" = 0D then
            Rec.Validate("Posting Date", WorkDate());
        if Rec."Expense Report Date" = 0D then
            Rec.Validate("Expense Report Date", WorkDate());
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

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    var
        ExpenseUser: Record "Expense User";
        EmployeeNo: Code[20];
    begin
        if ExpenseUser.Get(Rec."Expense User No.") then
            EmployeeNo := ExpenseUser."Employee No.";

        DimMgt.AddDimSource(DefaultDimSource, Database::Employee, EmployeeNo, FieldNo = Rec.FieldNo("Expense User No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", GetSalesPersonCodeFromEmployee());
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Expense, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);


        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) and GuiAllowed and not GetHideValidationDialog() then
            if CouldDimensionsBeKept() then
                if not ConfirmKeepExistingDimensions() then begin
                    "Dimension Set ID" := OldDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(Rec."Dimension Set ID", Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                end;

        if (OldDimSetID <> "Dimension Set ID") and ExpenseLinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure Preview(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpensePreviewPostMgt: Codeunit "Expense Preview Post Mgt.";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(ExpensePreviewPostMgt);
        GenJnlPostPreview.Preview(ExpensePreviewPostMgt, ExpenseReportHeader);
    end;

    /// <summary>
    /// Updates currency factor on the report header
    /// </summary>
    procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        if Rec."Reimbursement Currency Code" <> '' then begin
            if Rec."Posting Date" <> 0D then
                CurrencyDate := "Posting Date"
            else
                CurrencyDate := WorkDate();

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, Rec."Reimbursement Currency Code") then begin
                Rec."Reimbursement Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, Rec."Reimbursement Currency Code");
                if (Rec."Reimbursement Currency Code" <> xRec."Reimbursement Currency Code") and (xRec."No." <> '') then
                    UpdateReportLines(Rec.FieldCaption("Reimbursement Currency Code"));
            end else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Reimbursement Currency Code");
        end else begin
            Rec."Reimbursement Currency Factor" := 0;
            if "Reimbursement Currency Code" <> xRec."Reimbursement Currency Code" then
                UpdateReportLines(Rec.FieldCaption("Reimbursement Currency Code"));
        end;
    end;

    local procedure CouldDimensionsBeKept(): Boolean;
    begin
        if (xRec."Expense User No." <> '') and (xRec."Expense User No." <> Rec."Expense User No.") then
            exit(false);
        if (xRec."Responsibility Center" <> '') and (xRec."Responsibility Center" <> Rec."Responsibility Center") then
            exit(true);
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

    procedure CheckExpenseReportPostRestrictions()
    begin
        OnCheckExpenseReportPostRestrictions();
    end;

    local procedure ConfirmKeepExistingDimensions() Confirmed: Boolean
    begin
        Confirmed := Confirm(DoYouWantToKeepExistingDimensionsQst);
    end;

    local procedure UpdateFromEmployee()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
    begin
        if Rec."Expense User No." <> '' then begin
            ExpenseUser.Get(Rec."Expense User No.");

            Rec.Validate("Expense User Name", ExpenseUser."Name");
            if not Employee.Get(ExpenseUser."Employee No.") then
                Error(ExpenseUserMustBeLinkedToAnEmployeeErr, ExpenseUser."No.");

            Employee.TestField("Employee Posting Group");

            Rec.Validate("Employee Posting Group", Employee."Employee Posting Group");
            Rec.Validate("Reimbursement Currency Code", Employee."Currency Code")
        end else begin
            Rec.validate("Expense User Name", '');
            Rec.Validate("Employee Posting Group", '');
        end;
    end;

    procedure UpdateApproverID()
    begin
        GetApproverId(Rec."Approver Expense User No.", Rec."Approver Expense User ID");
    end;

    local procedure GetApproverId(var ApproverExpenseUserNo: Code[20]; var ApproverExpenseUserID: Code[50])
    var
        ExpenseUser: Record "Expense User";
    begin
        GetExpenseApproverUser(ExpenseUser);

        ApproverExpenseUserNo := ExpenseUser."No.";
        ApproverExpenseUserID := ExpenseUser."User Id For Approvals";
    end;

    internal procedure TestApprovalStatus()
    begin
        if not (Rec.Status in [Rec.Status::Released, Rec.Status::Rejected]) then
            Error(InvalidApprovalStatusErr, Rec."No.");
    end;

    internal procedure TestApprovalPending()
    begin
        if not (Rec.Status in [Rec.Status::"Pending Approval", Rec.Status::"Interim Approved"]) then
            Error(NotPendingApprovalErr, Rec."No.");
    end;

    /// <summary>
    /// Assigns an optional interim approver who must approve before the final approver.
    /// </summary>
    procedure AssignInterimApprover(NewApproverExpenseUserNo: Code[20])
    begin
        AssignInterimApprover(NewApproverExpenseUserNo, '');
    end;

    internal procedure AssignInterimApprover(NewApproverExpenseUserNo: Code[20]; ActorExpenseUserNo: Code[20])
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ExpenseReportApprovalMgmt.AssignInterimApprover(Rec, NewApproverExpenseUserNo, ActorExpenseUserNo);
    end;

    local procedure GetFinalApproverNo(ExpenseUserNo: Code[20]): Code[20]
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        if ExpenseUserNo = '' then
            exit('');

        if ExpenseApprovalSetup.Get(ExpenseUserNo) and (ExpenseApprovalSetup."Approver No." <> '') then
            exit(ExpenseApprovalSetup."Approver No.");

        ExpenseAgentSetup.GetRecordOnce();
        exit(ExpenseAgentSetup."Default Approver No.");
    end;

    local procedure GetExpenseApproverUser(var ExpenseUser: Record "Expense User")
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseApprovalSetup.Get(Rec."Expense User No.") then
            if ExpenseAgentSetup."Default Approver No." = '' then
                Error(ExpenseApprovalSetupNotExistErr, ExpenseApprovalSetup.TableCaption, Rec.FieldCaption("Expense User No."), Rec."Expense User No.");

        if ExpenseAgentSetup."Default Approver No." = '' then
            ExpenseApprovalSetup.TestField("Approver No.");

        if not ExpenseUser.Get(ExpenseApprovalSetup."Approver No.") then
            if not ExpenseUser.Get(ExpenseAgentSetup."Default Approver No.") then
                Error(ExpenseUserSetupNotExistErr, ExpenseUser.TableCaption, ExpenseApprovalSetup."Approver No.");

        ExpenseUser.TestField("User Id For Approvals");
    end;

    local procedure CheckExpenseUserWhenApprovalIsEnabled()
    var
        UserSetup: Record "User Setup";
        ExpenseUser: Record "Expense User";
    begin
        if SkipExpenseUserApprovalCheck then
            exit;

        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Enable Approval Workflow" then
            exit;

        UserSetup.SetLoadFields("Unlimited Expense Approval");
        UserSetup.Get(UserId);
        if UserSetup."Unlimited Expense Approval" then
            exit;

        ExpenseUser.Get(Rec."Expense User No.");
        if ExpenseUser."User Id For Approvals" <> UserId then
            Error(ExpenseUserIsConfiguredForDifferentEmployeeWhenApprovalIsEnabledErr, ExpenseUser.FieldCaption("User Id For Approvals"), UserId, ExpenseUser.TableCaption, Rec."Expense User No.");
    end;

    internal procedure SetCalledFromExpenseAgent(NewCalledFromExpenseAgent: Boolean)
    begin
        CalledFromExpenseAgent := NewCalledFromExpenseAgent;
    end;

    internal procedure CreateFromApprovedTravelRequest(SpendRequest: Record "Spend Request")
    var
        ExistingExpenseReportHeader: Record "Expense Report Header";
        NewExpenseReportHeader: Record "Expense Report Header";
    begin
        SpendRequest.TestField("Document Type", SpendRequest."Document Type"::"Travel Request");
        SpendRequest.TestStatus(SpendRequest.Status::Approved);
        SpendRequest.TestField("Requested For");

        ExistingExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        if not ExistingExpenseReportHeader.IsEmpty() then
            exit;

        NewExpenseReportHeader.Init();
        NewExpenseReportHeader.Validate(Description, CopyStr(SpendRequest.Purpose, 1, MaxStrLen(NewExpenseReportHeader.Description)));
        NewExpenseReportHeader.ValidateExpenseUserFromApprovedTravelRequest(SpendRequest."Requested For");
        NewExpenseReportHeader.Validate("Reimbursement Currency Code", SpendRequest."Currency Code");
        NewExpenseReportHeader.SetHideValidationDialog(true);
        NewExpenseReportHeader.Validate("Spend Request No.", SpendRequest."No.");
        NewExpenseReportHeader.Insert(true);
    end;

    internal procedure ValidateExpenseUserFromApprovedTravelRequest(ExpenseUserNo: Code[20])
    begin
        SkipExpenseUserApprovalCheck := true;
        Rec.Validate("Expense User No.", ExpenseUserNo);
        SkipExpenseUserApprovalCheck := false;
    end;

    local procedure CheckTraveler()
    var
        Traveler: Record Traveler;
    begin
        Rec.TestField("Expense User No.");

        Traveler.SetRange("Spend Request No.", Rec."Spend Request No.");
        Traveler.SetRange("Expense User No.", Rec."Expense User No.");
        if Traveler.IsEmpty() then
            Error(ExpenseUserNotTravelerErr, Rec."Expense User No.", Rec."Spend Request No.");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckExpenseReportPostRestrictions()
    begin
    end;
}
