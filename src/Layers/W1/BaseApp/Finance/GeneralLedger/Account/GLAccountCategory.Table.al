// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Environment.Configuration;
using System.Text;

table 570 "G/L Account Category"
{
    Caption = 'G/L Account Category';
    DataCaptionFields = Description;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Parent Entry No."; Integer)
        {
            Caption = 'Parent Entry No.';
        }
        field(3; "Sibling Sequence No."; Integer)
        {
            Caption = 'Sibling Sequence No.';
        }
        field(4; "Presentation Order"; Text[100])
        {
            Caption = 'Presentation Order';
        }
        field(5; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(6; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(7; "Account Category"; Option)
        {
            BlankZero = true;
            Caption = 'Account Category';
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
        field(8; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
            Editable = false;

            trigger OnValidate()
            begin
                UpdatePresentationOrder();
            end;
        }
        field(9; "Additional Report Definition"; Option)
        {
            Caption = 'Additional Report Definition';
            OptionCaption = ' ,Operating Activities,Investing Activities,Financing Activities,Cash Accounts,Retained Earnings,Distribution to Shareholders';
            OptionMembers = " ","Operating Activities","Investing Activities","Financing Activities","Cash Accounts","Retained Earnings","Distribution to Shareholders";

            trigger OnValidate()
            begin
                if "Additional Report Definition" <> "Additional Report Definition"::" " then
                    TestField("Income/Balance", "Income/Balance"::"Balance Sheet");
            end;
        }
        field(11; "System Generated"; Boolean)
        {
            Caption = 'System Generated';
        }
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

    procedure InitializeDataSet()
    begin
        CODEUNIT.Run(CODEUNIT::"G/L Account Category Mgt.");
    end;

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

    procedure MoveUp()
    begin
        Move(-1);
    end;

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

    procedure MakeChildOfPreviousSibling()
    begin
        ChangeAncestor(true);
    end;

    procedure MakeSiblingOfParent()
    begin
        ChangeAncestor(false);
    end;

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

    procedure MapAccounts()
    begin
    end;

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

    procedure PositiveNormalBalance(): Boolean
    begin
        exit("Account Category" in ["Account Category"::Expense, "Account Category"::Assets, "Account Category"::"Cost of Goods Sold"]);
    end;

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

    procedure GetAccSchedUpdateNeededNotificationId(): Guid
    begin
        exit('a9b554dd-98ea-4713-90c8-ecc652419a50');
    end;

    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            MyNotifications.InsertDefault(NotificationID, WarnAccountCategoriesUpdatedTxt,
              WarnGenerateAccountSchedulesTxt, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotaling(GLAccountCategory: Record "G/L Account Category"; var TotallingStr: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMove(var RecGLAccountCategory: Record "G/L Account Category"; var GLAccountCategory: Record "G/L Account Category"; Steps: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDescendants(var GLAccountCategory: Record "G/L Account Category"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePresentationOrder(var GLAccountCategory: Record "G/L Account Category"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTotaling(var GLAccountCategory: Record "G/L Account Category"; NewTotaling: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBalanceOnAfterGetTotaling(var GLAccountCategory: Record "G/L Account Category"; TotalingStr: Text; var Balance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBalanceOnBeforeProcessChildren(var GLAccountCategory: Record "G/L Account Category"; var Balance: Decimal; var IsHandled: Boolean)
    begin
    end;
}

