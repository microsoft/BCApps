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

/// <summary>
/// Configuration table for VAT rate change conversion settings and filters.
/// Controls which master data, journals, and documents are updated during VAT rate change operations.
/// </summary>
table 550 "VAT Rate Change Setup"
{
    Caption = 'VAT Rate Change Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for the singleton setup record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Specifies whether general product posting groups should be updated during VAT rate change conversion.
        /// </summary>
        field(10; "Update Gen. Prod. Post. Groups"; Option)
        {
            Caption = 'Update Gen. Prod. Post. Groups';
            ToolTip = 'Specifies the VAT rate change for general product posting groups.';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        /// <summary>
        /// Specifies whether G/L accounts should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(15; "Update G/L Accounts"; Option)
        {
            Caption = 'Update G/L Accounts';
            ToolTip = 'Specifies the VAT rate change for general ledger accounts.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether items should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(17; "Update Items"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Items';
            ToolTip = 'Specifies the VAT rate change for items.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether item templates should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(18; "Update Item Templates"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Item Templates';
            ToolTip = 'Specifies that VAT rate changes are updated for item categories.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether item charges should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(19; "Update Item Charges"; Option)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Update Item Charges';
            ToolTip = 'Specifies the VAT rate change for item charges.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether resources should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(21; "Update Resources"; Option)
        {
            AccessByPermission = TableData Resource = R;
            Caption = 'Update Resources';
            ToolTip = 'Specifies the VAT rate change for resources.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether general journal lines should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(30; "Update Gen. Journal Lines"; Option)
        {
            Caption = 'Update Gen. Journal Lines';
            ToolTip = 'Specifies the VAT rate change for general journal lines.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether general journal allocation lines should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(31; "Update Gen. Journal Allocation"; Option)
        {
            AccessByPermission = TableData "Gen. Jnl. Allocation" = R;
            Caption = 'Update Gen. Journal Allocation';
            ToolTip = 'Specifies the VAT rate change for general journal allocation.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether standard general journal lines should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(32; "Update Std. Gen. Jnl. Lines"; Option)
        {
            Caption = 'Update Std. Gen. Jnl. Lines';
            ToolTip = 'Specifies the VAT rate change for standard general journal lines.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether resource journal lines should be updated with general product posting groups during conversion.
        /// </summary>
        field(33; "Update Res. Journal Lines"; Option)
        {
            AccessByPermission = TableData Resource = R;
            Caption = 'Update Res. Journal Lines';
            ToolTip = 'Specifies the VAT rate change for resource journal lines.';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        /// <summary>
        /// Specifies whether project journal lines should be updated with general product posting groups during conversion.
        /// </summary>
        field(35; "Update Job Journal Lines"; Option)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Update Project Journal Lines';
            ToolTip = 'Specifies the VAT rate change for job journal lines.';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        /// <summary>
        /// Specifies whether requisition lines should be updated with general product posting groups during conversion.
        /// </summary>
        field(37; "Update Requisition Lines"; Option)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Update Requisition Lines';
            ToolTip = 'Specifies the VAT rate change for requisition lines.';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        /// <summary>
        /// Specifies whether standard item journal lines should be updated with general product posting groups during conversion.
        /// </summary>
        field(39; "Update Std. Item Jnl. Lines"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Update Std. Item Jnl. Lines';
            ToolTip = 'Specifies the VAT rate change for standard item journal lines.';
            InitValue = "Gen. Prod. Posting Group";
            OptionCaption = ',Gen. Prod. Posting Group,,No';
            OptionMembers = ,"Gen. Prod. Posting Group",,No;
        }
        /// <summary>
        /// Specifies whether sales documents should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(50; "Update Sales Documents"; Option)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Update Sales Documents';
            ToolTip = 'Specifies the VAT rate change for sales documents.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether purchase documents should be updated with new VAT or general product posting groups during conversion.
        /// </summary>
        field(55; "Update Purchase Documents"; Option)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Update Purchase Documents';
            ToolTip = 'Specifies the VAT rate change for purchase documents.';
            InitValue = Both;
            OptionCaption = 'VAT Prod. Posting Group,Gen. Prod. Posting Group,Both,No';
            OptionMembers = "VAT Prod. Posting Group","Gen. Prod. Posting Group",Both,No;
        }
        /// <summary>
        /// Specifies whether reminder documents should be updated with new VAT product posting groups during conversion.
        /// </summary>
        field(70; "Update Reminders"; Option)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Update Reminders';
            ToolTip = 'Specifies the VAT rate change for reminders.';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        /// <summary>
        /// Specifies whether finance charge memo documents should be updated with new VAT product posting groups during conversion.
        /// </summary>
        field(75; "Update Finance Charge Memos"; Option)
        {
            Caption = 'Update Finance Charge Memos';
            ToolTip = 'Specifies the VAT rate change for finance charge memos.';
            InitValue = "VAT Prod. Posting Group";
            OptionCaption = 'VAT Prod. Posting Group,,,No';
            OptionMembers = "VAT Prod. Posting Group",,,No;
        }
        /// <summary>
        /// Indicates whether the VAT rate change conversion process has been completed.
        /// </summary>
        field(90; "VAT Rate Change Tool Completed"; Boolean)
        {
            Caption = 'VAT Rate Change Tool Completed';
            ToolTip = 'Specifies if the VAT rate change conversion is complete.';
            InitValue = false;
        }
        /// <summary>
        /// Specifies whether sales documents with any status, including released documents, should be updated during conversion.
        /// </summary>
        field(91; "Ignore Status on Sales Docs."; Boolean)
        {
            Caption = 'Ignore Status on Sales Docs.';
            ToolTip = 'Specifies that all existing sales documents regardless of status, including documents with a status of released, are updated.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies whether purchase documents with any status, including released documents, should be updated during conversion.
        /// </summary>
        field(92; "Ignore Status on Purch. Docs."; Boolean)
        {
            Caption = 'Ignore Status on Purch. Docs.';
            ToolTip = 'Specifies all existing purchase documents regardless of status, including documents with a status of released, are updated.';
            InitValue = true;
        }
        /// <summary>
        /// Enables actual data modification during conversion. When false, conversion runs in preview mode only.
        /// </summary>
        field(93; "Perform Conversion"; Boolean)
        {
            Caption = 'Perform Conversion';
            ToolTip = 'Specifies that the VAT rate conversion is performed on existing data.';
        }
        /// <summary>
        /// Filter used to limit which items are included in the VAT rate change conversion process.
        /// </summary>
        field(100; "Item Filter"; Text[250])
        {
            Caption = 'Item Filter';
            ToolTip = 'Specifies which items will be updated by setting appropriate filters.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        /// <summary>
        /// Filter used to limit which G/L accounts are included in the VAT rate change conversion process.
        /// </summary>
        field(101; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            ToolTip = 'Specifies which accounts will be updated by setting appropriate filters.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        /// <summary>
        /// Filter used to limit which resources are included in the VAT rate change conversion process.
        /// </summary>
        field(102; "Resource Filter"; Text[250])
        {
            Caption = 'Resource Filter';
            ToolTip = 'Specifies which resources will be updated by setting appropriate filters.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies whether unit prices should be updated for G/L account lines when prices include VAT.
        /// </summary>
        field(110; "Update Unit Price For G/L Acc."; Boolean)
        {
            Caption = 'Update Unit Prices for G/L Accounts';
            ToolTip = 'Specifies that the unit price must be updated for document lines that have the type G/L Account.';
        }
        /// <summary>
        /// Specifies whether unit prices should be updated for item charge lines when prices include VAT.
        /// </summary>
        field(111; "Upd. Unit Price For Item Chrg."; Boolean)
        {
            Caption = 'Update Unit Prices for Item Charges';
            ToolTip = 'Specifies that the unit price must be updated for document lines that have the type Charge (Item).';
        }
        /// <summary>
        /// Specifies whether unit prices should be updated for fixed asset lines when prices include VAT.
        /// </summary>
        field(112; "Upd. Unit Price For FA"; Boolean)
        {
            Caption = 'Update Unit Prices for Fixed Assets';
            ToolTip = 'Specifies that the unit price must be updated for document lines that have the type Fixed Asset.';
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

    /// <summary>
    /// Opens item lookup dialog and sets the provided text filter based on user selection.
    /// </summary>
    /// <param name="Text">Filter text to be updated with selected item numbers</param>
    /// <returns>True if user selected items and confirmed, false if cancelled</returns>
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

    /// <summary>
    /// Opens resource lookup dialog and sets the provided text with the selected resource number.
    /// </summary>
    /// <param name="Text">Text to be updated with selected resource number</param>
    /// <returns>True if user selected a resource and confirmed, false if cancelled</returns>
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

    /// <summary>
    /// Opens G/L account lookup dialog and sets the provided text filter based on user selection.
    /// </summary>
    /// <param name="Text">Filter text to be updated with selected G/L account numbers</param>
    /// <returns>True if user selected accounts and confirmed, false if cancelled</returns>
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

