// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// VAT business posting group part page component used within the VAT Setup Wizard for group selection.
/// Displays VAT business posting groups with selection checkboxes allowing users to choose which groups to create.
/// </summary>
/// <remarks>
/// Page type: ListPart component integrated into VAT Setup Wizard workflow.
/// Data source: VAT Assisted Setup Bus. Grp. table containing temporary wizard selections.
/// User interaction: Select/deselect VAT business posting groups for creation during wizard completion.
/// </remarks>
page 1878 "VAT Bus. Post. Grp Part"
{
    Caption = 'VAT Bus. Post. Grp Part';
    PageType = ListPart;
    SourceTable = "VAT Assisted Setup Bus. Grp.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include';

                    trigger OnValidate()
                    begin
                        if not Rec.Selected then
                            if Rec.CheckExistingCustomersAndVendorsWithVAT(Rec.Code) then begin
                                TrigerNotification(VATBusGrpExistingDataErrorMsg);
                                Rec.Selected := true;
                            end;
                    end;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        if (Rec.Code <> xRec.Code) and (xRec.Code <> '') then
                            if Rec.CheckExistingCustomersAndVendorsWithVAT(xRec.Code) then begin
                                TrigerNotification(VATBusGrpExistingDataErrorMsg);
                                Error('');
                            end;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec.CheckExistingCustomersAndVendorsWithVAT(Rec.Code) then begin
            TrigerNotification(VATBusGrpExistingDataErrorMsg);
            exit(false);
        end;
        if Rec.Count = 1 then begin
            TrigerNotification(VATBusGrpEmptyErrorMsg);
            exit(false);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Selected := true;
    end;

    trigger OnOpenPage()
    begin
        VATBusGrpNotification.Id := Format(CreateGuid());
        Rec.PopulateVATBusGrp();
        Rec.Selected := true;
        Rec.SetRange(Default, false);
    end;

    var
        VATBusGrpNotification: Notification;
        VATBusGrpExistingDataErrorMsg: Label 'You can''t change or delete the VAT business posting group because it''s already been used to post VAT for transactions.';
        VATBusGrpEmptyErrorMsg: Label 'You can''t delete the record because the VAT setup would be empty.';

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        VATBusGrpNotification.Recall();
        VATBusGrpNotification.Message(NotificationMsg);
        VATBusGrpNotification.Send();
    end;

    /// <summary>
    /// Hides any displayed notifications related to VAT business posting group validation or warnings.
    /// Clears notification messages from the user interface during wizard navigation.
    /// </summary>
    procedure HideNotification()
    var
        DummyGuid: Guid;
    begin
        if VATBusGrpNotification.Id = DummyGuid then
            exit;
        VATBusGrpNotification.Message := '';
        VATBusGrpNotification.Recall();
    end;
}

