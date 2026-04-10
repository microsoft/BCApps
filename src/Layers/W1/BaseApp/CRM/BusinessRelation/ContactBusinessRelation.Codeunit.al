// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

using System.Email;

codeunit 5956 "Contact Business Relation"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email", 'OnAfterAddRelation', '', false, false)]
    local procedure OnEmailAddedRelation(EmailMessageId: Guid; TableId: Integer; SystemId: Guid; var RelatedSystemIds: Dictionary of [Integer, List of [Guid]])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Get all business related records
        ContactBusinessRelation.GetBusinessRelatedSystemIds(TableId, SystemId, RelatedSystemIds);
    end;

}
