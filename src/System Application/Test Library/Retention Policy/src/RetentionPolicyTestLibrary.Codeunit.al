// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.DataAdministration;

using System.DataAdministration;

codeunit 138709 "Retention Policy Test Library"
{
    EventSubscriberInstance = Manual;

    var
        RecordExceedSubscriberCount: Integer;

    procedure GetDeleteRecordExceededSubscriberCount(): Integer
    begin
        exit(RecordExceedSubscriberCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyRecordLimitExceeded', '', false, false)]
    local procedure OnApplyRetentionPolicyRecordLimitExceeded(CurrTableId: Integer; NumberOfRecordsRemainingToBeDeleted: Integer)
    begin
        RecordExceedSubscriberCount += 1;
    end;
}