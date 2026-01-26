// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;
using System.Utilities;

report 11514 "G/L Setup Information"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/GLSetupInformation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Setup Information';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Title; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_Layout_; Format(Layout))
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(LayoutInt; LayoutInt)
            {
            }
            column(Title_Number; Number)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Setup_InformationCaption; Setup_InformationCaptionLbl)
            {
            }
            dataitem("General Ledger Setup"; "General Ledger Setup")
            {
                DataItemTableView = sorting("Primary Key");
                column(General_Ledger_Setup__Appln__Rounding_Precision_; "Appln. Rounding Precision")
                {
                }
                column(General_Ledger_Setup__Amount_Rounding_Precision_; "Amount Rounding Precision")
                {
                }
                column(General_Ledger_Setup__Unit_Amount_Rounding_Precision_; "Unit-Amount Rounding Precision")
                {
                }
                column(General_Ledger_Setup__LCY_Code_; "LCY Code")
                {
                }
                column(General_Ledger_Setup__VAT_Exchange_Rate_Adjustment_; "VAT Exchange Rate Adjustment")
                {
                }
                column(General_Ledger_Setup__VAT_Tolerance___; "VAT Tolerance %")
                {
                }
                column(General_Ledger_Setup__EMU_Currency_; "EMU Currency")
                {
                }
                column(General_Ledger_Setup__Additional_Reporting_Currency_; "Additional Reporting Currency")
                {
                }
                column(General_Ledger_Setup__Unit_Amount_Decimal_Places_; "Unit-Amount Decimal Places")
                {
                }
                column(General_Ledger_Setup__Summarize_G_L_Entries_; "Summarize G/L Entries")
                {
                }
                column(General_Ledger_Setup__Amount_Decimal_Places_; "Amount Decimal Places")
                {
                }
                column(General_Ledger_Setup__Bank_Account_Nos__; "Bank Account Nos.")
                {
                }
                column(General_Ledger_Setup__Local_Cont__Addr__Format_; "Local Cont. Addr. Format")
                {
                }
                column(General_Ledger_Setup__Inv__Rounding_Precision__LCY__; "Inv. Rounding Precision (LCY)")
                {
                }
                column(General_Ledger_Setup__Inv__Rounding_Type__LCY__; "Inv. Rounding Type (LCY)")
                {
                }
                column(General_Ledger_Setup__Local_Address_Format_; "Local Address Format")
                {
                }
                column(General_Ledger_Setup__Mark_Cr__Memos_as_Corrections_; "Mark Cr. Memos as Corrections")
                {
                }
                column(General_Ledger_Setup__Adjust_for_Payment_Disc__; "Adjust for Payment Disc.")
                {
                }
                column(General_Ledger_Setup__Unrealized_VAT_; "Unrealized VAT")
                {
                }
                column(General_Ledger_Setup__Pmt__Disc__Excl__VAT_; "Pmt. Disc. Excl. VAT")
                {
                }
                column(General_Ledger_Setup__Allow_Posting_To_; Format("Allow Posting To"))
                {
                }
                column(General_Ledger_Setup__Allow_Posting_From_; Format("Allow Posting From"))
                {
                }
                column(General_Ledger_Setup__Max__VAT_Difference_Allowed_; "Max. VAT Difference Allowed")
                {
                }
                column(General_Ledger_Setup__VAT_Rounding_Type_; "VAT Rounding Type")
                {
                }
                column(General_Ledger_Setup__Global_Dimension_1_Code_; "Global Dimension 1 Code")
                {
                }
                column(General_Ledger_Setup__Global_Dimension_2_Code_; "Global Dimension 2 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_1_Code_; "Shortcut Dimension 1 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_2_Code_; "Shortcut Dimension 2 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_3_Code_; "Shortcut Dimension 3 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_4_Code_; "Shortcut Dimension 4 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_5_Code_; "Shortcut Dimension 5 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_6_Code_; "Shortcut Dimension 6 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_7_Code_; "Shortcut Dimension 7 Code")
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_8_Code_; "Shortcut Dimension 8 Code")
                {
                }
                column(General_Ledger_Setup_Primary_Key; "Primary Key")
                {
                }
                column(General_Ledger_Setup__Summarize_G_L_Entries_Caption; FieldCaption("Summarize G/L Entries"))
                {
                }
                column(General_Ledger_Setup__Amount_Decimal_Places_Caption; FieldCaption("Amount Decimal Places"))
                {
                }
                column(General_Ledger_Setup__Unit_Amount_Decimal_Places_Caption; FieldCaption("Unit-Amount Decimal Places"))
                {
                }
                column(General_Ledger_Setup__Additional_Reporting_Currency_Caption; FieldCaption("Additional Reporting Currency"))
                {
                }
                column(General_Ledger_Setup__VAT_Tolerance___Caption; FieldCaption("VAT Tolerance %"))
                {
                }
                column(General_Ledger_Setup__EMU_Currency_Caption; FieldCaption("EMU Currency"))
                {
                }
                column(General_Ledger_Setup__LCY_Code_Caption; FieldCaption("LCY Code"))
                {
                }
                column(General_Ledger_Setup__VAT_Exchange_Rate_Adjustment_Caption; FieldCaption("VAT Exchange Rate Adjustment"))
                {
                }
                column(General_Ledger_Setup__Amount_Rounding_Precision_Caption; FieldCaption("Amount Rounding Precision"))
                {
                }
                column(General_Ledger_Setup__Unit_Amount_Rounding_Precision_Caption; FieldCaption("Unit-Amount Rounding Precision"))
                {
                }
                column(General_Ledger_Setup__Appln__Rounding_Precision_Caption; FieldCaption("Appln. Rounding Precision"))
                {
                }
                column(General_Ledger_Setup__Bank_Account_Nos__Caption; FieldCaption("Bank Account Nos."))
                {
                }
                column(General_Ledger_Setup__Local_Cont__Addr__Format_Caption; FieldCaption("Local Cont. Addr. Format"))
                {
                }
                column(General_Ledger_Setup__Inv__Rounding_Precision__LCY__Caption; FieldCaption("Inv. Rounding Precision (LCY)"))
                {
                }
                column(General_Ledger_Setup__Inv__Rounding_Type__LCY__Caption; FieldCaption("Inv. Rounding Type (LCY)"))
                {
                }
                column(General_Ledger_Setup__Local_Address_Format_Caption; FieldCaption("Local Address Format"))
                {
                }
                column(General_Ledger_Setup__Mark_Cr__Memos_as_Corrections_Caption; FieldCaption("Mark Cr. Memos as Corrections"))
                {
                }
                column(General_Ledger_Setup__Adjust_for_Payment_Disc__Caption; FieldCaption("Adjust for Payment Disc."))
                {
                }
                column(General_Ledger_Setup__Unrealized_VAT_Caption; FieldCaption("Unrealized VAT"))
                {
                }
                column(General_Ledger_Setup__Pmt__Disc__Excl__VAT_Caption; FieldCaption("Pmt. Disc. Excl. VAT"))
                {
                }
                column(General_Ledger_Setup__Allow_Posting_To_Caption; General_Ledger_Setup__Allow_Posting_To_CaptionLbl)
                {
                }
                column(General_Ledger_Setup__Allow_Posting_From_Caption; General_Ledger_Setup__Allow_Posting_From_CaptionLbl)
                {
                }
                column(G_L_SetupCaption; G_L_SetupCaptionLbl)
                {
                }
                column(GeneralCaption; GeneralCaptionLbl)
                {
                }
                column(VATCaption; VATCaptionLbl)
                {
                }
                column(RoundingCaption; RoundingCaptionLbl)
                {
                }
                column(CurrencyCaption; CurrencyCaptionLbl)
                {
                }
                column(General_Ledger_Setup__Max__VAT_Difference_Allowed_Caption; FieldCaption("Max. VAT Difference Allowed"))
                {
                }
                column(General_Ledger_Setup__VAT_Rounding_Type_Caption; FieldCaption("VAT Rounding Type"))
                {
                }
                column(DimensionsCaption; DimensionsCaptionLbl)
                {
                }
                column(General_Ledger_Setup__Global_Dimension_1_Code_Caption; FieldCaption("Global Dimension 1 Code"))
                {
                }
                column(General_Ledger_Setup__Global_Dimension_2_Code_Caption; FieldCaption("Global Dimension 2 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_1_Code_Caption; FieldCaption("Shortcut Dimension 1 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_2_Code_Caption; FieldCaption("Shortcut Dimension 2 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_3_Code_Caption; FieldCaption("Shortcut Dimension 3 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_4_Code_Caption; FieldCaption("Shortcut Dimension 4 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_5_Code_Caption; FieldCaption("Shortcut Dimension 5 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_6_Code_Caption; FieldCaption("Shortcut Dimension 6 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_7_Code_Caption; FieldCaption("Shortcut Dimension 7 Code"))
                {
                }
                column(General_Ledger_Setup__Shortcut_Dimension_8_Code_Caption; FieldCaption("Shortcut Dimension 8 Code"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Layout <> Layout::"General Info" then
                        CurrReport.Break();
                end;
            }
            dataitem("Company Information"; "Company Information")
            {
                DataItemTableView = sorting("Primary Key");
                column(Company_Information__E_Mail_; "E-Mail")
                {
                }
                column(Company_Information__Home_Page_; "Home Page")
                {
                }
                column(Company_Information__Ship_to_County_; "Ship-to County")
                {
                }
                column(Company_Information__Ship_to_Post_Code_; "Ship-to Post Code")
                {
                }
                column(Company_Information_County; County)
                {
                }
                column(Company_Information__Location_Code_; "Location Code")
                {
                }
                column(Company_Information__Post_Code_; "Post Code")
                {
                }
                column(Company_Information__Ship_to_Contact_; "Ship-to Contact")
                {
                }
                column(Company_Information__Ship_to_Address_; "Ship-to Address")
                {
                }
                column(Company_Information__Ship_to_Address_2_; "Ship-to Address 2")
                {
                }
                column(Company_Information__Ship_to_City_; "Ship-to City")
                {
                }
                column(Company_Information__Ship_to_Name_; "Ship-to Name")
                {
                }
                column(Company_Information__Ship_to_Name_2_; "Ship-to Name 2")
                {
                }
                column(Company_Information__Customs_Permit_Date_; Format("Customs Permit Date"))
                {
                }
                column(Company_Information__VAT_Registration_No__; "VAT Registration No.")
                {
                }
                column(Company_Information__Payment_Routing_No__; "Payment Routing No.")
                {
                }
                column(Company_Information__Customs_Permit_No__; "Customs Permit No.")
                {
                }
                column(Company_Information__Bank_Account_No__; "Bank Account No.")
                {
                }
                column(Company_Information__Bank_Branch_No__; "Bank Branch No.")
                {
                }
                column(Company_Information__Giro_No__; "Giro No.")
                {
                }
                column(Company_Information__Bank_Name_; "Bank Name")
                {
                }
                column(Company_Information__Fax_No__; "Fax No.")
                {
                }
                column(Company_Information__Telex_No__; "Telex No.")
                {
                }
                column(Company_Information__Phone_No__2_; "Phone No. 2")
                {
                }
                column(Company_Information_City; City)
                {
                }
                column(Company_Information__Phone_No__; "Phone No.")
                {
                }
                column(Company_Information__Address_2_; "Address 2")
                {
                }
                column(Company_Information__Name_2_; "Name 2")
                {
                }
                column(Company_Information_Address; Address)
                {
                }
                column(Company_Information_Name; Name)
                {
                }
                column(Company_Information_Primary_Key; "Primary Key")
                {
                }
                column(Company_Information__Name_2_Caption; FieldCaption("Name 2"))
                {
                }
                column(Company_Information_AddressCaption; FieldCaption(Address))
                {
                }
                column(Company_Information__Address_2_Caption; FieldCaption("Address 2"))
                {
                }
                column(Company_Information__Phone_No__Caption; FieldCaption("Phone No."))
                {
                }
                column(Company_Information__Phone_No__2_Caption; FieldCaption("Phone No. 2"))
                {
                }
                column(Company_Information__Telex_No__Caption; FieldCaption("Telex No."))
                {
                }
                column(Company_Information__Fax_No__Caption; FieldCaption("Fax No."))
                {
                }
                column(Company_Information__Giro_No__Caption; FieldCaption("Giro No."))
                {
                }
                column(Company_Information__Bank_Name_Caption; FieldCaption("Bank Name"))
                {
                }
                column(Company_Information__Bank_Branch_No__Caption; FieldCaption("Bank Branch No."))
                {
                }
                column(Company_Information__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
                {
                }
                column(Company_Information__Payment_Routing_No__Caption; FieldCaption("Payment Routing No."))
                {
                }
                column(Company_Information__Customs_Permit_No__Caption; FieldCaption("Customs Permit No."))
                {
                }
                column(Company_Information__Customs_Permit_Date_Caption; Company_Information__Customs_Permit_Date_CaptionLbl)
                {
                }
                column(Company_Information__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(Company_Information__Ship_to_Name_Caption; FieldCaption("Ship-to Name"))
                {
                }
                column(Company_Information__Ship_to_Name_2_Caption; FieldCaption("Ship-to Name 2"))
                {
                }
                column(Company_Information__Ship_to_Address_Caption; FieldCaption("Ship-to Address"))
                {
                }
                column(Company_Information__Ship_to_Address_2_Caption; FieldCaption("Ship-to Address 2"))
                {
                }
                column(Company_Information__Ship_to_Contact_Caption; FieldCaption("Ship-to Contact"))
                {
                }
                column(Company_Information__Location_Code_Caption; FieldCaption("Location Code"))
                {
                }
                column(Post_Code___CityCaption; Post_Code___CityCaptionLbl)
                {
                }
                column(Company_Information_CountyCaption; FieldCaption(County))
                {
                }
                column(Shipment_Post_Code___CityCaption; Shipment_Post_Code___CityCaptionLbl)
                {
                }
                column(Company_Information__Ship_to_County_Caption; FieldCaption("Ship-to County"))
                {
                }
                column(Company_Information__Home_Page_Caption; FieldCaption("Home Page"))
                {
                }
                column(Company_Information__E_Mail_Caption; FieldCaption("E-Mail"))
                {
                }
                column(Company_Information_NameCaption; FieldCaption(Name))
                {
                }
                column(Company_DataCaption; Company_DataCaptionLbl)
                {
                }
                column(Company_AddressCaption; Company_AddressCaptionLbl)
                {
                }
                column(Shipment_AddressCaption; Shipment_AddressCaptionLbl)
                {
                }
                column(CommunicationCaption; CommunicationCaptionLbl)
                {
                }
                column(PaymentsCaption; PaymentsCaptionLbl)
                {
                }
                column(Customs_and_VATCaption; Customs_and_VATCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"General Info" then
                        CurrReport.Break();
                end;
            }
            dataitem("Business Unit"; "Business Unit")
            {
                DataItemTableView = sorting(Code);
                column(Business_Unit_Code; Code)
                {
                }
                column(Business_Unit_Consolidate; Consolidate)
                {
                }
                column(Business_Unit__Consolidation___; "Consolidation %")
                {
                }
                column(Business_Unit__Starting_Date_; "Starting Date")
                {
                }
                column(Business_Unit__Ending_Date_; "Ending Date")
                {
                }
                column(ROUND__Income_Currency_Factor__0_0001_; Round("Income Currency Factor", 0.0001))
                {
                }
                column(ROUND__Balance_Currency_Factor__0_0001_; Round("Balance Currency Factor", 0.0001))
                {
                }
                column(Business_Unit__Exch__Rate_Losses_Acc__; "Exch. Rate Losses Acc.")
                {
                }
                column(Business_Unit__Exch__Rate_Gains_Acc__; "Exch. Rate Gains Acc.")
                {
                }
                column(Business_Unit__Residual_Account_; "Residual Account")
                {
                }
                column(ROUND__Last_Balance_Currency_Factor__0_0001_; Round("Last Balance Currency Factor", 0.0001))
                {
                }
                column(Business_Unit__Company_Name_; "Company Name")
                {
                }
                column(Business_Unit__Currency_Code_; "Currency Code")
                {
                }
                column(Consolidation_CompaniesCaption; Consolidation_CompaniesCaptionLbl)
                {
                }
                column(Business_Unit__Residual_Account_Caption; Business_Unit__Residual_Account_CaptionLbl)
                {
                }
                column(Business_Unit__Exch__Rate_Gains_Acc__Caption; Business_Unit__Exch__Rate_Gains_Acc__CaptionLbl)
                {
                }
                column(Business_Unit__Exch__Rate_Losses_Acc__Caption; Business_Unit__Exch__Rate_Losses_Acc__CaptionLbl)
                {
                }
                column(ROUND__Balance_Currency_Factor__0_0001_Caption; ROUND__Balance_Currency_Factor__0_0001_CaptionLbl)
                {
                }
                column(ROUND__Income_Currency_Factor__0_0001_Caption; ROUND__Income_Currency_Factor__0_0001_CaptionLbl)
                {
                }
                column(Business_Unit__Ending_Date_Caption; Business_Unit__Ending_Date_CaptionLbl)
                {
                }
                column(Business_Unit__Starting_Date_Caption; Business_Unit__Starting_Date_CaptionLbl)
                {
                }
                column(Business_Unit__Consolidation___Caption; Business_Unit__Consolidation___CaptionLbl)
                {
                }
                column(Business_Unit_ConsolidateCaption; FieldCaption(Consolidate))
                {
                }
                column(Business_Unit_CodeCaption; FieldCaption(Code))
                {
                }
                column(ROUND__Last_Balance_Currency_Factor__0_0001_Caption; ROUND__Last_Balance_Currency_Factor__0_0001_CaptionLbl)
                {
                }
                column(Business_Unit__Currency_Code_Caption; Business_Unit__Currency_Code_CaptionLbl)
                {
                }
                column(Business_Unit__Company_Name_Caption; FieldCaption("Company Name"))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"General Info" then
                        CurrReport.Break();
                end;
            }
            dataitem("Customer Posting Group"; "Customer Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Customer_Posting_Group_Code; Code)
                {
                }
                column(Customer_Posting_Group__Receivables_Account_; "Receivables Account")
                {
                }
                column(Customer_Posting_Group__Service_Charge_Acc__; "Service Charge Acc.")
                {
                }
                column(Customer_Posting_Group__Payment_Disc__Debit_Acc__; "Payment Disc. Debit Acc.")
                {
                }
                column(Customer_Posting_Group__Invoice_Rounding_Account_; "Invoice Rounding Account")
                {
                }
                column(Customer_Posting_Group__Additional_Fee_Account_; "Additional Fee Account")
                {
                }
                column(Customer_Posting_Group__Interest_Account_; "Interest Account")
                {
                }
                column(Customer_Posting_Group__Debit_Curr__Appln__Rndg__Acc__; "Debit Curr. Appln. Rndg. Acc.")
                {
                }
                column(Customer_Posting_GroupsCaption; Customer_Posting_GroupsCaptionLbl)
                {
                }
                column(Customer_Posting_Group__Payment_Disc__Debit_Acc__Caption; Customer_Posting_Group__Payment_Disc__Debit_Acc__CaptionLbl)
                {
                }
                column(Customer_Posting_Group__Invoice_Rounding_Account_Caption; Customer_Posting_Group__Invoice_Rounding_Account_CaptionLbl)
                {
                }
                column(Customer_Posting_Group__Additional_Fee_Account_Caption; FieldCaption("Additional Fee Account"))
                {
                }
                column(Customer_Posting_Group__Interest_Account_Caption; FieldCaption("Interest Account"))
                {
                }
                column(Customer_Posting_Group__Debit_Curr__Appln__Rndg__Acc__Caption; Customer_Posting_Group__Debit_Curr__Appln__Rndg__Acc__CaptionLbl)
                {
                }
                column(Customer_Posting_Group__Service_Charge_Acc__Caption; Customer_Posting_Group__Service_Charge_Acc__CaptionLbl)
                {
                }
                column(Customer_Posting_Group__Receivables_Account_Caption; Customer_Posting_Group__Receivables_Account_CaptionLbl)
                {
                }
                column(Customer_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Groups" then
                        CurrReport.Break();
                end;
            }
            dataitem("Vendor Posting Group"; "Vendor Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Vendor_Posting_Group_Code; Code)
                {
                }
                column(Vendor_Posting_Group__Payables_Account_; "Payables Account")
                {
                }
                column(Vendor_Posting_Group__Service_Charge_Acc__; "Service Charge Acc.")
                {
                }
                column(Vendor_Posting_Group__Payment_Disc__Debit_Acc__; "Payment Disc. Debit Acc.")
                {
                }
                column(Vendor_Posting_Group__Invoice_Rounding_Account_; "Invoice Rounding Account")
                {
                }
                column(Vendor_Posting_Group__Debit_Curr__Appln__Rndg__Acc__; "Debit Curr. Appln. Rndg. Acc.")
                {
                }
                column(Vendor_Posting_GroupsCaption; Vendor_Posting_GroupsCaptionLbl)
                {
                }
                column(Vendor_Posting_Group__Service_Charge_Acc__Caption; Vendor_Posting_Group__Service_Charge_Acc__CaptionLbl)
                {
                }
                column(Vendor_Posting_Group__Payment_Disc__Debit_Acc__Caption; Vendor_Posting_Group__Payment_Disc__Debit_Acc__CaptionLbl)
                {
                }
                column(Vendor_Posting_Group__Invoice_Rounding_Account_Caption; Vendor_Posting_Group__Invoice_Rounding_Account_CaptionLbl)
                {
                }
                column(Vendor_Posting_Group__Debit_Curr__Appln__Rndg__Acc__Caption; Vendor_Posting_Group__Debit_Curr__Appln__Rndg__Acc__CaptionLbl)
                {
                }
                column(Vendor_Posting_Group__Payables_Account_Caption; Vendor_Posting_Group__Payables_Account_CaptionLbl)
                {
                }
                column(Vendor_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Groups" then
                        CurrReport.Break();
                end;
            }
            dataitem("Inventory Posting Group"; "Inventory Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Inventory_Posting_Group_Code; Code)
                {
                }
                column(Inventory_Posting_Group_Description; Description)
                {
                }
                column(Inventory_Posting_GroupsCaption; Inventory_Posting_GroupsCaptionLbl)
                {
                }
                column(Inventory_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }
                column(Inventory_Posting_Group_DescriptionCaption; FieldCaption(Description))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Groups" then
                        CurrReport.Break();
                end;
            }
            dataitem("Bank Account Posting Group"; "Bank Account Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Bank_Account_Posting_Group_Code; Code)
                {
                }
                column(Bank_Account_Posting_Group__G_L_Bank_Account_No__; "G/L Account No.")
                {
                }
                column(Bank_Posting_GroupsCaption; Bank_Posting_GroupsCaptionLbl)
                {
                }
                column(Bank_Account_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }
                column(Bank_Account_Posting_Group__G_L_Bank_Account_No__Caption; Bank_Account_Posting_Group__G_L_Bank_Account_No__CaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Groups" then
                        CurrReport.Break();
                end;
            }
            dataitem("Gen. Business Posting Group"; "Gen. Business Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Gen__Business_Posting_Group_Code; Code)
                {
                }
                column(Gen__Business_Posting_Group_Description; Description)
                {
                }
                column(Gen__Business_Posting_Group__Def__VAT_Bus__Posting_Group_; "Def. VAT Bus. Posting Group")
                {
                }
                column(Gen__Business_Posting_Group__Auto_Insert_Default_; "Auto Insert Default")
                {
                }
                column(Gen__Business_Posting_GroupsCaption; Gen__Business_Posting_GroupsCaptionLbl)
                {
                }
                column(Gen__Business_Posting_Group__Auto_Insert_Default_Caption; Gen__Business_Posting_Group__Auto_Insert_Default_CaptionLbl)
                {
                }
                column(Gen__Business_Posting_Group__Def__VAT_Bus__Posting_Group_Caption; FieldCaption("Def. VAT Bus. Posting Group"))
                {
                }
                column(Gen__Business_Posting_Group_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Gen__Business_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Matrix" then
                        CurrReport.Break();
                end;
            }
            dataitem("Gen. Product Posting Group"; "Gen. Product Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(Gen__Product_Posting_Group_Code; Code)
                {
                }
                column(Gen__Product_Posting_Group_Description; Description)
                {
                }
                column(Gen__Product_Posting_Group__Def__VAT_Prod__Posting_Group_; "Def. VAT Prod. Posting Group")
                {
                }
                column(Gen__Product_Posting_Group__Auto_Insert_Default_; "Auto Insert Default")
                {
                }
                column(Gen__Product_Posting_GroupsCaption; Gen__Product_Posting_GroupsCaptionLbl)
                {
                }
                column(Gen__Product_Posting_Group__Auto_Insert_Default_Caption; Gen__Product_Posting_Group__Auto_Insert_Default_CaptionLbl)
                {
                }
                column(Gen__Product_Posting_Group__Def__VAT_Prod__Posting_Group_Caption; FieldCaption("Def. VAT Prod. Posting Group"))
                {
                }
                column(Gen__Product_Posting_Group_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Gen__Product_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Matrix" then
                        CurrReport.Break();
                end;
            }
            dataitem("General Posting Setup"; "General Posting Setup")
            {
                DataItemTableView = sorting("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                column(General_Posting_Setup__Gen__Bus__Posting_Group_; "Gen. Bus. Posting Group")
                {
                }
                column(General_Posting_Setup__Gen__Prod__Posting_Group_; "Gen. Prod. Posting Group")
                {
                }
                column(General_Posting_Setup__Sales_Account_; "Sales Account")
                {
                }
                column(General_Posting_Setup__Sales_Line_Disc__Account_; "Sales Line Disc. Account")
                {
                }
                column(General_Posting_Setup__Sales_Inv__Disc__Account_; "Sales Inv. Disc. Account")
                {
                }
                column(General_Posting_Setup__Sales_Pmt__Disc__Debit_Acc__; "Sales Pmt. Disc. Debit Acc.")
                {
                }
                column(General_Posting_Setup__Purch__Account_; "Purch. Account")
                {
                }
                column(General_Posting_Setup__Purch__Line_Disc__Account_; "Purch. Line Disc. Account")
                {
                }
                column(General_Posting_Setup__Purch__Inv__Disc__Account_; "Purch. Inv. Disc. Account")
                {
                }
                column(General_Posting_Setup__Purch__Pmt__Disc__Credit_Acc__; "Purch. Pmt. Disc. Credit Acc.")
                {
                }
                column(General_Posting_Setup__COGS_Account_; "COGS Account")
                {
                }
                column(General_Posting_Setup__Inventory_Adjmt__Account_; "Inventory Adjmt. Account")
                {
                }
                column(General_Posting_Setup__Sales_Credit_Memo_Account_; "Sales Credit Memo Account")
                {
                }
                column(General_Posting_Setup__Purch__Credit_Memo_Account_; "Purch. Credit Memo Account")
                {
                }
                column(Gen__Posting_SetupCaption; Gen__Posting_SetupCaptionLbl)
                {
                }
                column(General_Posting_Setup__Gen__Bus__Posting_Group_Caption; General_Posting_Setup__Gen__Bus__Posting_Group_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Gen__Prod__Posting_Group_Caption; General_Posting_Setup__Gen__Prod__Posting_Group_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Sales_Account_Caption; General_Posting_Setup__Sales_Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Sales_Line_Disc__Account_Caption; General_Posting_Setup__Sales_Line_Disc__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Sales_Inv__Disc__Account_Caption; General_Posting_Setup__Sales_Inv__Disc__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Sales_Pmt__Disc__Debit_Acc__Caption; General_Posting_Setup__Sales_Pmt__Disc__Debit_Acc__CaptionLbl)
                {
                }
                column(General_Posting_Setup__Purch__Account_Caption; General_Posting_Setup__Purch__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Purch__Line_Disc__Account_Caption; General_Posting_Setup__Purch__Line_Disc__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Purch__Inv__Disc__Account_Caption; General_Posting_Setup__Purch__Inv__Disc__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Purch__Pmt__Disc__Credit_Acc__Caption; General_Posting_Setup__Purch__Pmt__Disc__Credit_Acc__CaptionLbl)
                {
                }
                column(General_Posting_Setup__COGS_Account_Caption; General_Posting_Setup__COGS_Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Inventory_Adjmt__Account_Caption; General_Posting_Setup__Inventory_Adjmt__Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Sales_Credit_Memo_Account_Caption; General_Posting_Setup__Sales_Credit_Memo_Account_CaptionLbl)
                {
                }
                column(General_Posting_Setup__Purch__Credit_Memo_Account_Caption; General_Posting_Setup__Purch__Credit_Memo_Account_CaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"Posting Matrix" then
                        CurrReport.Break();
                end;
            }
            dataitem("VAT Business Posting Group"; "VAT Business Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(VAT_Business_Posting_Group_Code; Code)
                {
                }
                column(VAT_Business_Posting_Group_Description; Description)
                {
                }
                column(VAT_Posting_GroupsCaption; VAT_Posting_GroupsCaptionLbl)
                {
                }
                column(VAT_Business_Posting_Group_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(VAT_Business_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"VAT Setup" then
                        CurrReport.Break();
                end;
            }
            dataitem("VAT Product Posting Group"; "VAT Product Posting Group")
            {
                DataItemTableView = sorting(Code);
                column(VAT_Product_Posting_Group_Code; Code)
                {
                }
                column(VAT_Product_Posting_Group_Description; Description)
                {
                }
                column(VAT_Product_Posting_GroupsCaption; VAT_Product_Posting_GroupsCaptionLbl)
                {
                }
                column(VAT_Product_Posting_Group_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(VAT_Product_Posting_Group_CodeCaption; FieldCaption(Code))
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"VAT Setup" then
                        CurrReport.Break();
                end;
            }
            dataitem("VAT Posting Setup"; "VAT Posting Setup")
            {
                DataItemTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                column(VAT_Posting_Setup__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
                {
                }
                column(VAT_Posting_Setup__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
                {
                }
                column(VAT_Posting_Setup__VAT_Calculation_Type_; "VAT Calculation Type")
                {
                }
                column(VAT_Posting_Setup__VAT___; "VAT %")
                {
                }
                column(VAT_Posting_Setup__Unrealized_VAT_Type_; "Unrealized VAT Type")
                {
                }
                column(VAT_Posting_Setup__Adjust_for_Payment_Discount_; "Adjust for Payment Discount")
                {
                }
                column(VAT_Posting_Setup__Sales_VAT_Account_; "Sales VAT Account")
                {
                }
                column(VAT_Posting_Setup__Sales_VAT_Unreal__Account_; "Sales VAT Unreal. Account")
                {
                }
                column(VAT_Posting_Setup__Purchase_VAT_Account_; "Purchase VAT Account")
                {
                }
                column(VAT_Posting_Setup__Purch__VAT_Unreal__Account_; "Purch. VAT Unreal. Account")
                {
                }
                column(VAT_Posting_Setup__Reverse_Chrg__VAT_Acc__; "Reverse Chrg. VAT Acc.")
                {
                }
                column(VAT_Posting_Setup__Reverse_Chrg__VAT_Unreal__Acc__; "Reverse Chrg. VAT Unreal. Acc.")
                {
                }
                column(VAT_SetupCaption; VAT_SetupCaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Reverse_Chrg__VAT_Unreal__Acc__Caption; VAT_Posting_Setup__Reverse_Chrg__VAT_Unreal__Acc__CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Reverse_Chrg__VAT_Acc__Caption; VAT_Posting_Setup__Reverse_Chrg__VAT_Acc__CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Purch__VAT_Unreal__Account_Caption; VAT_Posting_Setup__Purch__VAT_Unreal__Account_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Purchase_VAT_Account_Caption; VAT_Posting_Setup__Purchase_VAT_Account_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Sales_VAT_Unreal__Account_Caption; VAT_Posting_Setup__Sales_VAT_Unreal__Account_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Sales_VAT_Account_Caption; VAT_Posting_Setup__Sales_VAT_Account_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Adjust_for_Payment_Discount_Caption; VAT_Posting_Setup__Adjust_for_Payment_Discount_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__Unrealized_VAT_Type_Caption; VAT_Posting_Setup__Unrealized_VAT_Type_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__VAT___Caption; FieldCaption("VAT %"))
                {
                }
                column(VAT_Posting_Setup__VAT_Calculation_Type_Caption; VAT_Posting_Setup__VAT_Calculation_Type_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__VAT_Prod__Posting_Group_Caption; VAT_Posting_Setup__VAT_Prod__Posting_Group_CaptionLbl)
                {
                }
                column(VAT_Posting_Setup__VAT_Bus__Posting_Group_Caption; VAT_Posting_Setup__VAT_Bus__Posting_Group_CaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::"VAT Setup" then
                        CurrReport.Break();
                end;
            }
            dataitem("Source Code"; "Source Code")
            {
                DataItemTableView = sorting(Code);
                column(Source_Code_Code; Code)
                {
                }
                column(Source_Code_Description; Description)
                {
                }
                column(Source_Code_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Source_Code_CodeCaption; FieldCaption(Code))
                {
                }
                column(SourceCaption; SourceCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::PostingSource then
                        CurrReport.Break();
                end;
            }
            dataitem("Source Code Setup"; "Source Code Setup")
            {
                DataItemTableView = sorting("Primary Key");
                column(Source_Code_Setup__Inventory_Post_Cost_; "Inventory Post Cost")
                {
                }
                column(Source_Code_Setup__Post_Recognition_; "Post Recognition")
                {
                }
                column(Source_Code_Setup__Post_Value_; "Post Value")
                {
                }
                column(Source_Code_Setup__Close_Income_Statement_; "Close Income Statement")
                {
                }
                column(Source_Code_Setup_Consolidation; Consolidation)
                {
                }
                column(Source_Code_Setup__General_Journal_; "General Journal")
                {
                }
                column(Source_Code_Setup__Item_Journal_; "Item Journal")
                {
                }
                column(Source_Code_Setup__Resource_Journal_; "Resource Journal")
                {
                }
                column(Source_Code_Setup__Job_Journal_; "Job Journal")
                {
                }
                column(Source_Code_Setup__VAT_Settlement_; "VAT Settlement")
                {
                }
                column(Source_Code_Setup__Compress_Item_Ledger_; "Compress Item Ledger")
                {
                }
                column(Source_Code_Setup__Item_Reclass__Journal_; "Item Reclass. Journal")
                {
                }
                column(Source_Code_Setup__Phys__Inventory_Journal_; "Phys. Inventory Journal")
                {
                }
                column(Source_Code_Setup_Sales; Sales)
                {
                }
                column(Source_Code_Setup_Purchases; Purchases)
                {
                }
                column(Source_Code_Setup__Sales_Journal_; "Sales Journal")
                {
                }
                column(Source_Code_Setup__Purchase_Journal_; "Purchase Journal")
                {
                }
                column(Source_Code_Setup__Cash_Receipt_Journal_; "Cash Receipt Journal")
                {
                }
                column(Source_Code_Setup__Payment_Journal_; "Payment Journal")
                {
                }
                column(Source_Code_Setup__Sales_Entry_Application_; "Sales Entry Application")
                {
                }
                column(Source_Code_Setup__Purchase_Entry_Application_; "Purchase Entry Application")
                {
                }
                column(Source_Code_Setup__Fixed_Asset_Journal_; "Fixed Asset Journal")
                {
                }
                column(Source_Code_Setup__Fixed_Asset_G_L_Journal_; "Fixed Asset G/L Journal")
                {
                }
                column(Source_Code_Setup__Insurance_Journal_; "Insurance Journal")
                {
                }
                column(Source_Code_Setup__Compress_FA_Ledger_; "Compress FA Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Maintenance_Ledger_; "Compress Maintenance Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Insurance_Ledger_; "Compress Insurance Ledger")
                {
                }
                column(Source_Code_Setup__Exchange_Rate_Adjmt__; "Exchange Rate Adjmt.")
                {
                }
                column(Source_Code_Setup__Compress_G_L_; "Compress G/L")
                {
                }
                column(Source_Code_Setup__Compress_VAT_Entries_; "Compress VAT Entries")
                {
                }
                column(Source_Code_Setup__Compress_Cust__Ledger_; "Compress Cust. Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Vend__Ledger_; "Compress Vend. Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Res__Ledger_; "Compress Res. Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Job_Ledger_; "Compress Job Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Bank_Acc__Ledger_; "Compress Bank Acc. Ledger")
                {
                }
                column(Source_Code_Setup__Compress_Check_Ledger_; "Compress Check Ledger")
                {
                }
                column(Source_Code_Setup__Financially_Voided_Check_; "Financially Voided Check")
                {
                }
                column(Source_Code_Setup__Finance_Charge_Memo_; "Finance Charge Memo")
                {
                }
                column(Source_Code_Setup_Reminder; Reminder)
                {
                }
                column(Source_Code_Setup__Deleted_Document_; "Deleted Document")
                {
                }
                column(Source_Code_Setup__Adjust_Add__Reporting_Currency_; "Adjust Add. Reporting Currency")
                {
                }
                column(Source_Code_Setup_Primary_Key; "Primary Key")
                {
                }
                column(Source_SetupCaption; Source_SetupCaptionLbl)
                {
                }
                column(Source_Code_Setup__Post_Value_Caption; FieldCaption("Post Value"))
                {
                }
                column(Source_Code_Setup__Inventory_Post_Cost_Caption; FieldCaption("Inventory Post Cost"))
                {
                }
                column(Source_Code_Setup__Post_Recognition_Caption; FieldCaption("Post Recognition"))
                {
                }
                column(Source_Code_Setup__Resource_Journal_Caption; FieldCaption("Resource Journal"))
                {
                }
                column(Source_Code_Setup__Job_Journal_Caption; FieldCaption("Job Journal"))
                {
                }
                column(Source_Code_Setup__Item_Journal_Caption; FieldCaption("Item Journal"))
                {
                }
                column(Source_Code_Setup__Compress_Item_Ledger_Caption; FieldCaption("Compress Item Ledger"))
                {
                }
                column(Source_Code_Setup__Item_Reclass__Journal_Caption; FieldCaption("Item Reclass. Journal"))
                {
                }
                column(Source_Code_Setup__Phys__Inventory_Journal_Caption; FieldCaption("Phys. Inventory Journal"))
                {
                }
                column(Source_Code_Setup_ConsolidationCaption; FieldCaption(Consolidation))
                {
                }
                column(Source_Code_Setup__VAT_Settlement_Caption; FieldCaption("VAT Settlement"))
                {
                }
                column(Source_Code_Setup__Close_Income_Statement_Caption; FieldCaption("Close Income Statement"))
                {
                }
                column(Source_Code_Setup__General_Journal_Caption; FieldCaption("General Journal"))
                {
                }
                column(Source_Code_Setup_SalesCaption; FieldCaption(Sales))
                {
                }
                column(Source_Code_Setup_PurchasesCaption; FieldCaption(Purchases))
                {
                }
                column(Source_Code_Setup__Sales_Journal_Caption; FieldCaption("Sales Journal"))
                {
                }
                column(Source_Code_Setup__Purchase_Journal_Caption; FieldCaption("Purchase Journal"))
                {
                }
                column(Source_Code_Setup__Cash_Receipt_Journal_Caption; FieldCaption("Cash Receipt Journal"))
                {
                }
                column(Source_Code_Setup__Payment_Journal_Caption; FieldCaption("Payment Journal"))
                {
                }
                column(Source_Code_Setup__Sales_Entry_Application_Caption; FieldCaption("Sales Entry Application"))
                {
                }
                column(Source_Code_Setup__Purchase_Entry_Application_Caption; FieldCaption("Purchase Entry Application"))
                {
                }
                column(Source_Code_Setup__Fixed_Asset_Journal_Caption; FieldCaption("Fixed Asset Journal"))
                {
                }
                column(Source_Code_Setup__Fixed_Asset_G_L_Journal_Caption; FieldCaption("Fixed Asset G/L Journal"))
                {
                }
                column(Source_Code_Setup__Insurance_Journal_Caption; FieldCaption("Insurance Journal"))
                {
                }
                column(Source_Code_Setup__Compress_FA_Ledger_Caption; FieldCaption("Compress FA Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Maintenance_Ledger_Caption; FieldCaption("Compress Maintenance Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Insurance_Ledger_Caption; FieldCaption("Compress Insurance Ledger"))
                {
                }
                column(Source_Code_Setup__Exchange_Rate_Adjmt__Caption; FieldCaption("Exchange Rate Adjmt."))
                {
                }
                column(Source_Code_Setup__Compress_G_L_Caption; FieldCaption("Compress G/L"))
                {
                }
                column(Source_Code_Setup__Compress_VAT_Entries_Caption; FieldCaption("Compress VAT Entries"))
                {
                }
                column(Source_Code_Setup__Compress_Cust__Ledger_Caption; FieldCaption("Compress Cust. Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Vend__Ledger_Caption; FieldCaption("Compress Vend. Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Res__Ledger_Caption; FieldCaption("Compress Res. Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Job_Ledger_Caption; FieldCaption("Compress Job Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Bank_Acc__Ledger_Caption; FieldCaption("Compress Bank Acc. Ledger"))
                {
                }
                column(Source_Code_Setup__Compress_Check_Ledger_Caption; FieldCaption("Compress Check Ledger"))
                {
                }
                column(Source_Code_Setup__Financially_Voided_Check_Caption; FieldCaption("Financially Voided Check"))
                {
                }
                column(Source_Code_Setup__Finance_Charge_Memo_Caption; FieldCaption("Finance Charge Memo"))
                {
                }
                column(Source_Code_Setup_ReminderCaption; FieldCaption(Reminder))
                {
                }
                column(Source_Code_Setup__Deleted_Document_Caption; FieldCaption("Deleted Document"))
                {
                }
                column(Source_Code_Setup__Adjust_Add__Reporting_Currency_Caption; FieldCaption("Adjust Add. Reporting Currency"))
                {
                }
                column(G_LCaption; G_LCaptionLbl)
                {
                }
                column(Cust_VendorCaption; Cust_VendorCaptionLbl)
                {
                }
                column(Date_CompressionCaption; Date_CompressionCaptionLbl)
                {
                }
                column(Misc_Caption; Misc_CaptionLbl)
                {
                }
                column(Fixed_AssetsCaption; Fixed_AssetsCaptionLbl)
                {
                }
                column(Items_and_StockCaption; Items_and_StockCaptionLbl)
                {
                }
                column(Resources_and_ProjectsCaption; Resources_and_ProjectsCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::PostingSource then
                        CurrReport.Break();
                end;
            }
            dataitem("Reason Code"; "Reason Code")
            {
                DataItemTableView = sorting(Code);
                column(Reason_Code_Code; Code)
                {
                }
                column(Reason_Code_Description; Description)
                {
                }
                column(Reason_Code_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Reason_Code_CodeCaption; FieldCaption(Code))
                {
                }
                column(Reason_CodeCaption; Reason_CodeCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::PostingSource then
                        CurrReport.Break();
                end;
            }
            dataitem("Field"; "Field")
            {
                DataItemTableView = sorting(TableNo, "No.") order(ascending) where(RelationTableNo = filter(= 308));

                trigger OnAfterGetRecord()
                var
                    FldRef: FieldRef;
                begin
                    if (StrPos(TableName, 'Setup') = 0) and (StrPos(TableName, 'Template') = 0) then
                        CurrReport.Skip();

                    RecRef.Open(TableNo);
                    if RecRef.FindFirst() then
                        repeat
                            FldRef := RecRef.Field("No.");
                            FldRefValue := FldRef.Value();
                            if FldRefValue <> '' then begin
                                EntryNo := EntryNo + 1;
                                NumberSeriesBuffer.Init();
                                NumberSeriesBuffer."Entry No." := EntryNo;
                                NumberSeriesBuffer."Table No." := TableNo;
                                NumberSeriesBuffer."Table Name" := TableName;
                                NumberSeriesBuffer."Field Name" := FieldName;
                                NumberSeriesBuffer."Field No." := "No.";
                                NumberSeriesBuffer."Field Value" := FldRefValue;
                                NumberSeriesBuffer.Insert();
                                NumberSeriesBuffer2.Init();
                                NumberSeriesBuffer2.Copy(NumberSeriesBuffer);
                                NumberSeriesBuffer2.Insert();
                            end;
                        until RecRef.Next() = 0;
                    RecRef.Close();
                end;

                trigger OnPreDataItem()
                begin
                    if Layout <> Layout::NoSeries then
                        CurrReport.Break();

                    EntryNo := 0;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    ErrorCounter := 0;
                    FirstEntry := false;
                    Clear(ErrorText);

                    NumberSeriesBuffer.Reset();
                    if NumberSeriesBuffer.FindSet() then
                        repeat
                            if not ((StrPos(NumberSeriesBuffer."Field Name", 'Posting') = 0) and
                                    (StrPos(NumberSeriesBuffer."Field Name", 'Posted') = 0))
                            then
                                if NoSeries.Get(NumberSeriesBuffer."Field Value") then begin
                                    if NoSeries."Manual Nos." then
                                        AddError(StrSubstNo(Text1140001, NumberSeriesBuffer."Table Name", NumberSeriesBuffer."Field Name",
                                            NumberSeriesBuffer."Field Value"));
                                    if not NoSeries."Date Order" then
                                        AddError(StrSubstNo(Text1140002, NumberSeriesBuffer."Table Name", NumberSeriesBuffer."Field Name",
                                            NumberSeriesBuffer."Field Value"));
                                end;

                            NumberSeriesBuffer2.Reset();
                            NumberSeriesBuffer2.SetRange("Field Value", NumberSeriesBuffer."Field Value");
                            NumberSeriesBuffer2.SetFilter("Entry No.", '<> %1', NumberSeriesBuffer."Entry No.");
                            if NumberSeriesBuffer2.FindSet() then
                                repeat
                                    if not ((NumberSeriesBuffer2."Table No." = NumberSeriesBuffer."Table No.") and NumberSeriesBuffer2.Checked) then begin
                                        AddError(StrSubstNo(Text1140015, NumberSeriesBuffer."Table Name", NumberSeriesBuffer."Field Name",
                                            NumberSeriesBuffer2."Table Name", NumberSeriesBuffer2."Field Name", NumberSeriesBuffer."Field Value"));
                                        NumberSeriesBuffer2.Checked := true;
                                        NumberSeriesBuffer.Checked := true;
                                        NumberSeriesBuffer.Modify();
                                        NumberSeriesBuffer2.Modify();
                                        FirstEntry := true;
                                    end;
                                until NumberSeriesBuffer2.Next() = 0;
                            if FirstEntry then begin
                                NumberSeriesBuffer2.Get(NumberSeriesBuffer."Entry No.");
                                NumberSeriesBuffer2.Checked := true;
                                NumberSeriesBuffer2.Modify();
                            end;
                        until NumberSeriesBuffer.Next() = 0;
                    SetRange(Number, 1, ErrorCounter);
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SetupInformation; Layout)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Setup Information';
                        OptionCaption = 'G/L Setup - Company Data - Consolidation,Posting Groups,Posting Matrix,VAT Setup,Source Code - Reason Code,Check Number Series';
                        ToolTip = 'Specifies that you want to investigate setup information for this area.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        LayoutInt := Layout;
    end;

    var
        NumberSeriesBuffer: Record "Number Series Buffer" temporary;
        NumberSeriesBuffer2: Record "Number Series Buffer" temporary;
        NoSeries: Record "No. Series";
        RecRef: RecordRef;
        "Layout": Option "General Info","Posting Groups","Posting Matrix","VAT Setup",PostingSource,NoSeries;
        ErrorText: array[1024] of Text[250];
        FldRefValue: Text[30];
        LayoutInt: Integer;
        EntryNo: Integer;
        ErrorCounter: Integer;
        FirstEntry: Boolean;
        Text1140001: Label 'Warning ! The number series %3 used in table %1 / field %2 allows creating manual document numbers';
        Text1140002: Label 'Warning ! The number series %3 used in table %1 / field %2  is not chronological';
        Text1140015: Label 'Warning ! The number series %5 used in table %1 / field %2 also is used in table %3 / field %4. ';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Setup_InformationCaptionLbl: Label 'Setup Information';
        General_Ledger_Setup__Allow_Posting_To_CaptionLbl: Label 'Allow Posting To';
        General_Ledger_Setup__Allow_Posting_From_CaptionLbl: Label 'Allow Posting From';
        G_L_SetupCaptionLbl: Label 'G/L Setup';
        GeneralCaptionLbl: Label 'General';
        VATCaptionLbl: Label 'VAT';
        RoundingCaptionLbl: Label 'Rounding';
        CurrencyCaptionLbl: Label 'Currency';
        DimensionsCaptionLbl: Label 'Dimensions';
        Company_Information__Customs_Permit_Date_CaptionLbl: Label 'Customs Permit Date';
        Post_Code___CityCaptionLbl: Label 'Post Code / City';
        Shipment_Post_Code___CityCaptionLbl: Label 'Shipment Post Code / City';
        Company_DataCaptionLbl: Label 'Company Data';
        Company_AddressCaptionLbl: Label 'Company Address';
        Shipment_AddressCaptionLbl: Label 'Shipment Address';
        CommunicationCaptionLbl: Label 'Communication';
        PaymentsCaptionLbl: Label 'Payments';
        Customs_and_VATCaptionLbl: Label 'Customs and VAT';
        Consolidation_CompaniesCaptionLbl: Label 'Consolidation Companies';
        Business_Unit__Residual_Account_CaptionLbl: Label 'Rounding Acc.';
        Business_Unit__Exch__Rate_Gains_Acc__CaptionLbl: Label 'Ex. Profit Acc.';
        Business_Unit__Exch__Rate_Losses_Acc__CaptionLbl: Label 'Ex. Loss Acc.';
        ROUND__Balance_Currency_Factor__0_0001_CaptionLbl: Label 'Ex. for Balance';
        ROUND__Income_Currency_Factor__0_0001_CaptionLbl: Label 'Ex. for P/L';
        Business_Unit__Ending_Date_CaptionLbl: Label 'End Date';
        Business_Unit__Starting_Date_CaptionLbl: Label 'Start Date';
        Business_Unit__Consolidation___CaptionLbl: Label 'Cons. %';
        ROUND__Last_Balance_Currency_Factor__0_0001_CaptionLbl: Label 'Fact. last Bal.';
        Business_Unit__Currency_Code_CaptionLbl: Label 'Curr.';
        Customer_Posting_GroupsCaptionLbl: Label 'Customer Posting Groups';
        Customer_Posting_Group__Payment_Disc__Debit_Acc__CaptionLbl: Label 'Cash Disc. Account';
        Customer_Posting_Group__Invoice_Rounding_Account_CaptionLbl: Label 'Inv. Round. Acc.';
        Customer_Posting_Group__Debit_Curr__Appln__Rndg__Acc__CaptionLbl: Label 'Curr. Appl. Round. Acc.';
        Customer_Posting_Group__Service_Charge_Acc__CaptionLbl: Label 'Charge Account';
        Customer_Posting_Group__Receivables_Account_CaptionLbl: Label 'Customer Summary Account';
        Vendor_Posting_GroupsCaptionLbl: Label 'Vendor Posting Groups';
        Vendor_Posting_Group__Service_Charge_Acc__CaptionLbl: Label 'Charge Account';
        Vendor_Posting_Group__Payment_Disc__Debit_Acc__CaptionLbl: Label 'Cash Disc. Account';
        Vendor_Posting_Group__Invoice_Rounding_Account_CaptionLbl: Label 'Inv. Round. Acc.';
        Vendor_Posting_Group__Debit_Curr__Appln__Rndg__Acc__CaptionLbl: Label 'Curr. Appl. Round. Acc.';
        Vendor_Posting_Group__Payables_Account_CaptionLbl: Label 'Vendor Summary Acc.';
        Inventory_Posting_GroupsCaptionLbl: Label 'Inventory Posting Groups';
        Bank_Posting_GroupsCaptionLbl: Label 'Bank Posting Groups';
        Bank_Account_Posting_Group__G_L_Bank_Account_No__CaptionLbl: Label 'Bank G/L Account';
        Gen__Business_Posting_GroupsCaptionLbl: Label 'Gen. Business Posting Groups';
        Gen__Business_Posting_Group__Auto_Insert_Default_CaptionLbl: Label 'Use Std. Posting Gr.';
        Gen__Product_Posting_GroupsCaptionLbl: Label 'Gen. Product Posting Groups';
        Gen__Product_Posting_Group__Auto_Insert_Default_CaptionLbl: Label 'Use Std. Posting Gr.';
        Gen__Posting_SetupCaptionLbl: Label 'Gen. Posting Setup';
        General_Posting_Setup__Gen__Bus__Posting_Group_CaptionLbl: Label 'Bus. PG';
        General_Posting_Setup__Gen__Prod__Posting_Group_CaptionLbl: Label 'Prod. PG';
        General_Posting_Setup__Sales_Account_CaptionLbl: Label 'Item Sales';
        General_Posting_Setup__Sales_Line_Disc__Account_CaptionLbl: Label 'Salesline D.';
        General_Posting_Setup__Sales_Inv__Disc__Account_CaptionLbl: Label 'Salesinv. D.';
        General_Posting_Setup__Sales_Pmt__Disc__Debit_Acc__CaptionLbl: Label 'Cash D';
        General_Posting_Setup__Purch__Account_CaptionLbl: Label 'Item Purch.';
        General_Posting_Setup__Purch__Line_Disc__Account_CaptionLbl: Label 'Purch. Line D.';
        General_Posting_Setup__Purch__Inv__Disc__Account_CaptionLbl: Label 'Purch. Inv. D';
        General_Posting_Setup__Purch__Pmt__Disc__Credit_Acc__CaptionLbl: Label 'P. Cash D';
        General_Posting_Setup__COGS_Account_CaptionLbl: Label 'Stock Dec.';
        General_Posting_Setup__Inventory_Adjmt__Account_CaptionLbl: Label 'Stock Var.';
        General_Posting_Setup__Sales_Credit_Memo_Account_CaptionLbl: Label 'Sales CM';
        General_Posting_Setup__Purch__Credit_Memo_Account_CaptionLbl: Label 'Purch. CM';
        VAT_Posting_GroupsCaptionLbl: Label 'VAT Posting Groups';
        VAT_Product_Posting_GroupsCaptionLbl: Label 'VAT Product Posting Groups';
        VAT_SetupCaptionLbl: Label 'VAT Setup';
        VAT_Posting_Setup__Reverse_Chrg__VAT_Unreal__Acc__CaptionLbl: Label 'Unreal. Rev. VAT';
        VAT_Posting_Setup__Reverse_Chrg__VAT_Acc__CaptionLbl: Label 'Reverse VAT';
        VAT_Posting_Setup__Purch__VAT_Unreal__Account_CaptionLbl: Label 'Unreal. Purch';
        VAT_Posting_Setup__Purchase_VAT_Account_CaptionLbl: Label 'Purch. VAT';
        VAT_Posting_Setup__Sales_VAT_Unreal__Account_CaptionLbl: Label 'Unreal. Sales';
        VAT_Posting_Setup__Sales_VAT_Account_CaptionLbl: Label 'Sales VAT';
        VAT_Posting_Setup__Adjust_for_Payment_Discount_CaptionLbl: Label 'Red. on Cash D.';
        VAT_Posting_Setup__Unrealized_VAT_Type_CaptionLbl: Label 'Unreal. VAT Type';
        VAT_Posting_Setup__VAT_Calculation_Type_CaptionLbl: Label 'Calc. Type';
        VAT_Posting_Setup__VAT_Prod__Posting_Group_CaptionLbl: Label 'VAT Product Gr.';
        VAT_Posting_Setup__VAT_Bus__Posting_Group_CaptionLbl: Label 'VAT Business Posting Groups';
        SourceCaptionLbl: Label 'Source';
        Source_SetupCaptionLbl: Label 'Source Setup';
        G_LCaptionLbl: Label 'G/L';
        Cust_VendorCaptionLbl: Label 'Cust/Vendor';
        Date_CompressionCaptionLbl: Label 'Date Compression';
        Misc_CaptionLbl: Label 'Misc.';
        Fixed_AssetsCaptionLbl: Label 'Fixed Assets';
        Items_and_StockCaptionLbl: Label 'Items and Stock';
        Resources_and_ProjectsCaptionLbl: Label 'Resources and Projects';
        Reason_CodeCaptionLbl: Label 'Reason Code';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

