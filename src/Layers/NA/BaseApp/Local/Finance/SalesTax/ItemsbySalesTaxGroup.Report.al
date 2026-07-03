// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10147 "Items by Sales Tax Group"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/SalesTax/ItemsbySalesTaxGroup.rdlc';
    Caption = 'Items by Sales Tax Group';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Tax Group"; "Tax Group")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Tax_Group__TABLECAPTION__________TaxGrpFilter; "Tax Group".TableCaption + ': ' + TaxGrpFilter)
            {
            }
            column(TaxGrpFilter; TaxGrpFilter)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(TABLECAPTION_________FIELDCAPTION_Code___________Code; TableCaption + ' ' + FieldCaption(Code) + ': ' + Code)
            {
            }
            column(Tax_Group_Description; Description)
            {
            }
            column(Tax_Group_Code; Code)
            {
            }
            column(Items_by_Sales_Tax_GroupCaption; Items_by_Sales_Tax_GroupCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item__No__Caption; Item.FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; Item.FieldCaption(Description))
            {
            }
            column(Item__Vendor_No__Caption; Item.FieldCaption("Vendor No."))
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item.FieldCaption("Base Unit of Measure"))
            {
            }
            column(Item__Shelf_No__Caption; Item.FieldCaption("Shelf No."))
            {
            }
            column(Item__Inventory_Posting_Group_Caption; Item.FieldCaption("Inventory Posting Group"))
            {
            }
            column(Item_BlockedCaption; Item.FieldCaption(Blocked))
            {
            }
            column(Item_CommentCaption; Item.FieldCaption(Comment))
            {
            }
            dataitem(Item; Item)
            {
                CalcFields = Comment;
                DataItemLink = "Tax Group Code" = field(Code);
                RequestFilterFields = "No.", "Shelf No.", "Inventory Posting Group", "Vendor No.";
                column(Item__No__; "No.")
                {
                }
                column(Item_Description; Description)
                {
                }
                column(Item__Vendor_No__; "Vendor No.")
                {
                }
                column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
                {
                }
                column(Item__Shelf_No__; "Shelf No.")
                {
                }
                column(Item__Inventory_Posting_Group_; "Inventory Posting Group")
                {
                }
                column(Item_Blocked; Blocked)
                {
                }
                column(Item_Comment; Comment)
                {
                }
                column(Item_Tax_Group_Code; "Tax Group Code")
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
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
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        TaxGrpFilter := "Tax Group".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ItemFilter: Text;
        TaxGrpFilter: Text;
        Items_by_Sales_Tax_GroupCaptionLbl: Label 'Items by Sales Tax Group';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

