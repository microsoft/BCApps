// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Assembly.Document;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Email;

table 14 Location
{
    Caption = 'Location';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Location List";
    LookupPageID = "Location List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(130; "Default Bin Code"; Code[20])
        {
            Caption = 'Default Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));
        }
        field(5700; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5701; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(5702; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(5703; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
                OnAfterLookupCity(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidateCity(Rec, PostCode);
            end;
        }
        field(5704; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5705; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ExtendedDatatype = PhoneNo;
        }
        field(5706; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(5707; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(5713; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(5714; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
                OnAfterLookupPostCode(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidatePostCode(Rec, PostCode);
            end;
        }
        field(5715; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(5718; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(5719; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(5720; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(5724; "Use As In-Transit"; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Use As In-Transit';

            trigger OnValidate()
            begin
                if "Use As In-Transit" then begin
                    TestField("Require Put-away", false);
                    TestField("Require Pick", false);
                    TestField("Use Cross-Docking", false);
                    TestField("Require Receive", false);
                    TestField("Require Shipment", false);
                    TestField("Bin Mandatory", false);
                    TestField("Job Consump. Whse. Handling", "Job Consump. Whse. Handling"::"No Warehouse Handling");
                    TestField("Asm. Consump. Whse. Handling", "Asm. Consump. Whse. Handling"::"No Warehouse Handling");
                end;
            end;
        }
        field(5726; "Require Put-away"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Require Put-away';

            trigger OnValidate()
            var
                WhseActivHeader: Record "Warehouse Activity Header";
                WhseRcptHeader: Record "Warehouse Receipt Header";
            begin
                WhseRcptHeader.SetRange("Location Code", Code);
                if not WhseRcptHeader.IsEmpty() then
                    Error(Text008, FieldCaption("Require Put-away"), xRec."Require Put-away", WhseRcptHeader.TableCaption());

                if not "Require Put-away" then begin
                    TestField("Directed Put-away and Pick", false);
                    WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
                    WhseActivHeader.SetRange("Location Code", Code);
                    if not WhseActivHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Put-away"), true, WhseActivHeader.TableCaption());
                    "Use Cross-Docking" := false;
                    "Cross-Dock Bin Code" := '';
                end else
                    CreateInboundWhseRequest();
            end;
        }
        field(5727; "Require Pick"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Require Pick';

            trigger OnValidate()
            var
                WhseActivHeader: Record "Warehouse Activity Header";
                WhseShptHeader: Record "Warehouse Shipment Header";
            begin
                WhseShptHeader.SetRange("Location Code", Code);
                if not WhseShptHeader.IsEmpty() then
                    Error(Text008, FieldCaption("Require Pick"), xRec."Require Pick", WhseShptHeader.TableCaption());

                if not "Require Pick" then begin
                    TestField("Directed Put-away and Pick", false);
                    WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
                    WhseActivHeader.SetRange("Location Code", Code);
                    if not WhseActivHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Pick"), true, WhseActivHeader.TableCaption());
                    "Use Cross-Docking" := false;
                    "Cross-Dock Bin Code" := '';
                end;
                if not Rec.PickAccordingToFEFO() then
                    Rec."Pick According to FEFO" := false;
            end;
        }
        field(5728; "Cross-Dock Due Date Calc."; DateFormula)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Cross-Dock Due Date Calc.';
        }
        field(5729; "Use Cross-Docking"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Use Cross-Docking';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUseCrossDocking(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Use Cross-Docking" then begin
                    TestField("Require Receive");
                    TestField("Require Shipment");
                    TestField("Require Put-away");
                    TestField("Require Pick");
                end else
                    "Cross-Dock Bin Code" := '';
            end;
        }
        field(5730; "Require Receive"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Receipt Header" = R;
            Caption = 'Require Receive';

            trigger OnValidate()
            var
                WhseRcptHeader: Record "Warehouse Receipt Header";
                WhseActivHeader: Record "Warehouse Activity Header";
            begin
                if not "Require Receive" then begin
                    TestField("Directed Put-away and Pick", false);
                    WhseRcptHeader.SetRange("Location Code", Code);
                    if not WhseRcptHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Receive"), true, WhseRcptHeader.TableCaption());
                    "Receipt Bin Code" := '';
                    "Use Cross-Docking" := false;
                    "Cross-Dock Bin Code" := '';
                end else begin
                    WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
                    WhseActivHeader.SetRange("Location Code", Code);
                    WhseActivHeader.SetFilter("Source Document", '<>%1&<>%2&<>%3&<>%4', WhseActivHeader."Source Document"::"Prod. Consumption", WhseActivHeader."Source Document"::"Prod. Output", WhseActivHeader."Source Document"::"Assembly Consumption", WhseActivHeader."Source Document"::"Job Usage");
                    if not WhseActivHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Receive"), false, WhseActivHeader.TableCaption());

                    CreateInboundWhseRequest();
                end;
            end;
        }
        field(5731; "Require Shipment"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Require Shipment';

            trigger OnValidate()
            var
                WhseShptHeader: Record "Warehouse Shipment Header";
                WhseActivHeader: Record "Warehouse Activity Header";
            begin
                if not "Require Shipment" then begin
                    TestField("Directed Put-away and Pick", false);
                    WhseShptHeader.SetRange("Location Code", Code);
                    if not WhseShptHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Shipment"), true, WhseShptHeader.TableCaption());
                    "Shipment Bin Code" := '';
                    "Use Cross-Docking" := false;
                    "Cross-Dock Bin Code" := '';
                end else begin
                    WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
                    WhseActivHeader.SetRange("Location Code", Code);
                    WhseActivHeader.SetFilter("Source Document", '<>%1&<>%2&<>%3&<>%4', WhseActivHeader."Source Document"::"Prod. Consumption", WhseActivHeader."Source Document"::"Prod. Output", WhseActivHeader."Source Document"::"Assembly Consumption", WhseActivHeader."Source Document"::"Job Usage");
                    if not WhseActivHeader.IsEmpty() then
                        Error(Text008, FieldCaption("Require Shipment"), false, WhseActivHeader.TableCaption());
                end;
            end;
        }
        field(5732; "Bin Mandatory"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Mandatory';

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                WhseEntry: Record "Warehouse Entry";
                WhseActivHeader: Record "Warehouse Activity Header";
                WhseShptHeader: Record "Warehouse Shipment Header";
                WhseRcptHeader: Record "Warehouse Receipt Header";
                Window: Dialog;
            begin
                if "Bin Mandatory" and not xRec."Bin Mandatory" then begin
                    Window.Open(Text010);
                    OnValidateBinMandatoryOnBeforeItemLedgEntrySetFilters(Rec);
                    ItemLedgEntry.SetRange(Open, true);
                    ItemLedgEntry.SetRange("Location Code", Code);
                    if not ItemLedgEntry.IsEmpty() then
                        Error(Text009, FieldCaption("Bin Mandatory"));

                    "Default Bin Selection" := "Default Bin Selection"::"Fixed Bin";
                    "Pick Bin Policy" := "Pick Bin Policy"::"Default Bin";
                    "Put-away Bin Policy" := "Put-away Bin Policy"::"Default Bin";
                    OnValidateBinMandatoryOnAfterItemLedgEntrySetFilters(Rec);
                    Window.Close();
                end;

                WhseActivHeader.SetRange("Location Code", Code);
                if not WhseActivHeader.IsEmpty() then
                    Error(Text008, FieldCaption("Bin Mandatory"), xRec."Bin Mandatory", WhseActivHeader.TableCaption());

                WhseRcptHeader.SetRange("Location Code", Code);
                if not WhseRcptHeader.IsEmpty() then
                    Error(Text008, FieldCaption("Bin Mandatory"), xRec."Bin Mandatory", WhseRcptHeader.TableCaption());

                WhseShptHeader.SetRange("Location Code", Code);
                if not WhseShptHeader.IsEmpty() then
                    Error(Text008, FieldCaption("Bin Mandatory"), xRec."Bin Mandatory", WhseShptHeader.TableCaption());

                if not "Bin Mandatory" and xRec."Bin Mandatory" then begin
                    WhseEntry.SetRange("Location Code", Code);
                    OnValidateBinMandatoryOnAfterWhseEntrySetFilters(Rec, WhseEntry);
                    WhseEntry.CalcSums("Qty. (Base)");
                    if WhseEntry."Qty. (Base)" <> 0 then
                        Error(Text002, FieldCaption("Bin Mandatory"));
                end;

                if not Rec.PickAccordingToFEFO() then
                    Rec."Pick According to FEFO" := false;

                if not "Bin Mandatory" then begin
                    "Open Shop Floor Bin Code" := '';
                    "To-Production Bin Code" := '';
                    "From-Production Bin Code" := '';
                    "Adjustment Bin Code" := '';
                    "Receipt Bin Code" := '';
                    "Shipment Bin Code" := '';
                    "Cross-Dock Bin Code" := '';
                    "To-Assembly Bin Code" := '';
                    "From-Assembly Bin Code" := '';
                    Rec."To-Job Bin Code" := '';
                    Rec."Check Whse. Class" := false;
                    OnValidateBinMandatoryOnAfterCheckBins(Rec);
                end;
            end;
        }
        field(5733; "Directed Put-away and Pick"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Directed Put-away and Pick';

            trigger OnValidate()
            var
                WhseActivHeader: Record "Warehouse Activity Header";
                WhseShptHeader: Record "Warehouse Shipment Header";
                WhseRcptHeader: Record "Warehouse Receipt Header";
            begin
                WhseActivHeader.SetRange("Location Code", Code);
                if not WhseActivHeader.IsEmpty() then
                    Error(Text014, FieldCaption("Directed Put-away and Pick"), WhseActivHeader.TableCaption());

                WhseRcptHeader.SetRange("Location Code", Code);
                if not WhseRcptHeader.IsEmpty() then
                    Error(Text014, FieldCaption("Directed Put-away and Pick"), WhseRcptHeader.TableCaption());

                WhseShptHeader.SetRange("Location Code", Code);
                if not WhseShptHeader.IsEmpty() then
                    Error(Text014, FieldCaption("Directed Put-away and Pick"), WhseShptHeader.TableCaption());

                if "Directed Put-away and Pick" then begin
                    TestField("Use As In-Transit", false);
                    TestField("Bin Mandatory");
                    Validate("Require Receive", true);
                    Validate("Require Shipment", true);
                    Validate("Require Put-away", true);
                    Validate("Require Pick", true);
                    Validate("Use Cross-Docking", true);
                    "Default Bin Selection" := "Default Bin Selection"::" ";
                    Validate("Check Whse. Class", true);
                    "Pick Bin Policy" := "Pick Bin Policy"::"Bin Ranking";
                    "Put-away Bin Policy" := "Put-away Bin Policy"::"Put-away Template";
                    "Asm. Consump. Whse. Handling" := "Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    "Job Consump. Whse. Handling" := "Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                end else
                    Validate("Adjustment Bin Code", '');

                if (not "Directed Put-away and Pick") and xRec."Directed Put-away and Pick" then begin
                    "Default Bin Selection" := "Default Bin Selection"::"Fixed Bin";
                    "Use Put-away Worksheet" := false;
                    Validate("Use Cross-Docking", false);
                end;
            end;
        }
        field(5734; "Default Bin Selection"; Enum "Location Default Bin Selection")
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Default Bin Selection';

            trigger OnValidate()
            begin
                if ("Default Bin Selection" <> xRec."Default Bin Selection") and ("Default Bin Selection" = "Default Bin Selection"::" ") then
                    TestField("Directed Put-away and Pick");
            end;
        }
        field(5790; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
        }
        field(5791; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
        }
        field(7305; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            TableRelation = "Put-away Template Header";
        }
        field(7306; "Use Put-away Worksheet"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Use Put-away Worksheet';
        }
        field(7307; "Pick According to FEFO"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Pick According to FEFO';
        }
        field(7308; "Allow Breakbulk"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Allow Breakbulk';
            ToolTip = 'Specifies that an order can be fulfilled with items stored in alternate units of measure, if an item stored in the requested unit of measure is not found. This feature is applicable only with directed put-away and pick locations.';
        }
        field(7309; "Bin Capacity Policy"; Option)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Capacity Policy';
            OptionCaption = 'Never Check Capacity,Allow More Than Max. Capacity,Prohibit More Than Max. Cap.';
            OptionMembers = "Never Check Capacity","Allow More Than Max. Capacity","Prohibit More Than Max. Cap.";
        }
        field(7310; "Pick Bin Policy"; Enum "Pick Bin Policy")
        {
            Caption = 'Pick Bin Policy';
            InitValue = "Default Bin";
        }
        field(7311; "Check Whse. Class"; Boolean)
        {
            Caption = 'Check Warehouse Class';
        }
        field(7312; "Put-away Bin Policy"; Enum "Put-away Bin Policy")
        {
            Caption = 'Put-away Bin Policy';
            InitValue = "Default Bin";
        }
        field(7313; "Open Shop Floor Bin Code"; Code[20])
        {
            Caption = 'Open Shop Floor Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "Open Shop Floor Bin Code", FieldCaption("Open Shop Floor Bin Code"), Code);
            end;
        }
        field(7314; "To-Production Bin Code"; Code[20])
        {
            Caption = 'To-Production Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "To-Production Bin Code", FieldCaption("To-Production Bin Code"), Code);
            end;
        }
        field(7315; "From-Production Bin Code"; Code[20])
        {
            Caption = 'From-Production Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "From-Production Bin Code", FieldCaption("From-Production Bin Code"), Code);
            end;
        }
        field(7317; "Adjustment Bin Code"; Code[20])
        {
            Caption = 'Adjustment Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                if "Adjustment Bin Code" <> xRec."Adjustment Bin Code" then begin
                    if "Adjustment Bin Code" = '' then
                        CheckEmptyBin(
                          Rec.Code, xRec."Adjustment Bin Code", FieldCaption("Adjustment Bin Code"))
                    else
                        CheckEmptyBin(
                          Rec.Code, Rec."Adjustment Bin Code", FieldCaption("Adjustment Bin Code"));

                    CheckWhseAdjmtJnl();
                end;
            end;
        }
        field(7319; "Always Create Put-away Line"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Always Create Put-away Line';
        }
        field(7320; "Always Create Pick Line"; Boolean)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Always Create Pick Line';
        }
        field(7321; "Special Equipment"; Option)
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Special Equipment';
            OptionCaption = ' ,According to Bin,According to SKU/Item';
            OptionMembers = " ","According to Bin","According to SKU/Item";

            trigger OnValidate()
            begin
                if Rec."Special Equipment" <> Rec."Special Equipment"::" " then
                    Rec.TestField("Bin Mandatory");
            end;
        }
        field(7323; "Receipt Bin Code"; Code[20])
        {
            Caption = 'Receipt Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));
        }
        field(7325; "Shipment Bin Code"; Code[20])
        {
            Caption = 'Shipment Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                if "Shipment Bin Code" <> '' then begin
                    Bin.Get(Code, "Shipment Bin Code");
                    Bin.TestField(Dedicated, false);
                end;
            end;
        }
        field(7326; "Cross-Dock Bin Code"; Code[20])
        {
            Caption = 'Cross-Dock Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));
        }
        field(7330; "To-Assembly Bin Code"; Code[20])
        {
            Caption = 'To-Assembly Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "To-Assembly Bin Code", FieldCaption("To-Assembly Bin Code"), Code);
            end;
        }
        field(7331; "From-Assembly Bin Code"; Code[20])
        {
            Caption = 'From-Assembly Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "From-Assembly Bin Code", FieldCaption("From-Assembly Bin Code"), Code);
            end;
        }
        field(7332; "Asm.-to-Order Shpt. Bin Code"; Code[20])
        {
            Caption = 'Asm.-to-Order Shpt. Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Code, "Asm.-to-Order Shpt. Bin Code", FieldCaption("Asm.-to-Order Shpt. Bin Code"), Code);
            end;
        }
        field(7333; "To-Job Bin Code"; Code[20])
        {
            Caption = 'To-Project Bin Code';
            TableRelation = Bin.Code where("Location Code" = field(Code));

            trigger OnValidate()
            begin
                CheckBinCode(Rec.Code, Rec."To-Job Bin Code", Rec.FieldCaption(Rec."To-Job Bin Code"), Rec.Code);
            end;
        }
        field(7334; "Asm. Consump. Whse. Handling"; Enum "Asm. Consump. Whse. Handling")
        {
            Caption = 'Asm. Consump. Whse. Handling';

            trigger OnValidate()
            begin
                if Rec."Asm. Consump. Whse. Handling" <> xRec."Asm. Consump. Whse. Handling" then
                    CheckInventoryActivityExists(Rec.Code, Database::"Assembly Line", Rec.FieldCaption("Asm. Consump. Whse. Handling"));

                if Rec."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement" then
                    Rec.TestField("Bin Mandatory", true);
            end;
        }
        field(7335; "Job Consump. Whse. Handling"; Enum "Job Consump. Whse. Handling")
        {
            Caption = 'Project Consump. Whse. Handling';

            trigger OnValidate()
            begin
                if Rec."Job Consump. Whse. Handling" <> xRec."Job Consump. Whse. Handling" then
                    CheckInventoryActivityExists(Rec.Code, Database::Job, Rec.FieldCaption("Job Consump. Whse. Handling"));
            end;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7700; "Use ADCS"; Boolean)
        {
            AccessByPermission = TableData "Miniform Header" = R;
            Caption = 'Use ADCS';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
        key(Key3; "Use As In-Transit", "Bin Mandatory")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        TransferRoute: Record "Transfer Route";
        WhseEmployee: Record "Warehouse Employee";
        StockkeepingUnit: Record "Stockkeeping Unit";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        StockkeepingUnit.SetRange("Location Code", Code);
        if not StockkeepingUnit.IsEmpty() then
            Error(CannotDeleteLocSKUExistErr, Code);

        WMSCheckWarehouse();

        TransferRoute.SetRange("Transfer-from Code", Code);
        TransferRoute.DeleteAll();
        TransferRoute.Reset();
        TransferRoute.SetRange("Transfer-to Code", Code);
        TransferRoute.DeleteAll();

        WhseEmployee.SetRange("Location Code", Code);
        WhseEmployee.DeleteAll(true);

        CalendarManagement.DeleteCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::Location, Code);
        DimensionManagement.DeleteDefaultDim(Database::Location, Rec.Code);
    end;

    trigger OnRename()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        CalendarManagement.RenameCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::Location, Code, xRec.Code);
        DimensionManagement.RenameDefaultDim(Database::Location, xRec.Code, Rec.Code);
    end;

    var
        Bin: Record Bin;
        PostCode: Record "Post Code";
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete the %1 %2, because they contain items.';
        Text001: Label 'You cannot delete the %1 %2, because one or more Warehouse Activity Lines exist for this %1.';
        Text002: Label '%1 must be Yes, because the bins contain items.';
#pragma warning restore AA0470
        Text003: Label 'Cancelled.';
        Text004: Label 'The total quantity of items in the warehouse is 0, but the Adjustment Bin contains a negative quantity and other bins contain a positive quantity.\';
#pragma warning disable AA0470
        Text005: Label 'Do you still want to delete this %1?';
        Text006: Label 'You cannot change the %1 until the inventory stored in %2 %3 is 0.';
        Text007: Label 'You have to delete all Adjustment Warehouse Journal Lines first before you can change the %1.';
        Text008: Label '%1 must be %2, because one or more %3 exist.';
        Text009: Label 'You cannot change %1 because there are one or more open ledger entries on this location.';
#pragma warning restore AA0470
        Text010: Label 'Checking item ledger entries for open entries...';
#pragma warning disable AA0470
        Text011: Label 'You cannot change the %1 to %2 until the inventory stored in this bin is 0.';
        Text013: Label 'You cannot delete %1 because there are one or more ledger entries on this location.';
        Text014: Label 'You cannot change %1 because one or more %2 exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InvtActivityExistsFieldValidationErr: Label 'You cannot change %1 because one or more inventory activities exist for this location.', Comment = '%1 = field caption';
        CannotDeleteLocSKUExistErr: Label 'You cannot delete %1 because one or more stockkeeping units exist at this location.', Comment = '%1: Field(Code)';
#pragma warning disable AA0470
        LocationMustBeBinMandatoryErr: Label 'Location %1 must be set up with Bin Mandatory if the Location %2 uses it.', Comment = '%2 = Work Center No.';
#pragma warning restore AA0470
        UnspecifiedLocationLbl: Label '(Unspecified Location)';

    procedure RequireShipment(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Require Shipment");
        WarehouseSetup.GetRecordOnce();
        exit(WarehouseSetup."Require Shipment");
    end;

    procedure RequirePicking(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Require Pick");
        WarehouseSetup.GetRecordOnce();
        exit(WarehouseSetup."Require Pick");
    end;

    procedure RequireReceive(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Require Receive");
        WarehouseSetup.GetRecordOnce();
        exit(WarehouseSetup."Require Receive");
    end;

    procedure RequirePutaway(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Require Put-away");
        WarehouseSetup.GetRecordOnce();
        exit(WarehouseSetup."Require Put-away");
    end;

    procedure BinMandatory(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Bin Mandatory");
    end;

    procedure GetLocationSetup(LocationCode: Code[10]; var Location2: Record Location): Boolean
    begin
        if not Get(LocationCode) then begin
            Location2.Init();
            WarehouseSetup.GetRecordOnce();
            InventorySetup.GetRecordOnce();
            Location2.Code := LocationCode;
            Location2."Use As In-Transit" := false;
            Location2."Require Put-away" := WarehouseSetup."Require Put-away";
            Location2."Require Pick" := WarehouseSetup."Require Pick";
            Location2."Outbound Whse. Handling Time" := InventorySetup."Outbound Whse. Handling Time";
            Location2."Inbound Whse. Handling Time" := InventorySetup."Inbound Whse. Handling Time";
            Location2."Require Receive" := WarehouseSetup."Require Receive";
            Location2."Require Shipment" := WarehouseSetup."Require Shipment";
            // Initialize new settings based on upgrade
            case true of
                not Location2."Require Pick" and not Location2."Require Shipment",
                not Location2."Require Pick" and Location2."Require Shipment":
                    begin
                        Location2."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
                        Location2."Job Consump. Whse. Handling" := Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
                    end;
                Location2."Require Pick" and not Location2."Require Shipment":
                    begin
                        Location2."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";
                        Location2."Job Consump. Whse. Handling" := Enum::"Job Consump. Whse. Handling"::"Inventory Pick";
                    end;
                Location2."Require Pick" and Location2."Require Shipment":
                    begin
                        Location2."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                        Location2."Job Consump. Whse. Handling" := Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                    end;
            end;

            OnGetLocationSetupOnAfterInitLocation(Rec, Location2);
            exit(false);
        end;

        Location2 := Rec;
        exit(true);
    end;

    local procedure WMSCheckWarehouse()
    var
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WhseActivLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntry2: Record "Warehouse Entry";
        WhseJnlLine: Record "Warehouse Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWMSCheckWarehouse(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemLedgerEntry.SetRange("Location Code", Code);
        ItemLedgerEntry.SetRange(Open, true);
        if not ItemLedgerEntry.IsEmpty() then
            Error(Text013, Code);

        WarehouseEntry.SetRange("Location Code", Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        if WarehouseEntry."Qty. (Base)" = 0 then begin
            if "Adjustment Bin Code" <> '' then begin
                WarehouseEntry2.SetRange("Bin Code", "Adjustment Bin Code");
                WarehouseEntry2.SetRange("Location Code", Code);
                WarehouseEntry2.CalcSums("Qty. (Base)");
                if WarehouseEntry2."Qty. (Base)" < 0 then
                    if not Confirm(Text004 + Text005, false, TableCaption) then
                        Error(Text003)
            end;
        end else
            Error(Text000, TableCaption(), Code);

        WhseActivLine.SetRange("Location Code", Code);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetFilter("Qty. Outstanding", '<>0');
        if not WhseActivLine.IsEmpty() then
            Error(Text001, TableCaption(), Code);

        WhseJnlLine.SetRange("Location Code", Code);
        WhseJnlLine.SetFilter(Quantity, '<>0');
        if not WhseJnlLine.IsEmpty() then
            Error(Text001, TableCaption(), Code);

        Zone.SetRange("Location Code", Code);
        Zone.DeleteAll();
        Bin.SetRange("Location Code", Code);
        Bin.DeleteAll();
        BinContent.SetRange("Location Code", Code);
        BinContent.DeleteAll();
    end;

    procedure CheckEmptyBin(LocationCode: Code[10]; BinCode: Code[20]; CaptionOfField: Text[30])
    var
        WarehouseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetCurrentKey("Bin Code", "Location Code", "Item No.");
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Location Code", Code);
        if WarehouseEntry.FindFirst() then
            repeat
                WarehouseEntry.SetRange("Item No.", WarehouseEntry."Item No.");

                WhseEntry2.CopyFilters(WarehouseEntry);
                WhseEntry2.CalcSums("Qty. (Base)");
                if WhseEntry2."Qty. (Base)" <> 0 then begin
                    if (BinCode = "Adjustment Bin Code") and (xRec."Adjustment Bin Code" = '') then
                        Error(Text011, CaptionOfField, BinCode);

                    Error(Text006, CaptionOfField, Bin.TableCaption(), BinCode);
                end;

                WarehouseEntry.FindLast();
                WarehouseEntry.SetRange("Item No.");
            until WarehouseEntry.Next() = 0;
    end;

    local procedure CheckWhseAdjmtJnl()
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlTemplate.SetRange(Type, WhseJnlTemplate.Type::Item);
        if WhseJnlTemplate.Find('-') then
            repeat
                WhseJnlLine.SetRange("Journal Template Name", WhseJnlTemplate.Name);
                WhseJnlLine.SetRange("Location Code", Code);
                if not WhseJnlLine.IsEmpty() then
                    Error(
                      Text007,
                      FieldCaption("Adjustment Bin Code"));
            until WhseJnlTemplate.Next() = 0;
    end;

    procedure GetRequirementText(FieldNumber: Integer): Text[50]
    var
#pragma warning disable AA0074
        Text000: Label 'Shipment,Receive,Pick,Put-Away';
#pragma warning restore AA0074
    begin
        case FieldNumber of
            FieldNo("Require Shipment"):
                exit(SelectStr(1, Text000));
            FieldNo("Require Receive"):
                exit(SelectStr(2, Text000));
            FieldNo("Require Pick"):
                exit(SelectStr(3, Text000));
            FieldNo("Require Put-away"):
                exit(SelectStr(4, Text000));
        end;
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Location, GetPosition());
    end;

    procedure IsBWReceive(): Boolean
    begin
        exit("Bin Mandatory" and (not "Directed Put-away and Pick") and "Require Receive");
    end;

    procedure IsBWShip(): Boolean
    begin
        exit("Bin Mandatory" and (not "Directed Put-away and Pick") and "Require Shipment");
    end;

    procedure IsBinBWReceiveOrShip(BinCode: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsBinBWReceiveOrShip(Rec, BinCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(("Receipt Bin Code" <> '') and (BinCode = "Receipt Bin Code") or
          ("Shipment Bin Code" <> '') and (BinCode = "Shipment Bin Code"));
    end;

    procedure IsBinBWProdOutput(BinCode: Code[20]): Boolean
    begin
        exit(("To-Production Bin Code" <> '') and (BinCode = "To-Production Bin Code"));
    end;

    procedure IsInTransit(LocationCode: Code[10]): Boolean
    begin
        if Location.Get(LocationCode) then
            exit(Location."Use As In-Transit");
        exit(false);
    end;

    local procedure CreateInboundWhseRequest()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        TransferLine.SetRange("Transfer-to Code", Code);
        if TransferLine.FindSet() then
            repeat
                if TransferLine."Quantity Received" <> TransferLine."Quantity Shipped" then begin
                    TransferHeader.Get(TransferLine."Document No.");
                    WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
                    WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

                    TransferLine.SetRange("Document No.", TransferLine."Document No.");
                    TransferLine.FindLast();
                    TransferLine.SetRange("Document No.");
                end;
            until TransferLine.Next() = 0;
    end;

    procedure GetLocationsIncludingUnspecifiedLocation(IncludeOnlyUnspecifiedLocation: Boolean; ExcludeInTransitLocations: Boolean)
    var
        Location: Record Location;
    begin
        Init();
        Validate(Name, UnspecifiedLocationLbl);
        Insert();

        if not IncludeOnlyUnspecifiedLocation then begin
            if ExcludeInTransitLocations then
                Location.SetRange("Use As In-Transit", false);

            if Location.FindSet() then
                repeat
                    Init();
                    Copy(Location);
                    Insert();
                until Location.Next() = 0;
        end;

        FindFirst();
    end;

    procedure PickAccordingToFEFO(): Boolean
    begin
        exit(Rec."Require Pick" and ((Rec."Require Shipment" and Rec."Bin Mandatory") or (not Rec."Require Shipment")));
    end;

    procedure SelectMultipleLocations(): Text
    var
        LocationToSelect: Record Location;
        LocationList: Page "Location List";
    begin
        LocationToSelect.SetRange("Use As In-Transit", false);
        LocationList.SetTableView(LocationToSelect);
        LocationList.LookupMode(true);
        if LocationList.RunModal() = ACTION::LookupOK then
            exit(LocationList.GetSelectionFilter());
    end;

    procedure CheckInventoryActivityExists(LocationCode: Code[10]; SourceType: Integer; FieldCaption: Text)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        if not WarehouseActivityLine.IsEmpty() then
            Error(InvtActivityExistsFieldValidationErr, FieldCaption);
    end;

    procedure CheckBinCode(LocationCode: Code[10]; BinCode: Code[20]; BinCaption: Text; Number: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if BinCode <> '' then begin
            Location.Get(LocationCode);
            if not Location."Bin Mandatory" then
                Error(LocationMustBeBinMandatoryErr, Location.Code, Number);
            Bin.Get(LocationCode, BinCode);
            WhseIntegrationMgt.CheckBinTypeAndCode(Database::Location, BinCaption, LocationCode, BinCode, 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCity(var Location: Record Location; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupPostCode(var Location: Record Location; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var Location: Record Location; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var Location: Record Location; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUseCrossDocking(var Location: Record Location; xLocation: Record Location; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLocationSetupOnAfterInitLocation(var Location: Record Location; var Location2: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWMSCheckWarehouse(var Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinMandatoryOnBeforeItemLedgEntrySetFilters(var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinMandatoryOnAfterItemLedgEntrySetFilters(var Location: Record Location);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinMandatoryOnAfterWhseEntrySetFilters(var Location: Record Location; var WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Location: Record Location; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Location: Record Location; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsBinBWReceiveOrShip(Location: Record Location; BinCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinMandatoryOnAfterCheckBins(Location: Record Location)
    begin
    end;
}
