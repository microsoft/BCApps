// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using System.Agents;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Telemetry;
using System.Utilities;

table 6930 "Expense Agent Setup"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = rimdX;
    DataClassification = CustomerContent;
    Permissions = tabledata "Expense Agent Setup" = ri;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Expense Reports Nos."; Code[20])
        {
            Caption = 'Expense Reports Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series used to create new expense reports.';
        }
        field(3; "Posted Expense Reports Nos."; Code[20])
        {
            Caption = 'Posted Expense Reports Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series used for posted expense reports.';
        }
        field(4; "Expense Nos."; Code[20])
        {
            Caption = 'Expenses Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series used to create expenses.';
        }
        field(5; "Use Rules"; Boolean)
        {
            Caption = 'Apply rules';
            ToolTip = 'Specifies whether configured expense management rules are applied.';
        }
        field(6; "Enable Agent"; Boolean)
        {
            Caption = 'Enable agent';
            ToolTip = 'Specifies whether the agent is enabled to process expense submissions from email and calendar.';

            trigger OnValidate()
            begin
                if not "Enable Agent" then
                    RemoveAllScheduledTasks();
                if Rec."Enable Agent" then
                    CheckBeforeEnablingAgent();

                if (not xRec."Enable Agent") and Rec."Enable Agent" then
                    LogAgentEnabledTelemetry();

                if xRec."Enable Agent" and (not Rec."Enable Agent") then
                    LogAgentDisabledTelemetry();
            end;
        }
        field(7; "Exchange Rate for Expenses"; Enum "Expense Exchange Rate")
        {
            Caption = 'Exchange Rate for Expenses';
            ToolTip = 'Specifies which exchange rate to use when converting foreign currency expenses.';
        }
        field(8; "Do Not Allow Exp. Older Than"; DateFormula)
        {
            Caption = 'Do not allow expenses older than';
            ToolTip = 'Specifies a date formula; expenses older than the resulting date are not allowed.';
        }
        field(9; "If Exp. Is Older Than Allowed"; Enum "Expense Age Handling")
        {
            Caption = 'If expense is older than allowed';
            ToolTip = 'Specifies how the system handles expenses older than the allowed date: warn, require justification, or block submission.';
        }
        field(10; "Allow Prepayment-Cash Advance"; Boolean)
        {
            Caption = 'Allow prepayment-cash advance';
            ToolTip = 'Specifies whether prepayments and cash advances are allowed.';
        }
        field(11; "Allow Grp. of Trans. in Report"; Boolean)
        {
            Caption = 'Allow grouping of transactions in report';
            ToolTip = 'Specifies whether similar transactions are grouped together in expense reports.';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                FeatureTelemetry.LogUptake('0000TE9', GetFeatureName(), Enum::"Feature Uptake Status"::Used);
            end;
        }
        field(12; "Exp. Report Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Expense Report Rounding Precision';
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
            ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
#endif
            ToolTip = 'Specifies the rounding precision for amounts in expense reports.';
        }
#if not CLEANSCHEMA29
#pragma warning disable AL0432
#pragma warning disable AS0105
        field(13; "Expense Report Rounding Type"; Enum "Expense Report Rounding Type")
#pragma warning restore AL0432
#pragma warning restore AS0105
        {
            Caption = 'Expense Report Rounding Type';
#if CLEAN29
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
#pragma warning disable AS0072 // Bug 647877: temporary v30 suppression, restore ObsoleteTag to 30.0
            ObsoleteTag = '29.0';
#pragma warning restore AS0072
            ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
            ToolTip = 'Specifies how amounts are rounded: nearest, up, or down.';
        }
