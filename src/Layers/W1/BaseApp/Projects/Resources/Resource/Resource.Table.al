// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Assembly.Document;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Security.User;

table 156 Resource
{
    Caption = 'Resource';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Resource List";
    LookupPageID = "Resource List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "No." <> xRec."No." then begin
                    ResSetup.Get();
                    NoSeries.TestManual(ResSetup."Resource Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Type; Enum "Resource Type")
        {
            Caption = 'Type';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;
            end;
        }
        field(4; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Social Security No."; Text[30])
        {
            Caption = 'Social Security No.';
        }
        field(10; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(11; Education; Text[30])
        {
            Caption = 'Education';
        }
        field(12; "Contract Class"; Text[30])
        {
            Caption = 'Contract Class';
        }
        field(13; "Employment Date"; Date)
        {
            Caption = 'Employment Date';
        }
        field(14; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Resource Group No." = xRec."Resource Group No." then
                    exit;

                if xRec."Resource Group No." <> '' then begin
                    IsHandled := false;
                    OnValidateResourceGroupNoOnBeforeConfirm(Rec, xRec, IsHandled);
                    if not IsHandled then
                        if not Confirm(Text001, false, FieldCaption("Resource Group No.")) then begin
                            "Resource Group No." := xRec."Resource Group No.";
                            exit;
                        end;
                end;

                if xRec.GetFilter("Resource Group No.") <> '' then
                    SetFilter("Resource Group No.", "Resource Group No.");

                // Resource Capacity Entries
                ResCapacityEntry.SetCurrentKey("Resource No.");
                ResCapacityEntry.SetRange("Resource No.", "No.");
                ResCapacityEntry.ModifyAll("Resource Group No.", "Resource Group No.");

                PlanningLine.SetCurrentKey(Type, "No.");
                PlanningLine.SetRange(Type, PlanningLine.Type::Resource);
                PlanningLine.SetRange("No.", "No.");
                PlanningLine.SetRange("Schedule Line", true);
                PlanningLine.ModifyAll("Resource Group No.", "Resource Group No.");
            end;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(18; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            var
                UnitOfMeasure: Record "Unit of Measure";
                ResUnitOfMeasure: Record "Resource Unit of Measure";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBaseUnitOfMeasure(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then begin
                    TestNoEntriesExist(FieldCaption("Base Unit of Measure"));

                    if "Base Unit of Measure" <> '' then begin
                        UnitOfMeasure.Get("Base Unit of Measure");
                        if not ResUnitOfMeasure.Get("No.", "Base Unit of Measure") then begin
                            ResUnitOfMeasure.Init();
                            ResUnitOfMeasure.Validate("Resource No.", "No.");
                            ResUnitOfMeasure.Validate(Code, "Base Unit of Measure");
                            ResUnitOfMeasure."Qty. per Unit of Measure" := 1;
                            ResUnitOfMeasure.Insert();
                        end else begin
                            if ResUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", ResUnitOfMeasure."Qty. per Unit of Measure");
                            ResUnitOfMeasure.TestField("Related to Base Unit of Meas.");
                        end;
                    end;
                end;
            end;
        }
        field(19; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(20; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                Validate("Unit Cost", Round("Direct Unit Cost" * (1 + "Indirect Cost %" / 100)));
            end;
        }
        field(21; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(22; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(23; "Price/Profit Calculation"; Option)
        {
            Caption = 'Price/Profit Calculation';
            OptionCaption = 'Profit=Price-Cost,Price=Cost+Profit,No Relationship';
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";

            trigger OnValidate()
            begin
                case "Price/Profit Calculation" of
                    "Price/Profit Calculation"::"Profit=Price-Cost":
                        if "Unit Price" <> 0 then
                            "Profit %" := Round(100 * (1 - "Unit Cost" / "Unit Price"), 0.00001)
                        else
                            "Profit %" := 0;
                    "Price/Profit Calculation"::"Price=Cost+Profit":
                        if "Profit %" < 100 then
                            "Unit Price" := Round("Unit Cost" / (1 - "Profit %" / 100), 0.00001);
                end;
            end;
        }
        field(24; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(25; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(27; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const(Resource),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked and "Privacy Blocked" then
                    if GuiAllowed then
                        if Confirm(ConfirmBlockedPrivacyBlockedQst) then
                            "Privacy Blocked" := false
                        else
                            Error('')
                    else
                        Error(CanNotChangeBlockedDueToPrivacyBlockedErr);
            end;
        }
        field(39; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(40; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(41; Capacity; Decimal)
        {
            CalcFormula = sum("Res. Capacity Entry".Capacity where("Resource No." = field("No."),
                                                                    Date = field("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(42; "Qty. on Order (Job)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where(Status = const(Order),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "No." = field("No."),
                                                                           "Planning Date" = field("Date Filter")));
            Caption = 'Qty. on Order (Project)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Qty. Quoted (Job)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where(Status = const(Quote),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "No." = field("No."),
                                                                           "Planning Date" = field("Date Filter")));
            Caption = 'Qty. Quoted (Project)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Usage (Qty.)"; Decimal)
        {
            CalcFormula = sum("Res. Ledger Entry"."Quantity (Base)" where("Entry Type" = const(Usage),
                                                                           Chargeable = field("Chargeable Filter"),
                                                                           "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                           "Resource No." = field("No."),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Usage (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = sum("Res. Ledger Entry"."Total Cost" where("Entry Type" = const(Usage),
                                                                      Chargeable = field("Chargeable Filter"),
                                                                      "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                      "Resource No." = field("No."),
                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Usage (Price)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = sum("Res. Ledger Entry"."Total Price" where("Entry Type" = const(Usage),
                                                                       Chargeable = field("Chargeable Filter"),
                                                                       "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                       "Resource No." = field("No."),
                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Res. Ledger Entry"."Quantity (Base)" where("Entry Type" = const(Sale),
                                                                            "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                            "Resource No." = field("No."),
                                                                            "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Sales (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = - sum("Res. Ledger Entry"."Total Cost" where("Entry Type" = const(Sale),
                                                                       "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                       "Resource No." = field("No."),
                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Sales (Price)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = - sum("Res. Ledger Entry"."Total Price" where("Entry Type" = const(Sale),
                                                                        "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                        "Resource No." = field("No."),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Chargeable Filter"; Boolean)
        {
            Caption = 'Chargeable Filter';
            FieldClass = FlowFilter;
        }
        field(51; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(53; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidatePostCode(Rec, xRec);
            end;
        }
        field(54; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(55; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(56; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(57; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(58; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(59; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(60; "IC Partner Purch. G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner Purch. G/L Acc. No.';
            TableRelation = "IC G/L Account";
        }
        field(61; "Unit Group Exists"; Boolean)
        {
            CalcFormula = exist("Unit Group" where("Source Id" = field(SystemId),
                                                "Source Type" = const(Resource)));
            Caption = 'Unit Group Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if "Privacy Blocked" then
                    Blocked := true
                else
                    Blocked := false;
            end;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Resource)));
        }
        field(900; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = sum("Assembly Line"."Remaining Quantity (Base)" where("Document Type" = const(Order),
                                                                                 Type = const(Resource),
                                                                                 "No." = field("No."),
                                                                                 "Due Date" = field("Date Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(950; "Use Time Sheet"; Boolean)
        {
            Caption = 'Use Time Sheet';

            trigger OnValidate()
            begin
                if "Use Time Sheet" <> xRec."Use Time Sheet" then
                    if ExistUnprocessedTimeSheets() then
                        Error(Text005, FieldCaption("Use Time Sheet"));
            end;
        }
        field(951; "Time Sheet Owner User ID"; Code[50])
        {
            Caption = 'Time Sheet Owner User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                if "Time Sheet Owner User ID" <> xRec."Time Sheet Owner User ID" then
                    if ExistUnprocessedTimeSheets() then
                        Error(Text005, FieldCaption("Time Sheet Owner User ID"));
            end;
        }
        field(952; "Time Sheet Approver User ID"; Code[50])
        {
            Caption = 'Time Sheet Approver User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTimeSheetApproverUserID(Rec, IsHandled, xRec);
                if IsHandled then
                    exit;

                if "Time Sheet Approver User ID" <> xRec."Time Sheet Approver User ID" then
                    if ExistUnprocessedTimeSheets() then
                        Error(Text005, FieldCaption("Time Sheet Approver User ID"));
            end;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            TableRelation = "Deferral Template"."Deferral Code";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Gen. Prod. Posting Group")
        {
        }
        key(Key4; Name)
        {
        }
        key(Key5; Type)
        {
        }
        key(Key6; "Base Unit of Measure")
        {
        }
        key(Key7; "Resource Group No.")
        {
        }
        key(Key8; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, Type, "Base Unit of Measure")
        {
        }
        fieldgroup(Brick; "No.", Name, Type, "Base Unit of Measure", Image)
        {
        }
    }

    trigger OnDelete()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CheckJobPlanningLine();

        MoveEntries.MoveResEntries(Rec);

        ResCapacityEntry.SetCurrentKey("Resource No.");
        ResCapacityEntry.SetRange("Resource No.", "No.");
        ResCapacityEntry.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Resource);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Resource);
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        ResUnitMeasure.Reset();
        ResUnitMeasure.SetRange("Resource No.", "No.");
        ResUnitMeasure.DeleteAll();

        SalesOrderLine.SetCurrentKey(Type, "No.");
        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Resource);
        SalesOrderLine.SetRange("No.", "No.");
        if SalesOrderLine.FindFirst() then
            Error(DocumentExistsErr, "No.", SalesOrderLine."Document Type");

        PurchaseLine.SetRange(Type, PurchaseLine.Type::Resource);
        PurchaseLine.SetRange("No.", "No.");
        if PurchaseLine.FindFirst() then
            Error(DocumentExistsErr, "No.", PurchaseLine."Document Type");

        if ExistUnprocessedTimeSheets() then
            Error(Text006, TableCaption(), "No.");

        DimMgt.DeleteDefaultDim(DATABASE::Resource, "No.");

        DeleteResourceUnitGroup();
    end;

    trigger OnInsert()
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if "No." = '' then begin
            ResSetup.Get();
            ResSetup.TestField("Resource Nos.");
            "No. Series" := ResSetup."Resource Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
            Resource.ReadIsolation(IsolationLevel::ReadUncommitted);
            Resource.SetLoadFields("No.");
            while Resource.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        if GetFilter("Resource Group No.") <> '' then
            if GetRangeMin("Resource Group No.") = GetRangeMax("Resource Group No.") then
                Validate("Resource Group No.", GetRangeMin("Resource Group No."));

        DimMgt.UpdateDefaultDim(
          DATABASE::Resource, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        UpdateResourceUnitGroup();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        UpdateResourceUnitGroup();
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::Resource, xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::Resource, xRec."No.", "No.");
        PriceListLine.RenameNo(PriceListLine."Asset Type"::Resource, xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::Resource, xRec."No.", "No.");
        JobPlanningLine.RenameNo(JobPlanningLine.Type::Resource, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Resource, xRec."No.", "No.");
        "Last Date Modified" := Today;

        UpdateResourceUnitGroup();
    end;

    var
        ResSetup: Record "Resources Setup";
        Res: Record Resource;
        ResCapacityEntry: Record "Res. Capacity Entry";
        CommentLine: Record "Comment Line";
        SalesOrderLine: Record "Sales Line";
        ExtTextHeader: Record "Extended Text Header";
        PostCode: Record "Post Code";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        ResUnitMeasure: Record "Resource Unit of Measure";
        PlanningLine: Record "Job Planning Line";
        NoSeries: Codeunit "No. Series";
        MoveEntries: Codeunit MoveEntries;
        DimMgt: Codeunit DimensionManagement;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Do you want to change %1?';
        Text002: Label 'You cannot change %1 because there are ledger entries for this resource.';
        Text005: Label '%1 cannot be changed since unprocessed time sheet lines exist for this resource.';
        Text006: Label 'You cannot delete %1 %2 because unprocessed time sheet lines exist for this resource.', Comment = 'You cannot delete Resource LIFT since unprocessed time sheet lines exist for this resource.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
        CannotDeleteResourceErr: Label 'You cannot delete resource %1 because it is used in one or more project planning lines.', Comment = '%1 = Resource No.';
#pragma warning disable AA0470
        DocumentExistsErr: Label 'You cannot delete resource %1 because there are one or more outstanding %2 that include this resource.', Comment = '%1 = Resource No.';
#pragma warning restore AA0470
        PrivacyBlockedPostErr: Label 'You cannot post this line because resource %1 is blocked due to privacy.', Comment = '%1=resource no.';
        PrivacyBlockedErr: Label 'You cannot create this line because resource %1 is blocked due to privacy.', Comment = '%1=resource no.';
        ConfirmBlockedPrivacyBlockedQst: Label 'If you change the Blocked field, the Privacy Blocked field is changed to No. Do you want to continue?';
        CanNotChangeBlockedDueToPrivacyBlockedErr: Label 'The Blocked field cannot be changed because the user is blocked for privacy reasons.';

    procedure AssistEdit(OldRes: Record Resource) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldRes, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Res := Rec;
        ResSetup.Get();
        ResSetup.TestField("Resource Nos.");
        if NoSeries.LookupRelatedNoSeries(ResSetup."Resource Nos.", OldRes."No. Series", Res."No. Series") then begin
            Res."No." := NoSeries.GetNextNo(Res."No. Series");
            Rec := Res;
            exit(true);
        end;
    end;

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Resource;
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Resource, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Resource, GetPosition());
    end;

    procedure GetUnitOfMeasureFilter(No: Code[20]; UnitofMeasureCode: Code[10]) "Filter": Text
    var
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        ResourceUnitOfMeasure.Get(No, UnitofMeasureCode);
        if ResourceUnitOfMeasure."Related to Base Unit of Meas." then begin
            Clear(ResourceUnitOfMeasure);
            ResourceUnitOfMeasure.SetRange("Resource No.", No);
            ResourceUnitOfMeasure.SetRange("Related to Base Unit of Meas.", true);
            if ResourceUnitOfMeasure.FindSet() then begin
                repeat
                    Filter := Filter + GetQuotedCode(ResourceUnitOfMeasure.Code) + '|';
                until ResourceUnitOfMeasure.Next() = 0;
                Filter := DelStr(Filter, StrLen(Filter));
            end;
        end else
            Filter := GetQuotedCode(UnitofMeasureCode);
    end;

    local procedure ExistUnprocessedTimeSheets() Result: Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExistUnprocessedTimeSheets(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TimeSheetHeader.SetCurrentKey("Resource No.");
        TimeSheetHeader.SetRange("Resource No.", "No.");
        if TimeSheetHeader.FindSet() then
            repeat
                TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                TimeSheetLine.SetRange(Posted, false);
                if not TimeSheetLine.IsEmpty() then
                    exit(true);
            until TimeSheetHeader.Next() = 0;

        exit(false);
    end;

    procedure CreateTimeSheets()
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTimeSheets(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Use Time Sheet", true);
        Resource.Get("No.");
        Resource.SetRecFilter();
        REPORT.RunModal(REPORT::"Create Time Sheets", true, false, Resource);
    end;

    local procedure GetQuotedCode("Code": Text): Text
    begin
        exit(StrSubstNo('''%1''', Code));
    end;

    protected procedure TestNoEntriesExist(CurrentFieldName: Text[100])
    var
        ResLedgEntry: Record "Res. Ledger Entry";
    begin
        ResLedgEntry.SetRange("Resource No.", "No.");
        if not ResLedgEntry.IsEmpty() then
            Error(Text002, CurrentFieldName);
    end;

    local procedure CheckJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("No.", "No.");
        if not JobPlanningLine.IsEmpty() then
            Error(CannotDeleteResourceErr, "No.");
    end;

    procedure CheckResourcePrivacyBlocked(IsPosting: Boolean)
    begin
        if "Privacy Blocked" then begin
            if IsPosting then
                Error(PrivacyBlockedPostErr, "No.");
            Error(PrivacyBlockedErr, "No.");
        end;
    end;

    local procedure UpdateResourceUnitGroup()
    var
        UnitGroup: Record "Unit Group";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if CRMIntegrationManagement.IsIntegrationEnabled() then begin
            UnitGroup.SetRange("Source Id", Rec.SystemId);
            UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Resource);
            if UnitGroup.IsEmpty() then begin
                UnitGroup.Init();
                UnitGroup."Source Id" := Rec.SystemId;
                UnitGroup."Source No." := Rec."No.";
                UnitGroup."Source Type" := UnitGroup."Source Type"::Resource;
                UnitGroup.Insert();
            end;
        end
    end;

    local procedure DeleteResourceUnitGroup()
    var
        UnitGroup: Record "Unit Group";
    begin
        if UnitGroup.Get(UnitGroup."Source Type"::Resource, Rec.SystemId) then
            UnitGroup.Delete();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Resource: Record Resource; var xResource: Record Resource; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Resource: Record Resource; xOldRes: Record Resource; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Resource: Record Resource; var IsHandled: Boolean; var xResource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Resource: Record Resource; var xResource: Record Resource; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTimeSheetApproverUserID(var Resource: Record Resource; var IsHandled: Boolean; xResource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var Resource: Record Resource; xResource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBaseUnitOfMeasure(var Resource: Record Resource; xResource: Record Resource; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Resource: Record Resource; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Resource: Record Resource; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var Resource: Record Resource; xResource: Record Resource)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateResourceGroupNoOnBeforeConfirm(var Resource: Record "Resource"; xResource: Record "Resource"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTimeSheets(var Resource: Record "Resource"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExistUnprocessedTimeSheets(Resource: Record Resource; var Result: Boolean; var IsHandled: boolean);
    begin
    end;
}