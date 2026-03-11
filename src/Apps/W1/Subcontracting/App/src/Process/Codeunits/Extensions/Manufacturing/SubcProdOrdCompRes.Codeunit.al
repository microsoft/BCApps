// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

codeunit 99001530 "Subc. Prod. Ord. Comp. Res."
{
    EventSubscriberInstance = Manual;

    /// <summary>
    /// When a transfer is created, the storage location in the production component is swapped and thus triggers the verification.\
    /// The verification attempts to perform an auto tracking if the order tracking policy of the item is not equal to None, but this is not possible.\
    /// Therefore the verification is overwritten and set to false.
    /// </summary>
    /// <param name="NewProdOrderComp"></param>
    /// <param name="OldProdOrderComp"></param>
    /// <param name="HasError"></param>
    /// <param name="ShowError"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Comp.-Reserve", OnVerifyChangeOnBeforeHasError, '', false, false)]
    local procedure "Prod. Order Comp.-Reserve_OnVerifyChangeOnBeforeHasError"(NewProdOrderComp: Record "Prod. Order Component"; OldProdOrderComp: Record "Prod. Order Component"; var HasError: Boolean; var ShowError: Boolean)
    begin
        HasError := false;
    end;
}