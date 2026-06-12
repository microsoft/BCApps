// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Telemetry;

table 5600 "Fixed Asset"
{
    Caption = 'Fixed Asset';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Fixed Asset List";
    LookupPageID = "Fixed Asset List";
    Permissions = TableData "Ins. Coverage Ledger Entry" = r,
                  TableData Employee = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    FASetup.Get();
                    NoSeries.TestManual(FASetup."Fixed Asset Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the fixed asset.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
                if Description <> xRec.Description then begin
                    FADeprBook.SetCurrentKey("FA No.");
                    FADeprBook.SetRange("FA No.", "No.");
                    FADeprBook.ModifyAll(Description, Description);
                end;
            end;
        }
        field(3; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            ToolTip = 'Specifies a search description for the fixed asset.';
            OptimizeForTextSearch = true;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(5; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            ToolTip = 'Specifies the class that the fixed asset belongs to.';
            TableRelation = "FA Class";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateFAClassCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Subclass Code" = '' then
                    exit;

                FASubclass.Get("FA Subclass Code");
                if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                    "FA Subclass Code" := '';
            end;
        }
        field(6; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            ToolTip = 'Specifies the subclass of the class that the fixed asset belongs to.';
            TableRelation = "FA Subclass";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateFASubclassCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Subclass Code" = '' then begin
                    Validate("FA Posting Group", '');
                    exit;
                end;

                FASubclass.Get("FA Subclass Code");
                if "FA Class Code" <> '' then begin
                    if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                        Error(UnexpctedSubclassErr);
                end else
                    Validate("FA Class Code", FASubclass."FA Class Code");

                if "FA Posting Group" = '' then
                    Validate("FA Posting Group", FASubclass."Default FA Posting Group");
            end;
        }
        field(7; "Global Dimension 1 Code"; Code[20])
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
        field(8; "Global Dimension 2 Code"; Code[20])
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
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
            TableRelation = "FA Location";

            trigger OnValidate()
            begin
                if (Status > Status::Inventory) and (xRec."Location Code" <> '') then
                    TestNoEntriesExist(FieldCaption("Location Code"));

                if "FA Location Code" <> '' then begin
                    FALocation.Get("FA Location Code");
                    "OKATO Code" := FALocation."OKATO Code";
                    if "Assessed Tax Code" <> '' then
                        CheckRegionCode();
                end;

                UpdateFALocationId();
            end;
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the number of the vendor from which you purchased this fixed asset.';
            TableRelation = Vendor;
        }
        field(12; "Main Asset/Component"; Enum "FA Component Type")
        {
            Caption = 'Main Asset/Component';
            ToolTip = 'Specifies if the fixed asset is a main fixed asset or a component of a fixed asset.';
            Editable = false;
        }
        field(13; "Component of Main Asset"; Code[20])
        {
            Caption = 'Component of Main Asset';
            ToolTip = 'Specifies the number of the main fixed asset.';
            Editable = false;
            TableRelation = "Fixed Asset";
        }
        field(14; "Budgeted Asset"; Boolean)
        {
            Caption = 'Budgeted Asset';
            ToolTip = 'Specifies if the asset is for budgeting purposes.';

            trigger OnValidate()
            begin
                FAMoveEntries.ChangeBudget(Rec);
            end;
        }
        field(15; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            ToolTip = 'Specifies the warranty expiration date of the fixed asset.';
        }
        field(16; "Responsible Employee"; Code[20])
        {
            Caption = 'Responsible Employee';
            ToolTip = 'Specifies which employee is responsible for the fixed asset.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                UpdateResponsibleEmployeeId();
            end;
        }
        field(17; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the fixed asset''s serial number.';
            OptimizeForTextSearch = true;
        }
        field(18; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            ToolTip = 'Specifies when the fixed asset card was last modified.';
            Editable = false;
        }
        field(19; Insured; Boolean)
        {
            CalcFormula = exist("Ins. Coverage Ledger Entry" where("FA No." = field("No."),
                                                                    "Disposed FA" = const(false)));
            Caption = 'Insured';
            ToolTip = 'Specifies that the fixed asset is linked to an insurance policy.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("Fixed Asset"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        field(23; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            ToolTip = 'Specifies the number of the vendor who performs repairs and maintenance on the fixed asset.';
            TableRelation = Vendor;
        }
        field(24; "Under Maintenance"; Boolean)
        {
            Caption = 'Under Maintenance';
            ToolTip = 'Specifies if the fixed asset is currently being repaired.';
        }
        field(25; "Next Service Date"; Date)
        {
            Caption = 'Next Service Date';
            ToolTip = 'Specifies the next scheduled service date for the fixed asset. This is used as a filter in the Maintenance - Next Service report.';
        }
        field(26; Inactive; Boolean)
        {
            Caption = 'Inactive';
            ToolTip = 'Specifies that the fixed asset is inactive (for example, if the asset is not in service or is obsolete).';
        }
        field(27; "FA Posting Date Filter"; Date)
        {
            Caption = 'FA Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(29; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";

            trigger OnValidate()
            var
                FALedgerEntry: Record "FA Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFAPostingGroup(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Posting Group" <> xRec."FA Posting Group" then begin
                    FALedgerEntry.SetRange("FA No.", "No.");
                    if not FALedgerEntry.IsEmpty() then
                        Error(FoundFALedgerEntriesErr);
                end;
            end;
        }
        field(30; Acquired; Boolean)
        {
            CalcFormula = exist("FA Depreciation Book" where("FA No." = field("No."),
                                                              "Acquisition Date" = filter(<> 0D)));
            Caption = 'Acquired';
            ToolTip = 'Specifies if the fixed asset has been acquired.';
            FieldClass = FlowField;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ToolTip = 'Specifies the picture that has been inserted for the fixed asset.';
        }
        field(9001; "FA Location Id"; Guid)
        {
            Caption = 'FA Location Id';
            DataClassification = SystemMetadata;
            TableRelation = "FA Location".SystemId;

            trigger OnValidate()
            begin
                UpdateFALocationCode();
            end;
        }
        field(9002; "Responsible Employee Id"; Guid)
        {
            Caption = 'Responsible Employee Id';
            DataClassification = SystemMetadata;
            TableRelation = Employee.SystemId;


            trigger OnValidate()
            begin
                UpdateResponsibleEmployeeCode();
            end;
        }
        field(12400; "Inventory Number"; Text[30])
        {
            Caption = 'Inventory Number';
            OptimizeForTextSearch = true;
        }
        field(12401; "Depreciation Code"; Code[10])
        {
            Caption = 'Depreciation Code';
            TableRelation = "Depreciation Code";

            trigger OnValidate()
            var
                DepreciationCode: Record "Depreciation Code";
                FADeprBook: Record "FA Depreciation Book";
            begin
                if Confirm(Text12401, true) then
                    if DepreciationCode.Get("Depreciation Code") then begin
                        FADeprBook.SetRange(FADeprBook."FA No.", "No.");
                        if FADeprBook.Find('-') then
                            repeat
                                FADeprBook."Straight-Line %" := DepreciationCode."Depreciation Quota";
                                FADeprBook.Validate("No. of Depreciation Years", DepreciationCode."Service Life");
                                FADeprBook.Modify();
                            until FADeprBook.Next() = 0;
                    end;
            end;
        }
        field(12402; "FA Type"; Option)
        {
            Caption = 'FA Type';
            OptionCaption = 'Fixed Assets,Intangible Asset,Future Expense';
            OptionMembers = "Fixed Assets","Intangible Asset","Future Expense";

            trigger OnValidate()
            begin
                FASetup.Get();
                if "FA Type" = "FA Type"::"Future Expense" then begin
                    if FASetup."Default Depr. Book" <> '' then
                        DeleteFADeprBook("No.", FASetup."Default Depr. Book");
                    if FASetup."Release Depr. Book" <> '' then
                        DeleteFADeprBook("No.", FASetup."Release Depr. Book");
                    if FASetup."Disposal Depr. Book" <> '' then
                        DeleteFADeprBook("No.", FASetup."Disposal Depr. Book");
                    if FASetup."Future Depr. Book" <> '' then
                        InsertFADeprBook("No.", FASetup."Future Depr. Book", Enum::"FA Depreciation Method"::"Straight-Line", 0)
                    else
                        Message(Text12400);
                end else begin
                    if FASetup."Future Depr. Book" <> '' then
                        DeleteFADeprBook("No.", FASetup."Future Depr. Book");
                    if FASetup."Release Depr. Book" <> '' then
                        InsertFADeprBook("No.", FASetup."Release Depr. Book", Enum::"FA Depreciation Method"::"Straight-Line", 0);
                    if FASetup."Default Depr. Book" <> '' then
                        InsertFADeprBook("No.", FASetup."Default Depr. Book", Enum::"FA Depreciation Method"::"Straight-Line", 0);
                end;
            end;
        }
        field(12403; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            TableRelation = "Depreciation Group";

            trigger OnValidate()
            var
                DepreciationGroup: Record "Depreciation Group";
                FADeprBook: Record "FA Depreciation Book";
            begin
                if ("Depreciation Group" <> xRec."Depreciation Group") then begin
                    AmortizationCode.SetRange(Code, "Depreciation Code");
                    AmortizationCode.SetRange("Depreciation Group", "Depreciation Group");
                    if not AmortizationCode.FindFirst() then begin
                        if "Depreciation Code" <> '' then
                            Validate("Depreciation Code", '');
                    end else
                        Validate("Depreciation Code");

                    if TaxRegisterSetup.Get() then
                        if FADeprBook.Get("No.", TaxRegisterSetup."Tax Depreciation Book") then begin
                            if DepreciationGroup.Get("Depreciation Group") then;
                            if FADeprBook."Depr. Bonus %" <> DepreciationGroup."Depr. Bonus %" then begin
                                if not Confirm(
                                    Text12409,
                                    true,
                                    FADeprBook.FieldCaption("Depr. Bonus %"),
                                    FADeprBook."Depr. Bonus %",
                                    DepreciationGroup."Depr. Bonus %",
                                    FADeprBook.TableCaption(),
                                    FADeprBook.FieldCaption("FA No."),
                                    FADeprBook."FA No.",
                                    FADeprBook.FieldCaption("Depreciation Book Code"),
                                    FADeprBook."Depreciation Book Code")
                                then
                                    Error('');
                                FADeprBook.Validate("Depr. Bonus %", DepreciationGroup."Depr. Bonus %");
                                FADeprBook.Modify();
                            end;
                        end;

                    if "Depreciation Group" = '' then begin
                        FADeprBook.SetCurrentKey("FA No.");
                        FADeprBook.SetRange("FA No.", "No.");
                        if FADeprBook.FindSet() then
                            repeat
                                if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"DB/SL-RU Tax Group" then
                                    FADeprBook.FieldError("Depreciation Method");
                            until FADeprBook.Next() = 0;
                    end;
                end;
            end;
        }
        field(12404; "Belonging to Manufacturing"; Option)
        {
            Caption = 'Belonging to Manufacturing';
            OptionCaption = ' ,Production,Nonproduction';
            OptionMembers = " ",Production,Nonproduction;
        }
        field(12405; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(12406; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(12407; "FA Location Code Filter"; Code[20])
        {
            Caption = 'FA Location Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "FA Location";
            ValidateTableRelation = false;
        }
        field(12408; "Depreciation Book Code Filter"; Code[10])
        {
            Caption = 'Depreciation Book Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Depreciation Book";
        }
        field(12409; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Inventory,Montage,Operation,Maintenance,Repair,Disposed,WrittenOff';
            OptionMembers = Inventory,Montage,Operation,Maintenance,Repair,Disposed,WrittenOff;

            trigger OnValidate()
            begin
                if xRec.Status <> Rec.Status then
                    if not Confirm(Text12403, false, xRec.Status, Rec.Status) then
                        Status := xRec.Status;
            end;
        }
        field(12410; "Factory No."; Text[30])
        {
            Caption = 'Factory No.';
            OptimizeForTextSearch = true;
        }
        field(12411; "Initial Release Date"; Date)
        {
            Caption = 'Initial Release Date';
            Editable = false;
        }
        field(12412; "Status Document No."; Code[20])
        {
            Caption = 'Status Document No.';
            OptimizeForTextSearch = true;
            Editable = false;
        }
        field(12413; "Passport No."; Text[30])
        {
            Caption = 'Passport No.';
            OptimizeForTextSearch = true;
        }
        field(12414; "Status Date"; Date)
        {
            Caption = 'Status Date';
        }
        field(12415; "Manufacturing Year"; Text[4])
        {
            Caption = 'Manufacturing Year';
            OptimizeForTextSearch = true;
        }
        field(12417; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(12418; "Unrealized VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Entry"."Remaining Unrealized Amount" where("Object Type" = const("Fixed Asset"),
                                                                               "Object No." = field("No."),
                                                                               Type = const(Purchase)));
            Caption = 'Unrealized VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12425; "G/L Account No. Filter"; Code[20])
        {
            Caption = 'G/L Account No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Account";
        }
        field(12426; "G/L Starting Date Filter"; Date)
        {
            Caption = 'G/L Starting Date Filter';
            FieldClass = FlowFilter;
        }
        field(12427; "G/L Starting Balance"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const("Fixed Asset"),
                                                        "Source No." = field("No."),
                                                        "G/L Account No." = field("G/L Account No. Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                        "Posting Date" = field(upperlimit("G/L Starting Date Filter"))));
            Caption = 'G/L Starting Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12428; "G/L Net Change"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const("Fixed Asset"),
                                                        "Source No." = field("No."),
                                                        "G/L Account No." = field("G/L Account No. Filter"),
                                                        "Posting Date" = field("Date Filter"),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'G/L Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12429; "G/L Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry"."Debit Amount" where("Source Type" = const("Fixed Asset"),
                                                                "Source No." = field("No."),
                                                                "G/L Account No." = field("G/L Account No. Filter"),
                                                                "Posting Date" = field("Date Filter"),
                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'G/L Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12430; "G/L Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry"."Credit Amount" where("Source Type" = const("Fixed Asset"),
                                                                 "Source No." = field("No."),
                                                                 "G/L Account No." = field("G/L Account No. Filter"),
                                                                 "Posting Date" = field("Date Filter"),
                                                                 "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                 "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'G/L Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12431; "G/L Balance to Date"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("G/L Entry".Amount where("Source Type" = const("Fixed Asset"),
                                                        "Source No." = field("No."),
                                                        "G/L Account No." = field("G/L Account No. Filter"),
                                                        "Posting Date" = field(upperlimit("Date Filter")),
                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'G/L Balance to Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12450; "Vehicle Identification Number"; Code[30])
        {
            Caption = 'Vehicle Identification Number';
        }
        field(12451; "Vehicle Model"; Text[30])
        {
            Caption = 'Vehicle Model';
            OptimizeForTextSearch = true;
        }
        field(12452; "Vehicle Type"; Text[50])
        {
            Caption = 'Vehicle Type';
            OptimizeForTextSearch = true;
        }
        field(12453; "Vehicle Reg. No."; Code[20])
        {
            Caption = 'Vehicle Reg. No.';
        }
        field(12454; "Vehicle Capacity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Vehicle Capacity';
        }
        field(12455; "Vehicle Engine No."; Code[20])
        {
            Caption = 'Vehicle Engine No.';
        }
        field(12456; "Vehicle Chassis No."; Code[20])
        {
            Caption = 'Vehicle Chassis No.';
        }
        field(12457; "Vehicle Passport Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Vehicle Passport Weight';
        }
        field(12458; "Run after Release Date"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Run after Release Date';
        }
        field(12459; "Run after Renovation Date"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Run after Renovation Date';
        }
        field(12460; "Vehicle Writeoff Date"; Date)
        {
            Caption = 'Vehicle Writeoff Date';
            Editable = false;
        }
        field(12461; "Vehicle Class"; Option)
        {
            Caption = 'Vehicle Class';
            OptionCaption = ' ,Automobile,Trailer,Semitrailer';
            OptionMembers = " ",Automobile,Trailer,Semitrailer;
        }
        field(12462; "Is Vehicle"; Boolean)
        {
            Caption = 'Is Vehicle';
        }
        field(12463; "Last Renovation Date"; Date)
        {
            Caption = 'Last Renovation Date';
        }
        field(12470; Manufacturer; Text[30])
        {
            Caption = 'Manufacturer';
            OptimizeForTextSearch = true;
        }
        field(12493; "Undepreciable FA"; Boolean)
        {
            Caption = 'Undepreciable FA';

            trigger OnValidate()
            begin
                if Status > Status::Inventory then
                    TestNoEntriesExist(FieldCaption("Undepreciable FA"));
            end;
        }
        field(12495; "Operation Life (Months)"; Integer)
        {
            Caption = 'Operation Life (Months)';
            MinValue = 0;
        }
        field(12496; "Accrued Depr. Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Accrued Depr. Amount';
            MinValue = 0;
        }
        field(14921; "Assessed Tax Code"; Code[20])
        {
            Caption = 'Assessed Tax Code';
            TableRelation = "Assessed Tax Code";

            trigger OnValidate()
            begin
                if "Assessed Tax Code" <> '' then begin
                    if "FA Location Code" = '' then
                        Message(Text12404, "No.");
                    if "OKATO Code" = '' then
                        Message(Text12405, "No.");
                    CheckATCode();
                    CheckBaseCode();
                    CheckATCodeDuplicate();
                    if ("FA Location Code" <> '') and ("OKATO Code" <> '') then
                        CheckRegionCode();
                end;
                Modify();
            end;
        }
        field(14922; "FA Type for Taxation"; Option)
        {
            Caption = 'FA Type for Taxation';
            OptionCaption = ' ,Movable,Immovable,Untaxable';
            OptionMembers = " ",Movable,Immovable,Untaxable;
        }
        field(14923; "Distributed Asset"; Boolean)
        {
            Caption = 'Distributed Asset';
        }
        field(14924; "UGSS Asset"; Boolean)
        {
            Caption = 'UGSS Asset';
        }
        field(14925; "OKATO Code"; Code[11])
        {
            Caption = 'OKATO Code';
            TableRelation = OKATO;
        }
        field(14926; "Book Value per Share"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Book Value per Share';
            DecimalPlaces = 2 : 2;
            MaxValue = 1;
            MinValue = 0;
        }
        field(14927; "Property Type"; Option)
        {
            Caption = 'Property Type';
            OptionCaption = ' ,Immovable UGSS Property,Immovable Distributed Property,Other Property,,Special Economic Zone Property';
            OptionMembers = " ","Immovable UGSS Property","Immovable Distributed Property","Other Property",,"Special Economic Zone Property";
        }
        field(14928; "Tax Amount Paid Abroad"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tax Amount Paid Abroad';
        }
        field(17301; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            TableRelation = "Tax Difference" where("Depreciation Bonus" = const(false),
                                                    "Source Code Mandatory" = const(true));
        }
        field(17302; "Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("Tax Diff. Ledger Entry"."Tax Amount" where("Tax Diff. Code" = field("Tax Difference Code"),
                                                                           "Source Type" = const("Future Expense"),
                                                                           "Source No." = field("No."),
                                                                           "Posting Date" = field("FA Posting Date Filter")));
            Caption = 'Tax Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17303; "Created by FA No."; Code[20])
        {
            Caption = 'Created by FA No.';
            Editable = false;
            TableRelation = "Fixed Asset"."No.";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "FA Class Code")
        {
        }
        key(Key4; "FA Subclass Code")
        {
        }
        key(Key5; "Component of Main Asset", "Main Asset/Component")
        {
        }
        key(Key6; "FA Location Code")
        {
        }
        key(Key7; "Global Dimension 1 Code")
        {
        }
        key(Key8; "Global Dimension 2 Code")
        {
        }
        key(Key9; "FA Posting Group")
        {
        }
        key(Key10; Description)
        {
        }
        key(Key11; "FA Type")
        {
        }
        key(Key12; "Created by FA No.")
        {
        }
        key(Key13; "Depreciation Group")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "FA Class Code")
        {
        }
        fieldgroup(Brick; "No.", Description, "FA Class Code", Image)
        {
        }
    }

    trigger OnDelete()
    var
        FADeprBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        MainAssetComp.LockTable();
        InsCoverageLedgEntry.LockTable();
        if "Main Asset/Component" = "Main Asset/Component"::"Main Asset" then
            Error(Text000);
        FAMoveEntries.MoveFAInsuranceEntries("No.");
        FADeprBook.SetRange("FA No.", "No.");
        FADeprBook.DeleteAll(true);
        if not FADeprBook.IsEmpty() then
            Error(Text001, TableCaption(), "No.");

        MainAssetComp.SetCurrentKey("FA No.");
        MainAssetComp.SetRange("FA No.", "No.");
        MainAssetComp.DeleteAll();
        if "Main Asset/Component" = "Main Asset/Component"::Component then begin
            MainAssetComp.Reset();
            MainAssetComp.SetRange("Main Asset No.", "Component of Main Asset");
            MainAssetComp.SetRange("FA No.", '');
            MainAssetComp.DeleteAll();
            MainAssetComp.SetRange("FA No.");
            if not MainAssetComp.FindFirst() then begin
                FA.Get("Component of Main Asset");
                FA."Main Asset/Component" := FA."Main Asset/Component"::" ";
                FA."Component of Main Asset" := '';
                FA.Modify();
            end;
        end;

        MaintenanceRegistration.SetRange("FA No.", "No.");
        MaintenanceRegistration.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Fixed Asset");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"Fixed Asset", "No.");
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000H4G', 'Fixed Asset', Enum::"Feature Uptake Status"::"Set up");
        InitFANo();

        "Main Asset/Component" := "Main Asset/Component"::" ";
        "Component of Main Asset" := '';

        DimMgt.UpdateDefaultDim(
          DATABASE::"Fixed Asset", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        InitFADeprBooks("No.");

        UpdateFALocationId();
        UpdateResponsibleEmployeeId();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"Fixed Asset", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"Fixed Asset", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"Fixed Asset", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Fixed Asset", xRec."No.", "No.");

        "Last Date Modified" := Today;
    end;

    var
        CommentLine: Record "Comment Line";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        MaintenanceRegistration: Record "Maintenance Registration";
        MainAssetComp: Record "Main Asset Component";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        AmortizationCode: Record "Depreciation Code";
        FALocation: Record "FA Location";
        FALedgEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
        AssessedTaxCode: Record "Assessed Tax Code";
        OKATO: Record OKATO;
        FAMoveEntries: Codeunit "FA MoveEntries";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;

#pragma warning disable AA0074
        Text000: Label 'A main asset cannot be deleted.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete %1 %2 because it has associated depreciation books.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12401: Label 'Change service life?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12400: Label 'Future Depr. Book does not exist';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12402: Label 'The field %1 cannot be changed for a fixed asset with ledger entries.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12403: Label 'FA Status will be changed from %1 to %2. Continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12404: Label 'FA Location Code is empty in FA No.=%1. Assessed tax would not be calculated properly.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12405: Label 'OKATO Code is empty in FA No.=%1. Assessed tax would not be calculated properly.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12406: Label 'Region Code should be the same both in OKATO Code=%1 and in Assessed Tax Code=%2 for Fixed Asset=%3. \Assessed Tax would not be calculated properly.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12407: Label 'There are duplicate Assessed Tax Codes: Assessed Tax Code=%1 and Assessed Tax Code=%2. Remove one of them.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12408: Label 'Base Assessed Tax Code should exist for Assessed Tax Code=%1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12409: Label '%1 will be changed from %2 to %3 for %4 %5=%6, %7=%8. Continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UnexpctedSubclassErr: Label 'This fixed asset subclass belongs to a different fixed asset class.';
        DontAskAgainActionTxt: Label 'Don''t ask again';
        NotificationNameTxt: Label 'Fixed Asset Acquisition Wizard';
        NotificationDescriptionTxt: Label 'Notify when ready to acquire the fixed asset.';
        ReadyToAcquireMsg: Label 'You are ready to acquire the fixed asset.';
        AcquireActionTxt: Label 'Acquire';
        FoundFALedgerEntriesErr: Label 'You cannot change the FA posting group because posted FA ledger entries use the existing posting group.';

    procedure AssistEdit(OldFA: Record "Fixed Asset") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(FASetup, FA, Rec, Result, IsHandled, OldFA);
        if IsHandled then
            exit(Result);

        FA := Rec;
        FASetup.Get();
        FASetup.TestField("Fixed Asset Nos.");
        if NoSeries.LookupRelatedNoSeries(FASetup."Fixed Asset Nos.", OldFA."No. Series", FA."No. Series") then begin
            FA."No." := NoSeries.GetNextNo(FA."No. Series");
            Rec := FA;
            exit(true);
        end;
    end;

    local procedure InitFANo()
    var
        FixedAsset: Record "Fixed Asset";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFANo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            FASetup.Get();
            FASetup.TestField("Fixed Asset Nos.");
            if NoSeries.AreRelated(FASetup."Fixed Asset Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := FASetup."Fixed Asset Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            FixedAsset.ReadIsolation(IsolationLevel::ReadUncommitted);
            FixedAsset.SetLoadFields("No.");
            while FixedAsset.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if not IsHandled then begin
            DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
            if not IsTemporary then begin
                DimMgt.SaveDefaultDim(DATABASE::"Fixed Asset", "No.", FieldNumber, ShortcutDimCode);
                Modify(true);
            end;
        end;
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure TestNoEntriesExist(CurrentFieldName: Text[100])
    begin
        FALedgEntry.SetCurrentKey("FA No.");
        FALedgEntry.SetRange("FA No.", "No.");
        if FALedgEntry.Find('-') then
            Error(
              Text12402,
              CurrentFieldName);
    end;

    [Scope('OnPrem')]
    procedure CheckATCode()
    begin
        AssessedTaxCode.Get("Assessed Tax Code");
        AssessedTaxCode.TestField("Region Code");
        AssessedTaxCode.TestField("Rate %");
    end;

    [Scope('OnPrem')]
    procedure CheckRegionCode()
    begin
        AssessedTaxCode.Get("Assessed Tax Code");
        OKATO.Get("OKATO Code");
        if AssessedTaxCode."Region Code" <> OKATO."Region Code" then
            Message(Text12406, OKATO.Code, AssessedTaxCode.Code, "No.");
    end;

    [Scope('OnPrem')]
    procedure CheckATCodeDuplicate()
    var
        AssessedTaxCodeDubl: Record "Assessed Tax Code";
    begin
        AssessedTaxCode.Get("Assessed Tax Code");
        AssessedTaxCodeDubl.Reset();
        AssessedTaxCodeDubl.SetRange("Region Code", AssessedTaxCode."Region Code");
        AssessedTaxCodeDubl.SetRange("Rate %", AssessedTaxCode."Rate %");
        AssessedTaxCodeDubl.SetRange("Dec. Rate Tax Allowance Code", AssessedTaxCode."Dec. Rate Tax Allowance Code");
        AssessedTaxCodeDubl.SetFilter(Code, '<>%1', AssessedTaxCode.Code);
        if AssessedTaxCode."Exemption Tax Allowance Code" = '' then
            AssessedTaxCodeDubl.SetRange("Exemption Tax Allowance Code", '')
        else begin
            AssessedTaxCodeDubl.SetRange("Dec. Amount Tax Allowance Code", AssessedTaxCode."Dec. Amount Tax Allowance Code");
            AssessedTaxCodeDubl.SetRange("Exemption Tax Allowance Code", AssessedTaxCode."Exemption Tax Allowance Code");
        end;

        if AssessedTaxCodeDubl.Find('-') then
            Error(Text12407, AssessedTaxCode.Code, AssessedTaxCodeDubl.Code);
    end;

    [Scope('OnPrem')]
    procedure CheckBaseCode()
    var
        AssessedTaxCodeBase: Record "Assessed Tax Code";
    begin
        AssessedTaxCode.Get("Assessed Tax Code");
        if AssessedTaxCode."Exemption Tax Allowance Code" <> '' then begin
            AssessedTaxCodeBase.Reset();
            AssessedTaxCodeBase.SetRange("Region Code", AssessedTaxCode."Region Code");
            AssessedTaxCodeBase.SetRange("Rate %", AssessedTaxCode."Rate %");
            AssessedTaxCodeBase.SetRange("Dec. Rate Tax Allowance Code", AssessedTaxCode."Dec. Rate Tax Allowance Code");
            AssessedTaxCodeBase.SetRange("Dec. Amount Tax Allowance Code", AssessedTaxCode."Dec. Amount Tax Allowance Code");
            AssessedTaxCodeBase.SetRange("Exemption Tax Allowance Code", '');
            if not AssessedTaxCodeBase.Find('-') then
                Error(Text12408, AssessedTaxCode.Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure InitFADeprBooks("No.": Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FADeprBook: Record "FA Depreciation Book";
    begin
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Enable Russian Accounting" then
            exit;

        FASetup.Get();
        if TaxRegisterSetup.Get() then;
        if "FA Type" = "FA Type"::"Future Expense" then begin
            if FASetup."Future Depr. Book" <> '' then
                InsertFADeprBook("No.", FASetup."Future Depr. Book", Enum::"FA Depreciation Method"::"Straight-Line", 0);
            if TaxRegisterSetup."Future Exp. Depreciation Book" <> '' then
                InsertFADeprBook("No.", TaxRegisterSetup."Future Exp. Depreciation Book", Enum::"FA Depreciation Method"::"Straight-Line", 0);
        end else begin
            if FASetup."Release Depr. Book" <> '' then
                InsertFADeprBook("No.", FASetup."Release Depr. Book", FADeprBook."Depreciation Method"::"SL-RU", 0);
            if FASetup."Default Depr. Book" <> '' then
                InsertFADeprBook("No.", FASetup."Default Depr. Book", Enum::"FA Depreciation Method"::"Straight-Line", 0);
            if TaxRegisterSetup."Tax Depreciation Book" <> '' then
                InsertFADeprBook("No.", TaxRegisterSetup."Tax Depreciation Book",
                  FADeprBook."Depreciation Method"::"SL-RU", TaxRegisterSetup."Default Depr. Bonus %");
        end;
    end;

    local procedure InsertFADeprBook(FANo: Code[20]; DeprBookCode: Code[10]; DepreciationMethod: Enum "FA Depreciation Method"; DeprBonus: Decimal)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Init();
        FADeprBook."FA No." := FANo;
        FADeprBook."Depreciation Book Code" := DeprBookCode;
        FADeprBook.Description := FADeprBook.Description;
        FADeprBook."Depr. Bonus %" := DeprBonus;
        FADeprBook."Depreciation Method" := DepreciationMethod;
        if FADeprBook.Insert() then;
    end;

    local procedure DeleteFADeprBook(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        if FADeprBook.Get(FANo, DeprBookCode) then
            FADeprBook.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure ShowTaxDifferences()
    var
        TaxDifference: Record "Tax Difference";
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
        TaxDiffFABuffer: Record "Tax Diff. FA Buffer" temporary;
        FATaxDifferences: Page "FA Tax Differences Detailed";
    begin
        TaxDiffLedgerEntry.SetRange("Source Type", GetTDESourceType());
        TaxDiffLedgerEntry.SetRange("Source No.", "No.");
        if TaxDiffLedgerEntry.FindSet() then
            repeat
                if not TaxDiffFABuffer.Get("No.", TaxDiffLedgerEntry."Tax Diff. Code") then begin
                    TaxDifference.Get(TaxDiffLedgerEntry."Tax Diff. Code");
                    TaxDiffFABuffer."FA No." := "No.";
                    TaxDiffFABuffer."Tax Difference Code" := TaxDiffLedgerEntry."Tax Diff. Code";
                    TaxDiffFABuffer.Description := TaxDifference.Description;
                    TaxDiffFABuffer."Amount (Base)" := TaxDiffLedgerEntry."Amount (Base)";
                    TaxDiffFABuffer."Amount (Tax)" := TaxDiffLedgerEntry."Amount (Tax)";
                    TaxDiffFABuffer.Difference := TaxDiffLedgerEntry.Difference;
                    TaxDiffFABuffer."Tax Amount" := TaxDiffLedgerEntry."Tax Amount";
                    TaxDiffFABuffer."FA Type" := "FA Type";
                    TaxDiffFABuffer.Insert();
                end else begin
                    TaxDiffFABuffer."Amount (Base)" += TaxDiffLedgerEntry."Amount (Base)";
                    TaxDiffFABuffer."Amount (Tax)" += TaxDiffLedgerEntry."Amount (Tax)";
                    TaxDiffFABuffer.Difference += TaxDiffLedgerEntry.Difference;
                    TaxDiffFABuffer."Tax Amount" += TaxDiffLedgerEntry."Tax Amount";
                    TaxDiffFABuffer.Modify();
                end;
            until TaxDiffLedgerEntry.Next() = 0;

        TaxDiffFABuffer.SetRange("FA No.", "No.");
        FATaxDifferences.SetTableView(TaxDiffFABuffer);
        FATaxDifferences.FillBuffer(TaxDiffFABuffer);
        FATaxDifferences.RunModal();
    end;

    [Scope('OnPrem')]
    procedure GetTDESourceType(): Integer
    var
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
    begin
        case "FA Type" of
            "FA Type"::"Fixed Assets":
                exit(TaxDiffLedgerEntry."Source Type"::"Fixed Asset");
            "FA Type"::"Intangible Asset":
                exit(TaxDiffLedgerEntry."Source Type"::"Intangible Asset");
            "FA Type"::"Future Expense":
                exit(TaxDiffLedgerEntry."Source Type"::"Future Expense");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDefDeprBook(): Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        if "FA Type" = "FA Type"::"Future Expense" then begin
            FASetup.TestField("Future Depr. Book");
            exit(FASetup."Future Depr. Book");
        end;
        if FASetup."Default Depr. Book" <> '' then
            exit(FASetup."Default Depr. Book")
        else
            exit('');
    end;

    procedure FieldsForAcquitionInGeneralGroupAreCompleted(): Boolean
    begin
        exit(("No." <> '') and (Description <> '') and ("FA Subclass Code" <> ''));
    end;

    procedure ShowAcquireWizardNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        FAAcquireWizardNotification: Notification;
    begin
        if IsNotificationEnabledForCurrentUser() then begin
            FAAcquireWizardNotification.Id(GetNotificationID());
            FAAcquireWizardNotification.Message(ReadyToAcquireMsg);
            FAAcquireWizardNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            FAAcquireWizardNotification.AddAction(
              AcquireActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'RunAcquisitionWizardFromNotification');
            FAAcquireWizardNotification.AddAction(
              DontAskAgainActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'HideNotificationForCurrentUser');
            FAAcquireWizardNotification.SetData(FixedAssetAcquisitionWizard.GetNotificationFANoDataItemID(), "No.");
            NotificationLifecycleMgt.SendNotification(FAAcquireWizardNotification, RecordId);
        end
    end;

    local procedure UpdateFALocationId()
    var
        FALocation: Record "FA Location";
    begin
        if "FA Location Code" = '' then begin
            Clear("FA Location Id");
            exit;
        end;

        if not FALocation.Get("FA Location Code") then
            exit;

        "FA Location Id" := FALocation.SystemId;
    end;

    local procedure UpdateFALocationCode()
    var
        FALocation: Record "FA Location";
    begin
        if not IsNullGuid("FA Location Id") then
            FALocation.GetBySystemId("FA Location Id");

        "FA Location Code" := FALocation.Code;
    end;

    local procedure UpdateResponsibleEmployeeId()
    var
        Employee: Record Employee;
    begin
        if "Responsible Employee" = '' then begin
            Clear("Responsible Employee Id");
            exit;
        end;

        if not Employee.Get("Responsible Employee") then
            exit;

        "Responsible Employee Id" := Employee.SystemId;
    end;

    local procedure UpdateResponsibleEmployeeCode()
    var
        Employee: Record Employee;
    begin
        if not IsNullGuid("Responsible Employee Id") then
            Employee.GetBySystemId("Responsible Employee Id");

        "Responsible Employee" := Employee."No.";
    end;

    procedure GetNotificationID(): Guid
    begin
        exit('3d5c2f86-cfb9-4407-97c3-9df74c7696c9');
    end;

    procedure SetNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetNotificationID(), NotificationNameTxt, NotificationDescriptionTxt, true);
    end;

    local procedure IsNotificationEnabledForCurrentUser(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationID()));
    end;

    procedure DontNotifyCurrentUserAgain()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationID()) then
            MyNotifications.InsertDefault(GetNotificationID(), NotificationNameTxt, NotificationDescriptionTxt, false);
    end;

    procedure RecallNotificationForCurrentUser()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordId, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var FASetup: Record "FA Setup"; var FixedAsset: Record "Fixed Asset"; var Rec: Record "Fixed Asset"; var Result: Boolean; var IsHandled: Boolean; OldFixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFANo(var FixedAsset: Record "Fixed Asset"; xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var FixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateFASubclassCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateFAClassCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFAPostingGroup(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;
}