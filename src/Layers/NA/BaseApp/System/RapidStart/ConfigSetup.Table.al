namespace System.IO;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Setup;
using System;
using System.Environment.Configuration;
using System.Globalization;
using System.Reflection;
using System.Utilities;
using System.Xml;

table 8627 "Config. Setup"
{
    Caption = 'Config. Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(4; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(5; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(6; City; Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(7; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }
        field(8; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
        }
        field(9; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(10; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(11; "Giro No."; Text[20])
        {
            Caption = 'Giro No.';
        }
        field(12; "Bank Name"; Text[100])
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Name';
        }
        field(13; "Bank Branch No."; Text[20])
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Branch No.';
        }
        field(14; "Bank Account No."; Text[30])
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Account No.';
        }
        field(15; "Payment Routing No."; Text[20])
        {
            Caption = 'Payment Routing No.';
        }
        field(17; "Customs Permit No."; Text[10])
        {
            Caption = 'Customs Permit No.';
        }
        field(18; "Customs Permit Date"; Date)
        {
            Caption = 'Customs Permit Date';
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(20; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(21; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(22; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(23; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(24; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(26; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
        }
        field(27; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(29; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(30; "Post Code"; Code[20])
        {
            Caption = 'Post Code';

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(31; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(32; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
        }
        field(33; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(34; "E-Mail"; Text[80])
        {
            Caption = 'Email';
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(35; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(36; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(37; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
        }
        field(38; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(39; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(40; "Industrial Classification"; Text[30])
        {
            Caption = 'Industrial Classification';
        }
        field(500; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
        }
        field(5791; "Check-Avail. Period Calc."; DateFormula)
        {
            Caption = 'Check-Avail. Period Calc.';
        }
        field(5792; "Check-Avail. Time Bucket"; Option)
        {
            Caption = 'Check-Avail. Time Bucket';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
        }
        field(7601; "Cal. Convergence Time Frame"; DateFormula)
        {
            Caption = 'Cal. Convergence Time Frame';
            InitValue = '1Y';
        }
        field(8600; "Package File Name"; Text[250])
        {
            Caption = 'Package File Name';

            trigger OnValidate()
            begin
                ReadPackageHeader(DecompressPackage(false));
            end;
        }
        field(8601; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            Editable = false;
        }
        field(8602; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            Editable = false;
            TableRelation = "Windows Language";
        }
        field(8603; "Product Version"; Text[80])
        {
            Caption = 'Product Version';
            Editable = false;
        }
        field(8604; "Package Name"; Text[50])
        {
            Caption = 'Package Name';
        }
        field(8605; "Your Profile Code"; Code[30])
        {
            Caption = 'Your Profile Code';
            TableRelation = "All Profile"."Profile ID";
        }
        field(8606; "Your Profile App ID"; Guid)
        {
            Caption = 'Your Profile App ID';
        }
        field(8607; "Your Profile Scope"; Option)
        {
            Caption = 'Your Profile Scope';
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
        }
        field(8608; "Package File"; BLOB)
        {
            Caption = 'Package File';
        }
        field(10010; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
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

    var
        PostCode: Record "Post Code";
        HideDialog: Boolean;

        PackageAlreadyExistsQst: Label 'The imported package already exists. Do you want to import another package?';
        PackageDataNotDefinedErr: Label '%1 should be defined in the imported package.', Comment = '%1 = "Package Code"';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    [Scope('OnPrem')]
    procedure CompleteWizard(): Boolean
    var
        Scope: Option System,Tenant;
        AppID: Guid;
    begin
        TestField("Package File Name");
        TestField("Package Code");
        TestField("Package Name");

        ImportPackage(DecompressPackage(false));
        ApplyPackages();
        ApplyAnswers();
        CopyCompInfo();
        SelectDefaultRoleCenter("Your Profile Code", AppID, Scope::System);
        exit(true);
    end;

    procedure SelectDefaultRoleCenter(ProfileID: Code[30]; AppID: Guid; Scope: Option System,Tenant)
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        if AllProfile.Get(Scope, AppID, ProfileID) then begin
            AllProfile.Validate("Default Role Center", true);
            AllProfile.Modify();
            ConfPersonalizationMgt.ChangeDefaultRoleCenter(AllProfile);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReadPackageHeader(DecompressedFileName: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PackageXML: DotNet XmlDocument;
    begin
        if "Package File Name" <> '' then begin
            XMLDOMManagement.LoadXMLDocumentFromFile(DecompressedFileName, PackageXML);
            ReadPackageHeaderCommon(PackageXML);
        end else begin
            "Package Code" := '';
            "Package Name" := '';
            "Product Version" := '';
            "Language ID" := 0;
        end;
    end;

    procedure ReadPackageHeaderFromStream(InStream: InStream)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        PackageXML: DotNet XmlDocument;
    begin
        if "Package File Name" <> '' then begin
            XMLDOMManagement.LoadXMLDocumentFromInStream(InStream, PackageXML);
            ReadPackageHeaderCommon(PackageXML);
        end else begin
            "Package Code" := '';
            "Package Name" := '';
            "Product Version" := '';
            "Language ID" := 0;
        end;
    end;

    local procedure ReadPackageHeaderCommon(PackageXML: DotNet XmlDocument)
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        DocumentElement: DotNet XmlElement;
        LanguageID: Text;
    begin
        DocumentElement := PackageXML.DocumentElement;
        "Package Code" :=
          CopyStr(
            ConfigXMLExchange.GetAttribute(
              ConfigXMLExchange.GetElementName(ConfigPackage.FieldName(Code)), DocumentElement),
            1, MaxStrLen("Package Code"));
        if "Package Code" = '' then
            Error(PackageDataNotDefinedErr, FieldCaption("Package Code"));
        "Package Name" :=
          CopyStr(
            ConfigXMLExchange.GetAttribute(
              ConfigXMLExchange.GetElementName(ConfigPackage.FieldName("Package Name")), DocumentElement),
            1, MaxStrLen("Package Name"));
        if "Package Name" = '' then
            Error(PackageDataNotDefinedErr, FieldCaption("Package Name"));
        "Product Version" :=
          CopyStr(
            ConfigXMLExchange.GetAttribute(
              ConfigXMLExchange.GetElementName(ConfigPackage.FieldName("Product Version")), DocumentElement),
            1, MaxStrLen("Product Version"));
        LanguageID := ConfigXMLExchange.GetAttribute(
            ConfigXMLExchange.GetElementName(ConfigPackage.FieldName("Language ID")), DocumentElement);
        if LanguageID <> '' then
            Evaluate("Language ID", LanguageID);
        Modify();
    end;

    [Scope('OnPrem')]
    procedure ImportPackage(DecompressedFileName: Text)
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        if ConfigPackage.Get("Package Code") then
            if not HideDialog then
                if Confirm(PackageAlreadyExistsQst, true) then begin
                    ConfigPackage.Delete(true);
                    Commit();
                end else
                    Error('');

        ConfigXMLExchange.SetHideDialog(HideDialog);
        ConfigXMLExchange.ImportPackageXML(DecompressedFileName);
        Commit();
    end;

    procedure ImportPackageFromStream(InStream: InStream)
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        if ConfigPackage.Get("Package Code") then
            if not HideDialog then
                if Confirm(PackageAlreadyExistsQst, true) then begin
                    ConfigPackage.Delete(true);
                    Commit();
                end else
                    Error('');

        ConfigXMLExchange.SetHideDialog(HideDialog);
        ConfigXMLExchange.ImportPackageXMLFromStream(InStream);
        Commit();
    end;

    procedure ApplyPackages() ErrorCount: Integer
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackage.Get("Package Code");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageMgt.SetHideDialog(HideDialog);
        ErrorCount := ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);
    end;

    procedure ApplyAnswers()
    var
        ConfigQuestionnaire: Record "Config. Questionnaire";
        ConfigQuestionnaireMgt: Codeunit "Questionnaire Management";
    begin
        if ConfigQuestionnaire.FindSet() then
            repeat
                ConfigQuestionnaireMgt.ApplyAnswers(ConfigQuestionnaire);
            until ConfigQuestionnaire.Next() = 0;
    end;

    procedure CopyCompInfo()
    var
        CompanyInfo: Record "Company Information";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if not CompanyInfo.Get() then begin
            CompanyInfo.Init();
            CompanyInfo.Insert();
        end;
        CompanyInfo.TransferFields(Rec);
        CompanyInfo.Modify();

        if not SalesReceivablesSetup.Get() then begin
            SalesReceivablesSetup.Init();
            SalesReceivablesSetup.Insert();
        end;
        SalesReceivablesSetup."Logo Position on Documents" := "Logo Position on Documents";
        SalesReceivablesSetup.Modify();

        Commit();
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [Scope('OnPrem')]
    procedure DecompressPackage(UploadToServer: Boolean) DecompressedFileName: Text
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        FileMgt: Codeunit "File Management";
    begin
        if UploadToServer then
            DecompressedFileName := ConfigXMLExchange.DecompressPackage(FileMgt.UploadFile(ChooseFileTitleMsg, ''))
        else
            DecompressedFileName := ConfigXMLExchange.DecompressPackage("Package File Name");
    end;

    procedure DecompressPackageToBlob(var TempBlob: Codeunit "Temp Blob"; var TempBlobUncompressed: Codeunit "Temp Blob")
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobUncompressed);
    end;
}
