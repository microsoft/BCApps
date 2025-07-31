// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Product Collections (ID 30172).
/// </summary>
page 30172 "Shpfy Product Collections"
{
    ApplicationArea = All;
    Caption = 'Shopify Custom Product Collections';
    PageType = List;
    SourceTable = "Shpfy Product Collection";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Default; Rec.Default) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetProductCollections)
            {
                Caption = 'Get Custom Product Collections';
                Image = UpdateDescription;
                ToolTip = 'Retrieves the custom product collections from Shopify.';

                trigger OnAction()
                var
                    ProductCollectionAPI: Codeunit "Shpfy Product Collection API";
                begin
                    ProductCollectionAPI.RetrieveCustomProductCollectionsFromShopify(CopyStr(Rec.GetFilter("Shop Code"), 1, 20));
                end;
            }
            action(SetAsDefault)
            {
                Caption = 'Set as Default';
                Enabled = not Rec.Default;
                Image = Approve;
                ToolTip = 'Sets Product Collection as Default.';

                trigger OnAction()
                begin
                    Rec.Validate(Default, true);
                    CurrPage.Update(true);
                end;
            }
            action(UnsetDefault)
            {
                Caption = 'Unset Default';
                Enabled = Rec.Default;
                Image = Reject;
                ToolTip = 'Unsets Product Collection as Default.';

                trigger OnAction()
                begin
                    Rec.Validate(Default, false);
                    CurrPage.Update(true);
                end;
            }
        }
        area(Promoted)
        {
            actionref(PromotedGetProductCollections; GetProductCollections) { }
            actionref(PromotedSetAsDefault; SetAsDefault) { }
            actionref(PromotedUnsetDefault; UnsetDefault) { }
        }
    }
}