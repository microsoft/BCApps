// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

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
                    ToolTip = 'Specifies whether to include the VAT product posting group on the line.';
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
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';

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
                    ToolTip = 'Specifies how a cost recipient is linked to its cost source to provide cost forwarding according to the costing method.';
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
                    ToolTip = 'Specifies a description of the VAT product posting group.';
                    Visible = VATRatesGroup;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used.';
                    Visible = VATRatesGroup;
                    Width = 3;
                }
                field("Sales VAT Account"; Rec."Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post sales VAT, for the particular combination of VAT business posting group and VAT product posting group.';
                    Visible = VATAccountsGroup;
                }
                field("Purchase VAT Account"; Rec."Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase VAT.';
                    Visible = VATAccountsGroup;
                }
                field("Reverse Chrg. VAT Acc."; Rec."Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Visible = VATAccountsGroup;
                }
                field("VAT Clause Desc"; Rec."VAT Clause Desc")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT clause.';
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

    procedure ShowVATRates()
    begin
        ResetView();
        VATRatesGroup := true;
        Rec.Reset();
        Rec.SetRange(Default, false);
        CurrPage.Update();
    end;

    procedure ShowVATAccounts()
    begin
        ResetView();
        VATAccountsGroup := true;
        ShowOnlySelectedSrvItem();
    end;

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

