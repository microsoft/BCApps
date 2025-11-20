// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 550 "VAT Rate Change Setup"
{
    Caption = 'VAT Rate Change Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(10; "Update Gen. Prod. Post. Groups"; Option)
        {
            Caption = 'Update Gen. Prod. Post. Groups';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        field(15; "Update G/L Accounts"; Option)
        {
            Caption = 'Update G/L Accounts';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(17; "Update Items"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Items';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(18; "Update Item Templates"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Item Templates';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(19; "Update Item Charges"; Option)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Update Item Charges';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(21; "Update Resources"; Option)
        {
            AccessByPermission = TableData Resource = R;
            Caption = 'Update Resources';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(30; "Update Gen. Journal Lines"; Option)
        {
            Caption = 'Update Gen. Journal Lines';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(31; "Update Gen. Journal Allocation"; Option)
        {
            AccessByPermission = TableData "Gen. Jnl. Allocation" = R;
            Caption = 'Update Gen. Journal Allocation';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(32; "Update Std. Gen. Jnl. Lines"; Option)
        {
            Caption = 'Update Std. Gen. Jnl. Lines';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(33; "Update Res. Journal Lines"; Option)
        {
            AccessByPermission = TableData Resource = R;
            Caption = 'Update Res. Journal Lines';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(35; "Update Job Journal Lines"; Option)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Update Project Journal Lines';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(37; "Update Requisition Lines"; Option)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Update Requisition Lines';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(39; "Update Std. Item Jnl. Lines"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Std. Item Jnl. Lines';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        field(50; "Update Sales Documents"; Option)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Update Sales Documents';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(55; "Update Purchase Documents"; Option)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Update Purchase Documents';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        field(70; "Update Reminders"; Option)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Update Reminders';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        field(75; "Update Finance Charge Memos"; Option)
        {
            Caption = 'Update Finance Charge Memos';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        field(90; "VAT Rate Change Tool Completed"; Boolean)
        {
            Caption = 'VAT Rate Change Tool Completed';
            InitValue = false;
        }
        field(91; "Ignore Status on Sales Docs."; Boolean)
        {
            Caption = 'Ignore Status on Sales Docs.';
            InitValue = true;
        }
        field(92; "Ignore Status on Purch. Docs."; Boolean)
        {
            Caption = 'Ignore Status on Purch. Docs.';
            InitValue = true;
        }
        field(93; "Perform Conversion"; Boolean)
        {
            Caption = 'Perform Conversion';
        }
        field(100; "Item Filter"; Text[250])
        {
            Caption = 'Item Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(101; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(102; "Resource Filter"; Text[250])
        {
            Caption = 'Resource Filter';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(110; "Update Unit Price For G/L Acc."; Boolean)
        {
            Caption = 'Update Unit Prices for G/L Accounts';
        }
        field(111; "Upd. Unit Price For Item Chrg."; Boolean)
        {
            Caption = 'Update Unit Prices for Item Charges';
        }
        field(112; "Upd. Unit Price For FA"; Boolean)
        {
            Caption = 'Update Unit Prices for Fixed Assets';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure LookUpItemFilter(var Text: Text[250]): Boolean
    var
        Item: Record Item;
        ItemList: Page "Item List";
    begin
        ItemList.LookupMode(true);
        ItemList.SetTableView(Item);
        if ItemList.RunModal() = ACTION::LookupOK then begin
            ItemList.GetRecord(Item);
            Text := ItemList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure LookUpResourceFilter(var Text: Text[250]): Boolean
    var
        Resource: Record Resource;
        ResourceList: Page "Resource List";
    begin
        ResourceList.LookupMode(true);
        ResourceList.SetTableView(Resource);
        if ResourceList.RunModal() = ACTION::LookupOK then begin
            ResourceList.GetRecord(Resource);
            Text := Resource."No.";
            exit(true);
        end;
        exit(false)
    end;

    procedure LookUpGLAccountFilter(var Text: Text[250]): Boolean
    var
        GLAccount: Record "G/L Account";
        GLAccountList: Page "G/L Account List";
    begin
        GLAccountList.LookupMode(true);
        GLAccountList.SetTableView(GLAccount);
        if GLAccountList.RunModal() = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            Text := GLAccountList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;
}

