// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Environment.Configuration;
using System.Text;

/// <summary>
/// Hierarchical category structure for organizing general ledger accounts into financial statement groupings.
/// Supports multi-level categorization for automated financial reporting and account analysis.
/// </summary>
/// <remarks>
/// Key relationships: G/L Account table, Financial Reports framework, Account Schedule structure.
/// Provides template structure for Balance Sheet, Income Statement, and Cash Flow categorization.
/// Extensible via table extensions for industry-specific account categorization requirements.
/// Supports parent-child relationships with presentation ordering and indentation levels.
/// </remarks>
table 570 "G/L Account Category"
{
    Caption = 'G/L Account Category';
    DataCaptionFields = Description;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the account category record with auto-increment functionality.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Reference to the parent category entry for hierarchical organization of account categories.
        /// </summary>
        field(2; "Parent Entry No."; Integer)
        {
            Caption = 'Parent Entry No.';
        }
        /// <summary>
        /// Sequence number for ordering sibling categories within the same parent level.
        /// </summary>
        field(3; "Sibling Sequence No."; Integer)
        {
            Caption = 'Sibling Sequence No.';
        }
        /// <summary>
        /// Text representation of the hierarchical position used for sorting and display ordering.
        /// </summary>
        field(4; "Presentation Order"; Text[100])
        {
            Caption = 'Presentation Order';
        }
        /// <summary>
        /// Visual indentation level for hierarchical display in user interfaces and reports.
        /// </summary>
        field(5; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        /// <summary>
        /// Descriptive name of the account category displayed in reports and user interfaces.
        /// </summary>
        field(6; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the record.';
        }
        /// <summary>
        /// Primary financial statement classification determining the main category type.
        /// </summary>
        field(7; "Account Category"; Option)
        {
            BlankZero = true;
            Caption = 'Account Category';
            ToolTip = 'Specifies the category of the G/L account.';
            OptionCaption = ',Assets,Liabilities,Equity,Income,Cost of Goods Sold,Expense';
            OptionMembers = ,Assets,Liabilities,Equity,Income,"Cost of Goods Sold",Expense;

            trigger OnValidate()
            begin
                if "Account Category" in ["Account Category"::Income, "Account Category"::"Cost of Goods Sold", "Account Category"::Expense]
                then begin
                    "Income/Balance" := "Income/Balance"::"Income Statement";
                    "Additional Report Definition" := "Additional Report Definition"::" ";
                end else
                    "Income/Balance" := "Income/Balance"::"Balance Sheet";
                if Description = '' then
                    Description := Format("Account Category");
                UpdatePresentationOrder();
            end;
        }
        /// <summary>
        /// Indicates whether the category appears on Income Statement or Balance Sheet reports.
        /// </summary>
        field(8; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
            Editable = false;

            trigger OnValidate()
            begin
                UpdatePresentationOrder();
            end;
        }
        /// <summary>
        /// Additional classification for cash flow statement and specialized financial reporting requirements.
        /// </summary>
        field(9; "Additional Report Definition"; Option)
        {
            Caption = 'Additional Report Definition';
            ToolTip = 'Specifies additional attributes that are used to create the cash flow statement.';
            OptionCaption = ' ,Operating Activities,Investing Activities,Financing Activities,Cash Accounts,Retained Earnings,Distribution to Shareholders';
            OptionMembers = " ","Operating Activities","Investing Activities","Financing Activities","Cash Accounts","Retained Earnings","Distribution to Shareholders";

            trigger OnValidate()
            begin
                if "Additional Report Definition" <> "Additional Report Definition"::" " then
                    TestField("Income/Balance", "Income/Balance"::"Balance Sheet");
            end;
        }
        /// <summary>
        /// Indicates whether this category was created automatically by the system during initialization.
        /// </summary>
        field(11; "System Generated"; Boolean)
        {
            Caption = 'System Generated';
        }
        /// <summary>
        /// Indicates whether this category has child categories in the hierarchical structure.
        /// </summary>
        field(12; "Has Children"; Boolean)
        {
            CalcFormula = exist("G/L Account Category" where("Parent Entry No." = field("Entry No.")));
            Caption = 'Has Children';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Presentation Order", "Sibling Sequence No.")
        {
        }
        key(Key3; "Parent Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLAccount: Record "G/L Account";
    begin
        if "System Generated" then
            Error(CannotDeleteSystemGeneratedErr, Description);
        GLAccount.SetRange("Account Subcategory Entry No.", "Entry No.");
        if GLAccount.FindFirst() then
            Error(CategoryUsedOnAccountErr, TableCaption(), Description, GLAccount.TableCaption(), GLAccount."No.");
        DeleteChildren("Entry No.");
        ShowNotificationAccSchedUpdateNeeded();
    end;

    var
        NewCategoryTxt: Label '<Enter a Name>';
        CannotDeleteSystemGeneratedErr: Label '%1 is a system generated category and cannot be deleted.', Comment = '%1 = a category value, e.g. "Assets"';
        NoAccountsInFilterErr: Label 'There are no G/L Accounts in the filter of type %1.', Comment = '%1 = either ''Balance Sheet'' or ''Income Statement''';
        CategoryUsedOnAccountErr: Label 'You cannot delete %1 %2 because it is used in %3 %4.', Comment = '%1=account category table name, %2=category description, %3=g/l account table name, %4=g/l account number.';
        DontShowAgainActionLbl: Label 'Don''t show again';
        AccSchedUpdateNeededNotificationMsg: Label 'You have changed one or more G/L account categories that financial reports use. We recommend that you update the financial reports with your changes by choosing the Generate Financial Reports action.';
        GenerateAccountSchedulesLbl: Label 'Generate Financial Reports';
        WarnGenerateAccountSchedulesTxt: Label 'Notify that financial reports should be updated after someone changes data for account categories.';
        WarnAccountCategoriesUpdatedTxt: Label 'Notify about updating account categories.';

    /// <summary>
    /// Updates the hierarchical presentation order and indentation level based on the category's position in the tree structure.
    /// Calculates the sort order for proper display sequence in financial reports and user interfaces.
    /// </summary>
    /// <remarks>
    /// Recursively processes parent categories to build complete presentation order string.
    /// Applies financial statement ordering (Assets, Liabilities, Equity, Income, COGS, Expense).
    /// Updates indentation level based on depth in category hierarchy.
    /// </remarks>
    procedure UpdatePresentationOrder()
    var
        GLAccountCategory: Record "G/L Account Category";
        PresentationOrder: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePresentationOrder(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Entry No." = 0 then
            exit;
        GLAccountCategory := Rec;
        if "Sibling Sequence No." = 0 then
            "Sibling Sequence No." := "Entry No." * 10000 mod 2000000000;
        Indentation := 0;
        PresentationOrder := CopyStr(Format(1000000 + "Sibling Sequence No."), 2);
        while GLAccountCategory."Parent Entry No." <> 0 do begin
            Indentation += 1;
            GLAccountCategory.Get(GLAccountCategory."Parent Entry No.");
            PresentationOrder := CopyStr(Format(1000000 + GLAccountCategory."Sibling Sequence No."), 2) + PresentationOrder;
        end;
        case "Account Category" of
            "Account Category"::Assets:
                PresentationOrder := '0' + PresentationOrder;
            "Account Category"::Liabilities:
                PresentationOrder := '1' + PresentationOrder;
            "Account Category"::Equity:
                PresentationOrder := '2' + PresentationOrder;
            "Account Category"::Income:
                PresentationOrder := '3' + PresentationOrder;
            "Account Category"::"Cost of Goods Sold":
                PresentationOrder := '4' + PresentationOrder;
            "Account Category"::Expense:
                PresentationOrder := '5' + PresentationOrder;
        end;
        "Presentation Order" := CopyStr(PresentationOrder, 1, MaxStrLen("Presentation Order"));
        Modify();
    end;

    /// <summary>
    /// Initializes the account category dataset with standard financial statement structure.
    /// Creates default categories for Assets, Liabilities, Equity, Income, Cost of Goods Sold, and Expenses.
    /// </summary>
    procedure InitializeDataSet()
    begin
        CODEUNIT.Run(CODEUNIT::"G/L Account Category Mgt.");
    end;

    /// <summary>
    /// Creates a new account category as a sibling of the current category with default settings.
    /// Returns the entry number of the newly created category for further processing.
    /// </summary>
    /// <returns>Entry number of the newly inserted account category</returns>
    procedure InsertRow(): Integer
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        exit(GLAccountCategoryMgt.AddCategory("Entry No.", "Parent Entry No.", "Account Category", NewCategoryTxt, false, 0));
    end;

    local procedure Move(Steps: Integer)
    var
        GLAccountCategory: Record "G/L Account Category";
        SiblingOrder: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMove(Rec, GLAccountCategory, Steps, IsHandled);
        if IsHandled then
            exit;

        if "Entry No." = 0 then
            exit;
        GLAccountCategory := Rec;
        GLAccountCategory.SetRange("Parent Entry No.", "Parent Entry No.");
        GLAccountCategory.SetRange("Account Category", "Account Category");
        GLAccountCategory.SetCurrentKey("Presentation Order", "Sibling Sequence No.");
        if GLAccountCategory.Next(Steps) = 0 then
            exit;
        SiblingOrder := "Sibling Sequence No.";
        "Sibling Sequence No." := GLAccountCategory."Sibling Sequence No.";
        GLAccountCategory."Sibling Sequence No." := SiblingOrder;
        GLAccountCategory.UpdatePresentationOrder();
        GLAccountCategory.Modify();
        UpdatePresentationOrder();
        Modify();
        UpdateDescendants(Rec);
        UpdateDescendants(GLAccountCategory);
    end;

    /// <summary>
    /// Moves the current account category up one position in the sibling sequence within the same parent level.
    /// Updates presentation order and descendant categories accordingly.
    /// </summary>
    procedure MoveUp()
    begin
        Move(-1);
    end;

    /// <summary>
    /// Moves the current account category down one position in the sibling sequence within the same parent level.
    /// Updates presentation order and descendant categories accordingly.
    /// </summary>
    procedure MoveDown()
    begin
        Move(1);
    end;

    local procedure ChangeAncestor(ChangeToChild: Boolean)
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if "Entry No." = 0 then
            exit;
        GLAccountCategory := Rec;
        if ChangeToChild then begin
            GLAccountCategory.SetRange("Parent Entry No.", "Parent Entry No.");
            GLAccountCategory.SetRange(Indentation, Indentation);
            GLAccountCategory.SetCurrentKey("Presentation Order", "Sibling Sequence No.");
            if GLAccountCategory.Next(-1) = 0 then
                exit;
            "Parent Entry No." := GLAccountCategory."Entry No."
        end else
            if GLAccountCategory.Get("Parent Entry No.") then
                "Parent Entry No." := GLAccountCategory."Parent Entry No."
            else
                exit;
        UpdatePresentationOrder();
        Modify();
        UpdateDescendants(Rec);
    end;

    local procedure UpdateDescendants(ParentGLAccountCategory: Record "G/L Account Category")
    var
        GLAccountCategory: Record "G/L Account Category";
        IsHandled: Boolean;
    begin
        if ParentGLAccountCategory."Entry No." = 0 then
            exit;

        IsHandled := false;
        OnBeforeUpdateDescendants(ParentGLAccountCategory, IsHandled);
        if IsHandled then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", ParentGLAccountCategory."Entry No.");
        if GLAccountCategory.FindSet() then
            repeat
                GLAccountCategory."Income/Balance" := ParentGLAccountCategory."Income/Balance";
                GLAccountCategory."Account Category" := ParentGLAccountCategory."Account Category";
                GLAccountCategory.UpdatePresentationOrder();
                UpdateDescendants(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    /// <summary>
    /// Changes the current category to become a child of its previous sibling category.
    /// Restructures the hierarchy by moving the category down one level in the tree.
    /// </summary>
    procedure MakeChildOfPreviousSibling()
    begin
        ChangeAncestor(true);
    end;

    /// <summary>
    /// Changes the current category to become a sibling of its parent category.
    /// Restructures the hierarchy by moving the category up one level in the tree.
    /// </summary>
    procedure MakeSiblingOfParent()
    begin
        ChangeAncestor(false);
    end;

    /// <summary>
    /// Deletes the current category and all its child categories from the hierarchy.
    /// Removes associated account assignments and updates related financial reports.
    /// </summary>
    procedure DeleteRow()
    begin
        if "Entry No." = 0 then
            exit;
        DeleteChildren("Entry No.");
        Delete(true);
    end;

    local procedure DeleteChildren(ParentEntryNo: Integer)
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Parent Entry No.", ParentEntryNo);
        if GLAccountCategory.FindSet() then
            repeat
                GLAccountCategory.DeleteRow();
            until GLAccountCategory.Next() = 0;
    end;

    /// <summary>
    /// Maps general ledger accounts to this category (placeholder for future implementation).
    /// Provides extension point for custom account mapping logic.
    /// </summary>
    procedure MapAccounts()
    begin
    end;

    /// <summary>
    /// Validates and assigns a new totaling filter for general ledger accounts in this category.
    /// Updates account assignments and clears previous totaling assignments as needed.
    /// </summary>
    /// <param name="NewTotaling">Filter expression for general ledger accounts to include in this category</param>
    /// <remarks>
    /// Validates that filtered accounts match the category's Income/Balance type.
    /// Clears previous account assignments before applying new totaling filter.
    /// Updates Account Subcategory Entry No. field on matched general ledger accounts.
    /// </remarks>
    procedure ValidateTotaling(NewTotaling: Text)
    var
        GLAccount: Record "G/L Account";
        OldTotaling: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateTotaling(Rec, NewTotaling, IsHandled);
        if IsHandled then
            exit;

        OldTotaling := GetTotaling();
        if NewTotaling = OldTotaling then
            exit;
        if NewTotaling <> '' then begin
            GLAccount.SetFilter("No.", NewTotaling);
            GLAccount.SetRange("Income/Balance", "Income/Balance");
            GLAccount.LockTable();
            if not GLAccount.FindSet() then
                Error(NoAccountsInFilterErr, "Income/Balance");
            if OldTotaling <> '' then
                ClearGLAccountSubcategoryEntryNo(OldTotaling, "Income/Balance");
            repeat
                GLAccount.Validate("Account Subcategory Entry No.", "Entry No.");
                GLAccount.Modify(true);
            until GLAccount.Next() = 0;
        end else
            ClearGLAccountSubcategoryEntryNo(OldTotaling, "Income/Balance");

        ShowNotificationAccSchedUpdateNeeded();
    end;

    local procedure ClearGLAccountSubcategoryEntryNo("Filter": Text; IncomeBalance: Enum "G/L Account Report Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("No.", Filter);
        GLAccount.SetRange("Income/Balance", IncomeBalance);
        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
    end;

    /// <summary>
    /// Opens a lookup page to select G/L accounts for the Totaling field.
    /// Provides a filtered view based on the category's Income/Balance setting.
    /// </summary>
    procedure LookupTotaling()
    var
        GLAccount: Record "G/L Account";
        GLAccList: Page "G/L Account List";
        OldTotaling: Text;
    begin
        GLAccount.SetRange("Income/Balance", "Income/Balance");
        OldTotaling := GetTotaling();
        if OldTotaling <> '' then begin
            GLAccount.SetFilter("No.", OldTotaling);
            if GLAccount.FindFirst() then
                GLAccList.SetRecord(GLAccount);
            GLAccount.SetRange("No.");
        end;
        GLAccList.SetTableView(GLAccount);
        GLAccList.LookupMode(true);
        if GLAccList.RunModal() = ACTION::LookupOK then
            ValidateTotaling(GLAccList.GetSelectionFilter());
    end;

    /// <summary>
    /// Determines if the account category has a positive normal balance.
    /// Returns true for Expense, Assets, and Cost of Goods Sold categories.
    /// </summary>
    procedure PositiveNormalBalance(): Boolean
    begin
        exit("Account Category" in ["Account Category"::Expense, "Account Category"::Assets, "Account Category"::"Cost of Goods Sold"]);
    end;

    /// <summary>
    /// Calculates the total balance for this account category including all child categories.
    /// Processes both totaling accounts and hierarchical child categories.
    /// </summary>
    procedure GetBalance(): Decimal
    var
        GLEntry: Record "G/L Entry";
        GLAccountCategory: Record "G/L Account Category";
        Balance: Decimal;
        TotalingStr: Text;
        IsHandled: Boolean;
    begin
        CalcFields("Has Children");
        if "Has Children" then begin
            OnGetBalanceOnBeforeProcessChildren(Rec, Balance, IsHandled);
            if not IsHandled then begin
                GLAccountCategory.SetRange("Parent Entry No.", "Entry No.");
                if GLAccountCategory.FindSet() then
                    repeat
                        Balance += GLAccountCategory.GetBalance();
                    until GLAccountCategory.Next() = 0;
            end;
        end;
        TotalingStr := GetTotaling();
        if TotalingStr = '' then
            exit(Balance);

        IsHandled := false;
        OnGetBalanceOnAfterGetTotaling(Rec, TotalingStr, Balance, IsHandled);
        if IsHandled then
            exit(Balance);

        GLEntry.SetFilter("G/L Account No.", TotalingStr);
        GLEntry.CalcSums(Amount);
        exit(Balance + GLEntry.Amount);
    end;

    /// <summary>
    /// Gets the totaling filter string for this account category.
    /// Returns the account filter used for calculating category totals.
    /// </summary>
    procedure GetTotaling(): Text[250]
    var
        GLAccount: Record "G/L Account";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        TotalingStr: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTotaling(Rec, TotalingStr, IsHandled);
        if IsHandled then
            exit(TotalingStr);

        GLAccount.SetRange("Account Subcategory Entry No.", "Entry No.");
        exit(CopyStr(SelectionFilterManagement.GetSelectionFilterForGLAccount(GLAccount), 1, 250));
    end;

    /// <summary>
    /// Shows a notification that account schedules need to be updated when categories change.
    /// Helps maintain consistency between account categories and financial reporting.
    /// </summary>
    procedure ShowNotificationAccSchedUpdateNeeded()
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AccSchedUpdateNeededNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetAccSchedUpdateNeededNotificationId()) then
            exit;

        AccSchedUpdateNeededNotification.Id := GetAccSchedUpdateNeededNotificationId();
        AccSchedUpdateNeededNotification.Message := AccSchedUpdateNeededNotificationMsg;
        AccSchedUpdateNeededNotification.AddAction(GenerateAccountSchedulesLbl, CODEUNIT::"Categ. Generate Acc. Schedules", 'RunGenerateAccSchedules');
        AccSchedUpdateNeededNotification.AddAction(
          DontShowAgainActionLbl, CODEUNIT::"Categ. Generate Acc. Schedules", 'HideAccSchedUpdateNeededNotificationForCurrentUser');
        AccSchedUpdateNeededNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        NotificationLifecycleMgt.SendNotification(AccSchedUpdateNeededNotification, RecordId);
    end;

    /// <summary>
    /// Returns the unique identifier for the account schedule update needed notification.
    /// Used for notification management and user preferences.
    /// </summary>
    procedure GetAccSchedUpdateNeededNotificationId(): Guid
    begin
        exit('a9b554dd-98ea-4713-90c8-ecc652419a50');
    end;

    /// <summary>
    /// Disables the account schedule update notification for the current user.
    /// Allows users to opt out of future notifications about category updates.
    /// </summary>
    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            MyNotifications.InsertDefault(NotificationID, WarnAccountCategoriesUpdatedTxt,
              WarnGenerateAccountSchedulesTxt, false);
    end;

    /// <summary>
    /// Integration event that allows customization of the GetTotaling procedure.
    /// Subscribers can provide custom totaling logic before the standard calculation.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotaling(GLAccountCategory: Record "G/L Account Category"; var TotallingStr: Text[250]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of the category move operation.
    /// Subscribers can implement custom logic before moving account categories.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMove(var RecGLAccountCategory: Record "G/L Account Category"; var GLAccountCategory: Record "G/L Account Category"; Steps: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of descendant category updates.
    /// Subscribers can implement custom logic before updating child categories.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDescendants(var GLAccountCategory: Record "G/L Account Category"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of presentation order updates.
    /// Subscribers can implement custom logic before updating category display order.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePresentationOrder(var GLAccountCategory: Record "G/L Account Category"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of totaling validation.
    /// Subscribers can implement custom validation logic before totaling field changes.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTotaling(var GLAccountCategory: Record "G/L Account Category"; NewTotaling: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of balance calculation after totaling.
    /// Subscribers can modify the balance calculation based on totaling results.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnGetBalanceOnAfterGetTotaling(var GLAccountCategory: Record "G/L Account Category"; TotalingStr: Text; var Balance: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of balance calculation before processing child categories.
    /// Subscribers can modify the balance calculation before child category processing.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnGetBalanceOnBeforeProcessChildren(var GLAccountCategory: Record "G/L Account Category"; var Balance: Decimal; var IsHandled: Boolean)
    begin
    end;
}

