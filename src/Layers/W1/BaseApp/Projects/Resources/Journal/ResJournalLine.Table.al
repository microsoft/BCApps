// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

table 207 "Res. Journal Line"
{
    Caption = 'Res. Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Res. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Entry Type"; Enum "Res. Journal Line Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies an entry type for each line.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies a document number for the journal line.';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when you want to assign.';

            trigger OnValidate()
            begin
                TestField("Posting Date");
                Validate("Document Date", "Posting Date");
            end;
        }
        field(6; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the number of the resource that you want to post an entry for.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                if "Resource No." = '' then begin
                    CreateDimFromDefaultDim(Rec.FieldNo("Resource No."));
                    exit;
                end;

                Res.Get("Resource No.");
                Res.CheckResourcePrivacyBlocked(false);
                Res.TestField(Blocked, false);
                OnValidateResourceNoOnAfterChecks(Res, Rec, xRec);

                Description := Res.Name;
                "Direct Unit Cost" := Res."Direct Unit Cost";
                "Unit Cost" := Res."Unit Cost";
                "Unit Price" := Res."Unit Price";
                "Resource Group No." := Res."Resource Group No.";
                "Work Type Code" := '';
                "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
                Validate("Unit of Measure Code", Res."Base Unit of Measure");

                if not "System-Created Entry" then
                    if "Time Sheet No." = '' then
                        Res.TestField("Use Time Sheet", false);

                CreateDimFromDefaultDim(Rec.FieldNo("Resource No."));
            end;
        }
        field(7; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            ToolTip = 'Specifies the resource group that this resource is assigned to.';
            Editable = false;
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Resource Group No."));
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description or name of the resource you chose in the Resource No. field.';
        }
        field(9; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                ResourceUnitOfMeasure: Record "Resource Unit of Measure";
            begin
                if "Resource No." <> '' then begin
                    if WorkType.Get("Work Type Code") then
                        "Unit of Measure Code" := WorkType."Unit of Measure Code"
                    else begin
                        Res.Get("Resource No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                    end;

                    if "Unit of Measure Code" = '' then begin
                        Res.Get("Resource No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure"
                    end;
                    "Qty. per Unit of Measure" := 1;
                    if ResourceUnitOfMeasure.Get("Resource No.", "Unit of Measure Code") then
                        "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";

                    FindResUnitCost(FieldNo("Work Type Code"));
                    FindResPrice(FieldNo("Work Type Code"));
                end;
            end;
        }
        field(10; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            TableRelation = Job;

            trigger OnValidate()
            begin
                FindResPrice(FieldNo("Job No."));

                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
            end;
        }
        field(11; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Resource Unit of Measure".Code where("Resource No." = field("Resource No."));

            trigger OnValidate()
            var
                ResourceUnitOfMeasure: Record "Resource Unit of Measure";
            begin
                if CurrFieldNo <> FieldNo("Work Type Code") then
                    TestField("Work Type Code", '');

                if "Unit of Measure Code" = '' then begin
                    Res.Get("Resource No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure"
                end;
                ResourceUnitOfMeasure.Get("Resource No.", "Unit of Measure Code");
                "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";

                FindResUnitCost(FieldNo("Unit of Measure Code"));
                FindResPrice(FieldNo("Unit of Measure Code"));

                Validate(Quantity);
            end;
        }
        field(12; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the item or resource specified on the line.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Unit Cost");
                Validate("Unit Price");
            end;
        }
        field(13; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Direct Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
            MinValue = 0;
        }
        field(14; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Cost" := Quantity * "Unit Cost";
            end;
        }
        field(15; "Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Cost';
            ToolTip = 'Specifies the total cost for this journal line.';

            trigger OnValidate()
            begin
                TestField(Quantity);
                GetGLSetup();
                "Unit Cost" := Round("Total Cost" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(16; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Price" := Quantity * "Unit Price";
            end;
        }
        field(17; "Total Price"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Price';
            ToolTip = 'Specifies the total price on the journal line.';

            trigger OnValidate()
            begin
                TestField(Quantity);
                GetGLSetup();
                "Unit Price" := Round("Total Price" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(18; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(19; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(21; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(23; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Res. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(24; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(25; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            ToolTip = 'Specifies what happens to the quantity on the journal line after posting.';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(26; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the last date when a recurring journal can be posted.';
        }
        field(27; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
            ToolTip = 'Specifies a recurring frequency if you have indicated in the Recurring field of the Res. Journal Template the journal is recurring.';
        }
        field(28; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(29; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        field(31; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(32; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(33; "Source Type"; Enum "Res. Journal Line Source Type")
        {
            Caption = 'Source Type';
        }
        field(34; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer."No.";
        }
        field(35; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            ToolTip = 'Specifies the number of a time sheet.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            ToolTip = 'Specifies the line number for a time sheet.';
            TableRelation = "Time Sheet Line"."Line No." where("Time Sheet No." = field("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            ToolTip = 'Specifies the date when a time sheet is created.';
            TableRelation = "Time Sheet Detail".Date where("Time Sheet No." = field("Time Sheet No."),
                                                            "Time Sheet Line No." = field("Time Sheet Line No."));
        }
        field(959; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Resource No.", Description, Quantity, "Document No.", "Document Date")
        { }
    }

    trigger OnInsert()
    begin
        LockTable();
        ResJnlTemplate.Get("Journal Template Name");
        ResJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        Res: Record Resource;
        WorkType: Record "Work Type";
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        GLSetupRead: Boolean;

    procedure FindResUnitCost(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
    begin
        FindPrice(PriceType::Purchase, CalledByFieldNo);
        Validate("Unit Cost");
    end;

    procedure FindResPrice(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
    begin
        FindPrice(PriceType::Sale, CalledByFieldNo);
        Validate("Unit Price");
    end;

    local procedure FindPrice(PriceType: Enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        PriceCalculation: Interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
    begin
        LineWithPrice := ResJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    procedure AfterFindResUnitCost(var ResourceCost: Record "Resource Cost")
    begin
        OnAfterFindResUnitCost(Rec, ResourceCost);
    end;

    procedure AfterFindResPrice(var ResourcePrice: Record "Resource Price")
    begin
        OnAfterFindResPrice(Rec, ResourcePrice);
    end;

    procedure BeforeFindResPrice(var ResourcePrice: Record "Resource Price")
    begin
        OnBeforeFindResPrice(Rec, ResourcePrice);
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(("Resource No." = '') and (Quantity = 0));
    end;

    procedure SetUpNewLine(LastResJnlLine: Record "Res. Journal Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        ResJnlTemplate.Get("Journal Template Name");
        ResJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ResJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ResJnlLine.FindFirst() then begin
            "Posting Date" := LastResJnlLine."Posting Date";
            "Document Date" := LastResJnlLine."Posting Date";
            "Document No." := LastResJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if ResJnlBatch."No. Series" <> '' then
                "Document No." := NoSeries.PeekNextNo(ResJnlBatch."No. Series", "Posting Date");
        end;
        "Recurring Method" := LastResJnlLine."Recurring Method";
        "Source Code" := ResJnlTemplate."Source Code";
        "Reason Code" := ResJnlBatch."Reason Code";
        "Posting No. Series" := ResJnlBatch."Posting No. Series";

        OnAfterSetUpNewLine(Rec, LastResJnlLine);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        OldDimSetID: Integer;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource, xRec, OldDimSetID);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure CopyDocumentFields(DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Posting Date" := SalesHeader."Posting Date";
        "Document Date" := SalesHeader."Document Date";
        "Reason Code" := SalesHeader."Reason Code";

        OnAfterCopyResJnlLineFromSalesHeader(SalesHeader, Rec);
    end;

    procedure CopyFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Resource No." := SalesLine."No.";
        Description := SalesLine.Description;
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesLine."Sell-to Customer No.";
        "Work Type Code" := SalesLine."Work Type Code";
        "Job No." := SalesLine."Job No.";
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "Entry Type" := "Entry Type"::Sale;
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        Quantity := -SalesLine."Qty. to Invoice";
        "Unit Cost" := SalesLine."Unit Cost (LCY)";
        "Total Cost" := SalesLine."Unit Cost (LCY)" * Quantity;
        "Unit Price" := SalesLine."Unit Price";
        "Total Price" := -SalesLine.Amount;

        OnAfterCopyResJnlLineFromSalesLine(SalesLine, Rec);
    end;





    procedure CopyFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    var
        Job: Record Job;
    begin
        "Entry Type" := JobJnlLine."Entry Type";
        "Document No." := JobJnlLine."Document No.";
        "External Document No." := JobJnlLine."External Document No.";
        "Posting Date" := JobJnlLine."Posting Date";
        "Document Date" := JobJnlLine."Document Date";
        "Resource No." := JobJnlLine."No.";
        Description := JobJnlLine.Description;
        "Work Type Code" := JobJnlLine."Work Type Code";
        "Job No." := JobJnlLine."Job No.";
        if "Job No." <> '' then
            if Job.Get("Job No.") and (Job."Bill-to Customer No." <> '') then begin
                "Source Type" := "Source Type"::Customer;
                "Source No." := Job."Bill-to Customer No.";
            end;
        "Shortcut Dimension 1 Code" := JobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := JobJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := JobJnlLine."Dimension Set ID";
        "Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        "Source Code" := JobJnlLine."Source Code";
        "Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        "Posting No. Series" := JobJnlLine."Posting No. Series";
        "Reason Code" := JobJnlLine."Reason Code";
        "Resource Group No." := JobJnlLine."Resource Group No.";
        "Recurring Method" := JobJnlLine."Recurring Method";
        "Expiration Date" := JobJnlLine."Expiration Date";
        "Recurring Frequency" := JobJnlLine."Recurring Frequency";
        Quantity := JobJnlLine.Quantity;
        "Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";
        "Direct Unit Cost" := JobJnlLine."Direct Unit Cost (LCY)";
        "Unit Cost" := JobJnlLine."Unit Cost (LCY)";
        "Total Cost" := JobJnlLine."Total Cost (LCY)";
        "Unit Price" := JobJnlLine."Unit Price (LCY)";
        "Total Price" := JobJnlLine."Line Amount (LCY)";
        "Time Sheet No." := JobJnlLine."Time Sheet No.";
        "Time Sheet Line No." := JobJnlLine."Time Sheet Line No.";
        "Time Sheet Date" := JobJnlLine."Time Sheet Date";

        OnAfterCopyResJnlLineFromJobJnlLine(Rec, JobJnlLine);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        ResJournalBatch: Record "Res. Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                ResJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            ResJournalBatch.SetFilter(Name, BatchFilter);
            ResJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure CopyFrom(PurchaseHeader: Record "Purchase Header")
    begin
        "Posting Date" := PurchaseHeader."Posting Date";
        "Document Date" := PurchaseHeader."Document Date";
        "Reason Code" := PurchaseHeader."Reason Code";

        OnAfterCopyResJnlLineFromPurchaseHeader(PurchaseHeader, Rec);
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        ResJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            ResJournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    procedure CopyFrom(PurchaseLine: Record "Purchase Line")
    begin
        "Resource No." := PurchaseLine."No.";
        Description := PurchaseLine.Description;
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchaseLine."Buy-from Vendor No.";
        "Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        "Shortcut Dimension 1 Code" := PurchaseLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchaseLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchaseLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := PurchaseLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
        "Entry Type" := "Entry Type"::Purchase;
        "Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
        Quantity := PurchaseLine."Qty. to Invoice";
        "Unit Cost" := PurchaseLine."Unit Cost (LCY)";
        "Total Cost" := PurchaseLine."Unit Cost (LCY)" * Quantity;
        "Unit Price" := PurchaseLine."Direct Unit Cost";
        "Total Price" := PurchaseLine.Amount;

        OnAfterCopyResJnlLineFromPurchaseLine(PurchaseLine, Rec);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Resource, Rec."Resource No.", FieldNo = Rec.FieldNo("Resource No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Resource Group", Rec."Resource Group No.", FieldNo = Rec.FieldNo("Resource Group No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ResJournalLine: Record "Res. Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var ResJournalLine: Record "Res. Journal Line"; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; xResJournalLine: Record "Res. Journal Line"; OldDimSetID: Integer)
    begin
    end;

    procedure AfterInitResourceCost(var ResourceCost: Record "Resource Cost")
    begin
        OnAfterInitResourceCost(Rec, ResourceCost);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromSalesHeader(var SalesHeader: Record "Sales Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromSalesLine(var SalesLine: Record "Sales Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;






    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromJobJnlLine(var ResJnlLine: Record "Res. Journal Line"; var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ResJournalLine: Record "Res. Journal Line"; LastResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ResJournalLine: Record "Res. Journal Line"; xResJournalLine: Record "Res. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindResPrice(ResJournalLine: Record "Res. Journal Line"; var ResourcePrice: Record "Resource Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ResJournalLine: Record "Res. Journal Line"; xResJournalLine: Record "Res. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromPurchaseHeader(PurchaseHeader: Record "Purchase Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromPurchaseLine(PurchaseLine: Record "Purchase Line"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateResourceNoOnAfterChecks(var Resource: Record Resource; var ResJournalLine: Record "Res. Journal Line"; xResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitResourceCost(var ResJournalLine: Record "Res. Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResUnitCost(var ResJournalLine: Record "Res. Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResPrice(var ResJournalLine: Record "Res. Journal Line"; var ResPrice: Record "Resource Price")
    begin
    end;
}
