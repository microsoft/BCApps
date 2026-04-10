// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 169 "Job Ledger Entry"
{
    Caption = 'Project Ledger Entry';
    DrillDownPageID = "Job Ledger Entries";
    LookupPageID = "Job Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the project.';
            TableRelation = Job;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date for the entry.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number on the project ledger entry.';
        }
        field(5; Type; Enum "Job Journal Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of account to which the project ledger entry is posted.';
        }
        field(7; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("G/L Account")) "G/L Account";
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the project ledger entry.';
        }
        field(9; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity that was posted on the entry.';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Direct Unit Cost (LCY)';
        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost (LCY)';
            Editable = false;
        }
        field(13; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(14; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;
        }
        field(15; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(16; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";
        }
        field(17; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(19; "Job Register No."; Integer)
        {
            Caption = 'Job Register No.';
            Editable = false;
            TableRelation = "Job Register";
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the relevant location code if an item is posted.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; "Job Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            ToolTip = 'Specifies the posting group that was used when the entry was posted. The value depends on the account type. For inventoriable items, the field contains the Inventory Posting Group. For other account types the field is blank.';
            TableRelation = "Inventory Posting Group";
        }
        field(30; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(31; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(32; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";
        }
        field(33; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(37; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(38; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(60; "Amt. to Post to G/L"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Amt. to Post to G/L';
            ToolTip = 'Specifies the amount that will be posted to the general ledger.';
        }
        field(61; "Amt. Posted to G/L"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Amt. Posted to G/L';
            ToolTip = 'Specifies the amount that has been posted to the general ledger.';
        }
        field(64; "Entry Type"; Enum "Job Journal Line Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the type of the entry. There are two types of entries:';
        }
        field(75; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(76; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(77; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(78; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(79; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(80; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(81; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        field(82; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(83; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(84; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(85; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(86; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(87; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(88; "Additional-Currency Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Additional-Currency Total Cost';
        }
        field(89; "Add.-Currency Total Price"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Add.-Currency Total Price';
        }
        field(94; "Add.-Currency Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Add.-Currency Line Amount';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1001; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Line Amount (LCY)';
            Editable = false;
        }
        field(1002; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
        }
        field(1003; "Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            ToolTip = 'Specifies the total cost for the posted entry, in the currency specified for the project.';
        }
        field(1004; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        field(1005; "Total Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            ToolTip = 'Specifies the total price for the posted entry, in the currency specified for the project.';
        }
        field(1006; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            ToolTip = 'Specifies the value of products on the entry.';
        }
        field(1007; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the line discount amount for the posted entry, in the currency specified for the project.';
        }
        field(1008; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;
        }
        field(1009; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(1010; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
        }
        field(1016; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(1017; "Ledger Entry Type"; Enum "Job Ledger Entry Type")
        {
            Caption = 'Ledger Entry Type';
            ToolTip = 'Specifies the entry type that the project ledger entry is linked to.';
        }
        field(1018; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            ToolTip = 'Specifies the entry number (Resource, Item or G/L) to which the project ledger entry is linked.';
            TableRelation = if ("Ledger Entry Type" = const(Resource)) "Res. Ledger Entry"
            else
            if ("Ledger Entry Type" = const(Item)) "Item Ledger Entry"
            else
            if ("Ledger Entry Type" = const("G/L Account")) "G/L Entry";
        }
        field(1019; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number if the project ledger entry Specifies an item usage that was posted with serial number tracking.';
        }
        field(1020; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number if the project ledger entry Specifies an item usage that was posted with lot number tracking.';
        }
        field(1021; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the line discount percent of the posted entry.';
            DecimalPlaces = 0 : 5;
        }
        field(1022; "Line Type"; Enum "Job Line Type")
        {
            Caption = 'Line Type';
        }
        field(1023; "Original Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Original Unit Cost (LCY)';
            Editable = false;
        }
        field(1024; "Original Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Total Cost (LCY)';
            Editable = false;
        }
        field(1025; "Original Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Original Unit Cost';
            ToolTip = 'Specifies the unit cost for the posted entry at the time of posting, in the currency specified for the project. No item cost adjustments are included.';
        }
        field(1026; "Original Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Total Cost';
            ToolTip = 'Specifies the total cost for the posted entry at the time of posting, in the currency specified for the project. No item cost adjustments are included.';
        }
        field(1027; "Original Total Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Original Total Cost (ACY)';
        }
        field(1028; Adjusted; Boolean)
        {
            Caption = 'Adjusted';
            ToolTip = 'Specifies whether a project ledger entry has been modified or adjusted. The value in this field is inserted by the Adjust Cost - Item Entries batch job. The Adjusted check box is selected if applicable.';
        }
        field(1029; "DateTime Adjusted"; DateTime)
        {
            Caption = 'DateTime Adjusted';
            ToolTip = 'Specifies the time stamp of a project ledger entry adjustment or modification.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5405; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", "Job Task No.", "Entry Type", "Posting Date")
        {
            IncludedFields = "Total Cost (LCY)", "Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
        key(Key4; "Job No.", "Posting Date")
        {
            IncludedFields = "Amt. to Post to G/L";
        }
        key(Key5; "Entry Type", Type, "No.", "Posting Date")
        {
        }
        key(Key7; "Job No.", "Entry Type", Type, "No.")
        {
        }
        key(Key8; Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date")
        {
        }
        key(Key9; "Job No.", "Entry Type", Type, "Posting Date")
        {
            MaintainSQLIndex = false;
            SumIndexFields = "Total Cost (LCY)", "Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key10; "Ledger Entry Type", "Ledger Entry No.")
        {
        }
        key(Key11; Type, "No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Job No.", "Posting Date", "Document No.")
        {
        }
    }

    trigger OnDelete()
    begin
        Job.UpdateOverBudgetValue("Job No.", true, "Total Cost (LCY)");
    end;

    trigger OnInsert()
    begin
        Job.UpdateOverBudgetValue("Job No.", true, "Total Cost (LCY)");
    end;

    trigger OnModify()
    begin
        Job.UpdateOverBudgetValue("Job No.", true, "Total Cost (LCY)");
    end;

    var
        Job: Record Job;
        DimMgt: Codeunit DimensionManagement;

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Ledger Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Job Ledger Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CopyTrackingFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Serial No." := JobJnlLine."Serial No.";
        "Lot No." := JobJnlLine."Lot No.";

        OnAfterCopyTrackingFromJobJnlLine(Rec, JobJnlLine);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobJnlLine(var JobLedgerEntry: Record "Job Ledger Entry"; JobJnlLine: Record "Job Journal Line")
    begin
    end;
}
