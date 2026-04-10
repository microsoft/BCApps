// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.Structure;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

table 5135 "Job Archive"
{
    Caption = 'Project Archive';
    DataCaptionFields = "No.", Description, "Version No.";
    DrillDownPageID = "Job Archive List";
    LookupPageID = "Job Archive List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            ToolTip = 'Specifies the additional name for the project. The field is used for searching purposes.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a short description of the project.';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer who pays for the project.';
            TableRelation = Customer;
        }
        field(12; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            ToolTip = 'Specifies the date on which you set up the project.';
            Editable = false;
        }
        field(13; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date on which the project actually starts.';
        }
        field(14; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date on which the project is expected to be completed.';
        }
        field(19; Status; Enum "Job Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies a status for the current project. You can change the status for the project as it progresses. Final calculations can be made on completed projects.';
            InitValue = Open;
        }
        field(20; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            ToolTip = 'Specifies the person at your company who is responsible for the project.';
            TableRelation = Resource where(Type = const(Person));
        }
        field(21; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(22; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(23; "Job Posting Group"; Code[20])
        {
            Caption = 'Project Posting Group';
            ToolTip = 'Specifies the posting group that links transactions made for the project with the appropriate general ledger accounts according to the general posting setup.';
            TableRelation = "Job Posting Group";
        }
        field(24; Blocked; Enum "Job Blocked")
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            ToolTip = 'Specifies when the project card was last modified.';
            Editable = false;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line Archive" where("Table Name" = const(Job),
                                                            "No." = field("No."),
                                                            "Version No." = field("Version No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(32; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(35; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location code of the project.';
            TableRelation = Location where("Use As In-Transit" = const(false));
            DataClassification = CustomerContent;
        }
        field(36; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies a bin code for specific location of the project.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            DataClassification = CustomerContent;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(49; "Scheduled Res. Qty."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Job Planning Line Archive"."Quantity (Base)" where("Job No." = field("No."),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "No." = field("Resource Filter"),
                                                                           "Planning Date" = field("Planning Date Filter"),
                                                                           "Version No." = field("Version No.")));
            Caption = 'Scheduled Res. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(51; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(55; "Resource Gr. Filter"; Code[20])
        {
            Caption = 'Resource Gr. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(56; "Scheduled Res. Gr. Qty."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Job Planning Line Archive"."Quantity (Base)" where("Job No." = field("No."),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "Resource Group No." = field("Resource Gr. Filter"),
                                                                           "Planning Date" = field("Planning Date Filter"),
                                                                           "Version No." = field("Version No.")));
            Caption = 'Scheduled Res. Gr. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer who pays for the project.';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(59; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
        }
        field(60; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies an additional line of the address.';
        }
        field(61; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            ToolTip = 'Specifies the city of the address.';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(63; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            ToolTip = 'Specifies the county code of the customer''s billing address.';
        }
        field(64; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            ToolTip = 'Specifies the postal code of the customer who pays for the project.';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(67; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s billing address.';
            Editable = true;
            TableRelation = "Country/Region";
        }
        field(68; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who pays for the project.';
        }
        field(80; "Task Billing Method"; Enum "Task Billing Method")
        {
            Caption = 'Task Billing Method';
            DataClassification = CustomerContent;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ToolTip = 'Specifies the telephone number of the company''s shipping address.';
            ExtendedDatatype = PhoneNo;
        }
        field(1000; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            ToolTip = 'Specifies the method that is used to calculate the value of work in process for the project.';
            TableRelation = "Job WIP Method".Code where(Valid = const(true));
        }
        field(1001; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code for the project. By default, the currency code is empty. If you enter a foreign currency code, it results in the project being planned and invoiced in that currency.';
            TableRelation = Currency;
        }
        field(1002; "Bill-to Contact No."; Code[20])
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
        }
        field(1003; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer who pays for the project.';
        }
        field(1004; "Planning Date Filter"; Date)
        {
            Caption = 'Planning Date Filter';
            FieldClass = FlowFilter;
        }
        field(1008; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            Editable = false;
        }
        field(1011; "Invoice Currency Code"; Code[10])
        {
            Caption = 'Invoice Currency Code';
            ToolTip = 'Specifies the currency code you want to apply when creating invoices for a project. By default, the invoice currency code for a project is based on what currency code is defined on the customer card.';
            TableRelation = Currency;
        }
        field(1012; "Exch. Calculation (Cost)"; Option)
        {
            Caption = 'Exch. Calculation (Cost)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1013; "Exch. Calculation (Price)"; Option)
        {
            Caption = 'Exch. Calculation (Price)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1014; "Allow Schedule/Contract Lines"; Boolean)
        {
            Caption = 'Allow Budget/Billable Lines';
            ToolTip = 'Specifies if you can add planning lines of both type Budget and type Billable to the project.';
        }
        field(1015; Complete; Boolean)
        {
            Caption = 'Complete';
        }
        field(1024; "Next Invoice Date"; Date)
        {
            CalcFormula = min("Job Planning Line Archive"."Planning Date" where("Job No." = field("No."),
                                                                         "Version No." = field("Version No."),
                                                                         "Contract Line" = const(true),
                                                                         "Qty. to Invoice" = filter(<> 0)));
            Caption = 'Next Invoice Date';
            ToolTip = 'Specifies the next invoice date for the project.';
            FieldClass = FlowField;
        }
        field(1025; "Apply Usage Link"; Boolean)
        {
            Caption = 'Apply Usage Link';
            ToolTip = 'Specifies whether usage entries, from the project journal or purchase line, for example, are linked to project planning lines. Select this check box if you want to be able to track the quantities and amounts of the remaining work needed to complete a project and to create a relationship between demand planning, usage, and sales. On a project card, you can select this check box if there are no existing project planning lines that include type Budget that have been posted. The usage link only applies to project planning lines that include type Budget.';
        }
        field(1027; "WIP Posting Method"; Option)
        {
            Caption = 'WIP Posting Method';
            ToolTip = 'Specifies how WIP posting is performed. Per Project: The total WIP costs and the sales value is used to calculate WIP. Per Project Ledger Entry: The accumulated values of WIP costs and sales are used to calculate WIP.';
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(1030; "Calc. Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("Job Task Archive"."Recognized Sales Amount" where("Job No." = field("No."),
                                                                        "Version No." = field("Version No.")));
            Caption = 'Calc. Recog. Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1031; "Calc. Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("Job Task Archive"."Recognized Costs Amount" where("Job No." = field("No."),
                                                                                "Version No." = field("Version No.")));
            Caption = 'Calc. Recog. Costs Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1032; "Calc. Recog. Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("Job Task Archive"."Recognized Sales G/L Amount" where("Job No." = field("No."),
                                                                                    "Version No." = field("Version No.")));
            Caption = 'Calc. Recog. Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1033; "Calc. Recog. Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("Job Task Archive"."Recognized Costs G/L Amount" where("Job No." = field("No."),
                                                                                    "Version No." = field("Version No.")));
            Caption = 'Calc. Recog. Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1035; "Over Budget"; Boolean)
        {
            Caption = 'Over Budget';
        }
        field(1036; "Project Manager"; Code[50])
        {
            Caption = 'Project Manager';
            ToolTip = 'Specifies the person who is assigned to manage the project.';
            TableRelation = "User Setup";
        }
        field(2000; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';
            TableRelation = Customer;
        }
        field(2001; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer who will receive the products and be billed by default.';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(2002; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        field(2003; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
            ToolTip = 'Specifies the address where the customer is located.';
        }
        field(2004; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(2005; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(2006; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            ToolTip = 'Specifies the name of the person to contact at the customer.';
        }
        field(2007; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(2008; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            ToolTip = 'Specifies the state, province or county of the address.';
        }
        field(2009; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the address.';
            TableRelation = "Country/Region";
        }
        field(2010; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(2011; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        field(2012; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            ToolTip = 'Specifies the number of the contact person that the sales document will be sent to.';
            TableRelation = Contact;
        }
        field(3000; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies the code for another shipment address than the customer''s own address, which is entered by default.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        field(3001; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name that products on the sales document will be shipped to.';
        }
        field(3002; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name that products on the sales document will be shipped to.';
        }
        field(3003; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that products on the sales document will be shipped to.';
        }
        field(3004; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(3005; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(3006; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the contact person at the address that products on the sales document will be shipped to.';
        }
        field(3007; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(3008; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            ToolTip = 'Specifies the state, province or county of the address.';
        }
        field(3009; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the customer''s country/region.';
            TableRelation = "Country/Region";
        }
        field(3997; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Job Archive"."Version No." where("No." = field("No.")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3998; "Source Doc. Exists"; Boolean)
        {
            FieldClass = Flowfield;
            CalcFormula = exist(Job where("No." = field("No.")));
            Caption = 'Source Doc. Exists';
            Editable = false;
        }
        field(3999; "Last Archived Date"; DateTime)
        {
            Caption = 'Last Archived Date';
            FieldClass = FlowField;
            CalcFormula = max("Job Archive".SystemCreatedAt where("No." = field("No.")));
            Editable = false;
        }
        field(4000; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(4001; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(4002; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(4003; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
        }
        field(5043; "Interaction Exist"; Boolean)
        {
            Caption = 'Interaction Exist';
            ToolTip = 'Specifies that the archived document is linked to an interaction log entry.';
        }
        field(5044; "Time Archived"; Time)
        {
            Caption = 'Time Archived';
            ToolTip = 'Specifies what time the document was archived.';
        }
        field(5045; "Date Archived"; Date)
        {
            Caption = 'Date Archived';
            ToolTip = 'Specifies the date when the document was archived.';
        }
        field(5046; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
            ToolTip = 'Specifies the user ID of the person who archived this document.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the version number of the archived document.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the default method of the unit price calculation.';
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';
            ToolTip = 'Specifies the default method of the unit cost calculation.';
        }
        field(7300; "Completely Picked"; Boolean)
        {
            CalcFormula = min("Job Planning Line Archive"."Completely Picked" where("Job No." = field("No.")));
            Caption = 'Completely Picked';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.", "Version No.")
        {
            Clustered = true;
        }
        key(Key2; "Bill-to Customer No.")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Version No.", Description, "Bill-to Customer No.", "Starting Date", Status)
        {
        }
        fieldgroup(Brick; "No.", "Version No.", Description, "Bill-to Customer No.", "Starting Date", Status, Image)
        {
        }
    }

    trigger OnDelete()
    var
        JobTaskArchive: Record "Job Task Archive";
        CommentLineArchive: Record "Comment Line Archive";
    begin
        JobTaskArchive.SetRange("Job No.", "No.");
        JobTaskArchive.SetRange("Version No.", "Version No.");
        JobTaskArchive.DeleteAll(true);

        CommentLineArchive.SetRange("Table Name", CommentLineArchive."Table Name"::Job);
        CommentLineArchive.SetRange("No.", "No.");
        CommentLineArchive.SetRange("Version No.", "Version No.");
        CommentLineArchive.DeleteAll();
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Job, GetPosition());
    end;

    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    procedure ShipToNameEqualsSellToName(): Boolean
    begin
        exit(
            (Rec."Ship-to Name" = Rec."Sell-to Customer Name") and
            (Rec."Ship-to Name 2" = Rec."Sell-to Customer Name 2")
        );
    end;

    procedure ShipToAddressEqualsSellToAddress() Result: Boolean
    begin
        Result :=
          ("Sell-to Address" = "Ship-to Address") and
          ("Sell-to Address 2" = "Ship-to Address 2") and
          ("Sell-to City" = "Ship-to City") and
          ("Sell-to County" = "Ship-to County") and
          ("Sell-to Post Code" = "Ship-to Post Code") and
          ("Sell-to Country/Region Code" = "Ship-to Country/Region Code") and
          ("Sell-to Contact" = "Ship-to Contact");

        OnAfterShipToAddressEqualsSellToAddress(Rec, Result);
    end;

    procedure BillToAddressEqualsSellToAddress(): Boolean
    begin
        if ("Sell-to Address" = "Bill-to Address") and
           ("Sell-to Address 2" = "Bill-to Address 2") and
           ("Sell-to City" = "Bill-to City") and
           ("Sell-to County" = "Bill-to County") and
           ("Sell-to Post Code" = "Bill-to Post Code") and
           ("Sell-to Country/Region Code" = "Bill-to Country/Region Code") and
           ("Sell-to Contact No." = "Bill-to Contact No.") and
           ("Sell-to Contact" = "Bill-to Contact")
        then
            exit(true);
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipToAddressEqualsSellToAddress(var JobArchive: Record "Job Archive"; var Result: Boolean)
    begin
    end;
}
