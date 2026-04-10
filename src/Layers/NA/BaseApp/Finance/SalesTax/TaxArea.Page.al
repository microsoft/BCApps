// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// Management page for tax area configuration and jurisdiction line maintenance.
/// Provides interface for creating tax areas and associating them with jurisdictions.
/// </summary>
page 464 "Tax Area"
{
    Caption = 'Tax Area';
    PageType = ListPlus;
    SourceTable = "Tax Area";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the tax area. For example, if you use a number as the tax code, you might want to describe the tax area in this field.';

                    trigger OnValidate()
                    var
                        Notification: Notification;
                    begin
                        if (StrLen(Rec.Description) > 30) and ShowTaxDescriptionWarning then begin
                            ShowTaxDescriptionWarning := false;
                            Notification.Message := TaxAreaDescriptionWarningMsg;
                            Notification.Scope := NotificationScope::LocalScope;
                            Notification.Send();
                        end;
                    end;
                }
                field("Country/Region"; Rec."Country/Region")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the country/region of this tax area. Tax jurisdictions of the same country/region can only then be assigned to this tax area.';
                    Visible = ShowTaxDetails;
                }
                field("Round Tax"; Rec."Round Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a rounding option for the tax area. This value is used to round sales tax to the nearest decimal.';
                    Visible = ShowTaxDetails;
                }
                field("Use External Tax Engine"; Rec."Use External Tax Engine")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies that you have purchased an external, third party sales tax engine, which calculates the sales tax rather than using the standard sales tax engine included in the product. Select the check box if this tax area code will indicate to the product that this external sales tax engine is to be used when this tax area code is used. Clear the check boxes to indicate that the standard, internal sales tax engine is to be used when this tax area code is used.';
                    Visible = ShowTaxDetails;
                }
            }
            part(Control7; "Tax Area Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Tax Area" = field(Code);
                Visible = ShowTaxDetails;
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not ShowTaxDetails then
            if Rec.Code <> '' then begin
                Rec.CreateTaxArea(Rec.Code, '', '');
                exit(false);
            end;
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        ShowTaxDetails := true;
        ShowTaxDescriptionWarning := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        if ShowTaxDetails and (CloseAction in [ACTION::OK, ACTION::LookupOK]) then begin
            TaxAreaLine.SetRange("Tax Area", Rec.Code);
            if not TaxAreaLine.FindFirst() then
                if not Confirm(TaxAreaNotSetupQst, false) then
                    Error('');
        end;
    end;

    var
        TaxAreaNotSetupQst: Label 'The Tax Area functionality does not work because you have not specified the Jurisdictions field.\\Do you want to continue?';
        ShowTaxDetails: Boolean;
        TaxAreaDescriptionWarningMsg: Label 'Descriptions longer than 30 characters may cause problems with printing Purchase Invoice';
        ShowTaxDescriptionWarning: Boolean;
}

