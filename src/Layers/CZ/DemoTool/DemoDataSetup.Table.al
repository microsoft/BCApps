table 101900 "Demo Data Setup"
{
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Editable = false;
        }
        field(6; "Currency Code"; Code[10])
        {
        }
        field(7; "Language Code"; Code[10])
        {
        }
        field(8; "Starting Year"; Integer)
        {

            trigger OnValidate()
            begin
                "Working Date" := DMY2Date(1, 1, "Starting Year");
            end;
        }
        field(9; "Working Date"; Date)
        {
        }
        field(15; "Local Currency Factor"; Decimal)
        {
            DecimalPlaces = 4 : 4;
            AutoFormatType = 0;
        }
        field(16; "Local Precision Factor"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(17; "Company Type"; Option)
        {
            OptionMembers = VAT,"Sales Tax";

            trigger OnValidate()
            begin
                if "Company Type" <> "Company Type"::VAT then
                    CheckMiniApp();
            end;
        }
        field(18; "Additional Currency Code"; Code[10])
        {
        }
        field(19; "LCY an EMU Currency"; Boolean)
        {
        }
        field(21; "Remove Country Prefix"; Boolean)
        {
            InitValue = true;
        }
        field(23; "Advanced Setup"; Boolean)
        {
        }
        field(24; "Adjust for Payment Discount"; Boolean)
        {
        }
        field(50; "Progress Window Design"; Text[250])
        {
        }
        field(51; "Data Language ID"; Integer)
        {
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

            trigger OnValidate()
            begin
                if Financials then
                    CheckMiniApp();
            end;
        }
        field(114; "Relationship Mgt."; Boolean)
        {

            trigger OnValidate()
            begin
                if "Relationship Mgt." then
                    CheckMiniApp();
            end;
        }
        field(115; "Reserved for future use 1"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Reserved for future use 1" then
                    CheckMiniApp();
            end;
        }
        field(116; "Reserved for future use 2"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Reserved for future use 2" then
                    CheckMiniApp();
            end;
        }
        field(117; "Service Management"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Service Management" then
                    CheckMiniApp();
            end;
        }
        field(118; Distribution; Boolean)
        {

            trigger OnValidate()
            begin
                if not Distribution and ADCS then
                    Error(DistributionDataErr);

                CheckMiniApp();
            end;
        }
        field(119; Manufacturing; Boolean)
        {

            trigger OnValidate()
            begin
                if Manufacturing then
                    CheckMiniApp();
            end;
        }
        field(120; ADCS; Boolean)
        {

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

            trigger OnValidate()
            begin
                if "Reserved for future use 3" then
                    CheckMiniApp();
            end;
        }
        field(123; "Reserved for future use 4"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Reserved for future use 4" then
                    CheckMiniApp();
            end;
        }
        field(124; "Reserved for future use 5"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Reserved for future use 5" then
                    CheckMiniApp();
            end;
        }
        field(125; "Test Demonstration Company"; Boolean)
        {
        }
        field(126; "Skip sequence of actions"; Boolean)
        {

            trigger OnValidate()
            begin
                if "Skip sequence of actions" then
                    CheckMiniApp();
            end;
        }
        field(130; "Goods VAT Rate"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(131; "Services VAT Rate"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(132; "Reduced VAT Rate"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(133; "Rapid Start Country"; Code[10])
        {
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
        XISURPLUS: Label 'I_SURPLUS';
        XISurplusTxt: Label 'Physical Inventory Surplus';
        XIDEFIC: Label 'I_DEFIC';
        XIDeficiencyTxt: Label 'Physical Inventory Deficiency';
        XITRANSFER: Label 'I_TRANSFER';
        XITransferTxt: Label 'Inventory Transfer';
        XIASSEMBLY: Label 'I_ASSEMBLY';
        XIAssemblyTxt: Label 'Inventory Assembly';
        XIMANUFACT: Label 'I_MANUFACT';
        XIManufactureTxt: Label 'Inventory Manufacture';
        XI: Label 'I';
        XS: Label 'S';
        XRC: Label 'RC';
        XNP: Label 'NP', Comment = 'Natural Person';
        XDomesticcustomersandvendorsnonentrepreneurs: Label 'Domestic customers and vendors (non-entrepreneurs)';

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
        exit(XVAT + Format("Goods VAT Rate"));
    end;

    procedure ServicesVATCode(): Code[10]
    begin
        TestField("Services VAT Rate");
        exit(XVAT + Format("Services VAT Rate"));
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

    procedure BaseVATRate(): Decimal
    begin
        // NAVCZ
        exit("Goods VAT Rate");
    end;

    procedure BaseVATCode(): Code[10]
    begin
        // NAVCZ
        exit(GoodsVATCode());
    end;

    procedure BaseVATItemCode(): Code[10]
    begin
        // NAVCZ
        exit(GoodsVATCode() + XI);
    end;

    procedure BaseVATServiceCode(): Code[10]
    begin
        // NAVCZ
        exit(GoodsVATCode() + XS);
    end;

    procedure BaseVATReverseChargeCode(): Code[10]
    begin
        // NAVCZ
        exit(GoodsVATCode() + XRC);
    end;

    procedure BaseVATText(): Text[30]
    begin
        // NAVCZ
        exit(GoodsVATText());
    end;

    procedure FirstReducedVATRate(): Decimal
    begin
        // NAVCZ
        exit("Services VAT Rate");
    end;

    procedure FirstReducedVATCode(): Code[10]
    begin
        // NAVCZ
        exit(ServicesVATCode());
    end;

    procedure FirstReducedVATItemCode(): Code[10]
    begin
        // NAVCZ
        exit(ServicesVATCode() + XI);
    end;

    procedure FirstReducedVATServiceCode(): Code[10]
    begin
        // NAVCZ
        exit(ServicesVATCode() + XS);
    end;

    procedure FirstReducedVATReverseChargeCode(): Code[10]
    begin
        // NAVCZ
        exit(ServicesVATCode() + XRC);
    end;

    procedure FirstReducedVATText(): Text[30]
    begin
        // NAVCZ
        exit(ServicesVATText());
    end;

    procedure SecondReducedVATRate(): Decimal
    begin
        // NAVCZ
        exit("Reduced VAT Rate");
    end;

    procedure SecondReducedVATCode(): Code[10]
    begin
        // NAVCZ
        exit(ReducedVATCode());
    end;

    procedure SecondReducedVATItemCode(): Code[10]
    begin
        // NAVCZ
        exit(ReducedVATCode() + XI);
    end;

    procedure SecondReducedVATServiceCode(): Code[10]
    begin
        // NAVCZ
        exit(ReducedVATCode() + XS);
    end;

    procedure SecondReducedVATText(): Text[30]
    begin
        // NAVCZ
        exit(ReducedVATText());
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
                    // NAVCZ
                    "Goods VAT Rate" := 21;
                    "Services VAT Rate" := 12;
                    "Reduced VAT Rate" := 10;
                    // NAVCZ
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

    procedure ISurplusCode(): Code[10]
    begin
        // NAVCZ
        exit(XISURPLUS);
    end;

    procedure ISurplusText(): Text[50]
    begin
        // NAVCZ
        exit(XISurplusTxt);
    end;

    procedure IDeficiencyCode(): Code[10]
    begin
        // NAVCZ
        exit(XIDEFIC);
    end;

    procedure IDeficiencyText(): Text[50]
    begin
        // NAVCZ
        exit(XIDeficiencyTxt);
    end;

    procedure ITransferCode(): Code[10]
    begin
        // NAVCZ
        exit(XITRANSFER);
    end;

    procedure ITransferText(): Text[50]
    begin
        // NAVCZ
        exit(XITransferTxt);
    end;

    procedure IAssemblyCode(): Code[10]
    begin
        // NAVCZ
        exit(XIASSEMBLY);
    end;

    procedure IAssemblyText(): Text[50]
    begin
        // NAVCZ
        exit(XIAssemblyTxt);
    end;

    procedure IManufactureCode(): Code[10]
    begin
        // NAVCZ
        exit(XIMANUFACT);
    end;

    procedure IManufactureText(): Text[50]
    begin
        // NAVCZ
        exit(XIManufactureTxt);
    end;

    procedure NPCode(): Code[10]
    begin
        // NAVCZ
        exit(XNP);
    end;

    procedure NPText(): Text[50]
    begin
        // NAVCZ
        exit(XDomesticcustomersandvendorsnonentrepreneurs);
    end;
}
