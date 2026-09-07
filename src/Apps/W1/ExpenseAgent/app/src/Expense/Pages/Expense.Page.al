// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;

page 6988 "Expense"
{
    Caption = 'Expense';
    PageType = Card;
    SourceTable = Expense;
    DataCaptionFields = "No.", "Expense Category", Description;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the expense user who incurred the expense.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category assigned to this expense.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the travel location for the expense. Available for Per Diem expenses.';
                    ShowMandatory = IsPerDiemCategory;
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Expense Report No."; Rec."Expense Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense report that includes this expense. Set when added to a report.';
                    Importance = Additional;
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date the expense occurred.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Expense Time"; Rec."Expense Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time the expense occurred.';
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a short description of the expense.';
                }
                field("Expense Ext. Doc. No."; Rec."Expense Ext. Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receipt No.';
                    ToolTip = 'Specifies the receipt number or external reference on the document.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in the expense currency.';
                    Editable = not ((Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem") or (Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage));

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in the local currency.';
                    Importance = Additional;
                    Editable = false;
                }
                field(Justification; Rec.Justification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the justification for the expense per policy.';
                    Importance = Additional;
                }
                field("Merchant Name"; Rec."Merchant Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor or merchant for this expense.';
                }
                field("Merchant Registration No."; Rec."Merchant Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor or merchant registration number for this expense.';
                }
                field("Merchant VAT Registration No."; Rec."Merchant VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the vendor or merchant VAT registration number for this expense.';
                }
                field("Expense Vendor No."; Rec."Expense Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense vendor record created for this expense. Open the expense vendor to review and approve vendor creation.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Currency Code field.';
                    Importance = Additional;
                    Editable = not (Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem");
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current status of the expense.';
                    Importance = Additional;
                }
                field("Rule Violations"; Rec."Rule Violations")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether any rule violations exist for this expense.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time the expense was created.';
                    Importance = Additional;
                    Editable = false;
                }
                group(Rule)
                {
                    ShowCaption = false;
                    Visible = ShowAppliedRuleTxt <> '';
                    field(AppliedRuleTxt; ShowAppliedRuleTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Status';
                        ToolTip = 'Specifies the applied rule; choose to view details. Available after a rule is applied.';
                        ShowCaption = false;
                        Editable = false;
                        StyleExpr = RuleStyleTxt;
                        DrillDown = true;

                        trigger OnDrillDown()
                        var
                            ExpenseRuleHeader: Record "Expense Rule Header";
                        begin
                            if IsNullGuid(Rec."Applied Rule Id") then
                                exit;

                            ExpenseRuleHeader.GetBySystemId(Rec."Applied Rule Id");
                            Commit();
                            Page.RunModal(Page::"Expense Rule Card", ExpenseRuleHeader);
                        end;
                    }
                }
            }
            group(Travel)
            {
                Visible = IsPerDiemCategory or IsMileageCategory;
                field("Starting Date and Time"; Rec."Starting Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start of the travel period for this expense. Editable for Per Diem expenses.';
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Ending Date and Time"; Rec."Ending Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end of the travel period for this expense. Editable for Per Diem expenses.';
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Starting Point"; Rec."Starting Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting location for mileage. Available for Mileage expenses.';
                    Editable = IsMileageCategory;
                }
                field("Ending Point"; Rec."Ending Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending location for mileage. Available for Mileage expenses.';
                    Editable = IsMileageCategory;
                }
                field(Mileage; Rec.Mileage)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the distance traveled for mileage reimbursement. Available for Mileage expenses.';
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Round Trip"; Rec."Round Trip")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Vehicle Type"; Rec."Vehicle Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vehicle type used for this mileage expense. The matching vehicle-specific mileage rate is applied, or the generic rate when none exists. Available for Mileage expenses.';
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Total Mileage"; TotalMileage)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Total Mileage';
                    ToolTip = 'Specifies the total mileage for reimbursement. If round trip, this is double the one-way distance.';
                    Editable = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure for mileage (for example, miles or kilometers). Available for Mileage expenses.';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
            group(Billing)
            {
                field(Billable; Rec.Billable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense is billable to a customer.';
                }
                field("Billable to Customer"; Rec."Billable to Customer")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Billable;
                    ToolTip = 'Specifies the customer to bill for this expense. Available when Billable is turned on.';
                    Importance = Additional;
                }
                field(Refundable; Rec.Refundable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense is reimbursable.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of reimbursement for this expense.';
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reduction to the reimbursable amount. Available when Refundable is on and the category does not require itemization.';
                    Editable = Rec.Refundable and (not IsItemizationCategory);
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount eligible for reimbursement based on policy.';
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reimbursable amount in the local currency.';
                    Importance = Additional;
                }
                field("Refundable Amount"; Rec."Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the amount eligible for refund based on policy.';
                }
                field("Refundable Amount (LCY)"; Rec."Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the refundable amount in the local currency.';
                    Importance = Additional;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method used for this expense.';
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Credit Card Feed No."; Rec."Credit Card Feed No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference to the imported credit card transaction. Set by the system when matched to a card feed.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job to assign this expense to.';
                    Importance = Additional;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job task to assign this expense to.';
                    Importance = Additional;
                }
            }
            group(Dimensions)
            {
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies Shortcut Dimension 1 for this expense.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies Shortcut Dimension 2 for this expense.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
            }

        }
        area(factboxes)
        {
            part(Statistics; "Expense Statistics")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
            }
            part(RuleViolations; "Expense Rule Violations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rule Violations';
                UpdatePropagation = Both;
                SubPageLink = "Expense No." = field("No.");
                Visible = Rec."No." <> '';
            }
            part("VAT Specification FactBox"; "Expense VAT Spec. FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Specification';
                SubPageLink = "Expense No." = field("No.");
                Visible = (Rec."No." <> '') and AllowVATReclaim;
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense"), "No." = field("No.");
            }
            part("Expense Picture"; "Expense Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense"), "No." = field("No."), "File Type" = const("Document Attachment File Type"::PDF);
                Visible = HasPdfAttachment;
                ShowFilter = false;
            }
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group("Expense")
            {
                Caption = 'Expense';
                action(ExpDimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Participants")
                {
                    Image = PersonInCharge;
                    Caption = 'Participants';
                    ToolTip = 'Add participants to the expense. Available for Participant expenses.';
                    ApplicationArea = Basic, Suite;
                    Visible = IsParticipantCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowParticipants();

                        CurrPage.Update(true);
                    end;
                }
                action("Itemizations")
                {
                    Image = Item;
                    Caption = 'Itemizations';
                    ToolTip = 'Add itemizations to the expense. Available for Itemize expenses.';
                    ApplicationArea = Basic, Suite;
                    Visible = IsItemizationCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowItemization();

                        CurrPage.Update(true);
                    end;
                }
                action("PerDiem")
                {
                    Image = CalculateCost;
                    Caption = 'Per Diem';
                    ToolTip = 'Add per diem entries to the expense. Available for Per Diem expenses.';
                    ApplicationArea = Basic, Suite;
                    Visible = IsPerDiemCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowPerDiem();

                        CurrPage.Update(true);
                    end;
                }
                action("VAT Specification")
                {
                    Image = VATPostingSetup;
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Specification';
                    RunObject = Page "Expense VAT Specification";
                    RunPageLink = "Expense No." = field("No.");
                    Enabled = (Rec."No." <> '') and AllowVATReclaim;
                    ToolTip = 'View or edit the per-rate VAT specification captured from the original invoice for this expense.';
                }
                action("Expense Report")
                {
                    Image = Document;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Report';
                    RunObject = Page "Expense Report";
                    RunPageLink = "No." = field("Expense Report No.");
                    Enabled = (Rec."Expense Report No." <> '') and (Rec."Posted Expense Report No." = '');
                    ToolTip = 'View the details of the expense report associated with this expense.';
                }
                action("Posted Expense Report")
                {
                    Image = Document;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Expense Report';
                    RunObject = Page "Posted Expense Report";
                    RunPageLink = "No." = field("Posted Expense Report No.");
                    Enabled = Rec."Posted Expense Report No." <> '';
                    ToolTip = 'View the details of the posted expense report associated with this expense.';
                }
            }
        }
        area(Processing)
        {
            group("Functions")
            {
                Caption = 'Functions';
                Image = "Action";

                action("Create Expense Report")
                {
                    Caption = 'Create Expense Report';
                    Image = NewDocument;
                    ToolTip = 'Create an expense report with this expense. Available when the expense status is Released.';
                    Enabled = Rec.Status = Rec.Status::Released;
                    ApplicationArea = Basic, Suite;

                    trigger OnAction()
                    var
                        Expenses: Record Expense;
                        CreateExpenseReport: Codeunit "Create Expense Report";
                    begin
                        Expenses.SetRange("No.", Rec."No.");

                        CreateExpenseReport.AddExpensesToReport(Expenses);
                    end;
                }
                action("Match Vendor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match merchant data to vendor';
                    Image = VendorCode;
                    ToolTip = 'Match the merchant data of this expense to a vendor.';
                    Enabled = (Rec."No." <> '');

                    trigger OnAction()
                    var
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        ExpenseVendorMatching.FindOrCreateExpenseVendor(Rec);
                        CurrPage.SaveRecord();
                    end;
                }
                action("Update VAT Specification")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update VAT Specification';
                    Image = VATPostingSetup;
                    ToolTip = 'Update VAT specification for this expense.';
                    Enabled = (Rec."No." <> '') and AllowVATReclaim;

                    trigger OnAction()
                    begin
                        Rec.UpdateVATSpecification(Rec."No.");
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group(Action21)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Release';
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the expense and lock editing. Reopen to edit.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the expense to allow edits.';

                    trigger OnAction()
                    var
                        ReleaseExpenseDoc: Codeunit "Release Expense Document";
                    begin
                        ReleaseExpenseDoc.PerformManualReopen(Rec);
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Home';

                group(Category_Release)
                {
                    Caption = 'Release';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref(Create_Expense_Report_Promoted; "Create Expense Report")
                {
                }
            }
            group(Category_Expense)
            {
                Caption = 'Expense';

                actionref(Participants_Promoted; Participants)
                {
                }
                actionref(Itemizations_Promoted; Itemizations)
                {
                }
                actionref(PerDiem_Promoted; PerDiem)
                {
                }
                actionref(ExpDimensions_Promoted; ExpDimensions)
                {
                }
                actionref(VATSpecification_Promoted; "VAT Specification")
                {
                }
                actionref(Expense_Report_Promoted; "Expense Report")
                {
                }
                actionref(Posted_Expense_Report_Promoted; "Posted Expense Report")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDocNoVisible();
        SetCategoryTypeVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    var
        ExpenseAttachmentMgt: Codeunit "Expense Attachment Mgt.";
    begin
        SetCategoryTypeVisibility();
        CalculateTotalMileage();

        if IsNullGuid(Rec."Applied Rule Id") then
            ShowAppliedRuleTxt := ''
        else
            ShowAppliedRuleTxt := ViewAppliedRuleLbl;

        RuleStyleTxt := Rec.GetRuleStyleText();
        HasPdfAttachment := ExpenseAttachmentMgt.HasPDFAttachment(Database::Expense, Rec."No.", 0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Expense Date" = 0D then
            Rec."Expense Date" := WorkDate();
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        IsMileageCategory, IsPerDiemCategory, IsParticipantCategory, IsItemizationCategory : Boolean;
        DocNoVisible: Boolean;
        HasPdfAttachment: Boolean;
        RuleStyleTxt: Text;
        ShowAppliedRuleTxt: Text[50];
        TotalMileage: Decimal;
        AllowVATReclaim: Boolean;
        ViewAppliedRuleLbl: Label 'View Applied Rule';

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit "Expense Doc No Visibility";
    begin
        DocNoVisible := DocumentNoVisibility.ExpenseDocumentNoIsVisible(Rec."No.");
    end;

    local procedure SetCategoryTypeVisibility()
    begin
        IsPerDiemCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem";
        IsMileageCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage;
        IsItemizationCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Itemize;
        IsParticipantCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Participants;
        ExpenseAgentSetup.GetRecordOnce();
        AllowVATReclaim := ExpenseAgentSetup."Allow VAT Reclaim";
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure CalculateTotalMileage()
    var
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
    begin
        TotalMileage := ExpenseAutoPopulation.GetEffectiveDistance(Rec.Mileage, Rec."Round Trip");
    end;
}