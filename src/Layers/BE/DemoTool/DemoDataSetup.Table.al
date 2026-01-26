table 101900 "Demo Data Setup"
{
    Caption = 'Demo Data Setup';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(7; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
        }
        field(8; "Starting Year"; Integer)
        {
            Caption = 'Starting Year';

            trigger OnValidate()
            begin
                "Working Date" := DMY2Date(1, 1, "Starting Year");
            end;
        }
        field(9; "Working Date"; Date)
        {
            Caption = 'Working Date';
        }
        field(15; "Local Currency Factor"; Decimal)
        {
            Caption = 'Local Currency Factor';
            DecimalPlaces = 4 : 4;
            AutoFormatType = 0;
        }
        field(16; "Local Precision Factor"; Decimal)
        {
            Caption = 'Local Precision Factor';
            AutoFormatType = 0;
        }
        field(17; "Company Type"; Option)
        {
            Caption = 'Company Type';
            OptionCaption = 'VAT,Sales Tax';
            OptionMembers = VAT,"Sales Tax";

            trigger OnValidate()
            begin
                if "Company Type" <> "Company Type"::VAT then
                    CheckMiniApp();
            end;
        }
        field(18; "Additional Currency Code"; Code[10])
        {
            Caption = 'Additional Currency Code';
        }
        field(19; "LCY an EMU Currency"; Boolean)
        {
            Caption = 'LCY an EMU Currency';
        }
        field(21; "Remove Country Prefix"; Boolean)
        {
            Caption = 'Remove Country Prefix';
            InitValue = true;
        }
        field(23; "Advanced Setup"; Boolean)
        {
            Caption = 'Advanced Setup';
        }
        field(24; "Adjust for Payment Discount"; Boolean)
        {
            Caption = 'Adjust for Payment Discount';
        }
        field(50; "Progress Window Design"; Text[250])
        {
            Caption = 'Progress Window Design';
        }
        field(51; "Data Language ID"; Integer)
        {
            Caption = 'Data Language ID';
            TableRelation = "Windows Language" where("Globally Enabled" = const(true),
                                                      "STX File Exist" = const(true));

            trigger OnValidate()
            begin
                CalcFields("Data Language Name");
                WindLanguage.Reset();
                WindLanguage.Get("Data Language ID");
                Validate("Language Code", WindLanguage."Abbreviated Name");
            end;
        }
        field(52; "Data Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Data Language ID")));
            Caption = 'Data Language Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Path to Picture Folder"; Text[250])
        {
            trigger OnValidate()
            begin
                if "Path to Picture Folder" = '' then
                    exit;
                if "Path to Picture Folder"[StrLen("Path to Picture Folder")] = '\' then
                    exit;
                "Path to Picture Folder" += '\';
            end;
        }
        field(111; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = 'Extended,Standard,Evaluation,O365', Locked = true;
            OptionMembers = Extended,Standard,Evaluation,O365;

            trigger OnValidate()
            begin
                "Skip sequence of actions" := false;
                if "Data Type" <> "Data Type"::Extended then begin
                    SelectDomains(false);
                    "Skip sequence of actions" := true;
                end;
            end;
        }
        field(113; Financials; Boolean)
        {
            Caption = 'Financials';

            trigger OnValidate()
            begin
                if Financials then
                    CheckMiniApp();
            end;
        }
        field(114; "Relationship Mgt."; Boolean)
        {
            Caption = 'Relationship Mgt.';

            trigger OnValidate()
            begin
                if "Relationship Mgt." then
                    CheckMiniApp();
            end;
        }
        field(115; "Reserved for future use 1"; Boolean)
        {
            Caption = 'Reserved for future use 1';

            trigger OnValidate()
            begin
                if "Reserved for future use 1" then
                    CheckMiniApp();
            end;
        }
        field(116; "Reserved for future use 2"; Boolean)
        {
            Caption = 'Reserved for future use 2';

            trigger OnValidate()
            begin
                if "Reserved for future use 2" then
                    CheckMiniApp();
            end;
        }
        field(117; "Service Management"; Boolean)
        {
            Caption = 'Service Management';

            trigger OnValidate()
            begin
                if "Service Management" then
                    CheckMiniApp();
            end;
        }
        field(118; Distribution; Boolean)
        {
            Caption = 'Distribution';

            trigger OnValidate()
            begin
                if not Distribution and ADCS then
                    Error(DistributionDataErr);

                CheckMiniApp();
            end;
        }
        field(119; Manufacturing; Boolean)
        {
            Caption = 'Manufacturing';

            trigger OnValidate()
            begin
                if Manufacturing then
                    CheckMiniApp();
            end;
        }
        field(120; ADCS; Boolean)
        {
            Caption = 'ADCS';

            trigger OnValidate()
            begin
                if ADCS then begin
                    Distribution := true;
                    CheckMiniApp();
                end;
            end;
        }
        field(121; "Reserved for future use 3"; Boolean)
        {
            Caption = 'Reserved for future use 3';

            trigger OnValidate()
            begin
                if "Reserved for future use 3" then
                    CheckMiniApp();
            end;
        }
        field(123; "Reserved for future use 4"; Boolean)
        {
            Caption = 'Reserved for future use 4';

            trigger OnValidate()
            begin
                if "Reserved for future use 4" then
                    CheckMiniApp();
            end;
        }
        field(124; "Reserved for future use 5"; Boolean)
        {
            Caption = 'Reserved for future use 5';

            trigger OnValidate()
            begin
                if "Reserved for future use 5" then
                    CheckMiniApp();
            end;
        }
        field(125; "Test Demonstration Company"; Boolean)
        {
            Caption = 'Test Demonstration Company';
        }
        field(126; "Skip sequence of actions"; Boolean)
        {
            Caption = 'Skip sequence of actions';

            trigger OnValidate()
            begin
                if "Skip sequence of actions" then
                    CheckMiniApp();
            end;
        }
        field(130; "Goods VAT Rate"; Decimal)
        {
            Caption = 'Goods VAT Rate';
            AutoFormatType = 0;
        }
        field(131; "Services VAT Rate"; Decimal)
        {
            Caption = 'Services VAT Rate';
            AutoFormatType = 0;
        }
        field(132; "Reduced VAT Rate"; Decimal)
        {
            Caption = 'Reduced VAT Rate';
            AutoFormatType = 0;
        }
        field(133; "Rapid Start Country"; Code[10])
        {
            Caption = 'Rapid Start Country';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DistributionDataErr: Label 'The Distribution demonstration data must be created prior to the ADCS data.';
        WindLanguage: Record "Windows Language";
        XVAT: Label 'VAT';
        XNOVAT: Label 'NO VAT';
        XMISC: Label 'MISC';
        XFULL: Label 'FULL';
        XDOMESTIC: Label 'DOMESTIC';
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XEU: Label 'EU';
        XCustomersandvendorsinEU: Label 'Customers and vendors in EU';
        XFOREIGN: Label 'FOREIGN';
        XOthercustomersandvendorsnotEU: Label 'Other customers and vendors (not EU)';
        XRAWMAT: Label 'RAW MAT';
        XRETAIL: Label 'RETAIL';
        XSERVICES: Label 'SERVICES';
        XMANUFACT: Label 'MANUFACT';
        XFREIGHT: Label 'FREIGHT';
        XEXPORT: Label 'EXPORT';
        XRESALE: Label 'RESALE';
        XFINISHED: Label 'FINISHED';
        XG3: Label 'G3';
        XS3: Label 'S3';

    procedure CheckPath(NewPath: Text[250]): Boolean
    var
        Directory: DotNet Directory;
    begin
        exit(Directory.Exists(NewPath));
    end;

    procedure GetDecimalSymbol(): Boolean
    begin
        exit("Language Code" in ['ENA', 'ENC', 'ENG', 'ENI', 'ENU', 'ENZ', 'ESM', 'KOR', 'MSL', 'THA', 'JPN'])
    end;

    procedure GetRSPackageCode(): Text[20]
    var
        CountryRegionCode: Code[10];
    begin
        Get();
        TestField("Country/Region Code");
        TestField("Language Code");

        if "Rapid Start Country" <> '' then
            CountryRegionCode := "Rapid Start Country"
        else
            CountryRegionCode := "Country/Region Code";

        exit(StrSubstNo('%1.%2.%3', CountryRegionCode, "Language Code", Format("Data Type")));
    end;

    local procedure CheckMiniApp()
    begin
        if CurrFieldNo <> 0 then
            TestField("Data Type", "Data Type"::Extended);
    end;

    procedure SelectDomains(SelectAll: Boolean)
    begin
        if SelectAll then
            TestField("Data Type", "Data Type"::Extended);
        Financials := SelectAll;
        "Relationship Mgt." := SelectAll;
        "Service Management" := SelectAll;
        Distribution := SelectAll;
        Manufacturing := SelectAll;
        ADCS := SelectAll;
    end;

    procedure GoodsVATCode(): Code[10]
    begin
        TestField("Goods VAT Rate");
        exit(XG3);
    end;

    procedure ServicesVATCode(): Code[10]
    begin
        TestField("Services VAT Rate");
        exit(XS3);
    end;

    procedure ReducedVATCode(): Code[10]
    begin
        exit(XVAT + Format("Reduced VAT Rate"));
    end;

    procedure FullVATCode(): Code[10]
    begin
        exit(XFULL);
    end;

    procedure FullGoodsVATCode(): Code[10]
    begin
        // introduced for TRIAL and EVAL companies in VAT countries (FULL NORMAL)
        exit(XVAT + Format("Goods VAT Rate"));
    end;

    procedure FullServicesVATCode(): Code[10]
    begin
        // introduced for TRIAL and EVAL companies in VAT countries (FULL REDUCED)
        exit(XVAT + Format("Goods VAT Rate"));
    end;

    procedure NoVATCode(): Code[10]
    begin
        exit(XNOVAT);
    end;

    procedure GoodsVATText(): Text[30]
    begin
        exit(Format("Goods VAT Rate") + ' %');
    end;

    procedure ServicesVATText(): Text[30]
    begin
        exit(Format("Services VAT Rate") + ' %');
    end;

    procedure ReducedVATText(): Text[30]
    begin
        exit(Format("Reduced VAT Rate") + ' %');
    end;

    procedure NoVATText(): Text[30]
    begin
        exit('0 %');
    end;

    procedure SetTaxRates()
    begin
        case "Company Type" of
            "Company Type"::VAT:
                begin
                    "Goods VAT Rate" := 21;
                    "Services VAT Rate" := 6;
                    "Reduced VAT Rate" := 12;
                end;
            "Company Type"::"Sales Tax":
                begin
                    "Goods VAT Rate" := 0;
                    "Services VAT Rate" := 0;
                    "Reduced VAT Rate" := 0;
                end;
        end;
    end;

    procedure DomesticCode(): Code[10]
    begin
        exit(XDOMESTIC);
    end;

    procedure DomesticText(): Text[50]
    begin
        exit(XDomesticcustomersandvendors);
    end;

    procedure EUCode(): Code[10]
    begin
        exit(XEU);
    end;

    procedure EUText(): Text[50]
    begin
        exit(XCustomersandvendorsinEU);
    end;

    procedure ForeignCode(): Code[10]
    begin
        exit(XFOREIGN);
    end;

    procedure ForeignText(): Text[50]
    begin
        exit(XOthercustomersandvendorsnotEU);
    end;

    procedure FreightCode(): Code[10]
    begin
        exit(XFREIGHT);
    end;

    procedure MiscCode(): Code[10]
    begin
        exit(XMISC);
    end;

    procedure RawMatCode(): Code[10]
    begin
        exit(XRAWMAT);
    end;

    procedure RetailCode(): Code[10]
    begin
        exit(XRETAIL);
    end;

    procedure ServicesCode(): Code[10]
    begin
        exit(XSERVICES);
    end;

    procedure ManufactCode(): Code[10]
    begin
        exit(XMANUFACT);
    end;

    procedure ExportCode(): Code[10]
    begin
        exit(XEXPORT);
    end;

    procedure ResaleCode(): Code[10]
    begin
        exit(XRESALE);
    end;

    procedure FinishedCode(): Code[10]
    begin
        exit(XFINISHED);
    end;
}