#endif
        field(14; "Check Category/SubCat. Usage"; Boolean)
        {
            Caption = 'Check category/subcategory usage';
            ToolTip = 'Specifies whether both category and subcategory are required on each expense.';
        }
        field(15; "Create Exp. Rep. Automatically"; Boolean)
        {
            Caption = 'Create Expense Reports Automatically';
            ToolTip = 'Specifies whether the system automatically creates expense reports according to the selected frequency.';
        }
        field(16; "When to Create Expense Reports"; Enum "Expense Report Frequency")
        {
            Caption = 'When To Create Expense Reports';
            ToolTip = 'Specifies how often the system automatically creates expense reports, for example daily or weekly.';

            trigger OnValidate()
            begin
                if xRec."When to Create Expense Reports" <> Rec."When to Create Expense Reports" then
                    case Rec."When to Create Expense Reports" of
                        "Expense Report Frequency"::Daily, "Expense Report Frequency"::" ":
                            begin
                                Rec."Day of Week" := Rec."Day of Week"::Sunday;
                                Rec."Day In A Month" := 0;
                                Clear(Rec."Custom Report Creation Formula");
                            end;
                        "Expense Report Frequency"::Weekly:
                            begin
                                Rec."Day In A Month" := 0;
                                Clear(Rec."Custom Report Creation Formula");
                            end;
                        "Expense Report Frequency"::Monthly:
                            begin
                                Rec."Day of Week" := Rec."Day of Week"::Sunday;
                                Clear(Rec."Custom Report Creation Formula");
                            end;
                        "Expense Report Frequency"::Custom:
                            begin
                                Rec."Day of Week" := Rec."Day of Week"::Sunday;
                                Rec."Day In A Month" := 0;
                            end;
                    end;
            end;
        }
        field(17; "Custom Report Creation Formula"; DateFormula)
        {
            Caption = 'Custom Formula For Expense Report Creation';
            ToolTip = 'Specifies a custom date formula used when creating expense reports automatically.';

            trigger OnValidate()
            begin
                if xRec."Custom Report Creation Formula" <> Rec."Custom Report Creation Formula" then
                    Rec.TestField("When to Create Expense Reports", "Expense Report Frequency"::Custom);
            end;
        }
        field(18; "Communication Channel"; Enum "Expense Communication Channel")
        {
            Caption = 'Communication Channel';
            ToolTip = 'Specifies the communication channel used to send expense notifications.';
        }
        field(19; "System Communication Channel"; Text[100])
        {
            Caption = 'System Communication Channel';
            ToolTip = 'Specifies the identifier or email address used as the system communication channel.';
        }
        field(20; "Approval Reminder After"; DateFormula)
        {
            Caption = 'Approval Reminder After';
            ToolTip = 'Specifies how long to wait before sending approval reminders for pending expense reports.';
        }
        field(21; "Standard Rate of Mileage"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Standard Rate of Mileage';
            ToolTip = 'Specifies the default mileage reimbursement rate.';
        }
        field(22; "Full Per-Diem Calculation"; Enum "Exp. Full Per Diem Calculation")
        {
            Caption = 'Full Per-Diem Calculation';
            ToolTip = 'Specifies the rule used to calculate full per diem, for example by calendar day or by hours.';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                FeatureTelemetry.LogUptake('0000TEA', GetFeatureName(), Enum::"Feature Uptake Status"::Used);

                if "Full Per-Diem Calculation" = "Full Per-Diem Calculation"::None then begin
                    "Partial Day Rules" := "Partial Day Rules"::"Flat Percentage Of Full Rate";
                    "Minimum Hours for Per Diem" := 0;
                    "Min Hours for Partial Per Diem" := 0;
                end;

                if not (Rec."Full Per-Diem Calculation" in [Enum::"Exp. Full Per Diem Calculation"::"24-hour Rolling Period", Enum::"Exp. Full Per Diem Calculation"::"Overnight Stay"]) then
                    Rec.Validate("Minimum Hours for Per Diem", 0);

                case "Full Per-Diem Calculation" of
                    "Full Per-Diem Calculation"::"Full Calendar Day":
                        "Partial Day Rules" := "Partial Day Rules"::"Flat Percentage Of Full Rate";
                    "Full Per-Diem Calculation"::"24-hour Rolling Period", "Full Per-Diem Calculation"::"Overnight Stay":
                        "Partial Day Rules" := "Partial Day Rules"::"Based On Eligible Hours";
                end;
            end;
        }
        field(23; "Per Diem Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Per Diem Rounding Precision';
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
            ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
#endif
            ToolTip = 'Specifies the rounding precision for per diem amounts.';
        }
        field(24; "Minimum Hours for Per Diem"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Hours for Per Diem';
            ToolTip = 'Specifies the minimum number of hours required to qualify for per diem.';

            trigger OnValidate()
            begin
                if (Rec."Minimum Hours for Per Diem" <> 0) and (not (Rec."Full Per-Diem Calculation" in [Enum::"Exp. Full Per Diem Calculation"::"24-hour Rolling Period", Enum::"Exp. Full Per Diem Calculation"::"Overnight Stay"])) then
                    Error(CannotUseMinHoursErr, Enum::"Exp. Full Per Diem Calculation"::"24-hour Rolling Period", Enum::"Exp. Full Per Diem Calculation"::"Overnight Stay");
            end;
        }
        field(25; "Partial Day Rules"; Enum "Expense Partial Day Rules")
        {
            Caption = 'Partial Day Rules';
            ToolTip = 'Specifies how per diem for partial days is determined.';

            trigger OnValidate()
            begin
                if xRec."Partial Day Rules" <> Rec."Partial Day Rules" then
                    case Rec."Partial Day Rules" of
                        Enum::"Expense Partial Day Rules"::"Based On Eligible Hours":
                            Rec.TestField(Rec."Full Per-Diem Calculation", Rec."Full Per-Diem Calculation"::"Full Calendar Day");
                        Enum::"Expense Partial Day Rules"::"Flat Percentage Of Full Rate":
                            if not (Rec."Full Per-Diem Calculation" in [Enum::"Exp. Full Per Diem Calculation"::"24-hour Rolling Period", Enum::"Exp. Full Per Diem Calculation"::"Overnight Stay"]) then
                                Error(InvalidPartialDaysRuleErr, Rec."Partial Day Rules", Enum::"Exp. Full Per Diem Calculation"::"24-hour Rolling Period", Enum::"Exp. Full Per Diem Calculation"::"Overnight Stay");
                    end;
            end;
        }
        field(26; "Reduction for Breakfast %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reduction for Breakfast %';
            ToolTip = 'Specifies the percentage deducted from the per diem when breakfast is provided.';
        }
        field(27; "Reduction for Lunch %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reduction for Lunch %';
            ToolTip = 'Specifies the percentage deducted from the per diem when lunch is provided.';
        }
        field(28; "Reduction for Dinner %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reduction for Dinner %';
            ToolTip = 'Specifies the percentage deducted from the per diem when dinner is provided.';
        }
        field(29; "Time Tolerance for Calendar"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Time Tolerance for Calendar';
            ToolTip = 'Specifies the allowed time deviation when matching calendar events to expenses.';
        }
        field(30; "Enable Anti-Corp. Statement"; Boolean)
        {
            Caption = 'Display anti-corruption attestation';
            ToolTip = 'Specifies whether users must confirm an anti-corruption attestation before submitting expenses.';
        }
        field(31; "Evaluate Policies"; Boolean)
        {
            Caption = 'Evaluate policies';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the agent automatically evaluates expenses against the configured policies. This feature consumes additional AI credits.';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if "Evaluate Policies" and (not xRec."Evaluate Policies") then
                    FeatureTelemetry.LogUptake('0000V3F', GetFeatureName(), Enum::"Feature Uptake Status"::Used);
            end;
        }
        field(32; "Submitter-run Evaluation"; Boolean)
        {
            Caption = 'Allow submitters to evaluate policies';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether submitters can preventively run policy evaluation before submitting expense reports. This evaluation will consume additional AI credits.';
        }
        field(34; "Expense User Nos."; Code[20])
        {
            Caption = 'Expense User Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series for creating individual Expense Users.';
        }
        field(35; "Expense Vendor Nos."; Code[20])
        {
            Caption = 'Expense Vendor Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series used when creating Expense Vendor records for accountant review.';
        }
        field(37; "Min Hours for Partial Per Diem"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Hours for Partial Per-Diem';
            ToolTip = 'Specifies the minimum number of hours required to qualify for a partial per diem.';
        }
        field(38; "Percentage For Partial Day"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Percentage For Partial Day';
            ToolTip = 'Specifies the percentage of the full per diem to apply for partial days.';
        }
        field(39; "Receipt No. Mandatory"; Boolean)
        {
            Caption = 'Receipt No. Mandatory';
            ToolTip = 'Specifies whether a receipt number is mandatory for expenses.';
        }
        field(40; "Merchant Name Mandatory"; Boolean)
        {
            Caption = 'Merchant Name Mandatory';
            ToolTip = 'Specifies whether a merchant name is mandatory for expenses.';
        }
        field(41; "Default Mileage UOM"; Code[10])
        {
            Caption = 'Default Mileage UOM';
            ToolTip = 'Specifies the default unit of measure for mileage.';
            TableRelation = "Unit of Measure";
        }
        field(42; "Only Shortest Route"; Boolean)
        {
            Caption = 'Only Shortest Route';
            ToolTip = 'Specifies whether only the shortest route is shown for mileage expenses. When enabled, alternative routes are not displayed on the map and only the shortest route is used for distance calculation.';
        }
        field(52; "User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(53; "Email Account ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(54; "Email Connector"; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }
        field(60; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
            ToolTip = 'Specifies the email address used by the agent.';
        }
        field(61; "Email Folder"; Text[2048])
        {
            Caption = 'Email Folder';
            ToolTip = 'Specifies the email folder the agent monitors.';
        }
        field(62; "Email Folder Id"; Text[2048])
        {
            Caption = 'Email Folder Id';
            ToolTip = 'Specifies the unique identifier of the email folder the agent monitors.';
            DataClassification = SystemMetadata;
        }
        field(76; "Open Report Notif. Freq."; Enum "Expense Report Frequency")
        {
            Caption = 'Open Report Notification Frequency';
            ToolTip = 'Specifies how often the system should send notifications for open expense reports (Daily, Weekly, etc.).';
            InitValue = Daily;

            trigger OnValidate()
            begin
                if xRec."Open Report Notif. Freq." <> Rec."Open Report Notif. Freq." then
                    case Rec."Open Report Notif. Freq." of
                        "Expense Report Frequency"::Daily, "Expense Report Frequency"::" ":
                            begin
                                Rec."Notif. Day of Week" := Rec."Notif. Day of Week"::Sunday;
                                Rec."Notif. Day In A Month" := 0;
                                Clear(Rec."Custom Notif. Formula");
                            end;
                        "Expense Report Frequency"::Weekly:
                            begin
                                Rec."Notif. Day In A Month" := 0;
                                Clear(Rec."Custom Notif. Formula");
                            end;
                        "Expense Report Frequency"::Monthly:
                            begin
                                Rec."Notif. Day of Week" := Rec."Notif. Day of Week"::Sunday;
                                Rec."Notif. Day In A Month" := 1;
                                Clear(Rec."Custom Notif. Formula");
                            end;
                        "Expense Report Frequency"::Custom:
                            begin
                                Rec."Notif. Day of Week" := Rec."Notif. Day of Week"::Sunday;
                                Rec."Notif. Day In A Month" := 0;
                            end;
                    end;
            end;
        }
        field(80; "Enable Approval Workflow"; Boolean)
        {
            Caption = 'Enable approval workflow';
            ToolTip = 'Specifies whether approval workflow is enabled for expense reports.';

            trigger OnValidate()
            begin
                if Rec."Enable Approval Workflow" then
                    Rec.TestField("Enable Agent", false);

                if (not Rec."Enable Approval Workflow") and xRec."Enable Approval Workflow" then
                    CheckBeforeDisableApprovalWorkflow();
            end;
        }
        field(81; "Day of Week"; Enum "Day of Week")
        {
            Caption = 'Day of Week';
            ToolTip = 'Specifies the day of the week used when expense reports are created weekly.';

            trigger OnValidate()
            begin
                if not IsNullGuid(xRec.SystemId) then
                    if xRec."Day of Week" <> Rec."Day of Week" then
                        Rec.TestField("When to Create Expense Reports", "Expense Report Frequency"::Weekly);
            end;
        }
        field(82; "Day In A Month"; Integer)
        {
            Caption = 'Day In A Month';
            ToolTip = 'Specifies the day of the month used when expense reports are created monthly.';

            trigger OnValidate()
            begin
                if Rec."Day In A Month" <> 0 then
                    if (Rec."Day In A Month" < 1) or (Rec."Day In A Month" > 31) then
                        Error(InvalidDayErr, Rec.FieldCaption("Day In A Month"));

                if not IsNullGuid(xRec.SystemId) then
                    if xRec."Day In A Month" <> Rec."Day In A Month" then
                        Rec.TestField("When to Create Expense Reports", "Expense Report Frequency"::Monthly);
            end;
        }
        field(83; "Expense Report Grouping"; Enum "Expense Reports Grouping")
        {
            Caption = 'Expense Report Grouping';
            ToolTip = 'Specifies how expense reports are grouped when they are created automatically.';
        }
        field(84; "Enable Open Report Notif."; Boolean)
        {
            Caption = 'Enable Open Report Notifications';
            ToolTip = 'Specifies whether the system sends periodic notifications for open expense reports. Notifications are only sent when a mailbox is configured.';
        }
        field(85; "Notif. Day of Week"; Enum "Day of Week")
        {
            Caption = 'Notification Day of Week';
            ToolTip = 'Specifies the day of the week for weekly open report notifications.';

            trigger OnValidate()
            begin
                if not IsNullGuid(xRec.SystemId) then
                    if xRec."Notif. Day of Week" <> Rec."Notif. Day of Week" then
                        Rec.TestField("Open Report Notif. Freq.", "Expense Report Frequency"::Weekly);
            end;
        }
        field(86; "Notif. Day In A Month"; Integer)
        {
            Caption = 'Notification Day In A Month';
            ToolTip = 'Specifies the day of the month for monthly open report notifications.';

            trigger OnValidate()
            begin
                if Rec."Notif. Day In A Month" <> 0 then
                    if (Rec."Notif. Day In A Month" < 1) or (Rec."Notif. Day In A Month" > 31) then
                        Error(InvalidDayErr, Rec.FieldCaption("Notif. Day In A Month"));

                if not IsNullGuid(xRec.SystemId) then
                    if xRec."Notif. Day In A Month" <> Rec."Notif. Day In A Month" then
                        Rec.TestField("Open Report Notif. Freq.", "Expense Report Frequency"::Monthly);
            end;
        }
        field(87; "Custom Notif. Formula"; DateFormula)
        {
            Caption = 'Custom Notification Formula';
            ToolTip = 'Specifies a custom date formula to use for open report notification scheduling.';

            trigger OnValidate()
            begin
                if not IsNullGuid(xRec.SystemId) then
                    if xRec."Custom Notif. Formula" <> Rec."Custom Notif. Formula" then
                        Rec.TestField("Open Report Notif. Freq.", "Expense Report Frequency"::Custom);
            end;
        }
        field(88; "Enable Approval Notif."; Boolean)
        {
            Caption = 'Notify users about approval updates';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the system sends email notifications when expense reports are submitted, approved, or rejected. Notifications are only sent when an email account is configured.';
        }
        field(89; "Enable Email with Receipts"; Boolean)
        {
            Caption = 'Process incoming emails with receipts';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the agent reads its mailbox and processes incoming emails containing expense receipts. Receipts are only processed when a mailbox is configured.';
        }
        field(90; "Posting Groups Applied"; Boolean)
        {
            Caption = 'Default expense posting groups applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default expense posting groups (including the employee posting group) have been created.';
            Editable = false;
        }
        field(91; "Exp. Categories Applied"; Boolean)
        {
            Caption = 'Default expense categories applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default expense categories and subcategories have been created.';
            Editable = false;
        }
        field(92; "Exp. Locations Applied"; Boolean)
        {
            Caption = 'Default expense locations applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default expense locations have been created.';
            Editable = false;
        }
        field(93; "Management Rules Applied"; Boolean)
        {
            Caption = 'Default management rules applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default management rules have been created.';
            Editable = false;
        }
        field(94; "Payment Methods Applied"; Boolean)
        {
            Caption = 'Default payment methods applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default expense payment methods (Card, Cash, Bank) have been created.';
            Editable = false;
        }
        field(95; "No. Series Applied"; Boolean)
        {
            Caption = 'Default number series applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default number series for expenses, expense users, expense reports, and posted expense reports have been created.';
            Editable = false;
        }
        field(96; "Noreply Email Account ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Noreply Email Account ID';
        }
        field(97; "Noreply Email Connector"; Enum "Email Connector")
        {
            DataClassification = SystemMetadata;
            Caption = 'Noreply Email Connector';
        }
        field(98; "Noreply Email Address"; Text[250])
        {
            Caption = 'Noreply Email Address';
            ToolTip = 'Specifies the noreply email address used for outgoing messages. If empty, the main email account is used.';
            DataClassification = SystemMetadata;
        }
        field(100; "Default Approver No."; Code[20])
        {
            Caption = 'Default Approver No.';
            ToolTip = 'Specifies the expense user who by default is set as approver.';
            DataClassification = CustomerContent;
            TableRelation = "Expense User";

            trigger OnValidate()
            var
                ExpenseUser: Record "Expense User";
                ExpenseApprovalSetup: Record "Expense Approval Setup";
                DoUpdateDefaults: Boolean;
                ProgressDialog: Dialog;
            begin
                if Rec."Default Approver No." = '' then
                    exit;
                Rec.CalcFields("Default Approver Name");
                if not GuiAllowed() or (xRec."Default Approver No." = '') then
                    DoUpdateDefaults := true
                else
                    DoUpdateDefaults := Confirm(UpdateDefaultsApproverQst, true, GetExpenseUserName(xRec."Default Approver No."), GetExpenseUserName(Rec."Default Approver No."));
                if not DoUpdateDefaults then
                    exit;
                ProgressDialog.Open(UpdatingDefaultApproversLbl);
                ExpenseApprovalSetup.SetRange("Approver No.", xRec."Default Approver No.");
                if not ExpenseApprovalSetup.IsEmpty() then
                    ExpenseApprovalSetup.ModifyAll("Approver No.", Rec."Default Approver No.");
                ExpenseUser.SetAutoCalcFields("Approver No.");
                ExpenseUser.SetFilter("Approver No.", '%1', '');
                if ExpenseUser.FindSet() then
                    repeat
                        ExpenseApprovalSetup.init();
                        ExpenseApprovalSetup."Expense User No." := ExpenseUser."No.";
                        ExpenseApprovalSetup."Approver No." := Rec."Default Approver No.";
                        if ExpenseApprovalSetup.Insert() then;
                    until ExpenseUser.Next() = 0;
                ProgressDialog.Close();
            end;
        }
        field(101; "Default Approver Name"; Text[100])
        {
            Caption = 'Default Approver';
            ToolTip = 'Specifies the name of the expense user who by default is set as approver.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Default Approver No.")));
        }
        field(102; "Create Emp. for Expense Users"; Boolean)
        {
            Caption = 'Create Employees for Expense Users';
            ToolTip = 'Specifies whether Employees should be automatically created from Expense Users when no matching Employee exists. Employees and their connection with Expense Users are critical for correct processing and posting in Expense Agent, but this setting may impact your HR data.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if Rec."Create Emp. for Expense Users" then
                    if not ConfirmManagement.GetResponseOrDefault(CreateEmployeesForExpenseUsersQst, false) then
                        Error('');
            end;
        }
        field(103; "Default VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Default VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the default VAT Business Posting Group for expense transactions.';
        }
        field(104; "Allow VAT Reclaim"; Boolean)
        {
            Caption = 'Allow VAT Reclaim';
            ToolTip = 'Specifies whether VAT reclaim is allowed on expenses.';

            trigger OnValidate()
            begin
                if "Allow VAT Reclaim" then
                    TestField("Default VAT Bus. Posting Group");
            end;
        }
        field(105; "VAT Rates Applied"; Boolean)
        {
            Caption = 'Default VAT Rates applied';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the default VAT rates have been applied.';
            Editable = false;
        }
        field(120; "Enable Project Fields"; Boolean)
        {
            Caption = 'Enable project fields';
            ToolTip = 'Specifies whether project and project task fields are visible in the expense web app for submitters.';
        }
        field(121; "Project Visibility"; Enum "Expense Project Visibility")
        {
            Caption = 'Project visibility';
            ToolTip = 'Specifies which projects are visible to submitters: only projects assigned to the user, or all active projects.';
        }
        field(122; "Enable Communication"; Boolean)
        {
            Caption = 'Send emails to users';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the agent sends outgoing emails to users: welcome emails, reimbursement notifications, approval updates, and unsubmitted-report reminders. Turn this off to stop all outgoing emails. Incoming receipt processing is controlled separately.';

            trigger OnValidate()
            begin
                if not Rec."Enable Communication" then begin
                    Rec."Enable Open Report Notif." := false;
                    Rec."Enable Approval Notif." := false;
                end;
            end;
        }
        field(150; "Use Canary Endpoint"; Boolean)
        {
            Caption = 'Canary';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether Expense Agent service calls from this environment are routed to the canary endpoint.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Returns whether the agent background task should be scheduled for the current
    /// setup. The task runs when the agent is enabled and there is work with a usable
    /// account: inbound receipt processing (receipts on + a mailbox) or outbound
    /// communication (welcome/reimbursement/approval/reminders on + a noreply account).
    /// AgentEnabled is passed in so the setup wizard can use its pending enable/disable
    /// state.
    /// </summary>
    internal procedure ShouldScheduleAgentTask(AgentEnabled: Boolean): Boolean
    var
        InboundConfigured: Boolean;
        OutboundConfigured: Boolean;
    begin
        if not AgentEnabled then
            exit(false);

        InboundConfigured := Rec."Enable Email with Receipts" and not IsNullGuid(Rec."Email Account ID");
        OutboundConfigured := Rec."Enable Communication" and not IsNullGuid(Rec."Noreply Email Account ID");

        exit(InboundConfigured or OutboundConfigured);
    end;

    /// <summary>
    /// Returns whether outgoing communication is fully configured: the master toggle is
    /// on and a no-reply sender account is set. Outbound emails (welcome, reimbursement,
    /// approval, reminders) are only sent from the no-reply account; there is no fallback.
    /// </summary>
    internal procedure IsOutgoingCommunicationConfigured(): Boolean
    begin
        exit(Rec."Enable Communication" and not IsNullGuid(Rec."Noreply Email Account ID"));
    end;

    internal procedure RemoveAllScheduledTasks()
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
    begin
        ExpenseAgentStatus.GetOrCreate();
        EAAgentScheduler.RemoveAgentTask(ExpenseAgentStatus);
    end;

    internal procedure ClearMailboxAndDependents()
    begin
        Rec."Email Address" := '';
        Clear(Rec."Email Account ID");
        Clear(Rec."Email Connector");
        Rec."Email Folder" := '';
        Rec."Email Folder Id" := '';
        Rec."Enable Email with Receipts" := false;
        Rec."Enable Open Report Notif." := false;
    end;

    var
        RecordHasBeenRead: Boolean;
        NoRegisteredUserLbl: Label 'No registered user';
        RegisteredUserLbl: Label '1 registered user';
        RegisteredUsersLbl: Label '%1 registered users', Comment = '%1 is an integer value';
        InvalidDayErr: Label '%1 must be between 1 and 31.', Comment = '%1 = Field Caption';
        CannotUseMinHoursErr: Label 'Minimum Hours for Per Diem can only be set when Full Per-Diem Calculation is either %1 or %2.', Comment = '%1 - Enum value "24-hour Rolling Period", %2 - Enum value "Overnight Stay"';
        InvalidPartialDaysRuleErr: Label 'Partial Day Rule can only be set to %1 when Full Per-Diem Calculation is either %2 or %3.', Comment = '%1 - Enum value "Flat Percentage Of Full Rate", %2 - Enum value "24-hour Rolling Period", %3 - Enum value "Overnight Stay"';
        CopyEmployeesToExpenseUsersQst: Label 'Do you want to copy existing employees to expense users?';
        DefaultSetupNotCreatedErr: Label 'You must create the default setup data before enabling the agent. Use the Apply Default Settings action to create it.';
        MissingCategoryErr: Label 'You must ensure that %1 has values when %2 is enabled', Comment = '%1 is a table name, e.g. Category, %2 is a field name, e.g. Check categories';
        CannotDisableApprovalWorkflowErr: Label 'You cannot disable approval workflow because there are expense reports pending approval. Please complete or cancel the approval process for those expense reports before disabling this feature.';
        FeatureNameLbl: Label 'Expense Agent', Locked = true;
        ClearNoreplyAccountQst: Label 'Do you want to clear the no-reply email account? The agent will no longer send welcome, reimbursement, approval or reminder emails until you configure one.';
        ClearMailboxAccountQst: Label 'Do you want to clear the mailbox account? The agent will no longer process emailed receipts until you configure a mailbox.';
        IncomingMailboxAccessFailedErr: Label 'The agent can''t use the selected Microsoft 365 mailbox for incoming receipts because the connection failed. Ask your Microsoft 365 administrator to check if you have permission to access the mailbox.';
        OutgoingMailboxAccessFailedErr: Label 'The agent can''t use the selected Microsoft 365 mailbox for outgoing notifications because the connection failed. Ask your Microsoft 365 administrator to check if you have permission to access the noreply mailbox.';
        MailboxAccessHttpRequestFailedErr: Label 'The agent can''t verify mailbox access because its settings don''t allow HTTP requests. Ask your administrator to update this setting and try again.';
        DeactivateNoAccessWithUserQst: Label 'If you deactivate the agent, you won''t be able to reactivate it because you don''t have permission to the current mail account (activated by %1). Are you sure you want to continue?', Comment = '%1 = full name of the user who originally activated the agent.';
        DeactivateNoAccessQst: Label 'If you deactivate the agent, you won''t be able to reactivate it because you don''t have permission to the current mail account. Are you sure you want to continue?';
        CreateEmployeesForExpenseUsersQst: Label 'Turning on this setting will enable automatic creation of records in the Employee table. This may impact your HR setup in Business Central.\\Are you sure you want to enable this feature?';
        UpdateDefaultsApproverQst: Label 'You have changed the default approver.\\Do you also want to change approver from %1 to %2 for all expense users who currently have %1 as approver?', Comment = '%1 and %2 are both person names.';
        UpdatingDefaultApproversLbl: Label 'Updating approvers...';
        XDOMESTICTxt: Label 'DOMESTIC'; // DOMESTIC VAT Business Posting Group used as default for all rates created by this codeunit


    internal procedure AssistEditNoreplyMailbox()
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccounts: Page "Email Accounts";
    begin
        if not CheckMailboxExists() then
            Page.RunModal(Page::"Email Account Wizard");

        if not CheckMailboxExists() then
            exit;

        EmailAccounts.EnableLookupMode();
        EmailAccounts.SetShowCreateAccount(true);
        EmailAccounts.FilterConnectorV4Accounts(true);
        if EmailAccounts.RunModal() = Action::LookupOK then begin
            EmailAccounts.GetAccount(TempEmailAccount);
            // Probe with the chosen account before mutating Rec, so a failed access
            // check leaves the previous noreply mailbox intact in the page.
            CheckSelectedNoreplyMailboxAccessOrError(TempEmailAccount);
            Rec."Noreply Email Account ID" := TempEmailAccount."Account Id";
            Rec."Noreply Email Connector" := TempEmailAccount.Connector;
            Rec."Noreply Email Address" := TempEmailAccount."Email Address";
            Rec.Modify();
        end else
            if Rec."Noreply Email Address" <> '' then
                if Confirm(ClearNoreplyAccountQst) then begin
                    Clear(Rec."Noreply Email Account ID");
                    Clear(Rec."Noreply Email Connector");
                    Rec."Noreply Email Address" := '';
                    Rec.Modify();
                end;
    end;

    internal procedure AssistEditMailbox()
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccounts: Page "Email Accounts";
    begin
        if not CheckMailboxExists() then
            Page.RunModal(Page::"Email Account Wizard");

        if not CheckMailboxExists() then
            exit;

        EmailAccounts.EnableLookupMode();
        EmailAccounts.SetShowCreateAccount(true);
        EmailAccounts.FilterConnectorV4Accounts(true);
        if EmailAccounts.RunModal() = Action::LookupOK then begin
            EmailAccounts.GetAccount(TempEmailAccount);
            // Probe with the chosen account before mutating Rec, so a failed access
            // check leaves the previously selected mailbox intact in the page.
            CheckSelectedIncomingMailboxAccessOrError(TempEmailAccount);
            Rec."Email Account ID" := TempEmailAccount."Account Id";
            Rec."Email Connector" := TempEmailAccount.Connector;
            Rec."Email Address" := TempEmailAccount."Email Address";
            if IsNullGuid(Rec."Noreply Email Account ID") then begin
                Rec."Noreply Email Account ID" := Rec."Email Account ID";
                Rec."Noreply Email Connector" := Rec."Email Connector";
                Rec."Noreply Email Address" := Rec."Email Address";
            end;
        end else
            if Rec."Email Address" <> '' then
                if Confirm(ClearMailboxAccountQst) then begin
                    Clear(Rec."Email Account ID");
                    Clear(Rec."Email Connector");
                    Rec."Email Address" := '';
                    Rec.Modify();
                end;
    end;

    local procedure CheckSelectedIncomingMailboxAccessOrError(TempEmailAccount: Record "Email Account" temporary)
    var
        EAMailboxAccess: Codeunit "EA Mailbox Access";
    begin
        EAMailboxAccess.SetTestAccount(TempEmailAccount."Account Id", TempEmailAccount.Connector);
        if EAMailboxAccess.Run(Rec) then
            exit;
        RaiseHttpClientErrorIfBlocked();
        Error(IncomingMailboxAccessFailedErr);
    end;

    local procedure CheckSelectedNoreplyMailboxAccessOrError(TempEmailAccount: Record "Email Account" temporary)
    var
        EAMailboxAccess: Codeunit "EA Mailbox Access";
    begin
        EAMailboxAccess.SetTestAccount(TempEmailAccount."Account Id", TempEmailAccount.Connector);
        if EAMailboxAccess.Run(Rec) then
            exit;
        RaiseHttpClientErrorIfBlocked();
        Error(OutgoingMailboxAccessFailedErr);
    end;

    local procedure CheckMailboxExists(): Boolean
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
        IConnector: Interface "Email Connector";
    begin
        EmailAccount.GetAllAccounts(false, TempEmailAccount);
        if TempEmailAccount.IsEmpty() then
            exit(false);

        if TempEmailAccount.FindSet() then
            repeat
                IConnector := TempEmailAccount.Connector;

                if IConnector is "Email Connector v4" then
                    exit(true);
            until TempEmailAccount.Next() = 0;
    end;

    internal procedure GetFeatureName(): Text
    begin
        exit(FeatureNameLbl);
    end;

    internal procedure LogAgentEnabledTelemetry()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000UBV', GetFeatureName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    internal procedure LogAgentDisabledTelemetry()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000UBW', GetFeatureName(), Enum::"Feature Uptake Status"::Undiscovered);
    end;

    internal procedure ValidateIncomingMailboxAccess(): Boolean
    var
        EAMailboxAccess: Codeunit "EA Mailbox Access";
    begin
        if IsNullGuid(Rec."Email Account ID") then
            exit(true);
        EAMailboxAccess.SetTestAccount(Rec."Email Account ID", Rec."Email Connector");
        exit(EAMailboxAccess.Run(Rec));
    end;

    internal procedure ValidateNoreplyMailboxAccess(): Boolean
    var
        EAMailboxAccess: Codeunit "EA Mailbox Access";
    begin
        if IsNullGuid(Rec."Noreply Email Account ID") then
            exit(true);
        EAMailboxAccess.SetTestAccount(Rec."Noreply Email Account ID", Rec."Noreply Email Connector");
        exit(EAMailboxAccess.Run(Rec));
    end;

    internal procedure CheckIncomingMailboxAccessOrError()
    begin
        if ValidateIncomingMailboxAccess() then
            exit;
        RaiseHttpClientErrorIfBlocked();
        Error(IncomingMailboxAccessFailedErr);
    end;

    internal procedure CheckNoreplyMailboxAccessOrError()
    begin
        if ValidateNoreplyMailboxAccess() then
            exit;
        RaiseHttpClientErrorIfBlocked();
        Error(OutgoingMailboxAccessFailedErr);
    end;

    internal procedure CheckMailboxAccessOrError()
    begin
        CheckIncomingMailboxAccessOrError();
        CheckNoreplyMailboxAccessOrError();
    end;

    /// <summary>
    /// Verifies the current user can access every mailbox the enabled features will use before
    /// the agent task is (re)scheduled: the receipts mailbox when incoming receipts are on, and
    /// the no-reply mailbox when outgoing communication is on. Each check is skipped when its
    /// feature is off or its account is unset, and errors when an account is set but inaccessible.
    /// </summary>
    internal procedure CheckSchedulingMailboxAccessOrError()
    begin
        if Rec."Enable Email with Receipts" and not IsNullGuid(Rec."Email Account ID") then
            CheckIncomingMailboxAccessOrError();
        if IsOutgoingCommunicationConfigured() then
            CheckNoreplyMailboxAccessOrError();
    end;

    // Returns true to proceed with deactivation, false if the user cancelled.
    internal procedure ShowDeactivationAccessWarning(): Boolean
    var
        ConfiguredByName: Text;
    begin
        if IsNullGuid(Rec."Email Account ID") then
            exit(true);
        if ValidateIncomingMailboxAccess() then
            exit(true);

        ConfiguredByName := GetAgentConfiguredByName();
        if ConfiguredByName <> '' then
            exit(Confirm(DeactivateNoAccessWithUserQst, false, ConfiguredByName));
        exit(Confirm(DeactivateNoAccessQst, false));
    end;

    local procedure GetAgentConfiguredByName(): Text
    var
        User: Record User;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
    begin
        if IsNullGuid(Rec."User Security ID") then
            exit('');
        AgentSetup.GetSetupRecord(TempAgentSetupBuffer, Rec."User Security ID", "Agent Metadata Provider"::"Expense Agent", '', '', '');
        if IsNullGuid(TempAgentSetupBuffer."Configured By") then
            exit('');
        if not User.Get(TempAgentSetupBuffer."Configured By") then
            exit('');
        if User."Full Name" <> '' then
            exit(User."Full Name");
        exit(User."User Name");
    end;

    local procedure RaiseHttpClientErrorIfBlocked()
    var
        NAVAppSettings: Record "NAV App Setting";
        EnvironmentInformation: Codeunit "Environment Information";
        CurrentModuleInfo: ModuleInfo;
    begin
        if not EnvironmentInformation.IsSandbox() then
            exit;
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        NAVAppSettings.ReadIsolation(IsolationLevel::ReadUncommitted);
        NAVAppSettings.SetRange("App ID", CurrentModuleInfo.Id);
        if not NAVAppSettings.FindFirst() then
            exit;
        if NAVAppSettings."Allow HttpClient Requests" then
            exit;
        Error(MailboxAccessHttpRequestFailedErr);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Agent Setup", 'I')]
    internal procedure InitRecord()
    begin
        if not Get() then
            Rec.Insert();
    end;

    internal procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense No. Series", 'X')]
    internal procedure CreateNoSeriesDefaults()
    var
        CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
    begin
        CreateExpenseNoSeries.Run();

        Rec.GetRecordOnce();
        if Rec."Expense Nos." = '' then
            Rec."Expense Nos." := CreateExpenseNoSeries.ExpenseNoSeries();
        if Rec."Expense User Nos." = '' then
            Rec."Expense User Nos." := CreateExpenseNoSeries.ExpenseUserSeries();
        if Rec."Expense Reports Nos." = '' then
            Rec."Expense Reports Nos." := CreateExpenseNoSeries.ExpenseReportNoSeries();
        if Rec."Posted Expense Reports Nos." = '' then
            Rec."Posted Expense Reports Nos." := CreateExpenseNoSeries.PostedExpenseReportNoSeries();
        if Rec."Expense Vendor Nos." = '' then
            Rec."Expense Vendor Nos." := CreateExpenseNoSeries.ExpenseVendorNoSeries();
        if not Rec."No. Series Applied" then
            Rec."No. Series Applied" := true;
        Rec.Modify();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense User", 'I')]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Agent Setup", 'X')]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense GL Account", 'X')]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Categories", 'X')]
    internal procedure CreatePostingGroupsDefaults()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        Codeunit.Run(Codeunit::"Create Expense Agent Setup");
        Codeunit.Run(Codeunit::"Create Expense GL Account");
        CreateExpenseCategories.InsertDefaultPostingGroups();

        Rec.GetRecordOnce();
        if not Rec."Posting Groups Applied" then begin
            Rec."Posting Groups Applied" := true;
            Rec.Modify();
        end;

        if GuiAllowed and ExpenseUser.IsEmpty() then
            if Confirm(CopyEmployeesToExpenseUsersQst, false) then begin
                Employee.SetLoadFields("No.", "First Name", "Middle Name", "Last Name", "Job Title", "E-Mail", "Company E-Mail");
                if Employee.FindSet() then
                    repeat
                        ExpenseUser.SetRange("Employee No.", Employee."No.");
                        if not ExpenseUser.FindFirst() then begin
                            ExpenseUser.Init();
                            ExpenseUser."No." := '';
                            ExpenseUser."Employee No." := Employee."No.";
                            ExpenseUser.Name := CopyStr(Employee.FullName(), 1, MaxStrLen(ExpenseUser.Name));
                            ExpenseUser."Job Title" := Employee."Job Title";
                            if Employee."Company E-Mail" <> '' then
                                ExpenseUser."E-mail" := Employee."Company E-Mail"
                            else
                                ExpenseUser."E-mail" := Employee."E-Mail";
                            ExpenseUser.Insert(true);
                        end;
                    until Employee.Next() = 0;
            end;
    end;

    internal procedure GetRegisteredUsersText(): Text
    var
        ExpenseUser: Record "Expense User";
        NoOfUsers: Integer;
    begin
        NoOfUsers := ExpenseUser.Count();
        if NoOfUsers = 0 then
            exit(NoRegisteredUserLbl);
        if NoOfUsers = 1 then
            exit(RegisteredUserLbl);
        exit(StrSubstNo(RegisteredUsersLbl, NoOfUsers));
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Categories", 'X')]
    internal procedure CreateExpenseCategoriesDefaults()
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.InsertDefaultExpenseCategories();

        Rec.GetRecordOnce();
        if not Rec."Exp. Categories Applied" then begin
            Rec."Exp. Categories Applied" := true;
            Rec.Modify();
        end;
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Categories", 'X')]
    internal procedure CreateExpenseLocationsDefaults()
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.InsertDefaultExpenseLocations();

        Rec.GetRecordOnce();
        if not Rec."Exp. Locations Applied" then begin
            Rec."Exp. Locations Applied" := true;
            Rec.Modify();
        end;
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Categories", 'X')]
    internal procedure CreateManagementRulesDefaults()
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.InsertDefaultManagementRules();

        Rec.GetRecordOnce();
        if not Rec."Management Rules Applied" then begin
            Rec."Management Rules Applied" := true;
            Rec.Modify();
        end;
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense VAT Rates", 'X')]
    internal procedure CreateCountryVATRatesDefaults()
    var
        CreateExpenseCountryVATRates: Codeunit "Create Expense VAT Rates";
    begin
        Rec.GetRecordOnce();
        if Rec."Default VAT Bus. Posting Group" = '' then begin
            Rec."Default VAT Bus. Posting Group" := XDOMESTICTxt;
            Rec.Modify();
        end;

        CreateExpenseCountryVATRates.InsertDefaultRates();

        if not Rec."VAT Rates Applied" then begin
            Rec."VAT Rates Applied" := true;
            Rec.Modify();
        end;
    end;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Create Expense Agent Setup", 'X')]
    internal procedure CreatePaymentMethodsDefaults()
    var
        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
    begin
        CreateExpenseAgentSetup.CreateDefaultPaymentMethods();

        Rec.GetRecordOnce();
        if not Rec."Payment Methods Applied" then begin
            Rec."Payment Methods Applied" := true;
            Rec.Modify();
        end;
    end;

    internal procedure CreateAccountingDefaults()
    begin
        if not Rec."No. Series Applied" then
            CreateNoSeriesDefaults();
        if not Rec."Payment Methods Applied" then
            CreatePaymentMethodsDefaults();
        if not Rec."Posting Groups Applied" then
            CreatePostingGroupsDefaults();
        if not Rec."Exp. Categories Applied" then
            CreateExpenseCategoriesDefaults();
    end;

    internal procedure CreateManagementDefaults()
    begin
        if not Rec."Exp. Locations Applied" then
            CreateExpenseLocationsDefaults();
        if not Rec."Management Rules Applied" then
            CreateManagementRulesDefaults();
        if not Rec."VAT Rates Applied" then
            CreateCountryVATRatesDefaults();
    end;

    internal procedure CreateDefaultSettings()
    begin
        CreateAccountingDefaults();
        CreateManagementDefaults();
    end;

    local procedure CheckBeforeEnablingAgent()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        if not ("Posting Groups Applied" and "Exp. Categories Applied") then
            Error(DefaultSetupNotCreatedErr);

        TestField("Expense Nos.");
        TestField("Expense Reports Nos.");
        TestField("Posted Expense Reports Nos.");
        TestField("Enable Approval Workflow", false);
        if "Check Category/SubCat. Usage" then begin
            if ExpenseCategory.IsEmpty() then
                error(MissingCategoryErr, ExpenseCategory.TableCaption, Rec.FieldCaption("Check Category/SubCat. Usage"));
            if ExpenseSubCategory.IsEmpty() then
                error(MissingCategoryErr, ExpenseSubCategory.TableCaption, Rec.FieldCaption("Check Category/SubCat. Usage"));
        end;
    end;

    local procedure CheckBeforeDisableApprovalWorkflow()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader.SetRange(Status, ExpenseReportHeader.Status::"Pending Approval");
        if not ExpenseReportHeader.IsEmpty() then
            Error(CannotDisableApprovalWorkflowErr);
    end;

    local procedure GetExpenseUserName(ExpenseUserNo: Code[20]): Text
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseUserNo <> '' then
            if ExpenseUser.Get(ExpenseUserNo) then
                exit(ExpenseUser.Name);
        exit('');
    end;
}