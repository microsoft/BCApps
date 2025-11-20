// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Bank.Setup;
using Microsoft.CostAccounting.Account;
using Microsoft.CRM.Team;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Payables;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using System.Email;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;


table 5200 Employee
{
    Caption = 'Employee';
    DataCaptionFields = "No.", "First Name", "Middle Name", "Last Name";
    DrillDownPageID = "Employee List";
    LookupPageID = "Employee List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeries.TestManual(HumanResSetup."Employee Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(3; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
        }
        field(4; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(5; Initials; Text[30])
        {
            Caption = 'Initials';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Initials)) or ("Search Name" = '') then
                    "Search Name" := Initials;
            end;
        }
        field(6; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(7; "Search Name"; Code[250])
        {
            Caption = 'Search Name';

            trigger OnValidate()
            begin
                if "Search Name" = '' then
                    "Search Name" := SetSearchNameToFullnameAndInitials();
            end;
        }
        field(8; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(10; City; Text[30])
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
        field(11; "Post Code"; Code[20])
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
            end;
        }
        field(12; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(13; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(14; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(15; "E-Mail"; Text[80])
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
        field(16; "Alt. Address Code"; Code[10])
        {
            Caption = 'Alt. Address Code';
            TableRelation = "Alternative Address".Code where("Employee No." = field("No."));
        }
        field(17; "Alt. Address Start Date"; Date)
        {
            Caption = 'Alt. Address Start Date';
        }
        field(18; "Alt. Address End Date"; Date)
        {
            Caption = 'Alt. Address End Date';
        }
        field(20; "Birth Date"; Date)
        {
            Caption = 'Birth Date';
        }
        field(21; "Social Security No."; Text[30])
        {
            Caption = 'Social Security No.';
        }
        field(22; "Union Code"; Code[10])
        {
            Caption = 'Union Code';
            TableRelation = Union;
        }
        field(23; "Union Membership No."; Text[30])
        {
            Caption = 'Union Membership No.';
        }
        field(24; Gender; Enum "Employee Gender")
        {
            Caption = 'Gender';
        }
        field(25; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(26; "Manager No."; Code[20])
        {
            Caption = 'Manager No.';
            TableRelation = Employee;
        }
        field(27; "Emplymt. Contract Code"; Code[10])
        {
            Caption = 'Emplymt. Contract Code';
            TableRelation = "Employment Contract";
        }
        field(28; "Statistics Group Code"; Code[10])
        {
            Caption = 'Statistics Group Code';
            TableRelation = "Employee Statistics Group";
        }
        field(29; "Employment Date"; Date)
        {
            Caption = 'Employment Date';
        }
        field(31; Status; Enum "Employee Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                Employe: Record Employee;
            begin
                EmployeeQualification.SetRange("Employee No.", "No.");
                EmployeeQualification.ModifyAll("Employee Status", Status);
                if Employe.Get(Rec."No.") then
                    Rec.Modify();
            end;
        }
        field(32; "Inactive Date"; Date)
        {
            Caption = 'Inactive Date';
        }
        field(33; "Cause of Inactivity Code"; Code[10])
        {
            Caption = 'Cause of Inactivity Code';
            TableRelation = "Cause of Inactivity";
        }
        field(34; "Termination Date"; Date)
        {
            Caption = 'Termination Date';
        }
        field(35; "Grounds for Term. Code"; Code[10])
        {
            Caption = 'Grounds for Term. Code';
            TableRelation = "Grounds for Termination";
        }
        field(36; "Global Dimension 1 Code"; Code[20])
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
        field(37; "Global Dimension 2 Code"; Code[20])
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
        field(38; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource where(Type = const(Person));

            trigger OnValidate()
            var
                [SecurityFiltering(SecurityFilter::Ignored)]
                Resource: Record Resource;
            begin
                if ("Resource No." <> '') and Resource.WritePermission then begin
                    CheckIfAnEmployeeIsLinkedToTheResource("Resource No.");
                    EmployeeResUpdate.ResUpdate(Rec);
                end;
            end;
        }
        field(39; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const(Employee),
                                                                     "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(41; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(42; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(43; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(44; "Cause of Absence Filter"; Code[10])
        {
            Caption = 'Cause of Absence Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cause of Absence";
        }
        field(45; "Total Absence (Base)"; Decimal)
        {
            CalcFormula = sum("Employee Absence"."Quantity (Base)" where("Employee No." = field("No."),
                                                                          "Cause of Absence Code" = field("Cause of Absence Filter"),
                                                                          "From Date" = field("Date Filter")));
            Caption = 'Total Absence (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; Extension; Text[30])
        {
            Caption = 'Extension';
        }
        field(47; "Employee No. Filter"; Code[20])
        {
            Caption = 'Employee No. Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
        }
        field(48; Pager; Text[30])
        {
            Caption = 'Pager';
        }
        field(49; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(50; "Company E-Mail"; Text[80])
        {
            Caption = 'Company Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("Company E-Mail");
            end;
        }
        field(51; Title; Text[30])
        {
            Caption = 'Title';
        }
        field(52; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(54; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(55; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            TableRelation = "Employee Posting Group";
        }
        field(56; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(57; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(58; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(59; Balance; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Employee Ledger Entry".Amount where("Employee No." = field("No."),
                                                                              "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                              "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                              "Posting Date" = field("Date Filter"),
                                                                              "Currency Code" = field("Currency Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount the employee owes the company, or the company owes them. For example, for an overpayment, or for expenses, respectively. The word "balance" indicates the amount can be positive (employee owes the company) or negative (the company owes the employee).';
        }
        field(60; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(70; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Employee Ledger Entry"."Amount (LCY)" where("Employee No." = field("No."),
                                                                              "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                              "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                              "Posting Date" = field("Date Filter"),
                                                                              "Currency Code" = field("Currency Filter")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount the employee owes the company, or the company owes them in local currency. For example, for an overpayment, or for expenses, respectively. The word "balance" indicates the amount can be positive (employee owes the company) or negative (the company owes the employee).';
        }
        field(75; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
        }
        field(90; "Currency Filter"; Code[10])
        {
            Caption = 'Currency Filter';
            FieldClass = FlowFilter;
            TableRelation = Currency;
        }
        field(100; "Engagement Type"; Enum "Employee Engagement Type")
        {
            Caption = 'Engagement Type';
        }
        field(101; "Collective Bargain. Agmt. Info"; Boolean)
        {
            Caption = 'Collective Bargaining Agreement Info';
        }
        field(102; "Board Member"; Boolean)
        {
            Caption = 'Board Member';
        }
        field(103; "Manager Role"; Boolean)
        {
            Caption = 'Manager Role';
        }
        field(104; "Payroll"; Decimal)
        {
            Caption = 'Payroll';

            trigger OnValidate()
            begin
                CalcPayrollLCY();
            end;
        }
        field(105; "Payroll Currency Code"; Code[10])
        {
            Caption = 'Payroll Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                CalcPayrollLCY();
            end;
        }
        field(106; "Payroll (LCY)"; Decimal)
        {
            Caption = 'Payroll (LCY)';

            trigger OnValidate()
            begin
                CalcPayroll();
            end;
        }
        field(107; "Payroll Currency Factor"; Decimal)
        {
            Caption = 'Payroll Currency Factor';
        }
        field(108; "Nationality"; Code[10])
        {
            Caption = 'Nationality';
            TableRelation = Nationality;
        }
        field(109; "Working Type"; Enum "Employee Working Type")
        {
            Caption = 'Working Type';
        }
        field(110; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies if multiple posting groups can be used for posting business transactions for this customer.';
        }
        field(1100; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(1101; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";
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
        key(Key3; Status, "Union Code")
        {
        }
        key(Key4; Status, "Emplymt. Contract Code")
        {
        }
        key(Key5; "Last Name", "First Name", "Middle Name")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "First Name", "Last Name", Initials, "Job Title")
        {
        }
        fieldgroup(Brick; "Last Name", "First Name", "Job Title", Image)
        {
        }
    }

    trigger OnDelete()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetCurrentKey("Employee No.", "Posting Date");
        EmployeeLedgerEntry.SetRange("Employee No.", Rec."No.");
        SetEmplLedgEntryFilterByAccPeriod(EmployeeLedgerEntry);
        if not EmployeeLedgerEntry.IsEmpty() then
            Error(EmployeeHasLedgerDeleteErr, Rec."No.");

        AlternativeAddr.SetRange("Employee No.", "No.");
        AlternativeAddr.DeleteAll();

        EmployeeQualification.SetRange("Employee No.", "No.");
        EmployeeQualification.DeleteAll();

        Relative.SetRange("Employee No.", "No.");
        Relative.DeleteAll();

        EmployeeAbsence.SetRange("Employee No.", "No.");
        EmployeeAbsence.DeleteAll();

        MiscArticleInformation.SetRange("Employee No.", "No.");
        MiscArticleInformation.DeleteAll();

        ConfidentialInformation.SetRange("Employee No.", "No.");
        ConfidentialInformation.DeleteAll();

        HumanResComment.SetRange("No.", "No.");
        HumanResComment.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Employee, "No.");
    end;

    trigger OnInsert()
    var
        Employee: Record Employee;
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        "Last Modified Date Time" := CurrentDateTime;
        HumanResSetup.Get();
        if "No." = '' then begin
            HumanResSetup.TestField("Employee Nos.");
            if NoSeries.AreRelated(HumanResSetup."Employee Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := HumanResSetup."Employee Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            Employee.ReadIsolation(IsolationLevel::ReadUncommitted);
            Employee.SetLoadFields("No.");
            while Employee.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
        if HumanResSetup."Automatically Create Resource" then begin
            ResourcesSetup.Get();
            Resource.Init();
            if NoSeries.IsManual(ResourcesSetup."Resource Nos.") then begin
                Resource."No." := "No.";
                Resource.Insert(true);
            end else
                Resource.Insert(true);
            "Resource No." := Resource."No.";
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Employee, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
        UpdateSearchName();
    end;

    trigger OnModify()
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        "Last Modified Date Time" := CurrentDateTime;
        "Last Date Modified" := Today;

        IsHandled := false;
        OnModifyOnBeforeEmployeeResourceUpdate(Rec, xRec, IsHandled);
        if not IsHandled then
            if Resource.ReadPermission() then
                EmployeeResUpdate.HumanResToRes(xRec, Rec);

        IsHandled := false;
        OnModifyOnBeforeEmployeeSalespersonUpdate(Rec, xRec, IsHandled);
        if not IsHandled then
            if SalespersonPurchaser.ReadPermission then
                EmployeeSalespersonUpdate.HumanResToSalesPerson(xRec, Rec);
        UpdateSearchName();
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Employee, xRec."No.", "No.");
        "Last Modified Date Time" := CurrentDateTime;
        "Last Date Modified" := Today;
        UpdateSearchName();
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        PostCode: Record "Post Code";
        AlternativeAddr: Record "Alternative Address";
        EmployeeQualification: Record "Employee Qualification";
        Relative: Record "Employee Relative";
        EmployeeAbsence: Record "Employee Absence";
        MiscArticleInformation: Record "Misc. Article Information";
        ConfidentialInformation: Record "Confidential Information";
        HumanResComment: Record "Human Resource Comment Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GeneralLedgerSetup: Record "General Ledger Setup";
        NoSeries: Codeunit "No. Series";
        EmployeeResUpdate: Codeunit "Employee/Resource Update";
        EmployeeSalespersonUpdate: Codeunit "Employee/Salesperson Update";
        DimMgt: Codeunit DimensionManagement;
        BlockedEmplForJnrlErr: Label 'You cannot create this document because employee %1 is blocked due to privacy.', Comment = '%1 = employee no.';
        BlockedEmplForJnrlPostingErr: Label 'You cannot post this document because employee %1 is blocked due to privacy.', Comment = '%1 = employee no.';
        EmployeeLinkedToResourceErr: Label 'You cannot link multiple employees to the same resource. Employee %1 is already linked to that resource.', Comment = '%1 = employee no.';
        EmployeeHasLedgerDeleteErr: Label 'You cannot delete Employee %1 because it has ledger entries in a fiscal year that has not been closed yet.', Comment = '%1 = employee no.';

    procedure AssistEdit() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        HumanResSetup.Get();
        HumanResSetup.TestField("Employee Nos.");
        if NoSeries.LookupRelatedNoSeries(HumanResSetup."Employee Nos.", xRec."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    procedure FullName(): Text[100]
    var
        NewFullName: Text[100];
        Handled: Boolean;
    begin
        OnBeforeGetFullName(Rec, NewFullName, Handled);
        if Handled then
            exit(NewFullName);

        if "Middle Name" = '' then
            exit("First Name" + ' ' + "Last Name");

        exit("First Name" + ' ' + "Middle Name" + ' ' + "Last Name");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Employee, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Employee, GetPosition());
    end;

    local procedure UpdateSearchName()
    var
        PrevSearchName: Code[250];
    begin
        PrevSearchName := xRec.FullName() + ' ' + xRec.Initials;
        if ((("First Name" <> xRec."First Name") or ("Middle Name" <> xRec."Middle Name") or ("Last Name" <> xRec."Last Name") or
             (Initials <> xRec.Initials)) and ("Search Name" = PrevSearchName))
        then
            "Search Name" := SetSearchNameToFullnameAndInitials();
    end;

    local procedure SetSearchNameToFullnameAndInitials(): Code[250]
    begin
        exit(FullName() + ' ' + Initials);
    end;

    procedure GetBankAccountNo(): Text
    begin
        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    procedure CheckBlockedEmployeeOnJnls(IsPosting: Boolean)
    begin
        if IsOnBeforeCheckBlockedEmployeeHandled(IsPosting) then
            exit;
        if "Privacy Blocked" then begin
            if IsPosting then
                Error(BlockedEmplForJnrlPostingErr, "No.");
            Error(BlockedEmplForJnrlErr, "No.")
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullName(Employee: Record Employee; var NewFullName: Text[100]; var Handled: Boolean)
    begin
    end;

    local procedure CheckIfAnEmployeeIsLinkedToTheResource(ResourceNo: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.SetFilter("No.", '<>%1', "No.");
        Employee.SetRange("Resource No.", ResourceNo);
        if Employee.FindFirst() then
            Error(EmployeeLinkedToResourceErr, Employee."No.");
    end;

    local procedure SetEmplLedgEntryFilterByAccPeriod(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        AccountingPeriod: Record "Accounting Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetEmployeeLedgEntryFilterByAccPeriod(EmployeeLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            EmployeeLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
    end;

    local procedure IsOnBeforeCheckBlockedEmployeeHandled(IsPosting: Boolean) IsHandled: Boolean
    begin
        OnBeforeCheckBlockedEmployee(Rec, IsPosting, IsHandled);
    end;

    local procedure CalcPayrollLCY()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if Rec."Payroll Currency Code" = '' then begin
            Rec."Payroll (LCY)" := Rec."Payroll";
            exit;
        end;

        GeneralLedgerSetup.GetRecordOnce();
        Rec.Validate("Payroll Currency Factor", CurrencyExchangeRate.ExchangeRate(WorkDate(), Rec."Payroll Currency Code"));
        Rec."Payroll (LCY)" := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), Rec."Payroll Currency Code", Rec."Payroll", Rec."Payroll Currency Factor"), GeneralLedgerSetup."Amount Rounding Precision");
    end;

    local procedure CalcPayroll()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if Rec."Payroll Currency Code" = '' then begin
            Rec."Payroll" := Rec."Payroll (LCY)";
            exit;
        end;

        GeneralLedgerSetup.GetRecordOnce();
        Rec.Validate("Payroll Currency Factor", CurrencyExchangeRate.ExchangeRate(WorkDate(), Rec."Payroll Currency Code"));
        Rec."Payroll" := Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(WorkDate(), Rec."Payroll Currency Code", Rec."Payroll (LCY)", Rec."Payroll Currency Factor"), GeneralLedgerSetup."Amount Rounding Precision");
    end;

    procedure CheckAllowMultiplePostingGroups()
    begin
        HumanResSetup.Get();
        if HumanResSetup."Allow Multiple Posting Groups" then
            TestField("Allow Multiple Posting Groups");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Employee: Record Employee; var xEmployee: Record Employee; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Employee: Record Employee; xEmployee: Record Employee; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Employee: Record Employee; var xEmployee: Record Employee; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Employee: Record Employee; var xEmployee: Record Employee; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedEmployee(Employee: Record Employee; IsPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Employee: Record Employee; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Employee: Record Employee; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeEmployeeSalespersonUpdate(var Employee: Record "Employee"; xEmployee: Record "Employee"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeEmployeeResourceUpdate(var Employee: Record "Employee"; xEmployee: Record "Employee"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetEmployeeLedgEntryFilterByAccPeriod(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}
