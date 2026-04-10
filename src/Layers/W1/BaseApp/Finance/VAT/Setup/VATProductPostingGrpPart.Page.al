// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// VAT product posting group part page component used within the VAT Setup Wizard for group selection and configuration.
/// Displays VAT product posting groups with selection options and VAT rate configuration fields.
/// </summary>
/// <remarks>
/// Page type: ListPart component integrated into VAT Setup Wizard workflow.
/// Data source: VAT Setup Posting Groups table containing temporary wizard configurations.
/// User interaction: Select/configure VAT product posting groups and rates for wizard-based setup creation.
/// </remarks>
page 1879 "VAT Product Posting Grp Part"
{
    Caption = 'VAT Product Posting Grp Part';
    PageType = ListPart;
    SourceTable = "VAT Setup Posting Groups";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATRatesGroup;

                    trigger OnValidate()
                    begin
                        if Rec.Selected then
                            exit;

                        if Rec.CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = Rec."Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        if Rec.CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = Rec."Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("Application Type"; Rec."Application Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATRatesGroup;

                    trigger OnValidate()
                    begin
                        if Rec.CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = Rec."Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("VAT Prod. Posting Grp Desc."; Rec."VAT Prod. Posting Grp Desc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATRatesGroup;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATRatesGroup;
                    Width = 3;
                }
                field("Sales VAT Account"; Rec."Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATAccountsGroup;
                }
                field("Purchase VAT Account"; Rec."Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATAccountsGroup;
                }
                field("Reverse Chrg. VAT Acc."; Rec."Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATAccountsGroup;
                }
                field("VAT Clause Desc"; Rec."VAT Clause Desc")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = VATClausesGroup;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec.CheckExistingItemAndServiceWithVAT(Rec."VAT Prod. Posting Group", Rec."Application Type" = Rec."Application Type"::Services) then begin
            TrigerNotification(VATDeleteIsNotallowedErr);
            exit(false);
        end;
        if VATAccountsGroup or VATClausesGroup then begin
            Rec.SetRange(Selected, true);
            if Rec.Count = 1 then begin
                TrigerNotification(VATEmptyErrorMsg);
                exit(false);
            end;
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if VATAccountsGroup or VATClausesGroup then
            Error(VATAddIsNotallowedErr);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Validate(Selected, true);
        Rec.Validate(Default, false);
        Rec.Validate("Application Type", Rec."Application Type"::Items);
    end;

    trigger OnOpenPage()
    begin
        VATNotification.Id := Format(CreateGuid());
        Rec.PopulateVATProdGroups();
        ShowVATRates();
        Rec.SetRange(Default, false);
    end;

    var
        VATNotification: Notification;
        VATRatesGroup: Boolean;
        VATAccountsGroup: Boolean;
        VATClausesGroup: Boolean;
        VATAddIsNotallowedErr: Label 'You can''t add accounts now because they won''t have settings like VAT rates. Go back to the VAT Rates for Items and Services page, add a line, and continue.';
        VATDeleteIsNotallowedErr: Label 'You can''t delete or modify this VAT record because it is connected to existing item.';
        VATEmptyErrorMsg: Label 'You can''t delete the record because the VAT setup would be empty.';

    /// <summary>
    /// Displays VAT rates configuration view for VAT product posting groups selection and rate assignment.
    /// Shows VAT product posting groups with editable VAT percentage fields for rate configuration.
    /// </summary>
    procedure ShowVATRates()
    begin
        ResetView();
        VATRatesGroup := true;
        Rec.Reset();
        Rec.SetRange(Default, false);
        CurrPage.Update();
    end;

    /// <summary>
    /// Displays VAT accounts configuration view for G/L account assignment to VAT product posting groups.
    /// Shows selected VAT product posting groups with account assignment fields for purchase and sales VAT accounts.
    /// </summary>
    procedure ShowVATAccounts()
    begin
        ResetView();
        VATAccountsGroup := true;
        ShowOnlySelectedSrvItem();
    end;

    /// <summary>
    /// Displays VAT clauses configuration view for VAT clause assignment to VAT product posting groups.
    /// Shows selected VAT product posting groups with VAT clause assignment fields for document text handling.
    /// </summary>
    procedure ShowVATClauses()
    begin
        ResetView();
        VATClausesGroup := true;
        ShowOnlySelectedSrvItem();
    end;

    local procedure ResetView()
    begin
        VATNotification.Recall();
        VATRatesGroup := false;
        VATAccountsGroup := false;
        VATClausesGroup := false;
    end;

    local procedure ShowOnlySelectedSrvItem()
    begin
        Rec.SetRange(Selected, true);
        CurrPage.Update();
    end;

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        VATNotification.Recall();
        VATNotification.Message(NotificationMsg);
        VATNotification.Send();
    end;

    /// <summary>
    /// Hides any displayed notifications related to VAT product posting group validation or configuration warnings.
    /// Clears notification messages from the user interface during wizard navigation.
    /// </summary>
    procedure HideNotification()
    var
        DummyGuid: Guid;
    begin
        if VATNotification.Id = DummyGuid then
            exit;
        VATNotification.Message := '';
        VATNotification.Recall();
    end;
}

