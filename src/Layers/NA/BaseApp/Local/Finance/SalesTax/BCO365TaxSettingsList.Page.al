// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;

page 10351 "BC O365 Tax Settings List"
{
    Caption = 'Tax Rates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Tax Area";

    layout
    {
        area(content)
        {
            repeater(Control1020001)
            {
                ShowCaption = false;
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax rate';
                    Editable = false;
                    ToolTip = 'Specifies the tax rate used to calculate tax on what you buy or sell.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Image = New;
                ToolTip = 'Create a new tax rate.';
                Visible = not IsCanada;

                trigger OnAction()
                var
                    TempTaxArea: Record "Tax Area" temporary;
                begin
                    TempTaxArea.Insert();
                    PAGE.RunModal(PAGE::"BC O365 Tax Settings Card", TempTaxArea);
                    CurrPage.Update();
                end;
            }
            action(Edit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                Scope = Repeater;
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                var
                    TempTaxArea: Record "Tax Area" temporary;
                begin
                    TempTaxArea := Rec;
                    TempTaxArea.Insert();
                    PAGE.RunModal(PAGE::"BC O365 Tax Settings Card", TempTaxArea);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(_NEW_TEMP__Promoted; _NEW_TEMP_)
                {
                }
                actionref(Edit_Promoted; Edit)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Code = O365TaxSettingsManagement.GetDefaultTaxArea() then
            TaxAreaDescription := StrSubstNo(DefaultTaxDescriptionTxt, Rec.GetDescriptionInCurrentLanguageFullLength())
        else
            TaxAreaDescription := Rec.GetDescriptionInCurrentLanguageFullLength();
    end;

    trigger OnInit()
    var
        CompanyInformation: Record "Company Information";
    begin
        IsCanada := CompanyInformation.IsCanada();
    end;

    var
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
        IsCanada: Boolean;
        DefaultTaxDescriptionTxt: Label '%1 (Default)', Comment = '%1 = a VAT rate name, such as "Reduced VAT"';
        TaxAreaDescription: Text;
}
