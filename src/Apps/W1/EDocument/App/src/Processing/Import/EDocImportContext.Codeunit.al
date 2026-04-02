// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.Purchases.Document;

codeunit 6199 "E-Doc. Import Context"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        CurrentContext: Text;
        IsBound: Boolean;
        AdditionalFieldContextLbl: Label 'While applying additional field "%1" (ID %2) with value ''%3''', Comment = '%1 = Field Name, %2 = Field Number, %3 = Value';
        ValidatingFieldLbl: Label 'While validating field "%1"', Comment = '%1 = Field Caption';
        WrapErrorLbl: Label '%1: %2', Comment = '%1 = Context, %2 = Original Error';

    procedure Bind()
    begin
        if not IsBound then begin
            BindSubscription(this);
            IsBound := true;
        end;
    end;

    procedure Unbind()
    begin
        if IsBound then begin
            UnbindSubscription(this);
            IsBound := false;
        end;
    end;

    procedure HasContext(): Boolean
    begin
        exit(CurrentContext <> '');
    end;

    procedure WrapErrorMessage(OriginalError: Text): Text
    begin
        if CurrentContext = '' then
            exit(OriginalError);
        exit(StrSubstNo(WrapErrorLbl, CurrentContext, OriginalError));
    end;

    procedure SetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)
    begin
        Unbind();
        CurrentContext := StrSubstNo(AdditionalFieldContextLbl, FieldName, FieldNo, Value);
    end;

    procedure ClearAdditionalFieldContext()
    begin
        CurrentContext := '';
        Bind();
    end;

    // Purchase Header OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Document Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDocDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Document Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Due Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDueDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Due Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Vendor Invoice No.", false, false)]
    local procedure OnBeforeValidatePurchHdrVendInvNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Vendor Invoice No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Currency Code", false, false)]
    local procedure OnBeforeValidatePurchHdrCurrCode(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Currency Code"));
    end;

    // Purchase Line OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "No.", false, false)]
    local procedure OnBeforeValidatePurchLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Allow Invoice Disc.", false, false)]
    local procedure OnBeforeValidatePurchLineAllowInvDisc(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Allow Invoice Disc."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Item Reference No.", false, false)]
    local procedure OnBeforeValidatePurchLineItemRefNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Item Reference No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, Quantity, false, false)]
    local procedure OnBeforeValidatePurchLineQty(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption(Quantity));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Direct Unit Cost", false, false)]
    local procedure OnBeforeValidatePurchLineDirectUnitCost(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Direct Unit Cost"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Line Discount Amount", false, false)]
    local procedure OnBeforeValidatePurchLineLineDiscAmt(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Line Discount Amount"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Deferral Code", false, false)]
    local procedure OnBeforeValidatePurchLineDeferralCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Deferral Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Dimension Set ID", false, false)]
    local procedure OnBeforeValidatePurchLineDimSetId(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Dimension Set ID"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 1 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim1(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 1 Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 2 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim2(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 2 Code"));
    end;
}
